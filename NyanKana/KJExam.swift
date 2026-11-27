import SwiftUI
import AVFoundation

// MARK: - しけん：JLPT の 本番と おなじ 形の もし（N5・N4）と、毎日の ミニテスト
// もし：分野ごとの 時間・基準点・合格点。聴解は 1回だけ 流れる（本番と おなじ）。プレミアムの 人だけ。
// ミニテスト：10もん、すぐ 答え合わせ。無料は 1日1回。

struct KJXLine: Hashable {
    var role: String
    var text: String        // ruby markup
    var spoken: String { KJRuby.plain(text).replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "　", with: "") }
}

struct KJXQ: Hashable {
    var sec: Int            // 0 もじ・ごい, 1 ぶんぽう・どっかい, 2 ちょうかい
    var kind: String
    var prompt: String
    var choices: [String]
    var ans: Int
    var passage: Int
    var lines: [KJXLine]
    var intro: String
    var ask: String
    var star: String        // ★: the right order (shown after)

    var listening: Bool { sec == 2 }
    /// the choices are heard, not read (はつわ・そくじ)
    var heardChoices: Bool { kind == "hatsuwa" || kind == "sokuji" }

    var head: String {
        switch kind {
        case "yomi": KJ.jt("＿＿の ことばは ひらがなで どう かきますか。", "How is the underlined word read?", "畫線的詞怎麼唸？", "밑줄 친 말은 어떻게 읽어요?")
        case "hyoki": KJ.jt("＿＿の ことばは どう かきますか。", "How is the underlined word written?", "畫線的詞怎麼寫？", "밑줄 친 말은 어떻게 써요?")
        case "bunmyaku": KJ.jt("（　）に なにを いれますか。", "What goes in （　）?", "（　）裡填什麼？", "（　）에 무엇을 넣어요?")
        case "iikae": KJ.jt("＿＿の ぶんと だいたい おなじ いみの ぶんは どれですか。", "Which sentence means about the same?", "哪一句意思差不多？", "비슷한 뜻의 문장은?")
        case "youhou": KJ.jt("つぎの ことばの つかいかたで いちばん いい ものは どれですか。", "Which sentence uses the word correctly?", "哪一句用法正確？", "바르게 쓴 문장은?")
        case "bunpo": KJ.jt("（　）に なにを いれますか。", "What goes in （　）?", "（　）裡填什麼？", "（　）에 무엇을 넣어요?")
        case "narabe": KJ.jt("★に 入る ものは どれですか。", "Which piece goes in ★?", "★裡填哪一個？", "★에 들어갈 것은?")
        case "bunsho": KJ.jt("ぶんしょうを よんで、（　）に 入る ものを えらんで ください。", "Read the text and fill in the blank.", "閱讀文章，選出填入的詞。", "글을 읽고 빈칸에 들어갈 것을 고르세요.")
        case "dokkai": KJ.jt("ぶんしょうを よんで、しつもんに こたえて ください。", "Read and answer.", "閱讀並回答。", "읽고 답하세요.")
        case "kadai": KJ.jt("かだいりかい", "Task listening", "課題理解", "과제 이해")
        case "point": KJ.jt("ポイントりかい", "Point listening", "重點理解", "포인트 이해")
        case "hatsuwa": KJ.jt("はつわひょうげん：なんと いいますか。", "What do you say?", "該說什麼？", "뭐라고 말해요?")
        case "sokuji": KJ.jt("そくじおうとう：へんじを えらんで ください。", "Choose the reply.", "選出回答。", "대답을 고르세요.")
        default: ""
        }
    }
}

struct KJMock: Identifiable, Hashable {
    var id: String
    var lv: Int
    var ja: String
    var en: String
    var minutes: [Int]
    var passages: [String]
    var sections: [[KJXQ]]

    static let secNames: [(ja: String, en: String, zh: String, ko: String)] = [
        ("げんごちしき（もじ・ごい）", "Vocabulary", "語言知識（文字・語彙）", "언어지식 (문자·어휘)"),
        ("げんごちしき（ぶんぽう）・どっかい", "Grammar · Reading", "語言知識（文法）・讀解", "언어지식 (문법)·독해"),
        ("ちょうかい", "Listening", "聽解", "청해"),
    ]
    var passLine: Int { lv == 5 ? 80 : 90 }

    static var best: [String: Int] {
        get { UserDefaults.standard.dictionary(forKey: "kj.mock.best") as? [String: Int] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: "kj.mock.best") }
    }
}

