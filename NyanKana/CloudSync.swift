import Foundation

/// iPhone ⇄ iPad: small records are kept in iCloud key-value storage (compressed to stay well
/// under its 1 MB limit). Every device merges what the others saved, so nothing is lost.
enum CloudSync {
    private static var kv: NSUbiquitousKeyValueStore { .default }

    static func put<T: Encodable>(_ value: T, _ key: String) {
        guard let d = try? JSONEncoder().encode(value),
              let z = try? (d as NSData).compressed(using: .lzfse) as Data else { return }
        kv.set(z, forKey: key)
    }

    static func get<T: Decodable>(_ type: T.Type, _ key: String) -> T? {
        guard let z = kv.data(forKey: key),
              let d = try? (z as NSData).decompressed(using: .lzfse) as Data else { return nil }
        return try? JSONDecoder().decode(type, from: d)
    }

    /// [right, asked] pairs: keep the one with more answers (never add the two, that would count twice)
    static func maxPairs(_ a: [String: [Int]], _ b: [String: [Int]]) -> [String: [Int]] {
        a.merging(b) { x, y in (y.count > 1 ? y[1] : 0) > (x.count > 1 ? x[1] : 0) ? y : x }
    }

    static var now: Double { Date().timeIntervalSince1970 }
}

// MARK: - TOEIC records

struct ToeicCloud: Codable, Equatable {
    var results: [ToeicResult]
    var wrong: [String]
    var goal: Int
    var tags: [String: [Int]]

    @MainActor static func local() -> ToeicCloud {
        .init(results: ToeicStore.results, wrong: ToeicStore.wrong, goal: ToeicStore.goal, tags: ToeicStore.tagStats)
    }

    /// merge the other device's TOEIC records into this one
    @MainActor static func merge(_ o: ToeicCloud) {
        var seen = Set(ToeicStore.results.map(\.id))
        var all = ToeicStore.results
        for r in o.results where !seen.contains(r.id) { all.append(r); seen.insert(r.id) }
        all.sort { $0.date < $1.date }
        ToeicStore.results = all
        var w = ToeicStore.wrong
        for x in o.wrong where !w.contains(x) { w.append(x) }
        ToeicStore.wrong = w
        if ToeicStore.goal == 0 { ToeicStore.goal = o.goal }
        ToeicStore.tagStats = CloudSync.maxPairs(ToeicStore.tagStats, o.tags)
    }
}
