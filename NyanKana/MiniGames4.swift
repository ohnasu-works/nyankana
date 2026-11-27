import SwiftUI
import UIKit
import Combine

// MARK: - ミニゲーム 第3弾（後半）：めくりカード・たこやき・ゆきがっせん・もじめいろ・やぶさめ・かわらわり

// MARK: - 15. めくりカード: match each letter with its sound

struct MGMekuri: View {
    @ObservedObject var ctx: MGCtx
    let letters: [String]

    struct Card: Identifiable {
        let id = UUID()
        var key: String         // the letter this pair is about
        var isKana: Bool
        var up = false
        var matched = false
        var face: String { isKana ? key : KJData.romaji(key) }
    }
    @State private var cards: [Card] = []
    @State private var first: UUID?
    @State private var lock = false
    @State private var token = 0

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let side = min((w - 60.s) / 4, (h * 0.62) / 4 * 0.78)
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(side), spacing: 10.s), count: 4), spacing: 10.s) {
                ForEach(cards) { c in card(c, side: side) }
            }
            .position(x: w / 2, y: h * 0.6)
        }
        .onChange(of: ctx.round) { _, _ in deal() }
        .onAppear { deal() }
    }

    private func card(_ c: Card, side: CGFloat) -> some View {
        ZStack {
            // back: a red and gold pattern
            RoundedRectangle(cornerRadius: 10.s).fill(Color(hex: 0xC8102E))
                .overlay(
                    ZStack {
                        Circle().stroke(Color(hex: 0xF2C14E), lineWidth: 3).padding(side * 0.18)
                        Circle().fill(Color(hex: 0xF2C14E)).frame(width: side * 0.16)
                    }
                )
                .overlay(RoundedRectangle(cornerRadius: 10.s).stroke(Color.ink, lineWidth: 3))
                .opacity(c.up || c.matched ? 0 : 1)
            // front
            RoundedRectangle(cornerRadius: 10.s).fill(c.matched ? Color(hex: 0xD9F7E3) : Color(hex: 0xFFF6E0))
                .overlay(RoundedRectangle(cornerRadius: 10.s).stroke(c.matched ? Color.mintDeep : Color.ink, lineWidth: 3))
                .overlay(
                    Text(c.face)
                        .font(c.isKana ? Font.custom(Fonts.rounded, size: side * 0.5) : Font.display(side * 0.32)).lineLimit(1).minimumScaleFactor(0.35)
                        .foregroundStyle(Color.ink)
                        .lineLimit(1).minimumScaleFactor(0.5)
                )
                .opacity(c.up || c.matched ? 1 : 0)
        }
        .frame(width: side, height: side * 1.28)
        .rotation3DEffect(.degrees(c.up || c.matched ? 0 : 180), axis: (x: 0, y: 1, z: 0))
        .scaleEffect(c.matched ? 0.94 : 1)
        .animation(.easeInOut(duration: 0.25), value: c.up)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: c.matched)
        .onTapGesture { flip(c) }
    }

    private func deal() {
        token += 1
        first = nil; lock = false
        let keys = Array(Array(Set(letters)).shuffled().prefix(8))
        var cs: [Card] = []
        for k in keys { cs.append(Card(key: k, isKana: true)); cs.append(Card(key: k, isKana: false)) }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { cards = cs.shuffled() }
    }

    private func flip(_ c: Card) {
        guard ctx.running, !lock, !c.up, !c.matched, let i = cards.firstIndex(where: { $0.id == c.id }) else { return }
        AudioManager.shared.se(.mgFlip)
        cards[i].up = true
        Speaker.shared.say(c.key)
        guard let f = first, let j = cards.firstIndex(where: { $0.id == f }) else { first = c.id; return }
        first = nil
        if cards[j].key == c.key {
            cards[i].matched = true; cards[j].matched = true
            AudioManager.shared.se(.kira)
            ctx.good(100, at: CGPoint(x: 0.5, y: 0.35), word: c.key)
            if cards.allSatisfy(\.matched) {
                ctx.score += 300
                ctx.pop("ぜんぶ そろった！", at: CGPoint(x: 0.5, y: 0.3), color: .sunDeep)
                AudioManager.shared.se(.clearShort)
                let my = token
                later(1.2) { if my == token { deal() } }
            }
        } else {
            lock = true
            ctx.lose()
            ctx.misses += 1
            let a = c.id, b = cards[j].id
            later(0.85) {
                for k in cards.indices where cards[k].id == a || cards[k].id == b { cards[k].up = false }
                lock = false
            }
        }
    }
}

// MARK: - 16. たこやき屋台: serve the ordered ball when it is golden

struct MGTakoyaki: View {
    @ObservedObject var ctx: MGCtx
    let letters: [String]

    struct Ball: Identifiable {
        let id = UUID()
        var kana: String
        var cook: Double = 0
        var speed: Double
        var served = false
        var burnt = false
    }
    @State private var balls: [Ball?] = Array(repeating: nil, count: 9)
    @State private var ask: MGAsk?
    @State private var token = 0
    @State private var clock = Timer.publish(every: 1.0 / 30, on: .main, in: .common).autoconnect()