/// plays exam audio line by line (recorded voices only)
@MainActor final class KJExamAudio: ObservableObject {
    static let shared = KJExamAudio()
    @Published var playing = false
    private var token = 0

    func stop() { token += 1; playing = false; AudioManager.shared.stopVoice() }

    func play(_ q: KJXQ, done: @escaping () -> Void = {}) {
        var seq: [(String, String)] = []
        if !q.intro.isEmpty { seq.append(("xn", KJRuby.plain(q.intro).replacingOccurrences(of: " ", with: ""))) }
        switch q.kind {
        case "hatsuwa":
            for (i, l) in q.lines.enumerated() { seq.append(("xn", ["いち。", "に。", "さん。"][i])); seq.append((l.role, l.spoken)) }
        case "sokuji":
            if let f = q.lines.first { seq.append((f.role, f.spoken)) }
            for (i, l) in q.lines.dropFirst().enumerated() { seq.append(("xn", ["いち。", "に。", "さん。"][i])); seq.append((l.role, l.spoken)) }
        default:
            for l in q.lines { seq.append((l.role, l.spoken)) }
        }
        if !q.ask.isEmpty { seq.append(("xn", KJRuby.plain(q.ask).replacingOccurrences(of: " ", with: ""))) }
        token += 1
        playing = true
        step(seq, 0, token, done)
    }

    private func step(_ seq: [(String, String)], _ i: Int, _ t: Int, _ done: @escaping () -> Void) {
        guard t == token else { return }
        guard i < seq.count else { playing = false; done(); return }
        let (role, text) = seq[i]
        var wait = 0.3
        if let b = RecordedVoice.buffer(text, role: role),
           AudioManager.shared.playVoiceChecked(b, volume: Float(max(0.7, AppState.shared.settings.voiceVolume))) {
            wait = Double(b.frameLength) / b.format.sampleRate
        }
        let gap = role == "xn" && text.count <= 3 ? 0.35 : 0.6
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64((wait + gap) * 1_000_000_000))
            self.step(seq, i + 1, t, done)
        }
    }
}

// MARK: menu (the しけん tab)

struct KJExamMenu: View {
    @ObservedObject private var app = AppState.shared
    @State private var running: KJMock?
    @State private var mini: KJMiniBox?
    @State private var lv = 5
    @State private var lockedNote = false

