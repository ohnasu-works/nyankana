import Foundation

/// One question. Three shapes:
///  - blank: "pre ___ post", answer `a` (one or more words), with `choices`
///  - order: arrange `words` in order
///  - sentence: pick the one correct full sentence from `choices` (mid bosses)
struct Question: Codable, Hashable, Identifiable {
    enum Kind: String, Codable { case blank, order, sentence }
    var id = UUID()
    var kind: Kind = .blank
    var jp: String              // meaning (Japanese; ko / zh via `tr`)
    var ko: String? = nil
    var zh: String? = nil
    var pre: String = ""
    var post: String = ""
    var a: String = ""
    var choices: [String] = []
    var words: [String] = []
    /// grammar point id, e.g. "be.present" — used by the weak-point analysis
    var point: String = ""
    /// set for word questions: the meaning comes from the word list (vocab_tr.json), not the shared table
    var vocabWord: String? = nil

    private enum CodingKeys: String, CodingKey { case kind, jp, ko, zh, pre, post, a, choices, words, point }

    var meaning: String {
        switch L10n.current {
        case .ja: jp
        case .ko: ko ?? Lv1Tr.ko(jp) ?? jp
        case .zhHant: zh ?? Lv1Tr.zh(jp) ?? jp
        // English: the "meaning" is a short hint in English that does not give the answer away (tr_en.json)
        default: vocabWord.map { Tr.vocab($0, ja: jp) } ?? Tr.text(jp)
        }
    }
    /// the full English sentence (read aloud after answering)
    var full: String {
        switch kind {
        case .order: words.joined(separator: " ")
        case .sentence: a
        case .blank: Question.join(pre, a, post)
        }
    }
    /// number of words to produce (time limit grows with it)
    var answerLength: Int {
        switch kind { case .order: words.count; case .sentence: 6; case .blank: a.split(separator: " ").count }
    }

    /// joins pre / answer / post without a space before trailing punctuation ("lives?" not "lives ?")
    static func join(_ pre: String, _ mid: String, _ post: String) -> String {
        var out = pre.isEmpty ? mid : pre + " " + mid
        if !post.isEmpty { out += (post.first.map { ",.?!;:".contains($0) } == true ? "" : " ") + post }
        return out
    }
    static func sp(_ post: String) -> String { post.isEmpty ? "" : (post.first.map { ",.?!;:".contains($0) } == true ? post : " " + post) }

    static func blank(_ jp: String, _ pre: String, _ a: String, _ post: String, _ ch: [String], _ point: String = "") -> Question {
        Question(kind: .blank, jp: jp, pre: pre, post: post, a: a, choices: ch, point: point)
    }
    static func order(_ jp: String, _ words: [String], _ point: String = "") -> Question {
        Question(kind: .order, jp: jp, words: words, point: point)
    }
    static func sentence(_ jp: String, _ a: String, _ ch: [String], _ point: String = "") -> Question {
        Question(kind: .sentence, jp: jp, a: a, choices: ch, point: point)
    }
}

/// Question pools per area. Lv1 is written here; the other areas are generated into Content/*.json.
enum QuestionBank {
    struct Pools { var single: [Question]; var phrase: [Question]; var order: [Question]; var mid: [Question]; var boss: [Question] }

    static func pools(for area: Area) -> Pools {
        let loaded = ContentLoader.pools(area)
        if area == .lv1, let ex = loaded {
            // Lv1: built-in be-verb set + general verbs / past tense from the content file
            return Pools(single: lv1.single + ex.single, phrase: lv1.phrase + ex.phrase, order: lv1.order + ex.order,
                         mid: lv1.mid + ex.mid, boss: lv1.boss + ex.boss)
        }
        return loaded ?? lv1
    }