    private let golden = 0.55...0.95

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let cell = min((w - 70.s) / 3, 104.s)
            ZStack {
                HStack(spacing: 10.s) {
                    Image("nk_nyan_joy").resizable().scaledToFit().frame(height: 90.s)
                    VStack(spacing: 2.s) {
                        Text("ちゅうもん！").font(.display(14.s)).foregroundStyle(Color.danger)
                        MGPrompt(ask: ask)
                    }
                }
                .position(x: w * 0.5, y: h * 0.24)
                // the grill
                RoundedRectangle(cornerRadius: 16.s).fill(Color(hex: 0x2B2B2B))
                    .overlay(RoundedRectangle(cornerRadius: 16.s).stroke(Color.ink, lineWidth: 4))
                    .frame(width: cell * 3 + 40.s, height: cell * 3 + 40.s)
                    .position(x: w / 2, y: h * 0.66)
                VStack(spacing: 8.s) {
                    ForEach(0..<3, id: \.self) { r in
                        HStack(spacing: 8.s) {
                            ForEach(0..<3, id: \.self) { c in hole(r * 3 + c, cell: cell) }
                        }
                    }
                }
                .position(x: w / 2, y: h * 0.66)
                // golden guide
                HStack(spacing: 6.s) {
                    swatch(0.3, "なま")
                    swatch(0.75, "きつねいろ！")
                    swatch(1.0, "こげ")
                }
                .position(x: w / 2, y: h * 0.95)
            }
        }
        .onReceive(clock) { _ in step() }
        .onChange(of: ctx.running) { _, on in if on { newAsk() } }
        .onChange(of: ctx.round) { _, _ in reset() }
        .onAppear { reset() }
    }

    private func swatch(_ cook: Double, _ label: String) -> some View {
        HStack(spacing: 3.s) {
            Image("mg_takoyaki").resizable().scaledToFit().frame(height: 20.s)
                .saturation(sat(cook)).brightness(bright(cook))
            Text(label).font(.ui(11.s)).foregroundStyle(.white)
        }
        .padding(.horizontal, 6.s).padding(.vertical, 2.s)
        .background(Capsule().fill(Color.black.opacity(0.45)))
    }

    private func sat(_ c: Double) -> Double { c < 0.55 ? 0.15 + 0.85 * c / 0.55 : 1 }
    private func bright(_ c: Double) -> Double {
        if c < 0.55 { return 0.35 * (1 - c / 0.55) }
        if c > 0.95 { return -min(0.55, (c - 0.95) * 2.2) }
        return 0
    }

    private func hole(_ i: Int, cell: CGFloat) -> some View {
        ZStack {
            Circle().fill(Color.black).overlay(Circle().stroke(Color(hex: 0x555555), lineWidth: 3))
            if let b = balls[i] {
                Image("mg_takoyaki").resizable().scaledToFit().frame(width: cell * 0.86)
                    .saturation(sat(b.cook)).brightness(bright(b.cook))
                    .scaleEffect(b.served ? 1.4 : 1)
                    .offset(y: b.served ? -cell : 0)
                    .opacity(b.served || b.burnt ? 0 : 1)
                    .animation(.easeIn(duration: 0.3), value: b.served)
                    .animation(.easeIn(duration: 0.4), value: b.burnt)
                if b.cook > 0.95 && !b.burnt { KJPicView("💨", size: 25.3.s).offset(x: cell * 0.3, y: -cell * 0.35) }
                // the little flag with the letter
                Text(b.kana).font(.custom(Fonts.rounded, size: cell * 0.26)).foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.35)
                    .padding(.horizontal, 5.s)
                    .background(RoundedRectangle(cornerRadius: 4.s).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 4.s).stroke(Color.ink, lineWidth: 1.5)))
                    .offset(y: -cell * 0.44)
                    .opacity(b.served || b.burnt ? 0 : 1)
            }
        }
        .frame(width: cell, height: cell)
        .contentShape(Rectangle())
        .onTapGesture { serve(i) }
    }

    private func newBall() -> Ball {
        let on = balls.compactMap { $0?.kana }
        let k = letters.filter { !on.contains($0) }.randomElement() ?? letters.randomElement() ?? "あ"
        return Ball(kana: k, cook: Double.random(in: 0...0.25), speed: Double.random(in: 0.08...0.13) * (1 + 0.015 * Double(ctx.hits)))
    }

    private func reset() {
        token += 1
        balls = Array(repeating: nil, count: 9)
        for i in 0..<9 { balls[i] = newBall() }
        ask = nil
    }

    /// order a ball that is close to golden
    private func newAsk() {
        guard ctx.running else { return }
        let live = balls.compactMap { $0 }.filter { !$0.served && !$0.burnt && $0.cook < 0.85 }
        guard let b = live.max(by: { $0.cook < $1.cook }) ?? live.randomElement() else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { ask = MGAsk.pick(b.kana, hits: ctx.hits) }
        mgSpeak(ask)
    }

    private func refill(_ i: Int, after: Double) {
        let my = token
        later(after) {
            guard my == token else { return }
            balls[i] = newBall()
            AudioManager.shared.se(.mgSizzle, volume: 0.35)
        }
    }

    private func step() {
        guard ctx.running else { return }
        for i in balls.indices {
            guard var b = balls[i], !b.served, !b.burnt else { continue }
            b.cook += b.speed / 30
            if b.cook >= 1.25 {
                b.burnt = true
                AudioManager.shared.se(.mgPoof, volume: 0.5)
                if b.kana == ask?.answer {
                    ctx.lose()
                    ctx.misses += 1
                    ctx.pop("こげた！", at: CGPoint(x: 0.5, y: 0.5), color: .ink)
                    later(0.4) { newAsk() }
                }
                refill(i, after: 0.8)
            }
            balls[i] = b
        }
    }

    private func serve(_ i: Int) {
        guard ctx.running, let b = balls[i], !b.served, !b.burnt, let a = ask?.answer else { return }
        if b.kana != a {
            ctx.bad(at: CGPoint(x: 0.5, y: 0.55))
            return
        }
        if b.cook < golden.lowerBound {
            ctx.bad(at: CGPoint(x: 0.5, y: 0.55), shakeIt: false)
            ctx.pop("まだ！", at: CGPoint(x: 0.5, y: 0.48), color: .sky)
            return
        }
        balls[i]?.served = true
        AudioManager.shared.se(.mgClink)
        let perfect = abs(b.cook - 0.75) < 0.12
        ctx.good(perfect ? 160 : 100, at: CGPoint(x: 0.5, y: 0.5), word: a)
        if perfect { ctx.pop("かんぺき！", at: CGPoint(x: 0.5, y: 0.43), color: .sunDeep) }
        refill(i, after: 0.6)
        later(0.35) { newAsk() }
    }
}

