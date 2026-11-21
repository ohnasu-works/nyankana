import SwiftUI
import UIKit

// MARK: - Word data

/// Word course: JLPT N5 … N1 (h3 / toeic are not used by にゃんカナ).
enum VocabLevel: Int, CaseIterable, Identifiable {
    case j1 = 1, j2, j3, h1, h2, h3, toeic
    var id: Int { rawValue }
    var label: String {
        switch self {
        case .j1: "N5"
        case .j2: "N4"
        case .j3: "N3"
        case .h1: "N2"
        case .h2: "N1"
        case .h3: "N1+"
        case .toeic: "—"
        }
    }
    var color: Color {
        switch self {
        case .j1: Color(hex: 0x7FD8FF)
        case .j2: Color(hex: 0x8FE3B0)
        case .j3: Color(hex: 0xFFE07A)
        case .h1: Color(hex: 0xFFB37A)
        case .h2: Color(hex: 0xFF9DC2)
        case .h3: Color(hex: 0xC5A8FF)
        case .toeic: Color(hex: 0xFFC65C)
        }
    }
}

struct VocabWord: Identifiable, Hashable {
    let id: String          // the word as written
    let word: String
    let level: Int
    let pos: String
    /// meanings: `ja` holds the English meaning (the field name is kept from にゃんグリッシュ)
    let ja: String, ko: String, zh: String
    /// the reading in hiragana (empty when the word is already written in kana)
    let forms: [String]
    var reading: String { forms.first ?? word }
    var meaning: String {
        switch L10n.current {
        case .ko: ko
        case .zhHant: zh
        default: ja
        }
    }
}

@MainActor
enum Vocab {
    static let all: [VocabWord] = VocabRaw.text.split(separator: "\n").compactMap { line in
        let f = line.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        guard f.count == 7 else { return nil }
        return VocabWord(id: f[0], word: f[0], level: Int(f[1]) ?? 0, pos: f[2], ja: f[3], ko: f[4], zh: f[5],
                         forms: f[6].split(separator: ",").map(String.init))
    }
    static let byID: [String: VocabWord] = Dictionary(all.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
    static func words(_ l: VocabLevel) -> [VocabWord] { all.filter { $0.level == l.rawValue } }
    static let counts: [Int: Int] = Dictionary(grouping: all, by: \.level).mapValues(\.count)

    /// three wrong meanings of the same part of speech (same course if possible)
    static func distractors(for w: VocabWord, count n: Int = 3, english: Bool = false) -> [String] {
        let pool = all.filter { $0.id != w.id && $0.pos == w.pos && abs($0.level - w.level) <= 1 && $0.level > 0 }
        var out: [String] = []
        // skip synonyms (e.g. adequate / sufficient both 「十分な」) so a question never has two right answers
        let gloss = { (x: VocabWord) in Set(x.ja.split(whereSeparator: { "・、,".contains($0) }).map { $0.trimmingCharacters(in: .whitespaces) }) }
        let mine = gloss(w)
        for c in pool.shuffled() {
            if !mine.isDisjoint(with: gloss(c)) { continue }
            let v = english ? c.word : c.meaning
            if v != (english ? w.word : w.meaning) && !out.contains(v) { out.append(v) }
            if out.count == n { break }
        }
        return out
    }

    /// game question: the meaning -> pick the Japanese word
    static func gameQuestion(_ w: VocabWord) -> Question {
        var q = Question.blank(w.ja, "", w.word, "", [w.word] + distractors(for: w, english: true), "vocab")
        q.ko = w.ko; q.zh = w.zh; q.vocabWord = w.word; q.kana = w.reading
        return q
    }
}

// MARK: - Learning record (spaced repetition)

struct VocabLog: Codable, Equatable {
    /// word id -> box 0...5 (box 4+ = mastered)
    var box: [String: Int] = [:]
    /// word id -> next review day "yyyy-MM-dd"
    var due: [String: String] = [:]
    /// day -> words learned / reviewed that day
    var days: [String: Int] = [:]
    var course = 1
    var dailyNew = 10
    var gameHits = 0
    /// word id -> when it was last answered (the newer device wins when syncing)
    var touched: [String: Double] = [:]

