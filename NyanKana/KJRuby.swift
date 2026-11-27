import SwiftUI

// MARK: - ふりがな つきの 文（ルビ）
// markup: {漢字|かんじ} = ruby, "~" = a place the line may break (between word groups), [[ ]] = the part a question hides

extension KJ {
    /// Japanese first, then the learner's language (one line)
    static func jt(_ ja: String, _ en: String, _ zh: String, _ ko: String) -> String { lang == "ja" ? ja : ja + "  " + t(en, zh, ko) }
    /// Japanese on top, the learner's language underneath (two lines, for KJButton)
    static func jt2(_ ja: String, _ en: String, _ zh: String, _ ko: String) -> String { lang == "ja" ? ja : t(en, zh, ko) + "\n" + ja }
}

/// one example sentence (ruby markup) with its translations
struct KJEx: Hashable {
    var ja: String
    var en: String
    var zh: String
    var ko: String
    var meaning: String { KJ.t(en, zh, ko) }
    var plain: String { KJRuby.plain(ja) }
}

enum KJRuby {
    struct Seg: Hashable { var base: String; var ruby: String; var blank: Bool }

    /// the sentence without ruby or marks (what is spoken and recorded)
    static func plain(_ m: String) -> String {
        var out = ""
        for c in chunks(m) { for s in c { out += s.base } }
        return out
    }
    /// the sentence in kana only
    static func kana(_ m: String) -> String {
        var out = ""
        for c in chunks(m) { for s in c { out += s.ruby.isEmpty ? s.base : s.ruby } }
        return out
    }
    /// the hidden part ([[ ]])
    static func blank(_ m: String) -> String {
        var out = ""
        for c in chunks(m) { for s in c where s.blank { out += s.base } }
        return out
    }

    static func chunks(_ m: String) -> [[Seg]] {
        m.split(separator: "~", omittingEmptySubsequences: true).map { segs(String($0)) }
    }

    static func segs(_ s: String) -> [Seg] {
        var out: [Seg] = []
        var blank = false
        var buf = ""
        let cs = Array(s)
        var i = 0
        func flush() { if !buf.isEmpty { out.append(Seg(base: buf, ruby: "", blank: blank)); buf = "" } }
        while i < cs.count {
            if cs[i] == "[", i + 1 < cs.count, cs[i + 1] == "[" { flush(); blank = true; i += 2; continue }
            if cs[i] == "]", i + 1 < cs.count, cs[i + 1] == "]" { flush(); blank = false; i += 2; continue }
            if cs[i] == "{", let bar = cs[i...].firstIndex(of: "|"), let end = cs[i...].firstIndex(of: "}"), bar < end {
                flush()
                out.append(Seg(base: String(cs[(i + 1)..<bar]), ruby: String(cs[(bar + 1)..<end]), blank: blank))
                i = end + 1
                continue
            }
            buf.append(cs[i]); i += 1
        }
        flush()
        return out
    }
}

/// a left-aligned wrapping row (sentences)
struct KJFlow: Layout {
    var spacing: CGFloat = 0
    var line: CGFloat = 4
    var center = false
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let w = proposal.width ?? 360
        var x: CGFloat = 0, y: CGFloat = 0, row: CGFloat = 0, maxX: CGFloat = 0
        for s in subviews {
            let z = s.sizeThatFits(.unspecified)
            if x > 0 && x + z.width > w { y += row + line; x = 0; row = 0 }
            x += z.width + spacing; row = max(row, z.height); maxX = max(maxX, x - spacing)
        }
        return CGSize(width: min(w, maxX), height: y + row)
    }
    func placeSubviews(in b: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var rows: [[(Subviews.Element, CGSize)]] = [[]]
        var x: CGFloat = 0
        for s in subviews {
            let z = s.sizeThatFits(.unspecified)
            if x > 0 && x + z.width > b.width { rows.append([]); x = 0 }
            rows[rows.count - 1].append((s, z)); x += z.width + spacing
        }
        var y = b.minY
        for r in rows {
            let total = r.map(\.1.width).reduce(0, +) + spacing * CGFloat(max(0, r.count - 1))
            var cx = center ? b.minX + (b.width - total) / 2 : b.minX
            let h = r.map(\.1.height).max() ?? 0
            for (s, z) in r { s.place(at: CGPoint(x: cx, y: y + h - z.height), proposal: ProposedViewSize(z)); cx += z.width + spacing }
            y += h + line
        }
    }
}

