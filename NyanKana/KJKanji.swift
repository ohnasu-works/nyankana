import SwiftUI

// MARK: - かんじ（N5・N4 の 漢字）：読み・意味・書き順・その漢字を使う ことば
// 書き順の線は KanjiVG (Ulrich Apel, CC BY-SA 3.0)、読みは KANJIDIC2 (EDRDG, CC BY-SA 4.0)

struct KJKanji: Identifiable, Hashable {
    var k: String
    var lv: Int
    var strokes: Int
    var on: [String]
    var kun: [String]
    var m: [String]
    var paths: [String]
    var id: String { k }
    var meaning: String { KJ.t(m[0], m[1], m[2]) }

    static let byChar: [String: KJKanji] = Dictionary(all.map { ($0.k, $0) }, uniquingKeysWith: { a, _ in a })

    /// words in the dictionary that use this kanji (shortest first)
    var words: [KJData.Word] {
        var seen = Set<String>()
        return KJData.words.filter { $0.ja.contains(k) && seen.insert($0.ja).inserted }
            .sorted { ($0.ja.count, $0.ja) < ($1.ja.count, $1.ja) }
    }

    static var seen: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: "kj.kanji.seen") ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: "kj.kanji.seen") }
    }
}

/// KanjiVG path data (M C S c s) → a SwiftUI path in a 109 × 109 box
enum KJStroke {
    static func path(_ d: String) -> Path {
        var p = Path()
        var nums: [CGFloat] = []
        var cmd: Character = "M"
        var cur = CGPoint.zero, start = CGPoint.zero, lastCtl: CGPoint?
        func run() {
            var i = 0
            func take(_ n: Int) -> [CGFloat]? { guard i + n <= nums.count else { return nil }; defer { i += n }; return Array(nums[i..<(i + n)]) }
            while i < nums.count || (nums.isEmpty && i == 0) {
                if nums.isEmpty { break }
                switch cmd {
                case "M", "m":
                    guard let v = take(2) else { return }
                    cur = cmd == "M" ? CGPoint(x: v[0], y: v[1]) : CGPoint(x: cur.x + v[0], y: cur.y + v[1])
                    start = cur; p.move(to: cur); lastCtl = nil
                    cmd = cmd == "M" ? "L" : "l"
                case "L", "l":
                    guard let v = take(2) else { return }
                    cur = cmd == "L" ? CGPoint(x: v[0], y: v[1]) : CGPoint(x: cur.x + v[0], y: cur.y + v[1])
                    p.addLine(to: cur); lastCtl = nil
                case "C", "c":
                    guard let v = take(6) else { return }
                    let o = cmd == "c" ? cur : .zero
                    let c1 = CGPoint(x: o.x + v[0], y: o.y + v[1]), c2 = CGPoint(x: o.x + v[2], y: o.y + v[3]), e = CGPoint(x: o.x + v[4], y: o.y + v[5])
                    p.addCurve(to: e, control1: c1, control2: c2); lastCtl = c2; cur = e
                case "S", "s":
                    guard let v = take(4) else { return }
                    let o = cmd == "s" ? cur : .zero
                    let c1 = lastCtl.map { CGPoint(x: 2 * cur.x - $0.x, y: 2 * cur.y - $0.y) } ?? cur
                    let c2 = CGPoint(x: o.x + v[0], y: o.y + v[1]), e = CGPoint(x: o.x + v[2], y: o.y + v[3])
                    p.addCurve(to: e, control1: c1, control2: c2); lastCtl = c2; cur = e
                default:
                    return
                }
            }
        }
        var num = ""
        func pushNum() { if let v = Double(num) { nums.append(CGFloat(v)) }; num = "" }
        for ch in d {
            if ch.isLetter {
                pushNum(); run(); nums = []
                cmd = ch
                if ch == "Z" || ch == "z" { p.closeSubpath(); cur = start }
            } else if ch == "-" {
                pushNum(); num = "-"
            } else if ch == "," || ch == " " {
                pushNum()
            } else if ch == "." && num.contains(".") {
                pushNum(); num = "."
            } else {
                num.append(ch)
            }
        }
        pushNum(); run()
        return p
    }
}

