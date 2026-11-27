import SwiftUI
import Combine

// MARK: - まなぶ：トレーニング と しけん（にゃんグリッシュの勉強モードと同じ ボリューム）
// かきとり／ならべかえ／リスニング／にがて音／にがて復習／60びょう／JLPT N5 もんだい／JLPT N5 もし

enum KJTrainMode: String, CaseIterable, Identifiable {
    case dictation, order, listening, speak, sounds, review, flash, jlpt, mock
    var id: String { rawValue }
    static let training: [KJTrainMode] = [.dictation, .order, .listening, .speak, .sounds, .review, .flash]
    static let exams: [KJTrainMode] = [.jlpt, .mock]

    var ja: String {
        switch self {
        case .dictation: "かきとり"
        case .order: "ならべかえ"
        case .listening: "リスニング"
        case .speak: "はつおん"
        case .sounds: "にがて音"
        case .review: "にがて ふくしゅう"
        case .flash: "60びょう チャレンジ"
        case .jlpt: "JLPT N5 もんだい"
        case .mock: "JLPT N5 もし"
        }
    }
    var sub: String {
        switch self {
        case .dictation: KJ.t("Hear a word, spell it in kana", "聽單字，用假名拼出來", "듣고 가나로 쓰기")
        case .order: KJ.t("Put the words in the right order", "把詞語排成正確的句子", "단어를 바른 순서로")
        case .listening: KJ.t("Hear a sentence, pick its meaning", "聽句子，選意思", "문장을 듣고 뜻 고르기")
        case .speak: KJ.t("Say it out loud — is it understood?", "唸出來，聽得懂嗎？", "소리 내어 말해요 — 통할까?")
        case .sounds: KJ.t("Long vowels, small っ, きゃ/きや…", "長音、促音、拗音……", "장음·촉음·요음 구별")
        case .review: KJ.t("The letters and words you missed", "再練習答錯的字和詞", "틀린 글자와 단어 복습")
        case .flash: KJ.t("How many in 60 seconds?", "60秒能答幾題？", "60초에 몇 문제?")
        case .jlpt: KJ.t("10 JLPT-style questions", "JLPT形式10題", "JLPT 형식 10문제")
        case .mock: KJ.t("30 questions · 10 minutes · score", "30題・10分鐘・估分", "30문제·10분·점수")
        }
    }
    var icon: String {
        switch self {
        case .dictation: "pencil.and.scribble"
        case .order: "square.grid.3x1.below.line.grid.1x2"
        case .listening: "ear.fill"
        case .speak: "mic.fill"
        case .sounds: "mouth.fill"
        case .review: "arrow.counterclockwise.circle.fill"
        case .flash: "bolt.fill"
        case .jlpt: "doc.text.fill"
        case .mock: "timer"
        }
    }
    var color: Color {
        switch self {
        case .dictation: Color(hex: 0xFFD1E3)
        case .order: Color(hex: 0xFFE9A8)
        case .listening: Color(hex: 0xBFE6FF)
        case .speak: Color(hex: 0xFFF0B3)
        case .sounds: Color(hex: 0xD9F7E3)
        case .review: Color(hex: 0xE6DCFF)
        case .flash: Color(hex: 0xFFD8B8)
        case .jlpt: Color(hex: 0xCFF3FF)
        case .mock: Color(hex: 0xFFE0E0)
        }
    }
    var bgm: String { switch self { case .flash, .review: "study_a"; case .dictation, .listening, .sounds, .speak: "study_c"; case .order: "study_b"; case .jlpt, .mock: "study_jlpt" } }

    // records
    var best: Int { UserDefaults.standard.integer(forKey: "kj.train.best.\(rawValue)") }
    func record(_ v: Int) { if v > best { UserDefaults.standard.set(v, forKey: "kj.train.best.\(rawValue)") } }
    static var totalCorrect: Int {
        get { UserDefaults.standard.integer(forKey: "kj.train.correct") }
        set { UserDefaults.standard.set(newValue, forKey: "kj.train.correct") }
    }
}