// MARK: - 17. ゆきがっせん: throw snowballs only at the kids with the letter

struct MGYuki: View {
    @ObservedObject var ctx: MGCtx
    let letters: [String]

    struct Kid: Identifiable {
        let id = UUID()
        var kana: String
        var up = false
        var hit = false
    }
    struct Shot { var to: Int; var t: Double; var ok: Bool }

    @State private var kids: [Kid?] = Array(repeating: nil, count: 5)
    @State private var ask: MGAsk?
    @State private var shot: Shot?
    @State private var splats: [CGPoint] = []
    @State private var spawnIn: Double = 0.6
    @State private var token = 0
    @State private var clock = Timer.publish(every: 1.0 / 30, on: .main, in: .common).autoconnect()

    private let spots: [CGPoint] = [CGPoint(x: 0.2, y: 0.52), CGPoint(x: 0.5, y: 0.47), CGPoint(x: 0.8, y: 0.52), CGPoint(x: 0.32, y: 0.74), CGPoint(x: 0.68, y: 0.74)]

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                MGPrompt(ask: ask).position(x: w * 0.5, y: h * 0.22)
                ForEach(0..<5, id: \.self) { i in spot(i, w: w, h: h) }
                if let s = shot {
                    let from = CGPoint(x: w * 0.5, y: h * 1.0)
                    let to = CGPoint(x: w * spots[s.to].x, y: h * spots[s.to].y - 60.s)
                    let e = CGFloat(s.t)
                    Circle().fill(Color.white).overlay(Circle().stroke(Color(hex: 0xB8D4E8), lineWidth: 2))
                        .frame(width: 34.s * (1.3 - e * 0.5), height: 34.s * (1.3 - e * 0.5))
                        .position(x: from.x + (to.x - from.x) * e, y: from.y + (to.y - from.y) * e - sin(e * .pi) * 90.s)
                        .allowsHitTesting(false)
                }
                // a snowball in the face
                ForEach(Array(splats.enumerated()), id: \.offset) { _, p in
                    Circle().fill(Color.white.opacity(0.92)).frame(width: 140.s, height: 120.s)
                        .blur(radius: 2)
                        .position(x: w * p.x, y: h * p.y)
                        .transition(.opacity)
                        .allowsHitTesting(false)
                }
            }
        }
        .onReceive(clock) { _ in step() }
        .onChange(of: ctx.running) { _, on in if on { newAsk() } }
        .onChange(of: ctx.round) { _, _ in reset() }
        .onAppear { reset() }
    }

    private func spot(_ i: Int, w: CGFloat, h: CGFloat) -> some View {
        let k = kids[i]
        let kh: CGFloat = 120.s
        return ZStack(alignment: .bottom) {
            if let k {
                ZStack {
                    Image("mg_yukinko").resizable().scaledToFit().frame(height: kh)
                    Text(k.kana).font(.custom(Fonts.rounded, size: 24.s)).foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.35)
                        .offset(x: kh * 0.8 * (0.43 - 0.5), y: kh * (0.63 - 0.5))
                }
                .rotationEffect(.degrees(k.hit ? -70 : 0), anchor: .bottom)
                .offset(y: k.up && !k.hit ? -20.s : kh * 0.9)
                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: k.up)
                .animation(.easeIn(duration: 0.3), value: k.hit)
                .contentShape(Rectangle())
                .onTapGesture { throwAt(i) }
            }
            // the snow wall in front
            Capsule().fill(LinearGradient(colors: [.white, Color(hex: 0xD6E6F2)], startPoint: .top, endPoint: .bottom))
                .overlay(Capsule().stroke(Color(hex: 0x9FB8CC), lineWidth: 2))
                .frame(width: 120.s, height: 46.s)
                .offset(y: 12.s)
        }
        .frame(width: 130.s, height: kh + 30.s)
        .clipShape(Rectangle().offset(y: -10.s))
        .position(x: w * spots[i].x, y: h * spots[i].y - kh / 2)
    }

    private func reset() {
        token += 1
        kids = Array(repeating: nil, count: 5); ask = nil; shot = nil; splats = []; spawnIn = 0.6
    }

    private func newAsk() {
        guard ctx.running, let k = letters.randomElement() else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { ask = MGAsk.pick(k, hits: ctx.hits) }
        mgSpeak(ask)
    }

    private func step() {
        guard ctx.running, let a = ask?.answer else { return }
        if var s = shot {
            s.t = min(1, s.t + 1.0 / 30 / 0.35)
            shot = s
            if s.t >= 1 { land(s) }
        }
        spawnIn -= 1.0 / 30
        guard spawnIn <= 0 else { return }
        spawnIn = max(0.4, 0.9 - 0.025 * Double(ctx.hits)) * Double.random(in: 0.8...1.2)
        let empty = kids.indices.filter { kids[$0] == nil }
        guard let i = empty.randomElement() else { return }
        let showsAnswer = !kids.contains { $0?.kana == a } && Double.random(in: 0...1) < 0.5
        let kid = Kid(kana: showsAnswer ? a : (mgDecoys(a, letters).prefix(4).randomElement() ?? a))
        kids[i] = kid
        later(0.02) { if kids[i]?.id == kid.id { kids[i]?.up = true } }
        let stay = max(1.0, 1.9 - 0.03 * Double(ctx.hits))
        let my = token
        later(stay) {
            guard my == token, kids[i]?.id == kid.id, kids[i]?.hit == false else { return }
            kids[i]?.up = false
            later(0.3) { if kids[i]?.id == kid.id { kids[i] = nil } }
        }
    }

    private func throwAt(_ i: Int) {
        guard ctx.running, shot == nil, let k = kids[i], k.up, !k.hit, let a = ask?.answer else { return }
        AudioManager.shared.se(.mgWhoosh, volume: 0.6)
        shot = Shot(to: i, t: 0, ok: k.kana == a)
    }

    private func land(_ s: Shot) {
        shot = nil
        let i = s.to
        let at = CGPoint(x: spots[i].x, y: spots[i].y - 0.15)
        if s.ok, let k = kids[i] {
            AudioManager.shared.se(.mgPoof)
            kids[i]?.hit = true
            ctx.good(100, at: at, word: k.kana)
            later(0.4) { if kids[i]?.id == k.id { kids[i] = nil } }
            switch mgChain(&ask, ctx: ctx) {
            case .next: break
            case .done: newAsk()
            case .none: if ctx.hits % 3 == 0 { newAsk() }
            }
        } else {
            // the kid throws one back!
            AudioManager.shared.se(.mgPoof, volume: 0.5)
            ctx.bad(at: at)
            later(0.2) {
                AudioManager.shared.se(.boyon, volume: 0.7)
                withAnimation(.easeOut(duration: 0.15)) {
                    splats = (0..<3).map { _ in CGPoint(x: CGFloat.random(in: 0.2...0.8), y: CGFloat.random(in: 0.35...0.8)) }
                }
                later(1.0) { withAnimation(.easeIn(duration: 0.4)) { splats = [] } }
            }
        }
    }
}

