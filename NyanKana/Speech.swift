import SwiftUI
import AVFoundation
import Speech
import Combine

// MARK: - Speech recognition (on device, English)

/// Listens to the microphone and turns English speech into text with Apple's speech recognizer.
/// It is not a phonetic grader: a word counts as "said well" when the recognizer hears that word.
@MainActor
final class SpeechCoach: ObservableObject {
    static let shared = SpeechCoach()

    enum State: Equatable { case idle, listening, denied, unavailable }
    @Published private(set) var state: State = .idle
    @Published private(set) var heard = ""

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
    private var engine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var onFinal: ((String) -> Void)?
    private var token = 0
    private var finishedToken = -1

    var available: Bool { recognizer?.isAvailable ?? false }

    /// Ask for microphone + speech permission (once), then call back with the result.
    func authorize(_ done: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            let ok = status == .authorized
            Task { @MainActor in
                guard ok else { SpeechCoach.shared.state = .denied; done(false); return }
                AVAudioApplication.requestRecordPermission { granted in
                    Task { @MainActor in
                        if !granted { SpeechCoach.shared.state = .denied }
                        done(granted)
                    }
                }
            }
        }
    }

    /// Start listening. `onFinal` gets the whole text when the speaker stops (silence) or `stop()` is called.
    func start(onFinal: @escaping (String) -> Void) {
        guard state != .listening else { return }
        authorize { ok in
            guard ok else { return }
            self.begin(onFinal)
        }
    }

    /// voice-answer stages keep the recording session open the whole time:
    /// switching the session back and forth on every answer made the music crackle and skip
    static var keepRecordSession = false {
        didSet {
            guard keepRecordSession != oldValue else { return }
            let session = AVAudioSession.sharedInstance()
            if keepRecordSession {
                try? session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers, .allowBluetoothA2DP])
            } else {
                try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            }
            try? session.setActive(true)
        }
    }

    private func begin(_ onFinal: @escaping (String) -> Void) {
        guard let recognizer, recognizer.isAvailable else { state = .unavailable; return }
        Speaker.shared.stop()
        self.onFinal = onFinal
        heard = ""
        token += 1
        let my = token

        if !SpeechCoach.keepRecordSession {
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
            try? session.setActive(true)
        }
        AudioManager.shared.duck(true)

        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        if recognizer.supportsOnDeviceRecognition { req.requiresOnDeviceRecognition = true }
        request = req

        let eng = AVAudioEngine()
        engine = eng
        SpeechCoach.installTap(eng.inputNode, req)
        eng.prepare()
        do { try eng.start() } catch { cleanup(); state = .unavailable; return }
        state = .listening
        AudioManager.shared.se(.tap, rate: 1.4, volume: 0.5)

        task = recognizer.recognitionTask(with: req) { result, error in
            let text = result?.bestTranscription.formattedString ?? ""
            let final = result?.isFinal ?? false
            let failed = error != nil
            Task { @MainActor in
                let c = SpeechCoach.shared
                guard my == c.token else { return }
                if !text.isEmpty { c.heard = text; c.armSilence(my) }
                if final || failed { c.finish(my) }
            }
        }
        // never listen forever
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 9_000_000_000)
            SpeechCoach.shared.finish(my)
        }
    }

    nonisolated private static func installTap(_ node: AVAudioInputNode, _ req: SFSpeechAudioBufferRecognitionRequest) {
        nonisolated(unsafe) let r = req
        let fmt = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: fmt) { buf, _ in r.append(buf) }
    }

    /// 1.3 s without new words = the speaker has finished
    private var silenceToken = 0
    private func armSilence(_ my: Int) {
        silenceToken += 1
        let s = silenceToken
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_300_000_000)
            let c = SpeechCoach.shared
            if c.silenceToken == s { c.finish(my) }
        }
    }

    /// Stop now and deliver what was heard.
    func stop() { finish(token) }

    /// Cancel without calling back (screen closed).
    func cancel() { token += 1; cleanup() }

    private func finish(_ my: Int) {
        guard my == token, finishedToken != my, state == .listening else { return }
        finishedToken = my
        let text = heard
        cleanup()
        onFinal?(text)
        onFinal = nil
    }

    private func cleanup() {
        engine?.inputNode.removeTap(onBus: 0)
        engine?.stop()
        engine = nil
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil
        if state == .listening { state = .idle }
        // back to playback only (unless a voice stage keeps the mic session open); the sound engine restarts on the route change
        if !SpeechCoach.keepRecordSession {
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try? session.setActive(true)
        }
        AudioManager.shared.duck(false)
    }
}

// MARK: - Comparing what was said with the target

enum SpeechMatch {
    private static let contractions: [String: String] = [
        "i'm": "i am", "you're": "you are", "he's": "he is", "she's": "she is", "it's": "it is", "we're": "we are",
        "they're": "they are", "that's": "that is", "there's": "there is", "what's": "what is", "isn't": "is not",
        "aren't": "are not", "wasn't": "was not", "weren't": "were not", "don't": "do not", "doesn't": "does not",
        "didn't": "did not", "can't": "can not", "cannot": "can not", "won't": "will not", "i'll": "i will",
        "you'll": "you will", "we'll": "we will", "i've": "i have", "you've": "you have", "haven't": "have not",
        "hasn't": "has not", "let's": "let us", "i'd": "i would", "shouldn't": "should not", "couldn't": "could not",
    ]
    private static let numbers = ["0": "zero", "1": "one", "2": "two", "3": "three", "4": "four", "5": "five", "6": "six",
                                  "7": "seven", "8": "eight", "9": "nine", "10": "ten", "11": "eleven", "12": "twelve",
                                  "20": "twenty", "100": "hundred"]

