import SwiftUI
import UIKit

/// Pick the UI-language variant of a short string.
/// Text in the UI language. vi / es / pt / en can be given inline (needed when the Japanese has \(…) inside);
/// otherwise they come from the translation tables (Tr), keyed by the Japanese.
func T(_ ja: String, _ ko: String, _ zh: String, vi: String? = nil, es: String? = nil, pt: String? = nil, en: String? = nil) -> String {
    switch L10n.current {
    case .ja: ja
    case .ko: ko
    case .zhHant: zh
    case .vi: vi ?? (Tr.has(ja) ? Tr.text(ja) : en ?? Tr.text(ja))
    case .es: es ?? (Tr.has(ja) ? Tr.text(ja) : en ?? Tr.text(ja))
    case .ptBR: pt ?? (Tr.has(ja) ? Tr.text(ja) : en ?? Tr.text(ja))
    case .en: en ?? Tr.text(ja)
    }
}

// MARK: - Study log (saved separately from game progress)

/// Daily study record: stamps, today's menu, weak points and best scores.
struct StudyLog: Codable, Equatable {
    struct Weak: Codable, Hashable { var q: Question; var miss: Int; var last: String }

    var days: [String: Int] = [:]          // "yyyy-MM-dd" -> answers that day
    var done: [String: [String]] = [:]     // "yyyy-MM-dd" -> finished menu ids
    var weak: [Weak] = []
    var best: [String: Int] = [:]
    var totalCorrect = 0
    var visits: [String] = []               // days the study screen was opened (attendance stamp)
    /// self-analysis: grammar point -> [right, asked]; skill ("vocab", "grammar", "listening", "writing", "speaking") -> [right, asked]
    var points: [String: [Int]] = [:]
    var skills: [String: [Int]] = [:]
    /// q.full -> when that weak point last changed (missed, answered right or cleared), for syncing
    var weakTouched: [String: Double] = [:]

    init() {}
    init(from d: Decoder) throws {
        let c = try d.container(keyedBy: K.self)
        days = (try? c.decodeIfPresent([String: Int].self, forKey: .days)) ?? [:]
        done = (try? c.decodeIfPresent([String: [String]].self, forKey: .done)) ?? [:]
        weak = (try? c.decodeIfPresent([Weak].self, forKey: .weak)) ?? []
        best = (try? c.decodeIfPresent([String: Int].self, forKey: .best)) ?? [:]
        totalCorrect = (try? c.decodeIfPresent(Int.self, forKey: .totalCorrect)) ?? 0
        visits = (try? c.decodeIfPresent([String].self, forKey: .visits)) ?? []
        points = (try? c.decodeIfPresent([String: [Int]].self, forKey: .points)) ?? [:]
        skills = (try? c.decodeIfPresent([String: [Int]].self, forKey: .skills)) ?? [:]
        weakTouched = (try? c.decodeIfPresent([String: Double].self, forKey: .weakTouched)) ?? [:]
    }
    private enum K: String, CodingKey { case days, done, weak, best, totalCorrect, visits, points, skills, weakTouched }

    /// Combine with another device's record: the bigger count wins (so nothing is counted twice),
    /// stamps and finished menus add up, and each weak point follows whichever device changed it last.
    func merged(with o: StudyLog) -> StudyLog {
        var m = self
        m.days.merge(o.days) { max($0, $1) }
        for (k, v) in o.done { m.done[k] = Array(Set((m.done[k] ?? []) + v)).sorted() }
        m.best.merge(o.best) { max($0, $1) }
        m.totalCorrect = max(totalCorrect, o.totalCorrect)
        m.visits = Array(Set(visits + o.visits)).sorted()
        m.points = CloudSync.maxPairs(points, o.points)
        m.skills = CloudSync.maxPairs(skills, o.skills)
        var mine = Dictionary(weak.map { ($0.q.full, $0) }, uniquingKeysWith: { a, _ in a })
        let theirs = Dictionary(o.weak.map { ($0.q.full, $0) }, uniquingKeysWith: { a, _ in a })
        for key in Set(mine.keys).union(theirs.keys).union(o.weakTouched.keys) {
            let tm = weakTouched[key] ?? 0, to = o.weakTouched[key] ?? 0
            if to > tm {
                mine[key] = theirs[key]          // nil = cleared on the other device
                m.weakTouched[key] = to
            } else if tm == to, mine[key] == nil, let t = theirs[key] {
                mine[key] = t                    // older records without times: keep both
            }
        }
        // keep the original order, then the new ones
        var out = weak.filter { mine[$0.q.full] != nil }.map { mine[$0.q.full]! }
        let have = Set(out.map(\.q.full))
        out += o.weak.filter { !have.contains($0.q.full) && mine[$0.q.full] != nil }.map { mine[$0.q.full]! }
        m.weak = Array(out.suffix(120))
        return m
    }

    /// one answer for the self-analysis table (game and study both count)
    mutating func track(_ q: Question, skill: String, correct: Bool) {
        if !q.point.isEmpty && q.point != "vocab" {
            var p = points[q.point] ?? [0, 0]; p[1] += 1; if correct { p[0] += 1 }; points[q.point] = p
        }
        let sk = q.point == "vocab" && skill == "grammar" ? "vocab" : skill
        var s = skills[sk] ?? [0, 0]; s[1] += 1; if correct { s[0] += 1 }; skills[sk] = s
    }

    static func key(_ date: Date = Date()) -> String {
        let f = DateFormatter(); f.calendar = Calendar(identifier: .gregorian); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    /// Today's three tasks (they rotate day by day so it does not get stale).
    func menu(for date: Date = Date()) -> [StudyMode] {
        let n = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        let second: StudyMode = [.order, .listening, .speak][n % 3]
        let third: StudyMode = weak.isEmpty ? .flash : .review
        return [.dictation, second, third]
    }
    func finished(_ m: StudyMode, on date: Date = Date()) -> Bool { done[StudyLog.key(date)]?.contains(m.rawValue) == true }
    func stamped(_ date: Date) -> Bool { let k = StudyLog.key(date); return menu(for: date).allSatisfy { done[k]?.contains($0.rawValue) == true } || (done[k]?.count ?? 0) >= 3 }

    /// consecutive days with at least one finished task (today may still be open)
    var streak: Int {
        let cal = Calendar.current
        var d = Date(); var n = 0
        if done[StudyLog.key(d)]?.isEmpty ?? true { d = cal.date(byAdding: .day, value: -1, to: d)! }
        while !(done[StudyLog.key(d)]?.isEmpty ?? true) { n += 1; d = cal.date(byAdding: .day, value: -1, to: d)! }
        return n
    }

    /// next title and how many more correct answers it takes
    var rankNext: (String, Int)? {
        let steps: [(Int, String)] = [(50, T("ことばの ひよこ", "말의 병아리", "語言小雞")), (200, T("ことば見習い", "말 견습생", "語言見習生")),
                                      (500, T("ことば使い", "말 사용자", "語言使者")), (1000, T("ことばマスター", "말 마스터", "語言大師")),
                                      (2000, T("ワーディアの英雄", "워디아의 영웅", "沃迪亞英雄"))]
        guard let n = steps.first(where: { totalCorrect < $0.0 }) else { return nil }
        return (n.1, n.0 - totalCorrect)
    }

    var rankTitle: String {
        switch totalCorrect {
        case ..<50: T("ことばの たまご", "말의 알", "語言之蛋")
        case ..<200: T("ことばの ひよこ", "말의 병아리", "語言小雞")
        case ..<500: T("ことば見習い", "말 견습생", "語言見習生")
        case ..<1000: T("ことば使い", "말 사용자", "語言使者")
        case ..<2000: T("ことばマスター", "말 마스터", "語言大師")
        default: T("ワーディアの英雄", "워디아의 영웅", "沃迪亞英雄")
        }
    }

    mutating func answered(correct: Bool) {
        days[StudyLog.key(), default: 0] += 1
        if correct { totalCorrect += 1 }
    }
    mutating func finish(_ m: StudyMode) {
        let k = StudyLog.key()
        if done[k]?.contains(m.rawValue) != true { done[k, default: []].append(m.rawValue) }
    }
    mutating func recordMiss(_ q: Question) {
        weakTouched[q.full] = CloudSync.now
        if let i = weak.firstIndex(where: { $0.q.full == q.full }) { weak[i].miss += 1; weak[i].last = StudyLog.key() }
        else { weak.append(.init(q: q, miss: 1, last: StudyLog.key())) }
        if weak.count > 120 { weak.removeFirst(weak.count - 120) }
    }
    /// answered right in review: one step closer to being cleared
    mutating func recordHit(_ q: Question) {
        guard let i = weak.firstIndex(where: { $0.q.full == q.full }) else { return }
        weakTouched[q.full] = CloudSync.now
        weak[i].miss -= 1
        if weak[i].miss <= 0 { weak.remove(at: i) }
    }

    private static let url: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("study.json")
    }()
    static func load() -> StudyLog {
        if let d = try? Data(contentsOf: url), let s = try? JSONDecoder().decode(StudyLog.self, from: d) { return s }
        return StudyLog()
    }
    func save() { writeLocal(); CloudSync.put(self, "study") }
    func writeLocal() { if let d = try? JSONEncoder().encode(self) { try? d.write(to: StudyLog.url, options: .atomic) } }
}

