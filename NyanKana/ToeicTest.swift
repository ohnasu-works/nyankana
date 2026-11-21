import SwiftUI
import Charts

// MARK: - Model

/// One TOEIC-style question.
struct TQ: Hashable {
    var key: String          // unique id
    var part: Int
    var prompt: String       // question text (Part 2: empty; the question is only heard)
    var choices: [String]
    var answer: Int
    var tip: String          // Japanese explanation
    var tag: String
}

/// A group that shares audio or a passage (Part 2 / 5 sets hold one question).
struct TSet: Identifiable, Hashable {
    var id: String
    var part: Int
    var audio: [String] = []      // "M:text" / "W:text" / "N:text"
    var passage: [String] = []
    var image: String? = nil       // Part 1 photograph
    var items: [TQ]
    var listening: Bool { part <= 4 }
}

enum ToeicTest {
    static let parts: [Int] = [1, 2, 3, 4, 5, 6, 7]
    static func name(_ p: Int) -> String {
        switch p {
        case 1: T("Part 1 写真描写", "Part 1 사진 묘사", "Part 1 照片描述")
        case 2: T("Part 2 応答問題", "Part 2 응답 문제", "Part 2 應答問題")
        case 3: T("Part 3 会話問題", "Part 3 대화 문제", "Part 3 對話問題")
        case 4: T("Part 4 説明文問題", "Part 4 설명문 문제", "Part 4 獨白問題")
        case 5: T("Part 5 短文穴うめ", "Part 5 단문 빈칸", "Part 5 單句填空")
        case 6: T("Part 6 長文穴うめ", "Part 6 장문 빈칸", "Part 6 段落填空")
        default: T("Part 7 読解", "Part 7 독해", "Part 7 閱讀理解")
        }
    }

    // MARK: parsing
    /// fixed (not random) rotation of the choices so the right answer isn't mostly A/B in the source data,
    /// and a paused mock test still matches after the app restarts
    static func mix(_ ch: [String], _ a: Int, _ seed: Int) -> ([String], Int) {
        let n = ch.count, r = (seed * 7 + 3) % max(1, n)
        return (Array(ch[r...] + ch[..<r]), (a - r + n) % n)
    }
    static let bank: [Int: [TSet]] = {
        var d: [Int: [TSet]] = [:]
        // Part 1: a photo and four statements that are only heard
        d[1] = (ToeicData.part1 + "\n" + ToeicData.part1b + "\n" + ToeicData.part1c).split(separator: "\n").enumerated().compactMap { i, line in
            let f = line.split(separator: "|", omittingEmptySubsequences: false).map { $0.trimmingCharacters(in: .whitespaces) }
            guard f.count == 8, let a = Int(f[5]) else { return nil }
            let (ch, ans) = mix(Array(f[1...4]), a, 0)
            let q = TQ(key: "p1.\(i)", part: 1, prompt: "", choices: ch, answer: ans, tip: f[6], tag: f[7])
            let audio = ["N:Look at the picture."] + ["A", "B", "C", "D"].enumerated().map { k, l in "N:\(l). \(ch[k])" }
            return TSet(id: "p1.\(i)", part: 1, audio: audio, image: f[0], items: [q])
        }
        // Part 2
        d[2] = (ToeicData.part2 + "\n" + ToeicData.part2b).split(separator: "\n").enumerated().compactMap { i, line in
            let f = line.split(separator: "|", omittingEmptySubsequences: false).map { $0.trimmingCharacters(in: .whitespaces) }
            guard f.count == 8, let a = Int(f[5]) else { return nil }
            let other = f[0] == "W" ? "M" : "W"
            let (ch, ans) = mix([f[2], f[3], f[4]], a, i)
            let q = TQ(key: "p2.\(i)", part: 2, prompt: "", choices: ch, answer: ans, tip: f[6], tag: f[7])
            return TSet(id: "p2.\(i)", part: 2, audio: ["\(f[0]):\(f[1])", "\(other):A. \(ch[0])", "\(other):B. \(ch[1])", "\(other):C. \(ch[2])"], items: [q])
        }
        // Part 3 / 4 / 6 / 7
        let j = "\n---\n"
        for (p, raw) in [(3, ToeicData.part3 + j + ToeicData.part3b), (4, ToeicData.part4 + j + ToeicData.part4b), (6, ToeicData.part6 + j + ToeicData.part6b), (7, ToeicData.part7 + j + ToeicData.part7b)] {
            d[p] = raw.components(separatedBy: "\n---\n").enumerated().map { si, block in
                var audio: [String] = [], passage: [String] = [], items: [TQ] = []
                for line in block.split(separator: "\n").map(String.init) {
                    if line.hasPrefix("Q:") {
                        let f = line.dropFirst(2).split(separator: "|", omittingEmptySubsequences: false).map { $0.trimmingCharacters(in: .whitespaces) }
                        guard f.count == 8, let a = Int(f[5]) else { continue }
                        let (ch, ans) = mix(Array(f[1...4]), a, si * 3 + items.count + p)
                        items.append(TQ(key: "p\(p).\(si).\(items.count)", part: p, prompt: f[0], choices: ch, answer: ans, tip: f[6], tag: f[7]))
                    } else if line.hasPrefix("P:") {
                        passage.append(line.dropFirst(2).trimmingCharacters(in: .whitespaces))
                    } else if line.count > 2 {
                        audio.append(line)
                    }
                }
                return TSet(id: "p\(p).\(si)", part: p, audio: audio, passage: passage, items: items)
            }
        }
        // Part 5 from the drill bank
        d[5] = ToeicBank.all.enumerated().map { i, q in
            // fixed (not random) order so a paused mock test still matches after the app restarts
            var ch = q.choices
            if !ch.contains(q.a) { ch[0] = q.a }
            let r = (i * 7 + 3) % max(1, ch.count)
            ch = Array(ch[r...] + ch[..<r])
            let tag = q.point.replacingOccurrences(of: "toeic.", with: "")
            let item = TQ(key: "p5.\(i)", part: 5, prompt: (q.pre.isEmpty ? "" : q.pre + " ") + "-------" + Question.sp(q.post),
                          choices: ch, answer: ch.firstIndex(of: q.a) ?? 0, tip: T("意味：", "뜻: ", "意思：") + q.meaning, tag: tag)
            return TSet(id: "p5.\(i)", part: 5, items: [item])
        }
        return d
    }()
    static func set(_ id: String) -> TSet? {
        let p = Int(id.dropFirst(1).prefix(1)) ?? 0
        return bank[p]?.first { $0.id == id }
    }

    /// weakest question types (needs a few answers each), worst first
    @MainActor static func weakTags(_ given: [String: [Int]]? = nil, max n: Int = 3) -> [String] {
        let stats = given ?? ToeicStore.tagStats
        func rate(_ v: [Int]) -> Double { Double(v[0]) / Double(max(1, v[1])) }
        return stats.filter { $0.value[1] >= 3 && rate($0.value) < 0.8 }
            .sorted { rate($0.value) < rate($1.value) }.prefix(n).map(\.key)
    }
    /// mini mock test (~20 questions) built only from the weak question types
    static func weakMock(_ tags: [String]) -> [String] {
        let want = Set(tags)
        guard !want.isEmpty else { return [] }
        var out: [TSet] = [], n = 0
        for s in bank.values.flatMap({ $0 }).shuffled() where s.items.contains(where: { want.contains($0.tag) }) {
            out.append(s); n += s.items.count
            if n >= 20 { break }
        }
        return out.sorted { $0.part < $1.part }.map(\.id)
    }