    static let lv1 = Pools(
        single: [
            .blank("私は学生です。", "I", "am", "a student.", ["am", "is", "are", "be"], "be.present"),
            .blank("彼女は先生です。", "She", "is", "a teacher.", ["am", "is", "are", "be"], "be.present"),
            .blank("私たちは友だちです。", "We", "are", "friends.", ["am", "is", "are", "be"], "be.present"),
            .blank("これは私のペンです。", "This", "is", "my pen.", ["am", "is", "are", "be"], "be.present"),
            .blank("あなたは疲れていますか？", "", "Are", "you tired?", ["Am", "Is", "Are", "Do"], "be.question"),
            .blank("彼はおなかがすいていません。", "He", "is", "not hungry.", ["am", "is", "are", "does"], "be.negative"),
            .blank("その猫たちはかわいい。", "The cats", "are", "cute.", ["am", "is", "are", "be"], "be.present"),
            .blank("私は今、家にいます。", "I", "am", "at home now.", ["am", "is", "are", "be"], "be.present"),
            .blank("これらは私の本です。", "These", "are", "my books.", ["am", "is", "are", "be"], "be.present"),
            .blank("彼は今、幸せです。", "He", "is", "happy now.", ["am", "is", "are", "be"], "be.present"),
            .blank("私はニャンではありません。", "I", "am", "not Nyan.", ["am", "is", "are", "do"], "be.negative"),
            .blank("そのお店は開いていますか？", "", "Is", "the shop open?", ["Am", "Is", "Are", "Do"], "be.question"),
            .blank("リンとニャンは友だちです。", "Rin and Nyan", "are", "friends.", ["am", "is", "are", "be"], "be.present"),
            .blank("今日は晴れです。", "It", "is", "sunny today.", ["am", "is", "are", "be"], "be.present"),
            .blank("私は眠くありません。", "I", "am", "not sleepy.", ["am", "is", "are", "do"], "be.negative"),
            .blank("あなたは私の友だちです。", "You", "are", "my friend.", ["am", "is", "are", "be"], "be.present"),
            .blank("そのりんごは赤い。", "The apple", "is", "red.", ["am", "is", "are", "be"], "be.present"),
            .blank("彼らは駅にいます。", "They", "are", "at the station.", ["am", "is", "are", "be"], "be.present"),
            .blank("ケンは背が高いですか？", "", "Is", "Ken tall?", ["Am", "Is", "Are", "Does"], "be.question"),
            .blank("私たちは忙しくありません。", "We", "are", "not busy.", ["am", "is", "are", "do"], "be.negative"),
            .blank("私の母は看護師です。", "My mother", "is", "a nurse.", ["am", "is", "are", "be"], "be.present"),
            .blank("あの犬たちは大きい。", "Those dogs", "are", "big.", ["am", "is", "are", "be"], "be.present"),
            .blank("私は日本出身です。", "I", "am", "from Japan.", ["am", "is", "are", "be"], "be.present"),
            .blank("その本はおもしろいですか？", "", "Is", "the book interesting?", ["Am", "Is", "Are", "Do"], "be.question"),
        ],
        phrase: [
            .blank("私は学生ではありません。", "I", "am not", "a student.", ["am not", "is not", "are not", "not am"], "be.negative"),
            .blank("彼は先生ではありません。", "He", "is not", "a teacher.", ["is not", "are not", "am not", "not is"], "be.negative"),
            .blank("あなたは忙しいですか？", "", "Are you", "busy?", ["Are you", "Is you", "You are", "Do you"], "be.question"),
            .blank("彼女は家にいますか？", "", "Is she", "at home?", ["Is she", "Are she", "She is", "Does she"], "be.question"),
            .blank("私たちは疲れていません。", "We", "are not", "tired.", ["are not", "is not", "not are", "do not"], "be.negative"),
            .blank("これはあなたのペンですか？", "", "Is this", "your pen?", ["Is this", "This is", "Are this", "Does this"], "be.question"),
            .blank("彼らは公園にいません。", "They", "are not", "in the park.", ["are not", "is not", "not are", "does not"], "be.negative"),
            .blank("ケンは私の友だちです。", "", "Ken is", "my friend.", ["Ken is", "Ken are", "Ken am", "Is Ken"], "be.present"),
            .blank("あの犬たちはかわいいですか？", "", "Are those dogs", "cute?", ["Are those dogs", "Is those dogs", "Those dogs are", "Do those dogs"], "be.question"),
            .blank("私の名前はリンです。", "", "My name is", "Rin.", ["My name is", "My name are", "I name is", "Is my name"], "be.present"),
            .blank("今日は寒くありません。", "It", "is not", "cold today.", ["is not", "are not", "not is", "does not"], "be.negative"),
            .blank("あなたとリンは姉妹ですか？", "", "Are you and Rin", "sisters?", ["Are you and Rin", "Is you and Rin", "You and Rin are", "Do you and Rin"], "be.question"),
            .blank("私は今、眠いです。", "", "I am", "sleepy now.", ["I am", "I is", "I are", "Am I"], "be.present"),
            .blank("その店は今日開いていません。", "The shop", "is not", "open today.", ["is not", "are not", "not is", "does not"], "be.negative"),
            .blank("あなたは日本出身ですか？", "", "Are you", "from Japan?", ["Are you", "Is you", "Do you", "You are"], "be.question"),
            .blank("それは私のかばんです。", "", "That is", "my bag.", ["That is", "That are", "Is that", "That am"], "be.present"),
        ],
        order: [
            .order("私はおなかがすいています。", ["I", "am", "hungry."], "be.present"),
            .order("彼女は私の姉です。", ["She", "is", "my", "sister."], "be.present"),
            .order("あなたは学生ですか？", ["Are", "you", "a", "student?"], "be.question"),
            .order("これは私の猫ではありません。", ["This", "is", "not", "my", "cat."], "be.negative"),
            .order("彼らは今、駅にいます。", ["They", "are", "at", "the", "station."], "be.present"),
            .order("そのペンは青いですか？", ["Is", "the", "pen", "blue?"], "be.question"),
            .order("私たちは同じクラスです。", ["We", "are", "in", "the", "same", "class."], "be.present"),
            .order("ニャンは眠くありません。", ["Nyan", "is", "not", "sleepy."], "be.negative"),
        ],
        mid: [
            .sentence("ケンとリンは東京にいます。", "Ken and Rin are in Tokyo.", ["Ken and Rin are in Tokyo.", "Ken and Rin is in Tokyo.", "Ken and Rin am in Tokyo.", "Ken and Rin in Tokyo are."], "be.present"),
            .sentence("あなたはどこの出身ですか？", "Where are you from?", ["Where are you from?", "Where is you from?", "Where you are from?", "Are where you from?"], "be.question"),
            .sentence("それは私の本ではありません。", "That is not my book.", ["That is not my book.", "That not is my book.", "That are not my book.", "That is my not book."], "be.negative"),
            .sentence("あなたとケンは同じクラスですか？", "Are you and Ken in the same class?", ["Are you and Ken in the same class?", "Is you and Ken in the same class?", "You and Ken are in the same class?", "Are you and Ken the same in class?"], "be.question"),
            .sentence("私の兄は今、家にいません。", "My brother is not at home now.", ["My brother is not at home now.", "My brother are not at home now.", "My brother not is at home now.", "My brother is at not home now."], "be.negative"),
            .sentence("私たちは今、とても忙しいです。", "We are very busy now.", ["We are very busy now.", "We is very busy now.", "We very are busy now.", "We am very busy now."], "be.present"),
            .sentence("このホチキスはあなたのものですか？", "Is this stapler yours?", ["Is this stapler yours?", "Are this stapler yours?", "This stapler is yours?", "Is yours this stapler?"], "be.question"),
        ],
        boss: [
            .order("私はダンスの先生です。", ["I", "am", "a", "dance", "teacher."], "be.present"),
            .blank("彼らは今、公園にいますか？", "", "Are", "they in the park now?", ["Am", "Is", "Are", "Do"], "be.question"),
            .order("これはあなたのかばんですか？", ["Is", "this", "your", "bag?"], "be.question"),
            .blank("私の名前はビーです。", "My name", "is", "Bee.", ["am", "is", "are", "be"], "be.present"),
            .order("私たちは悲しくありません。", ["We", "are", "not", "sad."], "be.negative"),
            .blank("あなたのお父さんは医者ですか？", "", "Is", "your father a doctor?", ["Am", "Is", "Are", "Does"], "be.question"),
            .order("彼女たちは私の姉です。", ["They", "are", "my", "sisters."], "be.present"),
        ]
    )
}

