import SwiftUI
import UIKit
import Combine

// MARK: - ミニゲーム 第2弾：ちょうちんたたき・かいてんずし・しゅりけんにんじゃ
// どれも MiniGameView（MiniGames.swift）の共通の枠の中で動く。

/// what to look for: a sound, a romaji spelling, or a word (picture + meaning)
enum MGAsk: Equatable {
    case sound(String)
    case romaji(String)
    case word(String)
    /// 18. れんさ: the letters of a word, one after another (index = the letter to find now)
    case chain(String, Int)

    var answer: String {
        switch self {
        case .sound(let k), .romaji(let k), .word(let k): k
        case .chain(let w, let i): Self.units(w)[safe: i] ?? ""
        }
    }

    static func units(_ w: String) -> [String] { w.map(String.init) }

    /// words the current game can chain (every letter is one the game uses); set by MiniGameView
    static var chainWords: [String] = []

    /// sound first while the player is new, then a mix — and now and then a whole word to chain
    static func pick(_ k: String, hits: Int) -> MGAsk {
        if hits >= 3, let w = chainWords.randomElement(), Double.random(in: 0...1) < 0.3 { return .chain(w, 0) }
        return hits < 3 || Bool.random() ? .sound(k) : .romaji(k)
    }
}

enum MGChainStep { case next, done, none }

/// after a right answer: move on inside a word chain (bonus when the word is done)
@MainActor func mgChain(_ ask: inout MGAsk?, ctx: MGCtx) -> MGChainStep {
    guard case .chain(let w, let i)? = ask else { return .none }
    if i + 1 < MGAsk.units(w).count {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { ask = .chain(w, i + 1) }
        ctx.pop(KJ.t("Chain \(i + 1)!", "連鎖 \(i + 1)！", "연쇄 \(i + 1)!"), at: CGPoint(x: 0.5, y: 0.36), color: .grape)
        AudioManager.shared.se(.studyCombo, volume: 0.8)
        return .next
    }
    ctx.score += 300
    if !ctx.won.contains(w) { ctx.won.append(w) }
    ctx.pop(KJ.t("Word! +300", "完成詞語！+300", "단어 완성! +300"), at: CGPoint(x: 0.5, y: 0.36), color: .sunDeep)
    AudioManager.shared.se(.clear, volume: 0.7)
    Speaker.shared.say(w)
    return .done
}

/// the question bubble shared by the games
struct MGPrompt: View {
    let ask: MGAsk?
    var body: some View {
        VStack(spacing: 6.s) {
            switch ask {
            case .sound(let k)?:
                Button { Speaker.shared.say(k) } label: {
                    Image(systemName: "speaker.wave.3.fill").font(.system(size: 26.s, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 66.s, height: 66.s)
                        .background(Circle().fill(Color.sky).overlay(Circle().stroke(Color.ink, lineWidth: 3)))
                }
                .buttonStyle(PressStyle(radius: 33.s, depth: 4))
            case .romaji(let k)?:
                Button { Speaker.shared.say(k) } label: {
                    bubble(HStack(spacing: 8.s) {
                        Text(KJData.romaji(k)).font(.display(40.s))
                        Image(systemName: "speaker.wave.2.fill").font(.system(size: 20.s, weight: .bold)).foregroundStyle(Color.sky)
                    })
                }
                .buttonStyle(.plain)
            case .word(let w)?:
                let word = KJData.word(w)
                Button { Speaker.shared.say(w) } label: {
                    bubble(HStack(spacing: 8.s) {
                        KJPicView(word?.emoji ?? "❓", size: 46.s)
                        Text(word?.meaning ?? "").font(.ui(18.s))
                    })
                }
                .buttonStyle(.plain)
            case .chain(let w, let i)?:
                let word = KJData.word(w)
                Button { Speaker.shared.say(w) } label: {
                    VStack(spacing: 4.s) {
                        HStack(spacing: 6.s) {
                            KJPicView(word?.emoji ?? "🔤", size: 32.2.s)
                            Text(word?.meaning ?? "").font(.ui(14.s)).foregroundStyle(Color.ink)
                        }
                        HStack(spacing: 4.s) {
                            ForEach(Array(MGAsk.units(w).enumerated()), id: \.offset) { j, u in
                                Text(j < i ? u : j == i ? KJData.romaji(u) : "・")
                                    .font(j < i ? Font.custom(Fonts.rounded, size: 22.s) : Font.display(18.s))
                                    .foregroundStyle(j < i ? Color.white : Color.ink)
                                    .frame(minWidth: 38.s, minHeight: 38.s)
                                    .background(RoundedRectangle(cornerRadius: 8.s).fill(j < i ? Color.mintDeep : j == i ? Color.sun : Color.white)
                                        .overlay(RoundedRectangle(cornerRadius: 8.s).stroke(Color.ink, lineWidth: 2)))
                            }
                        }
                    }
                    .padding(10.s)
                    .background(RoundedRectangle(cornerRadius: 16.s).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 16.s).stroke(Color.ink, lineWidth: 3)))
                }
                .buttonStyle(.plain)
            case nil:
                EmptyView()
            }
            Text(caption).font(.ui(12.s)).foregroundStyle(Color.ink)
                .padding(.horizontal, 8.s).padding(.vertical, 2.s)
                .background(Capsule().fill(Color.white.opacity(0.85)))
        }
        .id(chainID ?? ask?.answer ?? "")
        .transition(.scale.combined(with: .opacity))
    }

    /// a chain keeps one bubble for the whole word (it only fills in)
    private var chainID: String? {
        if case .chain(let w, _)? = ask { return "chain-" + w }
        return nil
    }

    private var caption: String {
        switch ask {
        case .sound?: KJ.t("Which one?", "哪一個？", "어느 것?")
        case .romaji?: KJ.t("Find this sound!", "找這個音！", "이 소리를 찾아요!")
        case .word?: KJ.t("Find this word!", "找這個詞！", "이 단어를 찾아요!")
        case .chain?: KJ.t("Chain the word, letter by letter!", "照順序連成詞語！", "순서대로 단어를 이어요!")
        case nil: ""
        }
    }

    private func bubble<V: View>(_ v: V) -> some View {
        v.foregroundStyle(Color.ink)
            .padding(.horizontal, 16.s)
            .frame(minWidth: 96.s, minHeight: 66.s)
            .background(RoundedRectangle(cornerRadius: 18.s).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 18.s).stroke(Color.ink, lineWidth: 3)))
    }
}

