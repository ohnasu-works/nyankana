import SwiftUI

// MARK: - にゃんカナ 試作：最初の設定 → 1章ステージ1（あ行＋あいさつ）
// The new NyanKana flow (prototype). Story beats in everyday Japanese, short learning parts between them.

/// the learner's own language, chosen on the first screen (memory aids and subtitles follow it)
enum KJ {
    static var lang: String {
        get { UserDefaults.standard.string(forKey: "kj.lang") ?? "en" }
        set { UserDefaults.standard.set(newValue, forKey: "kj.lang") }
    }
    static var name: String {
        get { UserDefaults.standard.string(forKey: "kj.name") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "kj.name") }
    }
    static var onboarded: Bool {
        get { UserDefaults.standard.bool(forKey: "kj.onboarded") }
        set { UserDefaults.standard.set(newValue, forKey: "kj.onboarded") }
    }
    /// text in the learner's language
    static func t(_ en: String, _ zh: String, _ ko: String) -> String {
        switch lang { case "zh": zh; case "ko": ko; default: en }
    }
    /// the learner's language with the Japanese underneath (second line)
    static func both(_ en: String, _ zh: String, _ ko: String) -> String {
        guard let j = ja[en] else { return t(en, zh, ko) }
        return t(en, zh, ko) + "\n" + j
    }
    static let ja: [String: String] = [
        "What's your name?": "なまえは？", "Your name": "なまえ",
        "You'll learn to say it in Japanese today.": "きょう にほんごで いえるように なります",
        "Why are you learning Japanese?": "どうして にほんごを まなぶ？",
        "Anime & manga": "アニメ・まんが", "Travel": "りょこう", "Work or school": "しごと・がっこう", "JLPT": "にほんごのうりょくしけん",
        "How much do you know?": "どのくらい しってる？", "I'm brand new": "はじめて", "I know some hiragana": "ひらがなを すこし しってる",
        "Here's the plan": "がくしゅうの よてい",
        "letters in your first 3 minutes": "もじを さいしょの 3ぷんで", "days to read all 46 hiragana": "にちで ひらがな46もじ ぜんぶ",
        "phrases you can say today": "フレーズを きょう いえる", "Let's go!": "しゅっぱつ！",
        "Tap the letter to hear it": "もじを タップすると きこえます", "Next": "つぎへ",
        "Listen and tap the letter": "きいて もじを えらぼう",
        "Useful phrase": "つかえる フレーズ", "Say it out loud with Nyan!": "ニャンと いっしょに こえに だそう！",
        "What do you say?": "なんと いう？",
        "You meet someone in the afternoon.": "ひるに だれかに あいました。",
        "Someone gives you a present.": "プレゼントを もらいました。",
        "Tell someone your name.": "じぶんの なまえを いいます。",
        "5 / 46 hiragana": "ひらがな 5 / 46", "3 phrases": "フレーズ 3つ", "3 signs back in town": "かんばん 3まい ふっかつ",
        "Play again": "もういちど", "Home": "ホームへ", "Redo first setup": "さいしょの せってい から",
    ]
}

struct KJLetter {
    var kana: String
    var romaji: String
    var en: String      // a picture to remember it by
    var zh: String      // the kanji it came from
    var ko: String      // the hangul with the same sound
    var ja: String = "" // the same aid in Japanese (shown underneath)
    var aid: String { KJ.t(en, zh, ko) }
}

enum KJData {
    static let aRow: [KJLetter] = [
        KJLetter(kana: "あ", romaji: "a", en: "A cross with a big swirl — you shout \"Ah!\" when you see it.",
                 zh: "來自漢字「安」的草書。安 → あ", ko: "소리는 「아」. あ = 아", ja: "十字と 大きな うずまき。見たら「あ！」"),
        KJLetter(kana: "い", romaji: "i", en: "Two little lines side by side, like two eels: \"ee\".",
                 zh: "來自漢字「以」的草書。以 → い", ko: "소리는 「이」. い = 이", ja: "2本の 線が ならんで「いー」"),
        KJLetter(kana: "う", romaji: "u", en: "A mouth saying \"ooh\" with a small hat on top.",
                 zh: "來自漢字「宇」的上半部。宇 → う", ko: "소리는 「우」. う = 우", ja: "「うー」と いう口に 小さな ぼうし"),
        KJLetter(kana: "え", romaji: "e", en: "A bird with a feather on its head asking \"eh?\"",
                 zh: "來自漢字「衣」的草書。衣 → え", ko: "소리는 「에」. え = 에", ja: "頭に はねの ある 鳥が「え？」"),
        KJLetter(kana: "お", romaji: "o", en: "A golfer swinging — the ball flies off: \"Oh!\"",
                 zh: "來自漢字「於」的草書。於 → お", ko: "소리는 「오」. お = 오", ja: "ゴルフの スイングで ボールが とんで「お！」"),
    ]