enum StudyMode: String, CaseIterable, Identifiable {
    case dictation, order, listening, speak, sounds, review, flash, toeic, toeicMock
    var id: String { rawValue }
    /// tile label: long names on two lines so the letters stay big
    var tileTitle: String {
        switch self {
        case .speak: T("発音\nチャレンジ", "발음\n챌린지", "發音\n挑戰")
        case .flash: T("60秒\nチャレンジ", "60초\n챌린지", "60秒\n挑戰")
        default: jp(title)
        }
    }
    var title: String {
        switch self {
        case .dictation: T("書き取り", "받아쓰기", "聽寫")
        case .order: T("ならべかえ", "순서 맞추기", "重組句子")
        case .listening: T("リスニング", "리스닝", "聽力")
        case .speak: T("発音チャレンジ", "발음 챌린지", "發音挑戰")
        case .sounds: T("にがて音", "어려운 소리", "難發的音")
        case .review: T("にがて復習", "약점 복습", "弱點複習")
        case .flash: T("60秒チャレンジ", "60초 챌린지", "60秒挑戰")
        case .toeic: "TOEIC Part 5"
        case .toeicMock: T("TOEIC模試", "TOEIC 모의고사", "TOEIC模擬考")
        }
    }
    var note: String {
        switch self {
        case .dictation: T("聞いて|書こう", "듣고 써 보자", "聽了寫下來")
        case .order: T("単語を|正しく|並べよう", "단어를 바르게 배열하자", "把單字排好")
        case .listening: T("意味を|聞き取ろう", "뜻을 알아듣자", "聽懂意思")
        case .speak: T("声に出して|通じるか|チェック", "소리 내어 통하는지 체크", "念出來看看能不能聽懂")
        case .sounds: T("L/R・TH など|言い分け|練習", "L/R·TH 등 구별 연습", "練習分辨L/R、TH等")
        case .review: T("まちがえた|問題を|もう一度", "틀린 문제를 다시", "再挑戰錯題")
        case .flash: T("どこまで|解ける？", "몇 문제나 풀까?", "能答幾題？")
        case .toeic: T("ビジネス英語の|穴うめ|10問", "비즈니스 영어 빈칸 10문제", "商務英文填空10題")
        case .toeicMock: T("30問・10分で|スコア目安", "30문제·10분 점수 예상", "30題・10分鐘估分")
        }
    }
    var icon: String {
        switch self { case .dictation: "pencil.and.scribble"; case .order: "square.grid.3x1.below.line.grid.1x2"; case .listening: "ear.fill"; case .speak: "mic.fill"; case .sounds: "mouth.fill"; case .review: "arrow.counterclockwise.circle.fill"; case .flash: "bolt.fill"; case .toeic: "briefcase.fill"; case .toeicMock: "timer" }
    }
    /// background music while practising
    var track: String {
        switch self {
        case .toeic, .toeicMock: "study_toeic"
        case .dictation, .order, .listening, .speak, .sounds: "study_c"
        case .flash, .review: "study_a"
        }
    }
    /// sticker picture on the study screen
    var art: String {
        switch self {
        case .dictation: "st_dictation"; case .order: "st_order"; case .listening: "st_listening"; case .speak: "st_speak"
        case .sounds: "st_sounds"; case .review: "st_review"; case .flash: "st_flash"; case .toeic, .toeicMock: "st_toeic"
        }
    }
    var color: Color {
        switch self { case .dictation: .sky; case .order: .sun; case .listening: .pop; case .speak: Color(hex: 0x8FE3D0); case .sounds: Color(hex: 0xFFC4E1); case .review: .grape; case .flash: .mint; case .toeic: Color(hex: 0xFFB86B); case .toeicMock: Color(hex: 0xFF9F8A) }
    }
    /// number of questions in one session
    var count: Int {
        switch self { case .flash: 999; case .toeic: 10; case .toeicMock: 30; case .dictation, .order, .listening, .speak: 10; default: 5 }
    }
    /// practice that starts from a level (Lv1–6) picker
    var hasLevels: Bool { self == .dictation || self == .order || self == .listening || self == .speak }
}

// MARK: - Question source

@MainActor
enum StudyPool {
    /// every question from the areas the player can reach (Lv1 always)
    /// level chosen in the study level picker (nil = every reachable area)
    static var level: Area?
    /// review only this grammar point (opened from a textbook page)
    static var point: String?
    static func all(_ app: AppState) -> [Question] {
        var out: [Question] = []
        for a in Area.allCases where (level.map { $0 == a } ?? app.isUnlocked(a)) {
            let p = QuestionBank.pools(for: a)
            out += p.single + p.phrase + p.order + p.mid + p.boss
        }
        var seen = Set<String>()
        return out.filter { seen.insert($0.full).inserted }
    }
    static func sentences(_ app: AppState) -> [Question] {
        all(app).filter { let n = $0.full.split(separator: " ").count; return n >= 3 && n <= 11 }
    }
    static func pick(_ mode: StudyMode, _ app: AppState) -> [Question] {
        switch mode {
        case .review:
            if let p = point {
                return Array(app.study.weak.filter { $0.q.point == p }.map(\.q).shuffled().prefix(10))
            }
            let w = app.study.weak.sorted { $0.miss > $1.miss }.prefix(8).map(\.q)
            return Array(w.shuffled().prefix(5))
        case .flash:
            return all(app).filter { $0.kind != .order && !$0.choices.isEmpty }.shuffled()
        case .toeic, .toeicMock:
            return ToeicBank.session(mode.count)
        default:
            return Array(sentences(app).shuffled().prefix(mode.count))
        }
    }
}

// MARK: - Study home: streak, stamp calendar, today's menu

struct StudyHomeView: View {
    @EnvironmentObject var app: AppState
    @State private var mode: StudyMode?
    @State private var month = Date()
    @State private var showCard = false
    @State private var stamped = false
    /// stamp tool animation: 0 hidden, 1 raised above the cell, 2 pressed down, 3 lifted away
    @State private var tool = 0
    @State private var showBook = false
    @State private var showDict = false
    @State private var showToeic = false
    @State private var toeicRun: ToeicRunView.Mode?
    @State private var levelFor: StudyMode?   // level picker shown for this mode
    @State private var confirmRestart = false
    @State private var tick = 0   // redraws the TOEIC menu after the saved test is removed
    @State private var toeicReport: ToeicResult?

    var body: some View {
        ZStack {
            SubScreen(title: L("home.study"), color: .mintDeep, bg: Color(hex: 0x9BE8CB)) {
                // everything on one screen — no long scrolling page
                VStack(spacing: 10.s) {
                    statusStrip
                    VocabCard()
                    todayStrip
                    libraryCard
                    practiceGrid
                        .frame(maxHeight: .infinity)
                }
                .padding(.horizontal, 14).padding(.top, 2).padding(.bottom, 10)
            }
            if showCard { stampCard.zIndex(3).transition(.opacity) }
            if showToeic {
                toeicPicker.zIndex(3).transition(.opacity)
                    .alert(T("保存中の模試は消えます。よろしいですか？", "저장 중인 모의고사가 삭제됩니다. 괜찮을까요?", "儲存中的模擬考將被刪除，確定嗎？"), isPresented: $confirmRestart) {
                        Button(T("消して最初から", "삭제하고 처음부터", "刪除並重新開始"), role: .destructive) { withAnimation { ToeicStore.mock = nil; tick += 1 } }
                        Button(T("キャンセル", "취소", "取消"), role: .cancel) {}
                    } message: {
                        Text(T("これまでの答えと残り時間は元に戻せません。", "지금까지의 답과 남은 시간은 되돌릴 수 없습니다.", "目前的答案與剩餘時間無法復原。"))
                    }
            }
            if let levelFor { levelPicker(levelFor).zIndex(3).transition(.opacity) }
            if let mode {
                Group {
                    switch mode {
                    case .speak: SpeakSessionView { back(from: mode) }
                    case .sounds: SoundsView { back(from: mode) }
                    default: StudySessionView(mode: mode) { back(from: mode) }
                    }
                }
                .geometryGroup()
                .transition(.move(edge: .trailing))
                .zIndex(2)
            }
            if let toeicRun {
                ToeicRunView(mode: toeicRun) { withAnimation { self.toeicRun = nil; showToeic = true } }
                    .id(String(describing: toeicRun))
                    .geometryGroup().transition(.move(edge: .trailing)).zIndex(2)
            }
            if let toeicReport {
                ToeicReportView(result: toeicReport) { withAnimation { self.toeicReport = nil; showToeic = true } }
                    .geometryGroup().transition(.move(edge: .trailing)).zIndex(2)
            }
        }
        .animation(.easeOut(duration: 0.25), value: mode)
        .animation(.easeOut(duration: 0.25), value: showCard)
        // free version: banner at the bottom, and a full-screen ad now and then after a session
        .safeAreaInset(edge: .bottom, spacing: 0) { if mode == nil { AdBannerSlot() } }
        .onChange(of: mode) { old, new in if old != nil && new == nil { AdManager.shared.roundFinished() } }
        .onAppear {
            AudioManager.shared.playBGM(.study)
            Task { await AdManager.shared.start() }
            // first visit of the day: show the stamp card and press today's stamp
            let k = StudyLog.key()
            if !app.study.visits.contains(k) {
                app.study.visits.append(k); app.study.save()
                stamped = false; tool = 0; showCard = true
                later(0.5) { withAnimation(.easeOut(duration: 0.35)) { tool = 1 } }            // the stamp comes in
                later(1.05) { withAnimation(.easeIn(duration: 0.12)) { tool = 2 } }            // ...and presses down
                later(1.17) {
                    AudioManager.shared.se(.hitSmall, rate: 0.8, volume: 0.9)
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    stamped = true
                }
                later(1.5) { withAnimation(.easeOut(duration: 0.35)) { tool = 3 } }             // lift it away
                later(1.9) { tool = 0 }
            }
        }
    }