    private var bought: Bool { KJLap.bought }
    private static let dayKey = "kj.mini.day"
    private var miniLeft: Bool {
        bought || UserDefaults.standard.string(forKey: Self.dayKey) != Self.today
    }
    static var today: String { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: Date()) }

    var body: some View {
        ScrollView {
            VStack(spacing: 12.s) {
                HStack(spacing: 8.s) {
                    ForEach([5, 4], id: \.self) { l in
                        Button { AudioManager.shared.se(.tap); lv = l } label: {
                            Text("N\(l)").font(.display(15.s)).foregroundStyle(lv == l ? .white : Color.ink)
                                .padding(.horizontal, 18.s).padding(.vertical, 5.s)
                                .background(Capsule().fill(lv == l ? Color.grape : Color.white).overlay(Capsule().stroke(Color.ink, lineWidth: 2)))
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
                // daily mini test
                card(icon: "bolt.fill", color: Color(hex: 0xCFF3FF),
                     title: KJ.jt("ミニテスト（10もん）", "Mini test (10 questions)", "迷你測驗（10題）", "미니 테스트 (10문제)"),
                     sub: bought ? KJ.t("Letters, words, grammar and listening — answers right away", "文字、詞彙、文法、聽力，馬上對答案", "문자·어휘·문법·청해, 바로 채점")
                                 : (miniLeft ? KJ.t("Free: once a day", "免費：每天一次", "무료: 하루 1번") : KJ.t("Done for today — come back tomorrow!", "今天已經做過了，明天再來！", "오늘은 끝! 내일 또 와요!")),
                     locked: !miniLeft) {
                    if miniLeft {
                        if !bought { UserDefaults.standard.set(Self.today, forKey: Self.dayKey) }
                        mini = KJMiniBox(qs: KJMiniTest.build(lv: lv))
                    } else { lockedNote = true }
                }
                Text(KJ.jt("ほんばんと おなじ 形の もし", "Full mock tests (same format as the real JLPT)", "和正式考試相同形式的模擬考", "실제 시험과 같은 형식의 모의고사"))
                    .font(.ui(13.s)).foregroundStyle(.white).frame(maxWidth: .infinity, alignment: .leading)
                ForEach(KJMock.all.filter { $0.lv == lv }) { m in
                    let n = m.sections.map(\.count).reduce(0, +)
                    let best = KJMock.best[m.id]
                    card(icon: bought ? "doc.text.fill" : "lock.fill", color: Color(hex: 0xFFE0E0),
                         title: m.ja + (lang == "ja" ? "" : "  " + m.en),
                         sub: "\(n) " + KJ.t("questions", "題", "문제") + " · " + m.minutes.map { "\($0)" }.joined(separator: "+") + KJ.t(" min", "分鐘", "분")
                            + (best.map { " · " + KJ.t("Best ", "最佳 ", "최고 ") + "\($0)/180" } ?? ""),
                         locked: !bought) {
                        if bought { running = m } else { app.sheet = .shop }
                    }
                }
                Text(KJ.t("Questions are original, made for this app in the JLPT format (not official). Scores are an estimate: 120 for vocabulary, grammar and reading, 60 for listening.",
                          "題目為本App依JLPT形式自製（非官方）。分數為估計：語言知識・讀解120分、聽解60分。",
                          "문제는 이 앱이 JLPT 형식으로 만든 것(공식 아님). 점수는 추정치: 언어지식·독해 120점, 청해 60점."))
                    .font(.ui(11.s, bold: false)).foregroundStyle(.white.opacity(0.85)).multilineTextAlignment(.leading)
            }
            .padding(.horizontal, 16.s).padding(.bottom, 24.s)
        }
        .fullScreenCover(item: $running) { m in KJMockView(mock: m) { running = nil } }
        .fullScreenCover(item: $mini) { b in KJMiniTest(qs: b.qs) { mini = nil } }
        .alert(KJ.t("You did today's mini test.", "今天的迷你測驗已完成。", "오늘의 미니 테스트를 했어요."), isPresented: $lockedNote) {
            Button(KJ.t("Get premium", "取得高級版", "프리미엄 받기")) { app.sheet = .shop }
            Button("OK", role: .cancel) {}
        } message: {
            Text(KJ.t("With premium you can take as many tests as you like, including the full mock tests.", "高級版可以無限次測驗，也能做完整模擬考。", "프리미엄은 모의고사를 포함해 몇 번이든 시험을 볼 수 있어요."))
        }
    }

    private var lang: String { KJ.lang }

    private func card(icon: String, color: Color, title: String, sub: String, locked: Bool, act: @escaping () -> Void) -> some View {
        Button { AudioManager.shared.se(.decide); act() } label: {
            HStack(spacing: 12.s) {
                Image(systemName: icon).font(.system(size: 24.s, weight: .bold)).foregroundStyle(Color.ink).frame(width: 34.s)
                VStack(alignment: .leading, spacing: 2.s) {
                    Text(title).font(.custom(Fonts.rounded, size: 16.s)).foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.6)
                    Text(sub).font(.ui(11.s, bold: false)).foregroundStyle(Color.ink.opacity(0.7)).fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                if locked { Image(systemName: "crown.fill").font(.system(size: 16.s)).foregroundStyle(Color.sunDeep) }
            }
            .padding(12.s)
            .background(RoundedRectangle(cornerRadius: 16.s).fill(color).overlay(RoundedRectangle(cornerRadius: 16.s).stroke(Color.ink, lineWidth: 3)))
            .opacity(locked ? 0.85 : 1)
        }
        .buttonStyle(PressStyle(radius: 16.s, depth: 4))
    }
}

struct KJMiniBox: Identifiable { let id = UUID(); let qs: [(KJXQ, KJMock)] }

// MARK: one question (shared by the mock and the mini test)

struct KJXQView: View {
    let q: KJXQ
    let mock: KJMock
    @Binding var picked: Int?
    var reveal: Bool              // show right / wrong (mini test, review)
    var canReplay: Bool
    var onPick: (Int) -> Void
    @ObservedObject private var audio = KJExamAudio.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 10.s) {
            Text(q.head).font(.ui(12.s)).foregroundStyle(.white).fixedSize(horizontal: false, vertical: true)
            if q.passage >= 0, let p = mock.passages[safe: q.passage] {
                ScrollView {
                    KJRubyText(markup: p, size: 16.s, ruby: true)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(12.s)
                }
                .frame(maxHeight: 260.s)
                .background(RoundedRectangle(cornerRadius: 12.s).fill(Color(hex: 0xFFFBF2)).overlay(RoundedRectangle(cornerRadius: 12.s).stroke(Color.ink, lineWidth: 2)))
            }
            if q.listening {
                HStack(spacing: 10.s) {
                    Image(systemName: audio.playing ? "waveform" : "headphones").font(.system(size: 26.s, weight: .bold)).foregroundStyle(.white)
                        .symbolEffect(.variableColor.iterative, isActive: audio.playing)
                    Text(audio.playing ? KJ.jt("きいて ください…", "Listen…", "請聽……", "들어 보세요…") : KJ.jt("こたえを えらんで ください", "Choose your answer", "請選答案", "답을 고르세요"))
                        .font(.ui(14.s)).foregroundStyle(.white)
                    Spacer()
                    if canReplay && !audio.playing {
                        Button { audio.play(q) } label: {
                            Label(KJ.jt("もういちど", "Replay", "重播", "다시 듣기"), systemImage: "arrow.counterclockwise")
                                .font(.ui(12.s)).foregroundStyle(Color.ink)
                                .padding(.horizontal, 10.s).padding(.vertical, 6.s).background(Capsule().fill(Color.white))
                        }
                    }
                }
                if q.kind == "hatsuwa" && !q.prompt.isEmpty {
                    paper { KJRubyText(markup: q.prompt, size: 17.s) }
                }
            } else if !q.prompt.isEmpty && q.kind != "bunsho" {
                paper {
                    if q.kind == "youhou" {
                        Text(q.prompt).font(.custom(Fonts.rounded, size: 24.s)).foregroundStyle(Color.ink)
                    } else {
                        KJRubyText(markup: q.prompt, size: 19.s, ruby: true, blank: .underline)
                    }
                }
            } else if q.kind == "bunsho" {
                Text(q.prompt).font(.custom(Fonts.rounded, size: 20.s)).foregroundStyle(.white)
            }
            // choices
            VStack(spacing: 8.s) {
                ForEach(Array(q.choices.enumerated()), id: \.offset) { k, c in
                    let ok = reveal && picked != nil && k == q.ans, ng = reveal && picked == k && k != q.ans
                    let sel = !reveal && picked == k
                    Button { onPick(k) } label: {
                        HStack(alignment: .center, spacing: 10.s) {
                            Text("\(k + 1)").font(.display(15.s)).foregroundStyle(sel ? .white : Color.ink)
                                .frame(width: 28.s, height: 28.s).background(Circle().fill(sel ? Color.grape : Color.white).overlay(Circle().stroke(Color.ink, lineWidth: 2)))
                            if q.heardChoices && !(reveal && picked != nil) {
                                Text("…").font(.ui(15.s)).foregroundStyle(Color.ink.opacity(0.4))
                            } else {
                                KJRubyText(markup: c, size: 17.s, ruby: true)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 10.s).padding(.vertical, 8.s)
                        .frame(maxWidth: .infinity, minHeight: 48.s, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 12.s).fill(ok ? Color(hex: 0xD9F7E3) : ng ? Color(hex: 0xFFD6D6) : sel ? Color(hex: 0xF0E6FF) : Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 12.s).stroke(ok ? Color.mintDeep : Color.ink, lineWidth: ok ? 3.5 : 2)))
                    }
                    .buttonStyle(.plain)
                    .disabled(reveal && picked != nil)
                }
            }
            if reveal && picked != nil { explain }
        }
    }

    /// after answering: the right order (★) or what was said (listening)
    @ViewBuilder private var explain: some View {
        if q.kind == "narabe" && !q.star.isEmpty {
            paper { KJRubyText(markup: KJ.jt("ただしい じゅんばん：", "Right order: ", "正確順序：", "바른 순서: ") + q.star, size: 15.s) }
        }
        if q.listening {
            paper {
                VStack(alignment: .leading, spacing: 6.s) {
                    Text(KJ.jt("スクリプト", "Script", "原文", "스크립트")).font(.ui(11.s)).foregroundStyle(Color.ink.opacity(0.6))
                    ForEach(Array(q.lines.enumerated()), id: \.offset) { i, l in
                        HStack(alignment: .top, spacing: 6.s) {
                            Text(label(l.role, i)).font(.ui(12.s)).foregroundStyle(Color.grape).frame(width: 34.s, alignment: .leading)
                            KJRubyText(markup: l.text, size: 15.s)
                        }
                    }
                }
            }
        }
    }

    private func label(_ role: String, _ i: Int) -> String {
        if q.heardChoices {
            if q.kind == "sokuji" { return i == 0 ? "Q" : "\(i)" }
            return "\(i + 1)"
        }
        return role.hasPrefix("xm") ? "男" : role.hasPrefix("xf") ? "女" : ""
    }

    private func paper<C: View>(@ViewBuilder _ c: () -> C) -> some View {
        c().frame(maxWidth: .infinity, alignment: .leading).padding(12.s)
            .background(RoundedRectangle(cornerRadius: 12.s).fill(Color.white.opacity(0.96)).overlay(RoundedRectangle(cornerRadius: 12.s).stroke(Color.ink, lineWidth: 2)))
    }
}