/// letters that are easy to mix up with `k` (from the ones the player knows)
func mgDecoys(_ k: String, _ letters: [String]) -> [String] {
    var out: [String] = []
    for g in KJData.lookAlike where g.contains(k) {
        for x in g where x != k && letters.contains(x) { out.append(x) }
    }
    return out + letters.filter { $0 != k && !out.contains($0) }.shuffled()
}

// MARK: - 3. ちょうちんたたき: whack only the lantern ghosts with the letter

struct MGChochin: View {
    @ObservedObject var ctx: MGCtx
    let letters: [String]

    struct Mole: Identifiable {
        let id = UUID()
        var kana: String
        var up = false
        var hit = false
        var wrong = false
    }
    @State private var slots: [Mole?] = Array(repeating: nil, count: 9)
    @State private var ask: MGAsk?
    @State private var mallet: (pos: CGPoint, id: UUID)?
    @State private var spawnIn: Double = 0.6
    @State private var pressed: Int?
    @State private var token = 0
    @State private var clock = Timer.publish(every: 1.0 / 30, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let cell = min(w * 0.3, 118.s)
            ZStack {
                MGPrompt(ask: ask).position(x: w * 0.5, y: h * 0.26)
                VStack(spacing: 4.s) {
                    ForEach(0..<3, id: \.self) { r in
                        HStack(spacing: 6.s) {
                            ForEach(0..<3, id: \.self) { c in hole(r * 3 + c, cell: cell) }
                        }
                    }
                }
                .position(x: w * 0.5, y: h * 0.66)
                if let m = mallet {
                    KJPicView("🔨", size: 73.6.s)
                        .rotationEffect(.degrees(-35))
                        .position(m.pos)
                        .id(m.id)
                        .transition(.asymmetric(insertion: .scale(scale: 1.6).combined(with: .opacity), removal: .opacity))
                        .allowsHitTesting(false)
                }
            }
            .coordinateSpace(name: "chochin")
        }
        .onReceive(clock) { _ in step() }
        .onChange(of: ctx.running) { _, on in if on { newAsk() } }
        .onChange(of: ctx.round) { _, _ in reset() }
        .onAppear { reset() }
    }

    private func hole(_ i: Int, cell: CGFloat) -> some View {
        let m = slots[i]
        return ZStack(alignment: .bottom) {
            // the dark hole in the stage
            Ellipse().fill(Color.black.opacity(0.75)).frame(width: cell * 0.86, height: cell * 0.24)
                .offset(y: -cell * 0.02)
            if let m {
                ZStack {
                    Image("mg_chochin").resizable().scaledToFit().frame(height: cell * 0.98)
                    Text(m.kana).font(.custom(Fonts.rounded, size: cell * 0.3)).foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.35)
                        .offset(y: cell * 0.98 * 0.152)
                }
                .scaleEffect(x: m.hit ? 1.25 : 1, y: m.hit ? 0.55 : 1, anchor: .bottom)
                .rotationEffect(.degrees(m.wrong ? 10 : 0))
                .offset(y: m.up && !m.hit ? -cell * 0.08 : cell * 1.05)
                .animation(.spring(response: 0.22, dampingFraction: 0.6), value: m.up)
                .animation(.spring(response: 0.15, dampingFraction: 0.4), value: m.hit)
                .animation(.default.repeatCount(3, autoreverses: true).speed(5), value: m.wrong)
            }
            // the wooden front of the stand hides the ghost while it is down
            RoundedRectangle(cornerRadius: 6.s).fill(LinearGradient(colors: [Color(hex: 0xB9773A), Color(hex: 0x7A4A21)], startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: 6.s).stroke(Color.ink, lineWidth: 2.5))
                .frame(width: cell * 0.96, height: cell * 0.2)
                .offset(y: cell * 0.12)
        }
        .frame(width: cell, height: cell * 1.12)
        .clipShape(Rectangle().offset(y: -cell * 0.05))
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .named("chochin"))
            .onChanged { v in
                guard pressed != i else { return }
                pressed = i
                if m?.up == true && m?.hit == false { whack(i, at: v.startLocation) }
            }
            .onEnded { _ in pressed = nil })
    }

    private func reset() {
        token += 1
        slots = Array(repeating: nil, count: 9)
        ask = nil; mallet = nil; spawnIn = 0.6
    }

    private func newAsk() {
        guard ctx.running, let k = letters.randomElement() else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { ask = MGAsk.pick(k, hits: ctx.hits) }
        if case .sound(let s)? = ask { later(0.2) { Speaker.shared.say(s) } }
    }

    private func step() {
        guard ctx.running, let a = ask?.answer else { return }
        spawnIn -= 1.0 / 30
        guard spawnIn <= 0 else { return }
        spawnIn = max(0.35, 0.85 - 0.025 * Double(ctx.hits)) * Double.random(in: 0.8...1.2)
        let empty = slots.indices.filter { slots[$0] == nil }
        guard let i = empty.randomElement() else { return }
        // the answer shows up often enough; the rest are decoys (look-alikes first)
        let showsAnswer = !slots.contains { $0?.kana == a } && Double.random(in: 0...1) < 0.5
        let k = showsAnswer ? a : (mgDecoys(a, letters).prefix(4).randomElement() ?? a)
        let m = Mole(kana: k)
        slots[i] = m
        later(0.02) { if slots[i]?.id == m.id { slots[i]?.up = true } }
        let stay = max(0.9, 1.7 - 0.03 * Double(ctx.hits))
        let my = token
        later(stay) {
            guard my == token, slots[i]?.id == m.id else { return }
            slots[i]?.up = false
            later(0.3) { if slots[i]?.id == m.id { slots[i] = nil } }
        }
    }

    private func whack(_ i: Int, at p: CGPoint) {
        guard ctx.running, let m = slots[i], m.up, !m.hit, let a = ask?.answer else { return }
        withAnimation(.easeOut(duration: 0.08)) { mallet = (CGPoint(x: p.x + 20.s, y: p.y - 30.s), UUID()) }
        let mid = mallet?.id
        later(0.25) { if mallet?.id == mid { withAnimation { mallet = nil } } }
        if m.kana == a {
            AudioManager.shared.se(.mgPokon)
            later(0.1) { AudioManager.shared.se(.mgPoof, volume: 0.6) }
            slots[i]?.hit = true
            ctx.good(100, at: CGPoint(x: 0.5, y: 0.5), word: a)
            later(0.35) { if slots[i]?.id == m.id { slots[i] = nil } }
            // a new letter every few hits keeps it fresh (a word chain goes on to its next letter)
            switch mgChain(&ask, ctx: ctx) {
            case .next: break
            case .done: newAsk()
            case .none: if ctx.hits % 3 == 0 { newAsk() }
            }
        } else {
            AudioManager.shared.se(.mgPokon, volume: 0.5)
            slots[i]?.wrong.toggle()
            ctx.bad(at: CGPoint(x: 0.5, y: 0.5))
        }
    }
}

