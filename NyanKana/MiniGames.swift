import SwiftUI
import UIKit
import Combine

// MARK: - ミニゲーム（設計書 22）
// 共通の枠：タイトル → 3・2・1・GO → プレイ → そこまで！ → 評価（S/A/B/C と ★）。
// それぞれ専用の BGM（Sounds/bgm_mg_*.m4a、Gemini で作曲）と効果音（se_mg_*）。

enum MGKind: String, CaseIterable {
    case karuta, tsuri, nazori, chochin, sushi, ninja
    case dash, taiko, train, shodo, tsumiki, daruma, kingyo, mekuri, takoyaki, yuki, meiro, yabusame, kawara

    var icon: String {
        switch self {
        case .karuta: "🎴"
        case .tsuri: "🎣"
        case .nazori: "🖌️"
        case .chochin: "🏮"
        case .sushi: "🍣"
        case .ninja: "🥷"
        case .dash: "🏃"
        case .taiko: "🥁"
        case .train: "🚄"
        case .shodo: "✍️"
        case .tsumiki: "🧱"
        case .daruma: "🎎"
        case .kingyo: "🐠"
        case .mekuri: "🃏"
        case .takoyaki: "🐙"
        case .yuki: "⛄"
        case .meiro: "🧭"
        case .yabusame: "🏹"
        case .kawara: "💥"
        }
    }

    /// the game's name in Japanese (read aloud on the title screen)
    var title: String {
        switch self {
        case .karuta: "かるた たいかい"
        case .tsuri: "もじ つり"
        case .nazori: "なぞりがき どうじょう"
        case .chochin: "ちょうちん たたき"
        case .sushi: "かいてん ずし"
        case .ninja: "しゅりけん にんじゃ"
        case .dash: "ニャン ダッシュ"
        case .taiko: "たいこ リズム"
        case .train: "しんかんせん レース"
        case .shodo: "しょどう チャレンジ"
        case .tsumiki: "もじ つみき"
        case .daruma: "だるま おとし"
        case .kingyo: "きんぎょ すくい"
        case .mekuri: "めくり カード"
        case .takoyaki: "たこやき やたい"
        case .yuki: "ゆきがっせん"
        case .meiro: "もじ めいろ"
        case .yabusame: "やぶさめ"
        case .kawara: "かわら わり"
        }
    }
    var sub: String {
        switch self {
        case .karuta: KJ.t("Karuta Battle", "歌留多大賽", "카루타 대회")
        case .tsuri: KJ.t("Letter Fishing", "文字釣魚", "글자 낚시")
        case .nazori: KJ.t("Tracing Dojo", "描字道場", "따라 쓰기 도장")
        case .chochin: KJ.t("Lantern Whack", "打燈籠", "초롱 두더지")
        case .sushi: KJ.t("Sushi Train", "迴轉壽司", "회전 초밥")
        case .ninja: KJ.t("Shuriken Ninja", "手裏劍忍者", "수리검 닌자")
        case .dash: KJ.t("Nyan Dash", "喵喵衝刺", "냥 대시")
        case .taiko: KJ.t("Taiko Rhythm", "太鼓節奏", "북 리듬")
        case .train: KJ.t("Bullet Train Race", "新幹線大賽", "신칸센 레이스")
        case .shodo: KJ.t("Calligraphy Challenge", "書法挑戰", "서예 챌린지")
        case .tsumiki: KJ.t("Letter Blocks", "文字積木", "글자 블록")
        case .daruma: KJ.t("Daruma Drop", "不倒翁敲敲樂", "다루마 떨어뜨리기")
        case .kingyo: KJ.t("Goldfish Scooping", "撈金魚", "금붕어 건지기")
        case .mekuri: KJ.t("Memory Cards", "翻牌配對", "카드 뒤집기")
        case .takoyaki: KJ.t("Takoyaki Stand", "章魚燒攤", "타코야키 포장마차")
        case .yuki: KJ.t("Snowball Fight", "打雪仗", "눈싸움")
        case .meiro: KJ.t("Letter Maze", "文字迷宮", "글자 미로")
        case .yabusame: KJ.t("Horseback Archery", "流鏑馬", "야부사메")
        case .kawara: KJ.t("Tile Breaker", "破瓦片", "기와 깨기")
        }
    }
    var howTo: String {
        switch self {
        case .karuta: KJ.both("Listen, then slap the card before the kappa does!", "聽發音，比河童更快拍下那張牌！", "소리를 듣고 갓파보다 먼저 카드를 쳐요!")
        case .tsuri: KJ.both("Catch the fish that has the letter!", "釣起帶著那個假名的魚！", "그 글자를 가진 물고기를 낚아요!")
        case .nazori: KJ.both("Trace the letter with your finger, then tap OK.", "用手指描寫假名，再按 OK。", "손가락으로 글자를 따라 쓰고 OK를 눌러요.")
        case .chochin: KJ.both("Whack only the lantern ghosts with the letter!", "只打帶著那個假名的燈籠妖怪！", "그 글자를 가진 초롱 요괴만 때려요!")
        case .sushi: KJ.both("Grab the plate the customer ordered!", "拿起客人點的那一盤！", "손님이 주문한 접시를 잡아요!")
        case .ninja: KJ.both("Swipe to slice the target with the letter!", "滑動手指，劈開那個假名的靶！", "밀어서 그 글자의 과녁을 베어요!")
        case .dash: KJ.both("Run through the gate with the letter! Tap a lane to move.", "從有那個假名的鳥居穿過去！點跑道移動。", "그 글자의 도리이를 지나가요! 길을 눌러 이동해요.")
        case .taiko: KJ.both("Hit the drum when the note with the letter reaches the circle!", "有那個假名的音符到圓圈時，敲鼓！", "그 글자의 음표가 원에 오면 북을 쳐요!")
        case .train: KJ.both("Answer fast to speed up your train. Beat the rival to Osaka!", "快速回答讓列車加速，比對手先到大阪！", "빨리 대답해서 열차를 가속! 라이벌보다 먼저 오사카로!")
        case .shodo: KJ.both("Listen and write the letter from memory, then tap OK.", "聽發音，憑記憶寫出假名，再按 OK。", "소리를 듣고 기억해서 글자를 쓴 뒤 OK를 눌러요.")
        case .tsumiki: KJ.both("Tap the blocks with the letter before they pile up to the top!", "在積木堆到頂之前，點掉有那個假名的積木！", "블록이 꼭대기까지 쌓이기 전에 그 글자의 블록을 눌러요!")
        case .daruma: KJ.both("Knock out the block with the letter. Don't topple the daruma!", "敲出有那個假名的木塊，別讓不倒翁倒下！", "그 글자의 블록을 쳐내요. 다루마를 쓰러뜨리지 마요!")
        case .kingyo: KJ.both("Scoop the goldfish with the letter. Wrong ones tear your paper scoop!", "撈起有那個假名的金魚。撈錯紙網會破！", "그 글자의 금붕어를 건져요. 틀리면 뜰채가 찢어져요!")
        case .mekuri: KJ.both("Flip two cards and match the letter with its sound!", "翻兩張牌，把假名和讀音配成一對！", "카드 두 장을 뒤집어 글자와 소리를 짝지어요!")
        case .takoyaki: KJ.both("Serve the ordered takoyaki when it turns golden. Not raw, not burnt!", "客人點的章魚燒變金黃時出餐！別生也別焦！", "주문한 타코야키가 노릇해지면 내요. 덜 익거나 타면 안 돼요!")
        case .yuki: KJ.both("Throw snowballs only at the kids holding the letter!", "只對舉著那個假名的孩子丟雪球！", "그 글자를 든 아이에게만 눈덩이를 던져요!")
        case .meiro: KJ.both("Hop to the next letter of the word, square by square!", "照著詞的順序，一格一格跳到下一個假名！", "단어 순서대로 한 칸씩 다음 글자로 뛰어요!")
        case .yabusame: KJ.both("Shoot only the targets with the letter as you gallop past!", "策馬奔馳，只射有那個假名的靶！", "말을 타고 달리며 그 글자의 과녁만 쏴요!")
        case .kawara: KJ.both("Bounce the ball and break only the tiles with the letter!", "反彈球，只打破有那個假名的瓦片！", "공을 튕겨서 그 글자의 기와만 깨요!")
        }
    }
    var bg: String {
        switch self {
        case .karuta: "bg_mg_karuta"
        case .tsuri: "bg_c1_enoshima"
        case .nazori: "bg_mg_dojo"
        case .chochin: "bg_mg_chochin"
        case .sushi: "bg_mg_sushi"
        case .ninja: "bg_mg_ninja"
        case .dash: "bg_mg_dash"
        case .taiko: "bg_mg_chochin"
        case .train: "bg_mg_shinkansen"
        case .shodo: "bg_mg_dojo"
        case .tsumiki: "bg_mg_karuta"
        case .daruma: "bg_mg_daruma"
        case .kingyo: "bg_mg_kingyo"
        case .mekuri: "bg_mg_karuta"
        case .takoyaki: "bg_mg_takoyaki"
        case .yuki: "bg_mg_yuki"
        case .meiro: "旅01_日光東照宮"
        case .yabusame: "bg_mg_yabusame"
        case .kawara: "bg_mg_dojo"
        }
    }
    var hero: String {
        switch self {
        case .karuta: "mg_kappa"
        case .tsuri: "nk_nyan_fish"
        case .nazori: "nk_nyan_proud"
        case .chochin: "mg_chochin"
        case .sushi: "mg_sushi"
        case .ninja: "nk_nyan_ninja"
        case .dash: "nk_nyan_hero"
        case .taiko: "mg_taiko"
        case .train: "mg_train"
        case .shodo: "nk_nyan_think"
        case .tsumiki: "nk_nyan_think"
        case .daruma: "mg_daruma"
        case .kingyo: "mg_kingyo"
        case .mekuri: "nk_nyan_tip"
        case .takoyaki: "mg_takoyaki"
        case .yuki: "mg_yukinko"
        case .meiro: "nk_nyan_think"
        case .yabusame: "nk_nyan_yabusame"
        case .kawara: "nk_nyan_angry"
        }
    }
    var bgm: String { "mg_" + rawValue }
    /// seconds on the clock (nil: the game ends by itself)
    var duration: Double? {
        switch self {
        case .karuta: 50
        case .tsuri: 45
        case .nazori: nil
        case .chochin: 45
        case .sushi: 50
        case .ninja: 45
        case .dash: 45
        case .taiko: 45
        case .train: 60
        case .shodo: nil
        case .tsumiki: 50
        case .daruma: 45
        case .kingyo: 45
        case .mekuri: 60
        case .takoyaki: 50
        case .yuki: 45
        case .meiro: 60
        case .yabusame: 45
        case .kawara: 60
        }
    }
    /// hits needed for an S
    var target: Int {
        switch self {
        case .karuta: 12
        case .tsuri: 12
        case .nazori: 5
        case .chochin: 15
        case .sushi: 12
        case .ninja: 14
        case .dash: 12
        case .taiko: 15
        case .train: 15
        case .shodo: 6
        case .tsumiki: 15
        case .daruma: 12
        case .kingyo: 12
        case .mekuri: 8
        case .takoyaki: 12
        case .yuki: 14
        case .meiro: 20
        case .yabusame: 12
        case .kawara: 12
        }
    }
}

