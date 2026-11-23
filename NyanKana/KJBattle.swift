import SwiftUI
import Combine

// MARK: - にゃんカナ バトル（1章1ステージ）
// Yokai minions (tsukumogami) carry the stolen letters. A voice calls one letter; the called minion
// starts to dive toward town. Tap the minion holding that letter before it reaches the bottom.
// After the waves, the mini-boss holds a whole word: tap the letters in order.

@MainActor
final class KJBattle: ObservableObject {
    struct Foe: Identifiable {
        let id = UUID()
        var kana: String
        var image: String
        var x: CGFloat           // 0...1 across the field
        var y: CGFloat           // 0...1 down the field (1 = reached town)
        var homeY: CGFloat
        var phase: Double = .random(in: 0...6)
        var dying = false
        var shake = false
    }
    struct Pop: Identifiable { let id = UUID(); var x: CGFloat; var y: CGFloat; var text: String }

    enum Stage: Equatable { case intro, waves, bossIntro, boss, won, lost }

    @Published var stage: Stage = .intro
    @Published var foes: [Foe] = []
    @Published var targetID: UUID?
    @Published var hearts = 3
    @Published var score = 0
    @Published var combo = 0
    @Published var maxCombo = 0
    @Published var fever: Double = 0          // seconds left
    @Published var pops: [Pop] = []
    @Published var hits = 0
    @Published var misses = 0
    @Published var flash = false
    // boss
    @Published var bossWord = 0
    @Published var bossTyped = ""
    @Published var bossTime: Double = 1       // 1 → 0
    @Published var bossHit = false
    @Published var bossShake = false

    let letters: [String]
    let goal = 15                              // minions to beat before the boss
    let bossWords = ["あお", "いえ", "うえ"]
    let bossImage = "nk_383"                   // もんじゃ焼きのせい
    private let minionImages = ["nk_342", "nk_343", "nk_344", "nk_345", "nk_346", "nk_349", "nk_350", "nk_352", "nk_353"]
    private var time: Double = 0
    private var spawnClock: Double = 0
    private var lastKana = ""

    var hintVisible: Bool { hits < 8 }         // the roman-letter hint fades out halfway
    var target: Foe? { foes.first { $0.id == targetID } }
    var bossAnswer: String { bossWords[min(bossWord, bossWords.count - 1)] }

    init(letters: [String]) { self.letters = letters }

    func start() {
        stage = .waves
        for i in 0..<3 { spawn(slot: i) }
        pickTarget()
    }

    // MARK: game loop
    func tick(_ dt: Double) {
        time += dt
        if fever > 0 { fever = max(0, fever - dt) }
        switch stage {
        case .waves: tickWaves(dt)
        case .boss: tickBoss(dt)
        default: break
        }
    }

    private var diveSpeed: CGFloat {
        // seconds to fall from the top to the town: 7 s at first, 4.5 s at the end; half speed in fever
        let secs = 7.0 - 2.5 * Double(min(hits, goal)) / Double(goal)
        return CGFloat(1 / secs) * (fever > 0 ? 0.5 : 1)
    }

    private func tickWaves(_ dt: Double) {
        for i in foes.indices where !foes[i].dying {
            if foes[i].id == targetID {
                foes[i].y += diveSpeed * CGFloat(dt)
            } else {
                foes[i].y += (foes[i].homeY - foes[i].y) * CGFloat(min(1, dt * 3))
            }
        }
        if let t = target, t.y >= 0.93 { eaten(t) }
        // keep three minions on the field
        spawnClock += dt
        if foes.filter({ !$0.dying }).count < 3, spawnClock > 0.6, hits + foes.count < goal + 2 {
            spawnClock = 0
            let used = Set(foes.filter { !$0.dying }.map { slotOf($0.x) })
            if let free = [0, 1, 2].first(where: { !used.contains($0) }) { spawn(slot: free) }
        }
        if targetID == nil, foes.contains(where: { !$0.dying }) { pickTarget() }
    }

    private func slotOf(_ x: CGFloat) -> Int { x < 0.35 ? 0 : x < 0.65 ? 1 : 2 }

    private func spawn(slot: Int) {
        let onField = Set(foes.filter { !$0.dying }.map(\.kana))
        let pool = letters.filter { !onField.contains($0) }
        guard let k = pool.randomElement() else { return }
        let x: CGFloat = [0.2, 0.5, 0.8][slot]
        let home = CGFloat.random(in: 0.08...0.3)
        foes.append(Foe(kana: k, image: minionImages.randomElement()!, x: x, y: -0.15, homeY: home))
        AudioManager.shared.se(.spawn, volume: 0.35)
    }