    init() {}
    init(from d: Decoder) throws {
        let c = try d.container(keyedBy: K.self)
        box = (try? c.decodeIfPresent([String: Int].self, forKey: .box)) ?? [:]
        due = (try? c.decodeIfPresent([String: String].self, forKey: .due)) ?? [:]
        days = (try? c.decodeIfPresent([String: Int].self, forKey: .days)) ?? [:]
        course = (try? c.decodeIfPresent(Int.self, forKey: .course)) ?? 1
        dailyNew = (try? c.decodeIfPresent(Int.self, forKey: .dailyNew)) ?? 10
        gameHits = (try? c.decodeIfPresent(Int.self, forKey: .gameHits)) ?? 0
        touched = (try? c.decodeIfPresent([String: Double].self, forKey: .touched)) ?? [:]
    }
    private enum K: String, CodingKey { case box, due, days, course, dailyNew, gameHits, touched }

    /// Combine with another device: each word follows the device that answered it last.
    func merged(with o: VocabLog) -> VocabLog {
        var m = self
        for (id, b) in o.box {
            let tm = touched[id] ?? 0, to = o.touched[id] ?? 0
            if box[id] == nil || to > tm || (to == tm && b > (box[id] ?? 0)) {
                m.box[id] = b
                if let d = o.due[id] { m.due[id] = d }
                m.touched[id] = max(tm, to)
            }
        }
        m.days.merge(o.days) { max($0, $1) }
        m.gameHits = max(gameHits, o.gameHits)
        return m
    }

    static let intervals = [0, 1, 2, 4, 7, 15, 30]
    static func key(_ d: Date = Date()) -> String {
        let f = DateFormatter(); f.calendar = Calendar(identifier: .gregorian); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "yyyy-MM-dd"
        return f.string(from: d)
    }

    func mastered(_ id: String) -> Bool { (box[id] ?? 0) >= 4 }
    var masteredCount: Int { box.values.filter { $0 >= 4 }.count }
    var learningCount: Int { box.count }
    func masteredCount(_ l: VocabLevel) -> Int { box.filter { $0.value >= 4 && (Vocab.byID[$0.key]?.level ?? -1) == l.rawValue }.count }
    func startedCount(_ l: VocabLevel) -> Int { box.keys.filter { (Vocab.byID[$0]?.level ?? -1) == l.rawValue }.count }
    var todayCount: Int { days[VocabLog.key()] ?? 0 }

    /// words due for review today (oldest first)
    @MainActor func dueToday(limit: Int = 30) -> [VocabWord] {
        let today = VocabLog.key()
        return box.keys.filter { (due[$0] ?? today) <= today }
            .sorted { (due[$0] ?? "") < (due[$1] ?? "") }
            .prefix(limit).compactMap { Vocab.byID[$0] }
    }
    @MainActor func newWords(_ n: Int) -> [VocabWord] {
        let l = VocabLevel(rawValue: course) ?? .j1
        return Array(Vocab.words(l).filter { box[$0.id] == nil }.prefix(n))
    }

    mutating func answer(_ id: String, correct: Bool) {
        let b = box[id] ?? 0
        let nb = correct ? min(6, b + 1) : max(0, b >= 4 ? 2 : 0)
        box[id] = nb
        let d = Calendar.current.date(byAdding: .day, value: correct ? VocabLog.intervals[nb] : 0, to: Date()) ?? Date()
        due[id] = VocabLog.key(d)
        touched[id] = CloudSync.now
        days[VocabLog.key(), default: 0] += 1
    }

    var rankTitle: String {
        let m = masteredCount
        switch m {
        case ..<50: return T("単語の|たまご", "단어 알", "單字蛋")
        case ..<200: return T("単語ハンター", "단어 사냥꾼", "單字獵人")
        case ..<500: return T("単語コレクター", "단어 수집가", "單字收藏家")
        case ..<1000: return T("単語マスター", "단어 마스터", "單字大師")
        case ..<2000: return T("ことばの|賢者", "말의 현자", "語言賢者")
        default: return T("ワーディアの|辞書王", "워디아의 사전왕", "沃迪亞辭典王")
        }
    }
    var rankNext: Int? { [50, 200, 500, 1000, 2000].first { $0 > masteredCount } }

    private static var url: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("vocab.json")
    }
    static func load() -> VocabLog { (try? JSONDecoder().decode(VocabLog.self, from: Data(contentsOf: url))) ?? VocabLog() }
    func save() { writeLocal(); CloudSync.put(self, "vocab") }
    func writeLocal() { try? JSONEncoder().encode(self).write(to: VocabLog.url, options: .atomic) }
}

// MARK: - Study home card

struct VocabCard: View {
    @EnvironmentObject var app: AppState
    @State private var open = false