// MARK: the full mock

struct KJMockView: View {
    let mock: KJMock
    var close: () -> Void
    @State private var sec = 0
    @State private var i = 0
    @State private var answers: [[Int?]] = []
    @State private var timeLeft: Double = 0
    @State private var phase: Phase = .intro
    @State private var picked: Int?
    @State private var reviewSec = 0
    @State private var quitAsk = false
    @ObservedObject private var audio = KJExamAudio.shared
    private let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    enum Phase { case intro, test, between, result, review }

    var body: some View {
        ZStack {
            KJBackdrop(bg: "bg_mg_dojo", dim: 0.6)
            VStack(spacing: 8.s) {
                HStack {
                    BackChip { if phase == .test || phase == .between { quitAsk = true } else { finish(); close() } }
                    Spacer()
                    if phase == .test {
                        Label(timeText, systemImage: "timer").font(.display(16.s)).foregroundStyle(timeLeft < 60 ? Color.danger : .white)
                        Text("\(i + 1) / \(mock.sections[sec].count)").font(.display(15.s)).foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 14.s).padding(.top, 6.s)
                switch phase {
                case .intro: introView
                case .test: testView
                case .between: betweenView
                case .result: resultView
                case .review: reviewView
                }
            }
        }
        .onAppear { answers = mock.sections.map { Array(repeating: nil, count: $0.count) }; AudioManager.shared.playBGM(.track("study_jlpt")) }
        .onDisappear { audio.stop() }
        .onReceive(clock) { _ in
            guard phase == .test, !(mock.sections[sec].first?.listening ?? false) else { return }
            timeLeft -= 1
            if timeLeft <= 0 { endSection() }
        }
        .alert(KJ.t("Stop the test?", "要停止測驗嗎？", "시험을 그만둘까요?"), isPresented: $quitAsk) {
            Button(KJ.t("Stop", "停止", "그만두기"), role: .destructive) { audio.stop(); close() }
            Button(KJ.t("Continue", "繼續", "계속"), role: .cancel) {}
        }
    }

    private var timeText: String {
        if mock.sections[sec].first?.listening ?? false { return "—" }
        let t = max(0, Int(timeLeft)); return String(format: "%d:%02d", t / 60, t % 60)
    }

    private var introView: some View {
        VStack(spacing: 14.s) {
            Spacer()
            OutlinedText(mock.ja, font: .display(34.s), fill: .sun, width: 4, shadow: 3)
            VStack(alignment: .leading, spacing: 8.s) {
                ForEach(0..<3, id: \.self) { s in
                    let n = KJMock.secNames[s]
                    HStack {
                        Text("\(s + 1). " + n.ja).font(.ui(14.s))
                        Spacer()
                        Text("\(mock.sections[s].count)" + KJ.t("q", "題", "문") + " / \(mock.minutes[s])" + KJ.t("min", "分", "분")).font(.ui(13.s, bold: false))
                    }
                    .foregroundStyle(Color.ink)
                }
                Text(KJ.t("Listening plays only once, like the real test. Pass: \(mock.passLine)/180, and at least 38/120 and 19/60.",
                          "聽解和正式考試一樣只播一次。及格：\(mock.passLine)/180，且各部分達基準分（38/120、19/60）。",
                          "청해는 실제 시험처럼 한 번만 나와요. 합격: \(mock.passLine)/180, 기준점 38/120·19/60 이상."))
                    .font(.ui(12.s, bold: false)).foregroundStyle(Color.ink.opacity(0.75)).fixedSize(horizontal: false, vertical: true)
            }
            .padding(16.s)
            .background(RoundedRectangle(cornerRadius: 18.s).fill(Color(hex: 0xFFFBF2)).overlay(RoundedRectangle(cornerRadius: 18.s).stroke(Color.ink, lineWidth: 3)))
            .padding(.horizontal, 20.s)
            KJButton(title: KJ.jt2("はじめる", "Start", "開始", "시작"), color: .pop, textColor: .white) { startSection(0) }
                .padding(.horizontal, 40.s)
            Spacer()
        }
    }

    private var testView: some View {
        let q = mock.sections[sec][i]
        return VStack(spacing: 10.s) {
            ScrollView {
                KJXQView(q: q, mock: mock, picked: $picked, reveal: false, canReplay: false) { k in
                    picked = k
                    answers[sec][i] = k
                    AudioManager.shared.se(.tap, rate: 1.2, volume: 0.6)
                }
                .padding(.horizontal, 16.s).padding(.bottom, 12.s)
            }
            HStack(spacing: 12.s) {
                if !q.listening && i > 0 {
                    KJButton(title: KJ.jt2("まえへ", "Back", "上一題", "이전"), color: .white) { go(i - 1) }
                }
                KJButton(title: i + 1 < mock.sections[sec].count ? KJ.jt2("つぎへ", "Next", "下一題", "다음") : KJ.jt2("おわる", "Finish part", "結束這部分", "이 부분 끝"),
                         color: .pop, textColor: .white) {
                    if i + 1 < mock.sections[sec].count { go(i + 1) } else { endSection() }
                }
                .disabled(q.listening && audio.playing)
                .opacity(q.listening && audio.playing ? 0.5 : 1)
            }
            .padding(.horizontal, 20.s).padding(.bottom, 10.s)
        }
    }

    private var betweenView: some View {
        VStack(spacing: 14.s) {
            Spacer()
            Text(KJ.jt("つぎは", "Next part", "下一部分", "다음 파트")).font(.ui(16.s)).foregroundStyle(.white)
            OutlinedText(KJMock.secNames[sec].ja, font: .display(22.s), fill: .sun, width: 3, shadow: 2)
            Text(KJ.t(KJMock.secNames[sec].en, KJMock.secNames[sec].zh, KJMock.secNames[sec].ko)).font(.ui(14.s)).foregroundStyle(.white)
            KJButton(title: KJ.jt2("はじめる", "Start", "開始", "시작"), color: .pop, textColor: .white) { begin() }
                .padding(.horizontal, 40.s)
            Spacer()
        }
    }

    // MARK: scores

    private func right(_ s: Int) -> Int { zip(mock.sections[s], answers[safe: s] ?? []).filter { $0.0.ans == $0.1 }.count }
    private var langScore: Int {
        let n = mock.sections[0].count + mock.sections[1].count
        return Int((Double(right(0) + right(1)) / Double(max(n, 1)) * 120).rounded())
    }
    private var listenScore: Int { Int((Double(right(2)) / Double(max(mock.sections[2].count, 1)) * 60).rounded()) }
    private var total: Int { langScore + listenScore }
    private var passed: Bool { total >= mock.passLine && langScore >= 38 && listenScore >= 19 }

    private var resultView: some View {
        ScrollView {
            VStack(spacing: 14.s) {
                Image(passed ? "nk_nyan_joy" : "nk_nyan_think").resizable().scaledToFit().frame(height: 130.s)
                OutlinedText("\(total) / 180", font: .display(48.s), fill: .sun, width: 4, shadow: 3)
                OutlinedText(passed ? KJ.jt("ごうかく ライン！", "Pass line cleared!", "達到及格線！", "합격선 통과!") : KJ.jt("もう すこし！", "Almost there!", "再加油！", "조금만 더!"),
                             font: .display(22.s), fill: passed ? .mint : .pop, width: 3, shadow: 2)
                VStack(spacing: 8.s) {
                    scoreRow(KJMock.secNames[0].ja + "・" + KJMock.secNames[1].ja.replacingOccurrences(of: "げんごちしき", with: ""), langScore, 120, 38)
                    scoreRow(KJMock.secNames[2].ja, listenScore, 60, 19)
                    Divider()
                    ForEach(0..<3, id: \.self) { s in
                        HStack {
                            Text(KJMock.secNames[s].ja).font(.ui(12.s, bold: false))
                            Spacer()
                            Text("\(right(s)) / \(mock.sections[s].count)").font(.display(13.s))
                        }
                        .foregroundStyle(Color.ink)
                    }
                    weakKinds
                }
                .padding(16.s)
                .background(RoundedRectangle(cornerRadius: 18.s).fill(Color(hex: 0xFFFBF2)).overlay(RoundedRectangle(cornerRadius: 18.s).stroke(Color.ink, lineWidth: 3)))
                .padding(.horizontal, 18.s)
                KJButton(title: KJ.jt2("こたえを みる", "Review answers", "查看答案", "답 확인"), color: .sun) { reviewSec = 0; i = 0; phase = .review }
                    .padding(.horizontal, 40.s)
                KJButton(title: KJ.jt2("もどる", "Back", "返回", "돌아가기"), color: .white) { close() }
                    .padding(.horizontal, 40.s)
            }
            .padding(.bottom, 30.s)
        }
    }

    private func scoreRow(_ name: String, _ v: Int, _ of: Int, _ base: Int) -> some View {
        VStack(alignment: .leading, spacing: 3.s) {
            HStack {
                Text(name).font(.ui(13.s)).lineLimit(1).minimumScaleFactor(0.6)
                Spacer()
                Text("\(v) / \(of)").font(.display(16.s))
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.ink.opacity(0.1))
                    Capsule().fill(v >= base ? Color.mintDeep : Color.danger).frame(width: g.size.width * CGFloat(v) / CGFloat(of))
                    Rectangle().fill(Color.ink).frame(width: 2).offset(x: g.size.width * CGFloat(base) / CGFloat(of))
                }
            }
            .frame(height: 10.s)
            Text(KJ.t("Minimum: \(base)", "基準分：\(base)", "기준점: \(base)")).font(.ui(10.s, bold: false)).foregroundStyle(Color.ink.opacity(0.6))
        }
        .foregroundStyle(Color.ink)
    }

    /// the question types with the most mistakes
    @ViewBuilder private var weakKinds: some View {
        let all = (0..<3).flatMap { s in mock.sections[s].enumerated().map { (q: $0.element, a: answers[safe: s]?[safe: $0.offset] ?? nil) } }
        let byKind = Dictionary(grouping: all, by: { $0.q.kind })
        let weak = byKind.map { (k: $0.key, miss: $0.value.filter { $0.q.ans != $0.a }.count, n: $0.value.count) }
            .filter { $0.miss > 0 }.sorted { Double($0.miss) / Double($0.n) > Double($1.miss) / Double($1.n) }.prefix(3)
        if !weak.isEmpty {
            VStack(alignment: .leading, spacing: 3.s) {
                Text(KJ.jt("にがてな もんだい", "Your weak spots", "較弱的題型", "약한 문제 유형")).font(.ui(12.s)).foregroundStyle(Color.ink.opacity(0.7))
                ForEach(Array(weak.enumerated()), id: \.offset) { _, w in
                    let sample = all.first { $0.q.kind == w.k }!.q
                    Text("・" + sample.head.components(separatedBy: "  ").first! + "　\(w.n - w.miss)/\(w.n)")
                        .font(.ui(12.s, bold: false)).foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.6)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var reviewView: some View {
        let qs = mock.sections[reviewSec]
        let q = qs[i]
        let mine = answers[safe: reviewSec]?[safe: i] ?? nil
        return VStack(spacing: 8.s) {
            Picker("", selection: $reviewSec) {
                ForEach(0..<3, id: \.self) { s in Text("\(s + 1)").tag(s) }
            }
            .pickerStyle(.segmented).padding(.horizontal, 16.s)
            .onChange(of: reviewSec) { _, _ in i = 0 }
            ScrollView {
                KJXQView(q: q, mock: mock, picked: Binding<Int?>.constant(mine ?? -1), reveal: true, canReplay: true) { _ in }
                    .padding(.horizontal, 16.s)
                if mine == nil {
                    Text(KJ.jt("こたえて いません", "Not answered", "未作答", "미응답")).font(.ui(13.s)).foregroundStyle(Color.danger)
                }
            }
            HStack(spacing: 12.s) {
                KJButton(title: KJ.jt2("まえへ", "Back", "上一題", "이전"), color: .white) { audio.stop(); if i > 0 { i -= 1 } }
                Text("\(i + 1)/\(qs.count)").font(.display(14.s)).foregroundStyle(.white)
                KJButton(title: KJ.jt2("つぎへ", "Next", "下一題", "다음"), color: .pop, textColor: .white) { audio.stop(); if i + 1 < qs.count { i += 1 } else { phase = .result } }
            }
            .padding(.horizontal, 16.s).padding(.bottom, 10.s)
        }
    }

    // MARK: flow

    private func startSection(_ s: Int) { sec = s; phase = .between }
    private func begin() {
        i = 0
        timeLeft = Double(mock.minutes[sec] * 60)
        phase = .test
        present()
    }
    private func present() {
        picked = answers[safe: sec]?[safe: i] ?? nil
        let q = mock.sections[sec][i]
        if q.listening { later(0.4) { audio.play(q) } }
    }
    private func go(_ n: Int) { audio.stop(); i = n; present() }
    private func endSection() {
        audio.stop()
        if sec + 1 < mock.sections.count { startSection(sec + 1) } else { finish(); phase = .result; AudioManager.shared.se(passed ? .clear : .studyClear) }
    }
    private func finish() {
        guard phase == .test || phase == .between else { return }
        var b = KJMock.best
        if total > (b[mock.id] ?? -1) { b[mock.id] = total; KJMock.best = b }
    }
}

// MARK: the mini test (10 questions, answers right away)

enum KJMiniTest {
    static func build(lv: Int) -> [(KJXQ, KJMock)] {
        let ms = KJMock.all.filter { $0.lv == lv }
        var pool: [String: [(KJXQ, KJMock)]] = [:]
        for m in ms { for s in m.sections { for q in s where q.passage < 0 { pool[q.kind, default: []].append((q, m)) } } }
        let plan: [(String, Int)] = [("yomi", 1), ("hyoki", 1), ("bunmyaku", 1), ("iikae", 1), ("bunpo", 2), ("narabe", 1), ("kadai", 1), ("point", 1), ("sokuji", 1)]
        var out: [(KJXQ, KJMock)] = []
        for (k, n) in plan { out += (pool[k] ?? []).shuffled().prefix(n) }
        return out
    }
}

struct KJMiniTest: View {
    let qs: [(KJXQ, KJMock)]
    var close: () -> Void
    @State private var i = 0
    @State private var picked: Int?
    @State private var right = 0
    @State private var done = false
    @ObservedObject private var audio = KJExamAudio.shared

    var body: some View {
        ZStack {
            KJBackdrop(bg: "bg_mg_dojo", dim: 0.6)
            VStack(spacing: 8.s) {
                HStack {
                    BackChip { audio.stop(); close() }
                    Spacer()
                    if !done { Text("\(i + 1) / \(qs.count)").font(.display(16.s)).foregroundStyle(.white) }
                }
                .padding(.horizontal, 14.s).padding(.top, 6.s)
                if done {
                    Spacer()
                    Image(right >= 8 ? "nk_nyan_joy" : "nk_nyan_think").resizable().scaledToFit().frame(height: 140.s)
                    OutlinedText("\(right) / \(qs.count)", font: .display(52.s), fill: .sun, width: 4, shadow: 3)
                    KJButton(title: KJ.jt2("もどる", "Back", "返回", "돌아가기"), color: .white) { close() }.padding(.horizontal, 40.s)
                    Spacer()
                } else if let pair = qs[safe: i] {
                    let q = pair.0
                    ScrollView {
                        KJXQView(q: q, mock: pair.1, picked: $picked, reveal: true, canReplay: true) { k in
                            guard picked == nil, !audio.playing || !q.listening else { return }
                            picked = k
                            if k == q.ans { right += 1; AudioManager.shared.se(.studyOK) } else { AudioManager.shared.se(.studyNG) }
                        }
                        .padding(.horizontal, 16.s)
                    }
                    if picked != nil {
                        KJButton(title: KJ.jt2("つぎへ", "Next", "下一題", "다음"), color: .pop, textColor: .white) {
                            audio.stop()
                            if i + 1 < qs.count { i += 1; present() } else { done = true; AudioManager.shared.se(right >= 8 ? .studyClear : .studyOK) }
                        }
                        .padding(.horizontal, 40.s).padding(.bottom, 10.s)
                    }
                }
            }
        }
        .onAppear { AudioManager.shared.playBGM(.track("study_jlpt")); present() }
        .onDisappear { audio.stop() }
    }

    private func present() {
        picked = nil
        if let q = qs[safe: i]?.0, q.listening { later(0.4) { audio.play(q) } }
    }
}
