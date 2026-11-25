import SwiftUI

// MARK: - にゃんカナ ゲームモード
// 最初の設定 → 章のマップ → ステージ（すごく短いお話 → 新しい文字 → ゲーム → クリアの演出 → お話）
// 台本：00_企画/にゃんカナ_ゲーム設計書_v1.md の 21

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
    static let letters: [KJLetter] = letters1 + letters2
    static let letters1: [KJLetter] = [
        KJLetter(kana: "あ", romaji: "a", en: "A cross with a big swirl — you shout \"Ah!\" when you see it.", zh: "來自漢字「安」。安 → あ", ko: "소리는 「아」. あ = 아", ja: "十字と 大きな うずまき。見たら「あ！」"),
        KJLetter(kana: "い", romaji: "i", en: "Two little lines side by side, like two eels: \"ee\".", zh: "來自漢字「以」。以 → い", ko: "소리는 「이」. い = 이", ja: "2本の 線が ならんで「いー」"),
        KJLetter(kana: "う", romaji: "u", en: "A mouth saying \"ooh\" with a small hat on top.", zh: "來自漢字「宇」。宇 → う", ko: "소리는 「우」. う = 우", ja: "「うー」と いう口に 小さな ぼうし"),
        KJLetter(kana: "え", romaji: "e", en: "A bird with a feather on its head asking \"eh?\"", zh: "來自漢字「衣」。衣 → え", ko: "소리는 「에」. え = 에", ja: "頭に はねの ある 鳥が「え？」"),
        KJLetter(kana: "お", romaji: "o", en: "A golfer swinging — the ball flies off: \"Oh!\"", zh: "來自漢字「於」。於 → お", ko: "소리는 「오」. お = 오", ja: "ゴルフの スイングで ボールが とんで「お！」"),
        KJLetter(kana: "か", romaji: "ka", en: "A karate kick with a little shout mark: \"Ka!\"", zh: "來自漢字「加」。加 → か", ko: "소리는 「카」. か = 카", ja: "カラテの キックで「か！」"),
        KJLetter(kana: "き", romaji: "ki", en: "A key with two teeth: \"ki\" like key.", zh: "來自漢字「幾」。幾 → き", ko: "소리는 「키」. き = 키", ja: "カギ（key）の 形で「き」"),
        KJLetter(kana: "く", romaji: "ku", en: "A beak opening: a cuckoo says \"ku\".", zh: "來自漢字「久」。久 → く", ko: "소리는 「쿠」. く = 쿠", ja: "くちばしが 開いて「く」"),
        KJLetter(kana: "け", romaji: "ke", en: "A keg next to a tall line: \"ke\".", zh: "來自漢字「計」。計 → け", ko: "소리는 「케」. け = 케", ja: "たるの となりに たて線で「け」"),
        KJLetter(kana: "こ", romaji: "ko", en: "Two lines like a coin slot: \"ko\".", zh: "來自漢字「己」。己 → こ", ko: "소리는 「코」. こ = 코", ja: "コインを 入れる すき間のような 2本線"),
        KJLetter(kana: "さ", romaji: "sa", en: "A samurai sword crossing a curved line: \"sa\".", zh: "來自漢字「左」。左 → さ", ko: "소리는 「사」. さ = 사", ja: "さむらいの 刀が 交わる「さ」"),
        KJLetter(kana: "し", romaji: "shi", en: "A fishing hook: \"she\" catches a fish.", zh: "來自漢字「之」。之 → し", ko: "소리는 「시」. し = 시", ja: "つりばりの 形で「し」"),
        KJLetter(kana: "す", romaji: "su", en: "A loop like a swing: \"su\".", zh: "來自漢字「寸」。寸 → す", ko: "소리는 「스」. す = 스", ja: "ブランコの ような わっかで「す」"),
        KJLetter(kana: "せ", romaji: "se", en: "A mouth with a tooth sticking out: \"se\".", zh: "來自漢字「世」。世 → せ", ko: "소리는 「세」. せ = 세", ja: "出っぱった 歯の ような「せ」"),
        KJLetter(kana: "そ", romaji: "so", en: "A zigzag like sewing thread: \"so\" (sew).", zh: "來自漢字「曽」。曽 → そ", ko: "소리는 「소」. そ = 소", ja: "ぬい糸の ジグザグで「そ」"),
        KJLetter(kana: "た", romaji: "ta", en: "The letters \"t\" and \"a\" side by side: \"ta\".", zh: "來自漢字「太」。太 → た", ko: "소리는 「타」. た = 타", ja: "tと aが ならんで「た」"),
        KJLetter(kana: "ち", romaji: "chi", en: "A cheerleader with a pom-pom: \"chi\".", zh: "來自漢字「知」。知 → ち", ko: "소리는 「치」. ち = 치", ja: "チアリーダーの ポンポンで「ち」"),
        KJLetter(kana: "つ", romaji: "tsu", en: "A wave from a tsunami: \"tsu\".", zh: "來自漢字「川」。川 → つ", ko: "소리는 「츠」. つ = 츠", ja: "つなみの 波の 形で「つ」"),
        KJLetter(kana: "て", romaji: "te", en: "A hand reaching out: \"te\" means hand.", zh: "來自漢字「天」。天 → て", ko: "소리는 「테」. て = 테", ja: "手を のばした 形。「て」は 手"),
        KJLetter(kana: "と", romaji: "to", en: "A toe with a splinter: \"to\".", zh: "來自漢字「止」。止 → と", ko: "소리는 「토」. と = 토", ja: "つま先（toe）に トゲで「と」"),
        KJLetter(kana: "な", romaji: "na", en: "A nun praying by a cross: \"na\".", zh: "來自漢字「奈」。奈 → な", ko: "소리는 「나」. な = 나", ja: "十字の そばで いのる人で「な」"),
        KJLetter(kana: "に", romaji: "ni", en: "A knee next to two lines: \"ni\".", zh: "來自漢字「仁」。仁 → に", ko: "소리는 「니」. に = 니", ja: "ひざ（knee）と 2本線で「に」"),
        KJLetter(kana: "ぬ", romaji: "nu", en: "Noodles twirled on chopsticks: \"nu\".", zh: "來自漢字「奴」。奴 → ぬ", ko: "소리는 「누」. ぬ = 누", ja: "はしで まいた めん（noodle）で「ぬ」"),
        KJLetter(kana: "ね", romaji: "ne", en: "A cat curled up with its tail: neko \"ne\".", zh: "來自漢字「祢」。祢 → ね", ko: "소리는 「네」. ね = 네", ja: "しっぽを まいた ねこで「ね」"),
        KJLetter(kana: "の", romaji: "no", en: "A \"no entry\" circle: \"no\".", zh: "來自漢字「乃」。乃 → の", ko: "소리는 「노」. の = 노", ja: "「だめ（no）」の まるで「の」"),
    ]
    static func letter(_ k: String) -> KJLetter? { letters.first { $0.kana == k } }
    static func romaji(_ k: String) -> String { letter(k)?.romaji ?? "" }

    struct Word {
        var ja: String; var emoji: String; var en: String; var zh: String; var ko: String
        var meaning: String { KJ.t(en, zh, ko) }
    }
    static let words: [Word] = words1 + words2
    static let words1: [Word] = [
        Word(ja: "あお", emoji: "🔵", en: "blue", zh: "藍色", ko: "파랑"),
        Word(ja: "いえ", emoji: "🏠", en: "house", zh: "家", ko: "집"),
        Word(ja: "うえ", emoji: "⬆️", en: "up", zh: "上面", ko: "위"),
        Word(ja: "かお", emoji: "😊", en: "face", zh: "臉", ko: "얼굴"),
        Word(ja: "あかい", emoji: "🔴", en: "red", zh: "紅色的", ko: "빨간"),
        Word(ja: "こえ", emoji: "🗣️", en: "voice", zh: "聲音", ko: "목소리"),
        Word(ja: "すし", emoji: "🍣", en: "sushi", zh: "壽司", ko: "초밥"),
        Word(ja: "かさ", emoji: "☂️", en: "umbrella", zh: "傘", ko: "우산"),
        Word(ja: "あし", emoji: "🦶", en: "foot", zh: "腳", ko: "발"),
        Word(ja: "たこ", emoji: "🐙", en: "octopus", zh: "章魚", ko: "문어"),
        Word(ja: "て", emoji: "✋", en: "hand", zh: "手", ko: "손"),
        Word(ja: "つくえ", emoji: "🪑", en: "desk", zh: "桌子", ko: "책상"),
        Word(ja: "ねこ", emoji: "🐱", en: "cat", zh: "貓", ko: "고양이"),
        Word(ja: "いぬ", emoji: "🐶", en: "dog", zh: "狗", ko: "개"),
        Word(ja: "さかな", emoji: "🐟", en: "fish", zh: "魚", ko: "물고기"),
    ]
    static func word(_ w: String) -> Word? { words.first { $0.ja == w } }

    /// letters that look alike: when both are known, they are mixed in on purpose
    static let lookAlike: [[String]] = lookAlike1 + lookAlike2
    static let lookAlike1: [[String]] = [["あ", "お"], ["き", "さ", "ち"], ["ぬ", "め"], ["ね", "れ", "わ"], ["い", "こ"], ["し", "つ"], ["た", "な"], ["て", "と"]]
}