/// Loads generated content (Content/area_N.json) when present.
enum ContentLoader {
    private struct File: Codable { var single: [Question]; var phrase: [Question]; var order: [Question]; var mid: [Question]; var boss: [Question] }
    static func pools(_ area: Area) -> QuestionBank.Pools? {
        guard let url = Bundle.main.url(forResource: "area_\(area.rawValue)", withExtension: "json"),
              let d = try? Data(contentsOf: url), let f = try? JSONDecoder().decode(File.self, from: d) else { return nil }
        return .init(single: f.single, phrase: f.phrase, order: f.order, mid: f.mid, boss: f.boss)
    }
}

// MARK: - Stage plan

enum EnemyPath: String { case front, sky, left, right }

enum Encounter {
    case zako(Question, image: Int, path: EnemyPath, item: ItemKind?)
    case pack([Question], images: [Int], item: ItemKind?)
    case fork
    case bonus
    case mid([Question])
    case boss([Question])
    /// Silence Castle: a mid boss of an earlier area comes back, or (boss rush) a boss as a shadow of itself
    case guest(BossProfile, [Question], shadow: Bool)
    /// the boss's dramatic entrance before the final battle
    case bossCall
    /// rare runaway (metal-slime style), kidnapper (beat it in time -> heal), possessed townsperson (mini boss)
    case rare(Question)
    case kidnap([Question])
    case possessed([Question])
}

enum StageKind { case normal, mid, boss }