    /// practice: a few sets of one part
    static func practice(_ p: Int) -> [String] {
        let n = [1: 6, 2: 10, 3: 3, 4: 3, 5: 10, 6: 2, 7: 3][p] ?? 5
        return Array((bank[p] ?? []).shuffled().prefix(n)).map(\.id)
    }
    /// Part 7 sets with two or three documents
    static func isMulti(_ s: TSet) -> Bool { s.passage.contains { $0.hasPrefix("【文書") } }

    /// the mock test, listening first like the real test.
    /// full: 200 questions / 2 hours (P1 6, P2 25, P3 13 sets, P4 10 sets, P5 30, P6 4 sets, P7 54)
    /// half: about 100 questions / 1 hour
    static func mock(full: Bool) -> [String] {
        func pick(_ p: Int, _ n: Int) -> [TSet] { Array((bank[p] ?? []).shuffled().prefix(n)) }
        var out: [TSet] = []
        out += pick(1, full ? 6 : 3) + pick(2, full ? 25 : 12) + pick(3, full ? 13 : 6) + pick(4, full ? 10 : 5)
        out += pick(5, full ? 30 : 15) + pick(6, full ? 4 : 2)
        // Part 7: single passages up to the target, then the multi-document sets
        let p7 = (bank[7] ?? []).shuffled()
        var singles: [TSet] = [], n = 0
        for s in p7 where !isMulti(s) && n < (full ? 29 : 15) { singles.append(s); n += s.items.count }
        let multi = Array(p7.filter { isMulti($0) }.prefix(full ? 5 : 2))
        out += singles + multi
        return out.map(\.id)
    }
    static func seconds(full: Bool) -> Int { full ? 120 * 60 : 60 * 60 }

    /// section score 5...495 from the accuracy (a guide)
    static func score(_ right: Int, _ total: Int) -> Int {
        guard total > 0 else { return 5 }
        let r = Double(right) / Double(total)
        let table: [(Double, Double)] = [(0, 5), (0.25, 100), (0.5, 250), (0.7, 350), (0.85, 430), (0.95, 480), (1, 495)]
        for k in 1..<table.count where r <= table[k].0 {
            let (x0, y0) = table[k - 1], (x1, y1) = table[k]
            return Int(((y0 + (y1 - y0) * (r - x0) / (x1 - x0)) / 5).rounded()) * 5
        }
        return 495
    }
}

// MARK: - Advice per weak point

struct ToeicAdvice {
    let name: String
    let advice: String
    let lessons: [String]
    let part: Int?
    let mode: StudyMode?

    static func of(_ tag: String) -> ToeicAdvice {
        switch tag {
        case "people": .init(name: T("人物の動作（写真）", "인물의 동작(사진)", "人物動作（照片）"), advice: T("写真を|見たら|先に|「誰が|何を|しているか」を|英語で|思い浮かべよう。|動詞（-ing）を|しっかり|聞き取るのが|コツ。", "사진을 보면 먼저 '누가 무엇을 하는지' 영어로 떠올려 보세요. 동사(-ing)를 잘 들으세요.", "看到照片先用英文想「誰在做什麼」，仔細聽動詞（-ing）。"), lessons: [], part: 1, mode: .listening)
        case "object", "passive": .init(name: T("物の状態（写真）", "사물의 상태(사진)", "物品狀態（照片）"), advice: T("人が|いない|写真では|「物が|どう|置かれているか」が|正解。|being＋過去分詞（今〜されている）は|人が|いないと|使えないので|注意。", "사람이 없는 사진은 '물건이 어떻게 놓여 있는지'가 정답. being+과거분사는 사람이 없으면 쓸 수 없어요.", "沒有人的照片，正解是「物品如何擺放」。沒有人時不能用 being＋過去分詞。"), lessons: ["passive"], part: 1, mode: .listening)
        case "wh": .init(name: T("疑問詞の問い", "의문사 질문", "疑問詞問句"), advice: T("最初の|1語（Where／When／Who…）を|必ず|聞き取ろう。|答えの|種類が|決まります。", "첫 단어(Where/When/Who…)를 꼭 들으세요. 답의 종류가 정해집니다.", "一定要聽清楚第一個字（Where／When／Who…），它決定答案的類型。"), lessons: ["be.question", "verb.q"], part: 2, mode: .listening)
        case "yesno": .init(name: T("Yes/No 疑問文", "Yes/No 의문문", "Yes/No 問句"), advice: T("Yes/Noを|言わずに|答える|選択肢が|正解に|なりやすい。|意味で|つながるかを|確かめよう。", "Yes/No 없이 답하는 선택지가 정답인 경우가 많아요.", "不說 Yes/No 的回答常常是正解，要看意思是否連貫。"), lessons: ["perfect.done", "indirect"], part: 2, mode: .listening)
        case "request", "suggest": .init(name: T("依頼・提案", "의뢰·제안", "請求・提議"), advice: T("Could you〜／Why don't we〜は|お願いや|提案。|Sure や|Good idea で|応じる型を|覚えよう。", "Could you~/Why don't we~는 부탁·제안이에요. Sure/Good idea로 답하는 형태를 익히세요.", "Could you～／Why don't we～是請求或提議，記住用 Sure／Good idea 回應。"), lessons: ["modal.can", "modal.should"], part: 2, mode: .speak)
        case "choice", "statement": .init(name: T("選択・平叙文", "선택·평서문", "選擇・直述句"), advice: T("A or B には|Yes/Noで|答えない。|報告には|対応や|質問で|返す|応答が|正解。", "A or B에는 Yes/No로 답하지 않아요.", "A or B 不用 Yes/No 回答。"), lessons: ["conj.if"], part: 2, mode: .listening)
        case "gist", "purpose": .init(name: T("目的・話題", "목적·주제", "目的・主題"), advice: T("目的や|話題は|最初の|2文に|出やすい。|冒頭に|集中しよう。", "목적과 주제는 처음 두 문장에 나오기 쉬워요.", "目的和主題常出現在前兩句，要專心聽開頭。"), lessons: [], part: 3, mode: .listening)
        case "detail": .init(name: T("詳細の聞き取り・読み取り", "세부 정보", "細節"), advice: T("先に|設問を|読んで、|聞く（読む）|ポイントを|しぼろう。|数字や|曜日の|ひっかけに|注意。", "먼저 질문을 읽고 포인트를 좁히세요. 숫자·요일 함정에 주의.", "先讀題目鎖定重點，小心數字和星期的陷阱。"), lessons: [], part: 3, mode: .dictation)
        case "next", "inference", "intent": .init(name: T("推測・意図", "추측·의도", "推測・意圖"), advice: T("「次に何を|するか」は|会話の|最後に|出ます。|意図問題は|直前の|発言と|セットで|考えよう。", "'다음에 할 일'은 마지막에 나와요. 의도 문제는 직전 발언과 함께 생각하세요.", "「接下來做什麼」出現在最後；意圖題要搭配前一句來想。"), lessons: ["future.will", "future.going"], part: 4, mode: .listening)
        case "pos": .init(name: T("品詞", "품사", "詞性"), advice: T("空所の|前後だけ|見て、|名詞・形容詞・副詞の|どれが|入るかを|決めよう。|語尾（-tion／-ly など）が|手がかり。", "빈칸 앞뒤만 보고 명사·형용사·부사를 판단하세요. 어미가 힌트.", "只看空格前後判斷名詞、形容詞或副詞，字尾是線索。"), lessons: ["comp.more", "participle"], part: 5, mode: nil)
        case "verb": .init(name: T("動詞の形・時制", "동사 형태·시제", "動詞形式・時態"), advice: T("主語・時の|ことば（since, by tomorrow）・|受け身かどうかの|3点を|確認しよう。", "주어·시간 표현·수동태 여부를 확인하세요.", "確認主詞、時間詞和是否被動。"), lessons: ["perfect.cont", "passive", "past.perf", "future.prog"], part: 5, mode: nil)
        case "prep", "conj": .init(name: T("前置詞・接続詞", "전치사·접속사", "介系詞・連接詞"), advice: T("後ろが|名詞なら|前置詞、|文（主語＋動詞）なら|接続詞。|Despite と|Although を|区別しよう。", "뒤가 명사면 전치사, 문장이면 접속사.", "後面是名詞用介系詞，是句子用連接詞。"), lessons: ["logic.despite", "logic.although", "logic.unless", "nominal.whether"], part: 5, mode: nil)
        case "pron": .init(name: T("代名詞・関係詞", "대명사·관계사", "代名詞・關係詞"), advice: T("空所が|何を|指すかを|探そう。|人か|物か、|主格か|所有格かを|確かめて。", "빈칸이 무엇을 가리키는지 찾으세요.", "找出空格指的是什麼，確認是人或物、主格或所有格。"), lessons: ["rel.that", "rel.where", "rel.what", "rel.whose"], part: 5, mode: nil)
        case "vocab", "p6vocab": .init(name: T("語彙", "어휘", "詞彙"), advice: T("ビジネスで|よく出る|単語を、|たんごトレーニングの|TOEICコースで|毎日|増やそう。", "단어 트레이닝 TOEIC 코스로 매일 늘리세요.", "用單字訓練的 TOEIC 課程每天累積。"), lessons: [], part: 5, mode: nil)
        case "p6grammar": .init(name: T("長文の文法", "장문 문법", "段落文法"), advice: T("Part 6 は|1文だけで|解ける|文法問題から|先に|解こう。", "Part 6는 한 문장으로 풀리는 문법 문제부터.", "Part 6 先做只看一句就能解的文法題。"), lessons: ["passive", "rel.which"], part: 6, mode: nil)
        case "p6context": .init(name: T("文脈・文の挿入", "문맥·문장 삽입", "上下文・插入句"), advice: T("空所の|前と|後ろの|文を|読み、|話の|流れ（追加・逆接・理由）を|つかもう。", "앞뒤 문장을 읽고 흐름(추가·역접·이유)을 파악하세요.", "讀空格前後的句子，掌握語意流向（補充・轉折・原因）。"), lessons: ["logic.however", "logic.therefore"], part: 6, mode: nil)
        default: .init(name: T("語句の意味", "어구의 뜻", "詞義"), advice: T("文の中での|意味を|考えて|言い換えを|選ぼう。", "문장 속 의미로 판단하세요.", "依句中的意思選出換句。"), lessons: [], part: 7, mode: nil)
        }
    }
}