    private func pickTarget() {
        let alive = foes.filter { !$0.dying }
        guard !alive.isEmpty else { targetID = nil; return }
        // never the same letter twice in a row (when there is a choice)
        let choices = alive.count > 1 ? alive.filter { $0.kana != lastKana } : alive
        let t = choices.randomElement()!
        targetID = t.id
        lastKana = t.kana
        callOut()
    }

    func callOut() {
        if stage == .waves, let t = target { Speaker.shared.say(t.kana) }
        if stage == .boss { Speaker.shared.say(bossAnswer) }
    }

    func tap(_ foe: Foe) {
        guard stage == .waves, !foe.dying, let t = target else { return }
        if foe.kana == t.kana {
            defeat(foe)
        } else {
            wrong(foe)
        }
    }

    private func defeat(_ foe: Foe) {
        guard let i = foes.firstIndex(where: { $0.id == foe.id }) else { return }
        foes[i].dying = true
        hits += 1
        combo += 1; maxCombo = max(maxCombo, combo)
        let gain = (100 + Int((1 - foes[i].y) * 60)) * (1 + min(combo, 10) / 5) * (fever > 0 ? 2 : 1)
        score += gain
        let pop = Pop(x: foe.x, y: foe.y, text: combo >= 3 ? "\(combo) COMBO!" : "+\(gain)")
        pops.append(pop)
        AudioManager.shared.se(combo >= 5 ? .hitBig : .hitSmall)
        later(0.12) { AudioManager.shared.se(.kira, volume: 0.6) }
        if combo > 0, combo % 8 == 0 { startFever() }
        let id = foe.id
        targetID = nil
        later(0.45) { self.foes.removeAll { $0.id == id } }
        later(0.9) { self.pops.removeAll { $0.id == pop.id } }
        if hits >= goal {
            later(0.7) { self.toBoss() }
        } else {
            later(0.35) { if self.stage == .waves { self.pickTarget() } }
        }
    }

    private func wrong(_ foe: Foe) {
        combo = 0; misses += 1
        AudioManager.shared.se(.wrong, volume: 0.7)
        if let i = foes.firstIndex(where: { $0.id == foe.id }) {
            foes[i].shake = true
            later(0.35) { if let j = self.foes.firstIndex(where: { $0.id == foe.id }) { self.foes[j].shake = false } }
        }
        // a wrong tap pushes the real target closer to town
        if let j = foes.firstIndex(where: { $0.id == targetID }) { foes[j].y = min(0.9, foes[j].y + 0.12) }
        later(0.4) { self.callOut() }
    }

    private func eaten(_ foe: Foe) {
        // the minion reached town and ate the letter
        foes.removeAll { $0.id == foe.id }
        targetID = nil
        combo = 0; misses += 1
        hurt()
        if stage == .waves { later(0.6) { if self.stage == .waves { self.pickTarget() } } }
    }

    private func hurt() {
        hearts -= 1
        AudioManager.shared.se(.damage)
        flash = true
        later(0.25) { self.flash = false }
        if hearts <= 0 {
            stage = .lost
            AudioManager.shared.se(.gameOver)
        }
    }

    private func startFever() {
        fever = 8
        AudioManager.shared.se(.fever)
    }

    // MARK: boss
    private func toBoss() {
        foes.removeAll()
        targetID = nil
        stage = .bossIntro
        AudioManager.shared.se(.bossAppear)
        AudioManager.shared.playBGM(.boss)
    }

    func startBoss() {
        stage = .boss
        bossWord = 0; bossTyped = ""; bossTime = 1
        later(0.4) { self.callOut() }
    }

    private func tickBoss(_ dt: Double) {
        bossTime -= dt / (fever > 0 ? 16 : 9)
        if bossTime <= 0 {
            bossTime = 1
            bossTyped = ""
            bossShake = true
            later(0.4) { self.bossShake = false }
            hurt()
            if stage == .boss { later(0.5) { self.callOut() } }
        }
    }