// MARK: - 5. かいてんずし: grab the plate the customer ordered

struct MGSushi: View {
    @ObservedObject var ctx: MGCtx
    let letters: [String]

    struct Plate: Identifiable {
        let id = UUID()
        var text: String
        var lane: Int          // 0: top, moving right / 1: bottom, moving left
        var x: Double          // 0...1, wraps around
        var tag: Int
        var taken = false
        var wrong = false
    }
    @State private var plates: [Plate] = []
    @State private var ask: MGAsk?
    @State private var stack = 0
    @State private var belt: Double = 0
    @State private var flying: (text: String, from: CGPoint, t: Double, tag: Int)?
    @State private var size: CGSize = .zero
    @State private var pressed: UUID?
    @State private var token = 0
    @State private var clock = Timer.publish(every: 1.0 / 30, on: .main, in: .common).autoconnect()

    private let tags: [Color] = [.pop, .sky, .mint, .sun, .grape]
    static let netas = ["mg_sushi"] + (1...8).map { "mg_sushi_\($0)" }
    private let laneY: [CGFloat] = [0.5, 0.7]
    private var words: [String] {
        KJData.words.map(\.ja).filter { w in w.allSatisfy { letters.contains(String($0)) } }
    }

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                Color.clear
                    .onAppear { size = g.size }
                    .onChange(of: g.size) { _, v in size = v }
                // the customer and the order
                HStack(spacing: 10.s) {
                    Image("nk_nyan_joy").resizable().scaledToFit().frame(height: 96.s)
                    VStack(spacing: 2.s) {
                        Text(KJ.t("Order!", "點餐！", "주문!")).font(.display(14.s)).foregroundStyle(Color.danger)
                        MGPrompt(ask: ask)
                    }
                }
                .position(x: w * 0.5, y: h * 0.27)