    private var header: some View { topCard }

    // MARK: one-screen layout

    /// Nyan, the streak, the word-power title and the stamp calendar button, in one line
    private var statusStrip: some View {
        HStack(spacing: 10.s) {
            // iPad: Nyan and the streak twice as big
            let k: CGFloat = UIScale.isPad ? 2 : 1
            Image("nyan").resizable().scaledToFit().frame(height: 46.s * k)
                .modifier(LonelyLook(mood: Absence.mood(app), size: 46.s * k))
            HStack(alignment: .firstTextBaseline, spacing: 3 * k) {
                UIIcon("ui_fire|🔥", size: 22.s * k)
                Text("\(app.study.streak)").font(.en(22.s * k)).foregroundStyle(Color.popDeep)
                Text(jp(T("日|連続", "일 연속", "天連續"))).font(.ui(13.s * k)).foregroundStyle(Color.ink)
            }
            Spacer(minLength: 0)
            Button { AudioManager.shared.se(.decide); stamped = true; tool = 0; showCard = true } label: {
                VStack(spacing: 1) {
                    Image(systemName: "calendar").font(.system(size: 20.s, weight: .black))
                    Text(jp(T("スタンプ", "도장", "印章"))).font(.ui(11.s))
                }
                .foregroundStyle(Color.ink)
                .frame(width: 62.s, height: 50.s)
                .background(RoundedRectangle(cornerRadius: 14.s).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 14.s).stroke(Color.ink, lineWidth: 2.5)))
            }
            .buttonStyle(PressStyle(radius: 14.s, depth: 4))
        }
    }

    /// today's three items as big icon buttons; a check when done
    private var todayStrip: some View {
        let menu = app.study.menu()
        let doneN = menu.filter { app.study.finished($0) }.count
        return HStack(spacing: 10.s) {
            VStack(alignment: .leading, spacing: 2.s) {
                Text(jp(T("きょうの|メニュー", "오늘의 메뉴", "今日菜單"))).font(.display(16.s)).foregroundStyle(Color.ink)
                    .lineLimit(2).minimumScaleFactor(0.7)
                if doneN == menu.count { UIIcon("ui_hanamaru|💮", size: 24.s) }
                else { Text("\(doneN)/\(menu.count)").font(.en(20.s)).foregroundStyle(Color.ink) }
            }
            .frame(width: 92.s, alignment: .leading)
            ForEach(menu) { m in
                let done = app.study.finished(m)
                Button { AudioManager.shared.se(.decide); open(m) } label: {
                    // same icon box and same label box on every tile, so all three line up
                    VStack(spacing: 2.s) {
                        Image(m.art).resizable().scaledToFit().frame(width: 40.s, height: 40.s)
                        Text(m.tileTitle).font(.ui(11.s)).foregroundStyle(Color.ink).lineLimit(2).multilineTextAlignment(.center).minimumScaleFactor(0.6)
                            .padding(.horizontal, 5.s)
                            .frame(maxWidth: .infinity).frame(height: 34.s)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 6.s)
                    .background(RoundedRectangle(cornerRadius: 14.s).fill(done ? Color(hex: 0xE8FFF5) : Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 14.s).stroke(Color.ink, lineWidth: 2.5)))
                    .overlay(alignment: .topTrailing) {
                        if done {
                            Image(systemName: "checkmark.circle.fill").font(.system(size: 18.s, weight: .black))
                                .foregroundStyle(Color.mintDeep).background(Circle().fill(.white)).offset(x: 5, y: -5)
                        }
                    }
                }
                .buttonStyle(PressStyle(radius: 14.s, depth: 4))
            }
        }
        .padding(10.s)
        .background(RoundedRectangle(cornerRadius: 18.s).fill(Color.paper).overlay(RoundedRectangle(cornerRadius: 18.s).stroke(Color.ink, lineWidth: 3)))
    }

    /// 7 practice modes + TOEIC, 4 x 2, each with its own picture
    private var practiceGrid: some View {
        let modes: [StudyMode] = [.dictation, .order, .listening, .speak, .sounds, .review, .flash]
        return GeometryReader { g in
            let gap = 8.s
            let w = (g.size.width - gap * 3) / 4
            let h = min((g.size.height - gap) / 2, w * 1.5)
            VStack(spacing: gap) {
                HStack(spacing: gap) { ForEach(modes.prefix(4)) { practiceTile($0, w: w, h: h) } }
                HStack(spacing: gap) {
                    ForEach(modes.suffix(3)) { practiceTile($0, w: w, h: h) }
                    toeicTile(w: w, h: h)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func practiceTile(_ m: StudyMode, w: CGFloat, h: CGFloat) -> some View {
        let disabled = m == .review && app.study.weak.isEmpty
        return Button { AudioManager.shared.se(.decide); open(m) } label: {
            Group {
                if h < w * 0.8 {
                    // short, wide tiles (iPad landscape): picture on the left, name on the right
                    HStack(spacing: 4.s) {
                        Image(m.art).resizable().scaledToFit().frame(maxWidth: w * 0.36, maxHeight: h * 0.8)
                        VStack(spacing: 1) {
                            // one line here: the tile is too short for two
                            Text(m.title).font(.ui(14.s)).foregroundStyle(Color.ink)
                                .lineLimit(1).minimumScaleFactor(0.4)
                            practiceSub(m)
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    VStack(spacing: 3.s) {
                        // tiles with a second line (BEST / count) get a smaller picture so the name fits whole
                        Image(m.art).resizable().scaledToFit().frame(maxHeight: h * (m == .flash || m == .review ? 0.38 : 0.5))
                        Text(m.tileTitle).font(.ui(14.s)).foregroundStyle(Color.ink)
                            .lineLimit(2).multilineTextAlignment(.center).minimumScaleFactor(0.5)
                        practiceSub(m)
                    }
                }
            }
            .padding(6.s)
            .frame(width: w, height: h)
            .background(RoundedRectangle(cornerRadius: 16.s).fill(m.color.opacity(0.55)).overlay(RoundedRectangle(cornerRadius: 16.s).fill(Color.white.opacity(0.35)).padding(4)))
            .overlay(RoundedRectangle(cornerRadius: 16.s).stroke(Color.ink, lineWidth: 2.5))
            .opacity(disabled ? 0.45 : 1)
        }
        .buttonStyle(PressStyle(radius: 16.s, depth: 4))
        .disabled(disabled)
    }

    @ViewBuilder private func practiceSub(_ m: StudyMode) -> some View {
        if m == .flash, let b = app.study.best["flash"] { Text("BEST \(b)").font(.en(11.s)).foregroundStyle(Color.ink.opacity(0.7)).lineLimit(1).minimumScaleFactor(0.6) }
        if m == .review { Text("\(app.study.weak.count)").font(.en(11.s)).foregroundStyle(Color.ink.opacity(0.7)).lineLimit(1).minimumScaleFactor(0.6) }
    }

    /// TOEIC gets one tile of its own (business navy), which opens Part 5 and the mock test
    private func toeicTile(w: CGFloat, h: CGFloat) -> some View {
        Button { AudioManager.shared.se(.decide); showToeic = true } label: {
            let pic = Image("st_toeic").resizable().scaledToFit()
                .overlay(alignment: .bottomTrailing) {
                    if !app.toeicUnlocked { Image(systemName: "lock.fill").font(.system(size: 14.s, weight: .black)).foregroundStyle(Color.sun) }
                }
            let words = VStack(spacing: 1) {
                Text("TOEIC").font(.en(16.s)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.6)
                VStack(spacing: 0) {
                    Text("Part 1〜7").lineLimit(1).minimumScaleFactor(0.5)
                    Text(T("模試200問", "모의고사 200문제", "模擬考200題")).lineLimit(1).minimumScaleFactor(0.5)
                }
                .font(.ui(11.s)).foregroundStyle(.white.opacity(0.9))
            }
            let wordsShort = VStack(spacing: 1) {
                Text("TOEIC").font(.en(16.s)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.5)
                Text("Part 1〜7・" + T("模試200問", "모의고사 200문제", "模擬考200題"))
                    .font(.ui(11.s)).foregroundStyle(.white.opacity(0.9)).lineLimit(1).minimumScaleFactor(0.4)
            }
            Group {
                if h < w * 0.8 {
                    HStack(spacing: 4.s) { pic.frame(maxWidth: w * 0.3, maxHeight: h * 0.7); wordsShort.frame(maxWidth: .infinity) }
                } else {
                    VStack(spacing: 3.s) { pic.frame(maxHeight: h * 0.38); words }
                }
            }
            .padding(6.s)
            .frame(width: w, height: h)
            .background(RoundedRectangle(cornerRadius: 16.s).fill(LinearGradient(colors: [Color(hex: 0x2E4A8C), Color(hex: 0x1E2F5E)], startPoint: .top, endPoint: .bottom)))
            .overlay(RoundedRectangle(cornerRadius: 16.s).stroke(Color.ink, lineWidth: 2.5))
        }
        .buttonStyle(PressStyle(radius: 16.s, depth: 4))
    }

    private func mockRow(icon: String, title: String, note: String, locked: Bool, keepOpen: Bool = false, _ go: @escaping () -> Void) -> some View {
        Button {
            AudioManager.shared.se(.decide)
            // locked: open the premium (purchase) screen instead of doing nothing
            if locked { app.sheet = .shop; return }
            if !keepOpen { showToeic = false }; withAnimation { go() }
        } label: {
            HStack(spacing: 12.s) {
                Image(systemName: locked ? "lock.fill" : icon).font(.system(size: 20.s, weight: .black)).foregroundStyle(Color.ink)
                    .frame(width: 44.s, height: 44.s).background(Circle().fill(Color(hex: 0xFF9F8A)).overlay(Circle().stroke(Color.ink, lineWidth: 2.5)))
                VStack(alignment: .leading, spacing: 2) {
                    Text(jp(title)).font(.ui(16.s)).foregroundStyle(Color.ink)
                    Text(jp(locked ? T("ゲームの|最後の|卒業試験|（サイレンス城）を|クリアか、|プレミアムで|解放", "게임 마지막 졸업 시험(사일런스 성)을 클리어하거나 프리미엄으로 해금", "通關遊戲最後的畢業考（沉默城）或高級版解鎖") : note))
                        .font(.ui(11.s, bold: false)).foregroundStyle(Color.ink.opacity(0.65)).fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(10.s)
            .background(RoundedRectangle(cornerRadius: 16.s).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 16.s).stroke(Color.ink, lineWidth: 2.5)))
            .opacity(locked ? 0.6 : 1)
        }
        .buttonStyle(PressStyle(radius: 16.s, depth: 4))
    }

    /// level modes open the Lv1–6 picker first; the rest start right away
    private func open(_ m: StudyMode) {
        if m.hasLevels { withAnimation { levelFor = m } } else { StudyPool.level = nil; mode = m }
    }

    /// back from a session: to the picker it came from
    private func back(from m: StudyMode) {
        withAnimation {
            mode = nil
            if m == .toeic || m == .toeicMock { showToeic = true }
            else if m.hasLevels { levelFor = m }
        }
        StudyPool.level = nil
    }

    private func levelPicker(_ m: StudyMode) -> some View {
        ZStack {
            Color.ink.opacity(0.55).ignoresSafeArea().onTapGesture { withAnimation { levelFor = nil } }
            VStack(spacing: 10.s) {
                HStack(spacing: 10.s) {
                    Image(m.art).resizable().scaledToFit().frame(height: 48.s)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(jp(m.title)).font(.display(22.s)).foregroundStyle(Color.ink)
                        Text(jp(T("レベルを|選ぼう。|1回|\(m.count)問", "레벨을 고르자. 1회 \(m.count)문제", "選擇等級。每次\(m.count)題", vi: "Chọn cấp độ. Mỗi lượt \(m.count) câu", es: "Elige un nivel. \(m.count) preguntas por ronda", pt: "Escolha um nível. \(m.count) perguntas por rodada", en: "Pick a level. \(m.count) questions per round"))).font(.ui(12.s)).foregroundStyle(Color.ink.opacity(0.7))
                    }
                    Spacer(minLength: 0)
                }
                let areas: [Area] = [.lv1, .lv2, .lv3, .lv4, .lv5, .lv6]
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8.s), GridItem(.flexible(), spacing: 8.s)], spacing: 8.s) {
                    ForEach(areas, id: \.self) { a in
                        Button {
                            AudioManager.shared.se(.decide)
                            StudyPool.level = a
                            withAnimation { levelFor = nil; mode = m }
                        } label: {
                            VStack(alignment: .leading, spacing: 4.s) {
                                Text(a.levelLabel).font(.en(17.s)).foregroundStyle(.white)
                                    .padding(.horizontal, 10.s).padding(.vertical, 1)
                                    .background(Capsule().fill(Color.ink))
                                Text(jp(a.grammarHint)).font(.ui(12.s)).foregroundStyle(Color.ink)
                                    .lineLimit(3).minimumScaleFactor(0.7).multilineTextAlignment(.leading)
                                Spacer(minLength: 0)
                            }
                            // every level tile is the same size so the grid lines up
                            .frame(maxWidth: .infinity, minHeight: 92.s, maxHeight: 92.s, alignment: .topLeading)
                            .padding(.horizontal, 10.s).padding(.vertical, 8.s)
                            .background(RoundedRectangle(cornerRadius: 14.s).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 14.s).stroke(Color.ink, lineWidth: 2.5)))
                        }
                        .buttonStyle(PressStyle(radius: 14.s, depth: 3))
                    }
                }
                PopButton(title: L("common.back"), color: .white, height: 46) { withAnimation { levelFor = nil } }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 24).fill(Color(hex: 0xFFFBF2)).overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.ink, lineWidth: 4)))
            .frame(maxWidth: 460.s)
            .padding(.horizontal, 14)
        }
    }

    /// TOEIC Part 5 and the mock test, side by side
    private var toeicPicker: some View {
        ZStack {
            Color.ink.opacity(0.55).ignoresSafeArea().onTapGesture { showToeic = false }
            // scrolls only when the panel is taller than the screen (small iPhones)
            ViewThatFits(in: .vertical) {
                toeicPanelBody.padding(16)
                ScrollView { toeicPanelBody.padding(16) }
            }
            .background(RoundedRectangle(cornerRadius: 24).fill(Color(hex: 0x2E4A8C)).overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.ink, lineWidth: 4)))
            .frame(maxWidth: 460.s)
            .padding(.horizontal, 14)
            .padding(.vertical, 24)
        }
    }

    @ViewBuilder private var toeicPanelBody: some View {
        VStack(spacing: 12.s) {
            HStack(spacing: 10.s) {
                Image("st_toeic").resizable().scaledToFit().frame(height: 48.s)
                VStack(alignment: .leading, spacing: 2) {
                    Text("TOEIC").font(.en(24.s)).foregroundStyle(.white)
                    Text(jp(T("ビジネス英語で|力だめし", "비즈니스 영어로 실력 체크", "用商務英文測實力"))).font(.ui(12.s)).foregroundStyle(.white.opacity(0.85))
                }
                Spacer(minLength: 0)
                // back sits at the top, where people look first (it was easy to miss at the bottom)
                Button { AudioManager.shared.se(.tap); showToeic = false } label: {
                    Label(L("common.back"), systemImage: "xmark").font(.ui(14.s)).foregroundStyle(Color.ink)
                        .lineLimit(1).fixedSize()
                        .padding(.horizontal, 12.s).padding(.vertical, 8.s)
                        .background(Capsule().fill(Color.white).overlay(Capsule().stroke(Color.ink, lineWidth: 2.5)))
                }
                .buttonStyle(.plain)
            }
            let locked = !app.toeicUnlocked
            // parts 2–7: part 5 keeps the quick drill, the others use the full test engine
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8.s), count: 3), spacing: 8.s) {
                ForEach(ToeicTest.parts, id: \.self) { p in
                    Button {
                        AudioManager.shared.se(.decide)
                        if locked { app.sheet = .shop; return }
                        showToeic = false
                        withAnimation { if p == 5 { mode = .toeic } else { toeicRun = .practice(p) } }
                    } label: {
                        VStack(spacing: 2) {
                            Text("Part \(p)").font(.en(18.s)).foregroundStyle(Color.ink)
                            Text(jp(ToeicTest.name(p).components(separatedBy: " ").last ?? "")).font(.ui(11.s)).foregroundStyle(Color.ink.opacity(0.7))
                                .lineLimit(1).minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 10.s)
                        .background(RoundedRectangle(cornerRadius: 14.s).fill(p <= 4 ? Color(hex: 0xBFD7FF) : Color(hex: 0xFFE3B0)).overlay(RoundedRectangle(cornerRadius: 14.s).stroke(Color.ink, lineWidth: 2.5)))
                    }
                    .buttonStyle(PressStyle(radius: 14.s, depth: 3))
                }
            }
            .opacity(locked ? 0.6 : 1)
            // mock tests (pause and resume): the real-size test and a half-size one
            let _ = tick
            if let saved = ToeicStore.mock {
                mockRow(icon: "play.fill", title: T("模試の|つづきから", "모의고사 이어서", "繼續模擬考"),
                        note: T("\(saved.index + 1)問目から・|残り|時間も|保存|されています", "\(saved.index + 1)번부터 · 남은 시간도 저장됨", "從第\(saved.index + 1)題開始・剩餘時間也已儲存", vi: "Từ câu \(saved.index + 1) · thời gian còn lại cũng đã lưu", es: "Desde la pregunta \(saved.index + 1) · también se guardó el tiempo restante", pt: "A partir da questão \(saved.index + 1) · o tempo restante também foi salvo", en: "From question \(saved.index + 1) · time left is saved too"),
                        locked: locked) { toeicRun = .mock(full: saved.full ?? false) }
                mockRow(icon: "arrow.counterclockwise", title: T("模試を|最初から|やり直す", "모의고사 처음부터 다시", "模擬考重新開始"),
                        note: T("中断中の|模試は|消えます", "중단한 모의고사는 삭제됩니다", "中斷的模擬考會被刪除"),
                        locked: locked, keepOpen: true) { confirmRestart = true }
            } else {
                mockRow(icon: "timer", title: T("本格模試", "실전 모의고사", "正式模擬考"),
                        note: T("本番と|同じ|200問・2時間。|中断して|保存できます", "실전과 같은 200문제·2시간 · 중단 저장 가능", "與正式考試相同的200題・2小時・可中斷儲存"),
                        locked: locked) { toeicRun = .mock(full: true) }
                mockRow(icon: "hourglass", title: T("ハーフ模試", "하프 모의고사", "半份模擬考"),
                        note: T("約100問・1時間。|時間が|ない|日に", "약 100문제·1시간 · 시간이 없을 때", "約100題・1小時・時間不多時"),
                        locked: locked) { toeicRun = .mock(full: false) }
            }
            // extra tools as one row of small tiles, so the whole panel fits on the screen without scrolling
            let weakIDs = locked ? [] : ToeicTest.weakMock(ToeicTest.weakTags())
            let wrong = locked ? [] : ToeicStore.wrong
            let last = ToeicStore.results.last
            if !weakIDs.isEmpty || !wrong.isEmpty || last != nil {
                HStack(spacing: 8.s) {
                    if !weakIDs.isEmpty {
                        toolTile(icon: "target", title: T("にがて|ミニ模試", "약점\n미니 모의고사", "弱點\n迷你模擬考"), badge: nil, color: Color(hex: 0xFFC9DD)) {
                            toeicRun = .review(weakIDs)
                        }
                    }
                    if !wrong.isEmpty {
                        toolTile(icon: "arrow.uturn.backward.circle.fill", title: T("まちがい|解き直し", "틀린 문제\n다시 풀기", "重做\n答錯題目"), badge: "\(wrong.count)", color: Color(hex: 0xBFEBD6)) {
                            toeicRun = .review(Array(wrong.prefix(10)))
                        }
                    }
                    if let last {
                        toolTile(icon: "chart.bar.xaxis", title: T("前回の|分析・記録", "지난\n분석·기록", "上次\n分析・紀錄"), badge: "\(last.total)", color: Color.sun) {
                            toeicReport = last
                        }
                    }
                }
            }
        }
    }

    private func toolTile(icon: String, title: String, badge: String?, color: Color, action: @escaping () -> Void) -> some View {
        Button { AudioManager.shared.se(.decide); showToeic = false; withAnimation { action() } } label: {
            VStack(spacing: 3.s) {
                HStack(spacing: 4) {
                    Image(systemName: icon).font(.system(size: 15.s, weight: .bold))
                    if let badge { Text(badge).font(.en(14.s)) }
                }
                Text(jp(title)).font(.ui(12.s)).multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.7)
            }
            .foregroundStyle(Color.ink)
            .frame(maxWidth: .infinity, minHeight: 58.s).padding(.horizontal, 4)
            .background(RoundedRectangle(cornerRadius: 14.s).fill(color).overlay(RoundedRectangle(cornerRadius: 14.s).stroke(Color.ink, lineWidth: 2.5)))
        }
        .buttonStyle(PressStyle(radius: 14.s, depth: 3))
    }

    private var headerRow: some View {
        HStack(spacing: 12.s) {
            Image("nyan").resizable().scaledToFit().frame(height: 54.s)
            VStack(alignment: .leading, spacing: 4.s) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    UIIcon("ui_fire|🔥", size: 20.s)
                    Text("\(app.study.streak)").font(.en(26.s)).foregroundStyle(Color.popDeep)
                    Text(jp(T("日|連続", "일 연속", "天連續"))).font(.ui(15.s)).foregroundStyle(Color.ink)
                }
                // word-power title: grows with the number of correct answers
                HStack(spacing: 6) {
                    Text(jp(T("ことば力", "말의 힘", "語言力"))).font(.ui(11.s)).foregroundStyle(Color.ink.opacity(0.6))
                    Text(jp(app.study.rankTitle)).font(.ui(14.s)).foregroundStyle(Color.ink)
                        .padding(.horizontal, 10.s).padding(.vertical, 3.s)
                        .background(Capsule().fill(Color.sun).overlay(Capsule().stroke(Color.ink, lineWidth: 2)))
                }
                if let nx = app.study.rankNext {
                    Text(jp(T("あと|\(nx.1)問|正解で|「\(nx.0)」", "앞으로 \(nx.1)문제 맞히면 「\(nx.0)」", "再答對\(nx.1)題升級為「\(nx.0)」", vi: "Đúng thêm \(nx.1) câu để lên “\(nx.0)”", es: "\(nx.1) aciertos más para “\(nx.0)”", pt: "Mais \(nx.1) acertos para “\(nx.0)”", en: "\(nx.1) more correct for “\(nx.0)”")))
                        .font(.ui(11.s, bold: false)).foregroundStyle(Color.ink.opacity(0.6))
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.bottom, 4.s)
    }

    /// Top of the study screen: streak + title, then this month's stamp calendar.
    private var topCard: some View {
        VStack(spacing: 8.s) {
            headerRow
            calendar
        }
    }

    private var todayCard: some View {
        let menu = app.study.menu()
        let doneN = menu.filter { app.study.finished($0) }.count
        return PaperCard {
            VStack(alignment: .leading, spacing: 10.s) {
                HStack {
                    Text(jp(T("きょうの|メニュー", "오늘의 메뉴", "今日菜單"))).font(.display(20.s)).foregroundStyle(Color.ink)
                    Spacer()
                    Text("\(doneN)/\(menu.count)").font(.en(20.s)).foregroundStyle(doneN == menu.count ? Color.mintDeep : Color.ink)
                }
                ForEach(menu) { m in menuRow(m, done: app.study.finished(m)) }
                if doneN == menu.count {
                    HStack(spacing: 8) {
                        UIIcon("ui_hanamaru|💮", size: 28.s)
                        Text(jp(T("きょうの|はなまる|ゲット！|また|あしたね", "오늘의 꽃도장 획득! 내일 또 만나", "拿到今天的花丸！明天見"))).font(.ui(15.s)).foregroundStyle(Color.popDeep)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func menuRow(_ m: StudyMode, done: Bool) -> some View {
        Button { AudioManager.shared.se(.decide); open(m) } label: {
            HStack(spacing: 12.s) {
                Image(systemName: m.icon).font(.system(size: 20.s, weight: .black)).foregroundStyle(Color.ink)
                    .frame(width: 44.s, height: 44.s)
                    .background(Circle().fill(m.color).overlay(Circle().stroke(Color.ink, lineWidth: 2.5)))
                VStack(alignment: .leading, spacing: 1) {
                    Text(jp(m.title)).font(.ui(17.s)).foregroundStyle(Color.ink)
                    Text(jp(m.note)).font(.ui(12.s, bold: false)).foregroundStyle(Color.ink.opacity(0.6))
                }
                Spacer()
                Image(systemName: done ? "checkmark.seal.fill" : "play.circle.fill")
                    .font(.system(size: 26.s, weight: .bold)).foregroundStyle(done ? Color.mintDeep : Color.popDeep)
            }
            .padding(10.s)
            .background(RoundedRectangle(cornerRadius: 16.s).fill(done ? Color(hex: 0xE8FFF5) : Color.white).overlay(RoundedRectangle(cornerRadius: 16.s).stroke(Color.ink, lineWidth: 2.5)))
        }
        .buttonStyle(PressStyle(radius: 16.s, depth: 4))
    }

    private var calendar: some View {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: month)
        let first = cal.date(from: comps)!
        let days = cal.range(of: .day, in: .month, for: first)!.count
        let lead = (cal.component(.weekday, from: first) - cal.firstWeekday + 7) % 7
        let today = StudyLog.key()
        let cols = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        return PaperCard {
            VStack(spacing: 8.s) {
                HStack {
                    Button { month = cal.date(byAdding: .month, value: -1, to: month)! } label: { Image(systemName: "chevron.left.circle.fill") }
                    Spacer()
                    Text(verbatim: "\(comps.year!).\(comps.month!)").font(.en(20.s)).foregroundStyle(Color.ink)
                    Spacer()
                    Button { month = cal.date(byAdding: .month, value: 1, to: month)! } label: { Image(systemName: "chevron.right.circle.fill") }
                }
                .font(.system(size: 24.s)).foregroundStyle(Color.sky).buttonStyle(.plain)
                LazyVGrid(columns: cols, spacing: 4) {
                    ForEach(0..<(lead + days), id: \.self) { i in
                        if i < lead { Color.clear.frame(height: 38.s) }
                        else {
                            let d = cal.date(byAdding: .day, value: i - lead, to: first)!
                            let k = StudyLog.key(d)
                            let n = app.study.done[k]?.count ?? 0
                            ZStack {
                                RoundedRectangle(cornerRadius: 8).fill(k == today ? Color.sun.opacity(0.5) : Color.white)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.ink.opacity(0.25), lineWidth: 1.5))
                                if app.study.stamped(d) { UIIcon("ui_hanamaru|💮", size: 20.s) }
                                else if k == today && !stamped { EmptyView() }
                                else if app.study.visits.contains(k) || n > 0 {
                                    Image(systemName: "pawprint.fill").font(.system(size: 18.s)).foregroundStyle(Color.popDeep.opacity(0.85))
                                        .rotationEffect(.degrees(-12))
                                }
                                Text("\(i - lead + 1)").font(.en(11.s)).foregroundStyle(Color.ink.opacity(0.7))
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).padding(3)
                            }
                            .frame(height: 38.s)
                            .anchorPreference(key: TodayCellKey.self, value: .bounds) { k == today ? $0 : nil }
                        }
                    }
                }
            }
        }
    }

    /// Daily stamp card (shown on the first visit of the day, or from the header button).
    private var stampCard: some View {
        ZStack {
            Color.ink.opacity(0.55).ignoresSafeArea().onTapGesture { showCard = false }
            VStack(spacing: 12.s) {
                HStack(spacing: 8) {
                    Image("nyan").resizable().scaledToFit().frame(height: 60.s).modifier(Hop(amount: 4, period: 0.9))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(jp(Absence.mood(app) > 0 ? Absence.line(Absence.mood(app)) : T("きょうも|来たね！", "오늘도 왔구나!", "今天也來了！"))).font(.display(Absence.mood(app) > 0 ? 16.s : 20.s)).foregroundStyle(Color.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(jp(T("スタンプを|押したよ。|連続\(max(1, app.study.streak))日目", "도장을 찍었어. 연속 \(max(1, app.study.streak))일째", "蓋好章了。連續第\(max(1, app.study.streak))天", vi: "Đã đóng dấu! Chuỗi \(max(1, app.study.streak)) ngày", es: "¡Sello puesto! Racha de \(max(1, app.study.streak)) días", pt: "Carimbo feito! Sequência de \(max(1, app.study.streak)) dias", en: "Stamped! \(max(1, app.study.streak))-day streak")))
                            .font(.ui(13.s)).foregroundStyle(Color.ink.opacity(0.7))
                    }
                    Spacer(minLength: 0)
                }
                calendar
                    .overlayPreferenceValue(TodayCellKey.self) { a in
                        GeometryReader { g in
                            if let a, tool > 0 {
                                let r = g[a]
                                ZStack {
                                    if tool == 2 || (tool == 3 && stamped) {
                                        Circle().stroke(Color.popDeep.opacity(tool == 2 ? 0.6 : 0), lineWidth: 3)
                                            .frame(width: tool == 2 ? 40.s : 70.s, height: tool == 2 ? 40.s : 70.s)
                                            .position(x: r.midX, y: r.midY)
                                    }
                                    StampTool()
                                        .scaleEffect(tool == 2 ? CGSize(width: 1.08, height: 0.9) : CGSize(width: 1, height: 1), anchor: .bottom)
                                        .position(x: r.midX + (tool == 3 ? 40.s : 0), y: r.midY - 34.s - (tool == 1 ? 50.s : tool == 3 ? 90.s : 0))
                                        .opacity(tool == 3 ? 0 : 1)
                                }
                            }
                        }
                    }
                PopButton(title: T("きょうのメニューへ", "오늘의 메뉴로", "前往今日菜單"), color: .pop, textColor: .white) { showCard = false }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 26).fill(Color(hex: 0x9BE8CB)).overlay(RoundedRectangle(cornerRadius: 26).stroke(Color.ink, lineWidth: 4)))
            .frame(maxWidth: 460.s)
            .padding(.horizontal, 12)
        }
    }

    /// textbook (grammar lessons) and dictionary
    private var libraryCard: some View {
        HStack(spacing: 10.s) {
            libButton("ui_book", T("きょうほん", "교본", "教本"), T("文法を|まなぶ", "문법 배우기", "學文法"), Color(hex: 0xFFD66B)) { showBook = true }
            libButton("st_dict", T("じしょ", "사전", "辭典"), T("単語を|しらべる", "단어 찾기", "查單字"), Color(hex: 0x9FD8FF)) { showDict = true }
        }
        .sheet(isPresented: $showBook) { TextbookView().environmentObject(app) }
        .sheet(isPresented: $showDict) { DictionaryView().environmentObject(app) }
    }

    private func libButton(_ icon: String, _ title: String, _ sub: String, _ c: Color, _ action: @escaping () -> Void) -> some View {
        Button { AudioManager.shared.se(.decide); action() } label: {
            HStack(spacing: 8.s) {
                Image(icon).resizable().scaledToFit().frame(height: 40.s)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title.replacingOccurrences(of: "|", with: "")).font(.ui(16.s)).lineLimit(1).minimumScaleFactor(0.6)
                    Text(sub.replacingOccurrences(of: "|", with: "")).font(.ui(11.s, bold: false)).opacity(0.7)
                        .lineLimit(1).minimumScaleFactor(0.6)
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(Color.ink)
            // both buttons exactly the same size
            .padding(.horizontal, 10.s).frame(maxWidth: .infinity).frame(height: 62.s)
            .background(RoundedRectangle(cornerRadius: 16.s).fill(c).overlay(RoundedRectangle(cornerRadius: 16.s).stroke(Color.ink, lineWidth: 2.5)))
        }
        .buttonStyle(PressStyle(radius: 16.s, depth: 4))
    }

    private var freeCard: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 10.s) {
                PopHeading(text: T("じゆう|れんしゅう", "자유 연습", "自由練習"))
                let cols = [GridItem(.flexible()), GridItem(.flexible())]
                LazyVGrid(columns: cols, spacing: 10.s) {
                    ForEach(StudyMode.allCases) { m in
                        let locked = (m == .toeic || m == .toeicMock) && !app.toeicUnlocked
                        let disabled = (m == .review && app.study.weak.isEmpty) || locked
                        Button { AudioManager.shared.se(.decide); open(m) } label: {
                            VStack(spacing: 4.s) {
                                Image(systemName: locked ? "lock.fill" : m.icon).font(.system(size: 22.s, weight: .black))
                                Text(jp(m.title)).font(.ui(14.s)).lineLimit(1).minimumScaleFactor(0.6)
                                if m == .flash, let b = app.study.best["flash"] { Text("BEST \(b)").font(.en(11.s)) }
                                if m == .review { Text("\(app.study.weak.count)").font(.en(11.s)) }
                                if m == .toeicMock {
                                    if locked { Text(jp(T("卒業で|解放", "졸업하면 해금", "畢業後解鎖"))).font(.ui(11.s)) }
                                    else if let b = app.study.best["toeicMock"] { Text("BEST \(b)").font(.en(11.s)) }
                                }
                                if m == .toeic {
                                    if locked { Text(jp(T("卒業で|解放", "졸업하면 해금", "畢業後解鎖"))).font(.ui(11.s)) }
                                    else if let b = app.study.best["toeic"] { Text("BEST \(b)/10").font(.en(11.s)) }
                                }
                            }
                            .foregroundStyle(Color.ink)
                            .frame(maxWidth: .infinity, minHeight: 78.s)
                            .background(RoundedRectangle(cornerRadius: 16.s).fill(m.color).overlay(RoundedRectangle(cornerRadius: 16.s).stroke(Color.ink, lineWidth: 2.5)))
                            .opacity(disabled ? 0.45 : 1)
                        }
                        .buttonStyle(PressStyle(radius: 16.s, depth: 4))
                        .disabled(disabled)
                    }
                }
            }
        }
    }
}

