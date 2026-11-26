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
    /// `readable`: only words made of letters already learned (for games where the word is spelled or read)
    static func answerWords(for stage: KJC1.Stage, need: Int = 3, readable: Bool = false) -> [String] {
        let have = Set(learnedLetters(upTo: stage.id) + stage.known)
        let canRead: (String) -> Bool = { w in w.allSatisfy { have.contains(String($0)) || "ゃゅょっャュョッー".contains($0) } }
        let taught = words(upTo: stage.id).filter { !readable || canRead($0) }
        let recent = Array(taught.suffix(12))
        var out = (recent + recent + taught).uniqued()
        if out.count < need { out = (out + stage.words.filter { KJData.word($0) != nil && (!readable || canRead($0)) }).uniqued() }
        return out
    }

    /// every letter taught in a lesson up to and including this stage
    static func learnedLetters(upTo id: Int) -> [String] {
        let all = KJC1.stages
        guard let i = all.firstIndex(where: { $0.id == id }) else { return [] }
        return all[...i].flatMap(\.newKana).uniqued()
    }
}

// MARK: - にている ひっかけ：かんたんに なりすぎないように、形や音が にている ものを はずれに使う

enum KJSimilar {
    /// letters that look or sound alike (look-alike groups + the same letter with / without ゛゜)
    static func alike(_ a: Character, _ b: Character) -> Bool {
        guard a != b else { return false }
        let sa = String(a), sb = String(b)
        if KJData.lookAlike.contains(where: { $0.contains(sa) && $0.contains(sb) }) { return true }
        let base: (String) -> String = { $0.applyingTransform(.stripDiacritics, reverse: false) ?? $0 }
        let h: (String) -> String = { $0.applyingTransform(.hiraganaToKatakana, reverse: true) ?? $0 }
        return base(sa) == base(sb) || h(sa) == h(sb)
    }

    static func hasKanji(_ s: String) -> Bool { s.unicodeScalars.contains { (0x4E00...0x9FFF).contains($0.value) || $0.value == 0x3005 } }

    private static var readCache: [String: String] = [:]
    /// how a word is pronounced, as romaji (kanji included: 手 → te)
    static func reading(_ s: String) -> String {
        if let r = readCache[s] { return r }
        let src = KJData.readings[s] ?? s
        var out = ""
        let cf = src as CFString
        let tok = CFStringTokenizerCreate(nil, cf, CFRangeMake(0, CFStringGetLength(cf)), kCFStringTokenizerUnitWord, Locale(identifier: "ja") as CFLocale)
        while CFStringTokenizerAdvanceToNextToken(tok) != [] {
            if let l = CFStringTokenizerCopyCurrentTokenAttribute(tok, kCFStringTokenizerAttributeLatinTranscription) as? String { out += l }
        }
        if out.isEmpty { out = src.applyingTransform(.toLatin, reverse: false) ?? src }
        let r = out.lowercased().filter { $0.isLetter }
        readCache[s] = r
        return r
    }

    /// how alike two words are (bigger = more confusing)
    static func score(_ w: String, _ x: String) -> Int {
        let a = Array(w), b = Array(x)
        var s = 0
        if a.count == b.count {
            s += 3
            let diff = zip(a, b).filter { $0 != $1 }
            if diff.count == 1 { s += alike(diff[0].0, diff[0].1) ? 9 : 5 }
            else if diff.count == 2 { s += 2 }
        } else if abs(a.count - b.count) == 1 { s += 1 }
        if a.first == b.first { s += 3 } else if let p = a.first, let q = b.first, alike(p, q) { s += 2 }
        if a.last == b.last { s += 2 }
        s += Set(a).intersection(Set(b)).count
        return s
    }

    /// `count` words from the pool that look / sound most like `w` (a little shuffled so it does not repeat)
    static func words(_ w: String, from pool: [String], count: Int = 3) -> [String] {
        // never a word that SOUNDS the same (て / 手) — in a listening question both would be right;
        // and no kanji next to an answer written in kana
        let sound = reading(w), kanaOnly = !hasKanji(w)
        let cands = pool.filter { $0 != w && reading($0) != sound && (!kanaOnly || !hasKanji($0)) }.uniqued()
        let ranked = cands.map { ($0, score(w, $0) * 10 + Int.random(in: 0..<8)) }.sorted { $0.1 > $1.1 }.map(\.0)
        return Array(ranked.prefix(count))
    }
}