                ForEach(0..<2, id: \.self) { l in beltView(w: w).position(x: w / 2, y: h * laneY[l] + 26.s) }
                ForEach(plates) { p in
                    plateView(p)
                        .position(x: w * CGFloat(p.x), y: h * laneY[p.lane])
                }
                // the stack of plates you ate
                VStack(spacing: -16.s) {
                    ForEach(0..<min(stack, 12), id: \.self) { i in
                        Ellipse().fill(tags[i % tags.count]).frame(width: 64.s, height: 22.s)
                            .overlay(Ellipse().stroke(Color.ink, lineWidth: 2))
                    }
                }
                .rotationEffect(.degrees(180))
                .position(x: w * 0.84, y: h * 0.9 - CGFloat(min(stack, 12)) * 3.s)
                Text("× \(stack)").font(.display(20.s)).foregroundStyle(Color.ink)
                    .padding(.horizontal, 8.s)
                    .background(Capsule().fill(Color.white.opacity(0.9)))
                    .position(x: w * 0.84, y: h * 0.95)
                if let f = flying {
                    let e = CGFloat(f.t)
                    plateView(Plate(text: f.text, lane: 0, x: 0, tag: f.tag))
                        .scaleEffect(1 - e * 0.5)
                        .position(x: f.from.x + (w * 0.84 - f.from.x) * e, y: f.from.y + (h * 0.88 - f.from.y) * e - sin(e * .pi) * 80.s)
                        .allowsHitTesting(false)
                }
            }
        }
        .onReceive(clock) { _ in step() }
        .onChange(of: ctx.running) { _, on in if on { newAsk() } }
        .onChange(of: ctx.round) { _, _ in reset() }
        .onAppear { reset() }
    }

    private func beltView(w: CGFloat) -> some View {
        ZStack {
            Capsule().fill(Color(hex: 0x9AA3AD)).overlay(Capsule().stroke(Color.ink, lineWidth: 2.5))
            // moving slats
            HStack(spacing: 22.s) {
                ForEach(0..<20, id: \.self) { _ in Rectangle().fill(Color.white.opacity(0.35)).frame(width: 3.s) }
            }
            .offset(x: CGFloat(belt.truncatingRemainder(dividingBy: 1)) * 25.s)
            .clipShape(Capsule())
        }
        .frame(width: w + 40, height: 22.s)
    }

    private func plateView(_ p: Plate) -> some View {
        ZStack(alignment: .bottom) {
            // a different topping on each plate (salmon, tuna, egg, shrimp, ikura, kappa maki, octopus, inari, squid)
            Image(Self.netas[p.tag % Self.netas.count]).resizable().scaledToFit().frame(width: 108.s)
            Text(p.text).font(.custom(Fonts.rounded, size: p.text.count > 2 ? 16.s : 22.s)).foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.35)
                .lineLimit(1).minimumScaleFactor(0.6)
                .padding(.horizontal, 7.s).frame(minWidth: 40.s, minHeight: 30.s)
                .background(Capsule().fill(Color.white).overlay(Capsule().stroke(tags[p.tag % tags.count], lineWidth: 4)))
                .offset(y: 10.s)
        }
        .rotationEffect(.degrees(p.wrong ? 8 : 0))
        .animation(.default.repeatCount(3, autoreverses: true).speed(5), value: p.wrong)
        .opacity(p.taken ? 0 : 1)
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in
                guard pressed != p.id else { return }
                pressed = p.id
                grab(p)
            }
            .onEnded { _ in pressed = nil })
    }

    private func reset() {
        token += 1
        stack = 0; ask = nil; flying = nil
        plates = []
        for lane in 0..<2 {
            for i in 0..<4 { plates.append(Plate(text: content(), lane: lane, x: Double(i) / 4 + 0.05, tag: Int.random(in: 0..<40))) }
        }
    }

    /// a letter, or (later on) a word made of letters the player knows
    private func content() -> String {
        if ctx.hits >= 6, !words.isEmpty, Double.random(in: 0...1) < 0.4 { return words.randomElement()! }
        return letters.randomElement() ?? "あ"
    }

    private func newAsk() {
        guard ctx.running else { return }
        let on = plates.filter { !$0.taken && $0.x > 0.05 && $0.x < 0.95 }
        guard let p = on.randomElement() else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            ask = p.text.count > 1 ? .word(p.text) : MGAsk.pick(p.text, hits: ctx.hits)
        }
        switch ask {
        case .sound(let k)?, .word(let k)?: later(0.2) { Speaker.shared.say(k) }
        default: break
        }
    }

    private func step() {
        belt += 1.0 / 30 * 1.5
        guard !plates.isEmpty else { return }
        let speed = min(0.2, 0.09 + 0.004 * Double(ctx.hits))
        for i in plates.indices {
            plates[i].x += (plates[i].lane == 0 ? speed : -speed) / 30
            if plates[i].x > 1.12 || plates[i].x < -0.12 {
                // round the corner and come back with something new (the order stays on the belt)
                plates[i].x = plates[i].lane == 0 ? -0.1 : 1.1
                if plates[i].text != ask?.answer || plates.filter({ $0.text == ask?.answer && !$0.taken }).count > 1 {
                    plates[i].text = content()
                }
                plates[i].taken = false
                plates[i].tag = Int.random(in: 0..<5)
            }
        }
        if var f = flying {
            f.t = min(1, f.t + 1.0 / 30 / 0.5)
            flying = f
            if f.t >= 1 {
                flying = nil
                stack += 1
                AudioManager.shared.se(.mgClink, volume: 0.6)
                if stack % 5 == 0 { ctx.pop(KJ.t("Seconds!", "再來一盤！", "한 접시 더!"), at: CGPoint(x: 0.8, y: 0.75), color: .sunDeep) }
            }
        }
        // make sure the order is still on the belt
        if ctx.running, let a = ask?.answer, !plates.contains(where: { $0.text == a && !$0.taken }) {
            if let i = plates.indices.filter({ plates[$0].x < 0 || plates[$0].x > 1 }).randomElement() ?? plates.indices.randomElement() {
                plates[i].text = a
                plates[i].taken = false
            }
        }
    }

    private func grab(_ p: Plate) {
        guard ctx.running, flying == nil, let i = plates.firstIndex(where: { $0.id == p.id }), !plates[i].taken, let a = ask?.answer else { return }
        let w = size.width, h = size.height
        let from = CGPoint(x: w * CGFloat(p.x), y: h * laneY[p.lane])
        if p.text == a {
            AudioManager.shared.se(.mgClink)
            plates[i].taken = true
            flying = (p.text, from, 0, p.tag)
            ctx.good(p.text.count > 1 ? 150 : 100, at: CGPoint(x: p.x, y: laneY[p.lane] - 0.06), word: p.text)
            let my = token
            later(0.35) { if my == token { newAsk() } }
        } else {
            plates[i].wrong.toggle()
            ctx.bad(at: CGPoint(x: p.x, y: laneY[p.lane] - 0.06))
        }
    }
}

