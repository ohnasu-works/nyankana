import SwiftUI
import Combine

// MARK: - Navigation

enum Screen: Equatable {
    case home, map, study, zukan, record, closet, settings
    case game(StageRef)
}

enum SheetKind: String, Identifiable {
    case items, howTo, shop
    var id: String { rawValue }
}

// MARK: - World data (areas / stages / difficulty)

enum Area: Int, CaseIterable, Codable, Identifiable {
    case lv1 = 1, lv2, lv3, lv4, lv5, lv6, graduation
    var id: Int { rawValue }

    /// short label shown on the map node
    var badge: String { self == .graduation ? "★" : "\(rawValue)" }
    var levelLabel: String { self == .graduation ? L("area.grad.short") : "Lv\(rawValue)" }
    var name: String { L("area.\(rawValue).name") }
    var bossName: String { L("area.\(rawValue).boss") }
    var grammarHint: String { L("area.\(rawValue).grammar") }
    /// node position on the map picture, in fractions of its width / height
    var mapPoint: CGPoint {
        switch self {
        case .lv1: return CGPoint(x: 0.50, y: 0.84)
        case .lv2: return CGPoint(x: 0.68, y: 0.66)
        case .lv3: return CGPoint(x: 0.43, y: 0.57)
        case .lv4: return CGPoint(x: 0.73, y: 0.46)
        case .lv5: return CGPoint(x: 0.32, y: 0.38)
        case .lv6: return CGPoint(x: 0.68, y: 0.31)
        case .graduation: return CGPoint(x: 0.66, y: 0.13)
        }
    }
    var stageCount: Int { self == .graduation ? 10 : 30 }
}

enum Difficulty: String, CaseIterable, Codable, Identifiable {
    case easy, normal, hard
    var id: String { rawValue }
    var title: String { rawValue.uppercased() }
    var note: String { L("diff.\(rawValue).note") }
    var lives: Int { switch self { case .easy: 6; case .normal: 5; case .hard: 4 } }
    var timeScale: Double { switch self { case .easy: 1.6; case .normal: 1.0; case .hard: 0.85 } }
    /// answer buttons shown (easy = 3 choices)
    var choiceCount: Int { 4 }   // 3 choices were too easy to guess through
    /// how much of the time limit a wrong answer eats
    var wrongPenalty: Double { switch self { case .easy: 0.12; case .normal: 0.22; case .hard: 0.3 } }
    /// share of small enemies that ask a vocabulary word
    var vocabRate: Double { switch self { case .easy: 0.15; case .normal: 0.25; case .hard: 0.3 } }
    var scoreScale: Double { switch self { case .easy: 0.8; case .normal: 1.0; case .hard: 1.5 } }
}

struct StageRef: Hashable, Codable {
    var area: Area
    var index: Int          // 1...stageCount
    var difficulty: Difficulty
}