// MARK: - shared state: score, combo, fever, shake, pop-ups

@MainActor final class MGCtx: ObservableObject {
    struct Pop: Identifiable {
        let id = UUID()
        var text: String
        var pos: CGPoint        // 0...1 of the screen
        var color: Color
    }
    @Published var score = 0
    @Published var combo = 0
    @Published var maxCombo = 0
    @Published var hits = 0
    @Published var misses = 0
    @Published var fever = false
    @Published var timeLeft: Double = 0
    @Published var running = false
    @Published var shake: CGFloat = 0
    @Published var flash = false
    @Published var pops: [Pop] = []
    @Published var round = 0          // bumps on every (re)start so the game can reset itself
    var total: Double = 0
    var target = 10
    var won: [String] = []
    var endRequested: (() -> Void)?

    func reset(total: Double?, target: Int) {
        score = 0; combo = 0; maxCombo = 0; hits = 0; misses = 0; fever = false
        self.total = total ?? 0; timeLeft = total ?? 0; self.target = target
        pops = []; won = []; running = false; bonus = false; round += 1
    }

    @discardableResult
    func good(_ base: Int = 100, at p: CGPoint, word: String? = nil) -> Int {
        hits += 1; combo += 1; maxCombo = max(maxCombo, combo)
        if let w = word, !won.contains(w) { won.append(w) }
        let gain = (base + min(combo, 20) * 10) * (fever ? 2 : 1)
        score += gain
        pop("+\(gain)", at: p, color: fever ? .sunDeep : .popDeep)
        if hits == target && !bonus && running && total > 0 {
            bonus = true
            AudioManager.shared.se(.clearShort)
            pop("クリア！ ボーナスタイム！", at: CGPoint(x: 0.5, y: 0.42), color: .sunDeep)
        }
        if combo == 8 && !fever {
            fever = true
            AudioManager.shared.se(.fever)
            pop("FEVER ×2", at: CGPoint(x: 0.5, y: 0.34), color: .sun)
        } else if combo % 5 == 0 {
            AudioManager.shared.se(.studyCombo, volume: 0.7)
        }
        return gain
    }

    /// a wrong answer: combo gone, the screen shakes
    func bad(at p: CGPoint, shakeIt: Bool = true) {
        if AppState.shared.dev.anyRight { good(at: p); return }
        misses += 1; combo = 0; fever = false
        if shakeIt { withAnimation(.linear(duration: 0.35)) { shake += 1 } }
        flash = true
        later(0.15) { [weak self] in self?.flash = false }
        AudioManager.shared.se(.wrong, volume: 0.8)
        pop("MISS", at: p, color: .ink)
    }

    /// lost a point to the rival (not a wrong tap): combo gone, no shake
    func lose() { combo = 0; fever = false }

    func pop(_ t: String, at p: CGPoint, color: Color) {
        let x = Pop(text: t, pos: p, color: color)
        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { pops.append(x) }
        later(0.8) { [weak self] in
            withAnimation(.easeIn(duration: 0.2)) { self?.pops.removeAll { $0.id == x.id } }
        }
    }

    var accuracy: Double { hits + misses == 0 ? 0 : Double(hits) / Double(hits + misses) }
    var grade: String {
        let r = Double(hits) / Double(max(target, 1))
        if r >= 1 && accuracy >= 0.85 { return "S" }
        if r >= 0.75 && accuracy >= 0.7 { return "A" }
        if r >= 0.45 { return "B" }
        return "C"
    }
    /// at least one star, so a weak run never blocks the journey
    /// no star (= try again) when hardly anything was right
    /// (half the goal, and more right than wrong — tapping everything fast does not pass)
    var passed: Bool { hits >= max(2, target / 2) && accuracy >= 0.5 }
    var stars: Int {
        guard passed else { return 0 }
        switch grade {
        case "S": return 3
        case "A": return 2
        default: return 1
        }
    }
    /// 12. reached the goal: the rest of the clock is bonus time
    @Published var bonus = false

    func finish() {
        guard running else { return }
        running = false
        endRequested?()
    }
}

/// a quick left-right shake: animate `amount` by +1
struct MGShake: GeometryEffect {
    var amount: CGFloat
    var animatableData: CGFloat {
        get { amount }
        set { amount = newValue }
    }
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 12 * sin(amount * .pi * 6), y: 0))
    }
}

// MARK: - the frame around every mini-game

struct MiniGameView: View {
    let kind: MGKind
    let stage: KJC1.Stage
    var finished: (_ stars: Int, _ score: Int, _ won: [String]) -> Void
    /// the goal: a little higher each round (2しゅうめ ×1.15, 3しゅうめ ×1.3)
    private var lapTarget: Int { Int((Double(kind.target) * (stage.lap > 1 ? KJLap.miniTarget : 1)).rounded()) }