// MARK: - 6. しゅりけんにんじゃ: swipe through the target with the letter

struct MGNinja: View {
    @ObservedObject var ctx: MGCtx
    let letters: [String]

    struct Target: Identifiable {
        let id = UUID()
        var kana: String
        var p: CGPoint          // points
        var v: CGVector         // points per second
        var spin: Double
        var angle: Double = 0
        var wrong = false
    }
    struct Half: Identifiable {
        let id = UUID()
        var kana: String
        var p: CGPoint
        var v: CGVector
        var angle: Double
        var left: Bool
        var cut: Double         // slash angle
    }
    @State private var targets: [Target] = []
    @State private var halves: [Half] = []
    @State private var trail: [(p: CGPoint, t: Double)] = []
    @State private var ask: MGAsk?
    @State private var now: Double = 0
    @State private var nextWave: Double = 0.4
    @State private var waves = 0
    @State private var size: CGSize = .zero
    @State private var nyanJump = false
    @State private var token = 0
    @State private var clock = Timer.publish(every: 1.0 / 30, on: .main, in: .common).autoconnect()

    private let r: CGFloat = 46
    private let gravity: CGFloat = 900

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                Color.clear
                    .onAppear { size = g.size }
                    .onChange(of: g.size) { _, v in size = v }
                MGPrompt(ask: ask).position(x: w * 0.5, y: h * 0.25)