/// a sentence with furigana over the kanji; the line only breaks between word groups
struct KJRubyText: View {
    enum Blank { case plain, mark, hide, underline }
    let markup: String
    var size: CGFloat = 20
    var ruby = true
    var blank: Blank = .plain
    var color: Color = .ink
    var center = false

    var body: some View {
        if markup.contains("\n") {
            // paragraphs (reading passages)
            VStack(alignment: center ? .center : .leading, spacing: size * 0.35) {
                ForEach(Array(markup.components(separatedBy: "\n").enumerated()), id: \.offset) { _, line in
                    if line.replacingOccurrences(of: "~", with: "").trimmingCharacters(in: .whitespaces).isEmpty {
                        Color.clear.frame(height: size * 0.2)
                    } else {
                        KJRubyText(markup: line, size: size, ruby: ruby, blank: blank, color: color, center: center)
                    }
                }
            }
        } else {
            flow
        }
    }

    private var flow: some View {
        KJFlow(spacing: 0, line: size * 0.25, center: center) {
            ForEach(Array(KJRuby.chunks(markup).enumerated()), id: \.offset) { _, c in
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(Array(merged(c).enumerated()), id: \.offset) { _, s in seg(s) }
                }
                .fixedSize()
            }
        }
    }

    /// a hidden part is shown as one box, even if it is made of several pieces
    private func merged(_ c: [KJRuby.Seg]) -> [KJRuby.Seg] {
        guard blank == .hide else { return c }
        var out: [KJRuby.Seg] = []
        for s in c {
            if s.blank, let l = out.last, l.blank { continue }
            out.append(s.blank ? KJRuby.Seg(base: "（　　）", ruby: "", blank: true) : s)
        }
        return out
    }

    private func seg(_ s: KJRuby.Seg) -> some View {
        let hl = s.blank && blank == .mark
        return VStack(spacing: 0) {
            if ruby {
                Text(s.ruby.isEmpty ? " " : s.ruby).font(.ui(size * 0.42, bold: false))
                    .foregroundStyle(color.opacity(0.7)).lineLimit(1).fixedSize()
                    .opacity(s.ruby.isEmpty ? 0 : 1)
            }
            Text(s.base).font(.custom(Fonts.rounded, size: size))
                .foregroundStyle(hl ? Color.popDeep : s.blank && blank == .hide ? Color.grape : color)
                .underline(s.blank && blank == .underline, color: color)
                .lineLimit(1).fixedSize()
                .background(hl ? RoundedRectangle(cornerRadius: 4).fill(Color.sun.opacity(0.5)) : nil)
        }
    }
}

// MARK: - ぶんぽう（文法）

struct KJGrammar: Identifiable, Hashable {
    var id: String
    var lv: Int                 // 5 = N5, 4 = N4
    var pat: String
    var m: [String]             // meaning en / zh / ko
    var tip: [String]
    var ex: [KJEx]
    var decoys: [String]
    var meaning: String { KJ.t(m[0], m[1], m[2]) }
    var note: String { KJ.t(tip[0], tip[1], tip[2]) }

    static var learned: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: "kj.gram.ok") ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: "kj.gram.ok") }
    }

    /// the check question made from the first example: hide the grammar part, choose it
    var check: KJTQ {
        let e = ex[0]
        let right = KJRuby.blank(e.ja)
        let ch = ([right] + decoys).uniqued().shuffled()
        return KJTQ(head: KJ.jt("（　　）に 入るのは？", "What goes in （　　）?", "（　　）裡填什麼？", "（　　）에 들어갈 말은?"),
                    prompt: e.ja, note: e.meaning, audio: "", choices: ch, answer: ch.firstIndex(of: right) ?? 0,
                    explain: pat + "：" + meaning, key: id)
    }
}

struct KJGrammarList: View {
    @State private var lv = 5
    @State private var open: KJGrammar?
    @State private var quiz: KJGrammarQuizBox?
    @State private var learned = KJGrammar.learned