// MARK: - One study session

struct StudySessionView: View {
    let mode: StudyMode
    var close: () -> Void
    @EnvironmentObject var app: AppState

    @State private var qs: [Question] = []
    @State private var i = 0
    @State private var right = 0
    @State private var combo = 0
    @State private var finished = false
    @State private var judged: Bool?       // nil = answering, true/false = shown result
    // dictation
    @State private var typed = ""
    @State private var hints = 0
    @FocusState private var focus: Bool
    @AppStorage("study.handDictation") private var handDictation = false
    // order
    @State private var bank: [String] = []
    @State private var picked: [Int] = []
    // choice
    @State private var options: [String] = []
    @State private var chosen: String?
    // flash
    @State private var timeLeft: Double = 60
    @State private var runID = UUID()
    @State private var settled = false

    private var q: Question? { i < qs.count ? qs[i] : nil }

    var body: some View {
        ZStack {
            if mode == .toeic || mode == .toeicMock {
                // TOEIC stays calm, like a real test sheet
                Color(hex: 0xF6F7FB).ignoresSafeArea()
            } else {
                Color.white.ignoresSafeArea()
                PopBackdrop(base: mode.color.opacity(0.7), calm: true)   // nothing moves around while you think
            }
            VStack(spacing: 12.s) {
                topBar
                // iPad: the question sits in the middle of the screen, not squeezed at the top
                if UIScale.isPad { Spacer(minLength: 0).frame(maxHeight: 120) }
                VStack(spacing: 12.s) {
                    if finished { resultView } else if let q { question(q) } else { emptyView }
                }
                // answering never makes the layout slide around — but only after the screen has slid in,
                // otherwise the question text stands still while the rest of the screen comes in from the right
                .transaction { if settled { $0.animation = nil } }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: UIScale.isPad ? 760 : .infinity)
        }
        .onAppear {
            start()
            AudioManager.shared.playBGM(.track(mode.track))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { settled = true }
        }
        .onDisappear { AudioManager.shared.playBGM(.study) }
        .task(id: runID) {
            guard mode == .flash || mode == .toeicMock else { return }
            while !Task.isCancelled && !finished {
                try? await Task.sleep(nanoseconds: 100_000_000)
                if judged == nil || mode == .toeicMock { timeLeft -= 0.1 }
                if timeLeft <= 0 { finishSession() }
            }
        }
    }