    @StateObject private var ctx = MGCtx()
    enum Phase: Equatable { case title, count(Int), play, finish, result }
    @State private var phase: Phase = .title
    @State private var titleIn = false
    @State private var spin = false
    @State private var lastBeep = 0
    @State private var shownStars = 0
    @State private var shownScore = 0
    @State private var gradeIn = false
    @State private var clock = Timer.publish(every: 1.0 / 30, on: .main, in: .common).autoconnect()

    /// the letters to ask: everything known, the just-learned ones twice as often, plus the player's weak ones
    private var letters: [String] {
        let base = stage.known.isEmpty ? KJC1.A : stage.known
        return base + stage.focus + stage.focus + KJWeak.top(3, in: base)
    }

    var body: some View {
        GeometryReader { g in
            ZStack {
                KJBackdrop(bg: kind.bg, dim: 0)
                Group {
                    switch kind {
                    case .karuta: MGKaruta(ctx: ctx, letters: letters)
                    case .tsuri: MGTsuri(ctx: ctx, letters: letters)
                    case .nazori: MGNazori(ctx: ctx, letters: letters)
                    case .chochin: MGChochin(ctx: ctx, letters: letters)
                    case .sushi: MGSushi(ctx: ctx, letters: letters)
                    case .ninja: MGNinja(ctx: ctx, letters: letters)
                    case .dash: MGDash(ctx: ctx, letters: letters)
                    case .taiko: MGTaiko(ctx: ctx, letters: letters)
                    case .train: MGTrain(ctx: ctx, letters: letters)
                    case .shodo: MGNazori(ctx: ctx, letters: letters, guide: false)
                    case .tsumiki: MGTsumiki(ctx: ctx, letters: letters)
                    case .daruma: MGDaruma(ctx: ctx, letters: letters)
                    case .kingyo: MGKingyo(ctx: ctx, letters: letters)
                    case .mekuri: MGMekuri(ctx: ctx, letters: letters)
                    case .takoyaki: MGTakoyaki(ctx: ctx, letters: letters)
                    case .yuki: MGYuki(ctx: ctx, letters: letters)
                    case .meiro: MGMeiro(ctx: ctx, letters: letters)
                    case .yabusame: MGYabusame(ctx: ctx, letters: letters)
                    case .kawara: MGKawara(ctx: ctx, letters: letters)
                    }
                }
                .opacity(phase == .title ? 0 : 1)
                .modifier(MGShake(amount: ctx.shake))

                if ctx.fever { feverFrame(g.size) }
                if ctx.flash { Color.red.opacity(0.22).ignoresSafeArea().allowsHitTesting(false) }
                if phase != .title && phase != .result {
                    VStack(spacing: 6.s) {
                        hud
                        if ctx.bonus && phase == .play { bonusBar }
                        Spacer()
                    }
                    .padding(.top, 54.s)
                }
                ForEach(ctx.pops) { p in
                    OutlinedText(p.text, font: .display(26.s), fill: p.color == .ink ? .white : p.color, width: 3, shadow: 0)
                        .position(x: g.size.width * p.pos.x, y: g.size.height * p.pos.y)
                        .transition(.scale(scale: 0.3).combined(with: .opacity))
                        .allowsHitTesting(false)
                }
                overlay(g.size)
            }
            .frame(width: g.size.width, height: g.size.height)
        }
        .onAppear {
            // words this game can chain letter by letter (only games that bring the answer to you use chains)
            let chainable: Set<MGKind> = [.chochin, .yuki, .ninja, .yabusame, .taiko, .dash]
            MGWords.taught = KJLearned.answerWords(for: stage)
            MGAsk.chainWords = chainable.contains(kind) ? MGWords.pick(readable: letters, minLength: 2) : []
            MGPrompt.lastKind = nil; MGPrompt.seenKinds = []
            AudioManager.shared.playBGM(.track(kind.bgm))
            ctx.endRequested = { endGame() }
            ctx.reset(total: kind.duration, target: lapTarget)
            showTitle()
        }
        .onReceive(clock) { _ in tick() }
    }

    // MARK: flow