    var body: some View {
        ZStack {
            VStack(spacing: 8.s) {
                HStack(spacing: 8.s) {
                    levelChip(5); levelChip(4)
                    Spacer()
                    let list = KJGrammar.all.filter { $0.lv == lv }
                    Text("\(list.filter { learned.contains($0.id) }.count) / \(list.count)")
                        .font(.display(14.s)).foregroundStyle(.white)
                }
                .padding(.horizontal, 16.s)
                Button {
                    AudioManager.shared.se(.decide)
                    quiz = KJGrammarQuizBox(list: Array(KJGrammar.all.filter { $0.lv == lv }.shuffled().prefix(10)))
                } label: {
                    Label(KJ.jt("10もん テスト", "10-question check", "10題小測驗", "10문제 테스트"), systemImage: "checkmark.seal.fill")
                        .font(.ui(14.s)).foregroundStyle(Color.ink)
                        .frame(maxWidth: .infinity).padding(.vertical, 9.s)
                        .background(Capsule().fill(Color.sun).overlay(Capsule().stroke(Color.ink, lineWidth: 2.5)))
                }
                .buttonStyle(PressStyle(radius: 20.s, depth: 3))
                .padding(.horizontal, 16.s)
                ScrollView {
                    LazyVStack(spacing: 6.s) {
                        ForEach(KJGrammar.all.filter { $0.lv == lv }) { g in
                            Button { AudioManager.shared.se(.tap); withAnimation(.easeOut(duration: 0.2)) { open = g } } label: { row(g) }
                                .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16.s).padding(.bottom, 24.s)
                }
            }
            if let g = open {
                KJGrammarDetail(g: g) {
                    learned = KJGrammar.learned
                    withAnimation(.easeOut(duration: 0.2)) { open = nil }
                }
                .transition(.move(edge: .trailing))
            }
        }
        .fullScreenCover(item: $quiz) { box in
            KJGrammarQuiz(list: box.list) { learned = KJGrammar.learned; quiz = nil }
        }
    }

    private func levelChip(_ l: Int) -> some View {
        Button { AudioManager.shared.se(.tap); lv = l } label: {
            Text("N\(l)").font(.display(15.s)).foregroundStyle(lv == l ? .white : Color.ink)
                .padding(.horizontal, 16.s).padding(.vertical, 5.s)
                .background(Capsule().fill(lv == l ? Color.grape : Color.white).overlay(Capsule().stroke(Color.ink, lineWidth: 2)))
        }
        .buttonStyle(.plain)
    }

    private func row(_ g: KJGrammar) -> some View {
        HStack(spacing: 10.s) {
            Image(systemName: learned.contains(g.id) ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 18.s, weight: .bold)).foregroundStyle(learned.contains(g.id) ? Color.mintDeep : Color.ink.opacity(0.25))
            VStack(alignment: .leading, spacing: 1.s) {
                Text(g.pat).font(.custom(Fonts.rounded, size: 16.s)).foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.6)
                Text(g.meaning).font(.ui(12.s, bold: false)).foregroundStyle(Color.ink.opacity(0.7)).lineLimit(1)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.system(size: 13.s, weight: .bold)).foregroundStyle(Color.ink.opacity(0.4))
        }
        .padding(.horizontal, 12.s).padding(.vertical, 8.s)
        .background(RoundedRectangle(cornerRadius: 12.s).fill(Color.white.opacity(0.95)).overlay(RoundedRectangle(cornerRadius: 12.s).stroke(Color.ink, lineWidth: 2)))
    }
}

struct KJGrammarQuizBox: Identifiable { let id = UUID(); let list: [KJGrammar] }

/// one grammar point: meaning, how to use it, examples with voice, and a check
struct KJGrammarDetail: View {
    let g: KJGrammar
    var close: () -> Void
    @State private var ruby = true
    @State private var q: KJTQ?
    @State private var picked: Int?