    func bossTap(_ k: String) {
        guard stage == .boss else { return }
        let want = Array(bossAnswer)
        let next = String(want[bossTyped.count])
        if k == next {
            bossTyped += k
            AudioManager.shared.se(.hitSmall)
            Speaker.shared.say(k)
            if bossTyped.count == want.count {
                // one word done: a big hit
                combo += 1; maxCombo = max(maxCombo, combo)
                score += 500 * (fever > 0 ? 2 : 1)
                bossHit = true
                AudioManager.shared.se(.superHit)
                later(0.35) { self.bossHit = false }
                bossWord += 1
                if bossWord >= bossWords.count {
                    later(0.5) {
                        self.stage = .won
                        AudioManager.shared.se(.bossDefeat)
                        later(0.6) { AudioManager.shared.se(.victory) }
                    }
                } else {
                    later(0.7) { self.bossTyped = ""; self.bossTime = 1; self.callOut() }
                }
            }
        } else {
            combo = 0; misses += 1
            bossTyped = ""
            bossTime = max(0.05, bossTime - 0.2)
            AudioManager.shared.se(.wrong, volume: 0.7)
            later(0.4) { self.callOut() }
        }
    }

    var stars: Int {
        if stage != .won { return 0 }
        if hearts == 3 && misses <= 2 { return 3 }
        return hearts >= 2 ? 2 : 1
    }
}

// MARK: - the battle screen

struct KJBattleView: View {
    @Binding var won: Set<String>
    var done: () -> Void
    @StateObject private var b = KJBattle(letters: KJData.aRow.map(\.kana))
    @State private var clock = Timer.publish(every: 1.0 / 30, on: .main, in: .common).autoconnect()
    @State private var t: Double = 0

    var body: some View {
        GeometryReader { g in
            ZStack {
                // danger: town line near the bottom
                VStack {
                    Spacer()
                    Rectangle().fill(Color.danger.opacity(0.18)).frame(height: g.size.height * 0.14)
                        .overlay(alignment: .top) { Rectangle().fill(Color.danger.opacity(0.6)).frame(height: 3) }
                }
                .ignoresSafeArea()

                VStack(spacing: 6.s) {
                    hud
                    KJSignBoard(won: won).scaleEffect(0.8)
                    Spacer()
                }
                .padding(.top, 54.s)

                field(g.size)

                VStack {
                    Spacer()
                    if b.stage == .boss { bossPad } else { prompt }
                }
                .padding(.bottom, 18.s)

                if b.flash { Color.red.opacity(0.25).ignoresSafeArea().allowsHitTesting(false) }
                if b.fever > 0 {
                    Text("FEVER!").font(.display(30.s)).foregroundStyle(Color.sun)
                        .shadow(color: .black.opacity(0.4), radius: 0, x: 2, y: 2)
                        .position(x: g.size.width / 2, y: g.size.height * 0.33)
                        .allowsHitTesting(false)
                }
                overlay
            }
        }
        .onReceive(clock) { _ in
            t += 1.0 / 30
            b.tick(1.0 / 30)
        }
        .onChange(of: b.hits) { _, n in
            // every beaten minion returns its letter to the town signs
            if let k = KJData.aRow.map(\.kana)[safe: (n - 1) % 5] { _ = withAnimation(.spring) { won.insert(k) } }
        }
        .onAppear {
            AudioManager.shared.playBGM(.area(.lv1))
            later(0.3) { Speaker.shared.say("ようかいの てしたが きた！", voice: .nyan) }
        }
    }