// MARK: - App state (single source of truth, saved on change)

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var screen: Screen = .home
    @Published var sheet: SheetKind?

    let settings = SettingsStore()
    let dev = DevSettings()
    @Published var progress = ProgressStore.load()
    @Published var study = StudyLog.load()
    @Published var vocab = VocabLog.load()

    private var bag = Set<AnyCancellable>()

    private init() {
        // re-publish nested stores so every screen refreshes
        settings.objectWillChange.sink { [weak self] in self?.objectWillChange.send() }.store(in: &bag)
        dev.objectWillChange.sink { [weak self] in self?.objectWillChange.send() }.store(in: &bag)
        // iPhone ⇄ iPad: take in what the other device saved to iCloud, now and whenever it changes
        let kv = NSUbiquitousKeyValueStore.default
        NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: kv)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.mergeCloud() }
            .store(in: &bag)
        kv.synchronize()
        mergeCloud()
        Outfit.sync(self)
    }

    /// merge the iCloud copy into this device's progress and save the result back
    func mergeCloud() {
        // take in what is new from the other device; send up only what the cloud is missing
        // (writing the same thing back would bounce between the devices forever)
        if let c = ProgressStore.cloud() {
            let m = progress.merged(with: c)
            if m != progress { progress = m; m.writeLocal() }
            if m != c { m.upload() }
        } else { progress.upload() }
        if let c = CloudSync.get(StudyLog.self, "study") {
            let m = study.merged(with: c)
            if m != study { study = m; m.writeLocal() }
            if m != c { CloudSync.put(m, "study") }
        } else { CloudSync.put(study, "study") }
        if let c = CloudSync.get(VocabLog.self, "vocab") {
            let m = vocab.merged(with: c)
            if m != vocab { vocab = m; m.writeLocal() }
            if m != c { CloudSync.put(m, "vocab") }
        } else { CloudSync.put(vocab, "vocab") }
        if let c = CloudSync.get(ToeicCloud.self, "toeic") { ToeicCloud.merge(c) }
        let t = ToeicCloud.local()
        if CloudSync.get(ToeicCloud.self, "toeic") != t { CloudSync.put(t, "toeic") }
    }

    /// TOEIC records live in their own store: send them up after a test or practice
    func saveToeic() { CloudSync.put(ToeicCloud.local(), "toeic") }

    func go(_ s: Screen) {
        AudioManager.shared.se(.tap)
        if case .game(let r) = s { lastArea = r.area }
        screen = s
    }

    /// the area played last: the map opens there
    var lastArea: Area {
        get { Area(rawValue: UserDefaults.standard.integer(forKey: "lastArea")) ?? .lv1 }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "lastArea") }
    }
    /// set before going to the map to open that area's stage list straight away
    var openStageList = false
    /// back to the stage list of the area just played (from a result or the pause menu)
    func goStageList() { openStageList = true; go(.map) }

    var isPremium: Bool {
        // review recording ("-debugForceFree" or the developer switch; never in the App Store version):
        // ignore saved / iCloud / earlier TestFlight premium and trust only a purchase made in this run
        if Store.debugForceFree { return Store.shared.debugOwned }
        return progress.premium || dev.premium
    }

    func isUnlocked(_ area: Area) -> Bool {
        if dev.unlocks { return true }
        if area == .lv1 { return true }
        guard let prev = Area(rawValue: area.rawValue - 1) else { return true }
        return progress.clearedStages(in: prev) >= prev.stageCount
    }

    func isUnlocked(stage: Int, in area: Area) -> Bool {
        if dev.unlocks { return true }
        guard isUnlocked(area) else { return false }
        return stage <= progress.clearedStages(in: area) + 1
    }

    var toeicUnlocked: Bool { dev.unlocks || isPremium || progress.clearedStages(in: .graduation) >= Area.graduation.stageCount }

    func save() { progress.save(); study.save(); vocab.save(); saveToeic() }
}

// MARK: - Progress (saved locally + iCloud key-value)

struct StageResult: Codable, Equatable {
    var bestScore: Int = 0
    var bestRank: String = ""
    var stars: Int = 0
}

struct ProgressStore: Codable, Equatable {
    var premium = false
    /// "area-index-difficulty" -> best result
    var results: [String: StageResult] = [:]
    var items: [String] = []            // held item ids (max 3)
    var outfits: Set<String> = ["ken.default", "rin.default", "nyan.default"]
    var wearing: [String: String] = ["ken": "ken.default", "rin": "rin.default", "nyan": "nyan.default"]
    var zukanSeen: [String: Int] = [:]
    var zukanSaved: [String: Int] = [:]
    var zukanStar: Set<String> = []
    var streakDays: Int = 0
    var lastStudyDay: String = ""

    static func key(_ ref: StageRef) -> String { "\(ref.area.rawValue)-\(ref.index)-\(ref.difficulty.rawValue)" }

    func clearedStages(in area: Area) -> Int {
        var n = 0
        for i in 1...area.stageCount {
            let cleared = Difficulty.allCases.contains { results[ProgressStore.key(StageRef(area: area, index: i, difficulty: $0))] != nil }
            if cleared { n = i } else { break }
        }
        return n
    }

    private static let fileURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("progress.json")
    }()

    static func load() -> ProgressStore {
        if let d = try? Data(contentsOf: fileURL), let p = try? JSONDecoder().decode(ProgressStore.self, from: d) { return p }
        return ProgressStore()
    }

    func save() { writeLocal(); upload() }
    func writeLocal() { if let d = try? JSONEncoder().encode(self) { try? d.write(to: ProgressStore.fileURL, options: .atomic) } }
    func upload() { if let d = try? JSONEncoder().encode(self) { NSUbiquitousKeyValueStore.default.set(d, forKey: "progress") } }

    /// the copy saved in iCloud by another device (iPhone ⇄ iPad)
    static func cloud() -> ProgressStore? {
        guard let d = NSUbiquitousKeyValueStore.default.data(forKey: "progress") else { return nil }
        return try? JSONDecoder().decode(ProgressStore.self, from: d)
    }

    /// Combine two devices' progress without losing anything: best results, every outfit and
    /// every Gobble met on either device. Held items and what you wear stay as on this device.
    func merged(with o: ProgressStore) -> ProgressStore {
        var m = self
        m.premium = premium || o.premium
        for (k, r) in o.results {
            guard let mine = m.results[k] else { m.results[k] = r; continue }
            var b = mine
            b.stars = max(mine.stars, r.stars)
            if r.bestScore > mine.bestScore { b.bestScore = r.bestScore; b.bestRank = r.bestRank }
            m.results[k] = b
        }
        m.outfits.formUnion(o.outfits)
        m.zukanSeen.merge(o.zukanSeen) { max($0, $1) }
        m.zukanSaved.merge(o.zukanSaved) { max($0, $1) }
        m.zukanStar.formUnion(o.zukanStar)
        if o.lastStudyDay > lastStudyDay || (o.lastStudyDay == lastStudyDay && o.streakDays > streakDays) {
            m.lastStudyDay = o.lastStudyDay; m.streakDays = o.streakDays
        }
        return m
    }
}

