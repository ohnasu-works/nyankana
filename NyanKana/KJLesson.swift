import SwiftUI

// MARK: - 基本マス：ふつうの学習ゲーム（新しい文字を、順番に、もれなく）
// 1 きいて えらぶ → 2 よんで えらぶ → 3 なぞる → 4 もういちど きく（似た字まぜ）→ 5 ことば → 6 ふくしゅう（前の字・にがての字）
// まちがえた問題は 最後に もう一度出る（できるまで）。にがての字は KJWeak に記録して、あとの問題に多めに出す。

/// letters the player keeps missing (shared by the lessons and the games)
enum KJWeak {
    private static let key = "kj.weak"
    static var all: [String: Int] {
        get { (UserDefaults.standard.dictionary(forKey: key) as? [String: Int]) ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
    static func miss(_ k: String) { var a = all; a[k, default: 0] += 2; all = a; KJSRS.miss(k) }
    static func hit(_ k: String) {
        KJSRS.hit(k)
        var a = all
        guard let v = a[k] else { return }
        a[k] = v > 1 ? v - 1 : nil
        all = a
    }
    /// the weakest letters among `pool`
    static func top(_ n: Int, in pool: [String]) -> [String] {
        let a = all
        return pool.filter { (a[$0] ?? 0) > 0 }.sorted { (a[$0] ?? 0) > (a[$1] ?? 0) }.prefix(n).map { $0 }
    }
}

struct KJLessonView: View {
    let stage: KJC1.Stage
    var finished: (_ stars: Int, _ score: Int, _ won: [String]) -> Void

    enum Q: Equatable {
        case listen(String), read(String), trace(String), word(String), review(String)
        /// ことばマス: hear a word → pick how it is written / see a word → pick what it means
        case hearWord(String), meaning(String)
        var key: String {
            switch self {
            case .listen(let k), .read(let k), .trace(let k), .word(let k), .review(let k), .hearWord(let k), .meaning(let k): k
            }
        }
    }
    @State private var queue: [Q] = []
    @State private var total = 0
    @State private var i = 0
    @State private var firstTry = 0
    @State private var missed: Set<Int> = []       // indexes answered wrong at least once
    @State private var retried: [String: Int] = [:]
    @State private var choices: [String] = []
    @State private var picked: String?
    @State private var showRight = false
    @State private var mark: Bool?                  // ◯ / ✕ flash
    // word round
    @State private var typed: [String] = []
    @State private var pad: [String] = []
    // trace
    @State private var glyph: (image: UIImage, mask: [Bool]) = (UIImage(), [])
    @State private var strokes: [[CGPoint]] = []
    @State private var drawing = false
    @State private var traceTries = 0
    @State private var done = false

    private var pool: [String] { stage.known.isEmpty ? stage.newKana : stage.known }
    private var q: Q? { queue[safe: i] }

    var body: some View {
        ZStack {
            KJBackdrop(bg: stage.bg, dim: 0.45)
            VStack(spacing: 12.s) {
                progress.padding(.top, 54.s)
                if let q {
                    header(q)
                    Spacer(minLength: 0)
                    content(q)
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, 18.s)
            .padding(.bottom, 24.s)
            if let m = mark {
                Image(systemName: m ? "circle" : "xmark")
                    .font(.system(size: 160.s, weight: .black))
                    .foregroundStyle(m ? Color.danger : Color.sky)
                    .shadow(color: .white, radius: 6)
                    .transition(.scale(scale: 1.6).combined(with: .opacity))
                    .allowsHitTesting(false)
            }
        }
        .onAppear(perform: build)
    }

    // MARK: parts

    private var progress: some View {
        VStack(spacing: 4.s) {
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white)
                    Capsule().fill(Color.mint).frame(width: g.size.width * CGFloat(min(i, queue.count)) / CGFloat(max(queue.count, 1)))
                }
                .overlay(Capsule().stroke(Color.ink, lineWidth: 2))
            }
            .frame(height: 12.s)
            Text("\(min(i + 1, queue.count)) / \(queue.count)").font(.display(13.s)).foregroundStyle(.white)
        }
    }

