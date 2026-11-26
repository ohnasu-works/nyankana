import Foundation

// MARK: - 少しずつ おぼえる：こたえに なるのは「もう ならった」もの だけ
// まぎらわしい ひっかけ（はずれの 選択肢・ならんでいる 札）には まだ ならっていない 字や ことばが 出てもよい。
// でも 読み上げられる・聞かれる「こたえ」は、そのステージまでに レッスンで 教わった 文字・ことば だけ。

enum KJLearned {
    /// words taught (in a lesson) up to and including this stage, in the order they were taught
    static func words(upTo id: Int) -> [String] {
        let all = KJC1.stages
        guard let i = all.firstIndex(where: { $0.id == id }) else { return [] }
        var out: [String] = []
        for s in all[...i] where s.kind == .lesson {
            for w in s.words where KJData.word(w) != nil && !out.contains(w) { out.append(w) }
        }
        return out
    }

    /// the words a game at this stage may ask: taught words first (the newest most often);
    /// only if too few have been taught yet, the stage's own words are added (they come with their picture)
    static func answerWords(for stage: KJC1.Stage, need: Int = 3) -> [String] {
        let taught = words(upTo: stage.id)
        let recent = Array(taught.suffix(12))
        var out = (recent + recent + taught).uniqued()
        if out.count < need { out = (out + stage.words.filter { KJData.word($0) != nil }).uniqued() }
        return out
    }
}