// MARK: story lines

struct KJLine {
    /// "n" narrator, "s" Sora, "y" Nyan, or a side character's id (its recorded voice uses the same id)
    var role: String
    var face: String = ""       // picture name (expression)
    var ja: String
    var en: String
    var zh: String
    var ko: String
    var sub: String { KJ.t(en, zh, ko) }
    var isNarr: Bool { role == "n" }
    var isSora: Bool { role == "s" }
    var isNyan: Bool { role == "y" }
    var isOther: Bool { !isNarr && !isSora && !isNyan }
    /// Nyan's big dramatic pose (the joke is in the action, the words stay plain)
    var pose: Bool { face == "nk_nyan_hero" || face == "boss_kyubi" }
    var silent: Bool { ja.allSatisfy { $0 == "…" } }
    var name: String {
        switch role {
        case "s": return "ソラ"
        case "y": return "ニャン"
        case "kara": return "からかさおばけ"
        case "kyubi": return "きゅうびの きつね"
        case "fans": return "まちの ひと"
        default: return "おみせの ひと"
        }
    }
}

// MARK: - the whole flow

struct KanaJourneyView: View {
    @EnvironmentObject var app: AppState
    enum Screen: Equatable { case setup, map, stage(Int), playground }
    @State private var screen: Screen
    /// back from the もじレスキュー boss battle
    @State private var resume: KanaRescue.Outcome?