    private func header(_ q: Q) -> some View {
        let (ja, help) = labels(q)
        return HStack(spacing: 10.s) {
            Image(retried[q.key] != nil && missed.contains(i) ? "nk_nyan_think" : "nk_nyan_tip").resizable().scaledToFit().frame(height: 64.s)
            VStack(alignment: .leading, spacing: 2.s) {
                Text(ja).font(.custom(Fonts.rounded, size: 20.s)).foregroundStyle(Color.ink)
                Text(help).font(.ui(12.s, bold: false)).foregroundStyle(Color.ink.opacity(0.7))
                if case .review = q {
                    Text(KJ.t("Review", "複習", "복습")).font(.display(11.s)).foregroundStyle(.white)
                        .padding(.horizontal, 6.s).background(Capsule().fill(Color.grape))
                }
            }
            Spacer()
        }
        .padding(10.s)
        .background(RoundedRectangle(cornerRadius: 16.s).fill(Color.white.opacity(0.92)).overlay(RoundedRectangle(cornerRadius: 16.s).stroke(Color.ink, lineWidth: 2.5)))
    }

    private func labels(_ q: Q) -> (String, String) {
        switch q {
        case .listen, .review: return ("きいて えらぼう", KJ.t("Listen and choose", "聽音選字", "듣고 고르기"))
        case .read: return ("よんで えらぼう", KJ.t("How do you read it?", "怎麼唸？", "어떻게 읽어요?"))
        case .trace: return ("なぞって かこう", KJ.t("Trace it with your finger", "用手指描寫", "손가락으로 따라 쓰기"))
        case .word: return ("ことばを つくろう", KJ.t("Make the word", "拼出這個詞", "단어 만들기"))
        case .hearWord: return ("ことばを きこう", KJ.t("Listen: which word is it?", "聽聽看，是哪個詞？", "듣고 어떤 단어인지 골라요"))
        case .meaning: return ("いみは どれ？", KJ.t("What does it mean?", "是什麼意思？", "무슨 뜻이에요?"))
        }
    }

