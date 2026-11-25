import SwiftUI

// MARK: - 第1章（関東）のステージ
// 設計：00_企画/にゃんカナ_ゲーム設計書_v1.md の 21-5。セリフは KJC1Lines.swift（自動生成）。

enum KJC1 {
    enum Kind { case battle, mid, talk, listen, boss, mini }

    struct Stage: Identifiable {
        var id: Int
        var ja: String                // place name in Japanese
        var en: String
        var zh: String
        var ko: String
        var bg: String
        var kind: Kind
        var newKana: [String] = []
        var known: [String] = []      // every letter that can come up
        var words: [String] = []      // words for the picture rounds and the boss
        var goal = 20                 // minions to beat
        var fog = false               // stage 11: the letters fade in the mist
        var tonbi = false             // stage 9: a kite flies over (tap it for a bonus)
        var mini: MGKind? = nil       // a mini-game stage (MiniGames.swift)
        var chapter = 1               // 1 関東 … 7 九州・沖縄 (chapters 2-7: KJChapters.swift)
        var foe: String? = nil        // the mid-boss / boss picture
        var place: String { KJ.t(en, zh, ko) }
        var pre: [KJLine] { (KJC1.lines[id] ?? KJC1.lines2[id])?.pre ?? [] }
        var post: [KJLine] { (KJC1.lines[id] ?? KJC1.lines2[id])?.post ?? [] }
        var bossImage: String { foe ?? (kind == .boss ? "boss_kyubi" : "mid_karakasa") }
    }

    static let A = ["あ", "い", "う", "え", "お"]
    static let K = ["か", "き", "く", "け", "こ"]
    static let S = ["さ", "し", "す", "せ", "そ"]
    static let T = ["た", "ち", "つ", "て", "と"]
    static let N = ["な", "に", "ぬ", "ね", "の"]
    static let all = A + K + S + T + N

    static let stages: [Stage] = stages1 + stages2
    static func stages(in chapter: Int) -> [Stage] { stages.filter { $0.chapter == chapter } }
    static let stages1: [Stage] = [
        Stage(id: 1, ja: "あさくさ・かみなりもん", en: "Asakusa · Kaminarimon", zh: "淺草・雷門", ko: "아사쿠사・가미나리몬",
              bg: "旅01_浅草_雷門", kind: .battle, newKana: A, known: A, words: ["あお", "いえ", "うえ"], goal: 18),
        Stage(id: 101, ja: "しょどう どうじょう", en: "Tracing Dojo", zh: "描字道場", ko: "따라 쓰기 도장",
              bg: "bg_mg_dojo", kind: .mini, known: A, mini: .nazori),
        Stage(id: 2, ja: "あさくさ・なかみせ", en: "Asakusa · Nakamise", zh: "淺草・仲見世", ko: "아사쿠사・나카미세",
              bg: "旅01_浅草_仲見世通り", kind: .battle, newKana: K, known: A + K, words: ["かお", "あかい", "こえ", "あお", "いえ"], goal: 20),
        Stage(id: 102, ja: "かるた たいかい", en: "Karuta Battle", zh: "歌留多大賽", ko: "카루타 대회",
              bg: "bg_mg_karuta", kind: .mini, known: A + K, mini: .karuta),
        Stage(id: 3, ja: "しぶや", en: "Shibuya", zh: "澀谷", ko: "시부야",
              bg: "bg_c1_shibuya", kind: .battle, known: A + K, words: ["かお", "あかい", "こえ", "あお", "いえ", "うえ"], goal: 25),
        Stage(id: 4, ja: "とうきょうタワー", en: "Tokyo Tower", zh: "東京鐵塔", ko: "도쿄 타워",
              bg: "旅01_東京タワー_夜", kind: .battle, newKana: S, known: A + K + S, words: ["すし", "かさ", "あし", "かお", "こえ"], goal: 22),
        Stage(id: 5, ja: "あきはばら", en: "Akihabara", zh: "秋葉原", ko: "아키하바라",
              bg: "bg_c1_akiba", kind: .battle, newKana: T, known: A + K + S + T, words: ["たこ", "て", "つくえ", "すし", "かさ"], goal: 22),
        Stage(id: 6, ja: "あきはばら・あめ", en: "Akihabara · Rain", zh: "秋葉原・雨", ko: "아키하바라・비",
              bg: "bg_c1_akiba_rain", kind: .mid, known: A + K + S + T, words: ["かさ", "たこ", "つくえ", "あし", "すし", "かお"], goal: 12),
        Stage(id: 7, ja: "よこはま・ちゅうかがい", en: "Yokohama Chinatown", zh: "橫濱中華街", ko: "요코하마 차이나타운",
              bg: "bg_c1_chinatown", kind: .talk),
        Stage(id: 8, ja: "かまくら・だいぶつ", en: "Kamakura · Great Buddha", zh: "鎌倉大佛", ko: "가마쿠라 대불",
              bg: "bg_c1_daibutsu", kind: .battle, newKana: N, known: all, words: ["ねこ", "いぬ", "さかな", "たこ", "かさ"], goal: 22),
        Stage(id: 9, ja: "えのしま", en: "Enoshima", zh: "江之島", ko: "에노시마",
              bg: "bg_c1_enoshima", kind: .battle, known: all, words: ["さかな", "ねこ", "いぬ", "すし", "たこ", "て"], goal: 25, tonbi: true),
        Stage(id: 103, ja: "えのしま・もじつり", en: "Enoshima · Fishing", zh: "江之島・釣魚", ko: "에노시마・낚시",
              bg: "bg_c1_enoshima", kind: .mini, known: all, mini: .tsuri),
        Stage(id: 10, ja: "にっこう・とうしょうぐう", en: "Nikko · Toshogu", zh: "日光東照宮", ko: "닛코 도쇼구",
              bg: "旅01_日光東照宮", kind: .listen),
        Stage(id: 11, ja: "なす・せっしょうせき", en: "Nasu · Killing Stone", zh: "那須・殺生石", ko: "나스・살생석",
              bg: "bg_c1_sesshoseki", kind: .battle, known: all, words: ["ねこ", "いぬ", "さかな", "つくえ", "あかい", "かお"], goal: 25, fog: true),
        Stage(id: 12, ja: "なす・よる", en: "Nasu · Night", zh: "那須・夜", ko: "나스・밤",
              bg: "bg_c1_nasu_night", kind: .boss, known: all,
              words: ["あお", "かお", "すし", "かさ", "たこ", "つくえ", "ねこ", "いぬ", "さかな", "あかい", "こえ", "あし"], goal: 14),
    ]