// MARK: - Saved progress (mock test can be paused and resumed) and stats

struct ToeicMockState: Codable {
    var sets: [String]
    var full: Bool? = nil    // nil: an older, shorter test
    var answers: [String: Int] = [:]
    var index = 0            // flat question index
    var elapsed = 0          // seconds
    var partTime: [Int: Int]? = nil   // seconds spent per part
}

struct ToeicResult: Codable, Identifiable, Equatable {
    var id = UUID()
    var date = Date()
    var listening: Int
    var reading: Int
    var byPart: [Int: [Int]]       // part -> [right, total]
    var byTag: [String: [Int]]
    // kept for answer checking and review (nil in results saved by older builds)
    var sets: [String]? = nil
    var answers: [String: Int]? = nil
    var full: Bool? = nil
    var partTime: [Int: Int]? = nil   // seconds spent per part (mock tests)
    var total: Int { listening + reading }
}

@MainActor
enum ToeicStore {
    private static let d = UserDefaults.standard
    static var mock: ToeicMockState? {
        get { d.data(forKey: "toeic.mock").flatMap { try? JSONDecoder().decode(ToeicMockState.self, from: $0) } }
        set { if let newValue, let data = try? JSONEncoder().encode(newValue) { d.set(data, forKey: "toeic.mock") } else { d.removeObject(forKey: "toeic.mock") } }
    }
    /// wrong-answer notebook: ids of sets with a mistake (removed when solved in review)
    static var wrong: [String] {
        get { d.stringArray(forKey: "toeic.wrong") ?? [] }
        set { d.set(Array(newValue.suffix(200)), forKey: "toeic.wrong") }
    }
    /// target score (0 = not set)
    static var goal: Int {
        get { d.integer(forKey: "toeic.goal") }
        set { d.set(newValue, forKey: "toeic.goal") }
    }
    static var results: [ToeicResult] {
        get { d.data(forKey: "toeic.results").flatMap { try? JSONDecoder().decode([ToeicResult].self, from: $0) } ?? [] }
        set { if let data = try? JSONEncoder().encode(Array(newValue.suffix(30))) { d.set(data, forKey: "toeic.results") } }
    }
    /// right / total per tag, practice and mock together
    static var tagStats: [String: [Int]] {
        get { (d.dictionary(forKey: "toeic.tags") as? [String: [Int]]) ?? [:] }
        set { d.set(newValue, forKey: "toeic.tags") }
    }
    static func record(_ q: TQ, _ ok: Bool) {
        var s = tagStats; var v = s[q.tag] ?? [0, 0]; v[1] += 1; if ok { v[0] += 1 }; s[q.tag] = v; tagStats = s
    }
}

// MARK: - Runner (practice or mock)

struct ToeicRunView: View {
    enum Mode: Equatable { case practice(Int), mock(full: Bool), review([String]) }
    let mode: Mode
    var close: () -> Void
    @EnvironmentObject var app: AppState

    @State private var sets: [TSet] = []
    @State private var flat: [(set: Int, item: Int)] = []
    @State private var i = 0
    @State private var answers: [String: Int] = [:]
    @State private var chosen: Int?
    @State private var elapsed = 0
    @State private var partTime: [Int: Int] = [:]
    @State private var playedSet: String?
    @State private var playing = false
    @State private var result: ToeicResult?
    @State private var started = false
    @State private var showText = false   // practice: show the Part 2 answers as text

    private var isMock: Bool { if case .mock = mode { return true }; return false }
    @State private var full = true
    private var limit: Int { ToeicTest.seconds(full: full) }

