import SwiftUI

// MARK: - じしょ：ことばの くわしい 画面（例文・漢字・ゆっくり音声・にている ことば）

struct KJDictEx: Hashable {
    var ex: KJEx
    var note: [String]
    var tip: String { KJ.t(note[0], note[1], note[2]) }
}

enum KJDict {
    /// the same word written in kana or kanji: same reading and same meaning
    static func same(_ w: KJData.Word) -> String { (KJData.yomi(w.ja) ?? w.ja) + "|" + w.en.lowercased() }
    /// the kana spelling of the same word (かりる for 借りる), if the journey teaches it too
    static func kanaTwin(_ w: KJData.Word) -> String? {
        guard KJSimilar.hasKanji(w.ja) else { return nil }
        let k = same(w)
        return KJData.words.first { !KJSimilar.hasKanji($0.ja) && same($0) == k }?.ja
    }
    /// the example for a word, or for its other spelling
    static func example(_ w: KJData.Word) -> KJDictEx? {
        if let e = ex[w.ja] { return e }
        let k = same(w)
        return KJData.words.first { same($0) == k && ex[$0.ja] != nil }.flatMap { ex[$0.ja] }
    }

    /// words that are easy to mix up with `w`: one letter swapped for a look-alike, or the same sound
    static func similar(_ w: String) -> [KJData.Word] {
        let read = KJData.yomi(w) ?? w
        let groups = KJData.lookAlike
        var out: [KJData.Word] = []
        var seen: Set<String> = [w]
        let cs = Array(w)
        for other in KJData.words where !seen.contains(other.ja) {
            let o = Array(other.ja)
            var hit = false
            // same sound, different word (はし / 橋 / 箸)
            if (KJData.yomi(other.ja) ?? other.ja) == read { hit = true }
            // one letter different, and the two letters look alike
            if !hit && o.count == cs.count {
                let diff = zip(cs, o).filter { $0 != $1 }
                if diff.count == 1, let d = diff.first, groups.contains(where: { $0.contains(String(d.0)) && $0.contains(String(d.1)) }) { hit = true }
            }
            if hit { out.append(other); seen.insert(other.ja) }
            if out.count >= 6 { break }
        }
        return out
    }
}

struct KJWordBox: Identifiable { let w: KJData.Word; var id: String { w.ja } }

struct KJWordSheet: View {
    let w: KJData.Word
    @Environment(\.dismiss) private var dismiss
    @State private var ruby = true
    @State private var kanji: KJKanji?
    @State private var next: KJWordBox?

