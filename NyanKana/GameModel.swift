import SwiftUI
import Combine
import QuartzCore
import UIKit
import SceneKit

/// One enemy on the field. Small Gobbles have one question; mid bosses and bosses have a queue.
struct Foe: Identifiable {
    enum Kind { case zako, bonus, mid, boss, rare, kidnap, event }
    let id = UUID()
    var kind: Kind
    var image: String
    var path: EnemyPath = .front
    var item: ItemKind?
    var question: Question
    var queue: [Question] = []
    var hpMax: Int = 1
    var hits = 0
    var elapsed: Double = 0
    var penalty: Double = 0
    /// wrong answers on the current question (3 = the enemy attacks, so tapping every button can't win)
    var misses = 0
    var limit: Double = 10
    var active = false
    var attacking = false
    /// rare colour variant (about 1 in 40 small enemies)
    var shiny = false
    /// Silence Castle: whose mid boss / shadow boss this is (nil = this area's own)
    var profile: BossProfile? = nil
    var shadow = false
    /// throws something before its question (a quick word quiz: miss once and it hits)
    var shooter = false
    /// while the quick quiz is up, the real question waits here
    var held: Question? = nil
    /// hits count when the last throw came (one throw per question)
    var shotAt = -1

    var meter: Double { limit > 0 ? min(1, (elapsed + penalty) / limit) : 0 }
    /// enemies with a heart queue (several questions)
    var isBig: Bool { kind == .mid || kind == .boss || kind == .event || kind == .kidnap }
    /// the real bosses (arena, speech, big entrance)
    var isBoss: Bool { kind == .mid || kind == .boss }
    var zukanID: String {
        shiny ? image + "*" : image
    }
}

/// Drives one stage: encounters, timers, answers, items, story and result.
@MainActor
final class GameModel: ObservableObject {
    enum Phase: Equatable { case story(StoryKind), playing, result }
    enum Flash { case damage, heal }

    let ref: StageRef
    @Published private(set) var world: GameWorld
    @Published var phase: Phase = .story(.intro)

    @Published private(set) var foes: [Foe] = []
    @Published private(set) var targetID: UUID?
    @Published private(set) var lives: Int
    @Published private(set) var score = 0
    @Published private(set) var combo = 0
    /// the 3 item slots: a used item leaves its slot empty (the others do not move)
    @Published private(set) var items: [ItemKind?] = [nil, nil, nil]
    @Published var paused = false { didSet { world.scene.isPaused = paused } }
    @Published private(set) var forkChoice = false
    @Published private(set) var reveal: String?
    @Published private(set) var talk: String?
    @Published private(set) var bossLine: StoryLine?
    @Published private(set) var flash: Flash?
    @Published private(set) var timeStopLeft: Double = 0
    /// FEVER: every 8 combo -> 10 s of double score and slow enemies
    @Published private(set) var feverLeft: Double = 0
    /// white flash while switching between the street and a boss arena
    @Published private(set) var arenaFlash = false
    /// event card over the street (rare runaway, kidnapped person, possessed townsperson)
    @Published private(set) var event: EventScene?
    /// the kidnapped person, kept as a small badge at the top while you fight (the full card would cover the foes)
    @Published private(set) var helpChip: String?
    /// lightning flash strength when a big boss falls
    @Published private(set) var thunder: Double = 0
    /// screen effect of the last enemy attack
    @Published private(set) var hitFX: AttackKind?
    /// something thrown at you (bomb, knife, rock...): flies at the screen while the quick quiz runs
    struct Missile: Equatable {
        enum State: Equatable { case flying, hit, deflected }
        let foe: UUID
        let image: String
        let fromX: Double
        let spin: Bool
        var state: State = .flying
        /// how far it had come when it was knocked away (0...1)
        var at: Double = 0
    }
    @Published private(set) var missile: Missile?
    /// 0...1 — how close the thrown thing is (the quick quiz timer)
    var missileProgress: Double {
        guard let mm = missile else { return 0 }
        return foes.first { $0.id == mm.foe }?.meter ?? 1
    }
    private static let missiles = ["proj_bomb", "proj_knife", "proj_rock", "proj_shuriken", "proj_spike", "proj_wrench"]
    private var lastAttack: [UUID: AttackKind] = [:]
    private var eventToken = 0
    /// story lines are picked once per stage (the short scenes are random)
    private var storyCache: [Bool: [StoryLine]] = [:]
    func storyLines(_ k: StoryKind) -> [StoryLine] {
        if KanaRescue.active { return [] }   // にゃんカナ tells its own story around the battle
        if let c = storyCache[k == .intro] { return c }
        let l = StoryBank.lines(ref, k)
        storyCache[k == .intro] = l
        return l
    }
    private var captive = "capt_0"
    /// which skill this answer trains, for the self-analysis in きろく
    private var answerSkill: String {
        switch answerMode { case .voice: "speaking"; case .keyboard, .handwriting: "writing"; case .choice: "grammar" }
    }
    /// a voice for the kidnapped townsperson (each picture gets its own pitch)
    private var captiveVoice: Speaker.Voice {
        let n = Int(captive.split(separator: "_").last ?? "0") ?? 0
        return .init(pitch: [1.0, 1.25, 0.85, 1.4, 0.95, 1.15][n % 6], rate: 0.95)
    }
    private var possessedIndex = 0
    @Published private(set) var flyingItem: ItemKind?
    @Published private(set) var cleared = false
    @Published private(set) var progressText = ""

    // answer panel state
    @Published private(set) var choices: [String] = []
    /// easy: wrong buttons that were tapped. They stay in place (invisible) so the other buttons never move.
    @Published private(set) var gone: Set<String> = []
    @Published private(set) var tiles: [String] = []
    @Published private(set) var picked: [Int] = []
    @Published var typed = ""
    @Published private(set) var wrongToken = 0
    @Published var answerMode: AnswerMode {
        didSet {
            SpeechCoach.keepRecordSession = answerMode == .voice
            if answerMode != .choice && oldValue == .choice && phase == .playing { say(T("スコア|×1.5！", "점수 ×1.5!", "分數 ×1.5！")) }
        }
    }
    /// HARD + voice: blank questions are answered by reading the whole sentence aloud
    var voiceFullSentence: Bool { answerMode == .voice && ref.difficulty == .hard && target?.question.kind == .blank }

    // result
    private(set) var maxCombo = 0
    private(set) var correctCount = 0
    private(set) var wrongCount = 0
    private(set) var missed: [Question] = []
    private(set) var rank = "C"
    private(set) var stars = 1
    private(set) var newBest = false

    var maxLives: Int { ref.difficulty.lives }
    var target: Foe? { foes.first { $0.id == targetID } }

    private var plan: [Encounter] = []
    private var idx = -1
    private var run = 0                 // bumps on restart; stale delayed calls check it
    private let ticker = FrameTicker()
    private var talkToken = 0
    private let app = AppState.shared
    private var dev: DevSettings { app.dev }
    private var fast: Bool { dev.enabled && dev.fast }
    private var autoOK: Bool { dev.enabled && dev.autoCorrect }
    private let walkStep: Float = 14

    init(ref: StageRef) {
        self.ref = ref
        world = GameWorld(area: ref.area, stage: ref.index)
        lives = ref.difficulty.lives
        answerMode = AppState.shared.settings.answerMode
        items = GameModel.slots(AppState.shared.progress.items)
        ticker.onTick = { [weak self] dt in self?.tick(dt) }
        if storyLines(.intro).isEmpty { phase = .playing }
    }

    // MARK: - lifecycle