/// one question of any training mode
struct KJTQ: Identifiable {
    let id = UUID()
    var head: String            // what to do
    var prompt: String          // big text ("" = listen only)
    var note: String = ""       // small text under the prompt
    var audio: String = ""      // spoken when it appears (and with the speaker button)
    var choices: [String] = []
    var answer = 0
    var tiles: [String] = []    // ならべかえ / かきとり: tap these in order
    var want: [String] = []
    var explain = ""
    var key = ""                // for にがて
    var speak = false           // はつおん: answer by voice
}

struct KJTrainView: View {
    let mode: KJTrainMode
    var back: () -> Void
    /// a sentence stage on the map: only sentences of this level, and the stars go back to the stage
    var level: Int? = nil
    var stageDone: ((_ stars: Int, _ score: Int) -> Void)? = nil

    @State private var qs: [KJTQ] = []
    @State private var i = 0
    @State private var picked: Int?
    @State private var built: [Int] = []        // tile indexes tapped
    @State private var right = 0
    @State private var done = false
    @State private var mark: Bool?
    @State private var timeLeft: Double = 0
    @State private var clock = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    private var timed: Bool { mode == .flash || mode == .mock }
    private var q: KJTQ? { qs[safe: i] }

    var body: some View {
        ZStack {
            KJBackdrop(bg: "bg_mg_dojo", dim: 0.55)
            VStack(spacing: 10.s) {
                if stageDone == nil {
                    HStack {
                        BackChip { back() }
                        Spacer()
                        KJSlowButton()
                    }
                    .padding(.horizontal, 14.s).padding(.top, 6.s)
                } else {
                    // on the map the stage screen has its own back button
                    Color.clear.frame(height: 50.s)
                }
                if done { result } else if let q { board(q) } else if !qs.isEmpty || stageDone != nil {
                    // no question could be made: never leave an empty screen
                    Color.clear.onAppear { if qs.isEmpty, let d = stageDone { d(3, 0) } }
                }
            }
            if let m = mark {
                Image(systemName: m ? "circle" : "xmark")
                    .font(.system(size: 150.s, weight: .black))
                    .foregroundStyle(m ? Color.danger : Color.sky)
                    .shadow(color: .white, radius: 6)
                    .transition(.scale(scale: 1.6).combined(with: .opacity))
                    .allowsHitTesting(false)
            }
        }
        .onAppear { start() }
        .onDisappear { SpeechCoach.shared.cancel() }
        .onReceive(clock) { _ in tick() }
    }

    // MARK: board