    var body: some View {
        ZStack {
            Color(hex: 0xF6F7FB).ignoresSafeArea()
            if let result {
                ToeicReportView(result: result, close: close)
            } else if i < flat.count {
                VStack(spacing: 10.s) {
                    topBar
                    question
                    // the next button stays on screen (no scrolling down to find it)
                    if chosen != nil && !isMock {
                        PopButton(title: i + 1 >= flat.count ? T("けっかを見る", "결과 보기", "查看結果") : T("つぎへ", "다음", "下一題"), color: .pop, textColor: .white) { next() }
                            .padding(.bottom, 6)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: UIScale.isPad ? 820 : .infinity)
            }
        }
        .onAppear(perform: begin)
        .onDisappear { Speaker.shared.stop() }
        .task(id: started) {
            guard isMock, started else { return }
            while !Task.isCancelled, result == nil {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                elapsed += 1
                if i < flat.count { partTime[sets[flat[i].set].part, default: 0] += 1 }
                if elapsed % 10 == 0 { save() }
                if elapsed >= limit { finish() }
            }
        }
    }

    // MARK: parts

    private var topBar: some View {
        let (si, _) = flat[i]
        return HStack(spacing: 10.s) {
            if isMock {
                Button { Speaker.shared.stop(); save(); close() } label: {
                    Label(T("中断して保存", "중단하고 저장", "暫停並儲存"), systemImage: "pause.circle.fill").font(.ui(13.s)).foregroundStyle(Color.ink)
                        .padding(.horizontal, 12.s).padding(.vertical, 7.s)
                        .background(Capsule().fill(Color.white).overlay(Capsule().stroke(Color.ink, lineWidth: 2.5)))
                }
                .buttonStyle(.plain)
                .padding(.top, UIScale.isPad ? 30 : 0)
            } else {
                BackChip { Speaker.shared.stop(); close() }
            }
            Spacer()
            VStack(spacing: 0) {
                Text(ToeicTest.name(sets[si].part)).font(.ui(13.s)).foregroundStyle(Color.ink)
                Text("\(i + 1)/\(flat.count)").font(.en(13.s)).foregroundStyle(Color.ink.opacity(0.6))
            }
            Spacer()
            if isMock {
                let left = max(0, limit - elapsed)
                Text(String(format: "%d:%02d", left / 60, left % 60)).font(.en(18.s)).foregroundStyle(left < 300 ? Color.popDeep : Color.ink)
                    .frame(minWidth: 64.s)
            } else {
                Color.clear.frame(width: 64.s, height: 1)
            }
        }
        .padding(.top, 6)
    }

    @ViewBuilder private var question: some View {
        let (si, ii) = flat[i]
        let s = sets[si]
        let q = s.items[ii]
        ScrollViewReader { proxy in
        ScrollView {
            VStack(alignment: .leading, spacing: 12.s) {
                if s.listening {
                    HStack(spacing: 10.s) {
                        Image(systemName: playing ? "speaker.wave.3.fill" : "headphones").font(.system(size: 22.s, weight: .bold)).foregroundStyle(Color.ink)
                        Text(jp(playing ? T("再生中…", "재생 중…", "播放中…") : isMock ? T("音声は|1回だけ|流れます", "음성은 한 번만 나옵니다", "音檔只播放一次") : T("音声を|聞いて|答えよう", "음성을 듣고 답하세요", "聽音檔作答")))
                            .font(.ui(14.s)).foregroundStyle(Color.ink)
                        Spacer()
                        if !isMock && s.part <= 2 && !showText {
                            Button { AudioManager.shared.se(.tap); showText = true } label: {
                                Text(T("文字で見る", "글자로 보기", "看文字")).font(.ui(12.s))
                                    .padding(.horizontal, 10.s).padding(.vertical, 6.s)
                                    .background(Capsule().fill(Color.white).overlay(Capsule().stroke(Color.ink, lineWidth: 2)))
                            }
                            .buttonStyle(.plain).foregroundStyle(Color.ink)
                        }
                        if !isMock && !playing {
                            Button { play(s) } label: {
                                Label(T("もう一度", "다시", "再聽"), systemImage: "arrow.counterclockwise").font(.ui(13.s))
                                    .padding(.horizontal, 12.s).padding(.vertical, 6.s)
                                    .background(Capsule().fill(Color.sun).overlay(Capsule().stroke(Color.ink, lineWidth: 2)))
                            }
                            .buttonStyle(.plain).foregroundStyle(Color.ink)
                        }
                    }
                    .padding(12.s)
                    .background(RoundedRectangle(cornerRadius: 14.s).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 14.s).stroke(Color.ink, lineWidth: 2)))
                }
                if let img = s.image {
                    Image(img).resizable().scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: UIScale.isPad ? 420 : 260)
                        .clipShape(RoundedRectangle(cornerRadius: 12.s))
                        .overlay(RoundedRectangle(cornerRadius: 12.s).stroke(Color.ink, lineWidth: 2))
                }
                if !s.passage.isEmpty {
                    VStack(alignment: .leading, spacing: 6.s) {
                        ForEach(Array(s.passage.enumerated()), id: \.offset) { _, line in
                            Text(line).font(.system(size: 15.s, design: .serif)).foregroundStyle(Color.ink).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(14.s)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 12.s).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 12.s).stroke(Color.ink.opacity(0.4), lineWidth: 1.5)))
                }
                // the question
                if !q.prompt.isEmpty {
                    Text((s.items.count > 1 ? "Q\(ii + 1). " : "") + q.prompt).font(.system(size: 17.s, weight: .semibold)).foregroundStyle(Color.ink)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(jp(s.part == 1 ? T("写真を|最も|よく|表している|文を|選ぼう", "사진을 가장 잘 묘사한 문장을 고르세요", "選出最能描述照片的句子") : T("最も|適切な|応答を|選ぼう", "가장 알맞은 응답을 고르세요", "選出最適當的回應"))).font(.ui(15.s)).foregroundStyle(Color.ink)
                }
                ForEach(Array(q.choices.enumerated()), id: \.offset) { k, c in
                    choiceRow(q, k, c, hidden: s.part <= 2 && chosen == nil && !showText)
                }
                if let chosen, !isMock {
                    let ok = chosen == q.answer
                    VStack(alignment: .leading, spacing: 6.s) {
                        Text(ok ? "GREAT!" : "CHECK!").font(.en(22.s)).foregroundStyle(ok ? Color.mintDeep : Color.popDeep)
                        Text(L10n.current == .ja ? q.tip : T("", "정답: ", "正解：", vi: "Đáp án: ", es: "Respuesta: ", pt: "Resposta: ", en: "Answer: ") + q.choices[q.answer]).font(.ui(14.s, bold: false)).foregroundStyle(Color.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        if s.listening && ii == s.items.count - 1 {
                            DisclosureGroup(T("スクリプトを見る", "스크립트 보기", "查看原文")) {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(Array(s.audio.enumerated()), id: \.offset) { _, l in Text(l).font(.system(size: 14.s)).foregroundStyle(Color.ink) }
                                }
                            }
                            .font(.ui(13.s)).tint(Color.ink)
                        }
                    }
                    .padding(12.s)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 12.s).fill(ok ? Color(hex: 0xE8FFF5) : Color(hex: 0xFFEDF3)))
                    .id("feedback")
                }
            }
            .padding(.vertical, 6)
        }
        .onChange(of: chosen) { _, v in
            if v != nil && !isMock { later(0.15) { withAnimation(.easeOut(duration: 0.35)) { proxy.scrollTo("feedback", anchor: .bottom) } } }
        }
        }
    }

    private func choiceRow(_ q: TQ, _ k: Int, _ c: String, hidden: Bool) -> some View {
        let letter = ["A", "B", "C", "D"][k]
        let done = chosen != nil && !isMock
        let bg: Color = !done ? (chosen == k ? Color.sun : .white) : k == q.answer ? Color(hex: 0xBFF3DD) : chosen == k ? Color(hex: 0xFFC9D9) : .white
        return Button {
            guard chosen == nil else { return }
            pick(q, k)
        } label: {
            HStack(spacing: 10.s) {
                Text(letter).font(.en(17.s)).foregroundStyle(.white).frame(width: 32.s, height: 32.s).background(Circle().fill(Color.ink))
                if hidden {
                    Label(T("音声で|流れる|応答", "음성으로 나오는 응답", "以音檔播放的回應").replacingOccurrences(of: "|", with: ""), systemImage: "speaker.wave.2.fill")
                        .font(.ui(14.s, bold: false)).foregroundStyle(Color.ink.opacity(0.45))
                } else {
                    Text(c).font(.system(size: 16.s, weight: .medium)).foregroundStyle(Color.ink).multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12.s).frame(minHeight: 50.s)
            .background(RoundedRectangle(cornerRadius: 12.s).fill(bg).overlay(RoundedRectangle(cornerRadius: 12.s).stroke(Color.ink, lineWidth: 2)))
        }
        .buttonStyle(.plain)
    }

    // MARK: flow

    private func begin() {
        guard !started else { return }
        let ids: [String]
        if isMock, let saved = ToeicStore.mock {
            ids = saved.sets; answers = saved.answers; i = saved.index; elapsed = saved.elapsed; partTime = saved.partTime ?? [:]
            full = saved.full ?? false
        } else if case .mock(let f) = mode {
            full = f
            ids = ToeicTest.mock(full: f); ToeicStore.mock = ToeicMockState(sets: ids, full: f)
        } else if case .practice(let p) = mode {
            ids = ToeicTest.practice(p)
        } else if case .review(let r) = mode {
            ids = r
        } else { ids = [] }
        sets = ids.compactMap { ToeicTest.set($0) }
        flat = sets.enumerated().flatMap { si, s in s.items.indices.map { (si, $0) } }
        i = min(i, max(0, flat.count - 1))
        started = true
        enterQuestion()
    }

    private func enterQuestion() {
        guard i < flat.count else { return }
        chosen = nil; showText = false
        let s = sets[flat[i].set]
        if s.listening && playedSet != s.id { play(s) }
    }

    private func play(_ s: TSet) {
        playedSet = s.id
        playing = true
        let lines: [(Speaker.Who, String)] = s.audio.map { l in
            let who: Speaker.Who = l.hasPrefix("M:") ? .man : l.hasPrefix("W:") ? .woman : .narrator
            return (who, String(l.dropFirst(2)).trimmingCharacters(in: .whitespaces))
        }
        Speaker.shared.sayLines(lines, gap: s.part <= 2 ? 0.8 : 0.45) { playing = false }
    }

    private func pick(_ q: TQ, _ k: Int) {
        chosen = k
        answers[q.key] = k
        let ok = k == q.answer
        ToeicStore.record(q, ok)
        if isMock {
            AudioManager.shared.se(.tap, rate: 1.3, volume: 0.4)
            save()
            later(0.35) { next() }
        } else {
            AudioManager.shared.se(ok ? .studyOK : .studyNG, volume: 0.8)
        }
    }

    private func next() {
        if i + 1 >= flat.count { finish(); return }
        i += 1
        if isMock { save() }
        enterQuestion()
    }

    private func save() {
        guard isMock, result == nil else { return }
        ToeicStore.mock = ToeicMockState(sets: sets.map(\.id), full: full, answers: answers, index: i, elapsed: elapsed, partTime: partTime)
    }

    private func finish() {
        guard result == nil else { return }
        Speaker.shared.stop()
        var byPart: [Int: [Int]] = [:], byTag: [String: [Int]] = [:]
        var lr = [0, 0], lt = [0, 0]
        for s in sets { for q in s.items {
            let ok = answers[q.key] == q.answer
            var p = byPart[q.part] ?? [0, 0]; p[1] += 1; if ok { p[0] += 1 }; byPart[q.part] = p
            var t = byTag[q.tag] ?? [0, 0]; t[1] += 1; if ok { t[0] += 1 }; byTag[q.tag] = t
            let k = q.part <= 4 ? 0 : 1; lt[k] += 1; if ok { lr[k] += 1 }
        } }
        let r = ToeicResult(listening: lt[0] > 0 ? ToeicTest.score(lr[0], lt[0]) : 0, reading: lt[1] > 0 ? ToeicTest.score(lr[1], lt[1]) : 0, byPart: byPart, byTag: byTag,
                            sets: sets.map(\.id), answers: answers, full: isMock ? full : nil, partTime: isMock ? partTime : nil)
        // wrong-answer notebook: add sets with a mistake, drop sets now solved
        var w = ToeicStore.wrong
        for s in sets {
            if s.items.contains(where: { answers[$0.key] != $0.answer }) { if !w.contains(s.id) { w.append(s.id) } }
            else { w.removeAll { $0 == s.id } }
        }
        ToeicStore.wrong = w
        if isMock {
            ToeicStore.mock = nil
            ToeicStore.results = ToeicStore.results + [r]
            app.study.best["toeicMock"] = max(app.study.best["toeicMock"] ?? 0, r.total)
            app.study.finish(.toeicMock)
        } else {
            app.study.finish(.toeic)
        }
        app.save()
        AudioManager.shared.se(.studyClear, volume: 0.8)
        withAnimation { result = r }
    }
}