// MARK: - 18. もじめいろ: hop to the next letter of the word

struct MGMeiro: View {
    @ObservedObject var ctx: MGCtx
    let letters: [String]

    @State private var grid: [String] = Array(repeating: "", count: 25)
    @State private var pos = 12
    @State private var seq: [String] = []
    @State private var progress = 0
    @State private var visited: Set<Int> = []
    @State private var wrongAt: Int?
    @State private var token = 0

    private let n = 5

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let cell = min((w - 40.s) / CGFloat(n), 72.s)
            ZStack {
                // the word to follow, by sound
                VStack(spacing: 4.s) {
                    if let word = KJData.word(seq.joined()) {
                        KJPic.text("\(word.emoji) \(word.meaning)", size: 15.s).font(.ui(15.s)).foregroundStyle(Color.ink)
                    }
                    HStack(spacing: 6.s) {
                        ForEach(Array(seq.enumerated()), id: \.offset) { i, k in
                            Text(i < progress ? k : KJData.romaji(k))
                                .font(i < progress ? Font.custom(Fonts.rounded, size: 24.s) : Font.display(20.s))
                                .foregroundStyle(i < progress ? Color.white : Color.ink)
                                .frame(minWidth: 46.s, minHeight: 46.s)
                                .background(RoundedRectangle(cornerRadius: 10.s).fill(i < progress ? Color.mintDeep : (i == progress ? Color.sun : Color.white))
                                    .overlay(RoundedRectangle(cornerRadius: 10.s).stroke(Color.ink, lineWidth: 2.5)))
                        }
                    }
                }
                .padding(10.s)
                .background(RoundedRectangle(cornerRadius: 16.s).fill(Color.white.opacity(0.85)))
                .position(x: w / 2, y: h * 0.24)

                VStack(spacing: 4.s) {
                    ForEach(0..<n, id: \.self) { r in
                        HStack(spacing: 4.s) {
                            ForEach(0..<n, id: \.self) { c in tile(r * n + c, cell: cell) }
                        }
                    }
                }
                .position(x: w / 2, y: h * 0.64)
            }
        }
        .onChange(of: ctx.round) { _, _ in pos = 12; build() }
        .onChange(of: ctx.running) { _, on in if on { sayNext() } }
        .onAppear { pos = 12; build() }
    }

    private func tile(_ i: Int, cell: CGFloat) -> some View {
        let here = i == pos
        return ZStack {
            RoundedRectangle(cornerRadius: 10.s)
                .fill(here ? Color.sun : visited.contains(i) ? Color(hex: 0xD9F7E3) : Color(hex: 0xFFF6E0))
                .overlay(RoundedRectangle(cornerRadius: 10.s).stroke(wrongAt == i ? Color.danger : Color.ink, lineWidth: wrongAt == i ? 4 : 2.5))
            if here {
                Image("nk_nyan_joy").resizable().scaledToFit().frame(height: cell * 0.9)
            } else {
                // two-letter sounds (しゅ…) shrink to fit instead of turning into "…"
                Text(grid[i]).font(.custom(Fonts.rounded, size: grid[i].count > 1 ? cell * 0.36 : cell * 0.48)).foregroundStyle(Color.ink)
                    .lineLimit(1).minimumScaleFactor(0.4).padding(.horizontal, 3.s)
            }
        }
        .frame(width: cell, height: cell)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: pos)
        .onTapGesture { hop(i) }
    }

    private func neighbors(_ i: Int) -> [Int] {
        let r = i / n, c = i % n
        var out: [Int] = []
        if r > 0 { out.append(i - n) }
        if r < n - 1 { out.append(i + n) }
        if c > 0 { out.append(i - 1) }
        if c < n - 1 { out.append(i + 1) }
        return out
    }

    /// a word (or a row of the kana table) laid out as a winding path from where Nyan stands
    private func build() {
        token += 1
        let words = MGWords.pick(readable: letters, minLength: 2)
        let rows = [KJC1.A, KJC1.K, KJC1.S, KJC1.T, KJC1.N].filter { $0.allSatisfy { letters.contains($0) } }
        for _ in 0..<30 {
            let s: [String] = (Bool.random() || rows.isEmpty) && !words.isEmpty
                ? (words.randomElement() ?? "あい").map(String.init)
                : (rows.randomElement() ?? KJC1.A)
            // walk a random path of that length
            var path: [Int] = []
            var cur = pos
            var used: Set<Int> = [pos]
            var ok = true
            for _ in s {
                guard let nx = neighbors(cur).filter({ !used.contains($0) }).randomElement() else { ok = false; break }
                path.append(nx); used.insert(nx); cur = nx
            }
            guard ok else { continue }
            var gNew = (0..<(n * n)).map { _ in letters.randomElement() ?? "あ" }
            for (k, cell) in path.enumerated() { gNew[cell] = s[k] }
            // every step has look-alike traps right next to it (so you really have to know the letter),
            // and the right letter never sits beside the path where it isn't meant to be
            let onPath = Set(path).union([pos])
            for (k, cell) in path.enumerated() {
                let prev = k == 0 ? pos : path[k - 1]
                var traps = mgDecoys(s[k], letters).filter { $0 != s[k] }
                for nb in neighbors(prev) where nb != cell && !onPath.contains(nb) {
                    gNew[nb] = traps.isEmpty ? (letters.filter { $0 != s[k] }.randomElement() ?? gNew[nb]) : traps.removeFirst()
                }
                for nb in neighbors(prev) where nb != cell && gNew[nb] == s[k] {
                    gNew[nb] = letters.filter { $0 != s[k] }.randomElement() ?? gNew[nb]
                }
            }
            grid = gNew; seq = s; progress = 0; visited = [pos]
            return
        }
    }

    private func sayNext() {
        if progress < seq.count { Speaker.shared.say(seq[progress]) }
    }

    private func hop(_ i: Int) {
        guard ctx.running, progress < seq.count else { return }
        guard neighbors(pos).contains(i), grid[i] == seq[progress] else {
            wrongAt = i
            later(0.3) { if wrongAt == i { wrongAt = nil } }
            ctx.bad(at: CGPoint(x: 0.5, y: 0.6), shakeIt: false)
            return
        }
        AudioManager.shared.se(.mgPokon, volume: 0.6)
        AudioManager.shared.se(.mgWhoosh, volume: 0.35)
        pos = i
        visited.insert(i)
        progress += 1
        ctx.good(60, at: CGPoint(x: 0.5, y: 0.45))
        if progress == seq.count {
            let w = seq.joined()
            ctx.won.append(w)
            ctx.score += 200
            AudioManager.shared.se(.clearShort)
            Speaker.shared.say(w)
            ctx.pop("ゴール！", at: CGPoint(x: 0.5, y: 0.38), color: .sunDeep)
            let my = token
            later(1.0) { if my == token { build(); sayNext() } }
        } else {
            sayNext()
        }
    }
}