    init() {
        let r = KanaRescue.outcome
        KanaRescue.outcome = nil
        _resume = State(initialValue: r)
        if let r, r.cleared {
            _screen = State(initialValue: .stage(r.stageID))
        } else {
            _screen = State(initialValue: KJ.onboarded ? .map : .setup)
        }
    }

    var body: some View {
        ZStack {
            switch screen {
            case .setup:
                ZStack {
                    KJBackdrop(bg: "旅01_浅草_雷門", dim: 0.45)
                    KJSetupView { go(.stage(1)) }
                    VStack {
                        HStack { BackChip { Speaker.shared.stop(); app.go(.home) }; Spacer() }
                            .padding(.horizontal, 14.s).padding(.top, 6.s)
                        Spacer()
                    }
                }
            case .map:
                KJMapView(play: { go(.stage($0)) },
                          home: { Speaker.shared.stop(); app.go(.home) },
                          redoSetup: { KJ.onboarded = false; go(.setup) },
                          playground: { go(.playground) })
            case .playground:
                KJPlayground { AudioManager.shared.playBGM(.area(.lv1)); go(.map) }
            case .stage(let n):
                KJStageView(stage: KJC1.stage(n), resume: resume,
                            next: { go(KJC1.next(after: n).map { .stage($0) } ?? .map) },
                            map: { Speaker.shared.stop(); go(.map) })
                    .id(n)
            }
        }
        .transition(.opacity)
        .onAppear { AudioManager.shared.playBGM(.area(.lv1)) }
    }

    private func go(_ s: Screen) {
        resume = nil
        withAnimation(.easeInOut(duration: 0.3)) { screen = s }
    }
}