    static func stage(_ n: Int) -> Stage { stages.first { $0.id == n } ?? stages[0] }

    // progress: best stars per stage
    static func stars(_ id: Int) -> Int { UserDefaults.standard.integer(forKey: "kj.c1.s\(id)") }
    static func setStars(_ id: Int, _ s: Int) {
        if s > stars(id) { UserDefaults.standard.set(s, forKey: "kj.c1.s\(id)") }
    }
    static func best(_ id: Int) -> Int { UserDefaults.standard.integer(forKey: "kj.c1.b\(id)") }
    static func setBest(_ id: Int, _ s: Int) {
        if s > best(id) { UserDefaults.standard.set(s, forKey: "kj.c1.b\(id)") }
    }
    /// open when the stage before it (in map order) has a star
    static func unlocked(_ id: Int) -> Bool {
        guard let i = stages.firstIndex(where: { $0.id == id }) else { return false }
        // (a stage already cleared — or one further along — stays open, so saves from before new stages were added keep working)
        return i == 0 || stars(stages[i - 1].id) > 0 || stages[i...].contains { stars($0.id) > 0 }
    }
    /// the stage after this one on the map
    static func next(after id: Int) -> Int? {
        guard let i = stages.firstIndex(where: { $0.id == id }), i + 1 < stages.count else { return nil }
        return stages[i + 1].id
    }
    /// 1, 2, 3… in map order (shown as "1-n")
    static func number(_ id: Int) -> Int {
        let ch = stage(id).chapter
        return (stages(in: ch).firstIndex { $0.id == id } ?? 0) + 1
    }
    /// "2-5" style label
    static func label(_ id: Int) -> String { "\(stage(id).chapter)-\(number(id))" }
    static func chapterName(_ ch: Int) -> String {
        guard let n = chapterNames[ch] else { return "" }
        return KJ.t(n.en, n.zh, n.ko)
    }
}

// MARK: - the chapter map (one screen, no scrolling)