    // MARK: parts
    private var hud: some View {
        HStack {
            HStack(spacing: 3.s) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: i < b.hearts ? "heart.fill" : "heart")
                        .font(.system(size: 20.s, weight: .bold))
                        .foregroundStyle(i < b.hearts ? Color.pop : Color.ink.opacity(0.3))
                }
            }
            Spacer()
            if b.combo >= 2 {
                Text("\(b.combo) COMBO").font(.display(18.s)).foregroundStyle(Color.popDeep)
            }
            Spacer()
            Text("\(b.score)").font(.display(22.s)).foregroundStyle(Color.ink).monospacedDigit()
        }
        .padding(.horizontal, 18.s).padding(.vertical, 6.s)
        .background(Capsule().fill(Color.white.opacity(0.85)).overlay(Capsule().stroke(Color.ink, lineWidth: 3)))
        .padding(.horizontal, 14.s)
    }

    private func field(_ size: CGSize) -> some View {
        let top = size.height * 0.27, bottom = size.height * 0.78
        return ZStack {
            ForEach(b.foes) { f in
                let isTarget = f.id == b.targetID
                let bob = sin(t * 2 + f.phase) * 6
                Button { b.tap(f) } label: {
                    VStack(spacing: -10.s) {
                        // the stolen letter
                        Text(f.kana).font(.custom(Fonts.rounded, size: 34.s)).foregroundStyle(Color.ink)
                            .frame(width: 56.s, height: 56.s)
                            .background(Circle().fill(Color.white).overlay(Circle().stroke(isTarget ? Color.pop : Color.ink, lineWidth: isTarget ? 4 : 3)))
                            .zIndex(1)
                        Image(f.image).resizable().scaledToFit().frame(width: 92.s, height: 92.s)
                    }
                    .scaleEffect(f.dying ? 1.5 : (isTarget ? 1.08 : 1))
                    .opacity(f.dying ? 0 : 1)
                    .rotationEffect(.degrees(f.shake ? 12 : 0))
                    .animation(.easeOut(duration: 0.35), value: f.dying)
                    .animation(.default.repeatCount(3, autoreverses: true).speed(5), value: f.shake)
                }
                .buttonStyle(.plain)
                .position(x: size.width * f.x, y: top + (bottom - top) * f.y + (isTarget ? 0 : bob))
                if f.dying {
                    StarBurst().fill(Color.sun).frame(width: 110.s, height: 110.s)
                        .position(x: size.width * f.x, y: top + (bottom - top) * f.y)
                        .allowsHitTesting(false)
                }
            }
            ForEach(b.pops) { p in
                Text(p.text).font(.display(20.s)).foregroundStyle(Color.popDeep)
                    .shadow(color: .white, radius: 0, x: 1, y: 1)
                    .position(x: size.width * p.x, y: top + (bottom - top) * p.y - 60.s)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .allowsHitTesting(false)
            }
            if b.stage == .boss || b.stage == .bossIntro { boss(size) }
        }
    }

    private func boss(_ size: CGSize) -> some View {
        VStack(spacing: 8.s) {
            // the word the boss is holding: blanks fill as you tap
            HStack(spacing: 6.s) {
                ForEach(Array(b.bossAnswer.enumerated()), id: \.offset) { i, _ in
                    let typed = Array(b.bossTyped)
                    Text(i < typed.count ? String(typed[i]) : "？")
                        .font(.custom(Fonts.rounded, size: 34.s)).foregroundStyle(i < typed.count ? Color.ink : Color.ink.opacity(0.3))
                        .frame(width: 56.s, height: 56.s)
                        .background(Circle().fill(Color.white).overlay(Circle().stroke(Color.ink, lineWidth: 3)))
                }
            }
            Image(b.bossImage).resizable().scaledToFit().frame(width: 200.s, height: 200.s)
                .scaleEffect(b.bossHit ? 0.85 : 1)
                .rotationEffect(.degrees(b.bossShake ? -8 : 0))
                .animation(.spring(response: 0.25, dampingFraction: 0.4), value: b.bossHit)
                .modifier(Bob())
            // boss attack timer
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white)
                    Capsule().fill(b.bossTime < 0.3 ? Color.danger : Color.sun).frame(width: g.size.width * max(0, b.bossTime))
                }
                .overlay(Capsule().stroke(Color.ink, lineWidth: 2))
            }
            .frame(width: 180.s, height: 12.s)
            HStack(spacing: 4.s) {
                ForEach(0..<b.bossWords.count, id: \.self) { i in
                    Circle().fill(i < b.bossWord ? Color.ink.opacity(0.2) : Color.pop).frame(width: 10.s, height: 10.s)
                }
            }
        }
        .position(x: size.width / 2, y: size.height * 0.5)
    }

    private var prompt: some View {
        VStack(spacing: 6.s) {
            HStack(alignment: .bottom, spacing: 10.s) {
                Image(b.combo >= 5 ? "nk_nyan_joy" : "nk_nyan_proud").resizable().scaledToFit().frame(height: 74.s)
                VStack(spacing: 4.s) {
                    Button { b.callOut() } label: {
                        HStack(spacing: 8.s) {
                            Image(systemName: "speaker.wave.3.fill").font(.system(size: 24.s, weight: .bold))
                            if b.hintVisible, let k = b.target?.kana, let l = KJData.aRow.first(where: { $0.kana == k }) {
                                Text(l.romaji).font(.display(24.s))
                            }
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22.s).padding(.vertical, 12.s)
                        .background(Capsule().fill(Color.sky).overlay(Capsule().stroke(Color.ink, lineWidth: 3)))
                    }
                    .buttonStyle(PressStyle(radius: 30, depth: 4))
                    Text(KJ.both("Tap the letter you hear!", "點出聽到的假名！", "들리는 글자를 터치!"))
                        .font(.ui(12.s, bold: false)).foregroundStyle(Color.ink).multilineTextAlignment(.center)
                }
                Image("sora_full").resizable().scaledToFit().frame(height: 80.s)
            }
            ProgressView(value: Double(min(b.hits, b.goal)), total: Double(b.goal)).tint(Color.pop)
                .frame(width: 200.s)
        }
        .padding(.horizontal, 14.s)
    }

    private var bossPad: some View {
        VStack(spacing: 8.s) {
            Button { b.callOut() } label: {
                HStack(spacing: 8.s) {
                    Image(systemName: "speaker.wave.3.fill").font(.system(size: 22.s, weight: .bold))
                    Text(KJ.t("Listen", "聽", "듣기")).font(.ui(16.s))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20.s).padding(.vertical, 10.s)
                .background(Capsule().fill(Color.sky).overlay(Capsule().stroke(Color.ink, lineWidth: 3)))
            }
            .buttonStyle(PressStyle(radius: 30, depth: 4))
            HStack(spacing: 8.s) {
                ForEach(KJData.aRow.map(\.kana), id: \.self) { k in
                    Button { b.bossTap(k) } label: {
                        Text(k).font(.custom(Fonts.rounded, size: 36.s)).foregroundStyle(Color.ink)
                            .frame(width: 60.s, height: 66.s)
                            .background(RoundedRectangle(cornerRadius: 14.s).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 14.s).stroke(Color.ink, lineWidth: 3)))
                    }
                    .buttonStyle(PressStyle(radius: 14.s, depth: 5))
                }
            }
            Text(KJ.both("Spell the word you hear!", "拼出聽到的單字！", "들리는 단어를 만들어요!"))
                .font(.ui(12.s, bold: false)).foregroundStyle(Color.ink)
        }
    }

    @ViewBuilder private var overlay: some View {
        switch b.stage {
        case .intro:
            banner(title: KJ.both("Yokai minions are here!", "妖怪的手下來了！", "요괴 부하들이 왔다!"),
                   sub: KJ.both("They hold the stolen letters. Listen, then tap the one that has it.",
                               "牠們拿著被偷走的文字。聽發音，點出拿著那個字的妖怪。",
                               "훔친 글자를 들고 있어요. 소리를 듣고 그 글자를 가진 요괴를 터치!"),
                   image: "nk_nyan_proud", button: "START") { b.start() }
        case .bossIntro:
            banner(title: KJ.both("The Monjayaki Spirit appears!", "文字燒精靈出現了！", "몬자야키 정령 등장!"),
                   sub: KJ.both("It ate whole words. Listen and tap the letters in order.",
                               "牠吃掉了整個單字。聽發音，依序點出假名。",
                               "단어를 통째로 먹었어요. 듣고 글자를 순서대로 터치!"),
                   image: b.bossImage, button: "GO!") { b.startBoss() }
        case .won:
            banner(title: KJ.both("You won!", "勝利！", "승리!"),
                   sub: String(repeating: "★", count: b.stars) + String(repeating: "☆", count: 3 - b.stars) + "   \(b.score)",
                   image: "nk_nyan_joy", button: KJ.both("Next", "下一步", "다음")) {
                AudioManager.shared.playBGM(.area(.lv1)); done()
            }
        case .lost:
            banner(title: KJ.both("The letters got eaten…", "文字被吃掉了……", "글자를 먹혀 버렸다…"),
                   sub: KJ.both("Try again!", "再試一次！", "다시 도전!"),
                   image: "nk_nyan_sad", button: KJ.both("Retry", "再來一次", "다시 하기")) {
                b.hearts = 3; b.combo = 0; b.foes.removeAll(); b.targetID = nil
                if b.hits >= b.goal { b.startBoss() } else { b.start() }
            }
        default: EmptyView()
        }
    }

    private func banner(title: String, sub: String, image: String, button: String, _ action: @escaping () -> Void) -> some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            PaperCard {
                VStack(spacing: 12.s) {
                    Image(image).resizable().scaledToFit().frame(height: 130.s).modifier(Bob())
                    Text(title).font(.ui(22.s)).foregroundStyle(Color.ink).multilineTextAlignment(.center)
                    Text(sub).font(.ui(14.s, bold: false)).foregroundStyle(Color.ink.opacity(0.8)).multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    KJButton(title: button, color: .pop, textColor: .white, action: action)
                }
            }
            .padding(.horizontal, 30.s)
        }
    }
}