/// full-screen place picture (portrait: fills the screen, never letterboxed)
struct KJBackdrop: View {
    var bg: String
    var dim: Double
    var body: some View {
        GeometryReader { g in
            Image(bg).resizable().scaledToFill()
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

// MARK: - story: partner on the left, Nyan on the right, a side character in the middle

struct KJStoryView: View {
    var lines: [KJLine]
    var done: () -> Void
    @State private var i = 0
    @State private var bump = false

    var body: some View {
        let line = lines[min(i, lines.count - 1)]
        let other = lines[0...min(i, lines.count - 1)].last(where: { $0.isOther })
        GeometryReader { g in
            ZStack(alignment: .bottom) {
                // the two always on stage; the one talking steps forward
                HStack(alignment: .bottom, spacing: 0) {
                    Image(soraFace(line)).resizable().scaledToFit()
                        .frame(width: g.size.width * 0.5, height: g.size.height * 0.46, alignment: .bottom)
                        .scaleEffect(line.isSora ? 1.04 : 0.94, anchor: .bottom)
                        .brightness(line.isSora || line.isNarr ? 0 : -0.12)
                    ZStack(alignment: .bottom) {
                        if line.pose && line.isNyan {
                            StarBurst().fill(Color.sun.opacity(0.85))
                                .frame(width: g.size.width * 0.5, height: g.size.width * 0.5)
                                .rotationEffect(.degrees(bump ? 20 : -20))
                                .offset(y: -g.size.height * 0.06)
                        }
                        Image(nyanFace(line)).resizable().scaledToFit()
                            .frame(width: g.size.width * 0.46, height: g.size.height * 0.36, alignment: .bottom)
                            .rotationEffect(.degrees(line.pose && line.isNyan ? (bump ? -6 : 6) : 0), anchor: .bottom)
                            .scaleEffect(line.isNyan ? (line.pose && bump ? 1.12 : 1.04) : 0.94, anchor: .bottom)
                            .brightness(line.isNyan || line.isNarr ? 0 : -0.12)
                    }
                }
                .frame(width: g.size.width)
                .padding(.bottom, 190.s)

                // a side character (shop keeper, yokai…) stands in the middle, a little behind
                if let o = other, !o.face.isEmpty {
                    Image(o.face).resizable().scaledToFit()
                        .frame(width: g.size.width * 0.62, height: g.size.height * 0.34)
                        .scaleEffect(line.isOther ? 1.05 : 0.92)
                        .brightness(line.isOther ? 0 : -0.1)
                        .modifier(Bob())
                        .position(x: g.size.width / 2, y: g.size.height * 0.3)
                        .transition(.scale.combined(with: .opacity))
                }

                // text box
                VStack(alignment: .leading, spacing: 6.s) {
                    if !line.isNarr {
                        Text(line.name)
                            .font(.ui(15.s)).foregroundStyle(.white)
                            .padding(.horizontal, 12.s).padding(.vertical, 3.s)
                            .background(Capsule().fill(line.isSora ? Color.sky : line.isNyan ? Color.orange : Color.grape))
                    }
                    Text(line.ja).font(.ui(23.s)).foregroundStyle(Color.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(line.sub).font(.ui(15.s, bold: false)).foregroundStyle(Color.ink.opacity(0.65))
                        .fixedSize(horizontal: false, vertical: true)
                    HStack {
                        if !line.silent {
                            Button { say(line) } label: {
                                Image(systemName: "speaker.wave.2.fill").font(.system(size: 18.s, weight: .bold)).foregroundStyle(Color.ink)
                            }
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
        .onAppear { if !lines.isEmpty { start(lines[0]) } else { done() } }
    }

    private func soraFace(_ l: KJLine) -> String {
        if l.isSora { return l.face }
        if let last = lines[0...min(i, lines.count - 1)].last(where: { $0.isSora }) { return last.face }
        return "sora_full"
    }
    private func nyanFace(_ l: KJLine) -> String {
        if l.isNyan { return l.face }
        if let last = lines[0...min(i, lines.count - 1)].last(where: { $0.isNyan }) { return last.face }
        return "nk_nyan"
    }

    private func start(_ l: KJLine) {
        say(l)
        bump = false
        if l.pose {
            AudioManager.shared.se(.kira)
            withAnimation(.easeInOut(duration: 0.18).repeatCount(5, autoreverses: true)) { bump = true }
        }
        if l.face == "sora_shock" { AudioManager.shared.se(.boyon) }
    }
    private func say(_ l: KJLine) {
        if l.silent { Speaker.shared.stop(); return }
        Speaker.shared.sayRole(l.ja, role: l.role)
    }
    private func advance() {
        AudioManager.shared.se(.tap, rate: 1.3, volume: 0.3)
        if i + 1 < lines.count {
            withAnimation(.easeOut(duration: 0.2)) { i += 1 }
            start(lines[i])
        } else {
            Speaker.shared.stop()
            done()
        }
    }
}

// MARK: - learning one new letter (only the letters that are new in this stage)

struct KJLearnCard: View {
    var letter: KJLetter
    var index: Int
    var count: Int
    var next: () -> Void
    @State private var shown = false

    var body: some View {
        VStack(spacing: 14.s) {
            Spacer(minLength: 70.s)
            Text("NEW  \(index + 1) / \(count)").font(.ui(15.s)).foregroundStyle(Color.ink.opacity(0.6))
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
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 22.s)
            HStack(alignment: .bottom) {
                Image("nk_nyan_tip").resizable().scaledToFit().frame(height: 100.s)
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

extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
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