    var body: some View {
        let log = app.vocab
        let l = VocabLevel(rawValue: log.course) ?? .j1
        let goal = log.dailyNew + min(20, log.dueToday().count)
        let done = log.todayCount
        Button { AudioManager.shared.se(.decide); open = true } label: {
            HStack(spacing: 12.s) {
                ZStack {
                    Circle().stroke(Color.ink.opacity(0.12), lineWidth: 8.s)
                    Circle().trim(from: 0, to: min(1, CGFloat(done) / CGFloat(max(1, goal))))
                        .stroke(Color.mintDeep, style: StrokeStyle(lineWidth: 8.s, lineCap: .round)).rotationEffect(.degrees(-90))
                    // the word pet grows with the words you master
                    VocabPet(mastered: log.masteredCount, size: 56.s)
                }
                .frame(width: 72.s, height: 72.s)
                VStack(alignment: .leading, spacing: 3.s) {
                    HStack(spacing: 6) {
                        Text(jp(T("たんご|トレーニング", "단어 트레이닝", "單字訓練"))).font(.display(18.s)).foregroundStyle(Color.ink)
                        Text(l.label).font(.ui(11.s)).foregroundStyle(Color.ink)
                            .padding(.horizontal, 7).padding(.vertical, 2).background(Capsule().fill(l.color))
                    }
                    Text(jp(T("今日", "오늘", "今天")) + " \(min(done, goal))/\(goal)  ·  " + jp(T("復習", "복습", "複習")) + " \(log.dueToday().count)")
                        .font(.ui(12.s, bold: false)).foregroundStyle(Color.ink.opacity(0.7))
                    Text(jp(T("覚えた", "외움", "已記住")) + " \(log.masteredCount)").font(.ui(11.s)).foregroundStyle(Color.popDeep)
                }
                Spacer(minLength: 0)
                Image(systemName: "play.circle.fill").font(.system(size: 30.s, weight: .bold)).foregroundStyle(Color.popDeep)
            }
            .padding(12.s)
            .background(RoundedRectangle(cornerRadius: 18.s).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 18.s).stroke(Color.ink, lineWidth: 3)))
        }
        .buttonStyle(PressStyle(radius: 18.s, depth: 4))
        .fullScreenCover(isPresented: $open) { VocabHomeView().environmentObject(app) }
    }
}

// MARK: - Vocab home: courses, progress, start