    /// the game on screen now. Going to the next stage shows the new game before the old one goes away,
    /// so the old one must not cut off the new game's first line when it disappears.
    static weak var onScreen: GameModel?
    func appear() {
        GameModel.onScreen = self
        ticker.start()
        SpeechCoach.keepRecordSession = answerMode == .voice
        if phase == .playing && idx < 0 { begin() }
    }
    func disappear() {
        ticker.stop(); run += 1; itemsInFlight = 0
        AudioManager.shared.fadeOutSE()   // the clear fanfare must not ring on into the next stage
        guard GameModel.onScreen === self || GameModel.onScreen == nil else { return }   // a newer game already took over
        Speaker.shared.stop(); SpeechCoach.shared.cancel(); SpeechCoach.keepRecordSession = false
    }

    func storyDone(_ kind: StoryKind) {
        Speaker.shared.stop()
        if kind == .intro { phase = .playing; begin() } else { phase = .result }
    }

    func restart() {
        run += 1; itemsInFlight = 0
        AudioManager.shared.fadeOutSE()   // the clear fanfare must not keep ringing into the new run
        world = GameWorld(area: ref.area, stage: ref.index)
        foes = []; targetID = nil; lives = maxLives; score = 0; combo = 0; maxCombo = 0
        correctCount = 0; wrongCount = 0; missed = []; reveal = nil; talk = nil; bossLine = nil; feverLeft = 0
        forkChoice = false; timeStopLeft = 0; cleared = false; paused = false; idx = -1; missile = nil
        phase = .playing
        begin()
    }

    private func begin() {
        zakoQueue = []
        askedWords = []
        plan = StagePlanner(ref: ref).build()
        planKeys = Set(plan.flatMap { e -> [Question] in
            switch e {
            case let .zako(q, _, _, _), let .rare(q): return [q]
            case let .pack(qs, _, _), let .mid(qs), let .boss(qs), let .kidnap(qs), let .possessed(qs), let .guest(_, qs, _): return qs
            default: return []
            }
        }.map(\.dedupeKey))
        idx = -1
        // the junction is built at the start so it never pops in
        if let f = plan.firstIndex(where: { if case .fork = $0 { return true }; return false }) {
            world.prepareFork(distance: walkStep * Float(f + 1) + 10)
        }
        updateProgress()
        // the stage's scene name ("ST.3  Cherry-tree avenue")
        if !world.look.title.isEmpty {
            let title = "ST.\(ref.index)  " + jp(world.look.title)
            after(0.5) { self.say(title, long: true) }
        }
        let stageKind = StagePlanner(ref: ref).kind
        AudioManager.shared.playBGM(KanaRescue.active ? .track("mg_zako") : .area(ref.area))       // the boss theme starts with the boss's entrance
        after(0.5) { self.walkThenNext() }
    }