// MARK: - 19. やぶさめ: shoot only the targets with the letter as you gallop past

struct MGYabusame: View {
    @ObservedObject var ctx: MGCtx
    let letters: [String]

    struct Target: Identifiable {
        let id = UUID()
        var kana: String
        var x: CGFloat
        var hit = false
        var passed = false
    }
    @State private var targets: [Target] = []
    @State private var ask: MGAsk?
    @State private var scroll: CGFloat = 0
    @State private var t: Double = 0
    @State private var spawnIn: Double = 0.3
    @State private var gallopIn: Double = 0
    @State private var arrow: (to: CGPoint, id: UUID)?
    @State private var token = 0
    @State private var clock = Timer.publish(every: 1.0 / 30, on: .main, in: .common).autoconnect()

    private let ty: CGFloat = 0.5
    private let riderX: CGFloat = 0.22

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                MGScroller(image: "bg_mg_yabusame", offset: scroll)
                MGPrompt(ask: ask).position(x: w * 0.5, y: h * 0.22)
                ForEach(targets) { tg in
                    ZStack {
                        // the post
                        Rectangle().fill(Color(hex: 0x7A4A21)).frame(width: 8.s, height: h * 0.3).offset(y: h * 0.15)
                        ZStack {
                            Image("mg_target").resizable().scaledToFit().frame(width: 84.s)
                            Text(tg.kana).font(.custom(Fonts.rounded, size: 32.s)).foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.35)
                        }
                        .scaleEffect(tg.hit ? 1.5 : 1)
                        .opacity(tg.hit ? 0 : 1)
                        .animation(.easeOut(duration: 0.25), value: tg.hit)
                        .contentShape(Circle())
                        .onTapGesture { shoot(tg, w: w, h: h) }
                    }
                    .position(x: w * tg.x, y: h * ty)
                }
                if let a = arrow {
                    Path { p in
                        p.move(to: CGPoint(x: w * riderX + 40.s, y: h * 0.74))
                        p.addLine(to: a.to)
                    }
                    .stroke(Color(hex: 0x7A4A21), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .id(a.id)
                    .transition(.opacity)
                    .allowsHitTesting(false)
                }
                Image("nk_nyan_yabusame").resizable().scaledToFit().frame(height: 150.s)
                    .offset(y: CGFloat(abs(sin(t * 7))) * -10.s)
                    .rotationEffect(.degrees(sin(t * 7) * 3))
                    .position(x: w * riderX, y: h * 0.76)
                    .allowsHitTesting(false)
            }
        }
        .onReceive(clock) { _ in step() }
        .onChange(of: ctx.running) { _, on in if on { newAsk() } }
        .onChange(of: ctx.round) { _, _ in reset() }
        .onAppear { reset() }
    }

    private var speed: CGFloat { min(0.42, 0.22 + 0.01 * CGFloat(ctx.hits)) }

    private func reset() {
        token += 1
        targets = []; ask = nil; spawnIn = 0.3; scroll = 0
    }

    private func newAsk() {
        guard ctx.running, let k = letters.randomElement() else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { ask = MGAsk.pick(k, hits: ctx.hits) }
        mgSpeak(ask)
    }

    private func step() {
        t += 1.0 / 30
        guard ctx.running, let a = ask?.answer else { return }
        scroll += speed * 700 / 30
        gallopIn -= 1.0 / 30
        if gallopIn <= 0 { gallopIn = 0.9; AudioManager.shared.se(.mgGallop, volume: 0.3) }
        spawnIn -= 1.0 / 30
        if spawnIn <= 0 {
            spawnIn = max(0.75, 1.3 - 0.02 * Double(ctx.hits))
            let has = targets.contains { $0.kana == a && !$0.hit && !$0.passed }
            let k = !has && Double.random(in: 0...1) < 0.55 ? a : (mgDecoys(a, letters).prefix(4).randomElement() ?? a)
            targets.append(Target(kana: k, x: 1.15))
        }
        for i in targets.indices {
            targets[i].x -= speed / 30
            if !targets[i].hit && !targets[i].passed && targets[i].x < riderX - 0.05 {
                targets[i].passed = true
                if targets[i].kana == a {
                    ctx.lose()
                    ctx.misses += 1
                    ctx.pop("MISS", at: CGPoint(x: riderX, y: ty - 0.1), color: .white)
                    newAsk()
                }
            }
        }
        targets.removeAll { $0.x < -0.2 }
    }

    private func shoot(_ tg: Target, w: CGFloat, h: CGFloat) {
        guard ctx.running, !tg.hit, let a = ask?.answer, let i = targets.firstIndex(where: { $0.id == tg.id }) else { return }
        let to = CGPoint(x: w * tg.x, y: h * ty)
        withAnimation(.easeOut(duration: 0.08)) { arrow = (to, UUID()) }
        let aid = arrow?.id
        later(0.25) { if arrow?.id == aid { withAnimation { arrow = nil } } }
        AudioManager.shared.se(.mgArrow)
        let at = CGPoint(x: tg.x, y: ty - 0.1)
        if tg.kana == a {
            targets[i].hit = true
            AudioManager.shared.se(.mgDon, volume: 0.8)
            ctx.good(100 + Int(max(0, tg.x - riderX) * 100), at: at, word: a)
            switch mgChain(&ask, ctx: ctx) {
            case .next: break
            case .done: newAsk()
            case .none: if ctx.hits % 2 == 0 { newAsk() }
            }
        } else {
            ctx.bad(at: at)
        }
    }
}