struct VocabHomeView: View {
    @ObservedObject private var voiceSettings = AppState.shared.settings
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var session: SessionBox?
    @State private var reviewOnly = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    summary
                    startButtons
                    PaperCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(jp(T("コースを|えらぶ", "코스 선택", "選擇課程"))).font(.display(18)).foregroundStyle(Color.ink)
                            ForEach(VocabLevel.allCases) { l in courseRow(l) }
                        }
                    }
                    PaperCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(jp(T("1日に|出てくる|新しい単語の数", "하루에 나오는 새 단어 수", "每天出現的新單字數"))).font(.ui(15)).foregroundStyle(Color.ink)
                            Text(jp(T("「今日の単語」で|はじめて出る|単語の数です。|復習の単語は|これとは別に|出てきます。|毎日|続けるなら|5〜10が|おすすめ。", "「오늘의 단어」에서 처음 나오는 단어 수예요. 복습 단어는 따로 나와요. 매일 하려면 5~10개를 추천해요.", "「今日的單字」中首次出現的單字數。複習的單字另外出現。每天持續的話建議5～10個。")))
                                .font(.ui(12, bold: false)).foregroundStyle(Color.ink.opacity(0.6)).fixedSize(horizontal: false, vertical: true)
                            Picker("", selection: Binding(get: { app.vocab.dailyNew }, set: { app.vocab.dailyNew = $0; app.save() })) {
                                ForEach([5, 10, 20, 30], id: \.self) { Text("\($0)").tag($0) }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    PaperCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(jp(T("単語を|読む声", "단어를 읽는 목소리", "唸單字的聲音"))).font(.ui(15)).foregroundStyle(Color.ink)
                            Picker("", selection: Binding(get: { voiceSettings.wordVoice }, set: { voiceSettings.wordVoice = $0; Speaker.shared.say("Hello", gender: $0 == "m" ? .male : .female) })) {
                                Text(T("女性", "여성", "女聲")).tag("f")
                                Text(T("男性", "남성", "男聲")).tag("m")
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                }
                .padding(16)
            }
            .background(Color(hex: 0xE9FBF2).ignoresSafeArea())
            .navigationTitle(jp(T("たんごトレーニング", "단어 트레이닝", "單字訓練")))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button { dismiss() } label: { Label(L("common.back"), systemImage: "chevron.left").labelStyle(.titleAndIcon) } } }
            .fullScreenCover(item: $session) { box in
                VocabSessionView(words: box.words) { session = nil; AdManager.shared.roundFinished() }.environmentObject(app)
            }
        }
    }

    private struct SessionBox: Identifiable { let id = UUID(); let words: [VocabWord] }

    private var summary: some View {
        let log = app.vocab
        let total = VocabLevel.allCases.reduce(0) { $0 + (Vocab.counts[$1.rawValue] ?? 0) }
        return PaperCard {
            VStack(spacing: 8) {
                VocabPet(mastered: log.masteredCount, size: 130)
                    .padding(.top, 4)
                Text(jp(log.rankTitle)).font(.display(22)).foregroundStyle(Color.popDeep)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(log.masteredCount)").font(.en(46)).foregroundStyle(Color.ink)
                    Text("/ \(total)").font(.en(18)).foregroundStyle(Color.ink.opacity(0.5))
                }
                Text(jp(T("マスターした単語", "마스터한 단어", "已精通的單字"))).font(.ui(13)).foregroundStyle(Color.ink.opacity(0.7))
                if let n = log.rankNext {
                    Text(jp(T("あと", "앞으로 ", "再")) + "\(n - log.masteredCount)" + jp(T("語で|次の|称号！", "단어면 다음 칭호!", "個單字升級稱號！")))
                        .font(.ui(12, bold: false)).foregroundStyle(Color.ink.opacity(0.7))
                }
                HStack(spacing: 18) {
                    stat("ui_fire|🔥", "\(app.study.streak)", T("連続日数", "연속 일수", "連續天數"))
                    stat("ui_book|📖", "\(log.learningCount)", T("学習中", "학습 중", "學習中"))
                    stat("ui_game|🎮", "\(log.gameHits)", T("ゲームで正解", "게임에서 정답", "遊戲中答對"))
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func stat(_ i: String, _ v: String, _ k: String) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 6) {
                UIIcon(i, size: 34)
                Text(v).font(.en(24)).foregroundStyle(Color.ink)
            }
            Text(jp(k)).font(.ui(11)).foregroundStyle(Color.ink.opacity(0.6))
        }
    }

    private var startButtons: some View {
        let log = app.vocab
        let due = log.dueToday(limit: 20)
        let new = log.newWords(log.dailyNew)
        return VStack(spacing: 10) {
            PopButton(title: T("今日の単語をはじめる", "오늘의 단어 시작", "開始今天的單字") + "  (\(due.count + new.count))", color: .pop, textColor: .white) {
                session = SessionBox(words: (new + due).shuffled())
            }
            .disabled(due.isEmpty && new.isEmpty)
            if !due.isEmpty {
                PopButton(title: T("復習だけする", "복습만 하기", "只複習") + "  (\(due.count))", color: .sky) { session = SessionBox(words: due) }
            }
        }
    }

    private func courseRow(_ l: VocabLevel) -> some View {
        let total = Vocab.counts[l.rawValue] ?? 0
        let m = app.vocab.masteredCount(l)
        let s = app.vocab.startedCount(l)
        let on = app.vocab.course == l.rawValue
        return Button { AudioManager.shared.se(.tap); app.vocab.course = l.rawValue; app.save() } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(l.label).font(.ui(15)).foregroundStyle(Color.ink)
                        .frame(width: 58).padding(.vertical, 3).background(Capsule().fill(l.color))
                    // 学習中 grows as soon as you answer; 覚えた after answering right on 4 separate review days
                    Text("\(s) / \(total)").font(.en(14)).foregroundStyle(Color.ink)
                    Text(jp(T("学習中", "학습 중", "學習中"))).font(.ui(10)).foregroundStyle(Color.ink.opacity(0.55))
                    Text(jp(T("覚えた", "외움", "記住")) + " \(m)").font(.ui(11)).foregroundStyle(Color.mintDeep)
                        .padding(.leading, 4)
                    Spacer()
                    if total > 0 && m == total { UIIcon("ui_trophy|🏆", size: 18) }
                    else if total > 0 && m * 2 >= total { UIIcon("ui_medal_s|🥈", size: 18) }
                    if on { Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.mintDeep) }
                }
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.ink.opacity(0.08))
                        Capsule().fill(l.color.opacity(0.5)).frame(width: g.size.width * CGFloat(s) / CGFloat(max(1, total)))
                        Capsule().fill(l.color).frame(width: g.size.width * CGFloat(m) / CGFloat(max(1, total)))
                    }
                }
                .frame(height: 8)
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 12).fill(on ? Color(hex: 0xFFF6CF) : Color.white).overlay(RoundedRectangle(cornerRadius: 12).stroke(on ? Color.popDeep : Color.ink.opacity(0.2), lineWidth: on ? 2.5 : 1)))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Session