    private func showTitle() {
        phase = .title; titleIn = false; gradeIn = false; shownStars = 0; shownScore = 0
        later(0.1) {
            AudioManager.shared.se(.mgWhoosh)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.62)) { titleIn = true }
        }
        later(0.7) { Speaker.shared.say(kind.title.replacingOccurrences(of: " ", with: "")) }
        later(3.2) { startCount() }
    }

    private func startCount() {
        guard phase == .title else { return }
        count(3)
    }

    private func count(_ n: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { phase = .count(n) }
        AudioManager.shared.se(n == 0 ? .mgGo : .mgCount)
        if n == 0 {
            later(0.55) {
                withAnimation(.easeOut(duration: 0.2)) { phase = .play }
                lastBeep = 0
                ctx.running = true
            }
        } else {
            later(0.7) { count(n - 1) }
        }
    }

    private func tick() {
        guard phase == .play, ctx.running, kind.duration != nil else { return }
        ctx.timeLeft = max(0, ctx.timeLeft - 1.0 / 30)
        let sec = Int(ctx.timeLeft.rounded(.up))
        if sec <= 5 && sec > 0 && sec != lastBeep {
            lastBeep = sec
            AudioManager.shared.se(.mgCount, volume: 0.55)
        }
        if ctx.timeLeft <= 0 { ctx.finish() }
    }

    private func endGame() {
        AudioManager.shared.se(.mgStamp)
        AudioManager.shared.se(.papa, volume: 0.7)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.45)) { phase = .finish }
        later(1.5) {
            withAnimation(.easeOut(duration: 0.25)) { phase = .result }
            // count the score up, then the stars, then the grade stamp
            let target = ctx.score
            for i in 1...20 {
                later(0.03 * Double(i)) { shownScore = target * i / 20 }
            }
            for i in 0..<ctx.stars {
                later(0.8 + 0.35 * Double(i)) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) { shownStars = i + 1 }
                    AudioManager.shared.se(.kira, volume: 0.8)
                }
            }
            later(0.9 + 0.35 * Double(ctx.stars)) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.45)) { gradeIn = true }
                AudioManager.shared.se(ctx.grade == "S" ? .clear : .mgStamp)
            }
        }
    }

    private func retry() {
        AudioManager.shared.se(.decide)
        ctx.reset(total: kind.duration, target: lapTarget)
        showTitle()
    }

    // MARK: parts

    /// after the goal: BONUS TIME, and a button to stop whenever you like
    private var bonusBar: some View {
        HStack(spacing: 10.s) {
            KJPic.text("⭐ BONUS TIME", size: 16.s).font(.display(16.s)).foregroundStyle(Color.sunDeep)
                .padding(.horizontal, 12.s).padding(.vertical, 5.s)
                .background(Capsule().fill(Color.white).overlay(Capsule().stroke(Color.sunDeep, lineWidth: 3)))
                .modifier(Bob())
            Button {
                AudioManager.shared.se(.decide)
                ctx.finish()
            } label: {
                Text(KJ.both("Finish", "結束", "끝내기")).font(.ui(14.s)).foregroundStyle(.white)
                    .padding(.horizontal, 14.s).padding(.vertical, 6.s)
                    .background(Capsule().fill(Color.pop).overlay(Capsule().stroke(Color.ink, lineWidth: 2.5)))
            }
            .buttonStyle(.plain)
        }
        .transition(.scale.combined(with: .opacity))
    }

    private var hud: some View {
        VStack(spacing: 6.s) {
            HStack {
                Text("\(ctx.score)").font(.display(22.s)).foregroundStyle(Color.ink).monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.default, value: ctx.score)
                Spacer()
                if ctx.combo >= 2 {
                    Text("\(ctx.combo) COMBO").font(.display(18.s)).foregroundStyle(ctx.fever ? Color.sunDeep : Color.popDeep)
                        .scaleEffect(1 + min(CGFloat(ctx.combo), 10) * 0.02)
                        .id(ctx.combo)
                        .transition(.scale(scale: 1.6).combined(with: .opacity))
                }
                Spacer()
                if kind.duration != nil {
                    HStack(spacing: 4.s) {
                        Image(systemName: "timer").font(.system(size: 16.s, weight: .bold))
                        Text("\(Int(ctx.timeLeft.rounded(.up)))").font(.display(20.s)).monospacedDigit()
                    }
                    .foregroundStyle(ctx.timeLeft <= 5 ? Color.danger : Color.ink)
                    .scaleEffect(ctx.timeLeft <= 5 ? 1.15 : 1)
                } else {
                    Text("\(ctx.hits) / \(ctx.target)").font(.display(20.s)).foregroundStyle(Color.ink).monospacedDigit()
                }
            }
            if kind.duration != nil {
                GeometryReader { bar in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white)
                        Capsule().fill(ctx.timeLeft <= 5 ? Color.danger : Color.mint)
                            .frame(width: bar.size.width * max(0, ctx.timeLeft / max(ctx.total, 1)))
                    }
                    .overlay(Capsule().stroke(Color.ink, lineWidth: 2))
                }
                .frame(height: 9.s)
            }
        }
        .padding(.horizontal, 18.s).padding(.vertical, 6.s)
        .background(RoundedRectangle(cornerRadius: 22.s).fill(Color.white.opacity(0.88)).overlay(RoundedRectangle(cornerRadius: 22.s).stroke(Color.ink, lineWidth: 3)))
        .padding(.horizontal, 14.s)
    }

    private func feverFrame(_ size: CGSize) -> some View {
        TimelineView(.animation) { tl in
            let a = tl.date.timeIntervalSinceReferenceDate
            Rectangle()
                .strokeBorder(AngularGradient(colors: [.pop, .sun, .mint, .sky, .grape, .pop], center: .center,
                                              angle: .degrees(a * 120)), lineWidth: 10.s)
                .ignoresSafeArea()
        }
        .opacity(0.9)
        .allowsHitTesting(false)
    }

    @ViewBuilder private func overlay(_ size: CGSize) -> some View {
        switch phase {
        case .title: titleCard(size)
        case .count(let n): countView(n)
        case .finish: finishStamp
        case .result: resultCard
        case .play: EmptyView()
        }
    }

    private func titleCard(_ size: CGSize) -> some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            // the burst is drawn as an overlay so its size never widens the layout (it used to push everything right)
            Color.clear
                .frame(width: size.width, height: size.height)
                .overlay(
                    StarBurst().fill(Color.sun.opacity(0.55))
                        .frame(width: size.width * 1.3, height: size.width * 1.3)
                        .rotationEffect(.degrees(spin ? 360 : 0))
                        .animation(.linear(duration: 14).repeatForever(autoreverses: false), value: spin)
                )
                .clipped()
                .onAppear { spin = true }
                .allowsHitTesting(false)
            VStack(spacing: 14.s) {
                Image(kind.hero).resizable().scaledToFit().frame(height: 190.s).modifier(Bob())
                // sized so the whole name always fits on one line
                OutlinedText(kind.title, font: .custom(Fonts.rounded, size: min(40.s, (size.width - 70.s) / CGFloat(max(kind.title.count, 1)))),
                             fill: .sun, width: 5, shadow: 4)
                    .fixedSize()
                    .frame(width: size.width - 20.s)
                RibbonTitle(text: kind.sub, color: .sky, size: 20)
                PaperCard {
                    Text(kind.howTo).font(.ui(15.s)).foregroundStyle(Color.ink).multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 30.s)
                Text("TAP!").font(.display(18.s)).foregroundStyle(.white).opacity(0.85)
            }
            .frame(width: size.width, height: size.height)
            .offset(x: titleIn ? 0 : -size.width * 1.2)
            .rotationEffect(.degrees(titleIn ? 0 : -12))
        }
        .frame(width: size.width, height: size.height)
        .contentShape(Rectangle())
        .onTapGesture { startCount() }
    }

    private func countView(_ n: Int) -> some View {
        ZStack {
            Color.black.opacity(0.2).ignoresSafeArea().allowsHitTesting(true)
            OutlinedText(n == 0 ? "GO!" : "\(n)", font: .display(n == 0 ? 110.s : 140.s),
                         fill: n == 0 ? .pop : .sun, width: 6, shadow: 6)
                .id(n)
                .transition(.asymmetric(insertion: .scale(scale: 2.4).combined(with: .opacity), removal: .scale(scale: 0.4).combined(with: .opacity)))
        }
    }

    private var finishStamp: some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()
            Text("そこまで！")
                .font(.custom(Fonts.rounded, size: 52.s)).foregroundStyle(.white)
                .padding(.horizontal, 26.s).padding(.vertical, 12.s)
                .background(RoundedRectangle(cornerRadius: 16.s).fill(Color.danger).overlay(RoundedRectangle(cornerRadius: 16.s).stroke(Color.ink, lineWidth: 4)))
                .rotationEffect(.degrees(-8))
                .transition(.scale(scale: 3).combined(with: .opacity))
        }
    }

    private var resultCard: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            PaperCard {
                VStack(spacing: 10.s) {
                    Text(kind.title).font(.custom(Fonts.rounded, size: 20.s)).foregroundStyle(Color.ink)
                    ZStack {
                        Image(ctx.stars == 3 ? "nk_nyan_joy" : "nk_nyan_proud").resizable().scaledToFit().frame(height: 120.s)
                            .modifier(Bob())
                        if gradeIn {
                            Text(ctx.grade)
                                .font(.display(64.s))
                                .foregroundStyle(ctx.grade == "S" ? Color.sunDeep : ctx.grade == "A" ? Color.pop : Color.sky)
                                .frame(width: 92.s, height: 92.s)
                                .background(Circle().fill(Color.white).overlay(Circle().stroke(Color.danger, lineWidth: 5)))
                                .rotationEffect(.degrees(-12))
                                .offset(x: 96.s, y: -10.s)
                                .transition(.scale(scale: 3).combined(with: .opacity))
                        }
                    }
                    HStack(spacing: 6.s) {
                        ForEach(0..<3, id: \.self) { i in
                            Image(systemName: i < shownStars ? "star.fill" : "star")
                                .font(.system(size: 34.s, weight: .black))
                                .foregroundStyle(i < shownStars ? Color.sunDeep : Color.ink.opacity(0.25))
                                .scaleEffect(i < shownStars ? 1 : 0.8)
                        }
                    }
                    Text("\(shownScore)").font(.display(30.s)).foregroundStyle(Color.ink).monospacedDigit()
                    HStack(spacing: 16.s) {
                        Label("\(ctx.maxCombo)", systemImage: "flame.fill")
                        Label("\(ctx.hits)", systemImage: "checkmark.circle.fill")
                        Label("\(ctx.misses)", systemImage: "xmark.circle")
                    }
                    .font(.ui(15.s)).foregroundStyle(Color.ink.opacity(0.75))
                    if ctx.passed {
                        KJButton(title: KJ.both("Next", "下一步", "다음"), color: .pop, textColor: .white) {
                            KJMusic.play()
                            finished(ctx.stars, ctx.score, ctx.won)
                        }
                        KJButton(title: KJ.both("Play again", "再玩一次", "다시 하기"), color: .sun) { retry() }
                    } else {
                        // 11. not enough right answers: no moving on
                        Text(KJ.t("Almost! Get \(max(2, ctx.target / 3)) right to clear.", "差一點！答對 \(max(2, ctx.target / 3)) 題就過關。", "아깝다! \(max(2, ctx.target / 3))개 맞히면 클리어.") + "\n" + "おしい！ \(max(2, ctx.target / 3))もん せいかいで クリア")
                            .font(.ui(14.s)).foregroundStyle(Color.danger).multilineTextAlignment(.center)
                        KJButton(title: KJ.both("Try again", "再挑戰", "다시 도전"), color: .pop, textColor: .white) { retry() }
                        KJButton(title: KJ.both("Quit", "離開", "그만두기"), color: .white) {
                            KJMusic.play()
                            finished(0, ctx.score, [])
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 28.s)
        }
    }
}

// MARK: - 1. かるた大会: hear a letter, slap the card before the kappa