/// Builds the run of encounters for one stage.
/// Marked event stages on the course map (stage 3, 5 and 8 of every ten).
enum StageEvent {
    case lucky, rescue, possessed
    static func at(_ index: Int, of count: Int) -> StageEvent? {
        guard index % 10 != 0 else { return nil }
        switch index % 10 { case 3: return .lucky; case 5: return .rescue; case 8: return .possessed; default: return nil }
    }
    /// small picture on the map stone
    var image: String { switch self { case .lucky: "rare_1"; case .rescue: "capt_0"; case .possessed: "poss_3" } }
    var label: String {
        switch self {
        case .lucky: T("ラッキー", "럭키", "幸運")
        case .rescue: T("きゅうしゅつ", "구출", "救援")
        case .possessed: T("あやしい人", "수상한 사람", "可疑的人")
        }
    }
}

extension Question {
    /// two questions with the same meaning and answer count as the same question
    var dedupeKey: String { "\(kind.rawValue)|\(jp)|\(pre)|\(a)|\(post)" }
}

struct StagePlanner {
    let ref: StageRef
    var kind: StageKind { ref.index % 10 == 0 ? (ref.index == ref.area.stageCount ? .boss : .mid) : .normal }

    func build() -> [Encounter] {
        let pools = QuestionBank.pools(for: ref.area)
        return dedupe(buildRaw(pools), pools)
    }

    /// The same question must never come back within one stage: repeats are swapped for unused ones of the same kind.
    private func dedupe(_ plan: [Encounter], _ p: QuestionBank.Pools) -> [Encounter] {
        var used = Set<String>()
        var spare = (p.single + p.phrase + p.order + p.mid + p.boss).shuffled()
        func fix(_ q: Question) -> Question {
            if used.insert(q.dedupeKey).inserted { return q }
            if let i = spare.firstIndex(where: { $0.kind == q.kind && !used.contains($0.dedupeKey) }) {
                let r = spare.remove(at: i); used.insert(r.dedupeKey); return r
            }
            return q
        }
        func fixAll(_ qs: [Question]) -> [Question] { qs.map(fix) }
        return plan.map { e in
            switch e {
            case let .zako(q, image, path, item): return .zako(fix(q), image: image, path: path, item: item)
            case let .pack(qs, images, item): return .pack(fixAll(qs), images: images, item: item)
            case let .mid(qs): return .mid(fixAll(qs))
            case let .boss(qs): return .boss(fixAll(qs))
            case let .rare(q): return .rare(fix(q))
            case let .kidnap(qs): return .kidnap(fixAll(qs))
            case let .possessed(qs): return .possessed(fixAll(qs))
            case let .guest(p, qs, shadow): return .guest(p, fixAll(qs), shadow: shadow)
            case .fork, .bonus, .bossCall: return e
            }
        }
    }