struct VocabSessionView: View {
    @EnvironmentObject var app: AppState
    @ObservedObject private var settings = AppState.shared.settings
    let words: [VocabWord]
    let onClose: () -> Void

    enum Kind { case intro, meaning, english, listen, spell }
    @State private var queue: [(VocabWord, Kind)] = []
    @State private var idx = 0
    @State private var options: [String] = []
    @State private var judged: Bool?
    @State private var chosen = ""
    @State private var typed = ""
    @State private var right = 0
    @State private var wrongIDs = Set<String>()
    @State private var newlyMastered = 0
    @State private var finished = false
    @FocusState private var focus: Bool
    /// hide mode: the answer stays covered until you think of it, then you grade yourself
    @AppStorage("vocab.hide") private var hide = false
    @State private var shown = false

    var body: some View {
        ZStack {
            Color(hex: 0xE9FBF2).ignoresSafeArea()
            VStack(spacing: 14) {
                HStack {
                    BackChip { onClose() }
                    ProgressView(value: Double(min(idx, queue.count)), total: Double(max(1, queue.count))).tint(Color.mintDeep)
                    Text("\(min(idx + 1, queue.count))/\(queue.count)").font(.en(14)).foregroundStyle(Color.ink)
                    Button {
                        AudioManager.shared.se(.tap); hide.toggle(); shown = false
                    } label: {
                        VStack(spacing: 0) {
                            Image(systemName: hide ? "eye.slash.fill" : "eye.fill").font(.system(size: 16, weight: .black))
                            Text(hide ? T("かくす", "가리기", "遮住") : T("見せる", "보이기", "顯示")).font(.ui(9))
                        }
                        .foregroundStyle(hide ? Color.white : Color.ink)
                        .frame(width: 52, height: 42)
                        .background(RoundedRectangle(cornerRadius: 12).fill(hide ? Color.ink : Color.white).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.ink, lineWidth: 2.5)))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, UIScale.isPad ? 30 : 0)
                }
                .padding(.horizontal, 16).padding(.top, 8)
                if finished { result } else if idx < queue.count { card(queue[idx].0, queue[idx].1) }
                Spacer()
            }
        }
        .onAppear { AudioManager.shared.playBGM(.track("study_b")) }
        .onDisappear { AudioManager.shared.playBGM(.study) }
        .onAppear(perform: build)
    }

    private func build() {
        var q: [(VocabWord, Kind)] = []
        for w in words {
            let b = app.vocab.box[w.id]
            if b == nil { q.append((w, .intro)); q.append((w, .meaning)) }
            else {
                switch b! {
                case 0, 1: q.append((w, .meaning))
                case 2: q.append((w, .english))
                case 3: q.append((w, Bool.random() ? .listen : .english))
                default: q.append((w, Bool.random() ? .spell : .listen))
                }
            }
        }
        queue = q
        prepare()
    }

    private func prepare() {
        judged = nil; chosen = ""; typed = ""; shown = false
        guard idx < queue.count else { return }
        let (w, k) = queue[idx]
        switch k {
        case .intro: later(0.3) { Speaker.shared.say(w.word, gender: AppState.shared.settings.wordGender) }
        case .meaning, .listen:
            options = ([w.meaning] + Vocab.distractors(for: w)).shuffled()
            later(0.3) { Speaker.shared.say(w.word, gender: AppState.shared.settings.wordGender) }
        case .english: options = ([w.word] + Vocab.distractors(for: w, english: true)).shuffled()
        case .spell: focus = true
        }
    }

    @ViewBuilder
    private func card(_ w: VocabWord, _ k: Kind) -> some View {
        VStack(spacing: 14) {
            PaperCard {
                VStack(spacing: 10) {
                    HStack {
                        Text(VocabLevel(rawValue: w.level)?.label ?? "").font(.ui(11)).padding(.horizontal, 7).padding(.vertical, 2)
                            .background(Capsule().fill(VocabLevel(rawValue: w.level)?.color ?? .white))
                        Text(Library.posLabel(w.pos)).font(.ui(11)).foregroundStyle(.white).padding(.horizontal, 6).padding(.vertical, 2).background(Capsule().fill(Color.sky))
                        Spacer()
                        // switch the word voice (female / male) and hear it at once
                        Button {
                            settings.wordVoice = settings.wordVoice == "m" ? "f" : "m"
                            Speaker.shared.say(w.word, gender: settings.wordGender)
                        } label: {
                            Text(settings.wordVoice == "m" ? T("男性", "남성", "男聲") : T("女性", "여성", "女聲"))
                                .font(.ui(12)).foregroundStyle(Color.ink).lineLimit(1).fixedSize()
                                .padding(.horizontal, 8).frame(height: 38)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.ink, lineWidth: 2.5)))
                        }
                        .buttonStyle(.plain)
                        Button { Speaker.shared.say(w.word, gender: AppState.shared.settings.wordGender) } label: {
                            Image(systemName: "speaker.wave.2.fill").font(.system(size: 18, weight: .bold)).foregroundStyle(Color.ink)
                                .frame(width: 44, height: 38).background(RoundedRectangle(cornerRadius: 10).fill(Color.sun).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.ink, lineWidth: 2.5)))
                        }
                        .buttonStyle(.plain)
                    }
                    switch k {
                    case .intro:
                        Text("NEW!").font(.en(14)).foregroundStyle(.white).padding(.horizontal, 8).padding(.vertical, 2).background(Capsule().fill(Color.popDeep))
                        Text(w.word).font(.en(40)).foregroundStyle(Color.ink).minimumScaleFactor(0.5).lineLimit(1)
                        if hidden(k) { cover(T("意味を|思い出してから|「こたえを見る」", "뜻을 떠올린 뒤 「답 보기」", "想出意思後按「看答案」")) }
                        else {
                            Text(w.meaning).font(.ui(20)).foregroundStyle(Color.ink)
                            if let ex = Library.examples(for: w, max: 1).first {
                                ExampleRow(q: ex).padding(.top, 4)
                            }
                        }
                    case .meaning:
                        Text(w.word).font(.en(38)).foregroundStyle(Color.ink).minimumScaleFactor(0.5).lineLimit(1)
                        Text(jp(T("意味は？", "뜻은?", "意思是？"))).font(.ui(13, bold: false)).foregroundStyle(Color.ink.opacity(0.6))
                        if hide { if shown { Text(w.meaning).font(.ui(22)).foregroundStyle(Color.ink) } else { cover(T("頭の中で|答えてから|「こたえを見る」", "머릿속으로 답한 뒤 「답 보기」", "在腦中作答後按「看答案」")) } }
                    case .english:
                        Text(w.meaning).font(.ui(24)).foregroundStyle(Color.ink).multilineTextAlignment(.center)
                        Text(jp(T("英語で|いうと？", "영어로는?", "英文是？"))).font(.ui(13, bold: false)).foregroundStyle(Color.ink.opacity(0.6))
                        if hide { if shown { Text(w.word).font(.en(32)).foregroundStyle(Color.ink) } else { cover(T("頭の中で|答えてから|「こたえを見る」", "머릿속으로 답한 뒤 「답 보기」", "在腦中作答後按「看答案」")) } }
                    case .listen:
                        Image(systemName: "ear.fill").font(.system(size: 40, weight: .bold)).foregroundStyle(Color.pop)
                        Text(jp(T("聞いて|意味を|選ぼう", "듣고 뜻을 고르자", "聽完選出意思"))).font(.ui(13, bold: false)).foregroundStyle(Color.ink.opacity(0.6))
                        if judged != nil { Text(w.word).font(.en(30)).foregroundStyle(Color.ink) }
                    case .spell:
                        Text(w.meaning).font(.ui(24)).foregroundStyle(Color.ink).multilineTextAlignment(.center)
                        Text(jp(T("つづりを|書こう", "철자를 쓰자", "寫出拼法"))).font(.ui(13, bold: false)).foregroundStyle(Color.ink.opacity(0.6))
                        Text(String(w.word.prefix(1)) + String(repeating: " _", count: max(0, w.word.count - 1)))
                            .font(.en(20)).foregroundStyle(Color.ink.opacity(0.5))
                    }
                    if let j = judged {
                        Text(j ? "GREAT!" : "CHECK!").font(.en(24)).foregroundStyle(j ? Color.mintDeep : Color.popDeep)
                        if k == .english || k == .spell { Text(w.word).font(.en(26)).foregroundStyle(Color.ink) }
                        if k != .intro && !j { Text(w.meaning).font(.ui(16)).foregroundStyle(Color.ink) }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            answers(w, k)
        }
        .padding(.horizontal, 16)
    }

    private func hidden(_ k: Kind) -> Bool { hide && !shown && (k == .intro || k == .meaning || k == .english) }

    private func cover(_ text: String) -> some View {
        Text(jp(text)).font(.ui(13)).foregroundStyle(Color.ink.opacity(0.55)).multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: 0xFF8FB1).opacity(0.25))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.popDeep.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))))
            .onTapGesture { reveal() }
    }

    private func reveal() {
        AudioManager.shared.se(.tap)
        withAnimation(.easeOut(duration: 0.2)) { shown = true }
        if idx < queue.count { Speaker.shared.say(queue[idx].0.word, gender: AppState.shared.settings.wordGender) }
    }

    /// self check in hide mode: わかった / まだ
    private func selfGrade(_ w: VocabWord, _ k: Kind, _ ok: Bool) {
        if k == .intro {
            if ok {
                // already known: count it once and skip the quiz that follows
                app.vocab.answer(w.id, correct: true)
                if let j = queue.indices.first(where: { $0 > idx && queue[$0].0.id == w.id && queue[$0].1 == .meaning }) { queue.remove(at: j) }
                right += 1
                AudioManager.shared.se(.studyOK)
            }
            next()
        } else {
            judge(w, ok)
        }
    }

    @ViewBuilder
    private func answers(_ w: VocabWord, _ k: Kind) -> some View {
        if hide && (k == .intro || k == .meaning || k == .english) {
            if !shown {
                PopButton(title: T("こたえを見る", "답 보기", "看答案"), color: .sun) { reveal() }
            } else if judged == nil {
                HStack(spacing: 10) {
                    PopButton(title: T("まだ", "아직", "還不會"), color: .white) { selfGrade(w, k, false) }
                    PopButton(title: T("わかった！", "알았어!", "會了！"), color: .pop, textColor: .white) { selfGrade(w, k, true) }
                }
            } else { nextButton }
        } else {
            normalAnswers(w, k)
        }
    }

    @ViewBuilder
    private func normalAnswers(_ w: VocabWord, _ k: Kind) -> some View {
        switch k {
        case .intro:
            PopButton(title: T("おぼえた！", "외웠어!", "記住了！"), color: .pop, textColor: .white) { next() }
        case .spell:
            VStack(spacing: 10) {
                TextField(T("英語で入力", "영어로 입력", "輸入英文"), text: $typed)
                    .font(.en(22)).textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.default).focused($focus)
                    .padding(12).background(RoundedRectangle(cornerRadius: 14).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.ink, lineWidth: 2.5)))
                    .onSubmit { if judged == nil { judge(w, [w.word, w.reading].map(GameModel.norm).contains(GameModel.norm(typed))) } }
                if judged == nil {
                    PopButton(title: T("こたえる", "답하기", "作答"), color: .pop, textColor: .white) {
                        judge(w, [w.word, w.reading].map(GameModel.norm).contains(GameModel.norm(typed)))
                    }
                } else { nextButton }
            }
        default:
            VStack(spacing: 8) {
                ForEach(options, id: \.self) { o in
                    let correct = k == .english ? w.word : w.meaning
                    Button { guard judged == nil else { return }; chosen = o; judge(w, o == correct) } label: {
                        Text(k == .english ? o : jp(o)).font(k == .english ? .en(19) : .ui(16)).foregroundStyle(Color.ink)
                            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading).padding(.horizontal, 14)
                            .background(RoundedRectangle(cornerRadius: 14).fill(fill(o, correct)).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.ink, lineWidth: 2.5)))
                    }
                    .buttonStyle(PressStyle(radius: 14, depth: 4))
                }
                if judged != nil { nextButton }
            }
        }
    }

    private var nextButton: some View {
        PopButton(title: idx + 1 >= queue.count ? T("けっかを見る", "결과 보기", "查看結果") : T("つぎへ", "다음", "下一題"), color: .pop, textColor: .white) { next() }
    }

    private func fill(_ o: String, _ correct: String) -> Color {
        guard judged != nil else { return .white }
        if o == correct { return Color(hex: 0xBFF5DF) }
        if o == chosen { return Color(hex: 0xFFC9DC) }
        return .white
    }

    private func judge(_ w: VocabWord, _ ok: Bool) {
        focus = false
        judged = ok
        let was = app.vocab.mastered(w.id)
        // a word missed once in this session is not promoted the second time round
        app.vocab.answer(w.id, correct: ok && !wrongIDs.contains(w.id))
        var sk = app.study.skills["vocab"] ?? [0, 0]; sk[1] += 1; if ok { sk[0] += 1 }; app.study.skills["vocab"] = sk
        if ok { right += 1; AudioManager.shared.se(.studyOK) } else {
            AudioManager.shared.se(.studyNG)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if !wrongIDs.contains(w.id) {
                wrongIDs.insert(w.id)
                queue.append((w, .meaning))      // ask again at the end
            }
        }
        if !was && app.vocab.mastered(w.id) { newlyMastered += 1 }
        Speaker.shared.say(w.word, gender: AppState.shared.settings.wordGender)
    }

    private func next() {
        if idx + 1 >= queue.count {
            finished = true
            if app.study.done[StudyLog.key()]?.contains("vocab") != true { app.study.done[StudyLog.key(), default: []].append("vocab") }
            app.save()
            AudioManager.shared.se(.studyClear, volume: 0.8)
            return
        }
        idx += 1
        prepare()
    }

    private var result: some View {
        VStack(spacing: 14) {
            OutlinedText(wrongIDs.isEmpty ? "PERFECT!" : "FINISH!", font: .en(42), fill: .sun)
            PaperCard {
                VStack(spacing: 8) {
                    Image("nyan").resizable().scaledToFit().frame(height: 90).modifier(Hop())
                    Text(jp(T("今日の|学習", "오늘의 학습", "今天的學習")) + "  \(words.count)" + jp(T("語", "단어", "個")))
                        .font(.ui(16)).foregroundStyle(Color.ink)
                    if newlyMastered > 0 {
                        Text("+\(newlyMastered) " + jp(T("語を|マスター！", "단어 마스터!", "個單字精通！"))).font(.display(22)).foregroundStyle(Color.popDeep)
                    }
                    Text(jp(T("マスターした単語", "마스터한 단어", "已精通的單字")) + "  \(app.vocab.masteredCount)").font(.en(18)).foregroundStyle(Color.ink)
                    Text(jp(T("覚えた単語は|ゲームの|敵の問題にも|出てくるよ！|実力を|試そう！", "외운 단어는 게임 적의 문제로도 나와! 실력을 시험해 보자!", "記住的單字也會出現在遊戲的敵人題目中！來試試實力吧！")))
                        .font(.ui(12, bold: false)).foregroundStyle(Color.ink.opacity(0.7)).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
            PopButton(title: T("おわる", "끝내기", "結束"), color: .pop, textColor: .white) { onClose() }
        }
        .padding(.horizontal, 16)
    }
}


/// The word pet: an egg that hatches and grows like a little virtual pet as you master words.
/// It sways all the time and jumps when you tap it.
struct VocabPet: View {
    let mastered: Int
    var size: CGFloat
    @EnvironmentObject var app: AppState
    @State private var jump = false

    static func stage(_ m: Int) -> Int {
        switch m { case ..<10: 0; case ..<50: 1; case ..<200: 2; case ..<500: 3; case ..<1000: 4; default: 5 }
    }

    var body: some View {
        Image("vocab_pet\(Self.stage(mastered))").resizable().scaledToFit().frame(height: size)
            .phaseAnimator([0.0, 1.0]) { v, p in
                v.scaleEffect(x: 1 + 0.035 * p, y: 1 - 0.045 * p, anchor: .bottom)
                    .rotationEffect(.degrees(-3 + 6 * p), anchor: .bottom)
            } animation: { _ in .easeInOut(duration: 0.85) }
            .modifier(LonelyLook(mood: Absence.mood(app), size: size))
            .offset(y: jump ? -size * 0.2 : 0)
            .contentShape(Rectangle())
            .onTapGesture {
                AudioManager.shared.se(.tap, rate: 1.6, volume: 0.6)
                withAnimation(.spring(response: 0.22, dampingFraction: 0.45)) { jump = true }
                later(0.22) { withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { jump = false } }
            }
    }
}