                ForEach(targets) { t in
                    targetView(t.kana)
                        .rotationEffect(.degrees(t.angle))
                        .rotationEffect(.degrees(t.wrong ? 12 : 0))
                        .position(t.p)
                }
                ForEach(halves) { hf in
                    targetView(hf.kana)
                        .mask(
                            Rectangle().frame(width: r.s * 2, height: r.s * 4)
                                .offset(x: hf.left ? -r.s : r.s)
                                .rotationEffect(.degrees(hf.cut))
                        )
                        .rotationEffect(.degrees(hf.angle))
                        .position(hf.p)
                }
                // the blade's trail
                Path { p in
                    let pts = trail.map { $0.p }
                    guard let f = pts.first else { return }
                    p.move(to: f)
                    for q in pts.dropFirst() { p.addLine(to: q) }
                }
                .stroke(LinearGradient(colors: [.white.opacity(0), .white, Color.sky], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 7.s, lineCap: .round, lineJoin: .round))
                .shadow(color: Color.sky, radius: 6)
                .allowsHitTesting(false)

                Image("nk_nyan_ninja").resizable().scaledToFit().frame(height: 120.s)
                    .offset(y: nyanJump ? -24.s : 0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.45), value: nyanJump)
                    .position(x: w * 0.16, y: h * 0.9)
                    .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { v in swipe(to: v.location) }
                .onEnded { _ in trail = [] })
        }
        .onReceive(clock) { _ in step() }
        .onChange(of: ctx.running) { _, on in if on { newAsk() } }
        .onChange(of: ctx.round) { _, _ in reset() }
        .onAppear { reset() }
    }

    private func targetView(_ k: String) -> some View {
        ZStack {
            Image("mg_target").resizable().scaledToFit().frame(width: r.s * 2, height: r.s * 2)
            Text(k).font(.custom(Fonts.rounded, size: r.s * 0.8)).foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.35)
        }
    }

    private func reset() {
        token += 1
        targets = []; halves = []; trail = []; ask = nil; nextWave = 0.4; waves = 0
    }

    private func newAsk() {
        guard ctx.running, let k = letters.randomElement() else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { ask = MGAsk.pick(k, hits: ctx.hits) }
        if case .sound(let s)? = ask { later(0.2) { Speaker.shared.say(s) } }
        nextWave = min(nextWave, 0.3)
    }

    /// toss a few targets up from below; the answer is in most waves
    private func launch() {
        guard size.width > 0, let a = ask?.answer else { return }
        waves += 1
        let n = min(3, 1 + Int.random(in: 0...1) + ctx.hits / 8)
        var ks = Array(mgDecoys(a, letters).prefix(5).shuffled().prefix(n))
        if !targets.contains(where: { $0.kana == a }) && (waves % 2 == 1 || Bool.random()) {
            ks[Int.random(in: 0..<ks.count)] = a
        }
        let w = size.width, h = size.height
        for (i, k) in ks.enumerated() {
            // each target in its own column, flying fairly straight up, peaks at different heights
            let x = w * (0.18 + 0.64 * (CGFloat(i) + 0.5) / CGFloat(ks.count))
            let peak = h * (0.36 + 0.09 * CGFloat(i % 3)) + CGFloat.random(in: -10...10)
            let vy = -sqrt(2 * gravity * (h + r.s - peak))
            let vx = (w * 0.5 - x) * CGFloat.random(in: 0.05...0.15)
            targets.append(Target(kana: k, p: CGPoint(x: x, y: h + r.s), v: CGVector(dx: vx, dy: vy), spin: Double.random(in: -200...200)))
        }
        AudioManager.shared.se(.mgWhoosh, volume: 0.45)
    }

    private func step() {
        let dt: CGFloat = 1.0 / 30
        now += Double(dt)
        trail.removeAll { now - $0.t > 0.18 }
        if ctx.running {
            nextWave -= Double(dt)
            // a new wave only when the sky is nearly clear (no pile of overlapping targets)
            if nextWave <= 0 && targets.count <= 1 {
                launch()
                nextWave = max(0.9, 1.6 - 0.03 * Double(ctx.hits))
            }
        }
        for i in targets.indices {
            targets[i].v.dy += gravity * dt
            targets[i].p.x += targets[i].v.dx * dt
            targets[i].p.y += targets[i].v.dy * dt
            targets[i].angle += targets[i].spin * Double(dt)
        }
        targets.removeAll { $0.p.y > size.height + r.s * 2 && $0.v.dy > 0 }
        for i in halves.indices {
            halves[i].v.dy += gravity * dt
            halves[i].p.x += halves[i].v.dx * dt
            halves[i].p.y += halves[i].v.dy * dt
            halves[i].angle += (halves[i].left ? -240 : 240) * Double(dt)
        }
        halves.removeAll { $0.p.y > size.height + r.s * 3 }
    }

    private func swipe(to p: CGPoint) {
        let last = trail.last?.p
        trail.append((p, now))
        guard ctx.running, let a = last, let ans = ask?.answer else { return }
        guard hypot(p.x - a.x, p.y - a.y) > 4 else { return }
        for t in targets where !t.wrong && distance(t.p, a, p) < r.s {
            guard let i = targets.firstIndex(where: { $0.id == t.id }) else { continue }
            if t.kana == ans {
                slice(i, dir: CGVector(dx: p.x - a.x, dy: p.y - a.y))
            } else {
                targets[i].wrong = true
                targets[i].v.dy = max(targets[i].v.dy, 0) + 200
                AudioManager.shared.se(.mgPokon, volume: 0.6)
                ctx.bad(at: CGPoint(x: t.p.x / max(size.width, 1), y: t.p.y / max(size.height, 1) - 0.05))
            }
        }
    }

    private func slice(_ i: Int, dir: CGVector) {
        let t = targets.remove(at: i)
        let cut = atan2(Double(dir.dy), Double(dir.dx)) * 180 / .pi + 90
        let nx = -dir.dy, ny = dir.dx
        let len = max(hypot(nx, ny), 1)
        let push = CGVector(dx: nx / len * 160, dy: ny / len * 160)
        halves.append(Half(kana: t.kana, p: t.p, v: CGVector(dx: t.v.dx - push.dx, dy: min(t.v.dy, 0) - 150 - push.dy), angle: t.angle, left: true, cut: cut))
        halves.append(Half(kana: t.kana, p: t.p, v: CGVector(dx: t.v.dx + push.dx, dy: min(t.v.dy, 0) - 150 + push.dy), angle: t.angle, left: false, cut: cut))
        AudioManager.shared.se(.mgSlash)
        nyanJump = true
        later(0.2) { nyanJump = false }
        // high up = harder = more points
        let high = Int(max(0, 1 - t.p.y / max(size.height, 1)) * 100)
        ctx.good(100 + high, at: CGPoint(x: t.p.x / max(size.width, 1), y: t.p.y / max(size.height, 1) - 0.05), word: t.kana)
        switch mgChain(&ask, ctx: ctx) {
        case .next: nextWave = min(nextWave, 0.3)
        case .done: newAsk()
        case .none: if ctx.hits % 2 == 0 { newAsk() }
        }
    }

    /// distance from c to the segment a–b
    private func distance(_ c: CGPoint, _ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let ab = CGVector(dx: b.x - a.x, dy: b.y - a.y)
        let l2 = ab.dx * ab.dx + ab.dy * ab.dy
        guard l2 > 0 else { return hypot(c.x - a.x, c.y - a.y) }
        let k = max(0, min(1, ((c.x - a.x) * ab.dx + (c.y - a.y) * ab.dy) / l2))
        return hypot(c.x - (a.x + ab.dx * k), c.y - (a.y + ab.dy * k))
    }
}