    /// lower-case words without punctuation; contractions and digits spelled out
    static func words(_ s: String) -> [String] {
        let t = s.lowercased().replacingOccurrences(of: "’", with: "'")
        let kept = String(t.unicodeScalars.map { CharacterSet.letters.contains($0) || CharacterSet.decimalDigits.contains($0) || $0 == "'" ? Character($0) : " " })
        var out: [String] = []
        for w in kept.split(separator: " ").map(String.init) {
            let w2 = w.trimmingCharacters(in: CharacterSet(charactersIn: "'"))
            if let c = contractions[w2] { out += c.split(separator: " ").map(String.init) }
            else if let n = numbers[w2] { out.append(n) }
            else if !w2.isEmpty { out.append(w2) }
        }
        return out
    }

    /// For each target word (as written), whether it was heard, in order (longest common subsequence).
    static func marks(target: String, heard: String) -> [(word: String, ok: Bool)] {
        let shown = target.split(separator: " ").map(String.init)
        let h = words(heard)
        var result: [(String, Bool)] = []
        // compare word by word; a shown word may expand to two (I'm -> i am)
        var expanded: [(shownIndex: Int, w: String)] = []
        for (i, s) in shown.enumerated() { for w in words(s) { expanded.append((i, w)) } }
        let a = expanded.map(\.w), n = a.count, m = h.count
        var dp = Array(repeating: Array(repeating: 0, count: m + 1), count: n + 1)
        if n > 0 && m > 0 {
            for i in stride(from: n - 1, through: 0, by: -1) {
                for j in stride(from: m - 1, through: 0, by: -1) {
                    dp[i][j] = a[i] == h[j] ? dp[i + 1][j + 1] + 1 : max(dp[i + 1][j], dp[i][j + 1])
                }
            }
        }
        var hit = Array(repeating: false, count: n)
        var i = 0, j = 0
        while i < n && j < m {
            if a[i] == h[j] { hit[i] = true; i += 1; j += 1 }
            else if dp[i + 1][j] >= dp[i][j + 1] { i += 1 } else { j += 1 }
        }
        for (k, s) in shown.enumerated() {
            let parts = expanded.indices.filter { expanded[$0].shownIndex == k }
            result.append((s, parts.isEmpty || parts.allSatisfy { hit[$0] }))
        }
        return result
    }

    static func score(_ marks: [(word: String, ok: Bool)]) -> Int {
        guard !marks.isEmpty else { return 0 }
        return Int((Double(marks.filter(\.ok).count) / Double(marks.count) * 100).rounded())
    }

    /// does the heard text contain this phrase as whole words?
    static func contains(_ heard: String, _ phrase: String) -> Bool {
        let h = " " + words(heard).joined(separator: " ") + " "
        let p = words(phrase).joined(separator: " ")
        return !p.isEmpty && h.contains(" " + p + " ")
    }
}

// MARK: - Mic button

struct MicButton: View {
    var size: CGFloat = 76
    var onText: (String) -> Void
    @ObservedObject private var coach = SpeechCoach.shared
    @State private var pulse = false

    var body: some View {
        let on = coach.state == .listening
        Button {
            if on { coach.stop() } else { coach.start(onFinal: onText) }
        } label: {
            ZStack {
                if on {
                    Circle().fill(Color.popDeep.opacity(0.25)).frame(width: size * 1.35, height: size * 1.35)
                        .scaleEffect(pulse ? 1.12 : 0.9)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: pulse)
                        .onAppear { pulse = true }.onDisappear { pulse = false }
                }
                Circle().fill(Color.ink).offset(y: 4).frame(width: size, height: size)
                Circle().fill(on ? Color.popDeep : Color.pop).overlay(Circle().stroke(Color.ink, lineWidth: 3.5)).frame(width: size, height: size)
                Image(systemName: on ? "waveform" : "mic.fill").font(.system(size: size * 0.4, weight: .black)).foregroundStyle(.white)
                    .symbolEffect(.variableColor.iterative, isActive: on)
            }
            .frame(width: size * 1.35, height: size * 1.35)
        }
        .buttonStyle(.plain)
    }
}

/// Small line under the mic: what to do / what was heard / why it cannot listen.
struct MicStatus: View {
    @ObservedObject private var coach = SpeechCoach.shared
    var hint: String
    var body: some View {
        Group {
            switch coach.state {
            case .listening:
                Text(coach.heard.isEmpty ? T("聞いています…", "듣고 있어요…", "正在聆聽…") : "“\(coach.heard)”")
            case .denied:
                Text(jp(T("マイクと|音声認識を|「設定」アプリで|オンにしてね", "설정 앱에서 마이크와 음성 인식을 켜 주세요", "請在「設定」App開啟麥克風與語音辨識")))
            case .unavailable:
                Text(jp(T("いまは|音声認識が|使えません", "지금은 음성 인식을 쓸 수 없어요", "目前無法使用語音辨識")))
            case .idle:
                Text(jp(hint))
            }
        }
        .font(.ui(13.s, bold: false)).foregroundStyle(Color.ink.opacity(0.75)).multilineTextAlignment(.center)
        .lineLimit(3).frame(minHeight: 34.s)
    }
}