    /// the signs in town that come back as letters are won
    struct Sign { var word: String; var en: String; var zh: String; var ko: String }
    static let signs: [Sign] = [
        Sign(word: "うえ", en: "up", zh: "上面", ko: "위"),
        Sign(word: "いえ", en: "house", zh: "家", ko: "집"),
        Sign(word: "あお", en: "blue", zh: "藍色", ko: "파랑"),
    ]

    struct Phrase { var ja: String; var romaji: String; var en: String; var zh: String; var ko: String
        var meaning: String { KJ.t(en, zh, ko) } }

    static func phrases() -> [Phrase] {
        let n = KJ.name.isEmpty ? "〇〇" : KJ.name
        return [
            Phrase(ja: "こんにちは", romaji: "konnichiwa", en: "Hello", zh: "你好", ko: "안녕하세요"),
            Phrase(ja: "ありがとう", romaji: "arigatō", en: "Thank you", zh: "謝謝", ko: "고마워요"),
            Phrase(ja: "わたしは \(n) です", romaji: "watashi wa \(n) desu", en: "I am \(n).", zh: "我是\(n)。", ko: "저는 \(n)입니다."),
        ]
    }
}

// MARK: story lines

struct KJLine {
    enum Who { case narr, sora, nyan }
    var who: Who
    var face: String = ""       // picture name (expression)
    var ja: String
    var en: String
    var zh: String
    var ko: String
    var pose = false            // Nyan's big dramatic pose (the joke is in the action, the words stay plain)
    var sub: String { KJ.t(en, zh, ko) }
}

enum KJStory {
    static let opening: [KJLine] = [
        KJLine(who: .narr, ja: "ある あさ、にほんじゅうの もじが きえた。", en: "One morning, every letter in Japan vanished.", zh: "某天早上，日本所有的文字都消失了。", ko: "어느 날 아침, 일본의 모든 글자가 사라졌다."),
        KJLine(who: .sora, face: "sora_surprised", ja: "あれ？ かんばんに じが ない！", en: "Huh? The sign has no letters!", zh: "咦？招牌上沒有字！", ko: "어? 간판에 글자가 없어!"),
        KJLine(who: .nyan, face: "nk_nyan_proud", ja: "こんにちは！ ぼくは ニャン です。", en: "Hello! I'm Nyan.", zh: "你好！我是喵。", ko: "안녕하세요! 나는 냥이에요.", pose: true),
        KJLine(who: .sora, face: "sora_tsukkomi", ja: "…ふつうの あいさつ だね。", en: "…That's just a normal hello.", zh: "……只是普通的打招呼嘛。", ko: "…그냥 평범한 인사네."),
        KJLine(who: .nyan, face: "nk_nyan_tip", ja: "ようかいが もじを たべたんだ。", en: "The yokai ate the letters.", zh: "是妖怪把文字吃掉了。", ko: "요괴가 글자를 먹어 버렸어."),
        KJLine(who: .nyan, face: "nk_nyan_joy", ja: "いっしょに とりもどそう！", en: "Let's get them back together!", zh: "一起把它們找回來吧！", ko: "같이 되찾자!", pose: true),
    ]
    static let signsBack: [KJLine] = [
        KJLine(who: .sora, face: "sora_smile", ja: "かんばんが よめる！ 「うえ」「いえ」「あお」！", en: "I can read the signs! \"up\", \"house\", \"blue\"!", zh: "看得懂招牌了！「上面」「家」「藍色」！", ko: "간판이 읽혀! 「위」「집」「파랑」!"),
        KJLine(who: .nyan, face: "nk_nyan_proud", ja: "つぎは あいさつを おぼえよう。", en: "Next, let's learn some greetings.", zh: "接下來學打招呼吧。", ko: "다음은 인사를 배우자.", pose: true),
    ]
    static let ending: [KJLine] = [
        KJLine(who: .sora, face: "sora_smile", ja: "ありがとう、ニャン。", en: "Thank you, Nyan.", zh: "謝謝你，喵。", ko: "고마워, 냥."),
        KJLine(who: .nyan, face: "nk_nyan_shy", ja: "どういたしまして。", en: "You're welcome.", zh: "不客氣。", ko: "천만에요."),
        KJLine(who: .nyan, face: "nk_nyan_surprised", ja: "あっ！ あそこに きつねが いる！", en: "Oh! There's a fox over there!", zh: "啊！那邊有狐狸！", ko: "앗! 저기 여우가 있어!", pose: true),
        KJLine(who: .narr, ja: "つづく", en: "To be continued", zh: "待續", ko: "다음에 계속"),
    ]
}