struct MGKaruta: View {
    @ObservedObject var ctx: MGCtx
    let letters: [String]

    struct Card: Identifiable {
        let id = UUID()
        var kana: String
        var gone = 0          // 0 on the tatami, 1 taken by you, 2 taken by the kappa
        var wrong = false
    }
    @State private var cards: [Card] = []
    @State private var answer: String?
    @State private var charge: Double = 0      // the kappa's hand: 0 → 1 (slap)
    @State private var armed = false
    @State private var lock = true
    @State private var reveal: UUID?
    @State private var kappaJump = false
    @State private var kappaSad = false
    @State private var mine = 0
    @State private var his = 0
    @State private var token = 0
    @State private var pressed: UUID?
    @State private var clock = Timer.publish(every: 1.0 / 30, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                // the rival
                VStack(spacing: 6.s) {
                    Image("mg_kappa").resizable().scaledToFit().frame(height: 150.s)
                        .scaleEffect(kappaJump ? 1.25 : 1)
                        .offset(y: kappaJump ? 70.s : 0)
                        .rotationEffect(.degrees(kappaSad ? -12 : 0))
                        .animation(.spring(response: 0.22, dampingFraction: 0.5), value: kappaJump)
                        .animation(.spring(response: 0.3, dampingFraction: 0.3), value: kappaSad)
                    // how close the kappa is to slapping
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white)
                        Capsule().fill(charge > 0.7 ? Color.danger : Color.mintDeep).frame(width: 150.s * min(1, charge))
                    }
                    .frame(width: 150.s, height: 10.s)
                    .overlay(Capsule().stroke(Color.ink, lineWidth: 2))
                    HStack(spacing: 14.s) {
                        score("じぶん", mine, .pop)
                        Text("VS").font(.display(16.s)).foregroundStyle(.white).shadow(color: .black, radius: 0, x: 1, y: 1)
                        score("かっぱ", his, .mintDeep)
                    }
                }
                .position(x: w * 0.5, y: h * 0.3)

                // the cards on the tatami
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(min(96.s, w * 0.26)), spacing: 10.s), count: 3), spacing: 12.s) {
                    ForEach(cards) { c in cardView(c) }
                }
                .position(x: w * 0.5, y: h * 0.68)

                // listen again
                Button {
                    if let a = answer { Speaker.shared.say(a) }
                } label: {
                    Image(systemName: "speaker.wave.3.fill").font(.system(size: 22.s, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 58.s, height: 58.s)
                        .background(Circle().fill(Color.sky).overlay(Circle().stroke(Color.ink, lineWidth: 3)))
                }
                .buttonStyle(PressStyle(radius: 29.s, depth: 4))
                .position(x: w * 0.88, y: h * 0.3)
            }
        }
        .onReceive(clock) { _ in
            guard ctx.running, armed, !lock else { return }
            let speed = min(0.55, 0.26 + 0.018 * Double(ctx.hits))
            charge += speed / 30
            if charge >= 1 { kappaTakes() }
        }
        .onChange(of: ctx.running) { _, on in if on { next() } else { lock = true } }
        .onChange(of: ctx.round) { _, _ in reset() }
        .onAppear { reset() }
    }

    private func score(_ name: String, _ n: Int, _ c: Color) -> some View {
        VStack(spacing: 0) {
            Text(name).font(.ui(11.s)).foregroundStyle(Color.ink)
            Text("\(n)").font(.display(22.s)).foregroundStyle(c).monospacedDigit()
        }
        .frame(width: 74.s)   // same width for both sides
        .padding(.vertical, 3.s)
        .background(RoundedRectangle(cornerRadius: 10.s).fill(Color.white.opacity(0.9)).overlay(RoundedRectangle(cornerRadius: 10.s).stroke(Color.ink, lineWidth: 2)))
    }

    private func cardView(_ c: Card) -> some View {
        let isReveal = reveal == c.id
        return Text(c.kana)
            .font(.custom(Fonts.rounded, size: 46.s)).foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.35)
            .frame(maxWidth: .infinity).frame(height: 104.s)
            .background(
                RoundedRectangle(cornerRadius: 8.s).fill(Color(hex: 0xFFF6E0))
                    .overlay(RoundedRectangle(cornerRadius: 5.s).stroke(Color(hex: 0xC8102E), lineWidth: 3).padding(5.s))
                    .overlay(RoundedRectangle(cornerRadius: 8.s).stroke(Color.ink, lineWidth: 3))
            )
            .shadow(color: isReveal ? Color.sun : .black.opacity(0.25), radius: isReveal ? 14 : 2, x: 0, y: 3)
            .scaleEffect(isReveal ? 1.12 : 1)
            .rotationEffect(.degrees(c.wrong ? 8 : 0))
            .offset(y: c.gone == 1 ? 600 : c.gone == 2 ? -600 : 0)
            .rotationEffect(.degrees(c.gone == 0 ? 0 : (c.gone == 1 ? 25 : -35)))
            .opacity(c.gone == 0 ? 1 : 0)
            .animation(.easeIn(duration: 0.45), value: c.gone)
            .animation(.default.repeatCount(3, autoreverses: true).speed(5), value: c.wrong)
            .animation(.spring(response: 0.25, dampingFraction: 0.5), value: isReveal)
            .contentShape(Rectangle())
            // react at touch-down, once per touch
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard pressed != c.id else { return }
                    pressed = c.id
                    slap(c)
                }
                .onEnded { _ in pressed = nil })
    }

    // MARK: rules

    private func reset() {
        cards = []; answer = nil; charge = 0; armed = false; lock = true
        reveal = nil; kappaJump = false; kappaSad = false; mine = 0; his = 0; token += 1
        deal()
    }

    /// nine cards; letters that look alike are put side by side on purpose
    private func deal() {
        var pick = Array(Set(letters)).shuffled()
        if let a = pick.first, let group = KJData.lookAlike.first(where: { $0.contains(a) }) {
            for k in group where letters.contains(k) && !pick.prefix(9).contains(k) { pick.insert(k, at: 1) }
        }
        var chosen: [String] = []
        for k in pick where !chosen.contains(k) && chosen.count < 9 { chosen.append(k) }
        // not-yet-learned letters may sit on the table as extra cards, but are never the answer (see next())
        while chosen.count < 9 { chosen.append(KJC1.all.filter { !chosen.contains($0) }.randomElement() ?? "あ") }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { cards = chosen.shuffled().map { Card(kana: $0) } }
        AudioManager.shared.se(.mgWhoosh, volume: 0.6)
    }

    private func next() {
        token += 1
        let my = token
        let left = cards.filter { $0.gone == 0 }
        let known = Set(letters)
        let askable = left.filter { known.contains($0.kana) }
        if left.count < 3 || askable.isEmpty {
            deal()
            later(0.5) { if my == token { next() } }
            return
        }
        // only letters already learned are read out
        answer = askable.randomElement()?.kana
        charge = 0; armed = false; lock = false; reveal = nil
        later(0.35) {
            guard my == token, ctx.running, let a = answer else { return }
            Speaker.shared.say(a)
            later(0.6) { if my == token { armed = true } }
        }
    }

    private func slap(_ c: Card) {
        guard ctx.running, !lock, c.gone == 0, let i = cards.firstIndex(where: { $0.id == c.id }) else { return }
        if c.kana == answer {
            lock = true
            AudioManager.shared.se(.mgSlap)
            cards[i].gone = 1
            mine += 1
            let quick = Int((1 - min(charge, 1)) * 100)
            ctx.good(100 + quick, at: CGPoint(x: 0.5, y: 0.55), word: c.kana)
            if quick > 70 { ctx.pop("はやい！", at: CGPoint(x: 0.5, y: 0.47), color: .sky) }
            kappaSad = true
            later(0.5) { kappaSad = false }
            let my = token
            later(0.75) { if my == token { next() } }
        } else {
            cards[i].wrong.toggle()
            charge = min(1, charge + 0.25)
            ctx.bad(at: CGPoint(x: 0.5, y: 0.6))
        }
    }

    private func kappaTakes() {
        lock = true
        guard let i = cards.firstIndex(where: { $0.kana == answer && $0.gone == 0 }) else { next(); return }
        kappaJump = true
        AudioManager.shared.se(.mgSlap)
        AudioManager.shared.se(.sad, volume: 0.5)
        reveal = cards[i].id
        ctx.lose()
        his += 1
        ctx.pop("おそい！", at: CGPoint(x: 0.5, y: 0.47), color: .mintDeep)
        let my = token
        later(0.55) {
            guard my == token else { return }
            if let j = cards.firstIndex(where: { $0.id == reveal }) { cards[j].gone = 2 }
            kappaJump = false
            reveal = nil
        }
        later(1.1) { if my == token { next() } }
    }
}