    @ViewBuilder private func content(_ q: Q) -> some View {
        switch q {
        case .listen(let k), .review(let k):
            VStack(spacing: 18.s) {
                speakerButton(k, big: true)
                choiceGrid(answer: k, labels: choices)
            }
        case .read(let k):
            VStack(spacing: 18.s) {
                Text(k).font(.custom(Fonts.rounded, size: 110.s)).foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.35)
                    .lineLimit(1).minimumScaleFactor(0.5)
                    .frame(width: 190.s, height: 170.s)
                    .background(RoundedRectangle(cornerRadius: 24.s).fill(Color(hex: 0xFFF6E0)).overlay(RoundedRectangle(cornerRadius: 24.s).stroke(Color.ink, lineWidth: 3)))
                choiceGrid(answer: KJData.romaji(k), labels: choices, display: true)
            }
        case .trace(let k):
            trace(k)
        case .word(let w):
            word(w)
        case .hearWord(let w):
            VStack(spacing: 18.s) {
                speakerButton(w, big: true)
                choiceGrid(answer: w, labels: choices)
            }
        case .meaning(let w):
            VStack(spacing: 18.s) {
                Button { Speaker.shared.say(w) } label: {
                    Text(w).font(.custom(Fonts.rounded, size: 64.s)).foregroundStyle(Color.ink)
                        .lineLimit(1).minimumScaleFactor(0.4)
                        .padding(.horizontal, 20.s)
                        .frame(minWidth: 190.s, minHeight: 130.s)
                        .background(RoundedRectangle(cornerRadius: 24.s).fill(Color(hex: 0xFFF6E0)).overlay(RoundedRectangle(cornerRadius: 24.s).stroke(Color.ink, lineWidth: 3)))
                }
                .buttonStyle(.plain)
                meaningGrid(answer: w)
            }
        }
    }

    /// the four meanings (picture + words in the learner's language)
    private func meaningGrid(answer: String) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12.s), GridItem(.flexible(), spacing: 12.s)], spacing: 12.s) {
            ForEach(choices, id: \.self) { c in
                let info = KJData.word(c)
                let isRight = showRight && c == answer
                let isWrong = picked == c && c != answer
                Button { choose(c, answer: answer) } label: {
                    VStack(spacing: 2.s) {
                        KJPicView(info?.emoji ?? "❓", size: 39.1.s)
                        Text(info?.meaning ?? "").font(.ui(14.s)).foregroundStyle(Color.ink)
                            .lineLimit(2).minimumScaleFactor(0.6).multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity).frame(height: 96.s)
                    .background(RoundedRectangle(cornerRadius: 18.s)
                        .fill(isRight ? Color(hex: 0xD9F7E3) : isWrong ? Color(hex: 0xFFD6D6) : Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 18.s).stroke(isRight ? Color.mintDeep : Color.ink, lineWidth: isRight ? 4 : 3)))
                }
                .buttonStyle(PressStyle(radius: 18.s, depth: 4))
                .disabled(picked != nil)
            }
        }
    }

    /// three other words for the choices: ones of the same length that the player can read first
    private func wordDecoys(_ w: String) -> [String] {
        let have = Set(pool)
        let readable = KJData.words.map(\.ja).filter { $0 != w && $0.allSatisfy { have.contains(String($0)) || "ゃゅょっー".contains($0) } }
        var out = (stage.words.filter { $0 != w && KJData.word($0) != nil } + readable.filter { $0.count == w.count } + readable).uniqued()
        // the same word with one letter swapped looks the most alike
        let chars = w.map(String.init)
        if let i = chars.indices.randomElement(), let swap = mgDecoys(chars[i], pool).first(where: { $0 != chars[i] }) {
            var c = chars; c[i] = swap; out.insert(c.joined(), at: 0)
        }
        for x in KJData.words.map(\.ja).shuffled() where out.count < 3 && x != w && !out.contains(x) { out.append(x) }
        return Array(out.filter { $0 != w }.prefix(3))
    }

    private func speakerButton(_ k: String, big: Bool) -> some View {
        Button { Speaker.shared.say(k) } label: {
            Image(systemName: "speaker.wave.3.fill").font(.system(size: big ? 36.s : 22.s, weight: .bold)).foregroundStyle(.white)
                .frame(width: big ? 96.s : 56.s, height: big ? 96.s : 56.s)
                .background(Circle().fill(Color.sky).overlay(Circle().stroke(Color.ink, lineWidth: 3)))
        }
        .buttonStyle(PressStyle(radius: big ? 48.s : 28.s, depth: 4))
    }

    private func choiceGrid(answer: String, labels: [String], display: Bool = false) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12.s), GridItem(.flexible(), spacing: 12.s)], spacing: 12.s) {
            ForEach(labels, id: \.self) { c in
                let isRight = showRight && c == answer
                let isWrong = picked == c && c != answer
                Button { choose(c, answer: answer) } label: {
                    Text(c)
                        .font(display ? Font.display(30.s) : Font.custom(Fonts.rounded, size: c.count > 1 ? 34.s : 44.s))
                        .foregroundStyle(Color.ink)
                        .lineLimit(1).minimumScaleFactor(0.5)
                        .frame(maxWidth: .infinity).frame(height: 84.s)
                        .background(RoundedRectangle(cornerRadius: 18.s)
                            .fill(isRight ? Color(hex: 0xD9F7E3) : isWrong ? Color(hex: 0xFFD6D6) : Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 18.s).stroke(isRight ? Color.mintDeep : Color.ink, lineWidth: isRight ? 4 : 3)))
                }
                .buttonStyle(PressStyle(radius: 18.s, depth: 4))
                .disabled(picked != nil)
            }
        }
    }

    // MARK: trace

    private func trace(_ k: String) -> some View {
        GeometryReader { g in
            let side = min(g.size.width, g.size.height - 80.s)
            VStack(spacing: 12.s) {
                ZStack {
                    Rectangle().fill(Color(hex: 0xFFFDF5))
                    Path { p in
                        p.move(to: CGPoint(x: side / 2, y: 0)); p.addLine(to: CGPoint(x: side / 2, y: side))
                        p.move(to: CGPoint(x: 0, y: side / 2)); p.addLine(to: CGPoint(x: side, y: side / 2))
                    }
                    .stroke(Color(hex: 0xE05050).opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [6, 6]))
                    Image(uiImage: glyph.image).resizable().frame(width: side, height: side).blendMode(.multiply).opacity(0.22)
                    Canvas { c, _ in
                        for s in strokes {
                            guard let f = s.first else { continue }
                            var p = Path()
                            p.move(to: CGPoint(x: f.x * side, y: f.y * side))
                            for q in s.dropFirst() { p.addLine(to: CGPoint(x: q.x * side, y: q.y * side)) }
                            if s.count == 1 { p.addLine(to: CGPoint(x: f.x * side + 0.5, y: f.y * side)) }
                            c.stroke(p, with: .color(Color(hex: 0x1A1A1A)), style: StrokeStyle(lineWidth: side * 0.085, lineCap: .round, lineJoin: .round))
                        }
                    }
                }
                .frame(width: side, height: side)
                .overlay(Rectangle().stroke(Color.ink, lineWidth: 3))
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        guard picked == nil else { return }
                        let p = CGPoint(x: min(max(v.location.x / side, 0), 1), y: min(max(v.location.y / side, 0), 1))
                        if !drawing { drawing = true; strokes.append([p]); AudioManager.shared.se(.mgBrush, volume: 0.6) }
                        else if !strokes.isEmpty { strokes[strokes.count - 1].append(p) }
                    }
                    .onEnded { _ in drawing = false })
                HStack(spacing: 12.s) {
                    KJButton(title: KJ.both("Clear", "擦掉", "지우기"), color: .white) { strokes = [] }
                    KJButton(title: "OK!", color: .pop, textColor: .white) { judgeTrace(k) }
                }
            }
            .frame(width: g.size.width)
        }
    }

    private func judgeTrace(_ k: String) {
        guard picked == nil, !strokes.isEmpty else { return }
        let r = MGGlyph.judge(strokes, mask: glyph.mask)
        if r.cover >= 0.55 && r.inside >= 0.7 {
            Speaker.shared.say(k)
            right(k)
        } else {
            traceTries += 1
            AudioManager.shared.se(.studyNG)
            strokes = []
            if traceTries == 1 { missed.insert(i); KJWeak.miss(k) }
            if traceTries >= 3 { right(k, counts: false) }   // never stuck: move on after three tries
        }
    }

    // MARK: word

    private func word(_ w: String) -> some View {
        let chars = w.map(String.init)
        let info = KJData.word(w)
        return VStack(spacing: 14.s) {
            HStack(spacing: 12.s) {
                KJPicView(info?.emoji ?? "❓", size: 73.6.s)
                VStack(alignment: .leading) {
                    Text(info?.meaning ?? "").font(.ui(18.s)).foregroundStyle(Color.ink)
                    speakerButton(w, big: false)
                }
            }
            HStack(spacing: 6.s) {
                ForEach(0..<chars.count, id: \.self) { j in
                    Text(j < typed.count ? typed[j] : "？")
                        .font(.custom(Fonts.rounded, size: 32.s))
                        .foregroundStyle(j < typed.count ? Color.ink : Color.ink.opacity(0.3))
                        .frame(width: 52.s, height: 60.s)
                        .background(RoundedRectangle(cornerRadius: 10.s).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 10.s).stroke(Color.ink, lineWidth: 2.5)))
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8.s), count: 4), spacing: 8.s) {
                ForEach(pad, id: \.self) { k in
                    Button { typeKey(k, want: chars) } label: {
                        Text(k).font(.custom(Fonts.rounded, size: 30.s)).foregroundStyle(Color.ink)
                            .frame(maxWidth: .infinity).frame(height: 62.s)
                            .background(RoundedRectangle(cornerRadius: 14.s).fill(Color(hex: 0xFFF6E0)).overlay(RoundedRectangle(cornerRadius: 14.s).stroke(Color.ink, lineWidth: 2.5)))
                    }
                    .buttonStyle(PressStyle(radius: 14.s, depth: 3))
                }
            }
        }
    }

    private func typeKey(_ k: String, want: [String]) {
        guard picked == nil, typed.count < want.count, let w = q?.key else { return }
        if k == want[typed.count] {
            AudioManager.shared.se(.tap)
            typed.append(k)
            if typed.count == want.count { Speaker.shared.say(w); right(w) }
        } else {
            AudioManager.shared.se(.studyNG)
            KJWeak.miss(want[typed.count])
            if !missed.contains(i) { missed.insert(i) }
            Speaker.shared.say(want[typed.count])
        }
    }

    // MARK: flow

    private func build() {
        if stage.newKana.isEmpty { buildWords(); return }
        let new = stage.newKana
        let others = pool.filter { !new.contains($0) }
        var qs: [Q] = []
        qs += new.shuffled().map { .listen($0) }
        qs += new.shuffled().map { .read($0) }
        qs += new.map { .trace($0) }
        qs += new.shuffled().map { .listen($0) }
        let words = stage.words.filter { w in new.contains { w.contains($0) } && KJData.word(w) != nil }
        qs += words.prefix(2).map { .word($0) }
        // review: the weakest letters first, then the earlier ones
        var rev = KJWeak.top(3, in: pool)
        rev += others.shuffled().filter { !rev.contains($0) }
        qs += rev.prefix(4).map { .review($0) }
        queue = qs
        total = qs.count
        i = 0
        prepare()
    }

    /// ことばマス: the words of this place, one by one (hear → meaning → make), then the weak ones again
    private func buildWords() {
        let ws = stage.words.filter { KJData.word($0) != nil }.uniqued()
        var qs: [Q] = []
        qs += ws.shuffled().map { .hearWord($0) }
        qs += ws.shuffled().map { .meaning($0) }
        qs += ws.filter { $0.count <= 6 }.shuffled().prefix(3).map { .word($0) }
        var rev = KJWeak.top(3, in: pool)
        rev += pool.shuffled().filter { !rev.contains($0) }
        qs += rev.prefix(3).map { .review($0) }
        queue = qs
        total = qs.count
        i = 0
        prepare()
    }

    private func prepare() {
        picked = nil; showRight = false; typed = []; strokes = []; traceTries = 0
        guard let q else { return }
        switch q {
        case .listen(let k), .review(let k):
            choices = ([k] + fourDecoys(k)).shuffled()
            later(0.35) { Speaker.shared.say(k) }
        case .read(let k):
            let r = KJData.romaji(k)
            var rs = fourDecoys(k).map { KJData.romaji($0) }.filter { $0 != r && !$0.isEmpty }.uniqued()
            for x in KJData.letters.map(\.romaji).shuffled() where rs.count < 3 && x != r && !rs.contains(x) { rs.append(x) }
            choices = ([r] + rs.prefix(3)).shuffled()
        case .trace(let k):
            glyph = MGGlyph.make(k)
            later(0.3) { Speaker.shared.say(k) }
        case .hearWord(let w):
            choices = ([w] + wordDecoys(w)).shuffled()
            later(0.35) { Speaker.shared.say(w) }
        case .meaning(let w):
            var d = wordDecoys(w).filter { KJData.word($0) != nil }
            for x in KJData.words.map(\.ja).shuffled() where d.count < 3 && x != w && !d.contains(x) { d.append(x) }
            choices = ([w] + d.prefix(3)).shuffled()
            later(0.35) { Speaker.shared.say(w) }
        case .word(let w):
            var keys = w.map(String.init)
            for k in pool.shuffled() where keys.count < 8 && k.count == 1 && !keys.contains(k) { keys.append(k) }
            pad = keys.uniqued().shuffled()
            later(0.35) { Speaker.shared.say(w) }
        }
    }

    /// always three wrong choices (look-alikes first, then anything else the player has met)
    private func fourDecoys(_ k: String) -> [String] {
        var out = mgDecoys(k, (pool + stage.newKana).uniqued()).filter { $0 != k }.uniqued()
        for x in (KJC1.all + KJData.letters.map(\.kana)).uniqued().shuffled() where out.count < 3 && x != k && !out.contains(x) { out.append(x) }
        return Array(out.prefix(3))
    }

    private func choose(_ c: String, answer: String) {
        guard picked == nil, let q else { return }
        picked = c
        if c == answer || AppState.shared.dev.anyRight {
            right(q.key)
        } else {
            AudioManager.shared.se(.studyNG)
            KJWeak.miss(q.key)
            missed.insert(i)
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { mark = false; showRight = true }
            Speaker.shared.say(q.key)
            // once more at the end, until it is right
            if retried[q.key, default: 0] < 2 {
                retried[q.key, default: 0] += 1
                queue.append(q)
            }
            later(1.3) {
                withAnimation { mark = nil }
                advance()
            }
        }
    }

    private func right(_ k: String, counts: Bool = true) {
        picked = picked ?? k
        AudioManager.shared.se(.studyOK)
        if counts { KJWeak.hit(k) }
        if counts && !missed.contains(i) && i < total { firstTry += 1 }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { mark = true; showRight = true }
        later(0.7) {
            withAnimation { mark = nil }
            advance()
        }
    }

    private func advance() {
        if i + 1 >= queue.count {
            guard !done else { return }
            done = true
            let rate = Double(firstTry) / Double(max(total, 1))
            let stars = rate >= 0.9 ? 3 : rate >= 0.7 ? 2 : 1
            AudioManager.shared.se(.studyClear)
            finished(stars, firstTry * 100, stage.newKana.isEmpty ? stage.words : stage.newKana)
            return
        }
        withAnimation(.easeInOut(duration: 0.2)) { i += 1 }
        prepare()
    }
}

extension Array where Element: Hashable {
    /// the same items, each once, in their first order
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