    private func buildRaw(_ pools: QuestionBank.Pools) -> [Encounter] {
        var rng = SystemRandomNumberGenerator()
        var queue = questionQueue(pools).shuffled(using: &rng)
        func next() -> Question { if queue.isEmpty { queue = questionQueue(pools).shuffled() }; return queue.removeFirst() }
        func item() -> ItemKind? {
            let rate: Double = ref.difficulty == .easy ? 0.2 : ref.difficulty == .normal ? 0.14 : 0.11   // halved (items came too often)
            return Double.random(in: 0...1) < rate ? ItemKind.allCases.randomElement() : nil
        }
        let img = { Int.random(in: 0..<16) }

        switch kind {
        case .mid:
            let n = ref.difficulty == .easy ? 2 : ref.difficulty == .normal ? 3 : 5
            var qs = Array(pools.mid.shuffled().prefix(n))
            if ref.difficulty == .hard { qs = Array(pools.mid.shuffled().prefix(3)) + Array(pools.order.shuffled().prefix(2)) }
            return [.zako(next(), image: img(), path: .front, item: item()), .zako(next(), image: img(), path: .sky, item: nil), .mid(qs)]
        case .boss:
            let n = ref.difficulty == .easy ? 3 : ref.difficulty == .normal ? 5 : 7
            var qs = Array(pools.boss.shuffled().prefix(n))
            // normal / hard bosses always include one word-order question (easy skips it)
            if ref.difficulty != .easy, !qs.contains(where: { $0.kind == .order }), let o = pools.boss.first(where: { $0.kind == .order }) { qs[0] = o }
            // the final boss (King Silence) takes ten questions on every difficulty
            if ref.area == .graduation {
                let extra = (pools.mid + pools.boss).shuffled().filter { e in !qs.contains { $0.dedupeKey == e.dedupeKey } }
                qs += extra.prefix(max(0, 10 - qs.count))
                while qs.count < 10 { qs.append(next()) }
                qs = Array(qs.prefix(10))
            }
            // the last battle of the level: three waves, the mid boss once more, a grand entrance, then the boss
            let rematch = Array(pools.mid.shuffled().prefix(ref.difficulty == .easy ? 2 : 3))
            if ref.area == .graduation {
                // the last battle: the six bosses of Wordia come back as shadows, one after another, then the king
                var rush: [Encounter] = [.zako(next(), image: img(), path: .front, item: item()),
                                         .pack([next(), next()], images: [img(), img()], item: item())]
                var bq = (pools.mid + pools.boss).shuffled().filter { e in !qs.contains { $0.dedupeKey == e.dedupeKey } }
                for a in Area.allCases where a != .graduation {
                    var two: [Question] = []
                    while two.count < 2 { two.append(bq.isEmpty ? next() : bq.removeFirst()) }
                    rush.append(.guest(a.boss, two, shadow: true))
                }
                return rush + [.bossCall, .boss(qs)]
            }
            return [.zako(next(), image: img(), path: .front, item: item()),
                    .pack([next(), next()], images: [img(), img()], item: item()),
                    .zako(next(), image: img(), path: .sky, item: item()),
                    .pack([next(), next(), next()], images: [img(), img(), img()], item: item()),
                    .mid(rematch.isEmpty ? [next(), next()] : rematch),
                    .bossCall,
                    .boss(qs)]
        case .normal:
            var plan: [Encounter] = []
            let paths: [EnemyPath] = [.front, .sky, .left, .right]
            let count = ref.difficulty == .easy ? 4 : ref.difficulty == .normal ? 5 : 6
            var i = 0
            while plan.count < count {
                if i % 3 == 2 {
                    plan.append(.pack([next(), next()], images: [img(), img()], item: item()))
                } else {
                    plan.append(.zako(next(), image: img(), path: paths[(i + ref.index) % 4], item: item()))
                }
                i += 1
            }
            if ref.index % 5 == 3 { plan.insert(.fork, at: plan.count / 2) }
            if ref.index % 4 == 2 { plan.append(.bonus) }
            // events keep the long courses fresh
            let force = AppState.shared.dev.enabled && AppState.shared.dev.forceEvents
            let easyQ = { pools.single.randomElement() ?? next() }
            let ev = StageEvent.at(ref.index, of: ref.area.stageCount)
            if force || ev == .rescue || (ref.index > 2 && ref.index % 3 == 1) || (ref.index > 2 && Double.random(in: 0..<1) < 0.25) {
                plan.insert(.kidnap([next(), next()]), at: min(plan.count, 2))
            }
            if force || ev == .possessed || (ref.index > 3 && ref.index % 5 == 4) || (ref.index > 3 && Double.random(in: 0..<1) < 0.15) {
                let mq = ref.difficulty == .easy ? Array(pools.single.shuffled().prefix(2)) : Array(pools.mid.shuffled().prefix(3))
                plan.insert(.possessed(mq.count >= 2 ? mq : [next(), next(), next()]), at: max(1, plan.count - 1))
            }
            if force || ev == .lucky || Double.random(in: 0..<1) < 0.14 {
                plan.insert(.rare(easyQ()), at: Int.random(in: 1...max(1, plan.count - 1)))
            }
            if ev == .lucky && !plan.contains(where: { if case .bonus = $0 { return true }; return false }) { plan.append(.bonus) }
            if ref.area == .graduation {
                // Silence Castle: every stage ends with a mid boss from earlier in the journey (a different one each stage)
                // stage 1 → the first area's mid boss … stage 9 → the last area's: the whole journey in order
                let mids = BossProfile.mids
                let guest = mids[min(mids.count - 1, (ref.index - 1) * mids.count / 9)]
                let n = ref.difficulty == .easy ? 2 : 3
                let mq = Array(pools.mid.shuffled().prefix(n))
                plan.append(.guest(guest, mq.count == n ? mq : (0..<n).map { _ in next() }, shadow: false))
            }
            return plan
        }
    }

    private func questionQueue(_ p: QuestionBank.Pools) -> [Question] {
        switch ref.difficulty {
        case .easy: return p.single
        case .normal:
            var q: [Question] = []
            let a = p.single.shuffled(), b = p.phrase.shuffled()
            for (i, x) in a.enumerated() { q.append(x); if i % 2 == 1, i / 2 < b.count { q.append(b[i / 2]) } }
            return q
        case .hard: return p.phrase + p.order
        }
    }
}