// MARK: - 20. かわらわり: bounce the ball, break only the tiles with the letter

struct MGKawara: View {
    @ObservedObject var ctx: MGCtx
    let letters: [String]

    struct Tile: Identifiable {
        let id = UUID()
        var kana: String
        var r: Int, c: Int
        var broken = false
        var ping = false
    }
    @State private var tiles: [Tile] = []
    @State private var ask: MGAsk?
    @State private var ball = CGPoint(x: 0.5, y: 0.8)     // 0...1 of the play area
    @State private var vel = CGVector(dx: 0, dy: 0)
    @State private var resting = true
    @State private var paddle: CGFloat = 0.5
    @State private var size: CGSize = .zero
    @State private var token = 0
    @State private var clock = Timer.publish(every: 1.0 / 60, on: .main, in: .common).autoconnect()

    private let cols = 5, rowsN = 4
    private let top: CGFloat = 0.3, bottom: CGFloat = 0.92
    private let paddleY: CGFloat = 0.88
    private let paddleW: CGFloat = 0.26

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                Color.clear
                    .onAppear { size = g.size }
                    .onChange(of: g.size) { _, v in size = v }
                MGPrompt(ask: ask).position(x: w * 0.5, y: h * 0.17)
                RoundedRectangle(cornerRadius: 8.s).fill(Color.black.opacity(0.3))
                    .frame(width: w - 16.s, height: h * (bottom - top) + 20.s)
                    .position(x: w / 2, y: h * (top + bottom) / 2)
                ForEach(tiles) { t in
                    let r = rect(t, w: w, h: h)
                    Text(t.kana).font(.custom(Fonts.rounded, size: r.height * 0.55)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.35)
                        .frame(width: r.width - 4, height: r.height - 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6.s)
                                .fill(LinearGradient(colors: [Color(hex: 0x5B6573), Color(hex: 0x353C47)], startPoint: .top, endPoint: .bottom))
                                .overlay(RoundedRectangle(cornerRadius: 6.s).stroke(t.ping ? Color.sun : Color.black, lineWidth: t.ping ? 3 : 2))
                        )
                        .scaleEffect(t.broken ? 1.3 : 1)
                        .rotationEffect(.degrees(t.broken ? 25 : 0))
                        .opacity(t.broken ? 0 : 1)
                        .animation(.easeOut(duration: 0.25), value: t.broken)
                        .position(x: r.midX, y: r.midY)
                }
                // paddle and ball
                Capsule().fill(Color.pop).overlay(Capsule().stroke(Color.ink, lineWidth: 3))
                    .frame(width: w * paddleW, height: 18.s)
                    .position(x: w * paddle, y: h * paddleY)
                Circle().fill(Color.white).overlay(Circle().stroke(Color.ink, lineWidth: 2))
                    .frame(width: 22.s, height: 22.s)
                    .position(x: w * ball.x, y: h * ball.y)
                if resting && ctx.running {
                    Text(KJ.both("Tap to launch!", "點一下發射！", "눌러서 발사!")).font(.ui(13.s)).foregroundStyle(.white)
                        .position(x: w / 2, y: h * 0.8)
                }
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { v in paddle = min(1 - paddleW / 2, max(paddleW / 2, v.location.x / w)) }
                .onEnded { _ in if resting { launch() } })
        }
        .onReceive(clock) { _ in step() }
        .onChange(of: ctx.running) { _, on in if on { newAsk() } }
        .onChange(of: ctx.round) { _, _ in reset() }
        .onAppear { reset() }
    }

    private func rect(_ t: Tile, w: CGFloat, h: CGFloat) -> CGRect {
        let tw = (w - 30.s) / CGFloat(cols), th: CGFloat = 46.s
        return CGRect(x: 15.s + CGFloat(t.c) * tw, y: h * top + 14.s + CGFloat(t.r) * (th + 4), width: tw, height: th)
    }

    private func reset() {
        token += 1
        tiles = []
        for r in 0..<rowsN { for c in 0..<cols { tiles.append(Tile(kana: letters.randomElement() ?? "あ", r: r, c: c)) } }
        ask = nil; resting = true; paddle = 0.5
        ball = CGPoint(x: 0.5, y: paddleY - 0.03); vel = .zero
    }

    private func newAsk() {
        guard ctx.running else { return }
        let alive = tiles.filter { !$0.broken }
        if alive.count < 6 {
            // build a fresh wall
            tiles = []
            for r in 0..<rowsN { for c in 0..<cols { tiles.append(Tile(kana: letters.randomElement() ?? "あ", r: r, c: c)) } }
        }
        guard let k = tiles.filter({ !$0.broken }).randomElement()?.kana else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { ask = MGAsk.pick(k, hits: ctx.hits) }
        mgSpeak(ask)
    }

    private func launch() {
        guard ctx.running else { return }
        resting = false
        let sp = 520.s
        vel = CGVector(dx: sp * CGFloat.random(in: -0.4...0.4), dy: -sp)
        AudioManager.shared.se(.mgKa, volume: 0.5)
    }

    private func step() {
        guard ctx.running, size.width > 0 else { return }
        let w = size.width, h = size.height
        if resting {
            ball = CGPoint(x: paddle, y: paddleY - 0.03)
            return
        }
        let dt: CGFloat = 1.0 / 60
        var p = CGPoint(x: ball.x * w + vel.dx * dt, y: ball.y * h + vel.dy * dt)
        let rad: CGFloat = 11.s
        // walls
        if p.x < 8.s + rad { p.x = 8.s + rad; vel.dx = abs(vel.dx); AudioManager.shared.se(.mgKa, volume: 0.25) }
        if p.x > w - 8.s - rad { p.x = w - 8.s - rad; vel.dx = -abs(vel.dx); AudioManager.shared.se(.mgKa, volume: 0.25) }
        if p.y < h * top + rad { p.y = h * top + rad; vel.dy = abs(vel.dy) }
        // paddle
        let py = h * paddleY
        if vel.dy > 0 && p.y + rad >= py - 9.s && p.y < py + 9.s && abs(p.x - w * paddle) < w * paddleW / 2 + rad {
            let off = (p.x - w * paddle) / (w * paddleW / 2)
            let sp = min(760.s, hypot(vel.dx, vel.dy) * 1.02)
            let ang = Double(off) * 1.05
            vel = CGVector(dx: sp * CGFloat(sin(ang)), dy: -sp * CGFloat(cos(ang)))
            p.y = py - 9.s - rad
            AudioManager.shared.se(.mgPokon, volume: 0.4)
        }
        // tiles
        for i in tiles.indices where !tiles[i].broken {
            let r = rect(tiles[i], w: w, h: h).insetBy(dx: -rad, dy: -rad)
            guard r.contains(p) else { continue }
            // bounce off the side we came in from
            let dl = p.x - r.minX, dr = r.maxX - p.x, dtp = p.y - r.minY, db = r.maxY - p.y
            let m = min(dl, dr, dtp, db)
            if m == dl || m == dr { vel.dx = -vel.dx } else { vel.dy = -vel.dy }
            if tiles[i].kana == ask?.answer {
                tiles[i].broken = true
                AudioManager.shared.se(.mgCrack)
                ctx.good(100, at: CGPoint(x: r.midX / w, y: r.midY / h), word: tiles[i].kana)
                if !tiles.contains(where: { !$0.broken && $0.kana == ask?.answer }) { newAsk() }
            } else {
                tiles[i].ping = true
                let id = tiles[i].id
                later(0.15) { if let j = tiles.firstIndex(where: { $0.id == id }) { tiles[j].ping = false } }
                AudioManager.shared.se(.mgKa, volume: 0.5)
            }
            break
        }
        // lost
        if p.y > h * bottom + 30.s {
            ctx.bad(at: CGPoint(x: 0.5, y: 0.8))
            resting = true
            vel = .zero
            p = CGPoint(x: w * paddle, y: h * (paddleY - 0.03))
        }
        ball = CGPoint(x: p.x / w, y: p.y / h)
    }
}