// MARK: - あそびば: play any mini-game again, as often as you like

enum KJPlay {
    static func best(_ k: MGKind) -> Int { UserDefaults.standard.integer(forKey: "kj.mg.best.\(k.rawValue)") }
    static func stars(_ k: MGKind) -> Int { UserDefaults.standard.integer(forKey: "kj.mg.stars.\(k.rawValue)") }
    static func record(_ k: MGKind, stars: Int, score: Int) {
        if score > best(k) { UserDefaults.standard.set(score, forKey: "kj.mg.best.\(k.rawValue)") }
        if stars > self.stars(k) { UserDefaults.standard.set(stars, forKey: "kj.mg.stars.\(k.rawValue)") }
    }
    /// a stage made up for free play: every letter of chapter 1
    static func stage(_ k: MGKind) -> KJC1.Stage {
        KJC1.Stage(id: 900, ja: k.title, en: k.sub, zh: k.sub, ko: k.sub, bg: k.bg, kind: .mini, known: KJC1.all, mini: k)
    }
}

struct KJPlayground: View {
    var back: () -> Void
    @State private var playing: MGKind?

    var body: some View {
        ZStack {
            if let k = playing {
                MiniGameView(kind: k, stage: KJPlay.stage(k)) { s, sc, _ in
                    KJPlay.record(k, stars: s, score: sc)
                    withAnimation { playing = nil }
                }
                // quit in the middle of a game
                .overlay(alignment: .topLeading) {
                    BackChip { withAnimation { playing = nil } }.padding(.leading, 14.s).padding(.top, 6.s)
                }
                .transition(.opacity)
            } else {
                list.transition(.opacity)
            }
        }
    }