// MARK: - 2. もじつり: catch the fish carrying the letter

struct MGTsuri: View {
    @ObservedObject var ctx: MGCtx
    let letters: [String]

    struct Fish: Identifiable {
        let id = UUID()
        var kana: String
        var x: Double          // 0...1 of the width
        var y: Double          // 0...1 of the height (only the water part)
        var vx: Double
        var phase: Double
        var gold = false
        var flee = false
    }
    struct Splash: Identifiable { let id = UUID(); var x: CGFloat; var y: CGFloat }

    @State private var fish: [Fish] = []
    @State private var answer: String?
    @State private var listenMode = true
    @State private var reel: (id: UUID, t: Double, from: CGPoint)?
    @State private var splashes: [Splash] = []
    @State private var catchCount = 0
    @State private var t: Double = 0
    @State private var token = 0
    @State private var size: CGSize = .zero
    @State private var clock = Timer.publish(every: 1.0 / 30, on: .main, in: .common).autoconnect()

    private let waterTop: CGFloat = 0.47
    /// where the rod tip is (0...1 of the screen)
    private let tip = CGPoint(x: 0.34, y: 0.25)

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                Color.clear
                    .onAppear { size = g.size }
                    .onChange(of: g.size) { _, v in size = v }
                // the sea
                Wave(t: t, amp: 6.s)
                    .fill(LinearGradient(colors: [Color(hex: 0x5FD0F0).opacity(0.75), Color(hex: 0x1C6FB8).opacity(0.92)], startPoint: .top, endPoint: .bottom))
                    .frame(height: h * (1 - waterTop) + 20)
                    .position(x: w / 2, y: h * waterTop + (h * (1 - waterTop) + 20) / 2 - 10)
                    .allowsHitTesting(false)
                Wave(t: t * 1.4 + 2, amp: 4.s)
                    .stroke(Color.white.opacity(0.7), lineWidth: 3)
                    .frame(height: h * (1 - waterTop))
                    .position(x: w / 2, y: h * waterTop + h * (1 - waterTop) / 2 + 2)
                    .allowsHitTesting(false)

                // the fishing line while reeling in
                if let r = reel, let f = fish.first(where: { $0.id == r.id }) {
                    Path { p in
                        p.move(to: CGPoint(x: w * tip.x, y: h * tip.y))
                        p.addLine(to: pos(f, w, h))
                    }
                    .stroke(Color.white, lineWidth: 2)
                    .allowsHitTesting(false)
                }

                ForEach(fish) { f in fishView(f).position(pos(f, w, h)) }

                ForEach(splashes) { s in
                    SplashRing().position(x: w * s.x, y: h * s.y).allowsHitTesting(false)
                }

                // Nyan on the shore + the question
                Image("nk_nyan_fish").resizable().scaledToFit().frame(width: 150.s, height: 150.s)
                    .position(x: w * 0.17, y: h * 0.31)
                    .scaleEffect(reel != nil ? 1.05 : 1)
                    .allowsHitTesting(false)
                question.position(x: w * 0.66, y: h * 0.33)

                // the catch so far
                HStack(spacing: 2.s) {
                    KJPicView("🪣", size: 29.9.s)
                    Text("× \(catchCount)").font(.display(20.s)).foregroundStyle(Color.ink)
                }
                .padding(.horizontal, 10.s).padding(.vertical, 4.s)
                .background(Capsule().fill(Color.white.opacity(0.9)).overlay(Capsule().stroke(Color.ink, lineWidth: 2)))
                .position(x: w * 0.82, y: h * 0.94)
            }
        }
        .onReceive(clock) { _ in step() }
        .onChange(of: ctx.running) { _, on in if on { ask() } }
        .onChange(of: ctx.round) { _, _ in reset() }
        .onAppear { reset() }
    }

    private func pos(_ f: Fish, _ w: CGFloat, _ h: CGFloat) -> CGPoint {
        if let r = reel, r.id == f.id {
            // fly up to the rod tip
            let e = CGFloat(r.t * r.t)
            let from = r.from
            let hop = CGFloat(sin(r.t * .pi)) * 40.s
            return CGPoint(x: from.x + (w * tip.x - from.x) * e, y: from.y + (h * tip.y - from.y) * e - hop)
        }
        let top = h * (waterTop + 0.08), bottom = h * 0.9
        let bob = CGFloat(sin(t * 2 + f.phase)) * 6.s
        return CGPoint(x: w * CGFloat(f.x), y: top + (bottom - top) * CGFloat(f.y) + bob)
    }

    private var question: some View {
        VStack(spacing: 6.s) {
            if listenMode {
                Button { if let a = answer { Speaker.shared.say(a) } } label: {
                    Image(systemName: "speaker.wave.3.fill").font(.system(size: 26.s, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 66.s, height: 66.s)
                        .background(Circle().fill(Color.sky).overlay(Circle().stroke(Color.ink, lineWidth: 3)))
                }
                .buttonStyle(PressStyle(radius: 33.s, depth: 4))
            } else {
                Button { if let a = answer { Speaker.shared.say(a) } } label: {
                    HStack(spacing: 8.s) {
                        Text(answer.map { KJData.romaji($0) } ?? "").font(.display(40.s)).foregroundStyle(Color.ink)
                        Image(systemName: "speaker.wave.2.fill").font(.system(size: 20.s, weight: .bold)).foregroundStyle(Color.sky)
                    }
                    .padding(.horizontal, 16.s)
                    .frame(minWidth: 96.s, minHeight: 66.s)
                    .background(RoundedRectangle(cornerRadius: 18.s).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 18.s).stroke(Color.ink, lineWidth: 3)))
                }
                .buttonStyle(.plain)
            }
            Text(listenMode ? KJ.duo("Which fish?", "哪條魚？", "어느 물고기?") : KJ.duo("Find this sound!", "找這個音！", "이 소리를 찾아요!"))
                .font(.ui(12.s)).foregroundStyle(Color.ink)
                .padding(.horizontal, 8.s).padding(.vertical, 2.s)
                .background(Capsule().fill(Color.white.opacity(0.85)))
        }
        .id(answer ?? "")
        .transition(.scale.combined(with: .opacity))
    }

    private func fishView(_ f: Fish) -> some View {
        let face: CGFloat = f.vx > 0 ? -1 : 1
        let reeling = reel?.id == f.id
        return ZStack {
            Image("mg_fish").resizable().scaledToFit().frame(width: 112.s)
                .scaleEffect(x: face, y: 1)
                .hueRotation(.degrees(f.gold ? 35 : 0))
                .saturation(f.gold ? 1.4 : 1)
                .shadow(color: f.gold ? Color.yellow : .clear, radius: 10)
            Text(f.kana).font(.custom(Fonts.rounded, size: 30.s)).foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.35)
                .offset(x: face * 8.s, y: 1.s)
        }
        .rotationEffect(.degrees(reeling ? -60 * face : 0))
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 0).onChanged { _ in tap(f) })
    }

    // MARK: rules

    private func reset() {
        token += 1
        reel = nil; splashes = []; catchCount = 0; answer = nil
        fish = (0..<6).map { i in newFish(slot: i) }
        // every letter on screen is different
        var seen = Set<String>()
        for i in fish.indices {
            if seen.contains(fish[i].kana) { fish[i].kana = letters.filter { !seen.contains($0) }.randomElement() ?? fish[i].kana }
            seen.insert(fish[i].kana)
        }
    }

    private func newFish(slot: Int) -> Fish {
        let left = Bool.random()
        let speed = (0.06 + Double.random(in: 0...0.05) + 0.004 * Double(ctx.hits)) * (left ? 1 : -1)
        let onScreen = fish.map(\.kana)
        let k = letters.filter { !onScreen.contains($0) }.randomElement() ?? letters.randomElement() ?? "あ"
        return Fish(kana: k, x: Double.random(in: 0.05...0.95), y: (Double(slot % 6) + Double.random(in: 0.1...0.9)) / 6,
                    vx: speed, phase: Double.random(in: 0...6), gold: Double.random(in: 0...1) < 0.12)
    }

    private func ask() {
        guard ctx.running else { return }
        let pool = fish.filter { !$0.flee && $0.id != reel?.id }
        guard let f = pool.randomElement() else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            answer = f.kana
            listenMode = ctx.hits < 3 || Bool.random()
        }
        later(0.2) { Speaker.shared.say(f.kana) }   // the romaji is read out too (learn by hearing)
    }

    private func step() {
        t += 1.0 / 30
        guard !fish.isEmpty else { return }
        // swimming (the fish keep moving even before the start, it looks alive)
        for i in fish.indices where fish[i].id != reel?.id {
            fish[i].x += fish[i].vx / 30 * (fish[i].flee ? 5 : 1)
            if fish[i].x > 1.15 || fish[i].x < -0.15 {
                if fish[i].flee {
                    // it ran away: a new fish comes in
                    let k = fish[i].kana
                    var nf = newFish(slot: i)
                    nf.x = fish[i].vx > 0 ? -0.12 : 1.12
                    nf.vx = abs(nf.vx) * (fish[i].vx > 0 ? 1 : -1)
                    if nf.kana == answer { nf.kana = k }
                    fish[i] = nf
                } else {
                    fish[i].x = fish[i].vx > 0 ? -0.12 : 1.12
                    fish[i].y = (Double(i % 6) + Double.random(in: 0.1...0.9)) / 6
                }
            }
        }
        if var r = reel {
            r.t = min(1, r.t + 1.0 / 30 / 0.6)
            reel = r
            if r.t >= 1 { landed(r.id) }
        }
    }

    private func tap(_ f: Fish) {
        guard ctx.running, reel == nil, !f.flee, let i = fish.firstIndex(where: { $0.id == f.id }) else { return }
        guard size.width > 0 else { return }
        let h = size.height, w = size.width
        let p = pos(fish[i], w, h)
        if f.kana == answer {
            AudioManager.shared.se(.mgSplash)
            later(0.15) { AudioManager.shared.se(.mgReel, volume: 0.8) }
            splashes.append(Splash(x: p.x / w, y: p.y / h))
            let sid = splashes.last!.id
            later(0.7) { splashes.removeAll { $0.id == sid } }
            reel = (f.id, 0, p)
            ctx.good(f.gold ? 300 : 100, at: CGPoint(x: p.x / w, y: p.y / h - 0.06), word: f.kana)
            if f.gold { ctx.pop("GOLD!", at: CGPoint(x: p.x / w, y: p.y / h - 0.12), color: .sunDeep) }
        } else {
            AudioManager.shared.se(.mgBloop)
            fish[i].flee = true
            ctx.bad(at: CGPoint(x: p.x / w, y: p.y / h - 0.06))
        }
    }

    private func landed(_ id: UUID) {
        reel = nil
        catchCount += 1
        AudioManager.shared.se(.kira, volume: 0.6)
        if let i = fish.firstIndex(where: { $0.id == id }) {
            var nf = newFish(slot: i)
            nf.x = nf.vx > 0 ? -0.12 : 1.12
            fish[i] = nf
        }
        let my = token
        later(0.3) { if my == token { ask() } }
    }
}

