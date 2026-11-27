import SwiftUI
import Combine

// MARK: - にゃんカナ バトル
// Yokai minions carry the stolen letters. Several kinds of questions are mixed so it never feels the same:
//  • listen: a voice calls a letter, that minion dives — tap it before it reaches town
//  • read:   one minion glows (no voice) — pick how it sounds from three buttons
//  • word:   a picture appears — tap the letters in order to make the word
// Mid-boss / boss stages end with a yokai that holds whole words. Questions are random every time.

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
    /// a damage number that jumps off the boss
    struct Dmg: Identifiable { let id = UUID(); let text: String; let dx: CGFloat; let born = Date() }

    enum Phase: Equatable { case intro, waves, word, bossIntro, boss, won, lost }
    enum Ask: Equatable { case listen, read }

    @Published var phase: Phase = .intro
    @Published var foes: [Foe] = []
    @Published var targetID: UUID?
    @Published var ask: Ask = .listen
    /// ⑨ the glowing minion was tapped in "read" mode: point at the answer buttons
    @Published var readHint = false
    @Published var readChoices: [String] = []
    /// the first "read" questions: everything stops and an arrow points at the buttons below
    @Published var readTutorial = false
    /// after a wrong answer nothing can be tapped for a moment (no guessing by tapping everything fast)
    @Published var locked = false
    private var wrongOnTarget = 0
    private var readsRight = 0
    static var readTutorialSeen: Int {
        get { UserDefaults.standard.integer(forKey: "kj.readTut") }
        set { UserDefaults.standard.set(newValue, forKey: "kj.readTut") }
    }
    @Published var hearts = 3
    @Published var score = 0
    @Published var combo = 0
    @Published var maxCombo = 0
    @Published var fever: Double = 0          // seconds left
    @Published var pops: [Pop] = []
    @Published var hits = 0
    @Published var misses = 0
    @Published var flash = false
    // word round / boss
    @Published var word = ""
    @Published var typed = ""
    @Published var pad: [String] = []
    @Published var wordTime: Double = 1       // 1 → 0
    @Published var bossWord = 0
    @Published var bossHit = false
    @Published var bossShake = false
    @Published var dmgs: [Dmg] = []
    /// +1 = the whole screen shakes once
    @Published var quake: CGFloat = 0
    /// the last hit: the boss spins away, a big "とどめ！" and a white flash, then the win
    @Published var finishing = false
    @Published var whiteOut = false
    // stage 9: the kite that flies over and steals snacks
    @Published var tonbiX: CGFloat = -0.3
    @Published var tonbiOn = false
    @Published var won: [String] = []          // letters / words taken back (for the clear screen)

    let st: KJC1.Stage
    let goal: Int
    let bossWords: [String]
    private var wordsLeft: [String] = []
    /// each region has its own yokai minions (also listed in the picture book)
    /// (letter spirits — もじだま — carry a letter on their body; in battle that letter would be confused
    /// with the one in the bubble, so the battle uses the picture yokai only)
    private var minionImages: [String] {
        KJZukan.battleMinions(st.chapter)
    }
    private var time: Double = 0
    private var spawnClock: Double = 0
    private var lastKana = ""
    private var tonbiClock: Double = 0
    private var hitsAtLastWord = 0
    /// a new target is already on its way (stops the game loop from picking a second one = the "feint" bug)
    private var pickPending = false

    var hasBoss: Bool { st.kind == .mid || st.kind == .boss }
    var bossImage: String { st.bossImage }
    var target: Foe? { foes.first { $0.id == targetID } }
    /// the roman-letter hint: always on the first stage's first half, then only for the new letters early on
    var hintVisible: Bool {
        guard let k = target?.kana else { return false }
        return hits < goal / 2 && (st.id == 1 || st.newKana.contains(k))
    }
    var fogAlpha: Double { st.fog ? 0.15 + 0.85 * max(0, sin(time * 1.6)) : 1 }

    /// the boss words (never empty: readable taught words → any taught words → the stage's words → a letter)
    private static func bossList(_ stage: KJC1.Stage, _ n: Int) -> [String] {
        for pool in [KJLearned.answerWords(for: stage, readable: true), KJLearned.answerWords(for: stage), stage.words, stage.known] where !pool.isEmpty {
            return Array(pool.shuffled().prefix(n))
        }
        return ["あ"]
    }

    init(stage: KJC1.Stage) {
        st = stage
        goal = stage.goal
        hearts = KJLap.hearts
        switch stage.kind {
        case .boss: bossWords = Self.bossList(stage, 9)
        case .mid: bossWords = Self.bossList(stage, 4)
        default: bossWords = []
        }
    }

    func start() {
        phase = .waves
        pickPending = false
        for i in 0..<3 { spawn(slot: i) }
        pickTarget()
    }

    // MARK: game loop
    func tick(_ dt: Double) {
        time += dt
        if fever > 0 { fever = max(0, fever - dt) }
        if finishing { return }
        switch phase {
        case .waves: if !readTutorial { tickWaves(dt); tickTonbi(dt) }
        case .word, .boss: tickWord(dt)
        default: break
        }
    }

    private var diveSpeed: CGFloat {
        // seconds to fall from the top to the town: 7.5 s at first, 3.8 s at the end (faster and faster);
        // "read" questions start a little slower and catch up with each right answer; fever slows things a bit
        let secs = 7.5 - 3.7 * Double(min(hits, goal)) / Double(max(goal, 1))
        let readFactor = ask == .read ? min(1.0, 0.6 + 0.08 * Double(readsRight)) : 1.0
        // later rounds dive faster (2しゅうめ ×1.2, 3しゅうめ ×1.4)
        return CGFloat(1 / secs) * (fever > 0 ? 0.75 : 1) * CGFloat(readFactor) * CGFloat(KJLap.speed)
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
        spawnClock += dt
        if foes.filter({ !$0.dying }).count < 3, spawnClock > 0.6 {
            spawnClock = 0
            let used = Set(foes.filter { !$0.dying }.map { slotOf($0.x) })
            if let free = [0, 1, 2].first(where: { !used.contains($0) }) { spawn(slot: free) }
        }
        if targetID == nil, !pickPending, foes.contains(where: { !$0.dying }) { pickTarget() }
    }

    private func tickTonbi(_ dt: Double) {
        guard st.tonbi else { return }
        if tonbiOn {
            tonbiX += CGFloat(dt) * 0.32
            if tonbiX > 1.3 { tonbiOn = false }
        } else {
            tonbiClock += dt
            if tonbiClock > Double.random(in: 9...14) { tonbiClock = 0; tonbiX = -0.3; tonbiOn = true; AudioManager.shared.se(.papa, volume: 0.5) }
        }
    }

    func tapTonbi() {
        guard tonbiOn else { return }
        tonbiOn = false
        score += 300
        let pop = Pop(x: min(0.85, max(0.15, tonbiX)), y: 0.0, text: "せんべい GET! +300")
        pops.append(pop)
        AudioManager.shared.se(.itemGet)
        later(1.0) { self.pops.removeAll { $0.id == pop.id } }
    }

    private func slotOf(_ x: CGFloat) -> Int { x < 0.35 ? 0 : x < 0.65 ? 1 : 2 }

    /// new letters come up three times as often; look-alike letters are always in the mix
    private func pickLetter(excluding: Set<String>) -> String? {
        var bag: [String] = []
        for k in st.known where !excluding.contains(k) {
            bag += Array(repeating: k, count: st.newKana.contains(k) ? 3 : 1)
        }
        // a look-alike of the current target is likely to show up next to it
        if let t = target?.kana, let group = KJData.lookAlike.first(where: { $0.contains(t) }) {
            for k in group where k != t && st.known.contains(k) && !excluding.contains(k) { bag += [k, k] }
        }
        return bag.randomElement()
    }

    private func spawn(slot: Int) {
        let onField = Set(foes.filter { !$0.dying }.map(\.kana))
        guard let k = pickLetter(excluding: onField) else { return }
        let x: CGFloat = [0.2, 0.5, 0.8][slot]
        let home = CGFloat.random(in: 0.08...0.3)
        let img = minionImages.randomElement() ?? "nk_342"
        KJZukan.see(img)
        foes.append(Foe(kana: k, image: img, x: x, y: -0.15, homeY: home))
        AudioManager.shared.se(.spawn, volume: 0.35)
    }

    private func pickTarget() {
        pickPending = false
        let alive = foes.filter { !$0.dying }
        guard !alive.isEmpty else { targetID = nil; return }
        // never the same letter twice in a row (when there is a choice); new letters first
        var choices = alive.filter { $0.kana != lastKana }
        if choices.isEmpty { choices = alive }          // (all on screen are the last letter: allow it)
        let fresh = choices.filter { st.newKana.contains($0.kana) }
        if !fresh.isEmpty, Bool.random() { choices = fresh }
        guard let t = choices.randomElement() else { targetID = nil; return }
        targetID = t.id
        lastKana = t.kana
        wrongOnTarget = 0
        // mix the kinds of question (the very first ones are always "listen")
        // (rounds 2-3 ask "how is it read?" more often — reading is the real test)
        ask = (hits >= 4 && Double.random(in: 0...1) < KJLap.readChance) ? .read : .listen
        if ask == .read {
            var opts = Set([KJData.romaji(t.kana)])
            // wrong choices: the sounds of letters that LOOK like it first (き → さ・ち, 木 → 本・休), then the rest
            let others = mgDecoys(t.kana, st.known)
            for o in others where opts.count < 3 && !KJData.romaji(o).isEmpty { opts.insert(KJData.romaji(o)) }
            readChoices = Array(opts).shuffled()
            AudioManager.shared.se(.eyeShine, volume: 0.5)
            // the first two times ever: stop and show where to answer
            if Self.readTutorialSeen < 2 { readTutorial = true }
        } else {
            callOut()
        }
    }

    func callOut() {
        switch phase {
        case .waves: if ask == .listen, let t = target { Speaker.shared.say(t.kana) }
        case .word, .boss: Speaker.shared.say(word)
        default: break
        }
    }

    private var lastTap: (id: UUID, at: Double)?
    func tap(_ seen: Foe) {
        // the gesture reports every finger move: act once per touch, on the minion as it is now
        if let l = lastTap, l.id == seen.id, time - l.at < 0.5 { return }
        lastTap = (seen.id, time)
        guard phase == .waves, !locked, let foe = foes.first(where: { $0.id == seen.id }), !foe.dying, let t = target else { return }
        if ask == .read {
            // in "read" mode the answer is a sound button, not a minion
            if foe.id != t.id && !AppState.shared.dev.anyRight { wrong(foe) } else {
                AudioManager.shared.se(.tap)
                readHint = true
                later(1.4) { self.readHint = false }
            }
            return
        }
        if foe.kana == t.kana || AppState.shared.dev.anyRight { defeat(foe.kana == t.kana ? foe : t) } else { wrong(foe) }
    }

    func read(_ romaji: String) {
        guard phase == .waves, ask == .read, !locked, let t = target else { return }
        if readTutorial { readTutorial = false; Self.readTutorialSeen += 1 }
        if romaji == KJData.romaji(t.kana) || AppState.shared.dev.anyRight {
            readsRight += 1
            Speaker.shared.say(t.kana)
            defeat(t)
        } else {
            wrong(t)
        }
    }

    private func defeat(_ foe: Foe) {
        guard let i = foes.firstIndex(where: { $0.id == foe.id }) else { return }
        foes[i].dying = true
        hits += 1
        if !won.contains(foe.kana) { won.append(foe.kana) }
        combo += 1; maxCombo = max(maxCombo, combo)
        let gain = (100 + Int((1 - foes[i].y) * 60)) * (1 + min(combo, 10) / 5) * (fever > 0 ? 2 : 1) + (ask == .read ? 50 : 0)
        score += gain
        let pop = Pop(x: foe.x, y: foe.y, text: combo >= 3 ? "\(combo) COMBO!" : "+\(gain)")
        pops.append(pop)
        AudioManager.shared.se(combo >= 5 ? .hitBig : .hitSmall)
        later(0.12) { AudioManager.shared.se(.kira, volume: 0.6) }
        if combo > 0, combo % 8 == 0 { startFever() }
        let id = foe.id
        targetID = nil
        pickPending = true
        later(0.45) { self.foes.removeAll { $0.id == id } }
        later(0.9) { self.pops.removeAll { $0.id == pop.id } }
        if hits >= goal {
            later(0.7) { self.finishWaves() }
        } else if !st.words.isEmpty, hits - hitsAtLastWord >= 6 {
            hitsAtLastWord = hits
            // switch right after the answer (no waiting beat)
            later(0.15) { self.startWordRound() }
        } else {
            later(0.35) { if self.phase == .waves { self.pickTarget() } }
        }
    }

    private func wrong(_ foe: Foe) {
        combo = 0; misses += 1
        score = max(0, score - 30)
        AudioManager.shared.se(.wrong, volume: 0.7)
        // no freeze (fast players keep their tempo), but tapping everything does not work:
        // the second miss on the same letter costs a heart
        wrongOnTarget += 1
        if wrongOnTarget >= 2 { wrongOnTarget = 0; hurt(); if phase == .lost { return } }
        if let i = foes.firstIndex(where: { $0.id == foe.id }) {
            foes[i].shake = true
            later(0.35) { if let j = self.foes.firstIndex(where: { $0.id == foe.id }) { self.foes[j].shake = false } }
        }
        // a wrong answer pushes the real target closer to town
        if let j = foes.firstIndex(where: { $0.id == targetID }) { foes[j].y = min(0.9, foes[j].y + 0.12) }
        if ask == .listen { later(0.4) { self.callOut() } }
    }

    private func eaten(_ foe: Foe) {
        foes.removeAll { $0.id == foe.id }
        targetID = nil
        pickPending = true
        combo = 0; misses += 1
        hurt()
        if phase == .waves { later(0.6) { if self.phase == .waves { self.pickTarget() } } }
    }

    private func hurt() {
        if AppState.shared.dev.enabled && AppState.shared.dev.noDamage { AudioManager.shared.se(.damage); return }
        hearts -= 1
        AudioManager.shared.se(.damage)
        flash = true
        later(0.25) { self.flash = false }
        if hearts <= 0 {
            phase = .lost
            AudioManager.shared.se(.gameOver)
        }
    }

    private func startFever() {
        fever = 8
        AudioManager.shared.se(.fever)
    }

    private func finishWaves() {
        foes.removeAll(); targetID = nil
        if !hasBoss { finishBlow(); return }
        if hasBoss {
            phase = .bossIntro
            AudioManager.shared.se(.bossAppear)
            AudioManager.shared.playBGM(.boss)
        } else {
            win()
        }
    }

    private func win() {
        finishing = false
        phase = .won
        AudioManager.shared.se(hasBoss ? .winBoss : .win)
    }

    /// a normal hit on the boss / the word card: flash, knock-back, shake and a damage number
    private func damageFx(_ gain: Int) {
        bossHit = true
        withAnimation(.linear(duration: 0.35)) { quake += 1 }
        dmgs.append(Dmg(text: "\(gain)", dx: .random(in: -50...50)))
        let id = dmgs.last!.id
        AudioManager.shared.se(.superHit)
        later(0.1) { AudioManager.shared.se(.kira, volume: 0.6) }
        later(0.35) { self.bossHit = false }
        later(1.0) { self.dmgs.removeAll { $0.id == id } }
    }

    /// the finishing blow: slow, big and loud, then the win
    private func finishBlow() {
        guard !finishing else { return }
        finishing = true
        bossHit = true
        AudioManager.shared.stopBGM()
        AudioManager.shared.se(.finish)
        whiteOut = true
        later(0.12) { self.whiteOut = false }
        withAnimation(.linear(duration: 0.6)) { quake += 2 }
        later(0.3) { self.bossHit = false }
        later(1.7) { self.win() }
    }

    // MARK: word rounds (picture → word) and the boss (it holds whole words)
    private func makePad(for w: String) -> [String] {
        var keys = w.map(String.init)
        let extra = st.known.filter { !keys.contains($0) }.shuffled()
        for k in extra where keys.count < 8 { keys.append(k) }
        // keep each key once
        var seen = Set<String>(); keys = keys.filter { seen.insert($0).inserted }
        return keys.shuffled()
    }

    private func startWordRound() {
        if wordsLeft.isEmpty { wordsLeft = KJLearned.answerWords(for: st, readable: true).shuffled() }
        guard !wordsLeft.isEmpty else { pickTarget(); return }    // no readable word yet: keep to letters
        word = wordsLeft.removeFirst()
        typed = ""; wordTime = 1
        pad = makePad(for: word)
        foes.removeAll(); targetID = nil
        phase = .word
        AudioManager.shared.se(.decide)
        later(0.25) { self.callOut() }
    }

    func startBoss() {
        phase = .boss
        bossWord = 0
        nextBossWord()
    }

    private func nextBossWord() {
        word = bossWords[min(bossWord, bossWords.count - 1)]
        typed = ""; wordTime = 1
        pad = makePad(for: word)
        later(0.4) { self.callOut() }
    }

    private func tickWord(_ dt: Double) {
        let secs: Double = phase == .boss ? (st.kind == .boss ? 8 : 10) : 12
        wordTime -= dt / (secs * (fever > 0 ? 1.8 : 1))
        if wordTime <= 0 {
            wordTime = 1
            typed = ""
            bossShake = true
            later(0.4) { self.bossShake = false }
            hurt()
            if phase == .boss || phase == .word { later(0.5) { self.callOut() } }
        }
    }

    func padTap(_ k: String) {
        guard (phase == .word || phase == .boss), !finishing else { return }
        let want = Array(word)
        guard typed.count < want.count else { return }
        let next = String(want[typed.count])
        if k == next {
            typed += k
            AudioManager.shared.se(.hitSmall)
            if typed.count == want.count { wordDone() }
        } else {
            combo = 0; misses += 1
            typed = ""
            wordTime = max(0.05, wordTime - 0.2)
            AudioManager.shared.se(.wrong, volume: 0.7)
            later(0.4) { self.callOut() }
        }
    }

    private func wordDone() {
        combo += 1; maxCombo = max(maxCombo, combo)
        score += 500 * (fever > 0 ? 2 : 1)
        if !won.contains(word) { won.append(word) }
        Speaker.shared.say(word)
        let last = phase == .boss && bossWord + 1 >= bossWords.count
        if last {
            finishBlow()
        } else {
            damageFx(500 * (fever > 0 ? 2 : 1))
        }
        if phase == .word {
            later(0.9) {
                self.phase = .waves
                for i in 0..<3 { self.spawn(slot: i) }
                self.pickTarget()
            }
        } else {
            bossWord += 1
            if bossWord >= bossWords.count {
                // finishBlow() leads to the win
            } else {
                later(0.8) { self.nextBossWord() }
            }
        }
    }

    func retry() {
        hearts = KJLap.hearts; combo = 0; foes.removeAll(); targetID = nil; locked = false; readTutorial = false; readsRight = 0
        finishing = false; whiteOut = false; dmgs = []
        if phase == .lost && hits >= goal && hasBoss { startBoss() } else { start() }
    }

    var stars: Int {
        if phase != .won { return 0 }
        if hearts == KJLap.hearts && misses <= 2 { return 3 }
        return hearts >= KJLap.hearts - 1 && hearts >= 2 ? 2 : 1
    }
}

