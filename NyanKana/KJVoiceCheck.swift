import SwiftUI
import UIKit

// MARK: - 開発モード：音声チェック一覧
// すべての声を 種類ごとに 並べて、1つずつ 聞いて「OK」「おかしい」を つける。おかしい物は まとめて コピーして Claude に送れる。

struct KJVoiceCheckView: View {
    struct Item: Identifiable, Hashable {
        var id: String { kind + "|" + role + "|" + text }
        var kind: String
        var text: String
        var reading: String
        var role: String      // "" = the word voice (Speaker.say)
    }
    enum Mark: String { case ok, bad }

    @State private var part = 0
    @State private var marks: [String: Mark] = Self.load()
    @State private var onlyLeft = false
    @State private var onlyFixed = false
    @State private var copied = false

    private static let key = "kj.voicecheck"
    private static func load() -> [String: Mark] {
        var d = UserDefaults.standard.dictionary(forKey: key) as? [String: String] ?? [:]
        // 録り直した 声は「おかしい」の しるしを はずして、もう一度 きけるように
        let rev = UserDefaults.standard.integer(forKey: key + ".rev")
        if rev < 3 {
            d = d.filter { e in !(e.value == Mark.bad.rawValue && KJVoiceFixed.texts.contains(String(e.key.split(separator: "|", maxSplits: 2).last ?? ""))) }
            UserDefaults.standard.set(d, forKey: key)
            UserDefaults.standard.set(3, forKey: key + ".rev")
        }
        if rev < 4 {
            d = d.filter { e in !(e.value == Mark.bad.rawValue && KJVoiceFixed.round2.contains(String(e.key.split(separator: "|", maxSplits: 2).last ?? ""))) }
            UserDefaults.standard.set(d, forKey: key)
            UserDefaults.standard.set(4, forKey: key + ".rev")
        }
        return d.compactMapValues(Mark.init(rawValue:))
    }
    private func save() { UserDefaults.standard.set(marks.mapValues(\.rawValue), forKey: Self.key) }

    private static let parts = ["かんじの ことば", "かなの ことば", "かいわ", "ボス", "ストーリー"]

    /// every voice, grouped
    private static let all: [[Item]] = {
        var seen = Set<String>()
        let words = KJData.words.filter { seen.insert($0.ja).inserted }
        let kanji = words.filter { KJSimilar.hasKanji($0.ja) }.map { Item(kind: "ことば", text: $0.ja, reading: KJData.yomi($0.ja) ?? "", role: "") }
        let kana = words.filter { !KJSimilar.hasKanji($0.ja) }.map { Item(kind: "ことば", text: $0.ja, reading: "", role: "") }
        let talk = KJScene.all.flatMap { s in s.lines.map { Item(kind: "かいわ " + s.ja, text: $0.ja, reading: $0.kana, role: $0.me ? "kp" : s.face) } }
        var boss: [Item] = []
        for lap in [2, 3] { for c in 1...7 { if let b = KJLap.boss(lap: lap, chapter: c) {
            for t in [b.intro, b.half, b.out] { boss.append(Item(kind: b.ja, text: t, reading: "", role: b.role)) }
        } } }
        let story = KJC1.linesLap.keys.sorted().flatMap { id in
            let l = KJC1.linesLap[id]!
            return (l.pre + l.post).filter { !$0.ja.isEmpty }.map { Item(kind: "ストーリー \(id / 100000)-\(id / 1000 % 100)", text: $0.ja, reading: "", role: $0.role) }
        }
        return [kanji, kana, talk, boss, story]
    }()

    private var items: [Item] {
        let l = Self.all[part]
        let a = onlyFixed ? l.filter { KJVoiceFixed.texts.contains($0.text) } : l
        return onlyLeft ? a.filter { marks[$0.id] == nil } : a
    }

    var body: some View {
        VStack(spacing: 8) {
            Picker("", selection: $part) {
                ForEach(0..<Self.parts.count, id: \.self) { Text(Self.parts[$0]).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            HStack {
                let l = Self.all[part]
                Text("きいた \(l.filter { marks[$0.id] != nil }.count) / \(l.count)　おかしい \(l.filter { marks[$0.id] == .bad }.count)")
                    .font(.footnote)
                Spacer()
                Toggle("まだの物だけ", isOn: $onlyLeft).font(.footnote).fixedSize()
            }
            .padding(.horizontal)
            HStack {
                Text("なおした声：\(Self.all[part].filter { KJVoiceFixed.texts.contains($0.text) }.count)").font(.footnote).foregroundStyle(.orange)
                Spacer()
                Toggle("なおした物だけ", isOn: $onlyFixed).font(.footnote).fixedSize()
            }
            .padding(.horizontal)
            List(items) { it in
                HStack(spacing: 10) {
                    Button { play(it) } label: {
                        Image(systemName: "speaker.wave.2.fill").foregroundStyle(.blue)
                    }
                    .buttonStyle(.borderless)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(it.text).font(.body)
                            if KJVoiceFixed.texts.contains(it.text) {
                                Text("なおした").font(.caption2.bold()).foregroundStyle(.white)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Capsule().fill(Color.orange))
                            }
                        }
                        if !it.reading.isEmpty && it.reading != it.text { Text(it.reading).font(.caption).foregroundStyle(.secondary) }
                        Text(it.kind).font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer()
                    markButton(it, .ok, "checkmark.circle.fill", .green)
                    markButton(it, .bad, "xmark.circle.fill", .red)
                }
                .contentShape(Rectangle())
                .onTapGesture { play(it) }
            }
            .listStyle(.plain)
            HStack {
                Button(copied ? "コピーしました" : "おかしい物を コピー（\(marks.values.filter { $0 == .bad }.count)）") { copyBad() }
                    .buttonStyle(.borderedProminent)
                Button("ぜんぶ けす") { marks = [:]; save() }.buttonStyle(.bordered)
            }
            .padding(.bottom, 8)
        }
        .navigationTitle("音声チェック")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func markButton(_ it: Item, _ m: Mark, _ icon: String, _ c: Color) -> some View {
        Button {
            marks[it.id] = marks[it.id] == m ? nil : m
            save()
        } label: {
            Image(systemName: icon).font(.title3).foregroundStyle(marks[it.id] == m ? c : Color.gray.opacity(0.35))
        }
        .buttonStyle(.borderless)
    }

    private func play(_ it: Item) {
        if it.role.isEmpty { Speaker.shared.say(it.text) } else { Speaker.shared.sayRole(it.text, role: it.role) }
    }

    /// the wrong ones as text, to paste to Claude
    private func copyBad() {
        let bad = Self.all.flatMap { $0 }.filter { marks[$0.id] == .bad }
        let text = "おかしい音声（\(bad.count)件）\n" + bad.map { "・\($0.kind)：\($0.text)" + ($0.reading.isEmpty ? "" : "（\($0.reading)）") }.joined(separator: "\n")
        UIPasteboard.general.string = text
        copied = true
        later(2) { copied = false }
    }
}