/// the sea surface: a soft sine edge on top, filled down to the bottom
struct Wave: Shape {
    var t: Double
    var amp: CGFloat
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: r.height))
        var x: CGFloat = 0
        while x <= r.width {
            let y = amp + amp * CGFloat(sin(Double(x) / 38 + t * 1.6))
            p.addLine(to: CGPoint(x: x, y: y))
            x += 6
        }
        p.addLine(to: CGPoint(x: r.width, y: r.height))
        p.closeSubpath()
        return p
    }
}

/// white rings and drops where a fish was pulled out
struct SplashRing: View {
    @State private var go = false
    var body: some View {
        ZStack {
            Circle().stroke(Color.white, lineWidth: 4).frame(width: 40.s, height: 18.s)
                .scaleEffect(go ? 3 : 0.5).opacity(go ? 0 : 1)
            ForEach(0..<6, id: \.self) { i in
                Circle().fill(Color.white).frame(width: 9.s, height: 9.s)
                    .offset(x: go ? CGFloat(i - 3) * 16.s : 0, y: go ? -50.s + CGFloat(abs(i - 3)) * 12.s : 0)
                    .opacity(go ? 0 : 1)
            }
        }
        .onAppear { withAnimation(.easeOut(duration: 0.6)) { go = true } }
    }
}

// MARK: - 3. なぞりがき道場: trace the letter; a good one gets the red stamp

enum MGGlyph {
    static let n = 64
    /// the letter drawn big in the middle of a square: the faint guide picture and a 64×64 map of its ink
    static func make(_ k: String) -> (image: UIImage, mask: [Bool]) {
        let px = 256
        guard let c = CGContext(data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: px,
                                space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)
        else { return (UIImage(), []) }
        c.setFillColor(gray: 1, alpha: 1)
        c.fill(CGRect(x: 0, y: 0, width: px, height: px))
        c.translateBy(x: 0, y: CGFloat(px))
        c.scaleBy(x: 1, y: -1)
        UIGraphicsPushContext(c)
        // two-letter sounds (きゃ) are drawn smaller so both fit
        let size = CGFloat(px) * (k.count > 1 ? 0.44 : 0.74)
        let font = UIFont(name: Fonts.roundedBold, size: size) ?? .systemFont(ofSize: size, weight: .bold)
        let s = NSAttributedString(string: k, attributes: [.font: font, .foregroundColor: UIColor.black])
        let b = s.boundingRect(with: CGSize(width: px, height: px), options: [.usesLineFragmentOrigin], context: nil)
        s.draw(at: CGPoint(x: (CGFloat(px) - b.width) / 2, y: (CGFloat(px) - b.height) / 2))
        UIGraphicsPopContext()
        guard let img = c.makeImage(), let data = c.data else { return (UIImage(), []) }
        let p = data.bindMemory(to: UInt8.self, capacity: px * px)
        let step = px / n
        var mask = [Bool](repeating: false, count: n * n)
        for y in 0..<n {
            for x in 0..<n {
                var dark = false
                for yy in 0..<step where !dark {
                    for xx in 0..<step where p[(y * step + yy) * px + x * step + xx] < 140 { dark = true; break }
                }
                mask[y * n + x] = dark
            }
        }
        return (UIImage(cgImage: img), mask)
    }

    /// how much of the letter is covered, and how much of the ink stays on the letter
    static func judge(_ strokes: [[CGPoint]], mask: [Bool]) -> (cover: Double, inside: Double) {
        guard mask.count == n * n else { return (0, 0) }
        var ink = [Bool](repeating: false, count: n * n)
        let r = 3
        func dab(_ p: CGPoint) {
            let cx = Int(p.x * CGFloat(n)), cy = Int(p.y * CGFloat(n))
            for dy in -r...r {
                for dx in -r...r where dx * dx + dy * dy <= r * r {
                    let x = cx + dx, y = cy + dy
                    if x >= 0 && y >= 0 && x < n && y < n { ink[y * n + x] = true }
                }
            }
        }
        for s in strokes {
            guard var last = s.first else { continue }
            dab(last)
            for p in s.dropFirst() {
                let d = hypot(p.x - last.x, p.y - last.y) * CGFloat(n)
                let steps = max(1, Int(d * 2))
                for i in 1...steps {
                    let f = CGFloat(i) / CGFloat(steps)
                    dab(CGPoint(x: last.x + (p.x - last.x) * f, y: last.y + (p.y - last.y) * f))
                }
                last = p
            }
        }
        // the letter grown a little: ink there still counts as "on the letter"
        var near = [Bool](repeating: false, count: n * n)
        let g = 4
        for y in 0..<n {
            for x in 0..<n where mask[y * n + x] {
                for dy in -g...g {
                    for dx in -g...g {
                        let xx = x + dx, yy = y + dy
                        if xx >= 0 && yy >= 0 && xx < n && yy < n { near[yy * n + xx] = true }
                    }
                }
            }
        }
        var letter = 0, covered = 0, inkCount = 0, inkIn = 0
        for i in 0..<(n * n) {
            if mask[i] { letter += 1; if ink[i] { covered += 1 } }
            if ink[i] { inkCount += 1; if near[i] { inkIn += 1 } }
        }
        return (letter == 0 ? 0 : Double(covered) / Double(letter), inkCount == 0 ? 0 : Double(inkIn) / Double(inkCount))
    }
}