struct KJMapView: View {
    var play: (Int) -> Void
    var home: () -> Void
    var redoSetup: () -> Void
    var playground: () -> Void = {}
    /// which chapter's course is shown (starts on the furthest one that is open)
    @State private var chapter: Int = KJC1.stages.last { KJC1.unlocked($0.id) }?.chapter ?? 1

    private var course: [KJC1.Stage] { KJC1.stages(in: chapter) }
    private var chapterBG: String {
        ["旅01_隅田川の桜並木_夕方", "bg_c2_sendai", "bg_c3_otaru", "bg_c4_shirakawa", "bg_c5_inari", "bg_c6_miyajima", "bg_c7_okinawa"][max(0, min(6, chapter - 1))]
    }

    var body: some View {
        ZStack {
            KJBackdrop(bg: chapterBG, dim: 0.35)
            VStack(spacing: 10.s) {
                HStack {
                    BackChip { home() }
                    Spacer()
                    // あそびば: replay the mini-games
                    Button {
                        AudioManager.shared.se(.decide)
                        playground()
                    } label: {
                        HStack(spacing: 4.s) {
                            Text("🎮").font(.system(size: 16.s))
                            Text("あそびば").font(.custom(Fonts.rounded, size: 14.s)).foregroundStyle(Color.ink)
                        }
                        .padding(.horizontal, 12.s).padding(.vertical, 6.s)
                        .background(Capsule().fill(Color.mint).overlay(Capsule().stroke(Color.ink, lineWidth: 2.5)))
                    }
                    .buttonStyle(PressStyle(radius: 16.s, depth: 3))
                    KJSlowButton()
                }
                .padding(.horizontal, 14.s).padding(.top, 6.s)
                // the chapter: ◀ だい2しょう とうほく ▶
                HStack(spacing: 10.s) {
                    chapterArrow(-1)
                    VStack(spacing: 2.s) {
                        RibbonTitle(text: "だい\(chapter)しょう  \(KJC1.chapterNames[chapter]?.ja ?? "")", size: 20)
                        Text(KJ.t("Chapter \(chapter) · \(KJC1.chapterName(chapter))", "第\(chapter)章・\(KJC1.chapterName(chapter))", "제\(chapter)장・\(KJC1.chapterName(chapter))"))
                            .font(.ui(13.s)).foregroundStyle(.white).shadow(color: .black.opacity(0.6), radius: 2)
                    }
                    chapterArrow(1)
                }
                GeometryReader { g in
                    let cols = 3
                    let rows = Int((Double(course.count) / Double(cols)).rounded(.up))
                    let w = g.size.width / CGFloat(cols), h = g.size.height / CGFloat(rows)
                    ZStack {
                        // the road between the stages (zigzag)
                        Path { p in
                            for (i, s) in course.enumerated() {
                                let pt = point(i, cols: cols, w: w, h: h)
                                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                                _ = s
                            }
                        }
                        .stroke(Color.white.opacity(0.9), style: StrokeStyle(lineWidth: 8.s, lineCap: .round, dash: [2, 14.s]))
                        ForEach(Array(course.enumerated()), id: \.offset) { i, s in
                            node(s).position(point(i, cols: cols, w: w, h: h))
                        }
                    }
                }
                .padding(.horizontal, 6.s)
                Button(KJ.both("Redo first setup", "重新設定", "처음 설정 다시")) { redoSetup() }
                    .font(.ui(12.s, bold: false)).foregroundStyle(Color.ink.opacity(0.6))
                    .padding(.bottom, 8.s)
            }
        }
    }

    private func chapterArrow(_ d: Int) -> some View {
        let n = chapter + d
        let ok = (1...7).contains(n)
        return Button {
            guard ok else { return }
            AudioManager.shared.se(.tap)
            withAnimation(.easeInOut(duration: 0.25)) { chapter = n }
        } label: {
            Image(systemName: d < 0 ? "chevron.left.circle.fill" : "chevron.right.circle.fill")
                .font(.system(size: 30.s, weight: .bold))
                .foregroundStyle(ok ? Color.sun : Color.white.opacity(0.3))
                .background(Circle().fill(Color.ink).padding(3.s))
        }
        .disabled(!ok)
    }