// MARK: - Settings

@MainActor
final class SettingsStore: ObservableObject {
    private let d = UserDefaults.standard
    @Published var bgmVolume: Double { didSet { d.set(bgmVolume, forKey: "bgmVolume"); AudioManager.shared.bgmVolume = Float(bgmVolume) } }
    @Published var seVolume: Double { didSet { d.set(seVolume, forKey: "seVolume"); AudioManager.shared.seVolume = Float(seVolume) } }
    @Published var voiceVolume: Double { didSet { d.set(voiceVolume, forKey: "voiceVolume") } }
    @Published var voiceOn: Bool { didSet { d.set(voiceOn, forKey: "voiceOn") } }
    @Published var slowVoice: Bool { didSet { d.set(slowVoice, forKey: "slowVoice") } }
    /// voice that reads the sentence when an enemy is beaten ("f" / "m")
    @Published var gameVoice: String { didSet { d.set(gameVoice, forKey: "gameVoice") } }
    /// voice for words in the word training ("f" / "m")
    @Published var wordVoice: String { didSet { d.set(wordVoice, forKey: "wordVoice") } }
    /// voice for sentences in the study mode ("f" / "m")
    @Published var studyVoice: String { didSet { d.set(studyVoice, forKey: "studyVoice") } }
    var studyGender: Speaker.Gender { studyVoice == "m" ? .male : .female }
    var gameGender: Speaker.Gender { gameVoice == "m" ? .male : .female }
    var wordGender: Speaker.Gender { wordVoice == "m" ? .male : .female }
    @Published var subtitles: Bool { didSet { d.set(subtitles, forKey: "subtitles") } }
    @Published var answerMode: AnswerMode { didSet { d.set(answerMode.rawValue, forKey: "answerMode") } }
    @Published var difficulty: Difficulty { didSet { d.set(difficulty.rawValue, forKey: "difficulty") } }
    /// iPad / Mac landscape: answer panel on the left
    @Published var leftHanded: Bool { didSet { d.set(leftHanded, forKey: "leftHanded") } }
    /// "" = follow the device language; otherwise "ja", "ko", "zh-Hant"
    @Published var lang: String { didSet { d.set(lang, forKey: "lang"); L10n.current = L10n.resolve(lang) } }

    init() {
        d.register(defaults: ["bgmVolume": 0.6, "seVolume": 0.9, "voiceVolume": 1.0, "voiceOn": true, "slowVoice": false, "subtitles": true])
        bgmVolume = d.double(forKey: "bgmVolume")
        seVolume = d.double(forKey: "seVolume")
        voiceVolume = d.double(forKey: "voiceVolume")
        voiceOn = d.bool(forKey: "voiceOn")
        slowVoice = d.bool(forKey: "slowVoice")
        gameVoice = d.string(forKey: "gameVoice") ?? "f"
        wordVoice = d.string(forKey: "wordVoice") ?? "f"
        studyVoice = d.string(forKey: "studyVoice") ?? "f"
        subtitles = d.bool(forKey: "subtitles")
        // on a Mac the keyboard is right there: typing is the default
        answerMode = AnswerMode(rawValue: d.string(forKey: "answerMode") ?? "") ?? (ProcessInfo.processInfo.isiOSAppOnMac ? .keyboard : .choice)
        leftHanded = d.bool(forKey: "leftHanded")
        difficulty = Difficulty(rawValue: d.string(forKey: "difficulty") ?? "") ?? .normal
        lang = d.string(forKey: "lang") ?? ""
        #if DEBUG && targetEnvironment(simulator)
        // screenshots: the language can be forced here (simulator debug builds only)
        if !ScreenshotLang.value.isEmpty { lang = ScreenshotLang.value }
        #endif
        L10n.current = L10n.resolve(lang)
    }
}

enum AnswerMode: String, CaseIterable, Identifiable {
    case choice, keyboard, handwriting, voice
    var id: String { rawValue }
    var title: String { L("mode.\(rawValue)") }
    var icon: String {
        switch self { case .choice: "hand.tap.fill"; case .keyboard: "keyboard.fill"; case .handwriting: "pencil.tip"; case .voice: "mic.fill" }
    }
}

#if DEBUG && targetEnvironment(simulator)
enum ScreenshotLang { static let value = "" }
#endif