    /// delayed call that waits while paused and is dropped after a restart
    private func after(_ s: Double, scaled: Bool = true, _ f: @escaping @MainActor () -> Void) {
        let token = run
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(s * (scaled && self.fast ? 0.45 : 1) * 1_000_000_000))
            while self.paused { try? await Task.sleep(nanoseconds: 100_000_000) }
            guard token == self.run else { return }
            f()
        }
    }

    // MARK: - encounters

    private func walkThenNext() {
        guard phase == .playing, lives > 0 else { return }
        let d = world.walk(walkStep, duration: fast ? 0.8 : 1.9)
        after(d, scaled: false) { self.nextEncounter() }
    }

    private func nextEncounter() {
        guard phase == .playing, lives > 0 else { return }
        idx += 1
        updateProgress()
        guard idx < plan.count else { stageClear(); return }
        let pools = QuestionBank.pools(for: ref.area)
        helpChip = nil
        switch plan[idx] {
        case let .zako(q, img, path, item):
            var f = Foe(kind: .zako, image: gob(img), path: path, item: item, question: wordOr(q), shiny: rollShiny())
            f.shooter = rollShooter()
            spawn([f])
        case let .pack(qs, imgs, item):
            let shooterAt = rollShooter() ? Int.random(in: 0..<max(1, qs.count)) : -1
            spawn(qs.enumerated().map { i, q in
                var f = Foe(kind: .zako, image: gob(imgs[i % imgs.count]), path: .front, item: i == 0 ? item : nil, question: wordOr(q), shiny: rollShiny())
                f.shooter = i == shooterAt
                return f
            })
        case .fork:
            forkChoice = true
            say(L("game.which"), long: true)
        case .bossCall:
            bossEntrance()
        case .bonus:
            let q = pools.single.shuffled().first(where: { !planKeys.contains($0.dedupeKey) }) ?? pools.single.randomElement() ?? QuestionBank.lv1.single[0]
            spawn([Foe(kind: .bonus, image: gob(Int.random(in: 0..<16)), path: .sky, item: Bool.random() ? ItemKind.allCases.randomElement() : nil, question: q)])
            say(L("game.bonus"))
        case let .mid(qs):
            guard !qs.isEmpty else { break }
            spawn([Foe(kind: .mid, image: ref.area.mid(ref.index).image, question: qs[0], queue: Array(qs.dropFirst()), hpMax: qs.count)])
        case let .boss(qs):
            guard !qs.isEmpty else { break }
            spawn([Foe(kind: .boss, image: ref.area.boss.image, question: qs[0], queue: Array(qs.dropFirst()), hpMax: qs.count)])
        case let .guest(p, qs, shadow):
            guard !qs.isEmpty else { break }
            var f = Foe(kind: .mid, image: p.image, question: qs[0], queue: Array(qs.dropFirst()), hpMax: qs.count)
            f.profile = p; f.shadow = shadow
            if shadow { say(T("ボス|ラッシュ！", "보스 러시!", "首領連戰！"), long: true) }
            spawn([f])
        case let .rare(q):
            let k = GameEvents.rollRare()
            AudioManager.shared.se(.sparkle, rate: 1.3, volume: 0.9)
            AudioManager.shared.se(.eyeShine, volume: 0.8)
            showEvent(.init(image: GameEvents.rares[k], line: GameEvents.rareFound(k), tone: .rare), for: 2.2)
            spawn([Foe(kind: .rare, image: GameEvents.rares[k], path: .front, item: Bool.random() ? ItemKind.allCases.randomElement() : nil, question: q)])
        case let .kidnap(qs):
            captive = GameEvents.captives.randomElement()!
            AudioManager.shared.se(.bossAppear, rate: 1.25, volume: 0.6)
            let helpLine = GameEvents.help.randomElement()!
            // the cry for help is shown briefly, then shrinks to a small badge at the top
            showEvent(.init(image: captive, line: helpLine, tone: .help), for: 2.8)
            let c = captive
            after(2.9, scaled: false) { if self.foes.contains(where: { $0.kind == .kidnap }) { withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { self.helpChip = c } } }
            Speaker.shared.say(helpLine.en, voice: captiveVoice)
            // English UI shows no subtitles, but the rule still has to be told
            say(L10n.current == .en ? "Beat it before it escapes! Save them to heal!" : GameEvents.kidnapRule.sub, long: true)
            spawn([Foe(kind: .kidnap, image: GameEvents.kidnappers.randomElement()!, question: qs[0], queue: Array(qs.dropFirst()), hpMax: qs.count)])
        case let .possessed(qs):
            possessedIndex = Int.random(in: 0..<GameEvents.possessed.count)
            let p = GameEvents.possessed[possessedIndex]
            // a friendly chat first... then the townsperson turns into a monster
            showEvent(.init(image: p.normal, line: p.talk[0], tone: .talk), for: 60)
            Speaker.shared.say(p.talk[0].en)
            after(3.0) {
                self.showEvent(.init(image: p.normal, line: p.talk[1], tone: .talk), for: 60)
                Speaker.shared.say(p.talk[1].en)
            }
            after(6.0) {
                self.say(GameEvents.possessedWarn.sub)
                AudioManager.shared.se(.bossAppear, volume: 0.8)
                self.world.shake(0.4)
                self.flashArena {
                    self.showEvent(.init(image: p.monster, line: p.turn, tone: .evil), for: 2.6)
                    Speaker.shared.say(p.turn.en, voice: .init(pitch: 0.7, rate: 0.9))
                    self.spawn([Foe(kind: .event, image: p.monster, question: qs[0], queue: Array(qs.dropFirst()), hpMax: qs.count)])
                }
            }
        }
    }

    /// Zako look: cute Gobbles first, creepier-cute ones as the chapters go on.
    /// The stage's own enemies come first, then the area's six, then the classic Gobbles — no repeats within a stage.
    private var zakoQueue: [String] = []
    private func refillZako() {
        // にゃんカナ: the chapter's つくもがみ / ごとうち (EnemyTable); the old stage-only enemies are not used
        let own: [String] = []
        let area = EnemyTable.monsters(ref.area).shuffled()
        var q: [String] = []
        // own enemies early: 1st, 2nd (this difficulty's own) and 4th appearance
        var a = area
        if own.count > 0 { q.append(own[0]) }
        if !a.isEmpty { q.append(a.removeFirst()) }
        if own.count > 1 { q.append(own[1]) }
        q += a
        // classic Gobbles (the zukan's ゴブルズ page) join every stage: one or two, unseen ones first
        let gobs = gobblePool.filter { (app.progress.zukanSeen[$0] ?? 0) == 0 }.shuffled() + gobblePool.shuffled()
        let n = Int.random(in: 0..<3) == 0 ? 2 : 1
        var picked: [String] = []
        for g in gobs where !picked.contains(g) && picked.count < n { picked.append(g) }
        for (k, g) in picked.enumerated() { q.insert(g, at: min(q.count, 2 + k * 2)) }
        zakoQueue = q
    }

    /// Gobbles that fit this area's mood (cute ones first, creepier-cute ones later)
    private var gobblePool: [String] { EnemyTable.moji(ref.area) }
    private func rollShiny() -> Bool { Int.random(in: 0..<40) == 0 }
    /// small enemies that throw something first: none on EASY, some on NORMAL (from area 2), more on HARD
    private func rollShooter() -> Bool {
        switch ref.difficulty {
        case .easy: return false
        case .normal: return ref.area != .lv1 && Double.random(in: 0..<1) < 0.15
        case .hard: return Double.random(in: 0..<1) < (ref.area == .lv1 ? 0.15 : 0.25)
        }
    }
    /// the area boss throws every few questions (mid bosses and the boss rush don't throw)
    private func throwsNow(_ f: Foe) -> Bool {
        guard ref.difficulty != .easy, f.shotAt != f.hits else { return false }
        switch f.kind {
        case .zako: return f.shooter
        case .boss:
            let every = ref.difficulty == .hard ? 2 : 3
            return f.hits > 0 && f.hits % every == 0
        default: return false
        }
    }
    /// the quick quiz: a word of this level (meaning -> English)
    private func quickQuestion() -> Question {
        if let s = KanaRescue.session { return (s.pools.phrase + s.pools.single).randomElement() ?? QuestionBank.lv1.single[0] }
        let lv = min(6, ref.area.rawValue)
        let lo = max(1, lv - 1)
        if let w = Vocab.all.filter({ $0.level >= lo && $0.level <= lv && !askedWords.contains($0.id) }).randomElement() {
            askedWords.insert(w.id)
            return Vocab.gameQuestion(w)
        }
        return QuestionBank.pools(for: ref.area).single.randomElement() ?? QuestionBank.lv1.single[0]
    }

    /// About a quarter of the small enemies ask a word you are learning (or a word of this level).
    private var askedWords = Set<String>()
    private var planKeys = Set<String>()
    private func wordOr(_ q: Question) -> Question {
        if KanaRescue.active { return q }
        guard Double.random(in: 0..<1) < ref.difficulty.vocabRate else { return q }
        let lv = min(6, ref.area.rawValue)
        // words near this area's grade only (no 中1 words like "April" in the last area on HARD):
        // easy: two grades below up to this grade / normal: one below to one above / hard: this grade up to TOEIC
        let lo = ref.difficulty == .easy ? max(1, lv - 2) : ref.difficulty == .normal ? max(1, lv - 1) : max(1, lv)
        let cap = ref.difficulty == .easy ? lv : ref.difficulty == .normal ? lv + 1 : 7
        let learning = app.vocab.box.filter { $0.value < 4 }.keys.compactMap { Vocab.byID[$0] }.filter { $0.level >= lo && $0.level <= cap && !askedWords.contains($0.id) }
        let w = learning.randomElement() ?? Vocab.all.filter { $0.level >= lo && $0.level <= min(cap, 6) && !askedWords.contains($0.id) }.randomElement()
        guard let w else { return q }
        askedWords.insert(w.id)   // the same word never comes back in this stage
        return Vocab.gameQuestion(w)
    }

    private func gob(_ i: Int) -> String {
        if zakoQueue.isEmpty { refillZako() }
        if !zakoQueue.isEmpty { return zakoQueue.removeFirst() }
        let g = String(format: "gob_%02d", i % 16), a = "kimo_a\(i % 8)", b = "kimo_b\(i % 8)"
        switch ref.area {
        case .lv1: return g
        case .lv2: return i % 2 == 0 ? g : b
        case .lv3: return b
        case .lv4: return i % 2 == 0 ? b : a
        default: return i % 3 == 0 ? b : a
        }
    }

    private func spawn(_ list: [Foe]) {
        foes = list
        targetID = nil
        for (i, f) in list.enumerated() {
            world.spawn(id: f.id, image: f.image, kind: f.kind, path: f.path, index: i, count: list.count, item: f.item, fast: fast, shiny: f.shiny,
                        thrower: f.kind == .zako && f.shooter && ref.difficulty != .easy)
            if f.shiny { AudioManager.shared.se(.eyeShine); say(T("色違いだ！", "색이 다르다!", "異色版！")) }
            app.progress.zukanSeen[f.zukanID, default: 0] += 1
        }
        let big = list.contains { $0.isBoss }
        if big, let b = list.first(where: { $0.isBoss }) {
            let key = b.profile?.key ?? (b.kind == .boss ? ref.area.boss.key : ref.area.mid(ref.index).key)
            // the boss rush stays in the castle hall; a guest mid boss brings its own place
            if b.shadow { flashArena { self.world.showArena("arena_\(self.ref.area.boss.key)") } }
            else { flashArena { self.world.showArena("arena_\(key)") } }
            if b.shadow, let id = list.first?.id { world.shade(id) }
        }
        if big {
            AudioManager.shared.se(.bossAppear, volume: 0.8)
            world.shake(0.2)
            after(2.0) { if let b = self.foes.first { self.bossSays(b, .intro) } }
        }
        // like the web version: the moment the enemy appears, the sound plays and the question is up
        // (small enemies keep approaching while you answer; bosses get a short entrance first)
        let start = {
            for f in self.foes { self.begin(f.id) }
            if let first = self.foes.first(where: { !$0.attacking }) { self.select(first.id, sound: false) }
        }
        if big {
            after(2.0) { AudioManager.shared.se(.bossLand); self.world.shake(0.45); start() }  // boss's own landing sound
        } else if list.contains(where: { $0.kind == .event || $0.kind == .kidnap }) {
            AudioManager.shared.se(.hitBig, volume: 0.8)
            world.shake(0.25)
            after(0.9) { start() }
        } else {
            AudioManager.shared.se(.spawn)
            start()
        }
    }

    private func begin(_ id: UUID) {
        guard let i = foes.firstIndex(where: { $0.id == id }) else { return }
        if foes[i].held == nil, throwsNow(foes[i]) {
            foes[i].shotAt = foes[i].hits
            foes[i].held = foes[i].question
            foes[i].question = quickQuestion()
            world.charge(id, true)
            let img = Self.missiles.randomElement()!
            let lane = foes.count > 1 ? (Double(i) - Double(foes.count - 1) / 2) * 0.2 : 0
            missile = Missile(foe: id, image: img, fromX: 0.5 + lane, spin: img != "proj_bomb" && img != "proj_rock")
            AudioManager.shared.se(.bossAppear, rate: 1.6, volume: 0.5)
            world.shake(0.12)
            say(T("飛び道具だ！|早押しで|はね返せ！", "날아온다! 빨리 답해서 튕겨내!", "飛行道具來了！快搶答彈回去！"), long: true)
        }
        foes[i].elapsed = foes[i].held != nil && foes[i].kind == .zako && foes[i].hits == 0 ? -0.6 : 0
        foes[i].penalty = 0
        foes[i].limit = limit(for: foes[i])
        foes[i].active = true
        if id == targetID { prepareAnswer() }
    }

    private func limit(for f: Foe) -> Double {
        let q = f.question
        if f.held != nil {
            // quick quiz: short and the same for every enemy (a little longer for the final boss)
            var t = 4.2
            if answerMode == .keyboard || answerMode == .handwriting { t += 3 }
            if answerMode == .voice { t += 2 }
            if ref.area == .graduation && f.kind == .boss { t += 1 }
            return t * ref.difficulty.timeScale
        }
        let kb = answerMode == .keyboard && q.kind != .sentence
        // easy: the timer does not get shorter as the stage goes on
        let shrink = ref.difficulty == .easy ? 0 : Double(max(0, idx)) * 0.3
        var base: Double = f.isBig ? (q.kind == .order ? 16 : 11) : max(6.5, 9.5 - shrink)
        if kb && q.kind != .order { base += 3 }
        if answerMode == .voice { base += 2 }   // time to speak
        switch q.kind {
        case .sentence: base += 6
        case .order: base += f.isBig ? 0 : Double(q.words.count) * 2.2 - 2
        case .blank: base += Double(q.answerLength - 1) * 2.6 + (kb ? Double(q.a.count) * 0.25 : 0)
        }
        if foes.count > 1 { base *= 1.3 }
        if f.kind == .bonus { base *= 0.8 }
        if f.kind == .kidnap { base *= 0.8 }
        // the rare runaway: answer FAST
        if f.kind == .rare { return (kb ? 6.5 : 4.2) * ref.difficulty.timeScale }
        if !f.isBig { base += 1.2 }      // the question is up while the enemy is still walking in
        return base * ref.difficulty.timeScale
    }

    // MARK: - targeting

    func tapFoe(_ id: UUID) { select(id, sound: true) }

    /// Keyboard: Tab / Shift+Tab moves to the next / previous enemy.
    func cycleTarget(_ step: Int = 1) {
        let list = foes.filter { $0.active && !$0.attacking }
        guard list.count > 1 else { return }
        let i = list.firstIndex { $0.id == targetID } ?? -1
        let n = ((i + step) % list.count + list.count) % list.count
        select(list[n].id, sound: true)
    }

    /// Keyboard: ⌘1 / ⌘2 / ⌘3 uses the item in that slot.
    func useSlot(_ i: Int) { if i < items.count, items[i] != nil { use(slot: i) } }

    func select(_ id: UUID, sound: Bool) {
        guard phase == .playing, let f = foes.first(where: { $0.id == id }), !f.attacking else { return }
        if sound && id != targetID { AudioManager.shared.se(.tap, rate: 1.3, volume: 0.6) }
        targetID = id
        reveal = nil
        if f.active { prepareAnswer() }
    }

    private func prepareAnswer() {
        guard let q = target?.question else { return }
        gone = []
        let n = ref.difficulty.choiceCount
        if q.choices.count > n, q.choices.contains(q.a) {
            choices = ([q.a] + q.choices.filter { $0 != q.a }.shuffled().prefix(n - 1)).shuffled()
        } else {
            choices = q.choices.shuffled()
        }
        var t = q.words.shuffled()
        if t.count > 1 { var n = 0; while t == q.words && n < 8 { t.shuffle(); n += 1 } }
        tiles = t
        picked = []
        typed = ""
    }

    // MARK: - answering

    func choose(_ s: String) { submit(s) }

    func pickTile(_ i: Int) {
        guard let q = target?.question, q.kind == .order, !picked.contains(i) else { return }
        AudioManager.shared.se(.tap, rate: 1.5, volume: 0.5)
        picked.append(i)
        if picked.count == tiles.count {
            let ok = autoOK || picked.map { tiles[$0] } == q.words
            if ok { resolve(correct: true) } else {
                resolve(correct: false)
                after(0.35) { self.picked = [] }
            }
        }
    }

    func unpick(_ pos: Int) {
        guard pos < picked.count else { return }
        picked.remove(at: pos)
    }

    /// Voice mode: pick the choice that was said (whole words), or compare the whole sentence.
    func submitVoice(_ heard: String) {
        guard let q = target?.question, !heard.isEmpty else { return }
        // the mic did not catch it (hardly any of the words came through): say it again, no penalty
        if q.kind == .order || voiceFullSentence {
            // the mic did not catch it (hardly anything came through): say it again, no penalty
            if Self.overlap(q.full, heard) < 0.4 { voiceRetry(); return }
            // the whole sentence must be said: most of it, in order, including the answer
            let answerSaid = Self.norm(heard).contains(Self.norm(q.a)) || (q.kana.map { Self.norm(heard).contains(Self.norm($0)) } ?? false)
            if q.kind == .order { submit(Self.overlap(q.full, heard) >= 0.8 ? q.full : heard); return }
            submit(answerSaid && Self.overlap(q.full, heard) >= 0.8 ? q.a : heard)
            return
        }
        let said = choices.filter { c in !gone.contains(c) && (Self.norm(heard).contains(Self.norm(c)) || (c == q.a && q.kana.map { Self.norm(heard).contains(Self.norm($0)) } == true)) }.sorted { $0.count > $1.count }
        if let c = said.first(where: { Self.norm($0) == Self.norm(q.a) }) ?? said.first { submit(c) }
        else { voiceRetry() }      // none of the choices was heard: not a wrong answer, just say it again
    }

    /// Voice mode: what was heard is not an answer at all (noise, or the mic cut it off).
    private func voiceRetry() {
        AudioManager.shared.se(.boyon, volume: 0.6)
        say(T("聞き取れなかった！|もう一度|言ってね", "잘 안 들렸어! 다시 말해 줘", "沒聽清楚！再說一次"))
    }

    func submitTyped() {
        guard !typed.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        submit(typed)
    }

    private func submit(_ answer: String) {
        guard let q = target?.question else { return }
        let want = q.kind == .order ? q.full : q.a
        let got = Self.norm(answer)
        let ok = autoOK || got == Self.norm(want) || (q.kind != .order && q.kana.map { got == Self.norm($0) } == true)
        // easy: a wrong button disappears, so beginners can still find the answer and learn it
        if !ok, ref.difficulty == .easy, choices.count - gone.count > 2, choices.contains(answer) { gone.insert(answer) }
        resolve(correct: ok)
    }

    /// about how long the recorded voice takes to read a sentence (so the next voice does not cut it off)
    static func readTime(_ s: String) -> Double {
        // Japanese: about 8 characters a second
        return min(4.0, 0.7 + Double(s.count) * 0.12)
    }

    /// letters and digits only, no spaces, katakana turned into hiragana
    static func norm(_ s: String) -> String {
        let t = s.lowercased()
        let kana = t.applyingTransform(.hiraganaToKatakana, reverse: true) ?? t
        let kept = kana.unicodeScalars.filter { (CharacterSet.letters.contains($0) || CharacterSet.decimalDigits.contains($0) || $0 == "ー") }
        return String(String.UnicodeScalarView(kept))
    }
    /// how much of `want` (in order) is in `heard`: 0...1 (Japanese has no spaces, so it goes by characters)
    static func overlap(_ want: String, _ heard: String) -> Double {
        let w = Array(norm(want)), h = Array(norm(heard))
        guard !w.isEmpty, !h.isEmpty else { return 0 }
        var dp = Array(repeating: 0, count: h.count + 1)
        for a in w {
            var prev = 0
            for j in 1...h.count { let cur = dp[j]; dp[j] = a == h[j - 1] ? prev + 1 : max(dp[j], dp[j - 1]); prev = cur }
        }
        return Double(dp[h.count]) / Double(w.count)
    }

    // developer buttons
    func devCorrect() { resolve(correct: true) }
    func devWrong() { resolve(correct: false) }
    func devTimeout() {
        guard let id = targetID, let i = foes.firstIndex(where: { $0.id == id }), foes[i].active, !foes[i].attacking else { return }
        timeout(id)
    }

    private func resolve(correct: Bool) {
        guard phase == .playing, let id = targetID, let i = foes.firstIndex(where: { $0.id == id }), foes[i].active, !foes[i].attacking else { return }
        if correct {
            foes[i].misses = 0          // the miss count is per enemy (and per boss question): never carried over
            if foes[i].held != nil { deflect(i); return }
            let f = foes[i]
            if f.question.point == "vocab" { app.vocab.answer(f.question.a.lowercased(), correct: true); app.vocab.gameHits += 1 }
            app.study.track(f.question, skill: answerSkill, correct: true)
            combo += 1; maxCombo = max(maxCombo, combo); correctCount += 1
            let gain = (100 + (1 - f.meter) * 60) * ref.difficulty.scoreScale * (1 + Double(min(combo, 10)) * 0.1) * (feverLeft > 0 ? 2 : 1)
                * (answerMode == .choice ? 1 : 1.5)   // typing, writing or speaking the answer is worth more
            if combo % 8 == 0 { startFever() }
            score += Int(gain)
            AudioManager.shared.se(.shoot)
            let c = combo
            after(0.2, scaled: false) { GameModel.hitSound(combo: c, big: f.isBig) }
            world.shoot(at: id)
            Speaker.shared.say(f.question.full, gender: AppState.shared.settings.gameGender)
            if combo >= 3 { say("\(combo) COMBO!") } else if Int.random(in: 0..<4) == 0 { say(GameTalk.praise.randomElement()!) }
            defeatOrNext(id, scored: true)
        } else {
            combo = 0; wrongCount += 1
            if foes[i].question.point == "vocab" { app.vocab.answer(foes[i].question.a.lowercased(), correct: false) }
            app.study.track(foes[i].question, skill: answerSkill, correct: false)
            app.study.recordMiss(foes[i].question)
            AudioManager.shared.se(.wrong, volume: 0.8)
            wrongToken += 1
            // time is stopped: the enemies can't move, so a mistake can't hurt you either (try again)
            if timeStopLeft > 0 {
                say(T("ちがうよ！|時間が|止まってるうちに|もう一度！", "틀렸어! 시간이 멈춘 동안 다시!", "不對！趁時間停止再試一次！"))
                return
            }
            foes[i].penalty += foes[i].limit * ref.difficulty.wrongPenalty
            foes[i].misses += 1
            say(GameTalk.miss.randomElement()!)
            // too many misses and the enemy strikes at once (even if time is left):
            // boss and mid boss 1 miss, everyone else 2; a thrown thing hits after 1 miss; the rare runaway flees after 1 miss
            let limit = foes[i].held != nil || foes[i].kind == .boss || foes[i].kind == .mid || foes[i].kind == .rare ? 1 : 2
            if foes[i].meter >= 1 || foes[i].misses >= limit { foes[i].misses = 0; timeout(id) }
        }
    }

    /// Correct answer (or bomb): small enemies are rescued, bosses lose one heart.
    private func defeatOrNext(_ id: UUID, scored: Bool) {
        guard let i = foes.firstIndex(where: { $0.id == id }) else { return }
        if let h = foes[i].held { foes[i].question = h; foes[i].held = nil; world.charge(id, false); missile = nil }
        var f = foes[i]
        if f.isBig {
            f.hits += 1
            foes[i].hits = f.hits
            foes[i].active = false
            world.restore(1)
            if f.queue.isEmpty {
                // boss defeated
                foes.remove(at: i)
                targetID = nil
                app.progress.zukanSaved[f.zukanID, default: 0] += 1
                if f.kind == .kidnap {
                    // the kidnapped person is free: they heal you
                    helpChip = nil
                    // the correct answer is being read out: wait for it before the person speaks
                    let talkWait = GameModel.readTime(f.question.full)
                    after(0.3) {
                        AudioManager.shared.se(.rescue)
                        self.world.rescue(id, big: false)
                        self.world.restore(3)
                        let thanks = GameEvents.thanks.randomElement()!
                        self.showEvent(.init(image: self.captive, line: thanks, tone: .thanks), for: 2.6 + talkWait)
                        self.after(talkWait) { Speaker.shared.say(thanks.en, voice: self.captiveVoice) }
                        if self.lives < self.maxLives {
                            self.lives += 1
                            AudioManager.shared.se(.heal)
                            self.flashOnce(.heal)
                        } else {
                            self.score += 1000
                            AudioManager.shared.se(.levelUp, volume: 0.8)
                        }
                    }
                    after(2.9 + talkWait) { self.walkThenNext() }
                    return
                }
                if f.kind == .event {
                    let p = GameEvents.possessed[possessedIndex]
                    after(0.4) {
                        AudioManager.shared.se(.bossDefeat)
                        // a puff of smoke (smaller than a boss's) hides the change back to a person
                        self.world.rescue(id, big: true, freed: p.normal, puff: true)
                        self.world.restore(5)
                    }
                    after(1.4) {
                        self.showEvent(.init(image: p.normal, line: p.freed, tone: .thanks), for: 2.8)
                        Speaker.shared.say(p.freed.en)
                        if Bool.random(), let k = ItemKind.allCases.randomElement() { self.gain(k) }
                    }
                    after(4.4) { self.walkThenNext() }
                    return
                }
                after(0.4) {
                    if f.kind == .boss { self.thunderStrike() } else { AudioManager.shared.se(.bossDefeat) }
                    // the boss turns into its true form inside the smoke of the explosion (2 s later)
                    self.world.rescue(id, big: true, freed: f.kind == .boss ? self.ref.area.boss.freeImage : nil, reveal: f.kind == .boss ? 2.0 : 0)
                    self.world.restore(8)
                }
                let wait: Double = f.kind == .boss ? 4.4 : 0
                after(1.2 + wait) { self.bossSays(f, .out) }
                after(3.4 + wait) { self.flashArena { self.world.hideArena() } }
                after(4.0 + wait) {
                    self.bossLine = nil
                    // free version: a full-screen ad after the stage boss (not a mid boss: that is in the middle of a stage).
                    // The game waits until it is closed.
                    if f.kind == .boss { AdManager.shared.breakAd { self.walkThenNext() } } else { self.walkThenNext() }
                }
            } else {
                if f.isBoss && f.hits == (f.hpMax + 1) / 2 { after(0.5) { self.bossSays(f, .half) } }
                after(1.1) {
                    guard let j = self.foes.firstIndex(where: { $0.id == id }) else { return }
                    self.foes[j].question = self.foes[j].queue.removeFirst()
                    self.reveal = nil
                    self.begin(id)
                }
            }
            return
        }
        // small Gobble: rescued right away; the next question appears immediately
        foes.remove(at: i)
        app.progress.zukanSaved[f.zukanID, default: 0] += 1
        if f.kind == .rare {
            let k = GameEvents.rares.firstIndex(of: f.image) ?? 0
            score += GameEvents.rareScore[k] * (feverLeft > 0 ? 2 : 1)
            showEvent(.init(image: f.image, line: GameEvents.rareGot(k), tone: .rare), for: 2.4)
            after(0.15) { AudioManager.shared.se(.levelUp); AudioManager.shared.se(.sparkle, rate: 1.2, volume: 0.9) }
            world.shake(0.2)
        }
        after(0.28) {
            AudioManager.shared.se(.rescue, volume: 0.8)
            self.world.rescue(id, big: false)
            self.world.restore(1)
            if let k = f.item { self.gain(k) }
        }
        if targetID == id {
            targetID = nil
            if let next = foes.first(where: { $0.active && !$0.attacking }) { select(next.id, sound: false) }
        }
        if foes.isEmpty { after(1.3) { self.walkThenNext() } }
    }

    /// Quick quiz answered: the thrown thing flies back, then the real question.
    private func deflect(_ i: Int) {
        let id = foes[i].id
        let q = foes[i].question
        if q.point == "vocab" { app.vocab.answer(q.a.lowercased(), correct: true); app.vocab.gameHits += 1 }
        app.study.track(q, skill: answerSkill, correct: true)
        combo += 1; maxCombo = max(maxCombo, combo); correctCount += 1
        score += Int(60 * ref.difficulty.scoreScale * (answerMode == .choice ? 1 : 1.5))
        foes[i].question = foes[i].held ?? q
        foes[i].held = nil
        foes[i].active = false
        world.charge(id, false)
        // knocked away: it spins off and falls to the ground
        missile?.at = foes[i].meter
        missile?.state = .deflected
        world.approach(id, fast: fast)
        after(1.0, scaled: false) { if self.missile?.foe == id { self.missile = nil } }
        AudioManager.shared.se(.hitBig, rate: 1.5, volume: 0.9)
        AudioManager.shared.se(.kira, rate: 1.3, volume: 0.8)
        after(0.55, scaled: false) { AudioManager.shared.se(.boyon, rate: 0.7, volume: 0.6) }
        Speaker.shared.say(q.full, gender: AppState.shared.settings.gameGender)
        say(T("はね返した！", "튕겨냈다!", "彈回去了！"))
        after(0.9) {
            guard self.foes.contains(where: { $0.id == id }) else { return }
            self.reveal = nil
            self.begin(id)
        }
    }

    /// The prototype's hit sounds: the longer the combo, the more layers.
    static func hitSound(combo c: Int, big: Bool) {
        let a = AudioManager.shared
        if big { a.se(.hitBig); a.se(.kira, volume: 0.6); return }
        if c < 3 { a.se(.hitSmall) }
        else if c < 5 { a.se(.hitSmall); later(0.07) { a.se(.kira, volume: 0.8) } }
        else if c < 7 { a.se(.hitBig); later(0.08) { a.se(.eyeShine, volume: 0.8) } }
        else if c < 10 { a.se(.superHit); later(0.07) { a.se(.hitBig, volume: 0.7) } }
        else { a.se(.superHit); a.se(.blast, volume: 0.7); later(0.09) { a.se(.hitBig, volume: 0.7) } }
    }

    // MARK: - timer

    private var keepAlive: Double = 0
    private func tick(_ dt: Double) {
        guard phase == .playing, !paused else { return }
        keepAlive += dt
        if keepAlive >= 0.5 { keepAlive = 0; world.ensureRunning(frozen: timeStopLeft > 0) }
        if timeStopLeft > 0 {
            timeStopLeft = max(0, timeStopLeft - dt)
            if timeStopLeft == 0 { world.freeze(false); AudioManager.shared.se(.papa, volume: 0.6) }
            return
        }
        if feverLeft > 0 {
            feverLeft = max(0, feverLeft - dt)
            if feverLeft == 0 { AudioManager.shared.se(.papa, volume: 0.5) }
        }
        guard foes.contains(where: { $0.active && !$0.attacking }) else { return }
        let slow = feverLeft > 0 ? 0.55 : 1.0
        var due: [UUID] = []
        for i in foes.indices where foes[i].active && !foes[i].attacking {
            // enemies you are not answering wait at half speed
            foes[i].elapsed += (foes[i].id == targetID ? dt : dt * 0.5) * slow
            if foes[i].meter >= 1 { due.append(foes[i].id) }
        }
        due.forEach(timeout)
    }

    private func timeout(_ id: UUID) {
        guard lives > 0, let i = foes.firstIndex(where: { $0.id == id }), !foes[i].attacking else { return }
        foes[i].attacking = true
        foes[i].active = false
        let f = foes[i]
        if f.kind == .rare || f.kind == .kidnap {
            if f.kind == .rare {
                showEvent(.init(image: f.image, line: GameEvents.rareRan, tone: .rare), for: 1.8)
            } else {
                helpChip = nil
                showEvent(.init(image: captive, line: GameEvents.gotAway, tone: .help), for: 2.0)
            }
            AudioManager.shared.se(.sad, volume: 0.6)
            foes.remove(at: i)
            world.flee(id)
            if targetID == id { targetID = nil }
            if f.kind == .kidnap {
                // the person was carried off: that hurts (one heart), and the answer is shown
                if !dev.noDamage || !dev.enabled { lives -= 1 }
                feverLeft = 0; combo = 0
                missed.append(f.question)
                app.study.recordMiss(f.question)
                after(0.4, scaled: false) {
                    AudioManager.shared.se(.damage)
                    self.flashOnce(.damage)
                    self.reveal = f.question.full
                    Speaker.shared.say(f.question.full, gender: AppState.shared.settings.gameGender)
                }
                if lives <= 0 { after(1.8) { self.gameOver() }; return }
                after(2.4) {
                    if self.reveal == f.question.full { self.reveal = nil }
                    if self.foes.isEmpty { self.walkThenNext() }
                }
                return
            }
            if foes.isEmpty { after(1.6) { self.walkThenNext() } }
            return
        }
        // the lucky Gobble (it carries an item) fights back like any other enemy: missing it costs a heart
        if f.held != nil {
            // the thrown thing reaches you
            world.charge(id, false)
            missile?.state = .hit
            AudioManager.shared.se(.shoot, rate: 0.7, volume: 0.6)          // whoosh while it flies the last bit
            after(0.24, scaled: false) {
                AudioManager.shared.se(.blast, volume: 0.9)                 // the bang lands with the BANG! picture
                self.world.shake(0.45)
            }
            after(0.3, scaled: false) { self.bitten(id) }
            after(1.0, scaled: false) { if self.missile?.foe == id { self.missile = nil } }
            return
        }
        let kind = AttackKind.pick(big: f.isBig)
        lastAttack[id] = kind
        world.attack(id, kind: kind)
        switch kind {
        case .bite, .lick: AudioManager.shared.se(.boyon, volume: 0.7)
        case .stomp: AudioManager.shared.se(.spawn, rate: 0.7, volume: 0.8)
        case .spit: AudioManager.shared.se(.shoot, rate: 0.6, volume: 0.8)
        case .spin: AudioManager.shared.se(.papa, rate: 0.8, volume: 0.8)
        case .roar: AudioManager.shared.se(.bossAppear, rate: 1.4, volume: 0.6)
        }
        after(kind.impact) { self.bitten(id) }
    }

    private func bitten(_ id: UUID) {
        guard phase == .playing, let i = foes.firstIndex(where: { $0.id == id }) else { return }
        let f = foes[i]
        if !dev.noDamage || !dev.enabled { lives -= 1 }
        feverLeft = 0
        combo = 0
        missed.append(f.question)
        if f.question.point == "vocab" { app.vocab.answer(f.question.a.lowercased(), correct: false) }
        app.study.recordMiss(f.question)
        AudioManager.shared.se(.damage)
        flashOnce(.damage)
        Speaker.shared.say(f.question.full, gender: AppState.shared.settings.gameGender)
        let wasTarget = targetID == id || targetID == nil
        if wasTarget { reveal = f.question.full } else { say(L("game.answerWas") + f.question.full, long: true) }
        if f.held != nil {
            say(T("飛び道具が|当たった！", "날아온 게 맞았다!", "被飛行道具打中了！"), long: true)
        } else {
            let k = lastAttack.removeValue(forKey: id) ?? .bite
            if k == .stomp || k == .roar { AudioManager.shared.se(.blast, volume: 0.7) }
            withAnimation(.easeOut(duration: 0.1)) { hitFX = k }
            after(0.75, scaled: false) { withAnimation(.easeOut(duration: 0.3)) { self.hitFX = nil } }
            say(k.shout, long: true)
        }
        if lives <= 0 { after(1.6) { self.gameOver() }; return }

        if let h = f.held {
            // the thrown thing hit: now the real question (a thrower walks up first)
            world.approach(id, fast: fast)
            foes[i].question = h
            foes[i].held = nil
            foes[i].attacking = false
            after(1.8) { if self.reveal == f.question.full { self.reveal = nil }; self.begin(id) }
            return
        }
        if f.isBig {
            // the boss asks one more question later — a new one, so the same question doesn't keep coming back
            let p = QuestionBank.pools(for: ref.area)
            let fresh = (p.mid + p.boss + p.phrase + p.single).shuffled().first { $0.kind == f.question.kind && !planKeys.contains($0.dedupeKey) }
            if let fresh { planKeys.insert(fresh.dedupeKey) }
            foes[i].queue.append(fresh ?? f.question)
            foes[i].question = foes[i].queue.removeFirst()
            foes[i].attacking = false
            after(1.8) { self.reveal = nil; self.begin(id) }
            return
        }
        foes.remove(at: i)
        world.flee(id)
        if targetID == id { targetID = nil }
        after(1.8) {
            if self.reveal == f.question.full { self.reveal = nil }
            if self.targetID == nil, let next = self.foes.first(where: { $0.active && !$0.attacking }) { self.select(next.id, sound: false) }
            if self.foes.isEmpty { self.walkThenNext() }
        }
    }

    // MARK: - fork

    func chooseRoute(left: Bool) {
        guard forkChoice else { return }
        forkChoice = false
        let d = world.takeFork(left: left, fast: fast)
        after(d + 0.3, scaled: false) {
            let wait = self.forkLuck()
            self.after(wait, scaled: false) { self.nextEncounter() }
        }
    }

    /// One road is lucky, the other is not: a little gamble at every junction.
    /// Returns how long to wait before the next encounter.
    private func forkLuck() -> Double {
        guard phase == .playing, lives > 0 else { return 0 }
        let r = Double.random(in: 0..<1)
        if Bool.random() {
            // lucky road
            AudioManager.shared.se(.sparkle, rate: 1.1, volume: 0.9)
            if r < 0.4, let k = ItemKind.allCases.randomElement() {
                say(T("アタリ！|宝箱を|見つけた！", "당첨! 보물상자를 찾았다!", "猜對了！發現寶箱！"), long: true)
                gain(k)
            } else if r < 0.7, lives < maxLives {
                say(T("アタリ！|きれいな|泉で|ひと休み", "당첨! 맑은 샘에서 잠깐 휴식", "猜對了！在清泉旁休息一下"), long: true)
                lives += 1
                AudioManager.shared.se(.heal)
                flashOnce(.heal)
            } else {
                say(T("アタリ！|コインを|拾った|+500", "당첨! 코인을 주웠다 +500", "猜對了！撿到金幣 +500"), long: true)
                score += 500
                AudioManager.shared.se(.levelUp, volume: 0.7)
            }
            return 1.6
        }
        // unlucky road
        AudioManager.shared.se(.sad, volume: 0.7)
        if r < 0.4, lives > 1 {
            say(T("ハズレ！|落とし穴に|落ちた！", "꽝! 함정에 빠졌다!", "猜錯了！掉進陷阱！"), long: true)
            if !dev.noDamage || !dev.enabled { lives -= 1 }
            AudioManager.shared.se(.damage)
            flashOnce(.damage)
            world.shake(0.4)
            return 1.8
        }
        if r < 0.75 {
            // an ambush: two more enemies jump out
            say(T("ハズレ！|待ちぶせだ！", "꽝! 매복이다!", "猜錯了！有埋伏！"), long: true)
            let p = QuestionBank.pools(for: ref.area)
            let fresh = p.single.shuffled().filter { !planKeys.contains($0.dedupeKey) }
            let qs = Array((fresh.count >= 2 ? fresh : p.single.shuffled()).prefix(2))
            if qs.count == 2 {
                qs.forEach { planKeys.insert($0.dedupeKey) }
                plan.insert(.pack(qs, images: [Int.random(in: 0..<16), Int.random(in: 0..<16)], item: nil), at: min(plan.count, idx + 1))
                updateProgress()
            }
            world.shake(0.25)
            return 1.4
        }
        say(T("ハズレ！|道に迷って|-300", "꽝! 길을 잃었다 -300", "猜錯了！迷路了 -300"), long: true)
        score = max(0, score - 300)
        return 1.6
    }

    // MARK: - items

    /// saved slots → 3 slots ("" = empty; older saves were packed lists)
    static func slots(_ saved: [String]) -> [ItemKind?] {
        var out: [ItemKind?] = saved.prefix(3).map { ItemKind(rawValue: $0) }
        while out.count < 3 { out.append(nil) }
        return out
    }

    private var itemsInFlight = 0
    private func gain(_ k: ItemKind) {
        if KanaRescue.active { return }
        // items still flying to the tray already own an empty slot
        guard items.filter({ $0 == nil }).count > itemsInFlight else {
            if k == .heart && lives < maxLives { lives += 1; AudioManager.shared.se(.heal); flashOnce(.heal); say("LIFE UP!") } else { say(L("game.itemFull")) }
            return
        }
        AudioManager.shared.se(.itemGet)
        flyingItem = k
        itemsInFlight += 1
        after(0.9) {
            self.itemsInFlight -= 1
            // the first empty slot (filled in now, in case another item came in meanwhile)
            if let at = self.items.firstIndex(where: { $0 == nil }) { self.items[at] = k }
            if self.itemsInFlight == 0 { self.flyingItem = nil }
            self.saveItems()
        }
    }

    func use(slot at: Int) {
        guard phase == .playing, !paused, at < items.count, let k = items[at] else { return }
        switch k {
        case .heart:
            guard lives < maxLives else { say(L("game.lifeFull")); return }
            lives += 1
            AudioManager.shared.se(.heal)
            flashOnce(.heal)
        case .bomb:
            guard let id = targetID, let f = foes.first(where: { $0.id == id }), f.active, !f.attacking else { say(L("game.noTarget")); return }
            AudioManager.shared.se(.bomb)
            world.shoot(at: id, color: UIColor(red: 1, green: 0.55, blue: 0.3, alpha: 1))
            world.shake(0.3)
            reveal = f.question.full
            Speaker.shared.say(f.question.full, gender: AppState.shared.settings.gameGender)
            defeatOrNext(id, scored: false)
            after(1.6) { if self.reveal == f.question.full { self.reveal = nil } }
        case .timeStop:
            guard timeStopLeft <= 0, !foes.isEmpty else { say(L("game.noTarget")); return }
            timeStopLeft = 6
            world.freeze(true)
            AudioManager.shared.se(.timeStop)
        }
        items[at] = nil
        saveItems()
    }

    private func saveItems() {
        app.progress.items = items.map { $0?.rawValue ?? "" }
        app.save()
    }

    // MARK: - talk / effects

    private func say(_ s: String, long: Bool = false) {
        guard !s.isEmpty else { return }
        talkToken += 1
        let t = talkToken
        talk = s
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: long ? 2_200_000_000 : 1_300_000_000)
            if self.talkToken == t { self.talk = nil }
        }
    }

    private func showEvent(_ e: EventScene, for seconds: Double) {
        eventToken += 1
        let t = eventToken
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { event = e }
        after(seconds, scaled: false) { if self.eventToken == t { withAnimation(.easeOut(duration: 0.25)) { self.event = nil } } }
    }

    /// Big boss finish: thunder with flashes on each crack, then a fanfare.
    /// Big boss finish: a long thunder storm (5 strikes), then an explosion in a cloud of smoke,
    /// the boss's true form appears, and the stage-clear fanfare plays.
    private func thunderStrike() {
        AudioManager.shared.se(.thunder, volume: 1)
        for (t, a) in [(0.0, 0.95), (0.25, 0.7), (0.7, 0.95), (1.15, 0.6), (1.6, 0.9)] {
            after(t, scaled: false) {
                self.thunder = a
                self.world.shake(0.35)
                self.after(0.06, scaled: false) { self.thunder = a * 0.25 }
                self.after(0.1, scaled: false) { self.thunder = a * 0.8 }
                self.after(0.18, scaled: false) { withAnimation(.easeOut(duration: 0.3)) { self.thunder = 0 } }
            }
        }
        after(2.0, scaled: false) {
            AudioManager.shared.stopBGM()           // a moment of silence for the reveal
            AudioManager.shared.se(.boom, volume: 1)
            self.world.shake(0.6)
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
        // the fanfare is the (gorgeous) stage-clear sound, played when the stage ends
    }

    private func flashArena(_ swap: @escaping () -> Void) {
        withAnimation(.easeIn(duration: 0.15)) { arenaFlash = true }
        after(0.17, scaled: false) {
            swap()
            withAnimation(.easeOut(duration: 0.35)) { self.arenaFlash = false }
        }
    }

    private func startFever() {
        feverLeft = 10
        AudioManager.shared.se(.fever, volume: 0.95)
        say("FEVER!!", long: true)
        world.shake(0.15)
    }

    private func bossSays(_ f: Foe, _ v: BossVoice) {
        let l = BossVoice.line(f.kind, ref: ref, v, profile: f.profile, shadow: f.shadow)
        bossLine = l
        if !(f.kind == .boss && KanaRescue.sayBoss(l.en, key: ref.area.boss.key)) {
            Speaker.shared.say(l.en, voice: l.who.voice)
        }
        let shown = l
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if self.bossLine == shown { self.bossLine = nil }
        }
    }

    private func flashOnce(_ f: Flash) {
        flash = f
        if f == .damage { world.shake(0.35) }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 260_000_000)
            self.flash = nil
        }
    }

    /// Before the boss: the music stops, the screen darkens with warning flashes and thunder,
    /// the boss's silhouette speaks — then the battle starts.
    private func bossEntrance() {
        let grad = ref.area == .graduation
        AudioManager.shared.stopBGM()
        AudioManager.shared.se(.bossAppear, volume: 1)
        world.shake(0.3)
        say(T("…なにか|来るにゃ！", "…뭔가 온다냥!", "…有東西要來了喵！"), long: true)
        let strikes: [Double] = grad ? [0.6, 1.3, 1.9, 2.6, 3.2] : [0.8, 1.9]
        for t in strikes {
            after(t, scaled: false) {
                AudioManager.shared.se(.thunder, rate: grad ? 0.9 : 1.15, volume: grad ? 1 : 0.7)
                self.thunder = 0.9; self.world.shake(grad ? 0.5 : 0.3)
                self.after(0.08, scaled: false) { self.thunder = 0.2 }
                self.after(0.14, scaled: false) { self.thunder = 0.75 }
                self.after(0.24, scaled: false) { withAnimation(.easeOut(duration: 0.4)) { self.thunder = 0 } }
            }
        }
        let line: EventLine = grad
            ? .init(en: "しずかに…　もじの ない せかいこそ、やすらぎの せかいだ。", ja: "しずかに…|言葉のない|世界こそ、|やすらぎの|世界だ。", ko: "조용히… 말이 없는 세상이야말로 평온한 세상이다.", zh: "安靜……沒有語言的世界，才是平靜的世界。")
            : .init(en: "ほう…　ここまで きたか。", ja: "ほう…|ここまで|来たか。", ko: "호오… 여기까지 왔나.", zh: "哦……你們竟然走到這裡了。")
        after(grad ? 1.6 : 1.0, scaled: false) {
            self.showEvent(.init(image: self.ref.area.boss.image, line: line, tone: .evil), for: grad ? 3.4 : 2.6)
            if !KanaRescue.sayBoss(line.en, key: self.ref.area.boss.key) {
                Speaker.shared.say(line.en, voice: self.ref.area.boss.voice)
            }
        }
        after(grad ? 5.2 : 3.8, scaled: false) {
            AudioManager.shared.playBGM(grad ? .final : .boss)
            self.nextEncounter()
        }
    }

    private func updateProgress() {
        let total = plan.filter { if case .fork = $0 { return false }; if case .bossCall = $0 { return false }; return true }.count
        let done = plan.prefix(max(0, idx)).filter { if case .fork = $0 { return false }; if case .bossCall = $0 { return false }; return true }.count
        progressText = "\(min(done + 1, max(total, 1)))/\(max(total, 1))"
    }

    // MARK: - end

    private func stageClear() {
        cleared = true
        foes = []; targetID = nil
        AudioManager.shared.stopBGM()
        // boss stages end with the big boss fanfare (falls back to the stage-clear sound if missing)
        let bossStage = StagePlanner(ref: ref).kind == .boss
        AudioManager.shared.se(bossStage && Bundle.main.url(forResource: "se_fanfare_boss", withExtension: "m4a") != nil ? .fanfareBoss : .clear, volume: 1)
        world.restore(20)
        let total = correctCount + wrongCount + missed.count
        let acc = total == 0 ? 1 : Double(correctCount) / Double(total)
        rank = acc >= 0.95 && lives == maxLives ? "S" : acc >= 0.85 ? "A" : acc >= 0.7 ? "B" : "C"
        stars = rank == "S" || rank == "A" ? 3 : rank == "B" ? 2 : 1
        let key = ProgressStore.key(ref)
        var r = app.progress.results[key] ?? StageResult()
        newBest = score > r.bestScore
        r.bestScore = max(r.bestScore, score)
        if r.bestRank.isEmpty || "SABC".firstIndex(of: Character(rank))! < "SABC".firstIndex(of: Character(r.bestRank))! { r.bestRank = rank }
        r.stars = max(r.stars, stars)
        app.progress.results[key] = r
        app.save()
        after(2.0) {
            // the very last boss: the ending theme plays over the closing story
            if self.ref.area == .graduation && StagePlanner(ref: self.ref).kind == .boss { AudioManager.shared.playBGM(.ending) }
            if self.storyLines(.outro).isEmpty { self.phase = .result } else { self.phase = .story(.outro) }
        }
    }

    private func gameOver() {
        cleared = false
        world.removeAllFoes()
        foes = []; targetID = nil
        AudioManager.shared.stopBGM()
        AudioManager.shared.se(.gameOver)
        app.save()
        after(0.8) { AudioManager.shared.se(.sad, volume: 0.7) }
        phase = .result
    }

    /// The stage after this one (next area's first stage after a boss).
    var nextStage: StageRef? {
        if ref.index < ref.area.stageCount { return StageRef(area: ref.area, index: ref.index + 1, difficulty: ref.difficulty) }
        if let a = Area(rawValue: ref.area.rawValue + 1) { return StageRef(area: a, index: 1, difficulty: ref.difficulty) }
        return nil
    }
}

/// 30 fps timer for the meters.
final class FrameTicker: NSObject {
    var onTick: (Double) -> Void = { _ in }
    private var link: CADisplayLink?
    private var last: CFTimeInterval = 0

    func start() {
        guard link == nil else { return }
        last = 0
        let l = CADisplayLink(target: self, selector: #selector(step(_:)))
        l.preferredFrameRateRange = CAFrameRateRange(minimum: 20, maximum: 30, preferred: 30)
        l.add(to: .main, forMode: .common)
        link = l
    }

    func stop() { link?.invalidate(); link = nil }

    @objc private func step(_ l: CADisplayLink) {
        let dt = last == 0 ? 0 : l.timestamp - last
        last = l.timestamp
        onTick(min(dt, 0.1))
    }
}