// MARK: - the whole flow

struct KanaJourneyView: View {
    @EnvironmentObject var app: AppState
    enum Step: Equatable { case setup, opening, learn(Int), battle, signs, phrases(Int), phraseQuiz, ending, clear }
    @State private var step: Step = KJ.onboarded ? .opening : .setup
    @State private var won: Set<String> = []          // letters taken back (shown on the signs)

    var body: some View {
        ZStack {
            KJBackdrop(dim: step == .opening || step == .signs || step == .ending ? 0.05 : step == .battle ? 0.2 : 0.45)
            Group {
                switch step {
                case .setup:
                    KJSetupView { go(.opening) }
                case .opening:
                    KJStoryView(lines: KJStory.opening) { go(.learn(0)) }
                case .learn(let i):
                    KJLearnCard(letter: KJData.aRow[i], index: i) { go(i + 1 < KJData.aRow.count ? .learn(i + 1) : .battle) }
                        .id(i)
                case .battle:
                    KJBattleView(won: $won) { go(.signs) }
                case .signs:
                    VStack(spacing: 0) {
                        KJSignBoard(won: Set(KJData.aRow.map(\.kana))).padding(.top, 70.s)
                        KJStoryView(lines: KJStory.signsBack) { go(.phrases(0)) }
                    }
                case .phrases(let i):
                    KJPhraseCard(phrase: KJData.phrases()[i], index: i) { go(i + 1 < 3 ? .phrases(i + 1) : .phraseQuiz) }
                        .id(i)
                case .phraseQuiz:
                    KJPhraseQuiz { go(.ending) }
                case .ending:
                    KJStoryView(lines: KJStory.ending) { go(.clear) }
                case .clear:
                    KJClearView(again: { won = []; go(.opening) },
                                redoSetup: { KJ.onboarded = false; won = []; go(.setup) },
                                home: { Speaker.shared.stop(); app.go(.home) })
                }
            }
            .transition(.opacity)
            // top bar: back home and the slow-voice switch
            VStack {
                HStack {
                    BackChip { Speaker.shared.stop(); app.go(.home) }
                    Spacer()
                    if step != .setup && step != .clear {
                        Button { Speaker.shared.stop(); go(nextStep) } label: {
                            Image(systemName: "forward.end.fill").font(.system(size: 15.s, weight: .bold)).foregroundStyle(Color.ink)
                                .padding(.horizontal, 12.s).padding(.vertical, 9.s)
                                .background(Capsule().fill(Color.white).overlay(Capsule().stroke(Color.ink, lineWidth: 3)))
                        }
                        .buttonStyle(PressStyle(radius: 30, depth: 3))
                        .padding(.top, UIScale.isPad ? 30 : 0)
                    }
                    KJSlowButton()
                }
                .padding(.horizontal, 14.s).padding(.top, 6.s)
                Spacer()
            }
        }
        .onAppear { AudioManager.shared.playBGM(.area(.lv1)) }
    }

    /// where the skip button jumps to (testing: never get stuck)
    private var nextStep: Step {
        switch step {
        case .setup: return .opening
        case .opening: return .learn(0)
        case .learn: return .battle
        case .battle: won = Set(KJData.aRow.map(\.kana)); return .signs
        case .signs: return .phrases(0)
        case .phrases: return .phraseQuiz
        case .phraseQuiz: return .ending
        case .ending, .clear: return .clear
        }
    }

    private func go(_ s: Step) {
        withAnimation(.easeInOut(duration: 0.3)) { step = s }
    }
}

/// full-screen town picture (portrait: fills the screen, never letterboxed)
struct KJBackdrop: View {
    var dim: Double
    var body: some View {
        GeometryReader { g in
            Image("旅01_浅草_雷門").resizable().scaledToFill()
                .frame(width: g.size.width, height: g.size.height).clipped()
                .overlay(Color.white.opacity(dim))
        }
        .ignoresSafeArea()
    }
}

