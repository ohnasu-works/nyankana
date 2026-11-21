#if DEBUG && targetEnvironment(simulator)
import Foundation

/// Developer check (simulator only): lists every English line the app can speak that has no recorded voice.
/// Writes the result next to the project so it can be recorded and added to voice.pack.
@MainActor
enum VoiceAudit {
    static func role(_ v: Speaker.Voice?) -> String { guard let v else { return "f" }; return v.pitch < 0.98 ? "m" : "f" }

    static func run() {
        var items: [(String, String, String)] = []   // role, text, where
        func add(_ r: String, _ t: String, _ w: String) { if !t.isEmpty { items.append((r, t, w)) } }
        func both(_ t: String, _ w: String) { add("f", t, w); add("m", t, w) }
        // questions (game + study) and words
        for q in Library.bank { both(q.full, "question") }
        for a in Area.allCases { let p = QuestionBank.pools(for: a); for q in p.single + p.phrase + p.order + p.mid + p.boss { both(q.full, "pool") } }
        for w in Vocab.all { both(w.word, "word") }
        both("Hello", "settings")
        // story
        var scenes: [[StoryLine]] = []
        scenes += Array(StoryBank.chapterIntro.values) + Array(StoryBank.chapterOutro.values)
        scenes += StoryBank.shortIntros + StoryBank.shortOutros + StoryBank.funIntros + StoryBank.funOutros
        scenes += StoryBank.moreIntros + StoryBank.moreOutros
        scenes += StoryBank.areaIntros.values.flatMap { $0 } + StoryBank.areaOutros.values.flatMap { $0 }
        for a in Area.allCases {
            scenes.append(StoryBank.bossIntro(a))
            if a != .graduation { for i in [10, 20] { scenes.append(StoryBank.midIntro(a.mid(i), i)); scenes.append(StoryBank.midOutro(a.mid(i), i)) } }
        }
        for s in scenes { for l in s { add(role(l.who.voice), l.en, "story") } }
        for b in BossProfile.bosses + BossProfile.mids {
            for l in [b.intro, b.half, b.out] { add(role(b.voice), l.en, "boss") }
            add(role(b.freeVoice), b.out.en, "boss free")
        }
        // events
        let capt: [Speaker.Voice] = [1.0, 1.25, 0.85, 1.4, 0.95, 1.15].map { .init(pitch: $0, rate: 0.95) }
        for l in GameEvents.help + GameEvents.thanks { for v in capt { add(role(v), l.en, "captive") } }
        for p in GameEvents.possessed {
            for l in p.talk { add("f", l.en, "possessed") }
            add("m", p.turn.en, "possessed"); add("f", p.freed.en, "possessed")
        }
        // picture book
        for e in ZukanEntry.everything {
            add(role(e.voice), e.spoken, "zukan name")
            for l in e.lines { add(role(l.voice), l.en, "zukan line") }
            for part in NameParts.of(e.name) { add("f", part.en.replacingOccurrences(of: "-", with: ""), "name part") }
        }
        // TOEIC
        for (_, sets) in ToeicTest.bank { for s in sets { for l in s.audio {
            let r = l.hasPrefix("M:") ? "m" : l.hasPrefix("W:") ? "f" : "n"
            add(r, String(l.dropFirst(2)).trimmingCharacters(in: .whitespaces), "toeic")
        } } }
        var seen = Set<String>(), missing: [String] = []
        for (r, t, w) in items {
            let k = r + "|" + t
            if seen.insert(k).inserted, !RecordedVoice.has(t, role: r) { missing.append("\(r)\t\(w)\t\(t)") }
        }
        let out = "total \(seen.count) missing \(missing.count)\n" + missing.joined(separator: "\n")
        try? out.write(toFile: "/Users/sun/Documents/NyanKana/_work/voice_missing.txt", atomically: true, encoding: .utf8)
        print("VoiceAudit: total \(seen.count) missing \(missing.count)")
    }
}
#endif