// MARK: - Report: score, parts, weak points, advice, recommended lessons and practice

struct ToeicReportView: View {
    let result: ToeicResult
    var close: () -> Void
    @EnvironmentObject var app: AppState
    @State private var lesson: GrammarLesson?
    @State private var practice: Int?

    var body: some View {
        ScrollView {
            VStack(spacing: 14.s) {
                HStack { BackChip { close() }; Spacer() }.padding(.top, 6)
                PaperCard {
                    VStack(spacing: 8.s) {
                        Text(jp(T("スコアの|目安", "예상 점수", "預估分數"))).font(.ui(14.s)).foregroundStyle(Color.ink.opacity(0.7))
                        if result.listening > 0 && result.reading > 0 {
                            Text("\(result.total)").font(.en(54.s)).foregroundStyle(Color(hex: 0x2E4A8C))
                        }
                        HStack(spacing: 24.s) {
                            if result.listening > 0 { scoreBox("LISTENING", result.listening) }
                            if result.reading > 0 { scoreBox("READING", result.reading) }
                        }
                        Text(jp(T("※ 問題数を|へらした|模試からの|目安です", "※ 문제 수를 줄인 모의고사 기준의 참고치입니다", "※ 這是題數較少的模擬考推估值"))).font(.ui(11.s, bold: false)).foregroundStyle(Color.ink.opacity(0.55))
                        if let prev = ToeicStore.results.dropLast().last, result.listening > 0 && result.reading > 0 {
                            let d = result.total - prev.total
                            Text(jp(T("前回から", "지난번보다", "比上次")) + " \(d >= 0 ? "+" : "")\(d)").font(.ui(13.s)).foregroundStyle(d >= 0 ? Color.mintDeep : Color.popDeep)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                PaperCard {
                    VStack(alignment: .leading, spacing: 8.s) {
                        PopHeading(text: T("パート別", "파트별", "各大題"))
                        ForEach(result.byPart.keys.sorted(), id: \.self) { p in bar(ToeicTest.name(p), result.byPart[p] ?? [0, 0]) }
                    }
                }
                if let pt = result.partTime, !pt.isEmpty { timeCard(pt) }
                if let ids = result.sets, let ans = result.answers { reviewCard(ids, ans) }
                advice
                history
            }
            .padding(.horizontal, 16).padding(.bottom, 30)
            .frame(maxWidth: UIScale.isPad ? 820 : .infinity)
        }
        .background(Color(hex: 0xF6F7FB).ignoresSafeArea())
        .sheet(item: $lesson) { l in NavigationStack { LessonView(lesson: l) }.environmentObject(app) }
        .sheet(isPresented: $showAnswers) { ToeicAnswerSheet(ids: result.sets ?? [], answers: result.answers ?? [:]) }
        .sheet(item: $other) { r in ToeicReportView(result: r) { other = nil }.environmentObject(app) }
        .fullScreenCover(item: $redo) { b in ToeicRunView(mode: .review(b.ids)) { redo = nil }.environmentObject(app) }
        .fullScreenCover(item: Binding(get: { practice.map { PartBox(part: $0) } }, set: { practice = $0?.part })) { b in
            ToeicRunView(mode: .practice(b.part)) { practice = nil }.environmentObject(app)
        }
    }

    private struct PartBox: Identifiable { let part: Int; var id: Int { part } }
    private struct IDBox: Identifiable { let ids: [String]; var id: String { ids.joined(separator: ",") } }
    @State private var showAnswers = false
    @State private var other: ToeicResult?
    @State private var redo: IDBox?
    @State private var goal = ToeicStore.goal

    /// answer check + redo the missed questions
    private func reviewCard(_ ids: [String], _ ans: [String: Int]) -> some View {
        let sets = ids.compactMap { ToeicTest.set($0) }
        let qs = sets.flatMap(\.items)
        let missed = qs.filter { ans[$0.key] != $0.answer }.count
        let wrongSets = sets.filter { s in s.items.contains { ans[$0.key] != $0.answer } }.map(\.id)
        return PaperCard {
            VStack(alignment: .leading, spacing: 10.s) {
                PopHeading(text: T("答え合わせと復習", "채점과 복습", "對答案與複習"))
                Text(jp(T("\(qs.count)問中 |まちがい・|未回答 |\(missed)問", "\(qs.count)문제 중 오답·미응답 \(missed)문제", "\(qs.count)題中 答錯・未作答 \(missed)題", vi: "Sai hoặc bỏ trống \(missed)/\(qs.count) câu", es: "\(missed) de \(qs.count) incorrectas o sin responder", pt: "\(missed) de \(qs.count) erradas ou sem resposta", en: "\(missed) of \(qs.count) wrong or unanswered")))
                    .font(.ui(14.s)).foregroundStyle(Color.ink)
                PopButton(title: T("答え合わせを見る", "채점 보기", "查看對答案"), color: .sun, height: 46) { AudioManager.shared.se(.decide); showAnswers = true }
                if !wrongSets.isEmpty {
                    PopButton(title: T("まちがえた問題を解き直す", "틀린 문제 다시 풀기", "重做答錯的題目"), color: .pop, textColor: .white, height: 46) {
                        AudioManager.shared.se(.decide); redo = IDBox(ids: wrongSets)
                    }
                }
                Text(jp(T("まちがえた|問題は|自動で|保存。|TOEICメニューの|「まちがえた|問題を|解き直す」から|いつでも|復習|できて、|正解すると|リストから|消えるよ。", "틀린 문제는 자동 저장돼요. TOEIC 메뉴에서 언제든 복습하고, 맞히면 목록에서 사라져요.", "答錯的題目會自動儲存，可隨時從TOEIC選單複習，答對後就會從清單移除。")))
                    .font(.ui(12.s, bold: false)).foregroundStyle(Color.ink.opacity(0.65))
            }
        }
    }

    /// time used per part, with a target pace and advice
    private func timeCard(_ pt: [Int: Int]) -> some View {
        // target seconds per question (reading parts; listening runs at the audio's pace)
        let pace: [Int: Int] = [5: 20, 6: 30, 7: 60]
        let counts = result.byPart.mapValues { $0[1] }
        let slow = [5, 6, 7].filter { p in
            guard let s = pt[p], let n = counts[p], n > 0, let t = pace[p] else { return false }
            return Double(s) / Double(n) > Double(t) * 1.25
        }
        let unanswered = (result.answers.map { a in (result.sets ?? []).compactMap { ToeicTest.set($0) }.flatMap(\.items).filter { a[$0.key] == nil }.count }) ?? 0
        func mmss(_ s: Int) -> String { String(format: "%d:%02d", s / 60, s % 60) }
        return PaperCard {
            VStack(alignment: .leading, spacing: 8.s) {
                PopHeading(text: T("時間配分", "시간 배분", "時間分配"))
                ForEach(pt.keys.sorted(), id: \.self) { p in
                    let s = pt[p] ?? 0, n = max(1, counts[p] ?? 1)
                    HStack(spacing: 6.s) {
                        Text(jp(ToeicTest.name(p))).font(.ui(13.s))
                        Spacer()
                        Text(mmss(s)).font(.en(14.s))
                        Text(jp(T("1問 |\(s / n)秒", "1문제 \(s / n)초", "每題 \(s / n)秒", vi: "\(s / n) giây mỗi câu", es: "\(s / n) s por pregunta", pt: "\(s / n) s por questão", en: "\(s / n) s per question"))).font(.ui(11.s, bold: false)).foregroundStyle(Color.ink.opacity(0.6))
                            .frame(width: 70.s, alignment: .trailing)
                        if let t = pace[p] {
                            Image(systemName: s / n > Int(Double(t) * 1.25) ? "tortoise.fill" : "hare.fill")
                                .foregroundStyle(s / n > Int(Double(t) * 1.25) ? Color.popDeep : Color.mintDeep)
                        } else { Color.clear.frame(width: 18, height: 1) }
                    }
                    .foregroundStyle(Color.ink)
                }
                Text(jp(T("目安：|Part 5は|1問20秒、|Part 6は|1問30秒、|Part 7は|1問60秒。", "기준: Part 5는 1문제 20초, Part 6은 30초, Part 7은 60초.", "標準：Part 5每題20秒、Part 6每題30秒、Part 7每題60秒。")))
                    .font(.ui(11.s, bold: false)).foregroundStyle(Color.ink.opacity(0.6))
                VStack(alignment: .leading, spacing: 6.s) {
                    if slow.contains(5) || slow.contains(6) {
                        tipLine(T("Part 5・6で|時間を|使いすぎ。|わからない|問題は|迷わず|勘で|選んで、|Part 7に|時間を|残そう。", "Part 5·6에서 시간을 너무 썼어요. 모르는 문제는 바로 찍고 Part 7에 시간을 남기세요.", "Part 5・6花太多時間。不會的題目直接猜，把時間留給Part 7。"))
                    }
                    if slow.contains(7) {
                        tipLine(T("Part 7は|先に|設問を|読んでから|本文で|答えを|探すと|速くなるよ。", "Part 7은 질문을 먼저 읽고 본문에서 답을 찾으면 빨라져요.", "Part 7先讀題目再到本文找答案會比較快。"))
                    }
                    if unanswered > 0 {
                        tipLine(T("時間切れで|\(unanswered)問|未回答。|TOEICは|まちがえても|減点|されないので、|最後は|全部|マークしよう。", "시간 초과로 \(unanswered)문제 미응답. 틀려도 감점이 없으니 끝에는 전부 마킹하세요.", "時間到有\(unanswered)題未作答。答錯不扣分，最後全部都要作答。", vi: "Hết giờ, còn \(unanswered) câu chưa làm. TOEIC không trừ điểm câu sai, nên cuối giờ hãy chọn hết.", es: "Se acabó el tiempo con \(unanswered) sin responder. En TOEIC los errores no restan: al final, marca todas.", pt: "O tempo acabou com \(unanswered) sem resposta. No TOEIC erro não desconta: no fim, marque todas.", en: "Time ran out with \(unanswered) unanswered. Wrong answers cost nothing on the TOEIC, so mark every one at the end."))
                    }
                    if slow.isEmpty && unanswered == 0 {
                        tipLine(T("時間配分は|ばっちり！|このペースを|キープしよう。", "시간 배분 완벽! 이 페이스를 유지하세요.", "時間分配很完美！保持這個步調。"))
                    }
                }
            }
        }
    }

    private func tipLine(_ t: String) -> some View {
        HStack(alignment: .top, spacing: 6.s) {
            Image(systemName: "lightbulb.fill").foregroundStyle(Color.sunDeep)
            Text(jp(t)).font(.ui(13.s, bold: false)).foregroundStyle(Color.ink).fixedSize(horizontal: false, vertical: true)
        }
    }

    /// past mock results (score trend); tap to open that report
    @ViewBuilder private var history: some View {
        let all = ToeicStore.results.filter { $0.listening > 0 && $0.reading > 0 }
        if all.count >= 1 {
            PaperCard {
                VStack(alignment: .leading, spacing: 8.s) {
                    PopHeading(text: T("これまでの記録", "지금까지의 기록", "歷來紀錄"))
                    // target score
                    HStack(spacing: 8.s) {
                        Text(jp(T("目標スコア", "목표 점수", "目標分數"))).font(.ui(13.s)).foregroundStyle(Color.ink)
                        Menu {
                            Button(T("設定しない", "설정 안 함", "不設定")) { goal = 0; ToeicStore.goal = 0 }
                            ForEach(Array(stride(from: 400, through: 990, by: 50)).map { min($0, 990) } + [990], id: \.self) { g in
                                Button("\(g)") { goal = g; ToeicStore.goal = g }
                            }
                        } label: {
                            Text(goal > 0 ? "\(goal)" : T("えらぶ", "선택", "選擇")).font(.en(15.s)).foregroundStyle(Color.ink)
                                .padding(.horizontal, 12.s).padding(.vertical, 4.s)
                                .background(Capsule().fill(Color.sun).overlay(Capsule().stroke(Color.ink, lineWidth: 2)))
                        }
                        Spacer()
                        if goal > 0, let last = all.last {
                            Text(jp(last.total >= goal ? T("目標|達成！", "목표 달성!", "達成目標！") : T("あと |\(goal - last.total)点", "앞으로 \(goal - last.total)점", "還差\(goal - last.total)分", vi: "Còn \(goal - last.total) điểm", es: "Faltan \(goal - last.total) puntos", pt: "Faltam \(goal - last.total) pontos", en: "\(goal - last.total) points to go")))
                                .font(.ui(14.s)).foregroundStyle(last.total >= goal ? Color.mintDeep : Color.popDeep)
                        }
                    }
                    if all.count >= 2 || goal > 0 {
                        Chart {
                            ForEach(Array(all.suffix(10).enumerated()), id: \.offset) { k, r in
                                LineMark(x: .value("回", k + 1), y: .value("点", r.total)).foregroundStyle(Color(hex: 0x2E4A8C))
                                PointMark(x: .value("回", k + 1), y: .value("点", r.total)).foregroundStyle(r.id == result.id ? Color.pop : Color(hex: 0x2E4A8C))
                            }
                            if goal > 0 {
                                RuleMark(y: .value("目標", goal)).foregroundStyle(Color.popDeep).lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 4]))
                                    .annotation(position: .top, alignment: .leading) { Text(T("目標", "목표", "目標")).font(.ui(10.s)).foregroundStyle(Color.popDeep) }
                            }
                        }
                        .chartYScale(domain: 0...990)
                        .chartXAxis(.hidden)
                        .frame(height: 150.s)
                    }
                    let top = max(1, all.map(\.total).max() ?? 1)
                    ForEach(Array(all.suffix(10).reversed())) { r in
                        Button { if r.id != result.id { AudioManager.shared.se(.tap); other = r } } label: {
                            HStack(spacing: 8.s) {
                                Text(r.date.formatted(.dateTime.month().day())).font(.en(13.s)).frame(width: 54.s, alignment: .leading)
                                Text(jp(r.full == true ? T("本格", "실전", "正式") : r.full == false ? T("ハーフ", "하프", "半份") : "-")).font(.ui(11.s)).frame(width: 44.s, alignment: .leading)
                                GeometryReader { g in
                                    Capsule().fill(r.id == result.id ? Color.pop : Color(hex: 0x2E4A8C).opacity(0.55))
                                        .frame(width: max(8, g.size.width * CGFloat(r.total) / CGFloat(top)))
                                }
                                .frame(height: 12.s)
                                Text("\(r.total)").font(.en(15.s)).frame(width: 48.s, alignment: .trailing)
                            }
                            .foregroundStyle(Color.ink)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func scoreBox(_ t: String, _ v: Int) -> some View {
        VStack(spacing: 0) {
            Text(t).font(.en(12.s)).foregroundStyle(Color.ink.opacity(0.6))
            Text("\(v)").font(.en(28.s)).foregroundStyle(Color.ink)
        }
    }

    private func bar(_ name: String, _ v: [Int]) -> some View {
        let r = v[1] > 0 ? Double(v[0]) / Double(v[1]) : 0
        return VStack(alignment: .leading, spacing: 3) {
            HStack { Text(jp(name)).font(.ui(13.s)); Spacer(); Text("\(v[0])/\(v[1])").font(.en(13.s)) }.foregroundStyle(Color.ink)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.ink.opacity(0.1))
                    Capsule().fill(r >= 0.8 ? Color.mint : r >= 0.5 ? Color.sun : Color.pop).frame(width: g.size.width * r)
                }
            }
            .frame(height: 10.s)
        }
    }

    /// weakest points of this test (with the stats from practice as a tie-breaker)
    @ViewBuilder private var advice: some View {
        let stats = result.byTag.filter { $0.value[1] > 0 }
        let weak = stats.sorted { Double($0.value[0]) / Double($0.value[1]) < Double($1.value[0]) / Double($1.value[1]) }
            .filter { Double($0.value[0]) / Double($0.value[1]) < 0.8 }.prefix(3)
        PaperCard {
            VStack(alignment: .leading, spacing: 12.s) {
                PopHeading(text: T("じぶん分析と|対策", "자기 분석과 대책", "自我分析與對策"))
                if weak.isEmpty {
                    HStack(spacing: 8.s) {
                        Image("nyan").resizable().scaledToFit().frame(height: 50.s)
                        Text(jp(T("にがてな|ところは|見つからなかったにゃ！|この調子で|全パートを|続けよう。", "약점이 없었어! 이대로 계속하자.", "沒有發現弱點喵！繼續保持。"))).font(.ui(14.s)).foregroundStyle(Color.ink)
                    }
                }
                if !weak.isEmpty {
                    let ids = ToeicTest.weakMock(weak.map(\.key))
                    if !ids.isEmpty {
                        PopButton(title: T("にがてだけのミニ模試（約20問）", "약점만 미니 모의고사 (약 20문제)", "弱點迷你模擬考（約20題）"), color: .pop, textColor: .white, height: 46) {
                            AudioManager.shared.se(.decide); redo = IDBox(ids: ids)
                        }
                    }
                }
                ForEach(Array(weak), id: \.key) { tag, v in
                    let a = ToeicAdvice.of(tag)
                    VStack(alignment: .leading, spacing: 6.s) {
                        HStack {
                            Text(jp(a.name)).font(.ui(15.s)).foregroundStyle(Color.ink)
                            Spacer()
                            Text("\(v[0])/\(v[1])").font(.en(15.s)).foregroundStyle(Color.popDeep)
                        }
                        Text(jp(a.advice)).font(.ui(13.s, bold: false)).foregroundStyle(Color.ink).fixedSize(horizontal: false, vertical: true)
                        FlowRow(spacing: 6) {
                            ForEach(a.lessons, id: \.self) { id in
                                if let l = Library.lessons.first(where: { $0.id == id }) {
                                    chip("book.fill", jp(l.title), Color(hex: 0xFFD66B)) { lesson = l }
                                }
                            }
                            if let p = a.part { chip("headphones", ToeicTest.name(p), Color(hex: 0xBFD7FF)) { practice = p } }
                        }
                    }
                    .padding(12.s)
                    .background(RoundedRectangle(cornerRadius: 14.s).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 14.s).stroke(Color.ink.opacity(0.35), lineWidth: 1.5)))
                }
            }
        }
    }

    private func chip(_ icon: String, _ t: String, _ c: Color, _ a: @escaping () -> Void) -> some View {
        Button { AudioManager.shared.se(.decide); a() } label: {
            Label(t, systemImage: icon).font(.ui(12.s)).foregroundStyle(Color.ink)
                .padding(.horizontal, 10.s).padding(.vertical, 6.s)
                .background(Capsule().fill(c).overlay(Capsule().stroke(Color.ink, lineWidth: 1.5)))
        }
        .buttonStyle(.plain)
    }
}


// MARK: - Answer check: every question with the right answer, your answer and the explanation

struct ToeicAnswerSheet: View {
    let ids: [String]
    let answers: [String: Int]
    @Environment(\.dismiss) private var dismiss
    @State private var onlyWrong = true
    @State private var playing: String?