    private var list: some View {
        ZStack {
            KJBackdrop(bg: "bg_mg_chochin", dim: 0.3)
            VStack(spacing: 10.s) {
                HStack {
                    BackChip { back() }
                    Spacer()
                }
                .padding(.horizontal, 14.s).padding(.top, 6.s)
                RibbonTitle(text: "あそびば", color: .mint, size: 24)
                Text(KJ.t("Play the mini-games again!", "再玩一次小遊戲！", "미니게임을 다시 해요!")).font(.ui(14.s)).foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.6), radius: 2)
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12.s), GridItem(.flexible(), spacing: 12.s)], spacing: 12.s) {
                        ForEach(MGKind.allCases, id: \.self) { k in card(k) }
                    }
                    .padding(.horizontal, 16.s).padding(.bottom, 20.s)
                }
            }
        }
    }

    private func card(_ k: MGKind) -> some View {
        Button {
            AudioManager.shared.se(.decide)
            withAnimation { playing = k }
        } label: {
            VStack(spacing: 4.s) {
                KJPicView(k.icon, size: 46.s)
                Text(k.title).font(.custom(Fonts.rounded, size: 15.s)).foregroundStyle(Color.ink)
                    .lineLimit(1).minimumScaleFactor(0.6)
                Text(k.sub).font(.ui(11.s, bold: false)).foregroundStyle(Color.ink.opacity(0.7)).lineLimit(1).minimumScaleFactor(0.6)
                HStack(spacing: 2.s) {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: i < KJPlay.stars(k) ? "star.fill" : "star")
                            .font(.system(size: 13.s, weight: .bold))
                            .foregroundStyle(i < KJPlay.stars(k) ? Color.sunDeep : Color.ink.opacity(0.25))
                    }
                }
                Text(KJPlay.best(k) > 0 ? "BEST \(KJPlay.best(k))" : " ").font(.display(12.s)).foregroundStyle(Color.ink.opacity(0.7))
            }
            .frame(maxWidth: .infinity).padding(.vertical, 12.s)
            .background(RoundedRectangle(cornerRadius: 18.s).fill(Color.white.opacity(0.94)).overlay(RoundedRectangle(cornerRadius: 18.s).stroke(Color.ink, lineWidth: 3)))
        }
        .buttonStyle(PressStyle(radius: 18.s, depth: 4))
    }
}