    var body: some View {
        let read = KJData.yomi(w.ja) ?? w.ja
        let ex = KJDict.example(w)
        ScrollView {
            VStack(alignment: .leading, spacing: 14.s) {
                HStack {
                    Toggle(isOn: $ruby) { Text("ふりがな").font(.ui(12.s)) }.fixedSize()
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.system(size: 16.s, weight: .black)).foregroundStyle(Color.ink)
                            .frame(width: 36.s, height: 36.s).background(Circle().fill(Color.white).overlay(Circle().stroke(Color.ink, lineWidth: 2)))
                    }
                }
                // the word
                HStack(spacing: 14.s) {
                    KJPicView(w.emoji, size: 70.s)
                    VStack(alignment: .leading, spacing: 2.s) {
                        KJFuri(w.ja, size: 34.s, force: true)
                        Text(read.applyingTransform(.toLatin, reverse: false) ?? "").font(.ui(13.s, bold: false)).foregroundStyle(Color.ink.opacity(0.55))
                        Text(w.meaning).font(.ui(17.s)).foregroundStyle(Color.popDeep).fixedSize(horizontal: false, vertical: true)
                        if let twin = KJDict.kanaTwin(w) {
                            Text(KJ.jt("かなで かくと：", "In kana: ", "用假名寫：", "가나로 쓰면: ") + twin).font(.ui(12.s, bold: false)).foregroundStyle(Color.ink.opacity(0.6))
                        }
                    }
                    Spacer(minLength: 0)
                }
                HStack(spacing: 10.s) {
                    soundButton(KJ.jt("きく", "Listen", "聽", "듣기"), "speaker.wave.3.fill", Color.sky) { Speaker.shared.say(w.ja, slow: false) }
                    soundButton(KJ.jt("ゆっくり", "Slow", "慢速", "천천히"), "tortoise.fill", Color.mintDeep) { Speaker.shared.say(w.ja, slow: true) }
                }
                // example
                if let ex {
                    section(KJ.jt("れいぶん", "Example", "例句", "예문")) {
                        VStack(alignment: .leading, spacing: 6.s) {
                            KJRubyText(markup: ex.ex.ja, size: 19.s, ruby: ruby)
                            Text(ex.ex.meaning).font(.ui(13.s, bold: false)).foregroundStyle(Color.ink.opacity(0.75)).fixedSize(horizontal: false, vertical: true)
                            HStack(spacing: 10.s) {
                                soundButton(KJ.jt("きく", "Listen", "聽", "듣기"), "speaker.wave.2.fill", Color.sky) { Speaker.shared.say(ex.ex.plain, slow: false) }
                                soundButton(KJ.jt("ゆっくり", "Slow", "慢速", "천천히"), "tortoise.fill", Color.mintDeep) { Speaker.shared.say(ex.ex.plain, slow: true) }
                            }
                            if !ex.tip.isEmpty {
                                Label(ex.tip, systemImage: "lightbulb.fill").font(.ui(12.s, bold: false)).foregroundStyle(Color.ink.opacity(0.8))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                // kanji in the word
                let ks = w.ja.map(String.init).compactMap { KJKanji.byChar[$0] }
                if !ks.isEmpty {
                    section(KJ.jt("かんじ", "Kanji", "漢字", "한자")) {
                        VStack(spacing: 6.s) {
                            ForEach(ks) { k in
                                Button { kanji = k } label: {
                                    HStack(spacing: 10.s) {
                                        Text(k.k).font(.custom(Fonts.rounded, size: 30.s)).foregroundStyle(Color.ink).frame(width: 44.s)
                                        VStack(alignment: .leading, spacing: 1.s) {
                                            Text(k.meaning).font(.ui(13.s)).foregroundStyle(Color.ink)
                                            Text((k.on + k.kun).joined(separator: "・")).font(.ui(12.s, bold: false)).foregroundStyle(Color.ink.opacity(0.65)).lineLimit(1)
                                        }
                                        Spacer(minLength: 0)
                                        Image(systemName: "chevron.right").foregroundStyle(Color.ink.opacity(0.4))
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                // easy to mix up
                let sim = KJDict.similar(w.ja)
                if !sim.isEmpty {
                    section(KJ.jt("にている ことば", "Easy to mix up", "容易混淆的詞", "헷갈리기 쉬운 단어")) {
                        VStack(spacing: 6.s) {
                            ForEach(sim, id: \.ja) { s in
                                Button { Speaker.shared.say(s.ja); next = KJWordBox(w: s) } label: {
                                    HStack(spacing: 10.s) {
                                        KJPicView(s.emoji, size: 28.s)
                                        KJFuri(s.ja, size: 18.s, force: true)
                                        Text(s.meaning).font(.ui(12.s, bold: false)).foregroundStyle(Color.ink.opacity(0.7)).lineLimit(1)
                                        Spacer(minLength: 0)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(18.s)
        }
        .background(Color(hex: 0xFFFBF2).ignoresSafeArea())
        .onAppear { Speaker.shared.say(w.ja) }
        .sheet(item: $kanji) { k in KJKanjiSheet(k: k) }
        .sheet(item: $next) { b in KJWordSheet(w: b.w) }
    }

    private func soundButton(_ t: String, _ icon: String, _ c: Color, _ act: @escaping () -> Void) -> some View {
        Button(action: act) {
            Label(t, systemImage: icon).font(.ui(13.s)).foregroundStyle(.white)
                .padding(.horizontal, 14.s).padding(.vertical, 8.s)
                .background(Capsule().fill(c).overlay(Capsule().stroke(Color.ink, lineWidth: 2)))
        }
        .buttonStyle(PressStyle(radius: 18.s, depth: 3))
    }

    private func section<C: View>(_ title: String, @ViewBuilder _ c: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 6.s) {
            Text(title).font(.ui(13.s)).foregroundStyle(Color.ink.opacity(0.65))
            c().frame(maxWidth: .infinity, alignment: .leading).padding(12.s)
                .background(RoundedRectangle(cornerRadius: 14.s).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 14.s).stroke(Color.ink, lineWidth: 2)))
        }
    }
}