// MARK: - Pronunciation challenge (study mode)

/// Listen to a model sentence, say it, see which words were understood.
struct SpeakSessionView: View {
    var close: () -> Void
    @EnvironmentObject var app: AppState
    @State private var qs: [Question] = []
    @State private var i = 0
    @State private var marks: [(word: String, ok: Bool)] = []
    @State private var tries = 0
    @State private var best: [Int] = []
    @State private var finished = false
    /// auto: the model plays, then the mic opens by itself, and a good answer moves on by itself
    @AppStorage("speak.auto") private var auto = false

    private var q: Question? { i < qs.count ? qs[i] : nil }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            PopBackdrop(base: StudyMode.speak.color.opacity(0.7), calm: true)
            VStack(spacing: 12.s) {
                HStack {
                    BackChip { SpeechCoach.shared.cancel(); Speaker.shared.stop(); close() }
                    Spacer()
                    Text(jp(StudyMode.speak.title)).font(.display(20.s)).foregroundStyle(Color.ink)
                    Spacer()
                    Text("\(min(i + 1, max(1, qs.count)))/\(max(1, qs.count))").font(.en(20.s)).foregroundStyle(Color.ink).frame(minWidth: 56.s)
                }
                .padding(.top, 6)
                if finished { result } else if let q { card(q) }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
        }
        .onAppear {
            qs = Array(StudyPool.sentences(app).filter { $0.full.split(separator: " ").count <= 9 }.shuffled().prefix(StudyMode.speak.count))
            if let q { later(0.4) { playThenListen(q) } }
        }
        .onDisappear { SpeechCoach.shared.cancel() }
    }

    private func card(_ q: Question) -> some View {
        PaperCard {
            VStack(spacing: 14.s) {
                Text(jp(q.meaning)).font(.ui(14.s, bold: false)).foregroundStyle(Color.ink.opacity(0.7)).multilineTextAlignment(.center)
                // the sentence; after speaking each word turns green (heard) or red (try again)
                WrapWords(words: chips(q))
                HStack(spacing: 10.s) {
                    smallButton("speaker.wave.2.fill", T("お手本", "본보기", "示範")) { Speaker.shared.say(q.full, gender: AppState.shared.settings.studyGender) }
                    smallButton("tortoise.fill", T("ゆっくり", "천천히", "慢速")) { Speaker.shared.say(q.full, slow: true, gender: AppState.shared.settings.studyGender) }
                }
                HStack(spacing: 8.s) {
                    modeChip(T("手動", "수동", "手動"), on: !auto) { auto = false; SpeechCoach.shared.cancel() }
                    modeChip(T("自動", "자동", "自動"), on: auto) { auto = true; if marks.isEmpty { playThenListen(q) } }
                }
                MicButton { heard in judge(q, heard) }
                MicStatus(hint: marks.isEmpty ? T("マイクを|押して、|英文を|読んでね", "마이크를 누르고 영어 문장을 읽어 주세요", "按下麥克風，念出英文句子") : feedback)
                if !marks.isEmpty {
                    let sc = SpeechMatch.score(marks)
                    OutlinedText("\(sc)" + T("点", "점", "分"), font: .display(30.s), fill: sc >= 80 ? .sun : sc >= 50 ? Color(hex: 0xBFE9FF) : Color(hex: 0xFFB3CF), width: 3, shadow: 2)
                    HStack(spacing: 10.s) {
                        if sc < 100 && tries < 3 {
                            PopButton(title: T("もう一度", "다시 한 번", "再試一次"), color: .white, height: 46) { marks = []; playThenListen(q, slow: true) }
                        }
                        PopButton(title: T("つぎへ", "다음", "下一題"), color: .pop, textColor: .white, height: 46) { next() }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func modeChip(_ t: String, on: Bool, _ a: @escaping () -> Void) -> some View {
        Button { AudioManager.shared.se(.tap, rate: 1.3, volume: 0.4); a() } label: {
            Text(jp(t)).font(.ui(13.s)).foregroundStyle(on ? Color.white : Color.ink)
                .padding(.horizontal, 16.s).padding(.vertical, 6.s)
                .background(Capsule().fill(on ? Color.ink : Color.white).overlay(Capsule().stroke(Color.ink, lineWidth: 2)))
        }
        .buttonStyle(.plain)
    }

    /// play the model; in auto mode open the mic when it has finished
    private func playThenListen(_ q: Question, slow: Bool = false) {
        Speaker.shared.say(q.full, slow: slow, gender: AppState.shared.settings.studyGender)
        guard auto else { return }
        let at = i, t = tries
        let wait = (0.9 + Double(q.full.split(separator: " ").count) * 0.42) * (slow ? 1.45 : 1)
        later(wait) {
            guard auto, at == i, t == tries, marks.isEmpty, !finished else { return }
            SpeechCoach.shared.start { heard in judge(q, heard) }
        }
    }

    private func chips(_ q: Question) -> [(String, Bool?)] {
        if marks.isEmpty { return q.full.split(separator: " ").map { (String($0), Bool?.none) } }
        return marks.map { ($0.word, Bool?.some($0.ok)) }
    }

    private var feedback: String {
        let bad = marks.filter { !$0.ok }.map(\.word)
        if bad.isEmpty { return T("ぜんぶ|通じたよ！", "전부 통했어!", "全部聽懂了！") }
        return T("赤い|単語を|お手本で|確かめよう", "빨간 단어를 본보기로 확인해 보자", "用示範確認紅色的單字") + "\n" + bad.prefix(4).joined(separator: " / ")
    }

    private func judge(_ q: Question, _ heard: String) {
        marks = SpeechMatch.marks(target: q.full, heard: heard)
        tries += 1
        let sc = SpeechMatch.score(marks)
        AudioManager.shared.se(sc >= 80 ? .studyOK : .studyNG, volume: 0.8)
        app.study.answered(correct: sc >= 80)
        app.study.track(q, skill: "speaking", correct: sc >= 80)
        if sc < 60 { app.study.recordMiss(q) }
        if auto && sc >= 80 {
            let at = i
            later(1.8) { if auto && at == i && !finished { next() } }
        }
    }

    private func next() {
        best.append(SpeechMatch.score(marks))
        marks = []; tries = 0
        i += 1
        if i >= qs.count {
            finished = true
            app.study.finish(.speak)
            app.save()
            AudioManager.shared.se(.studyClear)
        } else if let q { playThenListen(q) }
    }

    private var result: some View {
        let avg = best.isEmpty ? 0 : best.reduce(0, +) / best.count
        return PaperCard {
            VStack(spacing: 12.s) {
                Image("nyan").resizable().scaledToFit().frame(height: 90.s)
                OutlinedText(T("平均", "평균", "平均") + " \(avg)" + T("点", "점", "分"), font: .display(30.s), fill: .sun, width: 3, shadow: 2)
                Text(jp(avg >= 80 ? T("はっきり|通じる|発音だよ！", "또렷하게 통하는 발음이야!", "發音很清楚，對方聽得懂！")
                        : T("赤かった|単語を|お手本で|くり返そう", "빨갛던 단어를 본보기로 반복해 보자", "跟著示範多念幾次紅色的單字")))
                    .font(.ui(14.s)).foregroundStyle(Color.ink).multilineTextAlignment(.center)
                PopButton(title: T("おわる", "끝내기", "結束"), color: .pop, textColor: .white) { close() }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func smallButton(_ icon: String, _ t: String, _ a: @escaping () -> Void) -> some View {
        Button { AudioManager.shared.se(.tap); a() } label: {
            HStack(spacing: 4) { Image(systemName: icon); Text(jp(t)) }
                .font(.ui(13.s)).foregroundStyle(Color.ink)
                .padding(.horizontal, 14.s).padding(.vertical, 8.s)
                .background(Capsule().fill(Color.white).overlay(Capsule().stroke(Color.ink, lineWidth: 2.5)))
        }
        .buttonStyle(PressStyle(radius: 30, depth: 3))
    }
}

/// The sentence as word chips (nil = not judged yet, true = heard, false = not heard).
struct WrapWords: View {
    var words: [(String, Bool?)]
    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(words.indices, id: \.self) { k in
                let (w, ok) = words[k]
                Text(w).font(.en(22.s)).foregroundStyle(Color.ink)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 8).fill(ok == nil ? Color.clear : ok! ? Color(hex: 0xB8F0C8) : Color(hex: 0xFFC2CF)))
            }
        }
    }
}

/// Simple wrapping row layout.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let w = proposal.width ?? 320
        var x: CGFloat = 0, y: CGFloat = 0, row: CGFloat = 0, maxX: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x > 0 && x + sz.width > w { y += row + spacing; x = 0; row = 0 }
            x += sz.width + spacing; row = max(row, sz.height); maxX = max(maxX, x)
        }
        return CGSize(width: min(w, maxX), height: y + row)
    }
    func placeSubviews(in b: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        // centre each row
        var rows: [[(Int, CGSize)]] = [[]]
        var x: CGFloat = 0
        for (i, s) in subviews.enumerated() {
            let sz = s.sizeThatFits(.unspecified)
            if x > 0 && x + sz.width > b.width { rows.append([]); x = 0 }
            rows[rows.count - 1].append((i, sz)); x += sz.width + spacing
        }
        var y = b.minY
        for r in rows {
            let rw = r.map(\.1.width).reduce(0, +) + spacing * CGFloat(max(0, r.count - 1))
            var cx = b.minX + (b.width - rw) / 2
            let rh = r.map(\.1.height).max() ?? 0
            for (i, sz) in r {
                subviews[i].place(at: CGPoint(x: cx, y: y + (rh - sz.height) / 2), proposal: ProposedViewSize(sz))
                cx += sz.width + spacing
            }
            y += rh + spacing
        }
    }
}