    private func board(_ q: KJTQ) -> some View {
        VStack(spacing: 12.s) {
            // progress / timer
            HStack {
                Text(mode.ja).font(.custom(Fonts.rounded, size: 15.s)).foregroundStyle(.white)
                Spacer()
                if timed {
                    Label("\(Int(timeLeft.rounded(.up)))", systemImage: "timer").font(.display(18.s))
                        .foregroundStyle(timeLeft <= 10 ? Color.danger : .white)
                }
                Text(mode == .flash ? "✔︎ \(right)" : "\(i + 1) / \(qs.count)").font(.display(16.s)).foregroundStyle(.white)
            }
            .padding(.horizontal, 18.s)
            PaperCard {
                VStack(spacing: 10.s) {
                    KJPic.text(q.head, size: 13.s).font(.ui(13.s)).foregroundStyle(Color.ink.opacity(0.7)).multilineTextAlignment(.center)
                    if !q.prompt.isEmpty {
                        KJPic.text(q.prompt, size: q.prompt.count > 14 ? 20.s : 28.s).font(.custom(Fonts.rounded, size: q.prompt.count > 14 ? 20.s : 28.s)).foregroundStyle(Color.ink)
                            .multilineTextAlignment(.center).minimumScaleFactor(0.5)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if !q.note.isEmpty {
                        KJPic.text(q.note, size: 14.s).font(.ui(14.s, bold: false)).foregroundStyle(Color.ink.opacity(0.75)).multilineTextAlignment(.center)
                    }
                    if !q.audio.isEmpty {
                        Button { Speaker.shared.say(q.audio) } label: {
                            Image(systemName: "speaker.wave.3.fill").font(.system(size: 24.s, weight: .bold)).foregroundStyle(.white)
                                .frame(width: 60.s, height: 60.s)
                                .background(Circle().fill(Color.sky).overlay(Circle().stroke(Color.ink, lineWidth: 3)))
                        }
                        .buttonStyle(PressStyle(radius: 30.s, depth: 4))
                    }
                    if picked != nil && !q.explain.isEmpty {
                        KJPic.text(q.explain, size: 13.s).font(.ui(13.s, bold: false)).foregroundStyle(Color.popDeep).multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16.s)
            Spacer(minLength: 0)
            if q.speak { mic(q) } else if q.tiles.isEmpty { choices(q) } else { tiles(q) }
            Spacer(minLength: 8.s)
        }
    }

    private func choices(_ q: KJTQ) -> some View {
        let two = q.choices.count <= 2
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10.s), count: two ? 2 : (q.choices.map(\.count).max() ?? 0) > 9 ? 1 : 2), spacing: 10.s) {
            ForEach(Array(q.choices.enumerated()), id: \.offset) { k, c in
                let isRight = picked != nil && k == q.answer
                let isWrong = picked == k && k != q.answer
                Button { choose(k) } label: {
                    Text(c).font(.custom(Fonts.rounded, size: c.count > 12 ? 15.s : c.count > 6 ? 19.s : 24.s)).foregroundStyle(Color.ink)
                        .multilineTextAlignment(.center).lineLimit(3).minimumScaleFactor(0.5)
                        .padding(.horizontal, 8.s)
                        .frame(maxWidth: .infinity).frame(minHeight: two ? 90.s : 62.s)
                        .background(RoundedRectangle(cornerRadius: 16.s)
                            .fill(isRight ? Color(hex: 0xD9F7E3) : isWrong ? Color(hex: 0xFFD6D6) : Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 16.s).stroke(isRight ? Color.mintDeep : Color.ink, lineWidth: isRight ? 4 : 3)))
                }
                .buttonStyle(PressStyle(radius: 16.s, depth: 4))
                .disabled(picked != nil)
            }
        }
        .padding(.horizontal, 16.s)
    }

    private func tiles(_ q: KJTQ) -> some View {
        VStack(spacing: 12.s) {
            // what you built so far
            FlowRow(spacing: 6.s) {
                ForEach(Array(built.enumerated()), id: \.offset) { pos, t in
                    Button { if picked == nil { built.remove(at: pos) } } label: { tile(q.tiles[t], on: true) }.buttonStyle(.plain)
                }
                if built.count < q.want.count { tile("…", on: false) }
            }
            .frame(maxWidth: .infinity, minHeight: 50.s)
            .padding(10.s)
            .background(RoundedRectangle(cornerRadius: 14.s).fill(Color.white.opacity(0.9)))
            .padding(.horizontal, 16.s)
            FlowRow(spacing: 8.s) {
                ForEach(Array(q.tiles.enumerated()), id: \.offset) { k, t in
                    Button {
                        guard picked == nil, !built.contains(k) else { return }
                        AudioManager.shared.se(.tap, rate: 1.3, volume: 0.5)
                        built.append(k)
                        if built.count == q.want.count { judgeTiles(q) }
                    } label: { tile(t, on: false).opacity(built.contains(k) ? 0.25 : 1) }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16.s)
            if picked == nil && !built.isEmpty {
                Button(KJ.both("Clear", "擦掉", "지우기")) { built = [] }
                    .font(.ui(13.s)).foregroundStyle(.white)
            }
        }
    }

    @ObservedObject private var coach = SpeechCoach.shared
    @State private var heard = ""

    private func mic(_ q: KJTQ) -> some View {
        VStack(spacing: 12.s) {
            if !heard.isEmpty || coach.state == .listening {
                Text(coach.state == .listening ? (coach.heard.isEmpty ? "…" : coach.heard) : "「\(heard)」")
                    .font(.ui(16.s)).foregroundStyle(.white).multilineTextAlignment(.center)
            }
            if coach.state == .denied || coach.state == .unavailable {
                Text(KJ.t("Allow the microphone and speech recognition in Settings.", "請在設定中允許麥克風和語音辨識。", "설정에서 마이크와 음성 인식을 허용해 주세요."))
                    .font(.ui(13.s)).foregroundStyle(.white).multilineTextAlignment(.center)
                KJButton(title: KJ.both("Skip", "略過", "건너뛰기"), color: .white) { judge(false, q) }
            }
            Button {
                guard picked == nil else { return }
                if coach.state == .listening { coach.stop(); return }
                heard = ""
                coach.start { text in
                    heard = text
                    guard picked == nil else { return }
                    picked = 0
                    judge(Self.sameSound(text, q.audio), q)
                }
            } label: {
                Image(systemName: coach.state == .listening ? "stop.fill" : "mic.fill").font(.system(size: 34.s, weight: .bold)).foregroundStyle(.white)
                    .frame(width: 96.s, height: 96.s)
                    .background(Circle().fill(coach.state == .listening ? Color.danger : Color.pop).overlay(Circle().stroke(Color.ink, lineWidth: 3)))
            }
            .buttonStyle(PressStyle(radius: 48.s, depth: 4))
            Text(coach.state == .listening ? KJ.t("Listening… say it now", "聆聽中……請說", "듣고 있어요… 말해요") : KJ.t("Tap and say it", "點一下再說", "누르고 말해요"))
                .font(.ui(13.s)).foregroundStyle(.white)
        }
    }

    /// heard vs wanted, compared by their sounds (romaji), so kanji in what was heard still counts
    static func sameSound(_ heard: String, _ want: String) -> Bool {
        let a = romaji(heard), b = romaji(want)
        guard !a.isEmpty, !b.isEmpty else { return false }
        if a.contains(b) { return true }
        let d = levenshtein(Array(a), Array(b))
        return Double(d) / Double(max(b.count, 1)) <= 0.25
    }

    static func romaji(_ s: String) -> String {
        let cf = s as CFString
        let tok = CFStringTokenizerCreate(nil, cf, CFRangeMake(0, CFStringGetLength(cf)), kCFStringTokenizerUnitWord, Locale(identifier: "ja") as CFLocale)
        var out = ""
        var t = CFStringTokenizerAdvanceToNextToken(tok)
        while !t.isEmpty {
            if let l = CFStringTokenizerCopyCurrentTokenAttribute(tok, kCFStringTokenizerAttributeLatinTranscription) as? String { out += l }
            t = CFStringTokenizerAdvanceToNextToken(tok)
        }
        return out.lowercased().filter { $0.isLetter }
    }

    static func levenshtein(_ a: [Character], _ b: [Character]) -> Int {
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }
        var prev = Array(0...b.count)
        for i in 1...a.count {
            var cur = [i] + Array(repeating: 0, count: b.count)
            for j in 1...b.count {
                cur[j] = min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1))
            }
            prev = cur
        }
        return prev[b.count]
    }

    private func tile(_ t: String, on: Bool) -> some View {
        Text(t).font(.custom(Fonts.rounded, size: 22.s)).foregroundStyle(Color.ink)
            .lineLimit(1).minimumScaleFactor(0.5)
            .padding(.horizontal, 12.s).frame(minWidth: 46.s, minHeight: 48.s)
            .background(RoundedRectangle(cornerRadius: 12.s).fill(on ? Color.sun : Color(hex: 0xFFF6E0)).overlay(RoundedRectangle(cornerRadius: 12.s).stroke(Color.ink, lineWidth: 2.5)))
    }

    // MARK: result

    private var score: Int {
        // mock: a JLPT-like scale out of 180 (80 = pass line)
        mode == .mock ? Int((Double(right) / Double(max(qs.count, 1)) * 180).rounded()) : right
    }

    private var result: some View {
        VStack(spacing: 14.s) {
            Spacer()
            Image(right * 10 >= max(qs.count, 1) * 7 || mode == .flash ? "nk_nyan_joy" : "nk_nyan_think").resizable().scaledToFit().frame(height: 150.s)
            if mode == .mock {
                OutlinedText("\(score) / 180", font: .display(48.s), fill: .sun, width: 4, shadow: 3)
                Text(score >= 80 ? KJ.t("Pass line cleared! (80+)", "超過及格線！（80分以上）", "합격선 돌파! (80점 이상)") : KJ.t("Pass line is 80. Keep going!", "及格線是80分，加油！", "합격선은 80점. 힘내요!"))
                    .font(.ui(16.s)).foregroundStyle(.white)
            } else {
                OutlinedText(mode == .flash ? "\(right)" : "\(right) / \(qs.count)", font: .display(52.s), fill: .sun, width: 4, shadow: 3)
            }
            Text(KJ.t("Best: ", "最佳：", "최고: ") + "\(mode.best)").font(.ui(14.s)).foregroundStyle(.white.opacity(0.85))
            KJButton(title: KJ.both("Again", "再一次", "다시"), color: .pop, textColor: .white) { start() }
            KJButton(title: KJ.both("Back", "返回", "돌아가기"), color: .white) { back() }
            Spacer()
        }
        .padding(.horizontal, 30.s)
    }

    // MARK: flow

    private func start() {
        AudioManager.shared.playBGM(.track(mode.bgm))
        qs = Self.build(mode, level: level)
        i = 0; right = 0; done = false; picked = nil; built = []
        timeLeft = mode == .flash ? 60 : mode == .mock ? 600 : 0
        present()
    }

    private func present() {
        picked = nil; built = []; heard = ""
        if let a = q?.audio, !a.isEmpty { later(0.35) { Speaker.shared.say(a) } }
    }

    private func tick() {
        guard timed, !done, timeLeft > 0 else { return }
        timeLeft -= 0.1
        if timeLeft <= 0 { finish() }
    }

    private func choose(_ k: Int) {
        guard picked == nil, let q else { return }
        picked = k
        judge(k == q.answer, q)
    }

    private func judgeTiles(_ q: KJTQ) {
        picked = 0
        judge(built.map { q.tiles[$0] } == q.want, q)
    }

    private func judge(_ ok: Bool, _ q: KJTQ) {
        if ok {
            right += 1
            KJTrainMode.totalCorrect += 1
            AudioManager.shared.se(.studyOK)
            if !q.key.isEmpty { KJWeak.hit(q.key) }
        } else {
            AudioManager.shared.se(.studyNG)
            if !q.key.isEmpty { KJWeak.miss(q.key) }
        }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { mark = ok }
        // after answering, hear it (the sentence / word) once more
        if !ok || mode == .order || mode == .dictation, !q.audio.isEmpty { Speaker.shared.say(q.audio) }
        let wait = mode == .flash ? 0.5 : ok ? 0.9 : 2.0
        later(wait) {
            withAnimation { mark = nil }
            next()
        }
    }

    private func next() {
        if mode == .flash {
            // endless: more questions while time is left
            if i + 1 >= qs.count { qs += Self.build(.flash, level: level) }
        }
        if i + 1 >= qs.count { finish(); return }
        withAnimation(.easeInOut(duration: 0.2)) { i += 1 }
        present()
    }

    private func finish() {
        guard !done else { return }
        done = true
        if let stageDone {
            // ★3 = 80% right, ★2 = 60%, ★1 = 40%
            let r = Double(right) / Double(max(qs.count, 1))
            stageDone(r >= 0.8 ? 3 : r >= 0.6 ? 2 : r >= 0.4 ? 1 : 0, right * 100)
            return
        }
        mode.record(score)
        if mode == .review { KJDaily.mark(.review) }
        if mode == .speak { KJDaily.mark(.speak) }
        AudioManager.shared.se(.studyClear)
    }

    // MARK: questions

    static func build(_ mode: KJTrainMode, level: Int? = nil) -> [KJTQ] {
        // (the kanji words of rounds 2-3 are not spelled letter by letter here)
        let words = KJData.words.filter { !KJSimilar.hasKanji($0.ja) }
        let all = KJStudyData.sentences
        let sentences = level.map { lv in all.filter { $0.level == lv } } ?? all
        switch mode {
        case .dictation:
            return words.filter { $0.ja.count >= 2 && $0.ja.count <= 5 }.shuffled().prefix(10).map { w in
                let chars = w.ja.map(String.init)
                var pad = chars
                for k in KJData.letters.map(\.kana).filter({ $0.count == 1 }).shuffled() where pad.count < chars.count + 4 && !pad.contains(k) { pad.append(k) }
                return KJTQ(head: KJ.both("Listen and write it", "聽了寫下來", "듣고 써 보자"), prompt: "", note: "\(w.emoji) \(w.meaning)", audio: w.ja,
                            tiles: pad.shuffled(), want: chars, explain: w.ja, key: w.ja)
            }
        case .order:
            return sentences.filter { $0.chunks.count >= 2 }.shuffled().prefix(10).map { s in
                KJTQ(head: KJ.both("Put them in order", "排出正確順序", "순서대로 놓아요"), prompt: s.meaning, audio: s.spoken,
                     tiles: s.chunks.shuffled(), want: s.chunks, explain: s.ja)
            }.map { q in
                // the shuffled tiles must not already be in order
                var q = q
                while q.tiles == q.want && q.want.count > 1 { q.tiles.shuffle() }
                return q
            }
        case .listening:
            return sentences.shuffled().prefix(10).map { s in
                let others = sentences.filter { $0.ja != s.ja }.shuffled().prefix(3).map(\.meaning)
                let ch = ([s.meaning] + others).shuffled()
                return KJTQ(head: KJ.both("What does it mean?", "是什麼意思？", "무슨 뜻이에요?"), prompt: "", audio: s.spoken,
                            choices: ch, answer: ch.firstIndex(of: s.meaning) ?? 0, explain: s.ja)
            }
        case .speak:
            // words first, then short sentences
            let ws = words.filter { $0.ja.count >= 2 && $0.ja.count <= 5 }.shuffled().prefix(6).map { w in
                KJTQ(head: KJ.both("Say this word", "唸這個詞", "이 단어를 말해요"), prompt: w.ja, note: "\(w.emoji) \(w.meaning)", audio: w.ja, explain: w.ja, key: w.ja, speak: true)
            }
            let ss = sentences.filter { $0.level <= 2 }.shuffled().prefix(4).map { s in
                KJTQ(head: KJ.both("Say this sentence", "唸這個句子", "이 문장을 말해요"), prompt: s.ja, note: s.meaning, audio: s.spoken, explain: s.ja, speak: true)
            }
            return ws + ss
        case .sounds:
            return KJStudyData.pairs.shuffled().prefix(10).map { p in
                let say = Bool.random() ? p.a : p.b
                return KJTQ(head: KJ.both("Which one did you hear?", "你聽到的是哪一個？", "어느 쪽을 들었어요?"), prompt: "", audio: say,
                            choices: [p.a, p.b], answer: say == p.a ? 0 : 1, explain: p.meaning)
            }
        case .review:
            // what is due today first (1 day, 3 days, 1 week… after learning), then the weakest, then anything
            let weak = KJWeak.all.sorted { $0.value > $1.value }.map(\.key)
            var pool: [String] = []
            for k in KJSRS.due + weak + KJC1.all.shuffled() where !pool.contains(k) && pool.count < 10 { pool.append(k) }
            return pool.map { k in
                let isWord = k.count > 2 || KJData.word(k) != nil && k.count > 1
                let others = isWord
                    ? words.map(\.ja).filter { $0 != k && $0.count == k.count }.shuffled().prefix(3).map { $0 }
                    : mgDecoys(k, KJData.letters.map(\.kana)).filter { $0 != k }.prefix(3).map { $0 }
                let ch = ([k] + others).shuffled()
                return KJTQ(head: KJ.both("Listen and choose", "聽音選字", "듣고 고르기"), prompt: "", audio: k,
                            choices: ch, answer: ch.firstIndex(of: k) ?? 0, key: k)
            }
        case .flash:
            return (0..<20).map { _ in
                if Bool.random(), let w = words.filter({ $0.ja.count <= 4 }).randomElement() {
                    let others = words.filter { $0.ja != w.ja }.shuffled().prefix(3).map(\.meaning)
                    let ch = ([w.meaning] + others).shuffled()
                    return KJTQ(head: KJ.both("What does it mean?", "是什麼意思？", "무슨 뜻?"), prompt: w.ja, audio: w.ja,
                                choices: ch, answer: ch.firstIndex(of: w.meaning) ?? 0, key: w.ja)
                }
                let l = KJData.letters.randomElement()!
                let others = mgDecoys(l.kana, KJData.letters.map(\.kana)).filter { $0 != l.kana }.prefix(3).map { KJData.romaji($0) }
                let ch = ([l.romaji] + others).uniqued().shuffled()
                return KJTQ(head: KJ.both("How do you read it?", "怎麼唸？", "어떻게 읽어요?"), prompt: l.kana,
                            choices: ch, answer: ch.firstIndex(of: l.romaji) ?? 0, key: l.kana)
            }
        case .jlpt, .mock:
            let n = mode == .jlpt ? 10 : 30
            // a mix like the real test: letters, words, grammar, listening
            let by = Dictionary(grouping: KJStudyData.exam, by: \.kind)
            let plan: [(String, Int)] = mode == .jlpt ? [("moji", 3), ("goi", 2), ("bunpo", 3), ("choukai", 2)] : [("moji", 8), ("goi", 7), ("bunpo", 8), ("choukai", 7)]
            var out: [KJTQ] = []
            for (kind, c) in plan {
                for e in (by[kind] ?? []).shuffled().prefix(c) {
                    var ch = e.choices
                    if kind == "choukai" {
                        // the meanings in the learner's language
                        ch = ch.map { en in KJStudyData.sentences.first { $0.en == en }?.meaning ?? en }
                    }
                    let right = ch[e.answer]
                    let order = ch.shuffled()
                    let head: String
                    switch kind {
                    case "moji": head = "もじ・" + KJ.t("Letters", "文字", "문자")
                    case "goi": head = "ごい・" + KJ.t("Vocabulary", "詞彙", "어휘")
                    case "bunpo": head = "ぶんぽう・" + KJ.t("Grammar: fill in （　）", "文法：填入（　）", "문법: （　）에 들어갈 말")
                    default: head = "ちょうかい・" + KJ.t("Listening", "聽力", "청해")
                    }
                    out.append(KJTQ(head: head, prompt: kind == "choukai" ? "" : e.q, audio: e.audio,
                                    choices: order, answer: order.firstIndex(of: right) ?? 0, explain: e.explain))
                }
            }
            return Array(out.prefix(n))
        }
    }
}