struct MGNazori: View {
    @ObservedObject var ctx: MGCtx
    let letters: [String]
    /// false: しょどうチャレンジ — write from memory (the letter shows only after OK)
    var guide = true
    @State private var reveal = false

    @State private var order: [String] = []
    @State private var idx = 0
    @State private var glyph: (image: UIImage, mask: [Bool]) = (UIImage(), [])
    @State private var strokes: [[CGPoint]] = []
    @State private var drawing = false
    @State private var stamp: String?          // shown on the paper after a good one
    @State private var tries = 0
    @State private var busy = false

    private var kana: String { order[safe: idx] ?? "あ" }

    var body: some View {
        GeometryReader { g in
            let side = min(g.size.width * 0.84, g.size.height * 0.48)
            VStack(spacing: 12.s) {
                Spacer(minLength: 110.s)
                // the letter to write
                HStack(spacing: 12.s) {
                    Image(stamp != nil ? "nk_nyan_joy" : "nk_nyan_proud").resizable().scaledToFit().frame(height: 72.s)
                    VStack(spacing: 2.s) {
                        Text(guide || reveal || stamp != nil ? kana : "？").font(.custom(Fonts.rounded, size: 34.s)).foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.35)
                        Text(KJData.romaji(kana)).font(.display(16.s)).foregroundStyle(Color.ink.opacity(0.7))
                    }
                    .frame(width: 80.s, height: 80.s)
                    .background(Circle().fill(Color.white).overlay(Circle().stroke(Color.ink, lineWidth: 3)))
                    Button { Speaker.shared.say(kana) } label: {
                        Image(systemName: "speaker.wave.3.fill").font(.system(size: 20.s, weight: .bold)).foregroundStyle(.white)
                            .frame(width: 50.s, height: 50.s)
                            .background(Circle().fill(Color.sky).overlay(Circle().stroke(Color.ink, lineWidth: 3)))
                    }
                    .buttonStyle(PressStyle(radius: 25.s, depth: 4))
                }
                paper(side)
                HStack(spacing: 12.s) {
                    KJButton(title: KJ.both("Clear", "擦掉", "지우기"), color: .white) {
                        AudioManager.shared.se(.back, volume: 0.6)
                        strokes = []
                    }
                    KJButton(title: "OK!", color: .pop, textColor: .white) { judge() }
                }
                .padding(.horizontal, 30.s)
                .disabled(busy)
                Spacer()
            }
            .frame(width: g.size.width)
        }
        .onChange(of: ctx.round) { _, _ in reset() }
        .onChange(of: ctx.running) { _, on in if on { Speaker.shared.say(kana) } }
        .onAppear { reset() }
    }

    private func paper(_ side: CGFloat) -> some View {
        ZStack {
            Rectangle().fill(Color(hex: 0xFFFDF5))
            // practice-paper cross
            Path { p in
                p.move(to: CGPoint(x: side / 2, y: 0)); p.addLine(to: CGPoint(x: side / 2, y: side))
                p.move(to: CGPoint(x: 0, y: side / 2)); p.addLine(to: CGPoint(x: side, y: side / 2))
            }
            .stroke(Color(hex: 0xE05050).opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [6, 6]))
            Image(uiImage: glyph.image).resizable().frame(width: side, height: side)
                .blendMode(.multiply).opacity(guide || reveal || stamp != nil ? 0.22 : 0)
            Canvas { c, _ in
                for s in strokes {
                    guard let f = s.first else { continue }
                    var p = Path()
                    p.move(to: CGPoint(x: f.x * side, y: f.y * side))
                    for q in s.dropFirst() { p.addLine(to: CGPoint(x: q.x * side, y: q.y * side)) }
                    if s.count == 1 { p.addLine(to: CGPoint(x: f.x * side + 0.5, y: f.y * side)) }
                    c.stroke(p, with: .color(Color(hex: 0x1A1A1A)), style: StrokeStyle(lineWidth: side * 0.085, lineCap: .round, lineJoin: .round))
                }
            }
            if let s = stamp {
                ZStack {
                    Circle().stroke(Color(hex: 0xD62828), lineWidth: 6.s)
                    Circle().stroke(Color(hex: 0xD62828), lineWidth: 2.s).padding(9.s)
                    Text(s).font(.custom(Fonts.rounded, size: 30.s)).foregroundStyle(Color(hex: 0xD62828)).lineLimit(1).minimumScaleFactor(0.35)
                }
                .frame(width: side * 0.42, height: side * 0.42)
                .rotationEffect(.degrees(-14))
                .position(x: side * 0.74, y: side * 0.74)
                .transition(.scale(scale: 2.6).combined(with: .opacity))
            }
        }
        .frame(width: side, height: side)
        .overlay(Rectangle().stroke(Color.ink, lineWidth: 3))
        .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 4)
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { v in
                guard ctx.running, !busy else { return }
                let p = CGPoint(x: min(max(v.location.x / side, 0), 1), y: min(max(v.location.y / side, 0), 1))
                if !drawing {
                    drawing = true
                    strokes.append([p])
                    AudioManager.shared.se(.mgBrush, volume: 0.7)
                } else if !strokes.isEmpty {
                    strokes[strokes.count - 1].append(p)
                }
            }
            .onEnded { _ in drawing = false })
    }

    private func reset() {
        var base = Array(Set(letters)).shuffled()
        while base.count < ctx.target { base.append(contentsOf: KJC1.A.shuffled()) }
        order = Array(base.prefix(ctx.target))
        idx = 0
        load()
    }

    private func load() {
        strokes = []; stamp = nil; tries = 0; busy = false; reveal = false
        glyph = MGGlyph.make(kana)
    }

    private func judge() {
        guard ctx.running, !busy, !strokes.isEmpty else { return }
        let r = MGGlyph.judge(strokes, mask: glyph.mask)
        // writing from memory on blank paper is harder to place exactly: a little kinder
        let (needCover, needInside) = guide ? (0.55, 0.7) : (0.42, 0.58)
        if r.cover >= needCover && r.inside >= needInside {
            busy = true
            let great = r.cover >= 0.75 && r.inside >= 0.85
            AudioManager.shared.se(.mgStamp)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.45)) { stamp = great ? "すばらしい" : "よし" }
            ctx.good(great ? 200 : 100, at: CGPoint(x: 0.5, y: 0.5), word: kana)
            Speaker.shared.say(kana)
            later(1.4) { advance() }
        } else {
            tries += 1
            ctx.bad(at: CGPoint(x: 0.5, y: 0.5), shakeIt: false)
            ctx.pop("もう いっかい！", at: CGPoint(x: 0.5, y: 0.42), color: .sky)
            if !guide {
                // show the letter for a moment, then try again
                reveal = true
                later(1.3) { reveal = false; strokes = [] }
            } else {
                strokes = []
            }
            if tries >= 3 {
                // three misses: move on (no points) so nobody gets stuck
                busy = true
                later(0.9) { advance() }
            }
        }
    }

    private func advance() {
        if idx + 1 >= order.count {
            ctx.finish()
            return
        }
        idx += 1
        load()
        Speaker.shared.say(kana)
    }
}
