import Foundation

// MARK: - もじレスキュー（最初からあるゲーム）を にゃんカナの ボス戦に使う
// 第1章のボス（九尾のきつね）は、にゃんグリッシュと同じ GameScreen で戦う。
// 問題は英語ではなく、その章で習った かな と ことば：
//  - ちいさな敵：音（ローマ字）→ かなを えらぶ / 書く / 言う
//  - ことば：絵と意味 → ことばを えらぶ・ならべる（もじを 正しい順に）
// 終わったら にゃんカナの ステージに戻り、クリア演出 → おはなし → 結果 へ続く。

enum KanaRescue {
    struct Session {
        var stageID: Int
        var pools: QuestionBank.Pools
    }
    struct Outcome {
        var stageID: Int
        var stars: Int
        var score: Int
        var won: [String]
        var cleared: Bool
    }

    /// set while the battle runs (QuestionBank / GameModel ask this)
    static var session: Session?
    /// set when the battle ends; KanaJourneyView picks it up and clears it
    static var outcome: Outcome?

    static var active: Bool { session != nil }

    /// the battle: the area-1 boss stage on NORMAL (zako, packs, the mid boss again, the boss's entrance, the boss)
    static func ref(_ chapter: Int = 1) -> StageRef {
        let a = KJC1.bossArea[chapter] ?? .lv1
        return StageRef(area: a, index: a.stageCount, difficulty: .normal)
    }

    @MainActor static func start(_ stage: KJC1.Stage) {
        session = Session(stageID: stage.id, pools: pools(stage))
        outcome = nil
        AppState.shared.go(.game(ref(stage.chapter)))
    }

    @MainActor static func finish(stars: Int, score: Int, cleared: Bool) {
        guard let s = session else { return }
        let words = KJC1.stage(s.stageID).words
        outcome = Outcome(stageID: s.stageID, stars: cleared ? max(1, stars) : 0, score: score,
                          won: cleared ? words : [], cleared: cleared)
        session = nil
        AudioManager.shared.playBGM(.area(.lv1))
        AppState.shared.go(.kana)
    }

    @MainActor static func quit() {
        session = nil
        outcome = nil
        AudioManager.shared.playBGM(.area(.lv1))
        AppState.shared.go(.kana)
    }

    // MARK: questions

    static func pools(_ stage: KJC1.Stage) -> QuestionBank.Pools {
        let letters = stage.known.isEmpty ? KJC1.all : stage.known
        let single = letters.map { letterQ($0, among: letters) }
        let words = stage.words.compactMap { KJData.word($0) }
        let phrase = words.map { wordQ($0, among: letters) }
        let order = words.filter { $0.ja.count >= 2 }.map { orderQ($0) }
        return QuestionBank.Pools(single: single, phrase: phrase, order: order,
                                  mid: phrase.shuffled(), boss: (phrase + order).shuffled())
    }

    /// "ka" → か (wrong choices: letters that look or sound alike first)
    static func letterQ(_ k: String, among letters: [String]) -> Question {
        let r = "“" + KJData.romaji(k) + "”"
        var q = Question.blank(r, "", k, "", [k] + distractors(k, among: letters))
        q.ko = r; q.zh = r; q.kana = k
        return q
    }

    /// 🐱 cat → ねこ (wrong choices: the word with one letter swapped)
    static func wordQ(_ w: KJData.Word, among letters: [String]) -> Question {
        var q = Question.blank(w.emoji + " " + w.en, "", w.ja, "", [w.ja] + wordDistractors(w.ja, among: letters))
        q.ko = w.emoji + " " + w.ko
        q.zh = w.emoji + " " + w.zh
        q.kana = w.ja
        return q
    }

    /// put the letters of the word in order
    static func orderQ(_ w: KJData.Word) -> Question {
        var q = Question.order(w.emoji + " " + w.en, w.ja.map(String.init))
        q.ko = w.emoji + " " + w.ko
        q.zh = w.emoji + " " + w.zh
        q.kana = w.ja
        return q
    }

    static func distractors(_ k: String, among letters: [String]) -> [String] {
        var out: [String] = []
        for g in KJData.lookAlike where g.contains(k) {
            for x in g where x != k && !out.contains(x) { out.append(x) }
        }
        // same vowel or same row sound alike to a beginner
        let r = KJData.romaji(k)
        let near = letters.filter { $0 != k && !out.contains($0) && (KJData.romaji($0).last == r.last || KJData.romaji($0).first == r.first) }
        out += near.shuffled()
        out += letters.filter { $0 != k && !out.contains($0) }.shuffled()
        return Array(out.prefix(3))
    }

    static func wordDistractors(_ word: String, among letters: [String]) -> [String] {
        let chars = word.map(String.init)
        var out: [String] = []
        var tries = 0
        while out.count < 3 && tries < 40 {
            tries += 1
            var c = chars
            let i = Int.random(in: 0..<c.count)
            guard let swap = distractors(c[i], among: letters).randomElement() else { continue }
            c[i] = swap
            let w = c.joined()
            if w != word && !out.contains(w) { out.append(w) }
        }
        while out.count < 3 { out.append(String(word.reversed()) + String(repeating: "ー", count: out.count)) }
        return out
    }
}