struct KJSlowButton: View {
    @EnvironmentObject var settings: SettingsStore
    var body: some View {
        Button { AudioManager.shared.se(.tap); settings.slowVoice.toggle() } label: {
            Text(settings.slowVoice ? "🐢 ON" : "🐢 OFF")
                .font(.ui(14.s)).foregroundStyle(Color.ink)
                .padding(.horizontal, 12.s).padding(.vertical, 8.s)
                .background(Capsule().fill(settings.slowVoice ? Color.mint : Color.white).overlay(Capsule().stroke(Color.ink, lineWidth: 3)))
        }
        .buttonStyle(PressStyle(radius: 30, depth: 3))
        .padding(.top, UIScale.isPad ? 30 : 0)
    }
}

// MARK: - first screens: language, name, why, level, promise

struct KJSetupView: View {
    var done: () -> Void
    @State private var page = 0
    @State private var name = KJ.name
    @State private var level = 0

    var body: some View {
        VStack(spacing: 16.s) {
            Spacer(minLength: 60.s)
            Image(page == 4 ? "nk_nyan_joy" : "nk_nyan_wave").resizable().scaledToFit().frame(height: 150.s)
                .modifier(Bob())
            PaperCard {
                VStack(spacing: 14.s) {
                    switch page {
                    case 0:
                        title("Choose your language\nことばを えらんでね")
                        choice("English", "en"); choice("中文（繁體）", "zh"); choice("한국어", "ko")
                    case 1:
                        title(KJ.both("What's your name?", "你叫什麼名字？", "이름이 뭐예요?"))
                        TextField(KJ.t("Your name", "你的名字", "이름"), text: $name)
                            .font(.ui(22.s)).multilineTextAlignment(.center)
                            .padding(12.s)
                            .background(RoundedRectangle(cornerRadius: 14.s).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 14.s).stroke(Color.ink, lineWidth: 3)))
                            .textInputAutocapitalization(.words).autocorrectionDisabled()
                        Text(KJ.both("You'll learn to say it in Japanese today.", "今天就能用日語說出來。", "오늘 일본어로 말할 수 있게 돼요."))
                            .font(.ui(14.s, bold: false)).foregroundStyle(Color.ink.opacity(0.7))
                        KJButton(title: "OK", color: .mint) {
                            KJ.name = name.trimmingCharacters(in: .whitespaces); next()
                        }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    case 2:
                        title(KJ.both("Why are you learning Japanese?", "為什麼學日語？", "왜 일본어를 배우나요?"))
                        reason(KJ.both("Anime & manga", "動漫", "애니·만화"))
                        reason(KJ.both("Travel", "旅行", "여행"))
                        reason(KJ.both("Work or school", "工作・學校", "일·학교"))
                        reason(KJ.both("JLPT", "日語檢定 JLPT", "JLPT 시험"))
                    case 3:
                        title(KJ.both("How much do you know?", "你會多少？", "얼마나 알아요?"))
                        KJButton(title: KJ.both("I'm brand new", "完全不會", "처음이에요"), color: .white) { level = 0; next() }
                        KJButton(title: KJ.both("I know some hiragana", "會一點平假名", "히라가나 조금 알아요"), color: .white) { level = 1; next() }
                    default:
                        title(KJ.both("Here's the plan", "學習計畫", "이렇게 배워요"))
                        promise("5", KJ.both("letters in your first 3 minutes", "個假名，3分鐘內學會", "글자를 처음 3분 안에"))
                        promise("7", KJ.both("days to read all 46 hiragana", "天讀懂全部46個平假名", "일이면 히라가나 46자를 전부"))
                        promise("3", KJ.both("phrases you can say today", "句今天就能說的話", "문장을 오늘 바로 말해요"))
                        KJButton(title: KJ.both("Let's go!", "出發！", "출발!"), color: .pop, textColor: .white) {
                            KJ.onboarded = true; done()
                        }
                    }
                }
            }
            .padding(.horizontal, 20.s)
            Spacer()
        }
    }

    private func next() { AudioManager.shared.se(.decide); withAnimation { page += 1 } }
    private func title(_ s: String) -> some View {
        Text(s).font(.ui(20.s)).foregroundStyle(Color.ink).multilineTextAlignment(.center)
    }
    private func choice(_ label: String, _ code: String) -> some View {
        KJButton(title: label, color: .white) { KJ.lang = code; next() }
    }
    private func reason(_ label: String) -> some View {
        KJButton(title: label, color: .white) { next() }
    }
    private func promise(_ n: String, _ s: String) -> some View {
        HStack(spacing: 12.s) {
            Text(n).font(.display(34.s)).foregroundStyle(Color.popDeep).frame(width: 54.s)
            Text(s).font(.ui(16.s)).foregroundStyle(Color.ink).frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - story: partner on the left, Nyan on the right, plain Japanese with a subtitle

struct KJStoryView: View {
    var lines: [KJLine]
    var done: () -> Void
    @State private var i = 0
    @State private var bump = false

    var body: some View {
        let line = lines[min(i, lines.count - 1)]
        GeometryReader { g in
            ZStack(alignment: .bottom) {
                // the two always on stage; the one talking steps forward
                HStack(alignment: .bottom, spacing: 0) {
                    Image(soraFace(line)).resizable().scaledToFit()
                        .frame(width: g.size.width * 0.52, height: g.size.height * 0.5, alignment: .bottom)
                        .scaleEffect(line.who == .sora ? 1.04 : 0.96, anchor: .bottom)
                        .brightness(line.who == .nyan ? -0.12 : 0)
                    ZStack(alignment: .bottom) {
                        if line.pose {
                            StarBurst().fill(Color.sun.opacity(0.85))
                                .frame(width: g.size.width * 0.5, height: g.size.width * 0.5)
                                .rotationEffect(.degrees(bump ? 20 : -20))
                                .offset(y: -g.size.height * 0.06)
                        }
                        Image(nyanFace(line)).resizable().scaledToFit()
                            .frame(width: g.size.width * 0.46, height: g.size.height * 0.36, alignment: .bottom)
                            .rotationEffect(.degrees(line.pose ? (bump ? -8 : 8) : 0), anchor: .bottom)
                            .scaleEffect(line.who == .nyan ? (line.pose && bump ? 1.15 : 1.04) : 0.96, anchor: .bottom)
                            .brightness(line.who == .sora ? -0.12 : 0)
                    }
                }
                .frame(width: g.size.width)
                .padding(.bottom, 190.s)

                // text box
                VStack(alignment: .leading, spacing: 6.s) {
                    if line.who != .narr {
                        Text(line.who == .sora ? "ソラ" : "ニャン")
                            .font(.ui(15.s)).foregroundStyle(.white)
                            .padding(.horizontal, 12.s).padding(.vertical, 3.s)
                            .background(Capsule().fill(line.who == .sora ? Color.sky : Color.orange))
                    }
                    Text(line.ja).font(.ui(23.s)).foregroundStyle(Color.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(line.sub).font(.ui(15.s, bold: false)).foregroundStyle(Color.ink.opacity(0.65))
                        .fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Button { say(line) } label: {
                            Image(systemName: "speaker.wave.2.fill").font(.system(size: 18.s, weight: .bold)).foregroundStyle(Color.ink)
                        }
                        Spacer()
                        Image(systemName: "chevron.down.circle.fill").font(.system(size: 22.s)).foregroundStyle(Color.pop)
                            .modifier(Bob())
                    }
                }
                .padding(16.s)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: 170.s, alignment: .top)
                .background(RoundedRectangle(cornerRadius: 22.s).fill(Color.paper).overlay(RoundedRectangle(cornerRadius: 22.s).stroke(Color.ink, lineWidth: 4)))
                .padding(.horizontal, 14.s).padding(.bottom, 16.s)
            }
            .frame(width: g.size.width, height: g.size.height)
            .contentShape(Rectangle())
            .onTapGesture { advance() }
        }
        .onAppear { start(lines[0]) }
    }

    private func soraFace(_ l: KJLine) -> String {
        if l.who == .sora { return l.face }
        if let last = lines[0...min(i, lines.count - 1)].last(where: { $0.who == .sora }) { return last.face }
        return "sora_full"
    }
    private func nyanFace(_ l: KJLine) -> String {
        if l.who == .nyan { return l.face }
        if let last = lines[0...min(i, lines.count - 1)].last(where: { $0.who == .nyan }) { return last.face }
        return "nk_nyan"
    }

    private func start(_ l: KJLine) {
        say(l)
        bump = false
        if l.pose {
            AudioManager.shared.se(.kira)
            withAnimation(.easeInOut(duration: 0.18).repeatCount(5, autoreverses: true)) { bump = true }
        }
    }
    private func say(_ l: KJLine) {
        switch l.who {
        case .narr: Speaker.shared.say(l.ja, gender: .female)
        case .sora: Speaker.shared.say(l.ja, gender: .male)
        case .nyan: Speaker.shared.say(l.ja, voice: .nyan)
        }
    }
    private func advance() {
        AudioManager.shared.se(.tap, rate: 1.3, volume: 0.3)
        if i + 1 < lines.count {
            i += 1
            start(lines[i])
        } else {
            Speaker.shared.stop()
            done()
        }
    }
}

// MARK: - learning one letter

struct KJLearnCard: View {
    var letter: KJLetter
    var index: Int
    var next: () -> Void
    @State private var shown = false

    var body: some View {
        VStack(spacing: 14.s) {
            Spacer(minLength: 70.s)
            Text("\(index + 1) / 5").font(.ui(15.s)).foregroundStyle(Color.ink.opacity(0.6))
            PaperCard {
                VStack(spacing: 10.s) {
                    Button { Speaker.shared.say(letter.kana) } label: {
                        Text(letter.kana).font(.custom(Fonts.rounded, size: 150.s)).foregroundStyle(Color.ink)
                            .scaleEffect(shown ? 1 : 0.4).opacity(shown ? 1 : 0)
                    }
                    .buttonStyle(.plain)
                    Text(letter.romaji).font(.display(30.s)).foregroundStyle(Color.popDeep)
                    Text(letter.aid).font(.ui(17.s)).foregroundStyle(Color.ink)
                        .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                    Text(letter.ja).font(.ui(14.s, bold: false)).foregroundStyle(Color.ink.opacity(0.6))
                        .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 6.s) {
                        Image(systemName: "speaker.wave.2.fill")
                        Text(KJ.both("Tap the letter to hear it", "點一下假名聽發音", "글자를 누르면 소리가 나요"))
                    }
                    .font(.ui(13.s, bold: false)).foregroundStyle(Color.ink.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 22.s)
            HStack(alignment: .bottom) {
                Image("nk_nyan_tip").resizable().scaledToFit().frame(height: 110.s)
                Spacer()
            }
            .padding(.horizontal, 22.s)
            KJButton(title: KJ.both("Next", "下一個", "다음"), color: .mint) { next() }
                .padding(.horizontal, 22.s)
            Spacer(minLength: 20.s)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) { shown = true }
            later(0.3) { Speaker.shared.say(letter.kana) }
        }
    }
}

// MARK: - quiz: hear it, pick it — each right answer sends the letter back to the signs

struct KJLetterQuiz: View {
    @Binding var won: Set<String>
    var done: () -> Void
    @State private var order: [KJLetter] = []
    @State private var q = 0
    @State private var options: [String] = []
    @State private var picked: String?
    @State private var shake = false

    var body: some View {
        VStack(spacing: 16.s) {
            Spacer(minLength: 64.s)
            KJSignBoard(won: won)
            Text(KJ.both("Listen and tap the letter", "聽發音，選出假名", "듣고 글자를 고르세요"))
                .font(.ui(18.s)).foregroundStyle(Color.ink)
            Button { play() } label: {
                Image(systemName: "speaker.wave.3.fill").font(.system(size: 40.s, weight: .bold)).foregroundStyle(.white)
                    .frame(width: 96.s, height: 96.s)
                    .background(Circle().fill(Color.sky).overlay(Circle().stroke(Color.ink, lineWidth: 4)))
            }
            .buttonStyle(PressStyle(radius: 48.s, depth: 5))
            // easy mode: the sound written in roman letters as a hint
            if let cur = order[safe: q] {
                Text(cur.romaji).font(.display(22.s)).foregroundStyle(Color.ink.opacity(0.45))
            }
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14.s), GridItem(.flexible(), spacing: 14.s)], spacing: 14.s) {
                ForEach(options, id: \.self) { o in
                    Button { answer(o) } label: {
                        Text(o).font(.custom(Fonts.rounded, size: 54.s)).foregroundStyle(Color.ink)
                            .frame(maxWidth: .infinity, minHeight: 92.s)
                            .background(RoundedRectangle(cornerRadius: 18.s).fill(color(o)).overlay(RoundedRectangle(cornerRadius: 18.s).stroke(Color.ink, lineWidth: 3)))
                    }
                    .buttonStyle(PressStyle(radius: 18.s, depth: 5))
                    .disabled(picked != nil)
                }
            }
            .padding(.horizontal, 22.s)
            .offset(x: shake ? -10 : 0)
            Text("\(min(q + 1, max(order.count, 1))) / \(max(order.count, 1))").font(.ui(14.s)).foregroundStyle(Color.ink.opacity(0.6))
            Spacer()
        }
        .onAppear(perform: setUp)
    }

    private var current: KJLetter? { order[safe: q] }

    private func setUp() {
        // every letter twice, mixed, never the same one twice in a row
        var o = (KJData.aRow + KJData.aRow).shuffled()
        for k in 1..<o.count where o[k].kana == o[k - 1].kana { o.swapAt(k, (k + 2) % o.count) }
        order = o
        q = 0
        makeOptions()
    }
    private func makeOptions() {
        guard let c = current else { return }
        let others = KJData.aRow.map(\.kana).filter { $0 != c.kana }.shuffled().prefix(3)
        options = ([c.kana] + others).shuffled()
        picked = nil
        later(0.35) { play() }
    }
    private func play() { if let c = current { Speaker.shared.say(c.kana) } }
    private func color(_ o: String) -> Color {
        guard let p = picked, let c = current else { return .white }
        if o == c.kana { return .mint }
        if o == p { return .danger }
        return .white
    }
    private func answer(_ o: String) {
        guard let c = current else { return }
        picked = o
        if o == c.kana {
            AudioManager.shared.se(.kira)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { _ = won.insert(o) }
            later(0.7) { step() }
        } else {
            AudioManager.shared.se(.wrong)
            withAnimation(.default.repeatCount(3, autoreverses: true).speed(4)) { shake = true }
            later(0.3) { shake = false }
            later(0.5) { play() }
            // the same letter comes again later
            order.append(c)
            later(1.4) { step() }
        }
    }
    private func step() {
        if q + 1 < order.count { q += 1; makeOptions() } else { done() }
    }
}

extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}

/// the town's signs: letters not won back yet show as blanks
struct KJSignBoard: View {
    var won: Set<String>
    var body: some View {
        HStack(spacing: 10.s) {
            ForEach(KJData.signs, id: \.word) { s in
                let full = s.word.allSatisfy { won.contains(String($0)) }
                VStack(spacing: 4.s) {
                    HStack(spacing: 2.s) {
                        ForEach(Array(s.word.enumerated()), id: \.offset) { _, ch in
                            let c = String(ch)
                            Text(won.contains(c) ? c : "？")
                                .font(.custom(Fonts.rounded, size: 30.s))
                                .foregroundStyle(won.contains(c) ? Color.white : Color.white.opacity(0.35))
                                .scaleEffect(won.contains(c) ? 1 : 0.8)
                        }
                    }
                    .padding(.horizontal, 12.s).padding(.vertical, 6.s)
                    .background(RoundedRectangle(cornerRadius: 10.s).fill(Color(hex: 0x8A5A3B)).overlay(RoundedRectangle(cornerRadius: 10.s).stroke(Color.ink, lineWidth: 3)))
                    Text(full ? KJ.t(s.en, s.zh, s.ko) : " ").font(.ui(12.s)).foregroundStyle(Color.ink)
                }
            }
        }
    }
}