/// the menu of training modes and exams (a tab of まなぶ)
struct KJTrainMenu: View {
    let modes: [KJTrainMode]
    var header: AnyView? = nil
    var open: (KJTrainMode) -> Void
    var body: some View {
        ScrollView {
            VStack(spacing: 10.s) {
                if let header { header }
                if modes == KJTrainMode.training {
                    Text(KJ.t("Words & sentences", "單字與句子", "단어와 문장")).font(.ui(14.s)).foregroundStyle(.white)
                        .padding(.top, header == nil ? 0 : 8.s)
                    Text(KJ.t("Correct answers so far: ", "累計答對：", "지금까지 정답: ") + "\(KJTrainMode.totalCorrect)")
                        .font(.ui(13.s)).foregroundStyle(.white)
                }
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10.s), GridItem(.flexible(), spacing: 10.s)], spacing: 10.s) {
                    ForEach(modes) { m in
                        Button { AudioManager.shared.se(.decide); open(m) } label: {
                            VStack(spacing: 6.s) {
                                Image(systemName: m.icon).font(.system(size: 26.s, weight: .bold)).foregroundStyle(Color.ink)
                                Text(m.ja).font(.custom(Fonts.rounded, size: 16.s)).foregroundStyle(Color.ink)
                                    .lineLimit(1).minimumScaleFactor(0.6)
                                Text(m.sub).font(.ui(11.s, bold: false)).foregroundStyle(Color.ink.opacity(0.7))
                                    .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.7)
                                if m.best > 0 {
                                    Text(KJ.t("Best ", "最佳 ", "최고 ") + "\(m.best)").font(.display(11.s)).foregroundStyle(Color.popDeep)
                                }
                            }
                            .padding(10.s)
                            .frame(maxWidth: .infinity).frame(height: 140.s)
                            .background(RoundedRectangle(cornerRadius: 18.s).fill(m.color).overlay(RoundedRectangle(cornerRadius: 18.s).stroke(Color.ink, lineWidth: 3)))
                        }
                        .buttonStyle(PressStyle(radius: 18.s, depth: 4))
                    }
                }
                if modes == KJTrainMode.exams {
                    Text(KJ.t("JLPT N5-style questions made for this app (not official). Pass line in the mock: 80 / 180.",
                              "本App自製的JLPT N5形式題目（非官方）。模擬考及格線：80 / 180。",
                              "이 앱이 만든 JLPT N5 형식 문제(공식 아님). 모의고사 합격선: 80 / 180."))
                        .font(.ui(11.s, bold: false)).foregroundStyle(.white.opacity(0.8)).multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 16.s).padding(.bottom, 24.s)
        }
    }
}