    // MARK: layout parts

    private var topBar: some View {
        HStack {
            BackChip { finished = true; Speaker.shared.stop(); close() }
            Spacer()
            Text(jp(mode.title)).font(.display(20.s)).foregroundStyle(Color.ink)
            Spacer()
            if mode == .toeicMock {
                VStack(spacing: 0) {
                    Text(String(format: "%d:%02d", Int(max(0, timeLeft)) / 60, Int(max(0, timeLeft)) % 60)).font(.en(18.s)).foregroundStyle(timeLeft < 60 ? Color.popDeep : Color.ink)
                    Text("\(min(i + 1, max(1, qs.count)))/\(max(1, qs.count))").font(.en(11.s)).foregroundStyle(Color.ink.opacity(0.6))
                }
                .frame(minWidth: 56.s)
            } else if mode == .flash {
                Text(String(format: "%.0f", max(0, timeLeft))).font(.en(24.s)).foregroundStyle(timeLeft < 10 ? Color.popDeep : Color.ink)
                    .frame(minWidth: 56.s)
            } else {
                Text("\(min(i + 1, max(1, qs.count)))/\(max(1, qs.count))").font(.en(20.s)).foregroundStyle(Color.ink).frame(minWidth: 56.s)
            }
        }
        .padding(.top, 6)
    }