/// the strokes drawn one after another
struct KJStrokeView: View {
    let kanji: KJKanji
    var size: CGFloat
    @State private var shown: Double = 0
    @State private var run = 0

    var body: some View {
        let paths = kanji.paths.map(KJStroke.path)
        ZStack {
            // guide lines
            Path { p in p.move(to: CGPoint(x: size / 2, y: 0)); p.addLine(to: CGPoint(x: size / 2, y: size)); p.move(to: CGPoint(x: 0, y: size / 2)); p.addLine(to: CGPoint(x: size, y: size / 2)) }
                .stroke(Color.ink.opacity(0.12), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
            ForEach(0..<paths.count, id: \.self) { i in
                paths[i].stroke(Color.ink.opacity(0.1), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                paths[i].trimmedPath(from: 0, to: max(0, min(1, shown - Double(i))))
                    .stroke(i == Int(shown) ? Color.popDeep : Color.ink, style: StrokeStyle(lineWidth: 4.5, lineCap: .round, lineJoin: .round))
            }
            .scaleEffect(size / 109, anchor: .topLeading)
            .frame(width: size, height: size, alignment: .topLeading)
            // stroke numbers
            ForEach(0..<paths.count, id: \.self) { i in
                if let s = startPoint(kanji.paths[i]), shown >= Double(i) {
                    Text("\(i + 1)").font(.ui(10.s)).foregroundStyle(Color.grape)
                        .position(x: s.x * size / 109 - 6, y: s.y * size / 109 - 6)
                }
            }
        }
        .frame(width: size, height: size)
        .contentShape(Rectangle())
        .onTapGesture { play() }
        .onAppear { play() }
    }

    private func startPoint(_ d: String) -> CGPoint? {
        var pt: CGPoint?
        KJStroke.path(d).cgPath.applyWithBlock { e in
            if pt == nil, e.pointee.type == .moveToPoint { pt = e.pointee.points[0] }
        }
        return pt
    }

    func play() {
        run += 1
        let my = run
        shown = 0
        let n = kanji.paths.count
        for i in 0..<n {
            later(0.15 + Double(i) * 0.55) {
                guard my == run else { return }
                withAnimation(.easeInOut(duration: 0.45)) { shown = Double(i + 1) }
            }
        }
    }
}

/// the kanji list: N5 / N4, five in a row
struct KJKanjiList: View {
    @State private var lv = 5
    @State private var open: KJKanji?
    @State private var seen = KJKanji.seen

    var body: some View {
        VStack(spacing: 8.s) {
            HStack(spacing: 8.s) {
                ForEach([5, 4], id: \.self) { l in
                    Button { AudioManager.shared.se(.tap); lv = l } label: {
                        Text("N\(l)").font(.display(15.s)).foregroundStyle(lv == l ? .white : Color.ink)
                            .padding(.horizontal, 16.s).padding(.vertical, 5.s)
                            .background(Capsule().fill(lv == l ? Color.grape : Color.white).overlay(Capsule().stroke(Color.ink, lineWidth: 2)))
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                let list = KJKanji.all.filter { $0.lv == lv }
                Text("\(list.filter { seen.contains($0.k) }.count) / \(list.count)").font(.display(14.s)).foregroundStyle(.white)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6.s), count: 5), spacing: 6.s) {
                ForEach(KJKanji.all.filter { $0.lv == lv }) { k in
                    Button {
                        AudioManager.shared.se(.tap)
                        KJKanji.seen.insert(k.k); seen = KJKanji.seen
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { open = k }
                    } label: {
                        VStack(spacing: 0) {
                            Text(k.k).font(.custom(Fonts.rounded, size: 26.s)).foregroundStyle(Color.ink)
                            Text(k.meaning).font(.ui(9.s, bold: false)).foregroundStyle(Color.ink.opacity(0.6)).lineLimit(1).minimumScaleFactor(0.5)
                        }
                        .frame(maxWidth: .infinity).frame(height: 56.s)
                        .background(RoundedRectangle(cornerRadius: 10.s).fill(seen.contains(k.k) ? Color(hex: 0xFFF6D8) : Color.white.opacity(0.93))
                            .overlay(RoundedRectangle(cornerRadius: 10.s).stroke(Color.ink, lineWidth: 2)))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheet(item: $open) { k in KJKanjiSheet(k: k).presentationDetents([.large]) }
    }
}

/// one kanji: stroke order, readings, meaning, and the words that use it
struct KJKanjiSheet: View {
    let k: KJKanji
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {
            VStack(spacing: 14.s) {
                HStack {
                    Text("N\(k.lv)").font(.display(13.s)).foregroundStyle(.white)
                        .padding(.horizontal, 8.s).padding(.vertical, 2.s).background(Capsule().fill(Color.grape))
                    Text(KJ.jt("\(k.strokes)かく", "\(k.strokes) strokes", "\(k.strokes)畫", "\(k.strokes)획")).font(.ui(13.s)).foregroundStyle(Color.ink.opacity(0.7))
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.system(size: 16.s, weight: .black)).foregroundStyle(Color.ink)
                            .frame(width: 36.s, height: 36.s).background(Circle().fill(Color.white).overlay(Circle().stroke(Color.ink, lineWidth: 2)))
                    }
                }
                HStack(alignment: .top, spacing: 16.s) {
                    VStack(spacing: 4.s) {
                        KJStrokeView(kanji: k, size: 150.s)
                            .background(RoundedRectangle(cornerRadius: 12.s).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 12.s).stroke(Color.ink, lineWidth: 2)))
                        Text(KJ.jt("おすと もういちど", "Tap to replay", "點一下重播", "누르면 다시")).font(.ui(10.s, bold: false)).foregroundStyle(Color.ink.opacity(0.5))
                    }
                    VStack(alignment: .leading, spacing: 8.s) {
                        Text(k.meaning).font(.ui(17.s)).foregroundStyle(Color.popDeep).fixedSize(horizontal: false, vertical: true)
                        reading(KJ.jt("おんよみ", "On (Chinese) reading", "音讀", "음독"), k.on)
                        reading(KJ.jt("くんよみ", "Kun (Japanese) reading", "訓讀", "훈독"), k.kun)
                    }
                    Spacer(minLength: 0)
                }
                let ws = k.words
                if !ws.isEmpty {
                    VStack(alignment: .leading, spacing: 6.s) {
                        Text(KJ.jt("この かんじを つかう ことば", "Words with this kanji", "用這個漢字的詞", "이 한자를 쓰는 단어")).font(.ui(13.s)).foregroundStyle(Color.ink.opacity(0.7))
                        ForEach(ws.prefix(20), id: \.ja) { w in
                            Button { Speaker.shared.say(w.ja) } label: {
                                HStack(spacing: 10.s) {
                                    KJPicView(w.emoji, size: 30.s)
                                    KJFuri(w.ja, size: 19.s, force: true)
                                    Text(w.meaning).font(.ui(12.s, bold: false)).foregroundStyle(Color.ink.opacity(0.7)).lineLimit(2)
                                    Spacer(minLength: 0)
                                    Image(systemName: "speaker.wave.2.fill").font(.system(size: 13.s, weight: .bold)).foregroundStyle(Color.grape)
                                }
                                .padding(.horizontal, 10.s).padding(.vertical, 6.s)
                                .background(RoundedRectangle(cornerRadius: 10.s).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 10.s).stroke(Color.ink.opacity(0.3), lineWidth: 1.5)))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(18.s)
        }
        .background(Color(hex: 0xFFFBF2).ignoresSafeArea())
    }

    private func reading(_ title: String, _ r: [String]) -> some View {
        VStack(alignment: .leading, spacing: 2.s) {
            Text(title).font(.ui(11.s, bold: false)).foregroundStyle(Color.ink.opacity(0.6))
            Text(r.isEmpty ? "—" : r.joined(separator: "・")).font(.custom(Fonts.rounded, size: 17.s)).foregroundStyle(Color.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