    var body: some View {
        ZStack {
            KJBackdrop(bg: "bg_mg_dojo", dim: 0.55)
            VStack(spacing: 8.s) {
                HStack {
                    BackChip { close() }
                    Spacer()
                    Toggle(isOn: $ruby) { Text("ふりがな").font(.ui(12.s)).foregroundStyle(.white) }.fixedSize()
                }
                .padding(.horizontal, 14.s).padding(.top, 6.s)
                ScrollView {
                    VStack(alignment: .leading, spacing: 12.s) {
                        PaperCard {
                            VStack(alignment: .leading, spacing: 6.s) {
                                Text("N\(g.lv)").font(.display(12.s)).foregroundStyle(.white)
                                    .padding(.horizontal, 8.s).padding(.vertical, 2.s).background(Capsule().fill(Color.grape))
                                Text(g.pat).font(.custom(Fonts.rounded, size: 24.s)).foregroundStyle(Color.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(g.meaning).font(.ui(16.s)).foregroundStyle(Color.popDeep)
                                Text(g.note).font(.ui(14.s, bold: false)).foregroundStyle(Color.ink.opacity(0.85))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Text(KJ.jt("れいぶん", "Examples", "例句", "예문")).font(.ui(14.s)).foregroundStyle(.white)
                        ForEach(g.ex, id: \.self) { e in exampleCard(e) }
                        checkCard
                    }
                    .padding(.horizontal, 16.s).padding(.bottom, 30.s)
                }
            }
        }
        .onAppear { q = g.check }
    }

    private func exampleCard(_ e: KJEx) -> some View {
        Button { Speaker.shared.say(e.plain) } label: {
            HStack(alignment: .top, spacing: 10.s) {
                VStack(alignment: .leading, spacing: 4.s) {
                    KJRubyText(markup: e.ja, size: 19.s, ruby: ruby, blank: .mark)
                    Text(e.meaning).font(.ui(13.s, bold: false)).foregroundStyle(Color.ink.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "speaker.wave.2.fill").font(.system(size: 16.s, weight: .bold)).foregroundStyle(Color.grape)
            }
            .padding(12.s)
            .background(RoundedRectangle(cornerRadius: 14.s).fill(Color.white.opacity(0.96)).overlay(RoundedRectangle(cornerRadius: 14.s).stroke(Color.ink, lineWidth: 2)))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private var checkCard: some View {
        if let q {
            VStack(alignment: .leading, spacing: 8.s) {
                Text(KJ.jt("たしかめよう", "Check", "確認一下", "확인해요")).font(.ui(14.s)).foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 8.s) {
                    KJRubyText(markup: q.prompt, size: 19.s, ruby: ruby, blank: picked == nil ? .hide : .mark)
                    Text(q.note).font(.ui(13.s, bold: false)).foregroundStyle(Color.ink.opacity(0.7))
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 8.s), GridItem(.flexible(), spacing: 8.s)], spacing: 8.s) {
                        ForEach(Array(q.choices.enumerated()), id: \.offset) { k, c in
                            let ok = picked != nil && k == q.answer, ng = picked == k && k != q.answer
                            Button {
                                guard picked == nil else { return }
                                picked = k
                                if k == q.answer {
                                    AudioManager.shared.se(.studyOK)
                                    KJGrammar.learned.insert(g.id)
                                    Speaker.shared.say(KJRuby.plain(q.prompt))
                                } else { AudioManager.shared.se(.studyNG) }
                            } label: {
                                Text(c).font(.custom(Fonts.rounded, size: 17.s)).foregroundStyle(Color.ink)
                                    .lineLimit(1).minimumScaleFactor(0.5)
                                    .frame(maxWidth: .infinity, minHeight: 46.s)
                                    .background(RoundedRectangle(cornerRadius: 12.s).fill(ok ? Color(hex: 0xD9F7E3) : ng ? Color(hex: 0xFFD6D6) : Color.white)
                                        .overlay(RoundedRectangle(cornerRadius: 12.s).stroke(ok ? Color.mintDeep : Color.ink, lineWidth: ok ? 3.5 : 2)))
                            }
                            .buttonStyle(PressStyle(radius: 12.s, depth: 3))
                        }
                    }
                    if picked != nil && picked != q.answer {
                        Button(KJ.jt("もういちど", "Try again", "再試一次", "다시 하기")) { picked = nil; self.q = g.check }
                            .font(.ui(13.s)).foregroundStyle(Color.grape)
                    }
                }
                .padding(12.s)
                .background(RoundedRectangle(cornerRadius: 14.s).fill(Color(hex: 0xFFFBF2)).overlay(RoundedRectangle(cornerRadius: 14.s).stroke(Color.ink, lineWidth: 2)))
            }
        }
    }
}

/// 10 grammar points in a row
struct KJGrammarQuiz: View {
    let list: [KJGrammar]
    var done: () -> Void
    @State private var i = 0
    @State private var q: KJTQ?
    @State private var picked: Int?
    @State private var right = 0
    @State private var finished = false
    @State private var missed: [KJGrammar] = []

    var body: some View {
        ZStack {
            KJBackdrop(bg: "bg_mg_dojo", dim: 0.55)
            VStack(spacing: 12.s) {
                HStack {
                    BackChip { done() }
                    Spacer()
                    if !finished { Text("\(i + 1) / \(list.count)").font(.display(16.s)).foregroundStyle(.white) }
                }
                .padding(.horizontal, 14.s).padding(.top, 6.s)
                if finished { result } else if let q { board(q) }
                Spacer(minLength: 0)
            }
        }
        .onAppear { load() }
    }

    private func load() { q = list[safe: i]?.check; picked = nil }

    private func board(_ q: KJTQ) -> some View {
        VStack(spacing: 14.s) {
            PaperCard {
                VStack(spacing: 8.s) {
                    Text(q.head).font(.ui(13.s)).foregroundStyle(Color.ink.opacity(0.7))
                    KJRubyText(markup: q.prompt, size: 21.s, ruby: true, blank: picked == nil ? .hide : .mark, center: true)
                    Text(q.note).font(.ui(14.s, bold: false)).foregroundStyle(Color.ink.opacity(0.75)).multilineTextAlignment(.center)
                    if picked != nil {
                        Text(q.explain).font(.ui(13.s)).foregroundStyle(Color.popDeep).multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16.s)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10.s), GridItem(.flexible(), spacing: 10.s)], spacing: 10.s) {
                ForEach(Array(q.choices.enumerated()), id: \.offset) { k, c in
                    let ok = picked != nil && k == q.answer, ng = picked == k && k != q.answer
                    Button { choose(k, q) } label: {
                        Text(c).font(.custom(Fonts.rounded, size: 20.s)).foregroundStyle(Color.ink)
                            .lineLimit(1).minimumScaleFactor(0.5)
                            .frame(maxWidth: .infinity, minHeight: 60.s)
                            .background(RoundedRectangle(cornerRadius: 16.s).fill(ok ? Color(hex: 0xD9F7E3) : ng ? Color(hex: 0xFFD6D6) : Color.white)
                                .overlay(RoundedRectangle(cornerRadius: 16.s).stroke(ok ? Color.mintDeep : Color.ink, lineWidth: ok ? 4 : 3)))
                    }
                    .buttonStyle(PressStyle(radius: 16.s, depth: 4))
                }
            }
            .padding(.horizontal, 16.s)
            if picked != nil {
                KJButton(title: KJ.jt2("つぎへ", "Next", "下一題", "다음"), color: .pop, textColor: .white) {
                    if i + 1 < list.count { i += 1; load() } else {
                        withAnimation { finished = true }
                        AudioManager.shared.se(right >= list.count - 2 ? .studyClear : .studyOK)
                    }
                }
                .padding(.horizontal, 40.s)
            }
        }
    }

    private func choose(_ k: Int, _ q: KJTQ) {
        guard picked == nil else { return }
        picked = k
        if k == q.answer {
            right += 1
            AudioManager.shared.se(.studyOK)
            KJGrammar.learned.insert(list[i].id)
            Speaker.shared.say(KJRuby.plain(q.prompt))
        } else {
            AudioManager.shared.se(.studyNG)
            missed.append(list[i])
        }
    }

    private var result: some View {
        VStack(spacing: 14.s) {
            Image(right >= list.count - 2 ? "nk_nyan_joy" : "nk_nyan_think").resizable().scaledToFit().frame(height: 140.s)
            OutlinedText("\(right) / \(list.count)", font: .display(48.s), fill: .sun, width: 4, shadow: 3)
            if !missed.isEmpty {
                VStack(alignment: .leading, spacing: 4.s) {
                    Text(KJ.jt("まちがえた ぶんぽう", "Review these", "答錯的文法", "틀린 문법")).font(.ui(13.s)).foregroundStyle(Color.ink.opacity(0.7))
                    ForEach(missed) { g in
                        Text("・" + g.pat + "　" + g.meaning).font(.ui(13.s, bold: false)).foregroundStyle(Color.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(12.s).frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 14.s).fill(Color.white.opacity(0.95)))
                .padding(.horizontal, 20.s)
            }
            KJButton(title: KJ.jt2("もどる", "Back", "返回", "돌아가기"), color: .white) { done() }
                .padding(.horizontal, 40.s)
        }
    }
}