    private func point(_ i: Int, cols: Int, w: CGFloat, h: CGFloat) -> CGPoint {
        let r = i / cols
        let c = r % 2 == 0 ? i % cols : cols - 1 - i % cols
        return CGPoint(x: w * (CGFloat(c) + 0.5), y: h * (CGFloat(r) + 0.5))
    }

    private func node(_ s: KJC1.Stage) -> some View {
        let open = KJC1.unlocked(s.id)
        let stars = KJC1.stars(s.id)
        let special = s.kind == .mid || s.kind == .boss
        let event = s.kind == .talk || s.kind == .listen
        let mini = s.kind == .mini
        return Button {
            guard open else { AudioManager.shared.se(.wrong, volume: 0.5); return }
            AudioManager.shared.se(.decide)
            play(s.id)
        } label: {
            VStack(spacing: 2.s) {
                ZStack {
                    Circle().fill(!open ? Color.white.opacity(0.6) : special ? Color.danger : event ? Color.grape : mini ? Color.mint : Color.sun)
                        .overlay(Circle().stroke(Color.ink, lineWidth: 3))
                        .frame(width: 58.s, height: 58.s)
                    if open {
                        if special {
                            Image(s.bossImage).resizable().scaledToFit().frame(width: 46.s, height: 46.s)
                        } else if let m = s.mini {
                            Text(m.icon).font(.system(size: 28.s))
                        } else {
                            Text("\(KJC1.number(s.id))").font(.display(24.s)).foregroundStyle(Color.ink)
                        }
                    } else {
                        Image(systemName: "lock.fill").font(.system(size: 20.s, weight: .bold)).foregroundStyle(Color.ink.opacity(0.5))
                    }
                }
                Text(s.ja).font(.ui(11.s)).foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.6)
                    .padding(.horizontal, 6.s).padding(.vertical, 1.s)
                    .background(Capsule().fill(Color.white.opacity(0.85)))
                Text(String(repeating: "★", count: stars) + String(repeating: "☆", count: 3 - stars))
                    .font(.ui(11.s)).foregroundStyle(stars > 0 ? Color.sunDeep : Color.ink.opacity(0.3))
            }
            .frame(width: 110.s)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - one stage: short story → new letters → game → clear → short story → result

struct KJStageView: View {
    let stage: KJC1.Stage
    var next: () -> Void
    var map: () -> Void
    enum Step: Equatable { case pre, learn(Int), game, clearFx, post, result }
    @State private var step: Step
    @State private var stars: Int
    @State private var score: Int
    @State private var won: [String]

    /// `resume`: back from the もじレスキュー boss battle — carry on with the clear effect
    init(stage: KJC1.Stage, resume: KanaRescue.Outcome? = nil, next: @escaping () -> Void, map: @escaping () -> Void) {
        self.stage = stage
        self.next = next
        self.map = map
        if let r = resume, r.stageID == stage.id, r.cleared {
            KJC1.setStars(stage.id, r.stars)
            KJC1.setBest(stage.id, r.score)
            _step = State(initialValue: .clearFx)
            _stars = State(initialValue: r.stars)
            _score = State(initialValue: r.score)
            _won = State(initialValue: r.won)
        } else {
            _step = State(initialValue: .pre)
            _stars = State(initialValue: 0)
            _score = State(initialValue: 0)
            _won = State(initialValue: [])
        }
    }

    var body: some View {
        ZStack {
            KJBackdrop(bg: stage.bg, dim: dim)
            Group {
                switch step {
                case .pre:
                    if stage.pre.isEmpty {
                        Color.clear.onAppear { afterPre() }
                    } else {
                        KJStoryView(lines: stage.pre) { afterPre() }
                    }
                case .learn(let i):
                    if let l = KJData.letter(stage.newKana[i]) {
                        KJLearnCard(letter: l, index: i, count: stage.newKana.count) {
                            go(i + 1 < stage.newKana.count ? .learn(i + 1) : .game)
                        }
                        .id(i)
                    }
                case .game:
                    game
                case .clearFx:
                    KJClearFx(stage: stage, won: won) { go(.post) }
                case .post:
                    if stage.post.isEmpty {
                        Color.clear.onAppear { go(.result) }
                    } else {
                        KJStoryView(lines: stage.post) { go(.result) }
                    }
                case .result:
                    KJResultView(stage: stage, stars: stars, score: score, won: won,
                                 next: next, retry: { go(.game) }, map: map)
                }
            }
            .transition(.opacity)
            VStack {
                HStack {
                    BackChip { map() }
                    Spacer()
                    if step != .result {
                        Button { Speaker.shared.stop(); skip() } label: {
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
    }

    private var dim: Double {
        switch step {
        case .pre, .post, .clearFx: return 0.05
        case .game: return 0.2
        default: return 0.45
        }
    }

    @ViewBuilder private var game: some View {
        switch stage.kind {
        case .talk:
            KJTalkEvent { s, sc in finish(s, sc, ["こんにちは", "わたしは〇〇です"]) }
        case .listen:
            KJListenEvent { s, sc in finish(s, sc, []) }
        case .mini:
            MiniGameView(kind: stage.mini ?? .karuta, stage: stage) { s, sc, w in finish(s, sc, w) }
        case .boss:
            // the chapter boss: the original もじレスキュー battle
            KJRescueLauncher(stage: stage)
        default:
            KJBattleView(stage: stage) { s, sc, w in finish(s, sc, w) }
        }
    }

    private func afterPre() { go(stage.newKana.isEmpty ? .game : .learn(0)) }

    private func finish(_ s: Int, _ sc: Int, _ w: [String]) {
        stars = s; score = sc; won = w
        KJC1.setStars(stage.id, s)
        KJC1.setBest(stage.id, sc)
        go(.clearFx)
    }

    /// testing: never get stuck
    private func skip() {
        switch step {
        case .pre: afterPre()
        case .learn: go(.game)
        case .game:
            if stage.kind == .mini { AudioManager.shared.playBGM(.area(.lv1)) }
            finish(max(1, stars), score, stage.newKana)
        case .clearFx: go(.post)
        case .post: go(.result)
        case .result: break
        }
    }

    private func go(_ s: Step) { withAnimation(.easeInOut(duration: 0.3)) { step = s } }
}

// MARK: - clear: the letters fly back onto the town sign (3–5 seconds, then on)

struct KJClearFx: View {
    let stage: KJC1.Stage
    let won: [String]
    var done: () -> Void
    @State private var shown = 0

    private var items: [String] { won.isEmpty ? (stage.newKana.isEmpty ? ["★"] : stage.newKana) : Array(won.prefix(10)) }

    var body: some View {
        VStack(spacing: 16.s) {
            Spacer()
            RibbonTitle(text: "CLEAR!")
            // the sign: blank boards fill one by one
            let cols = min(5, max(1, items.count))
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8.s), count: cols), spacing: 8.s) {
                ForEach(Array(items.enumerated()), id: \.offset) { i, k in
                    Text(i < shown ? k : "？")
                        .font(.custom(Fonts.rounded, size: k.count > 2 ? 22.s : 30.s))
                        .foregroundStyle(i < shown ? Color.white : Color.white.opacity(0.35))
                        .lineLimit(1).minimumScaleFactor(0.5)
                        .frame(maxWidth: .infinity, minHeight: 54.s)
                        .background(RoundedRectangle(cornerRadius: 10.s).fill(Color(hex: 0x8A5A3B)).overlay(RoundedRectangle(cornerRadius: 10.s).stroke(Color.ink, lineWidth: 3)))
                        .scaleEffect(i == shown - 1 ? 1.15 : 1)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: shown)
                }
            }
            .padding(.horizontal, 24.s)
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture { done() }
        .onAppear {
            AudioManager.shared.se(.clear)
            let step = min(0.45, 3.0 / Double(max(items.count, 1)))
            for i in 0..<items.count {
                later(0.4 + step * Double(i)) {
                    shown = i + 1
                    AudioManager.shared.se(.kira, volume: 0.6)
                    if items[i] != "★" { Speaker.shared.say(items[i]) }
                }
            }
            later(0.4 + step * Double(items.count) + 1.2) { done() }
        }
    }
}

// MARK: - result

struct KJResultView: View {
    let stage: KJC1.Stage
    let stars: Int
    let score: Int
    let won: [String]
    var next: () -> Void
    var retry: () -> Void
    var map: () -> Void

    var body: some View {
        VStack(spacing: 14.s) {
            Spacer(minLength: 70.s)
            RibbonTitle(text: "\(KJC1.label(stage.id)) CLEAR!")
            Text(stage.place).font(.ui(16.s)).foregroundStyle(Color.ink)
            Image(stars == 3 ? "nk_nyan_joy" : "nk_nyan_proud").resizable().scaledToFit().frame(height: 140.s).modifier(Bob())
            PaperCard {
                VStack(spacing: 8.s) {
                    Text(String(repeating: "★", count: stars) + String(repeating: "☆", count: 3 - stars))
                        .font(.display(34.s)).foregroundStyle(Color.sunDeep)
                    Text("\(score)").font(.display(24.s)).foregroundStyle(Color.ink).monospacedDigit()
                    Text("BEST  \(KJC1.best(stage.id))").font(.ui(12.s, bold: false)).foregroundStyle(Color.ink.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 30.s)
            KJButton(title: KJ.both("Next", "下一關", "다음"), color: .pop, textColor: .white) { next() }.padding(.horizontal, 30.s)
            HStack(spacing: 10.s) {
                KJButton(title: KJ.both("Play again", "再玩一次", "다시 하기"), color: .sun) { retry() }
                KJButton(title: KJ.both("Map", "地圖", "지도"), color: .white) { map() }
            }
            .padding(.horizontal, 30.s)
            Spacer()
        }
    }
}

// MARK: - event: Yokohama Chinatown — answer the shop keeper (and say your own name)

struct KJTalkEvent: View {
    var finished: (_ stars: Int, _ score: Int) -> Void
    struct Q { var npc: String; var face: String; var en: String; var zh: String; var ko: String; var answer: String }
    // situations (in the learner's language) → the right greeting
    private let all: [Q] = [
        Q(npc: "いらっしゃい！", face: "npc_chinatown", en: "You walk into the shop in the afternoon.", zh: "下午走進店裡。", ko: "낮에 가게에 들어갔어요.", answer: "こんにちは"),
        Q(npc: "はい、どうぞ。", face: "npc_chinatown", en: "The shop keeper hands you a meat bun.", zh: "店員遞給你肉包。", ko: "가게 주인이 고기만두를 줬어요.", answer: "ありがとう"),
        Q(npc: "おはよう！", face: "npc_chinatown", en: "It's 8 in the morning.", zh: "早上8點。", ko: "아침 8시예요.", answer: "おはよう"),
        Q(npc: "こんばんは！", face: "npc_chinatown", en: "It's 8 in the evening.", zh: "晚上8點。", ko: "저녁 8시예요.", answer: "こんばんは"),
        Q(npc: "いたっ！", face: "npc_chinatown", en: "You bump into someone.", zh: "你撞到別人了。", ko: "누군가와 부딪혔어요.", answer: "すみません"),
        Q(npc: "またね！", face: "npc_chinatown", en: "You are leaving the shop.", zh: "你要離開店了。", ko: "가게를 나가요.", answer: "さようなら"),
        Q(npc: "はじめまして！", face: "npc_chinatown", en: "You meet someone for the first time.", zh: "第一次見面。", ko: "처음 만났어요.", answer: "はじめまして"),
    ]
    private let options = ["こんにちは", "ありがとう", "おはよう", "こんばんは", "すみません", "さようなら", "はじめまして"]
    @State private var qs: [Q] = []
    @State private var q = 0
    @State private var choices: [String] = []
    @State private var picked: String?
    @State private var right = 0
    @State private var nameStep = false

    var body: some View {
        VStack(spacing: 14.s) {
            Spacer(minLength: 64.s)
            if nameStep {
                nameCard
            } else if let cur = qs[safe: q] {
                Image(cur.face).resizable().scaledToFit().frame(height: 170.s).modifier(Bob())
                Text(cur.npc).font(.ui(20.s)).foregroundStyle(Color.ink)
                    .padding(.horizontal, 14.s).padding(.vertical, 6.s)
                    .background(Capsule().fill(Color.white).overlay(Capsule().stroke(Color.ink, lineWidth: 3)))
                PaperCard {
                    VStack(spacing: 6.s) {
                        Text(KJ.t(cur.en, cur.zh, cur.ko)).font(.ui(18.s)).foregroundStyle(Color.ink)
                            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                        Text(KJ.both("What do you say?", "該怎麼說？", "뭐라고 말할까요?")).font(.ui(13.s, bold: false)).foregroundStyle(Color.ink.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 22.s)
                VStack(spacing: 10.s) {
                    ForEach(choices, id: \.self) { c in
                        PopButton(title: c, color: color(c, cur)) { answer(c, cur) }
                            .disabled(picked != nil)
                    }
                }
                .padding(.horizontal, 22.s)
                Text("\(q + 1) / \(qs.count)").font(.ui(13.s)).foregroundStyle(Color.ink.opacity(0.6))
            }
            Spacer()
        }
        .onAppear {
            qs = Array(all.shuffled().prefix(6))
            makeChoices()
        }
    }

    // the player says their own name: "わたしは ___ です"
    private var nameCard: some View {
        VStack(spacing: 14.s) {
            Image("npc_chinatown").resizable().scaledToFit().frame(height: 150.s).modifier(Bob())
            PaperCard {
                VStack(spacing: 10.s) {
                    Text("おなまえは？").font(.ui(22.s)).foregroundStyle(Color.ink)
                    HStack(spacing: 6.s) {
                        Text("わたしは").font(.ui(26.s))
                        Text(KJ.name.isEmpty ? "〇〇" : KJ.name).font(.ui(26.s)).foregroundStyle(Color.popDeep)
                            .padding(.horizontal, 8.s)
                            .background(RoundedRectangle(cornerRadius: 8.s).stroke(Color.popDeep, style: StrokeStyle(lineWidth: 2, dash: [5, 4])))
                        Text("です").font(.ui(26.s))
                    }
                    .foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.5)
                    Text(KJ.both("Say it out loud — put your own name in the middle!", "大聲說出來，中間放你的名字！", "소리 내서 말해요. 가운데에 내 이름을!"))
                        .font(.ui(13.s, bold: false)).foregroundStyle(Color.ink.opacity(0.7)).multilineTextAlignment(.center)
                    Button { sayName() } label: {
                        Image(systemName: "speaker.wave.3.fill").font(.system(size: 24.s, weight: .bold)).foregroundStyle(.white)
                            .frame(width: 64.s, height: 64.s)
                            .background(Circle().fill(Color.sky).overlay(Circle().stroke(Color.ink, lineWidth: 3)))
                    }
                    .buttonStyle(PressStyle(radius: 32.s, depth: 4))
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 22.s)
            KJButton(title: KJ.both("I said it!", "我說出來了！", "말했어요!"), color: .mint) {
                AudioManager.shared.se(.clear)
                let stars = right >= qs.count ? 3 : right >= qs.count - 1 ? 2 : 1
                finished(stars, right * 300 + 500)
            }
            .padding(.horizontal, 22.s)
        }
        .onAppear { later(0.4) { sayName() } }
    }

    private func sayName() {
        // "わたしは" … (your turn) … "です"
        Speaker.shared.say("わたしは")
        later(2.2) { Speaker.shared.say("です") }
    }

    private func makeChoices() {
        guard let cur = qs[safe: q] else { return }
        let others = options.filter { $0 != cur.answer }.shuffled().prefix(2)
        choices = ([cur.answer] + others).shuffled()
        picked = nil
    }
    private func color(_ c: String, _ cur: Q) -> Color {
        guard let p = picked else { return .white }
        if c == cur.answer { return .mint }
        return c == p ? .danger : .white
    }
    private func answer(_ c: String, _ cur: Q) {
        picked = c
        Speaker.shared.say(cur.answer)
        if c == cur.answer { right += 1; AudioManager.shared.se(.kira) } else { AudioManager.shared.se(.wrong) }
        later(1.4) {
            if q + 1 < qs.count { q += 1; makeChoices() } else { withAnimation { nameStep = true } }
        }
    }
}

// MARK: - event: Nikko's three monkeys — ears only (no letters on the screen until you answer)

struct KJListenEvent: View {
    var finished: (_ stars: Int, _ score: Int) -> Void
    private static let pool: [String] = KJData.words.map(\.ja) + ["こんにちは", "ありがとう", "すみません", "おはよう", "こんばんは", "さようなら"]
    @State private var qs: [String] = []
    @State private var q = 0
    @State private var choices: [String] = []
    @State private var picked: String?
    @State private var right = 0

    var body: some View {
        VStack(spacing: 14.s) {
            Spacer(minLength: 64.s)
            Image("npc_sanzaru").resizable().scaledToFit().frame(height: 120.s).modifier(Bob())
            Text(KJ.both("No peeking — just listen!", "不要偷看，用耳朵聽！", "보지 말고 귀로만 들어요!"))
                .font(.ui(16.s)).foregroundStyle(Color.ink).multilineTextAlignment(.center)
            Button { play() } label: {
                Image(systemName: "ear.fill").font(.system(size: 40.s, weight: .bold)).foregroundStyle(.white)
                    .frame(width: 96.s, height: 96.s)
                    .background(Circle().fill(Color.grape).overlay(Circle().stroke(Color.ink, lineWidth: 4)))
            }
            .buttonStyle(PressStyle(radius: 48.s, depth: 5))
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12.s), GridItem(.flexible(), spacing: 12.s)], spacing: 12.s) {
                ForEach(choices, id: \.self) { c in
                    Button { answer(c) } label: {
                        Text(c).font(.ui(c.count > 4 ? 20.s : 26.s)).foregroundStyle(Color.ink)
                            .lineLimit(1).minimumScaleFactor(0.5)
                            .frame(maxWidth: .infinity, minHeight: 70.s)
                            .background(RoundedRectangle(cornerRadius: 16.s).fill(color(c)).overlay(RoundedRectangle(cornerRadius: 16.s).stroke(Color.ink, lineWidth: 3)))
                    }
                    .buttonStyle(PressStyle(radius: 16.s, depth: 5))
                    .disabled(picked != nil)
                }
            }
            .padding(.horizontal, 22.s)
            Text("\(min(q + 1, max(qs.count, 1))) / \(max(qs.count, 1))").font(.ui(13.s)).foregroundStyle(Color.ink.opacity(0.6))
            Spacer()
        }
        .onAppear {
            qs = Array(Self.pool.shuffled().prefix(10))
            makeChoices()
        }
    }

    private func play() { if let c = qs[safe: q] { Speaker.shared.say(c) } }
    private func makeChoices() {
        guard let cur = qs[safe: q] else { return }
        // similar-looking or similar-sounding choices make it a real listening test
        let others = Self.pool.filter { $0 != cur && ($0.count == cur.count || $0.first == cur.first) }.shuffled().prefix(3)
        var c = [cur] + others
        for x in Self.pool.shuffled() where c.count < 4 && !c.contains(x) { c.append(x) }
        choices = c.shuffled()
        picked = nil
        later(0.4) { play() }
    }
    private func color(_ c: String) -> Color {
        guard let p = picked, let cur = qs[safe: q] else { return .white }
        if c == cur { return .mint }
        return c == p ? .danger : .white
    }
    private func answer(_ c: String) {
        guard let cur = qs[safe: q] else { return }
        picked = c
        if c == cur { right += 1; AudioManager.shared.se(.kira) } else { AudioManager.shared.se(.wrong); later(0.3) { play() } }
        later(1.3) {
            if q + 1 < qs.count { q += 1; makeChoices() } else {
                let stars = right >= 9 ? 3 : right >= 7 ? 2 : 1
                finished(stars, right * 200)
            }
        }
    }
}

/// a short "the boss is coming" moment, then the もじレスキュー battle screen
struct KJRescueLauncher: View {
    let stage: KJC1.Stage
    @State private var shown = false
    @State private var left = false
    var body: some View {
        VStack(spacing: 16.s) {
            Spacer()
            Image(stage.bossImage).resizable().scaledToFit().frame(height: 220.s)
                .scaleEffect(shown ? 1 : 0.3).opacity(shown ? 1 : 0)
            RibbonTitle(text: "BOSS BATTLE!", color: .danger, size: 26)
            Text(KJ.both("Answer with the letters you learned!", "用學過的假名回答！", "배운 글자로 대답해요!"))
                .font(.ui(15.s)).foregroundStyle(Color.ink).multilineTextAlignment(.center)
                .padding(.horizontal, 14.s).padding(.vertical, 6.s)
                .background(Capsule().fill(Color.white.opacity(0.9)))
            Spacer()
        }
        .onAppear {
            guard !shown else { return }
            AudioManager.shared.se(.bossAppear)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) { shown = true }
            later(1.8) { if !left { KanaRescue.start(stage) } }
        }
        .onDisappear { left = true }
    }
}