    private var emptyView: some View {
        PaperCard {
            VStack(spacing: 10.s) {
                Image("nyan").resizable().scaledToFit().frame(height: 90.s)
                Text(jp(T("にがてな|問題は|ないにゃ！|すごい！", "약점 문제가 없어! 대단해!", "沒有弱點題目！好厲害！"))).font(.ui(17.s)).foregroundStyle(Color.ink)
                PopButton(title: L("common.back"), color: .white) { close() }
            }
        }
    }

    @ViewBuilder
    private func question(_ q: Question) -> some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 10.s) {
                HStack {
                    if (mode == .toeic || mode == .toeicMock) && judged == nil {
                        Text(jp(T("空所に|入る|最も|適切な|語句を|選ぼう", "빈칸에 가장 알맞은 말을 고르자", "選出最適合填入空格的詞語"))).font(.ui(16.s)).foregroundStyle(Color.ink).fixedSize(horizontal: false, vertical: true)
                    } else if mode == .listening && judged == nil {
                        // listening: the answer stays hidden until you choose
                        HStack(spacing: 8.s) {
                            Image(systemName: "ear.fill").font(.system(size: 22.s, weight: .bold)).foregroundStyle(Color.pop)
                            Text(jp(T("英語を|聞いてね", "영어를 들어 봐", "聽聽英文"))).font(.ui(18.s)).foregroundStyle(Color.ink)
                        }
                    } else if mode == .listening {
                        VStack(alignment: .leading, spacing: 4.s) {
                            Text(q.full).font(.en(18.s)).foregroundStyle(Color.ink).fixedSize(horizontal: false, vertical: true)
                            Text(jp(q.meaning)).font(.ui(15.s, bold: false)).foregroundStyle(Color.ink.opacity(0.75)).fixedSize(horizontal: false, vertical: true)
                        }
                    } else {
                        Text(jp(q.meaning)).font(.ui(18.s)).foregroundStyle(Color.ink).fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    Button { Speaker.shared.say(q.full, gender: AppState.shared.settings.studyGender) } label: {
                        Image(systemName: "speaker.wave.2.fill").font(.system(size: 18.s, weight: .bold)).foregroundStyle(Color.ink)
                            .frame(width: 44.s, height: 38.s)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.sun).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.ink, lineWidth: 2.5)))
                    }
                    .buttonStyle(.plain)
                }
                if mode == .listening && judged == nil {
                    Text(jp(T("英語を|聞いて、|正しい|意味を|選ぼう", "영어를 듣고 알맞은 뜻을 고르자", "聽英文，選出正確的意思"))).font(.ui(13.s, bold: false)).foregroundStyle(Color.ink.opacity(0.6))
                }
                // the result line always keeps its space, so nothing below jumps when you answer
                ZStack(alignment: .topLeading) {
                    verdict(true, q).opacity(0).accessibilityHidden(true)
                    if let judged { verdict(judged, q) }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .overlay(alignment: .topTrailing) {
            if combo >= 2 { Text("\(combo) COMBO").font(.en(14.s)).foregroundStyle(.white).padding(.horizontal, 10).padding(.vertical, 3)
                .background(Capsule().fill(Color.popDeep)).offset(x: -8, y: -12) }
        }
        answerArea(q)
        if mode != .flash && mode != .toeicMock {
            // always in place (hidden until you answer) so the screen never shifts
            PopButton(title: i + 1 >= qs.count ? T("けっかを見る", "결과 보기", "查看結果") : T("つぎへ", "다음", "下一題"), color: .pop, textColor: .white) { next() }
                .opacity(judged == nil ? 0 : 1)
                .disabled(judged == nil)
        }
    }

    private func verdict(_ ok: Bool, _ q: Question) -> some View {
        VStack(alignment: .leading, spacing: 4.s) {
            Text(ok ? "GREAT!" : "CHECK!").font(.en(26.s)).foregroundStyle(ok ? Color.mintDeep : Color.popDeep)
            Text(q.full).font(.en(20.s)).foregroundStyle(Color.ink).fixedSize(horizontal: false, vertical: true)
            if mode == .dictation && !ok { diffView(q) }
        }
    }

    /// shows which typed words were right (green) or wrong (red)
    private func diffView(_ q: Question) -> some View {
        let want = norm(q.full).split(separator: " ").map(String.init)
        let got = norm(typed).split(separator: " ").map(String.init)
        return FlowRow(spacing: 4) {
            ForEach(Array(want.enumerated()), id: \.offset) { k, w in
                let ok = k < got.count && got[k] == w
                Text(k < got.count ? got[k] : "＿").font(.en(15.s)).foregroundStyle(ok ? Color.mintDeep : Color.popDeep)
                    .strikethrough(!ok && k < got.count)
            }
        }
    }

    @ViewBuilder
    private func answerArea(_ q: Question) -> some View {
        switch mode {
        case .dictation: dictationArea(q)
        case .order: orderArea(q)
        // English UI has no translation to pick from, so the choices are the English sentences themselves
        case .listening: choiceArea(options, correct: q.meaning.isEmpty ? q.full : q.meaning, en: q.meaning.isEmpty)
        case .speak, .sounds: EmptyView()
        case .review:
            if q.kind == .order || q.choices.isEmpty { orderArea(q) } else { choiceArea(options, correct: q.kind == .blank ? q.a : q.a, en: true, blank: q) }
        case .flash, .toeic, .toeicMock: choiceArea(options, correct: q.a, en: true, blank: q)
        }
    }

    private func dictationArea(_ q: Question) -> some View {
        VStack(spacing: 10.s) {
            let words = q.full.split(separator: " ").map(String.init)
            if hints > 0 {
                Text(words.enumerated().map { $0.offset < hints ? $0.element : String(repeating: "_", count: min(6, $0.element.count)) }.joined(separator: " "))
                    .font(.en(17.s)).foregroundStyle(Color.ink.opacity(0.6)).frame(maxWidth: .infinity, alignment: .leading)
            }
            // write with the keyboard or by hand (Apple Pencil / finger)
            if judged == nil {
                HStack(spacing: 8.s) {
                    inputChip("keyboard.fill", T("キーボード", "키보드", "鍵盤"), on: !handDictation) { handDictation = false; later(0.2) { focus = true } }
                    inputChip("pencil.tip", T("手書き", "손글씨", "手寫"), on: handDictation) { handDictation = true; focus = false }
                    Spacer(minLength: 0)
                }
            }
            if handDictation && judged == nil {
                // the whole sentence can be written a bit at a time: what is read so far fills the answer
                HandwritingPad(height: (UIScale.isPad ? 190 : 140).s, onRead: { typed = $0 })
                    .id(q.full)
            }
            if !(handDictation && judged == nil) {
            TextField(T("聞こえた英文を入力", "들린 영어 문장을 입력", "輸入聽到的英文"), text: $typed)
                .font(.en(20.s)).foregroundStyle(Color.ink)
                .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.asciiCapable)
                .focused($focus).disabled(judged != nil)
                .padding(12.s)
                .background(RoundedRectangle(cornerRadius: 14.s).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 14.s).stroke(Color.ink, lineWidth: 2.5)))
                .onSubmit { judgeTyped(q) }
                .onAppear { if !handDictation { later(0.3) { focus = true } } }      // the keyboard is up right away
            }
            if judged == nil {
                HStack(spacing: 10.s) {
                    PopButton(title: T("ヒント", "힌트", "提示"), color: .white, height: 48) {
                        AudioManager.shared.se(.tap); hints = min(words.count, hints + 1)
                    }
                    PopButton(title: T("こたえる", "정답 확인", "作答"), color: .mint, height: 48) { judgeTyped(q) }
                }
            }
        }
    }

    private func inputChip(_ icon: String, _ t: String, on: Bool, _ a: @escaping () -> Void) -> some View {
        Button { AudioManager.shared.se(.tap, rate: 1.3, volume: 0.4); a() } label: {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 13.s, weight: .black))
                Text(jp(t)).font(.ui(13.s))
            }
            .foregroundStyle(on ? Color.white : Color.ink)
            .padding(.horizontal, 12.s).padding(.vertical, 6.s)
            .background(Capsule().fill(on ? Color.ink : Color.white).overlay(Capsule().stroke(Color.ink, lineWidth: 2)))
        }
        .buttonStyle(.plain)
    }

    private func orderArea(_ q: Question) -> some View {
        VStack(spacing: 10.s) {
            FlowRow(spacing: 6) {
                ForEach(picked, id: \.self) { k in
                    Text(bank[k]).font(.en(18.s)).foregroundStyle(Color.ink)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.sun).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.ink, lineWidth: 2)))
                        .onTapGesture { guard judged == nil else { return }; AudioManager.shared.se(.tap); picked.removeAll { $0 == k } }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 50.s, alignment: .topLeading)
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 14.s).fill(Color.white.opacity(0.8)).overlay(RoundedRectangle(cornerRadius: 14.s).stroke(Color.ink, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))))
            FlowRow(spacing: 6) {
                ForEach(bank.indices, id: \.self) { k in
                    let used = picked.contains(k)
                    Button {
                        guard judged == nil, !used else { return }
                        AudioManager.shared.se(.tap); picked.append(k)
                        if picked.count == bank.count { judgeOrder(q) }
                    } label: {
                        Text(bank[k]).font(.en(18.s)).foregroundStyle(Color.ink)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.ink, lineWidth: 2)))
                            .opacity(used ? 0.25 : 1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func choiceArea(_ opts: [String], correct: String, en: Bool, blank: Question? = nil) -> some View {
        VStack(spacing: (UIScale.isPad ? 8 : 12).s) {
            if let b = blank, b.kind == .blank, judged == nil {
                Text(Question.join(b.pre, "____", b.post))
                    .font(.en(20.s)).foregroundStyle(Color.ink).frame(maxWidth: .infinity, alignment: .leading)
            }
            ForEach(opts, id: \.self) { o in
                Button {
                    guard judged == nil else { return }
                    chosen = o
                    judge(o == correct)
                } label: {
                    // bigger buttons on iPhone: the screen has room under the choices
                    Text(en ? o : jp(o)).font(en ? .en(20.s) : .ui(18.s)).foregroundStyle(Color.ink)
                        .multilineTextAlignment(.leading).frame(maxWidth: .infinity, minHeight: (UIScale.isPad ? 46 : 60).s, alignment: .leading)
                        .padding(.horizontal, 12)
                        .background(RoundedRectangle(cornerRadius: 14.s).fill(fill(o, correct)).overlay(RoundedRectangle(cornerRadius: 14.s).stroke(Color.ink, lineWidth: 2.5)))
                }
                .buttonStyle(PressStyle(radius: 14.s, depth: 4))
            }
        }
    }

    private func fill(_ o: String, _ correct: String) -> Color {
        guard judged != nil else { return .white }
        if o == correct { return Color(hex: 0xBFF5DF) }
        if o == chosen { return Color(hex: 0xFFC9DC) }
        return .white
    }

    private var resultView: some View {
        let total = mode == .flash ? right : qs.count
        let perfect = mode != .flash && right == qs.count
        return VStack(spacing: 14.s) {
            OutlinedText(perfect ? "PERFECT!" : "FINISH!", font: .en(42.s), fill: .sun)
            PaperCard {
                VStack(spacing: 10.s) {
                    Image("nyan").resizable().scaledToFit().frame(height: 100.s).modifier(Hop())
                    if mode == .flash {
                        Text("\(right)").font(.en(56.s)).foregroundStyle(Color.popDeep)
                        Text("BEST \(app.study.best["flash"] ?? right)").font(.en(18.s)).foregroundStyle(Color.ink)
                    } else if mode == .toeicMock {
                        Text("\(right) / \(qs.count)").font(.en(36.s)).foregroundStyle(Color.ink)
                        Text(jp(T("スコア目安", "예상 점수", "預估分數"))).font(.ui(13.s)).foregroundStyle(Color.ink.opacity(0.6))
                        Text("\(ToeicBank.estimate(right, of: qs.count))").font(.en(56.s)).foregroundStyle(Color.popDeep)
                        Text("BEST \(app.study.best["toeicMock"] ?? 0)").font(.en(15.s)).foregroundStyle(Color.ink)
                        Text(jp(T("※Part 5の|正答率からの|目安です", "※Part 5 정답률 기준 예상입니다", "※依Part 5答對率估算"))).font(.ui(11.s, bold: false)).foregroundStyle(Color.ink.opacity(0.5))
                    } else {
                        Text("\(right) / \(total)").font(.en(44.s)).foregroundStyle(Color.popDeep)
                    }
                    Text(jp(comment)).font(.ui(15.s)).foregroundStyle(Color.ink).multilineTextAlignment(.center)
                    if app.study.stamped(Date()) {
                        HStack { UIIcon("ui_hanamaru|💮", size: 30.s); Text(jp(T("きょうの|はなまる！", "오늘의 꽃도장!", "今日的花丸！"))).font(.ui(17.s)).foregroundStyle(Color.popDeep) }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            HStack(spacing: 10.s) {
                PopButton(title: T("もう一度", "한 번 더", "再一次"), color: .white) { start() }
                PopButton(title: T("メニューへ", "메뉴로", "回選單"), color: .mint) { close() }
            }
        }
    }

    private var comment: String {
        if mode == .flash { return right >= 20 ? T("はやい！|天才にゃ！", "빠르다! 천재야!", "好快！天才！") : T("あしたは|もっと|いけるにゃ！", "내일은 더 잘할 수 있어!", "明天一定更好！") }
        if right == qs.count { return T("ぜんぶ|正解！|この調子にゃ！", "전부 정답! 이 기세로!", "全對！保持下去！") }
        return T("まちがえた|問題は|にがて復習に|入ったよ。", "틀린 문제는 약점 복습에 들어갔어.", "答錯的題目已加入弱點複習。")
    }

    // MARK: logic

    private func start() {
        qs = StudyPool.pick(mode, app)
        i = 0; right = 0; combo = 0; finished = false
        timeLeft = mode == .toeicMock ? 600 : 60
        runID = UUID()
        prepare()
    }

    private func prepare() {
        judged = nil; chosen = nil; typed = ""; hints = 0; picked = []
        guard let q else { return }
        switch mode {
        case .dictation:
            later(0.35) { Speaker.shared.say(q.full, gender: AppState.shared.settings.studyGender) }
            later(0.3) { if !handDictation { focus = true } }
        case .listening:
            let pick: (Question) -> String = { $0.meaning.isEmpty ? $0.full : $0.meaning }
            var opts = [pick(q)]
            for o in StudyPool.all(app).shuffled() where !pick(o).isEmpty && !opts.contains(pick(o)) {
                opts.append(pick(o)); if opts.count == 4 { break }
            }
            options = opts.shuffled()
            later(0.35) { Speaker.shared.say(q.full, gender: AppState.shared.settings.studyGender) }
        default:
            if q.kind == .order || q.choices.isEmpty || mode == .order {
                bank = (q.kind == .order ? q.words : q.full.split(separator: " ").map(String.init)).shuffled()
            } else {
                options = q.choices.shuffled()
            }
        }
    }

    private func judgeTyped(_ q: Question) {
        guard judged == nil else { return }
        focus = false
        judge(norm(typed) == norm(q.full))
    }
    private func judgeOrder(_ q: Question) {
        let want = q.kind == .order ? q.words : q.full.split(separator: " ").map(String.init)
        judge(picked.map { bank[$0] } == want)
    }

    private func judge(_ ok: Bool) {
        guard let q else { return }
        judged = ok
        app.study.answered(correct: ok)
        let skill: String = switch mode {
            case .listening: "listening"; case .dictation, .order: "writing"; case .speak, .sounds: "speaking"; default: "grammar"
        }
        app.study.track(q, skill: skill, correct: ok)
        if ok {
            right += 1; combo += 1
            AudioManager.shared.se(.studyOK, volume: 0.8)
            if combo >= 3 { later(0.25) { AudioManager.shared.se(.studyCombo, volume: 0.5) } }
            if mode == .review { app.study.recordHit(q) }
        } else {
            combo = 0
            AudioManager.shared.se(.studyNG, volume: 0.7)
            app.study.recordMiss(q)
            if mode == .flash { timeLeft -= 3 }
        }
        if mode == .flash || mode == .toeicMock {
            later(mode == .toeicMock ? 0.5 : ok ? 0.35 : 0.9) { next() }
        } else {
            later(0.3) { Speaker.shared.say(q.full, gender: AppState.shared.settings.studyGender) }
        }
    }

    private func next() {
        Speaker.shared.stop()
        if i + 1 >= qs.count && mode != .flash { finishSession(); return }
        i += 1
        if i >= qs.count { finishSession(); return }
        prepare()
    }

    private func finishSession() {
        guard !finished else { return }
        finished = true
        if mode == .flash { app.study.best["flash"] = max(app.study.best["flash"] ?? 0, right) }
        if mode == .toeic { app.study.best["toeic"] = max(app.study.best["toeic"] ?? 0, right) }
        if mode == .toeicMock { app.study.best["toeicMock"] = max(app.study.best["toeicMock"] ?? 0, ToeicBank.estimate(right, of: qs.count)) }
        app.study.finish(mode)
        app.study.save()
        AudioManager.shared.se(.studyClear, volume: 0.8)
    }

    private func norm(_ s: String) -> String {
        let t = s.lowercased().replacingOccurrences(of: "’", with: "'")
        let kept = t.unicodeScalars.map { CharacterSet.letters.contains($0) || CharacterSet.decimalDigits.contains($0) || $0 == "'" ? Character($0) : " " }
        return String(kept).split(separator: " ").joined(separator: " ")
    }
}


/// Where today's cell is in the stamp card (the stamp tool lands there).
struct TodayCellKey: PreferenceKey {
    static let defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) { value = value ?? nextValue() }
}

/// A rubber stamp with a wooden handle, drawn in code.
struct StampTool: View {
    var body: some View {
        VStack(spacing: 0) {
            Circle().fill(Color(hex: 0xC98B4E)).overlay(Circle().stroke(Color.ink, lineWidth: 2.5))
                .frame(width: 26.s, height: 26.s)
            RoundedRectangle(cornerRadius: 4).fill(Color(hex: 0xB0743F)).overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.ink, lineWidth: 2.5))
                .frame(width: 14.s, height: 22.s)
                .padding(.top, -3)
            RoundedRectangle(cornerRadius: 6).fill(Color(hex: 0xE8D3B0)).overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.ink, lineWidth: 2.5))
                .frame(width: 44.s, height: 14.s)
                .padding(.top, -3)
            RoundedRectangle(cornerRadius: 4).fill(Color.popDeep).overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.ink, lineWidth: 2))
                .frame(width: 40.s, height: 9.s)
                .padding(.top, -2)
        }
        .rotationEffect(.degrees(-8))
        .shadow(color: Color.ink.opacity(0.25), radius: 0, x: 3, y: 3)
    }
}