// MARK: - the battle screen

struct KJBattleView: View {
    let stage: KJC1.Stage
    var finished: (_ stars: Int, _ score: Int, _ won: [String]) -> Void
    @StateObject private var b: KJBattle
    @State private var clock = Timer.publish(every: 1.0 / 30, on: .main, in: .common).autoconnect()
    @State private var t: Double = 0

    init(stage: KJC1.Stage, finished: @escaping (_ stars: Int, _ score: Int, _ won: [String]) -> Void) {
        self.stage = stage
        self.finished = finished
        _b = StateObject(wrappedValue: KJBattle(stage: stage))
    }

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
                    Spacer()
                }
                .padding(.top, 54.s)

                field(g.size)
                    .modifier(MGShake(amount: b.quake))

                VStack {
                    Spacer()
                    switch b.phase {
                    case .word, .boss: wordPad
                    default: prompt
                    }
                }
                .padding(.bottom, 18.s)

                if b.flash { Color.red.opacity(0.25).ignoresSafeArea().allowsHitTesting(false) }
                if b.finishing { finishTitle(g.size) }
                Color.white.opacity(b.whiteOut ? 0.9 : 0).ignoresSafeArea().allowsHitTesting(false)
                    .animation(.easeOut(duration: b.whiteOut ? 0.05 : 0.5), value: b.whiteOut)
                if b.fever > 0 {
                    Text("FEVER!").font(.display(30.s)).foregroundStyle(Color.sun)
                        .shadow(color: .black.opacity(0.4), radius: 0, x: 2, y: 2)
                        .position(x: g.size.width / 2, y: g.size.height * 0.2)
                        .allowsHitTesting(false)
                }
                overlay
            }
        }
        .onReceive(clock) { _ in
            t += 1.0 / 30
            b.tick(1.0 / 30)
        }
        .onAppear {
            // the minion battle has its own track; the boss part switches to the boss music
            AudioManager.shared.playBGM(.track("mg_zako"))
        }
    }

    // MARK: parts
    private var hud: some View {
        HStack {
            HStack(spacing: 3.s) {
                ForEach(0..<KJLap.hearts, id: \.self) { i in
                    Image(systemName: i < b.hearts ? "heart.fill" : "heart")
                        .font(.system(size: 20.s, weight: .bold))
                        .foregroundStyle(i < b.hearts ? Color.pop : Color.ink.opacity(0.3))
                }
            }
            Spacer()
            if b.combo >= 2 {
                Text("\(b.combo) COMBO").font(.display(18.s)).foregroundStyle(Color.popDeep)
                    .lineLimit(1).fixedSize()
            }
            Spacer()
            Text("\(b.score)").font(.display(22.s)).foregroundStyle(Color.ink).monospacedDigit()
                .lineLimit(1).minimumScaleFactor(0.6)
        }
        .padding(.horizontal, 18.s).padding(.vertical, 6.s)
        .background(Capsule().fill(Color.white.opacity(0.85)).overlay(Capsule().stroke(Color.ink, lineWidth: 3)))
        .padding(.horizontal, 14.s)
    }

    private func field(_ size: CGSize) -> some View {
        let top = size.height * 0.22, bottom = size.height * 0.74
        return ZStack {
            ForEach(b.foes) { f in
                let isTarget = f.id == b.targetID
                let bob = sin(t * 2 + f.phase) * 6
                let glow = isTarget && b.ask == .read
                VStack(spacing: -10.s) {
                        Text(f.kana).font(.custom(Fonts.rounded, size: 34.s)).foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.35)
                            .opacity(glow ? 1 : b.fogAlpha)
                            .frame(width: 56.s, height: 56.s)
                            .background(Circle().fill(glow ? Color.sun : Color.white)
                                .overlay(Circle().stroke(glow ? Color.pop : Color.ink, lineWidth: glow ? 4 : 3)))   // listening: no hint which one it is
                            .shadow(color: glow ? Color.sun : .clear, radius: 12)
                            .zIndex(1)
                        Image(f.image).resizable().scaledToFit().frame(width: 92.s, height: 92.s)
                    }
                    .scaleEffect(f.dying ? 1.5 : (glow ? 1.08 : 1))
                    .opacity(f.dying ? 0 : 1)
                    .rotationEffect(.degrees(f.shake ? 12 : 0))
                    .animation(.easeOut(duration: 0.35), value: f.dying)
                    .animation(.default.repeatCount(3, autoreverses: true).speed(5), value: f.shake)
                    .contentShape(Rectangle())
                    // react on touch-down: the minion keeps moving, so a normal button often missed the tap
                    .gesture(DragGesture(minimumDistance: 0).onChanged { _ in b.tap(f) })
                .position(x: size.width * f.x, y: top + (bottom - top) * f.y + (isTarget ? 0 : bob))
                if f.dying {
                    StarBurst().fill(Color.sun).frame(width: 110.s, height: 110.s)
                        .position(x: size.width * f.x, y: top + (bottom - top) * f.y)
                        .allowsHitTesting(false)
                }
            }
            if b.tonbiOn {
                Image("npc_tonbi").resizable().scaledToFit().frame(width: 110.s, height: 90.s)
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0).onChanged { _ in b.tapTonbi() })
                .position(x: size.width * b.tonbiX, y: size.height * 0.16 + sin(t * 3) * 14)
            }
            ForEach(b.pops) { p in
                Text(p.text).font(.display(20.s)).foregroundStyle(Color.popDeep)
                    .shadow(color: .white, radius: 0, x: 1, y: 1)
                    .position(x: size.width * p.x, y: top + (bottom - top) * p.y - 60.s)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .allowsHitTesting(false)
            }
            if b.phase == .word { wordCard(size) }
            if b.phase == .boss || b.phase == .bossIntro { boss(size) }
        }
    }

    /// the word as blanks that fill in as you tap
    private var blanks: some View {
        HStack(spacing: 6.s) {
            ForEach(Array(b.word.enumerated()), id: \.offset) { i, _ in
                let typed = Array(b.typed)
                Text(i < typed.count ? String(typed[i]) : "？")
                    .font(.custom(Fonts.rounded, size: 34.s)).foregroundStyle(i < typed.count ? Color.ink : Color.ink.opacity(0.3)).lineLimit(1).minimumScaleFactor(0.35)
                    .frame(width: 56.s, height: 56.s)
                    .background(Circle().fill(Color.white).overlay(Circle().stroke(Color.ink, lineWidth: 3)))
            }
        }
    }

    private var timer: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white)
                Capsule().fill(b.wordTime < 0.3 ? Color.danger : Color.sun).frame(width: g.size.width * max(0, b.wordTime))
            }
            .overlay(Capsule().stroke(Color.ink, lineWidth: 2))
        }
        .frame(width: 180.s, height: 12.s)
    }

    private func wordCard(_ size: CGSize) -> some View {
        VStack(spacing: 10.s) {
            PaperCard {
                VStack(spacing: 4.s) {
                    KJPicView(KJData.word(b.word)?.emoji ?? "❓", size: 90.s)
                    Text(KJData.word(b.word)?.meaning ?? "").font(.ui(18.s)).foregroundStyle(Color.ink)
                }
                .frame(width: 180.s)
            }
            .scaleEffect(b.bossHit ? 1.15 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.4), value: b.bossHit)
            .overlay {
                ForEach(b.dmgs) { d in
                    let age = max(0, Date().timeIntervalSince(d.born))
                    Text(d.text).font(.display(36.s)).foregroundStyle(Color.white)
                        .shadow(color: Color.popDeep, radius: 0, x: 3, y: 3)
                        .offset(x: d.dx.s, y: -60.s - CGFloat(age) * 100.s)
                        .opacity(age > 0.7 ? max(0, 1 - (age - 0.7) / 0.3) : 1)
                        .allowsHitTesting(false)
                }
            }
            blanks
            timer
        }
        .position(x: size.width / 2, y: size.height * 0.42)
    }

    private func boss(_ size: CGSize) -> some View {
        VStack(spacing: 8.s) {
            if b.phase == .boss { blanks }
            ZStack {
                if b.bossHit || b.finishing {
                    StarBurst().fill(Color.sun.opacity(0.9)).frame(width: b.finishing ? 320.s : 230.s, height: b.finishing ? 320.s : 230.s)
                        .rotationEffect(.degrees(t * 90))
                }
                Image(b.bossImage).resizable().scaledToFit().frame(width: 220.s, height: 220.s)
                    .brightness(b.bossHit ? 0.55 : 0)
                    .colorMultiply(b.bossHit ? Color(red: 1, green: 0.75, blue: 0.75) : .white)
                    .scaleEffect(b.finishing ? 0.05 : 1)
                    .rotationEffect(.degrees(b.finishing ? 900 : 0))
                    .opacity(b.finishing ? 0 : 1)
                    .animation(b.finishing ? .easeIn(duration: 1.0).delay(0.35) : .default, value: b.finishing)
                ForEach(b.dmgs) { d in
                    let age = max(0, Date().timeIntervalSince(d.born))
                    Text(d.text).font(.display(40.s)).foregroundStyle(Color.white)
                        .shadow(color: Color.popDeep, radius: 0, x: 3, y: 3)
                        .shadow(color: Color.ink, radius: 0, x: -2, y: -2)
                        .scaleEffect(age < 0.12 ? 1.6 - age * 5 : 1)
                        .offset(x: d.dx.s, y: -40.s - CGFloat(age) * 110.s)
                        .opacity(age > 0.7 ? max(0, 1 - (age - 0.7) / 0.3) : 1)
                        .allowsHitTesting(false)
                }
            }
                .scaleEffect(b.bossHit ? 0.85 : 1)
                .rotationEffect(.degrees(b.bossShake ? -8 : 0))
                .offset(x: stage.kind == .mid ? CGFloat(sin(t * 1.7)) * size.width * 0.22 : 0,
                        y: stage.kind == .mid ? -abs(CGFloat(sin(t * 3.4))) * 40.s : 0)
                .animation(.spring(response: 0.25, dampingFraction: 0.4), value: b.bossHit)
            if b.phase == .boss {
                timer
                HStack(spacing: 4.s) {
                    ForEach(0..<b.bossWords.count, id: \.self) { i in
                        // the boss's remaining power: tails for the fox, drops for the umbrella
                        KJPicView(stage.kind == .boss ? "🦊" : "💧", size: 16.1.s)
                            .opacity(i < b.bossWord ? 0.2 : 1)
                    }
                }
            }
        }
        .position(x: size.width / 2, y: size.height * 0.45)
    }

    private var prompt: some View {
        VStack(spacing: 6.s) {
            HStack(alignment: .bottom, spacing: 10.s) {
                Image(b.combo >= 5 ? "nk_nyan_joy" : "nk_nyan_proud").resizable().scaledToFit().frame(height: 74.s)
                VStack(spacing: 6.s) {
                    if b.ask == .read && b.phase == .waves {
                        if b.readTutorial {
                            // the first times: everything stops, and the buttons below are pointed out
                            VStack(spacing: 2.s) {
                                Text("ひかった もじの よみかたを えらぼう").font(.custom(Fonts.rounded, size: 15.s)).foregroundStyle(.white)
                                Text(KJ.t("A letter is glowing. Choose how it sounds below!", "有個字在發光，從下面選出它的讀音！", "빛나는 글자가 있어요. 아래에서 읽는 법을 골라요!"))
                                    .font(.ui(12.s, bold: false)).foregroundStyle(.white).multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 14.s).padding(.vertical, 8.s)
                            .background(RoundedRectangle(cornerRadius: 14.s).fill(Color.popDeep).overlay(RoundedRectangle(cornerRadius: 14.s).stroke(Color.ink, lineWidth: 2.5)))
                            Image(systemName: "arrowshape.down.fill").font(.system(size: 30.s, weight: .black)).foregroundStyle(Color.popDeep)
                                .offset(y: CGFloat(sin(t * 8) * 5))
                        } else if b.readHint {
                            Text(KJ.both("↓ Choose how it sounds", "↓ 選擇讀音", "↓ 읽는 법을 골라요"))
                                .font(.ui(14.s)).foregroundStyle(.white)
                                .padding(.horizontal, 10.s).padding(.vertical, 4.s)
                                .background(Capsule().fill(Color.popDeep))
                                .modifier(Bob())
                        }
                        HStack(spacing: 8.s) {
                            ForEach(b.readChoices, id: \.self) { r in
                                Button { b.read(r) } label: {
                                    Text(r).font(.display(r.count > 4 ? 19.s : 24.s)).foregroundStyle(Color.ink)
                                        .lineLimit(1).fixedSize()
                                        .padding(.horizontal, 10.s)
                                        .frame(minWidth: 62.s, minHeight: 52.s)
                                        .background(RoundedRectangle(cornerRadius: 14.s).fill(b.readTutorial ? Color.sun : Color.white)
                                            .overlay(RoundedRectangle(cornerRadius: 14.s).stroke(b.readTutorial ? Color.popDeep : Color.ink, lineWidth: 3)))
                                }
                                .buttonStyle(PressStyle(radius: 14.s, depth: 4))
                                .scaleEffect(b.readTutorial ? 1 + 0.06 * CGFloat(sin(t * 6)) : 1)
                                .opacity(b.locked ? 0.45 : 1)
                                .disabled(b.locked)
                            }
                        }
                        Text(KJ.both("How does the glowing one sound?", "發光的字怎麼唸？", "빛나는 글자는 어떻게 읽어요?"))
                            .font(.ui(12.s, bold: false)).foregroundStyle(Color.ink).multilineTextAlignment(.center)
                    } else {
                        Button { b.callOut() } label: {
                            HStack(spacing: 8.s) {
                                Image(systemName: "speaker.wave.3.fill").font(.system(size: 24.s, weight: .bold))
                                if b.hintVisible, let k = b.target?.kana {
                                    Text(KJData.romaji(k)).font(.display(24.s))
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
                }
                Image("sora_full").resizable().scaledToFit().frame(height: 80.s)
            }
            ProgressView(value: Double(min(b.hits, b.goal)), total: Double(b.goal)).tint(Color.pop)
                .frame(width: 200.s)
        }
        .padding(.horizontal, 14.s)
    }

    private var wordPad: some View {
        VStack(spacing: 8.s) {
            Button { b.callOut() } label: {
                HStack(spacing: 8.s) {
                    Image(systemName: "speaker.wave.3.fill").font(.system(size: 22.s, weight: .bold))
                    Text(KJ.duo("Listen", "聽", "듣기")).font(.ui(16.s))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20.s).padding(.vertical, 10.s)
                .background(Capsule().fill(Color.sky).overlay(Capsule().stroke(Color.ink, lineWidth: 3)))
            }
            .buttonStyle(PressStyle(radius: 30, depth: 4))
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(64.s), spacing: 8.s), count: 4), spacing: 8.s) {
                ForEach(b.pad, id: \.self) { k in
                    Button { b.padTap(k) } label: {
                        Text(k).font(.custom(Fonts.rounded, size: 34.s)).foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.35)
                            .frame(width: 62.s, height: 60.s)
                            .background(RoundedRectangle(cornerRadius: 14.s).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 14.s).stroke(Color.ink, lineWidth: 3)))
                    }
                    .buttonStyle(PressStyle(radius: 14.s, depth: 5))
                }
            }
            Text(KJ.both("Spell the word you hear!", "拼出聽到的單字！", "들리는 단어를 만들어요!"))
                .font(.ui(12.s, bold: false)).foregroundStyle(Color.ink)
        }
    }

    /// the big "とどめ！" over the last hit
    private func finishTitle(_ size: CGSize) -> some View {
        VStack(spacing: 0) {
            Text("とどめ！").font(.custom(Fonts.rounded, size: 64.s)).foregroundStyle(Color.white)
                .shadow(color: Color.popDeep, radius: 0, x: 4, y: 4)
                .shadow(color: Color.ink, radius: 0, x: -2, y: -2)
            Text("FINISH!").font(.display(26.s)).foregroundStyle(Color.sun)
                .shadow(color: Color.ink, radius: 0, x: 2, y: 2)
        }
        .rotationEffect(.degrees(-6))
        .transition(.scale(scale: 3).combined(with: .opacity))
        .position(x: size.width / 2, y: size.height * 0.3)
        .allowsHitTesting(false)
    }

    @ViewBuilder private var overlay: some View {
        switch b.phase {
        case .intro:
            banner(title: KJ.both("Yokai minions are here!", "妖怪的手下來了！", "요괴 부하들이 왔다!"),
                   sub: KJ.both("They hold the stolen letters. Listen, then tap the one that has it.",
                               "牠們拿著被偷走的文字。聽發音，點出拿著那個字的妖怪。",
                               "훔친 글자를 들고 있어요. 소리를 듣고 그 글자를 가진 요괴를 터치!"),
                   image: "nk_nyan_proud", button: "START") { b.start() }
        case .bossIntro:
            banner(title: stage.kind == .boss
                        ? KJ.both("The Nine-Tailed Fox appears!", "九尾狐出現了！", "구미호 등장!")
                        : KJ.both("The umbrella yokai appears!", "傘妖怪出現了！", "우산 요괴 등장!"),
                   sub: KJ.both("It ate whole words. Listen and tap the letters in order.",
                               "牠吃掉了整個單字。聽發音，依序點出假名。",
                               "단어를 통째로 먹었어요. 듣고 글자를 순서대로 터치!"),
                   image: b.bossImage, button: "GO!") { b.startBoss() }
        case .won:
            banner(title: KJ.both("You won!", "勝利！", "승리!"),
                   sub: String(repeating: "★", count: b.stars) + String(repeating: "☆", count: 3 - b.stars) + "   \(b.score)",
                   image: "nk_nyan_joy", button: KJ.both("Next", "下一步", "다음")) {
                KJMusic.play(); finished(b.stars, b.score, b.won)
            }
        case .lost:
            banner(title: KJ.both("The letters got eaten…", "文字被吃掉了……", "글자를 먹혀 버렸다…"),
                   sub: KJ.both("Try again!", "再試一次！", "다시 도전!"),
                   image: "nk_nyan_sad", button: KJ.both("Retry", "再來一次", "다시 하기")) { b.retry() }
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