    private func wrong(_ s: TSet) -> Bool { s.items.contains { answers[$0.key] != $0.answer } }

    var body: some View {
        let sets = ids.compactMap { ToeicTest.set($0) }
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    Picker("", selection: $onlyWrong) {
                        Text(T("まちがいだけ", "오답만", "只看答錯")).tag(true)
                        Text(T("全問", "전체", "全部")).tag(false)
                    }
                    .pickerStyle(.segmented)
                    let shown = sets.filter { !onlyWrong || wrong($0) }
                    if shown.isEmpty {
                        Text(jp(T("まちがいは|ありません！|全問正解", "오답이 없어요! 전부 정답", "沒有答錯！全部答對"))).font(.ui(15.s)).foregroundStyle(Color.ink)
                            .frame(maxWidth: .infinity).padding(.top, 30)
                    }
                    ForEach(shown) { s in card(s) }
                }
                .padding(16)
                .frame(maxWidth: UIScale.isPad ? 820 : .infinity)
                .frame(maxWidth: .infinity)
            }
            .background(Color(hex: 0xF6F7FB).ignoresSafeArea())
            .navigationTitle(T("答え合わせ", "채점", "對答案"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(T("とじる", "닫기", "關閉")) { Speaker.shared.stop(); dismiss() }
                }
            }
        }
        .onDisappear { Speaker.shared.stop() }
    }

    private func play(_ s: TSet) {
        playing = s.id
        let lines: [(Speaker.Who, String)] = s.audio.map { l in
            let who: Speaker.Who = l.hasPrefix("M:") ? .man : l.hasPrefix("W:") ? .woman : .narrator
            return (who, String(l.dropFirst(2)).trimmingCharacters(in: .whitespaces))
        }
        Speaker.shared.sayLines(lines, gap: s.part <= 2 ? 0.8 : 0.45) { if playing == s.id { playing = nil } }
    }

    private func card(_ s: TSet) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(jp(ToeicTest.name(s.part))).font(.ui(14.s)).foregroundStyle(Color.ink)
                Spacer()
                if !s.audio.isEmpty {
                    Button { if playing == s.id { Speaker.shared.stop(); playing = nil } else { play(s) } } label: {
                        Label(playing == s.id ? T("とめる", "정지", "停止") : T("音声", "음성", "音檔"), systemImage: playing == s.id ? "stop.fill" : "speaker.wave.2.fill")
                            .font(.ui(12.s)).padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Capsule().fill(Color.sun).overlay(Capsule().stroke(Color.ink, lineWidth: 2)))
                    }
                    .buttonStyle(.plain).foregroundStyle(Color.ink)
                }
            }
            if let img = s.image {
                Image(img).resizable().scaledToFit().frame(maxHeight: 200).clipShape(RoundedRectangle(cornerRadius: 10))
            }
            if !s.audio.isEmpty {
                DisclosureGroup(T("スクリプト（音声の英文）", "스크립트", "腳本")) {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(s.audio.enumerated()), id: \.offset) { _, l in Text(l).font(.system(size: 14.s)).fixedSize(horizontal: false, vertical: true) }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 4)
                }
                .font(.ui(13.s)).tint(Color.ink)
            }
            if !s.passage.isEmpty {
                DisclosureGroup(T("本文", "본문", "本文")) {
                    Text(s.passage.joined(separator: "\n")).font(.system(size: 14.s)).fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 4)
                }
                .font(.ui(13.s)).tint(Color.ink)
            }
            ForEach(s.items, id: \.key) { q in item(q) }
        }
        .foregroundStyle(Color.ink)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.ink, lineWidth: 2)))
    }

    private func item(_ q: TQ) -> some View {
        let mine = answers[q.key]
        let ok = mine == q.answer
        return VStack(alignment: .leading, spacing: 6) {
            Divider()
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: ok ? "circle" : "xmark").font(.system(size: 18, weight: .black))
                    .foregroundStyle(ok ? Color.mintDeep : Color.popDeep)
                Text(q.prompt.isEmpty ? T("（音声で流れた質問）", "(음성으로 나온 질문)", "（音檔中的問題）") : q.prompt)
                    .font(.system(size: 15.s, weight: .semibold)).fixedSize(horizontal: false, vertical: true)
            }
            ForEach(q.choices.indices, id: \.self) { k in
                HStack(alignment: .top, spacing: 6) {
                    Text("(\(["A", "B", "C", "D"][min(k, 3)]))").font(.en(13.s))
                    Text(q.choices[k]).font(.system(size: 14.s)).fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 4)
                    if k == q.answer { Text(T("正解", "정답", "正解")).font(.ui(11.s)).foregroundStyle(Color.mintDeep) }
                    else if k == mine { Text(T("あなた", "내 답", "你的答案")).font(.ui(11.s)).foregroundStyle(Color.popDeep) }
                }
                .padding(.horizontal, 8).padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: 8).fill(k == q.answer ? Color.mint.opacity(0.3) : k == mine ? Color.pop.opacity(0.18) : Color.clear))
            }
            if mine == nil { Text(T("未回答", "미응답", "未作答")).font(.ui(12.s)).foregroundStyle(Color.popDeep) }
            if !q.tip.isEmpty {
                Text(jp(q.tip)).font(.ui(13.s, bold: false)).foregroundStyle(Color.ink.opacity(0.8)).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