// MARK: - Sounds that are hard for Japanese / Korean / Chinese speakers

struct SoundPair: Identifiable {
    let id: String
    let title: String
    let tip: String
    let pairs: [(String, String)]

    static var all: [SoundPair] { [
        SoundPair(id: "lr", title: "L / R",
                  tip: T("L は舌先を|上の歯の裏に|つける。|R は舌を|どこにも|つけずに|奥へ丸める。",
                         "L은 혀끝을 윗니 뒤에 붙이고, R은 혀를 어디에도 붙이지 않고 안쪽으로 만다.",
                         "L要把舌尖頂在上排牙齒後面；R舌頭不碰任何地方，往後捲。"),
                  pairs: [("light", "right"), ("play", "pray"), ("glass", "grass"), ("lice", "rice"), ("collect", "correct"), ("fly", "fry")]),
        SoundPair(id: "th", title: "TH / S",
                  tip: T("TH は舌先を|上下の歯で|軽くはさんで|息を出す。|S は舌を|歯の裏に|近づけるだけ。",
                         "TH는 혀끝을 윗니와 아랫니 사이에 살짝 물고 숨을 내보낸다. S는 혀를 이 뒤에 가까이 둘 뿐.",
                         "TH要用上下牙輕咬舌尖再送氣；S只要把舌頭靠近牙齒後面。"),
                  pairs: [("think", "sink"), ("thank", "sank"), ("mouth", "mouse"), ("path", "pass"), ("thick", "sick"), ("thumb", "sum")]),
        SoundPair(id: "vb", title: "V / B",
                  tip: T("V は上の歯を|下くちびるに|当てて|震わせる。|B は両くちびるを|閉じてから|はじく。",
                         "V는 윗니를 아랫입술에 대고 떨리게 한다. B는 두 입술을 닫았다가 터뜨린다.",
                         "V把上排牙齒碰下唇並振動；B先閉上雙唇再彈開。"),
                  pairs: [("vest", "best"), ("very", "berry"), ("vote", "boat"), ("van", "ban"), ("curve", "curb")]),
        SoundPair(id: "fh", title: "F / H",
                  tip: T("F は上の歯を|下くちびるに|当てて|息を出す。|H は口を開けて|のどから|息を出す。",
                         "F는 윗니를 아랫입술에 대고 숨을 내보낸다. H는 입을 벌리고 목에서 숨을 내보낸다.",
                         "F把上排牙齒碰下唇送氣；H張開嘴從喉嚨送氣。"),
                  pairs: [("fat", "hat"), ("fold", "hold"), ("feel", "heel"), ("fair", "hair"), ("fire", "hire")]),
        SoundPair(id: "pf", title: "P / F",
                  tip: T("P は両くちびるで|はじく。|F は上の歯を|下くちびるに|当てる。",
                         "P는 두 입술로 터뜨린다. F는 윗니를 아랫입술에 댄다.",
                         "P用雙唇彈出；F把上排牙齒碰下唇。"),
                  pairs: [("pan", "fan"), ("pork", "fork"), ("pool", "fool"), ("pine", "fine"), ("copy", "coffee")]),
        SoundPair(id: "ii", title: "ship / sheep",
                  tip: T("短い i は|力を抜いて|短く「イ」。|長い ee は|口を横に引いて|「イー」。",
                         "짧은 i는 힘을 빼고 짧게 「이」, 긴 ee는 입을 옆으로 당겨 「이—」.",
                         "短的i放鬆短短地發「一」；長的ee把嘴角往兩邊拉，發「一—」。"),
                  pairs: [("ship", "sheep"), ("live", "leave"), ("sit", "seat"), ("fill", "feel"), ("hit", "heat")]),
        SoundPair(id: "ae", title: "hat / hut",
                  tip: T("a（hat）は|口を横に大きく|「エア」。|u（hut）は|口を小さく|あいまいな「ア」。",
                         "a(hat)는 입을 옆으로 크게 「애아」, u(hut)는 입을 작게 애매한 「어」.",
                         "a（hat）嘴巴往兩邊大開發「欸啊」；u（hut）嘴巴小小地發模糊的「阿」。"),
                  pairs: [("hat", "hut"), ("cap", "cup"), ("bag", "bug"), ("cat", "cut"), ("match", "much")]),
        SoundPair(id: "nl", title: "N / L",
                  tip: T("N は鼻から|息を出す。|L は鼻を使わず|舌の横から|息を出す。",
                         "N은 코로 숨을 내보낸다. L은 코를 쓰지 않고 혀 옆으로 숨을 내보낸다.",
                         "N從鼻子出氣；L不用鼻子，從舌頭兩側出氣。"),
                  pairs: [("night", "light"), ("nap", "lap"), ("know", "low"), ("net", "let"), ("not", "lot")]),
        SoundPair(id: "ssh", title: "S / SH",
                  tip: T("S は|歯のすき間から|「スー」。|SH は|くちびるを|丸く突き出して|「シュー」。",
                         "S는 이 사이로 「스—」, SH는 입술을 둥글게 내밀고 「슈—」.",
                         "S從牙縫發「嘶」；SH把嘴唇圓圓地往前噘，發「噓」。"),
                  pairs: [("see", "she"), ("sip", "ship"), ("seat", "sheet"), ("sort", "short"), ("sell", "shell")]),
        SoundPair(id: "chsh", title: "CH / SH",
                  tip: T("CH は|舌を上につけて|一気にはなす|「チッ」。|SH は|舌をつけずに|息を流す|「シュー」。",
                         "CH는 혀를 위에 붙였다가 한 번에 떼는 「치」, SH는 혀를 붙이지 않고 숨을 흘리는 「슈—」.",
                         "CH舌頭先頂住上面再一口氣放開發「吃」；SH舌頭不碰，讓氣流出發「噓」。"),
                  pairs: [("chair", "share"), ("cheap", "sheep"), ("watch", "wash"), ("chop", "shop"), ("catch", "cash")]),
        SoundPair(id: "dth", title: "D / TH",
                  tip: T("D は|舌先を|歯ぐきに当てて|はじく。|TH（this）は|舌先を|歯ではさんで|声を出す。",
                         "D는 혀끝을 잇몸에 댔다가 튕긴다. TH(this)는 혀끝을 이로 물고 소리를 낸다.",
                         "D舌尖碰牙齦再彈開；TH（this）用牙齒輕咬舌尖發聲。"),
                  pairs: [("day", "they"), ("den", "then"), ("dare", "there"), ("doze", "those"), ("udder", "other")]),
        SoundPair(id: "zth", title: "Z / TH",
                  tip: T("Z は|舌を歯につけずに|「ズー」と|ふるわせる。|TH は|舌先を|歯ではさむ。",
                         "Z는 혀를 이에 대지 않고 「즈—」 떨리게, TH는 혀끝을 이로 문다.",
                         "Z舌頭不碰牙齒，振動發「茲」；TH用牙齒輕咬舌尖。"),
                  pairs: [("breeze", "breathe"), ("closing", "clothing"), ("zen", "then"), ("bays", "bathe"), ("tease", "teethe")]),
        SoundPair(id: "nng", title: "N / NG",
                  tip: T("N は|舌先を|上の歯ぐきにつける。|NG は|舌の奥を|上あごにつけて|鼻に響かせる。",
                         "N은 혀끝을 윗잇몸에 대고, NG는 혀 안쪽을 입천장에 대고 코로 울린다.",
                         "N舌尖頂住上牙齦；NG舌根貼住上顎，讓聲音在鼻腔共鳴。"),
                  pairs: [("thin", "thing"), ("ran", "rang"), ("sin", "sing"), ("win", "wing"), ("ban", "bang")]),
        SoundPair(id: "eae", title: "bed / bad",
                  tip: T("e（bed）は|日本語の|「エ」に近い。|a（bad）は|口を大きく横に開いて|「エア」。",
                         "e(bed)는 「에」에 가깝고, a(bad)는 입을 옆으로 크게 벌려 「애아」.",
                         "e（bed）接近「欸」；a（bad）嘴巴往兩邊大開發「欸啊」。"),
                  pairs: [("bed", "bad"), ("pen", "pan"), ("men", "man"), ("said", "sad"), ("met", "mat")]),
        SoundPair(id: "erar", title: "hurt / heart",
                  tip: T("ER（hurt）は|口をあまり開けず|舌を丸めて|「アー」。|AR（heart）は|口を大きく開けて|「アー」。",
                         "ER(hurt)는 입을 많이 벌리지 않고 혀를 말아 「어—」, AR(heart)는 입을 크게 벌려 「아—」.",
                         "ER（hurt）嘴巴不要張太大，捲舌發「兒」；AR（heart）嘴巴張大發「啊」。"),
                  pairs: [("hurt", "heart"), ("fur", "far"), ("stir", "star"), ("perk", "park"), ("burn", "barn")]),
        SoundPair(id: "oou", title: "cost / coast",
                  tip: T("o（cost）は|口を縦に開いて|短く「ア」。|oa（coast）は|「オウ」と|くちびるを|すぼめていく。",
                         "o(cost)는 입을 세로로 벌려 짧게 「아」, oa(coast)는 「오우」 하고 입술을 오므린다.",
                         "o（cost）嘴巴直直張開短短發「阿」；oa（coast）發「歐」並慢慢把嘴唇收圓。"),
                  pairs: [("cost", "coast"), ("not", "note"), ("got", "goat"), ("want", "won't"), ("walk", "woke")]),
        SoundPair(id: "uuu", title: "full / fool",
                  tip: T("u（full）は|力を抜いて|短く「ウ」。|oo（fool）は|くちびるを|丸く突き出して|「ウー」。",
                         "u(full)는 힘을 빼고 짧게 「우」, oo(fool)는 입술을 둥글게 내밀고 「우—」.",
                         "u（full）放鬆短短發「烏」；oo（fool）嘴唇圓圓往前噘發「烏—」。"),
                  pairs: [("full", "fool"), ("pull", "pool"), ("look", "Luke"), ("could", "cooed"), ("soot", "suit")]),
        SoundPair(id: "tth", title: "T / TH",
                  tip: T("T は|舌先を|歯ぐきに|つけて|はじく。|TH は|舌先を|上下の歯で|軽くはさんで|息を出す。",
                         "T는 혀끝을 잇몸에 붙였다 튕기고, TH는 혀끝을 윗니와 아랫니 사이에 살짝 물고 숨을 내보낸다.",
                         "T 是舌尖頂住牙齦再彈開；TH 是舌尖輕輕夾在上下牙齒之間送氣。"),
                  pairs: [("tank", "thank"), ("tree", "three"), ("team", "theme"), ("tin", "thin"), ("true", "through")]),
        SoundPair(id: "year", title: "year / ear",
                  tip: T("year は|「イ」の前に|舌を|上あごに|近づけて|「ィヤ」と|始める。|ear は|そのまま|「イア」。",
                         "year는 「이」 앞에서 혀를 입천장에 가까이 대고 「이야」처럼 시작하고, ear는 그냥 「이어」.",
                         "year 要在「伊」前把舌頭靠近上顎，像「伊呀」開頭；ear 直接發「伊兒」。"),
                  pairs: [("year", "ear"), ("yeast", "east"), ("yearn", "earn"), ("yeah", "air"), ("Yale", "ale")]),
        SoundPair(id: "walk", title: "walk / work",
                  tip: T("walk は|口を|縦に|大きく開いて|「ウォーク」。|work は|口を|あまり開けず、|舌を|丸めて|「ワーク」。",
                         "walk는 입을 세로로 크게 벌려 「워-크」, work는 입을 크게 벌리지 않고 혀를 말아 「워r-크」.",
                         "walk 嘴巴直直張大發「沃克」；work 嘴巴不要張太開，舌頭捲起發「渥克」。"),
                  pairs: [("walk", "work"), ("ward", "word"), ("warm", "worm"), ("born", "burn"), ("short", "shirt")]),
        SoundPair(id: "mn", title: "M / N",
                  tip: T("語尾の|M は|くちびるを|しっかり|閉じる。|N は|口を|少し開けたまま、|舌先を|歯ぐきに|つける。",
                         "끝소리 M은 입술을 꼭 다물고, N은 입을 조금 연 채 혀끝을 잇몸에 붙인다.",
                         "字尾的 M 要緊閉雙唇；N 嘴巴微開，舌尖頂住牙齦。"),
                  pairs: [("some", "sun"), ("team", "teen"), ("gum", "gun"), ("Tom", "ton"), ("seem", "seen")]),
        SoundPair(id: "ball", title: "ball / bowl",
                  tip: T("ball は|口を|縦に開いて|のばす|「オー」。|bowl は|「オウ」と|くちびるを|すぼめていく。",
                         "ball은 입을 세로로 벌려 길게 「오-」, bowl은 「오우」 하고 입술을 오므린다.",
                         "ball 嘴巴直直張開拉長發「喔—」；bowl 發「歐」並慢慢把嘴唇收圓。"),
                  pairs: [("ball", "bowl"), ("call", "coal"), ("law", "low"), ("saw", "sew"), ("bought", "boat")]),
        SoundPair(id: "bird", title: "bird / bud",
                  tip: T("bird は|舌を|丸めたまま|「アー」と|のばす。|bud は|短く|あいまいな|「ア」。",
                         "bird는 혀를 만 채 「어r-」 하고 길게, bud는 짧고 애매한 「어」.",
                         "bird 舌頭捲著拉長發「兒—」；bud 是短而含糊的「阿」。"),
                  pairs: [("bird", "bud"), ("girl", "gull"), ("hurt", "hut"), ("turn", "ton"), ("first", "fussed")]),
        SoundPair(id: "cap", title: "cap / cop",
                  tip: T("a（cap）は|「エ」の口で|「ア」と言う。|o（cop）は|口を|縦に|大きく開けて|「ア」。",
                         "a(cap)는 「에」 입 모양으로 「애」, o(cop)는 입을 세로로 크게 벌려 「아」.",
                         "a（cap）用「欸」的嘴型發「啊」；o（cop）嘴巴直直張大發「阿」。"),
                  pairs: [("cap", "cop"), ("hat", "hot"), ("map", "mop"), ("black", "block"), ("sack", "sock")]),
    ] }
}