// MARK: - phrases

struct KJPhraseCard: View {
    var phrase: KJData.Phrase
    var index: Int
    var next: () -> Void

    var body: some View {
        VStack(spacing: 16.s) {
            Spacer(minLength: 70.s)
            Text(KJ.t("Useful phrase", "實用句子", "유용한 표현") + "  \(index + 1) / 3")
                .font(.ui(15.s)).foregroundStyle(Color.ink.opacity(0.6))
            PaperCard {
                VStack(spacing: 12.s) {
                    Button { Speaker.shared.say(phrase.ja) } label: {
                        Text(phrase.ja).font(.ui(34.s)).foregroundStyle(Color.ink)
                            .multilineTextAlignment(.center).minimumScaleFactor(0.5).lineLimit(2)
                    }
                    .buttonStyle(.plain)
                    Text(phrase.romaji).font(.display(18.s)).foregroundStyle(Color.popDeep)
                    Text(phrase.meaning).font(.ui(20.s)).foregroundStyle(Color.ink)
                    Text(KJ.both("Say it out loud with Nyan!", "跟著喵一起大聲說！", "냥이랑 같이 소리 내서 말해 봐요!"))
                        .font(.ui(13.s, bold: false)).foregroundStyle(Color.ink.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 22.s)
            HStack {
                Spacer()
                Image("nk_nyan_wave").resizable().scaledToFit().frame(height: 120.s).modifier(Bob())
            }
            .padding(.horizontal, 22.s)
            KJButton(title: KJ.both("Next", "下一個", "다음"), color: .mint) { next() }
                .padding(.horizontal, 22.s)
            Spacer(minLength: 20.s)
        }
        .onAppear { later(0.3) { Speaker.shared.say(phrase.ja) } }
    }
}

struct KJPhraseQuiz: View {
    var done: () -> Void
    @State private var q = 0
    @State private var picked: String?
    @State private var choices: [String] = []
    private let phrases = KJData.phrases()
    private var situations: [String] {
        [KJ.both("You meet someone in the afternoon.", "下午遇到別人時。", "낮에 누군가를 만났어요."),
         KJ.both("Someone gives you a present.", "別人送你禮物時。", "누군가 선물을 줬어요."),
         KJ.both("Tell someone your name.", "告訴別人你的名字。", "내 이름을 말해요.")]
    }

    var body: some View {
        VStack(spacing: 16.s) {
            Spacer(minLength: 70.s)
            Image("sora_think").resizable().scaledToFit().frame(height: 150.s)
            PaperCard {
                Text(situations[min(q, 2)]).font(.ui(19.s)).foregroundStyle(Color.ink)
                    .multilineTextAlignment(.center).frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 22.s)
            Text(KJ.both("What do you say?", "該怎麼說？", "뭐라고 말할까요?")).font(.ui(16.s)).foregroundStyle(Color.ink)
            VStack(spacing: 12.s) {
                ForEach(choices, id: \.self) { c in
                    PopButton(title: c, color: color(c)) { answer(c) }
                        .disabled(picked != nil)
                }
            }
            .padding(.horizontal, 22.s)
            Spacer()
        }
        .onAppear { choices = phrases.map(\.ja).shuffled() }
    }

    private func color(_ c: String) -> Color {
        guard let p = picked else { return .white }
        if c == phrases[q].ja { return .mint }
        return c == p ? .danger : .white
    }
    private func answer(_ c: String) {
        picked = c
        Speaker.shared.say(phrases[q].ja)
        AudioManager.shared.se(c == phrases[q].ja ? .kira : .wrong)
        later(1.4) {
            if q + 1 < phrases.count {
                q += 1; picked = nil; choices = phrases.map(\.ja).shuffled()
            } else { done() }
        }
    }
}

// MARK: - clear

struct KJClearView: View {
    var again: () -> Void
    var redoSetup: () -> Void
    var home: () -> Void
    var body: some View {
        VStack(spacing: 16.s) {
            Spacer(minLength: 70.s)
            RibbonTitle(text: "1-1 CLEAR!")
            Image("nk_nyan_joy").resizable().scaledToFit().frame(height: 160.s).modifier(Bob())
            PaperCard {
                VStack(spacing: 10.s) {
                    row("あいうえお", KJ.both("5 / 46 hiragana", "平假名 5 / 46", "히라가나 5 / 46"))
                    row("こんにちは", KJ.both("3 phrases", "3 句", "표현 3개"))
                    row("うえ・いえ・あお", KJ.both("3 signs back in town", "找回 3 塊招牌", "간판 3개 되찾음"))
                }
            }
            .padding(.horizontal, 22.s)
            KJButton(title: KJ.both("Play again", "再玩一次", "다시 하기"), color: .sun) { again() }.padding(.horizontal, 22.s)
            KJButton(title: KJ.both("Home", "回首頁", "홈으로"), color: .white) { home() }.padding(.horizontal, 22.s)
            Button(KJ.both("Redo first setup", "重新設定", "처음 설정 다시")) { redoSetup() }
                .font(.ui(13.s, bold: false)).foregroundStyle(Color.ink.opacity(0.6))
            Spacer()
        }
        .onAppear { AudioManager.shared.se(.clear) }
    }
    private func row(_ a: String, _ b: String) -> some View {
        HStack {
            Text(a).font(.ui(18.s)).foregroundStyle(Color.ink)
            Spacer()
            Text(b).font(.ui(14.s, bold: false)).foregroundStyle(Color.ink.opacity(0.7))
        }
    }
}

/// chunky button whose label may have a second (Japanese) line
struct KJButton: View {
    var title: String
    var color: Color = .sun
    var textColor: Color = .ink
    var action: () -> Void
    var body: some View {
        let parts = title.split(separator: "\n", maxSplits: 1).map(String.init)
        Button(action: action) {
            VStack(spacing: 1.s) {
                Text(parts[0]).font(.ui(18.s)).lineLimit(1).minimumScaleFactor(0.5)
                if parts.count > 1 {
                    Text(parts[1]).font(.ui(12.s, bold: false)).opacity(0.75).lineLimit(1).minimumScaleFactor(0.5)
                }
            }
            .foregroundStyle(textColor)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, minHeight: 56.s)
            .background(RoundedRectangle(cornerRadius: 16.s, style: .continuous).fill(color))
            .overlay(RoundedRectangle(cornerRadius: 16.s, style: .continuous).stroke(Color.ink, lineWidth: 3))
        }
        .buttonStyle(PressStyle(radius: 16.s, depth: 5))
    }
}