/// Pick a sound, then say one word of each pair; the recogniser tells which one it heard.
struct SoundsView: View {
    var close: () -> Void
    @EnvironmentObject var app: AppState
    @State private var pick: SoundPair?
    @State private var k = 0
    @State private var sayFirst = true
    @State private var verdict: (ok: Bool, text: String)?
    @State private var right = 0

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            PopBackdrop(base: StudyMode.sounds.color.opacity(0.7))
            VStack(spacing: 12.s) {
                HStack {
                    BackChip { SpeechCoach.shared.cancel(); if pick != nil { pick = nil } else { close() } }
                    Spacer()
                    Text(jp(StudyMode.sounds.title)).font(.display(20.s)).foregroundStyle(Color.ink)
                    Spacer()
                    Color.clear.frame(width: 56.s, height: 1)
                }
                .padding(.top, 6)
                ScrollView { if let pick { practice(pick) } else { menu } }
            }
            .padding(.horizontal, 16)
        }
        .onDisappear { SpeechCoach.shared.cancel() }
    }

    private var menu: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10.s), GridItem(.flexible(), spacing: 10.s)], spacing: 10.s) {
            ForEach(SoundPair.all) { s in
                Button { AudioManager.shared.se(.decide); pick = s; k = 0; right = 0; verdict = nil; sayFirst = Bool.random() } label: {
                    VStack(spacing: 4.s) {
                        Text(s.title).font(.en(20.s))
                        Text(s.pairs.prefix(2).map { "\($0.0) / \($0.1)" }.joined(separator: "\n")).font(.en(12.s)).opacity(0.7)
                        if let b = app.study.best["snd." + s.id] { Text("BEST \(b)/\(s.pairs.count)").font(.en(11.s)) }
                    }
                    .foregroundStyle(Color.ink).frame(maxWidth: .infinity, minHeight: 92.s)
                    .background(RoundedRectangle(cornerRadius: 16.s).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 16.s).stroke(Color.ink, lineWidth: 2.5)))
                }
                .buttonStyle(PressStyle(radius: 16.s, depth: 4))
            }
        }
        .padding(.top, 6)
    }

    private func practice(_ s: SoundPair) -> some View {
        let done = k >= s.pairs.count
        let pair = s.pairs[min(k, s.pairs.count - 1)]
        let target = sayFirst ? pair.0 : pair.1, other = sayFirst ? pair.1 : pair.0
        return PaperCard {
            VStack(spacing: 12.s) {
                Text(jp(s.tip)).font(.ui(13.s, bold: false)).foregroundStyle(Color.ink.opacity(0.75)).multilineTextAlignment(.center)
                if done {
                    OutlinedText("\(right) / \(s.pairs.count)", font: .display(34.s), fill: .sun, width: 3, shadow: 2)
                    PopButton(title: T("もう一度", "다시 한 번", "再試一次"), color: .white, height: 46) { k = 0; right = 0; verdict = nil; sayFirst = Bool.random() }
                    PopButton(title: T("ほかの音", "다른 소리", "其他的音"), color: .pop, textColor: .white, height: 46) { pick = nil }
                } else {
                    HStack(spacing: 14.s) {
                        wordCard(pair.0, target == pair.0)
                        wordCard(pair.1, target == pair.1)
                    }
                    Text(jp(T("黄色い|単語を|言ってみよう", "노란 단어를 말해 보자", "念出黃色的單字"))).font(.ui(13.s)).foregroundStyle(Color.ink)
                    MicButton { heard in judge(heard, target, other) }
                    MicStatus(hint: T("マイクを|押して|話してね", "마이크를 누르고 말해 주세요", "按下麥克風說話"))
                    if let v = verdict {
                        Text(jp(v.text)).font(.ui(15.s)).foregroundStyle(v.ok ? Color(hex: 0x1F9D55) : Color.popDeep).multilineTextAlignment(.center)
                        PopButton(title: T("つぎへ", "다음", "下一題"), color: .pop, textColor: .white, height: 46) {
                            verdict = nil; k += 1; sayFirst = Bool.random()
                            if k >= s.pairs.count {
                                let key = "snd." + s.id
                                app.study.best[key] = max(app.study.best[key] ?? 0, right)
                                app.study.finish(.sounds); app.save()
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func wordCard(_ w: String, _ target: Bool) -> some View {
        Button { Speaker.shared.say(w, slow: true, gender: AppState.shared.settings.wordGender) } label: {
            VStack(spacing: 2) {
                Text(w).font(.en(26.s)).foregroundStyle(Color.ink)
                Image(systemName: "speaker.wave.2.fill").font(.system(size: 13.s)).foregroundStyle(Color.ink.opacity(0.6))
            }
            .frame(maxWidth: .infinity, minHeight: 84.s)
            .background(RoundedRectangle(cornerRadius: 16.s).fill(target ? Color.sun : Color.white).overlay(RoundedRectangle(cornerRadius: 16.s).stroke(Color.ink, lineWidth: target ? 3.5 : 2)))
        }
        .buttonStyle(PressStyle(radius: 16.s, depth: 3))
    }

    private func judge(_ heard: String, _ target: String, _ other: String) {
        let hitT = SpeechMatch.contains(heard, target), hitO = SpeechMatch.contains(heard, other)
        if hitT && !hitO {
            right += 1
            verdict = (true, T("できた！|「", "성공! 「", "成功！「", vi: "Tốt lắm! Nghe rõ “", es: "¡Bien! Se oyó “", pt: "Boa! Deu para ouvir “", en: "Nice! I heard “") + target + T("」と|聞こえたよ", "」로 들렸어", "」聽起來很清楚", vi: "”", es: "”.", pt: "”.", en: "”."))
            AudioManager.shared.se(.studyOK)
        } else if hitO {
            verdict = (false, T("「", "「", "「", vi: "Nghe giống “", es: "Sonó como “", pt: "Pareceu “", en: "It sounded like “") + other + T("」に|聞こえたよ。|コツを見て|もう一度！", "」로 들렸어. 요령을 보고 다시!", "」。看看訣竅再試一次！", vi: "”. Xem mẹo rồi thử lại!", es: "”. ¡Mira el truco e inténtalo otra vez!", pt: "”. Veja a dica e tente de novo!", en: "”. Check the tip and try again!"))
            AudioManager.shared.se(.studyNG, volume: 0.8)
        } else {
            verdict = (false, (heard.isEmpty ? T("聞き取れなかったよ", "알아듣지 못했어", "沒有聽清楚") : "“\(heard)”") + "\n" + T("お手本を|聞いてから|もう一度", "본보기를 듣고 다시", "聽示範後再試一次", vi: "Nghe mẫu rồi thử lại", es: "Escucha el ejemplo y repite", pt: "Ouça o exemplo e repita", en: "Listen to the model and try again"))
            AudioManager.shared.se(.studyNG, volume: 0.8)
        }
        app.study.answered(correct: hitT && !hitO)
        var sk = app.study.skills["speaking"] ?? [0, 0]; sk[1] += 1; if hitT && !hitO { sk[0] += 1 }; app.study.skills["speaking"] = sk
    }
}
