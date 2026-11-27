import SwiftUI
import UIKit
import Combine

// MARK: - ミニゲーム 第3弾（前半）：ダッシュ・たいこ・しんかんせん・つみき・だるまおとし・きんぎょすくい

/// a wide background that scrolls sideways forever (every other copy is mirrored, so the seams never show)
struct MGScroller: View {
    let image: String
    var offset: CGFloat
    var body: some View {
        GeometryReader { g in
            let h = g.size.height
            let w = h * 2048 / 1143
            let o = offset.truncatingRemainder(dividingBy: w * 2)
            ZStack(alignment: .topLeading) {
                ForEach(0..<4, id: \.self) { i in
                    Image(image).resizable().frame(width: w + 1, height: h)
                        .scaleEffect(x: i % 2 == 1 ? -1 : 1, y: 1)
                        .offset(x: CGFloat(i) * w - o)
                }
            }
            .frame(width: g.size.width, height: h, alignment: .topLeading)
            .clipped()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

/// speak the question if it is a sound (or a word)
@MainActor func mgSpeak(_ a: MGAsk?) {
    switch a {
    // romaji too: beginners learn the sound by hearing it while they look for the letter
    case .sound(let k)?, .word(let k)?, .romaji(let k)?: later(0.2) { Speaker.shared.say(k) }
    case .chain(let w, 0)?: later(0.2) { Speaker.shared.say(w) }
    default: break
    }
}

// MARK: - 7. ニャンダッシュ: run through the gate with the letter

struct MGDash: View {
    @ObservedObject var ctx: MGCtx
    let letters: [String]

    struct Row: Identifiable {
        let id = UUID()
        var kanas: [String]     // one per lane
        var x: CGFloat          // 0...1 of the width
        var done = false
    }
    @State private var lane = 1
    @State private var rows: [Row] = []
    @State private var ask: MGAsk?
    @State private var scroll: CGFloat = 0
    @State private var t: Double = 0
    @State private var hop = false
    @State private var dash: Double = 0          // seconds of dash left
    @State private var token = 0
    @State private var clock = Timer.publish(every: 1.0 / 30, on: .main, in: .common).autoconnect()

    private let laneY: [CGFloat] = [0.6, 0.73, 0.86]
    private let nyanX: CGFloat = 0.2

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                MGScroller(image: "bg_mg_dash", offset: scroll)
                // the three lanes
                ForEach(0..<3, id: \.self) { l in
                    Capsule().fill(Color.white.opacity(l == lane ? 0.35 : 0.15))
                        .frame(width: w * 1.1, height: 8.s)
                        .position(x: w / 2, y: h * laneY[l] + 34.s)
                }
                MGPrompt(ask: ask).position(x: w * 0.5, y: h * 0.27)
                ForEach(rows) { r in
                    ForEach(0..<3, id: \.self) { l in
                        ZStack {
                            Image("mg_torii").resizable().scaledToFit().frame(height: 92.s)
                            Text(r.kanas[l]).font(.custom(Fonts.rounded, size: 19.s)).foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.35)
                                .offset(y: 92.s * (0.405 - 0.5))
                        }
                        .opacity(r.done && r.kanas[l] != ask?.answer ? 0.5 : 1)
                        .position(x: w * r.x, y: h * laneY[l] - 6.s)
                    }
                }
                if dash > 0 {
                    // speed lines
                    ForEach(0..<9, id: \.self) { i in
                        Capsule().fill(Color.white.opacity(0.75))
                            .frame(width: CGFloat(60 + (i * 37) % 90).s, height: 4.s)
                            .position(x: w * CGFloat(1.2 - (Double(i) * 0.37 + t * 3).truncatingRemainder(dividingBy: 1.2)) - 40.s,
                                      y: h * (0.5 + CGFloat(i) * 0.05))
                    }
                    .allowsHitTesting(false)
                    Text("DASH!").font(.display(28.s)).foregroundStyle(Color.sun)
                        .shadow(color: .black.opacity(0.6), radius: 0, x: 2, y: 2)
                        .position(x: w * nyanX + 30.s, y: h * laneY[lane] - 80.s)
                }
                Image("nk_nyan_hero").resizable().scaledToFit().frame(height: 96.s)
                    .rotationEffect(.degrees(dash > 0 ? 12 : 0))
                    .offset(y: hop ? -30.s : CGFloat(abs(sin(t * (dash > 0 ? 20 : 12)))) * -6.s)
                    .position(x: w * nyanX, y: h * laneY[lane])
                    .animation(.spring(response: 0.22, dampingFraction: 0.6), value: lane)
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onEnded { v in
                let dy = v.translation.height
                if dy < -30 { move(lane - 1) } else if dy > 30 { move(lane + 1) } else {
                    // a tap: go to the lane nearest the finger
                    let y = v.location.y / h
                    let near = laneY.enumerated().min { abs($0.element - y) < abs($1.element - y) }?.offset ?? lane
                    move(near)
                }
            })
        }
        .onReceive(clock) { _ in step() }
        .onChange(of: ctx.running) { _, on in if on { spawn() } }
        .onChange(of: ctx.round) { _, _ in reset() }
        .onAppear { reset() }
    }

    // speeds up with every hit, but gently (it was harder than the boss)
    private var speed: CGFloat { min(0.42, 0.24 + 0.007 * CGFloat(ctx.hits)) * (dash > 0 ? 1.9 : 1) }

    private func move(_ l: Int) {
        let n = max(0, min(2, l))
        guard n != lane else { return }
        lane = n
        AudioManager.shared.se(.mgWhoosh, volume: 0.4)
    }

    private func reset() {
        token += 1
        rows = []; ask = nil; lane = 1; scroll = 0
    }

    /// a new row of three gates, one of them is the answer
    /// a new row of gates; `keep`: the same question goes on (a word chain, or a miss inside one)
    private func spawn(keep: Bool = false) {
        guard ctx.running else { return }
        if !keep || ask == nil, let k = letters.randomElement() {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { ask = MGAsk.pick(k, hits: ctx.hits) }
            mgSpeak(ask)
        }
        guard let a = ask?.answer, !a.isEmpty else { return }
        var ks = Array(mgDecoys(a, letters).filter { $0 != a }.prefix(4).shuffled().prefix(2)) + [a]
        ks.shuffle()
        rows.append(Row(kanas: ks, x: 1.15))
    }

    private func step() {
        t += 1.0 / 30
        guard ctx.running else { return }
        dash = max(0, dash - 1.0 / 30)
        scroll += speed * 600 / 30
        for i in rows.indices {
            rows[i].x -= speed / 30
            if !rows[i].done && rows[i].x <= nyanX {
                rows[i].done = true
                let ok = rows[i].kanas[lane] == ask?.answer
                if ok {
                    AudioManager.shared.se(.kira)
                    AudioManager.shared.se(.mgWhoosh, volume: 0.7)
                    dash = 1.2 + min(1.5, Double(ctx.combo) * 0.15)   // the longer the combo, the longer the dash
                    hop = true
                    later(0.25) { hop = false }
                    ctx.good(100, at: CGPoint(x: nyanX, y: laneY[lane] - 0.1), word: rows[i].kanas[lane])
                } else {
                    ctx.bad(at: CGPoint(x: nyanX, y: laneY[lane] - 0.1))
                }
                var keep = false
                if ok { keep = mgChain(&ask, ctx: ctx) == .next } else if case .chain? = ask { keep = true }
                let my = token, keepIt = keep
                later(0.5) { if my == token { spawn(keep: keepIt) } }
            }
        }
        rows.removeAll { $0.x < -0.2 }
    }
}

// MARK: - 8. たいこリズム: hit the drum when the note with the letter is in the circle

struct MGTaiko: View {
    @ObservedObject var ctx: MGCtx
    let letters: [String]

    // the song (bgm_mg_taiko): 143.5 BPM, the first beat at 0.09 s — every note lands ON a beat
    private let period = 0.41822
    private let firstBeat = 0.0899

    struct Note: Identifiable {
        let id = UUID()
        var kana: String
        var at: Double          // song clock time when it reaches the circle
        var hit = false
        var passed = false
    }
    struct Burst: Identifiable { let id = UUID(); var text: String; var great: Bool }
    @State private var notes: [Note] = []
    @State private var bursts: [Burst] = []
    @State private var ask: MGAsk?
    @State private var drumHit = false
    @State private var flashOK = false
    @State private var ring = false
    @State private var pulse = false
    @State private var sinceAsk = 0
    @State private var token = 0
    // the song clock: the music's own position, unwrapped across loops (falls back to frame time)
    @State private var now: Double = 0
    @State private var lastBgm: Double?
    @State private var nextBeat = 0
    @State private var lastPulse = -1
    @State private var clock = Timer.publish(every: 1.0 / 60, on: .main, in: .common).autoconnect()

    private let zoneX: CGFloat = 0.22
    private let laneY: CGFloat = 0.5
    /// timing windows (seconds): 良 = right on the beat, 可 = close
    private let great = 0.075, ok = 0.15

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                MGPrompt(ask: ask).position(x: w * 0.5, y: h * 0.24)
                // the lane (it throbs on every beat of the music)
                Capsule().fill(Color.black.opacity(0.55)).frame(width: w * 1.1, height: 84.s)
                    .overlay(Capsule().stroke(Color.sun, lineWidth: pulse ? 5 : 3))
                    .position(x: w / 2, y: h * laneY)
                Circle().stroke(flashOK ? Color.sun : Color.white, lineWidth: 5)
                    .frame(width: 74.s, height: 74.s)
                    .scaleEffect(flashOK ? 1.3 : pulse ? 1.08 : 1)
                    .shadow(color: flashOK ? Color.sun : .clear, radius: 14)
                    .position(x: w * zoneX, y: h * laneY)
                // the shock ring of a good hit
                Circle().stroke(Color.sun, lineWidth: ring ? 2 : 10)
                    .frame(width: 74.s, height: 74.s)
                    .scaleEffect(ring ? 2.6 : 0.8).opacity(ring ? 0 : 0.9)
                    .position(x: w * zoneX, y: h * laneY)
                    .allowsHitTesting(false)
                ForEach(notes) { n in
                    Text(n.kana).font(.custom(Fonts.rounded, size: 30.s)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.35)
                        .frame(width: 62.s, height: 62.s)
                        .background(Circle().fill(Color.sky).overlay(Circle().stroke(Color.white, lineWidth: 4)))
                        .scaleEffect(n.hit ? 2.0 : 1)
                        .opacity(n.hit ? 0 : 1)
                        .animation(.easeOut(duration: 0.22), value: n.hit)
                        .position(x: w * x(of: n), y: h * laneY - (n.hit ? 40.s : 0))
                }
                // 良 / 可 and the combo, big, right over the circle
                ForEach(bursts) { b in
                    VStack(spacing: 0) {
                        OutlinedText(b.text, font: .custom(Fonts.rounded, size: b.great ? 46.s : 34.s), fill: b.great ? .sun : .sky, width: 4, shadow: 0)
                        if ctx.combo >= 2 {
                            OutlinedText("\(ctx.combo) コンボ", font: .display(18.s), fill: .white, width: 3, shadow: 0)
                        }
                    }
                    .position(x: w * zoneX + 60.s, y: h * laneY - 80.s)
                    .transition(.scale(scale: 0.4).combined(with: .opacity))
                    .allowsHitTesting(false)
                }
                // the drum: tap anywhere on it
                ZStack {
                    Image("mg_taiko").resizable().scaledToFit().frame(height: 230.s)
                    Text("ドン！").font(.custom(Fonts.rounded, size: 26.s)).foregroundStyle(Color.danger)
                        .offset(x: 230.s * 0.685 * (0.30 - 0.5), y: 230.s * (0.35 - 0.5))
                        .opacity(drumHit ? 1 : 0.35)
                }
                .scaleEffect(drumHit ? 0.9 : pulse ? 1.02 : 1)
                .animation(.spring(response: 0.12, dampingFraction: 0.4), value: drumHit)
                .position(x: w * 0.5, y: h * 0.78)
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0).onChanged { _ in if !drumHit { hitDrum() } }.onEnded { _ in drumHit = false })
            }
        }
        .onReceive(clock) { _ in step() }
        .onChange(of: ctx.running) { _, on in if on { newAsk() } }
        .onChange(of: ctx.round) { _, _ in reset() }
        .onAppear { reset() }
    }

    /// seconds a note takes from the right edge to the circle (a little shorter as you get better)
    private var lead: Double { max(1.35, 2.0 - 0.025 * Double(ctx.hits)) }
    private func x(of n: Note) -> CGFloat { zoneX + CGFloat((n.at - now) / lead) * (1.12 - zoneX) }

    private func reset() {
        token += 1
        notes = []; bursts = []; ask = nil; sinceAsk = 0; lastBgm = nil; nextBeat = 0; lastPulse = -1
    }

    private func newAsk() {
        guard ctx.running, let k = letters.randomElement() else { return }
        sinceAsk = 0
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { ask = MGAsk.pick(k, hits: ctx.hits) }
        mgSpeak(ask)
    }

    /// advance the song clock from the music itself
    private func tickClock() {
        if let t = AudioManager.shared.bgmTime {
            if let l = lastBgm {
                var d = t - l
                if d < -1, let len = AudioManager.shared.bgmLength { d += len }   // the track looped
                now += max(0, min(d, 0.25))
            } else {
                now = t
                nextBeat = Int(((t - firstBeat) / period).rounded(.up)) + 1
            }
            lastBgm = t
        } else {
            now += 1.0 / 60
        }
    }

    private func step() {
        tickClock()
        // the beat: the lane and the drum throb with the music
        let b = Int(((now - firstBeat) / period).rounded(.down))
        if b != lastPulse {
            lastPulse = b
            pulse = true
            later(0.09) { pulse = false }
        }
        guard ctx.running, let a = ask?.answer else { return }
        // put notes on the beats ahead: every other beat, and on every beat once you are in the groove
        let every = ctx.combo >= 10 ? 1 : 2
        while firstBeat + Double(nextBeat) * period < now + lead {
            if nextBeat % every == 0 {
                let k = Double.random(in: 0...1) < 0.42 ? a : (mgDecoys(a, letters).prefix(4).randomElement() ?? a)
                notes.append(Note(kana: k, at: firstBeat + Double(nextBeat) * period))
            }
            nextBeat += 1
        }
        for i in notes.indices where !notes[i].hit && !notes[i].passed && now - notes[i].at > ok {
            notes[i].passed = true
            if notes[i].kana == a {
                // a missed beat: the combo breaks (no shake)
                ctx.lose()
                ctx.misses += 1
                ctx.pop("MISS", at: CGPoint(x: zoneX, y: laneY - 0.08), color: .white)
            }
        }
        notes.removeAll { now - $0.at > lead * 0.3 || ($0.hit && now - $0.at > 0.4) }
    }

    private func hitDrum() {
        drumHit = true
        guard ctx.running, let a = ask?.answer else { AudioManager.shared.se(.mgDon); return }
        // the note closest to the circle in time
        let near = notes.enumerated().filter { !$0.element.hit && abs($0.element.at - now) < ok }
            .min { abs($0.element.at - now) < abs($1.element.at - now) }
        if let nr = near, nr.element.kana == a {
            let i = nr.offset, n = nr.element
            let perfect = abs(n.at - now) < great
            AudioManager.shared.se(.mgDon)
            if perfect { AudioManager.shared.se(.kira, volume: 0.5) }
            UIImpactFeedbackGenerator(style: perfect ? .heavy : .medium).impactOccurred()
            notes[i].hit = true
            ctx.good(perfect ? 150 : 100, at: CGPoint(x: zoneX, y: laneY - 0.09), word: a)
            // a big 良 / 可, a shock ring and a flash: hitting on the beat should feel great
            let burst = Burst(text: perfect ? "良" : "可", great: perfect)
            withAnimation(.spring(response: 0.18, dampingFraction: 0.45)) { bursts = [burst] }
            later(0.45) { withAnimation(.easeOut(duration: 0.15)) { bursts.removeAll { $0.id == burst.id } } }
            flashOK = true
            later(0.12) { flashOK = false }
            ring = false
            withAnimation(.easeOut(duration: 0.35)) { ring = true }
            later(0.36) { ring = false }
            if ctx.combo > 0 && ctx.combo % 10 == 0 {
                ctx.pop("\(ctx.combo) コンボ！", at: CGPoint(x: 0.5, y: 0.36), color: .sunDeep)
            }
            sinceAsk += 1
            switch mgChain(&ask, ctx: ctx) {
            case .next: break
            case .done: newAsk()
            case .none: if sinceAsk >= 5 { newAsk() }
            }
        } else if near != nil {
            // a wrong letter on the beat
            AudioManager.shared.se(.mgKa)
            ctx.bad(at: CGPoint(x: zoneX, y: laneY - 0.09), shakeIt: true)
        } else {
            // nothing at the circle: just a drum sound (keeps the rhythm, no penalty)
            AudioManager.shared.se(.mgKa, volume: 0.6)
        }
    }
}

// MARK: - 9. しんかんせんレース: answer fast, race the rival train to Osaka

struct MGTrain: View {
    @ObservedObject var ctx: MGCtx
    let letters: [String]

    @State private var me: Double = 0
    @State private var rival: Double = 0
    @State private var boost: Double = 0
    @State private var ask: MGAsk?
    @State private var choices: [String] = []
    @State private var wrongPick: String?
    @State private var scroll: CGFloat = 0
    @State private var shakeMe = false
    @State private var ended = false
    @State private var token = 0
    @State private var clock = Timer.publish(every: 1.0 / 30, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                MGScroller(image: "bg_mg_shinkansen", offset: scroll)
                // the race: Tokyo → Osaka
                VStack(spacing: 6.s) {
                    track("じぶん", me, tint: 0, w: w)
                    track("ライバル", rival, tint: 150, w: w)
                }
                .position(x: w / 2, y: h * 0.27)
                .offset(x: shakeMe ? 6 : 0)
                .animation(.default.repeatCount(3, autoreverses: true).speed(5), value: shakeMe)

                MGPrompt(ask: ask).position(x: w * 0.5, y: h * 0.5)
                // four answers
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12.s), GridItem(.flexible(), spacing: 12.s)], spacing: 12.s) {
                    ForEach(choices, id: \.self) { c in
                        Button { pick(c) } label: {
                            Text(c).font(.custom(Fonts.rounded, size: 38.s)).foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.35)
                                .frame(maxWidth: .infinity).frame(height: 74.s)
                                .background(RoundedRectangle(cornerRadius: 16.s).fill(wrongPick == c ? Color(hex: 0xFFC9C9) : Color.white)
                                    .overlay(RoundedRectangle(cornerRadius: 16.s).stroke(Color.ink, lineWidth: 3)))
                        }
                        .buttonStyle(PressStyle(radius: 16.s, depth: 4))
                    }
                }
                .padding(.horizontal, 26.s)
                .position(x: w / 2, y: h * 0.78)
            }
        }
        .onReceive(clock) { _ in step() }
        .onChange(of: ctx.running) { _, on in if on { newAsk() } }
        .onChange(of: ctx.round) { _, _ in reset() }
        .onAppear { reset() }
    }

    private func track(_ name: String, _ p: Double, tint: Double, w: CGFloat) -> some View {
        let len = w - 120.s
        return HStack(spacing: 6.s) {
            Text(name).font(.ui(11.s)).foregroundStyle(Color.ink).frame(width: 44.s)
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.85)).frame(height: 8.s).overlay(Capsule().stroke(Color.ink, lineWidth: 1.5))
                Image("mg_train").resizable().scaledToFit().frame(height: 34.s)
                    .hueRotation(.degrees(tint))
                    .offset(x: CGFloat(p) * (len - 80.s))
            }
            .frame(width: len)
            KJPicView("🏯", size: 23.s)
        }
    }

    private func reset() {
        token += 1
        me = 0; rival = 0; boost = 0; ask = nil; choices = []; ended = false; scroll = 0
    }

    private func newAsk() {
        guard ctx.running, let k = letters.randomElement() else { return }
        wrongPick = nil
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            ask = MGAsk.pick(k, hits: ctx.hits)
            choices = ([k] + Array(mgDecoys(k, letters).prefix(3))).shuffled()
        }
        mgSpeak(ask)
    }

    private func step() {
        guard ctx.running, !ended else { return }
        // the rival keeps a steady pace (it would arrive a little before the clock runs out)
        rival = min(1, rival + 1.0 / 30 / max(20, ctx.total * 0.85))
        if boost > 0 {
            let d = min(boost, 0.012)
            me = min(1, me + d)
            boost -= d
        }
        scroll += CGFloat(8 + boost * 900)
        if me >= 1 {
            ended = true
            AudioManager.shared.se(.mgHorn)
            ctx.score += 500 + Int(ctx.timeLeft) * 20
            ctx.pop("かち！", at: CGPoint(x: 0.5, y: 0.4), color: .sunDeep)
            later(1.0) { ctx.finish() }
        } else if rival >= 1 {
            ended = true
            AudioManager.shared.se(.mgHorn, volume: 0.6)
            ctx.pop("まけ…", at: CGPoint(x: 0.5, y: 0.4), color: .sky)
            later(1.0) { ctx.finish() }
        }
    }

    private func pick(_ c: String) {
        guard ctx.running, !ended, let a = ask?.answer else { return }
        if c == a {
            AudioManager.shared.se(.mgWhoosh, volume: 0.6)
            boost += 0.06 + (ctx.fever ? 0.03 : 0)
            ctx.good(100, at: CGPoint(x: 0.5, y: 0.66), word: a)
            newAsk()
        } else {
            wrongPick = c
            shakeMe.toggle()
            me = max(0, me - 0.02)
            ctx.bad(at: CGPoint(x: 0.5, y: 0.66))
        }
    }
}

// MARK: - 12. もじつみき: tap the blocks with the letter before the pile reaches the top

struct MGTsumiki: View {
    @ObservedObject var ctx: MGCtx
    let letters: [String]

    struct Block: Identifiable, Equatable {
        let id = UUID()
        var kana: String
        var wrong = false
    }
    @State private var cols: [[Block]] = Array(repeating: [], count: 5)
    @State private var ask: MGAsk?
    @State private var dropIn: Double = 0.5
    @State private var danger = false
    @State private var token = 0
    @State private var clock = Timer.publish(every: 1.0 / 30, on: .main, in: .common).autoconnect()

    private let rows = 7

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let cell = min((w - 40.s) / 5, (h * 0.58) / CGFloat(rows))
            ZStack {
                MGPrompt(ask: ask).position(x: w * 0.5, y: h * 0.22)
                // the box
                RoundedRectangle(cornerRadius: 10.s)
                    .fill(Color.black.opacity(0.35))
                    .overlay(RoundedRectangle(cornerRadius: 10.s).stroke(danger ? Color.danger : Color.white, lineWidth: 3))
                    .frame(width: cell * 5 + 12.s, height: cell * CGFloat(rows) + 12.s)
                    .position(x: w / 2, y: h * 0.36 + cell * CGFloat(rows) / 2)
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(0..<5, id: \.self) { c in
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            ForEach(cols[c].reversed()) { b in block(b, col: c, cell: cell) }
                        }
                        .frame(width: cell, height: cell * CGFloat(rows))
                    }
                }
                .position(x: w / 2, y: h * 0.36 + cell * CGFloat(rows) / 2)
            }
        }
        .onReceive(clock) { _ in step() }
        .onChange(of: ctx.running) { _, on in if on { newAsk() } }
        .onChange(of: ctx.round) { _, _ in reset() }
        .onAppear { reset() }
    }

    private func block(_ b: Block, col: Int, cell: CGFloat) -> some View {
        Text(b.kana).font(.custom(Fonts.rounded, size: cell * 0.5)).foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.35)
            .frame(width: cell - 4, height: cell - 4)
            .background(RoundedRectangle(cornerRadius: 6.s)
                .fill(LinearGradient(colors: [Color(hex: 0xF3D19C), Color(hex: 0xD9A35E)], startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: 6.s).stroke(Color(hex: 0x7A4A21), lineWidth: 2.5)))
            .frame(width: cell, height: cell)
            .rotationEffect(.degrees(b.wrong ? 8 : 0))
            .animation(.default.repeatCount(3, autoreverses: true).speed(5), value: b.wrong)
            .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .scale(scale: 1.6).combined(with: .opacity)))
            .contentShape(Rectangle())
            .onTapGesture { tap(b, col: col) }
    }

    private func reset() {
        token += 1
        cols = Array(repeating: [], count: 5); ask = nil; dropIn = 0.5; danger = false
        // start with two rows already there
        for c in 0..<5 {
            for _ in 0..<2 { cols[c].append(Block(kana: letters.randomElement() ?? "あ")) }
        }
    }

    private func newAsk() {
        guard ctx.running else { return }
        // ask for a letter that is on the board when there is one
        let on = cols.flatMap { $0 }.map(\.kana)
        guard let k = on.randomElement() ?? letters.randomElement() else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { ask = MGAsk.pick(k, hits: ctx.hits) }
        mgSpeak(ask)
    }

    private func drop() {
        let open = (0..<5).filter { cols[$0].count < rows }
        guard let c = open.randomElement() else { gameOver(); return }
        let a = ask?.answer
        let k = (a != nil && Double.random(in: 0...1) < 0.35) ? a! : (letters.randomElement() ?? "あ")
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { cols[c].append(Block(kana: k)) }
        AudioManager.shared.se(.mgPokon, volume: 0.35)
        danger = cols.contains { $0.count >= rows - 1 }
        if cols[c].count >= rows && (0..<5).allSatisfy({ cols[$0].count >= rows }) { gameOver() }
    }

    private func gameOver() {
        guard ctx.running else { return }
        ctx.pop("いっぱい！", at: CGPoint(x: 0.5, y: 0.5), color: .danger)
        ctx.finish()
    }

    private func step() {
        guard ctx.running else { return }
        dropIn -= 1.0 / 30
        if dropIn <= 0 {
            dropIn = max(0.55, 1.4 - 0.03 * Double(ctx.hits))
            drop()
        }
    }

    private func tap(_ b: Block, col: Int) {
        guard ctx.running, let a = ask?.answer, let i = cols[col].firstIndex(where: { $0.id == b.id }) else { return }
        if b.kana == a {
            AudioManager.shared.se(.mgPoof, volume: 0.7)
            AudioManager.shared.se(.kira, volume: 0.5)
            _ = withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { cols[col].remove(at: i) }
            ctx.good(100, at: CGPoint(x: 0.5, y: 0.5), word: a)
            danger = cols.contains { $0.count >= rows - 1 }
            // all of them gone: a bonus and a new letter
            if !cols.flatMap({ $0 }).contains(where: { $0.kana == a }) {
                ctx.score += 150
                ctx.pop("ぜんぶ クリア！", at: CGPoint(x: 0.5, y: 0.42), color: .sunDeep)
                newAsk()
            }
        } else {
            cols[col][i].wrong.toggle()
            ctx.bad(at: CGPoint(x: 0.5, y: 0.5))
            drop()   // a wrong tap drops one more block
        }
    }
}

// MARK: - 13. だるまおとし: knock out the block with the letter

struct MGDaruma: View {
    @ObservedObject var ctx: MGCtx
    let letters: [String]

    struct Piece: Identifiable {
        let id = UUID()
        var kana: String
        var color: Color
        var out = false
        var fromLeft = true
    }
    @State private var pieces: [Piece] = []      // index 0 = top
    @State private var ask: MGAsk?
    @State private var wobble = false
    @State private var fall = false
    @State private var strikes = 0
    @State private var hammerAt: CGPoint?
    @State private var token = 0

    private let colors: [Color] = [Color(hex: 0x3B82F6), Color(hex: 0x22C55E), Color(hex: 0xF59E0B), Color(hex: 0xA855F7), Color(hex: 0xEF4444), Color(hex: 0x14B8A6)]

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let pw = min(w * 0.62, 260.s), ph = 54.s
            ZStack {
                MGPrompt(ask: ask).position(x: w * 0.5, y: h * 0.21)
                VStack(spacing: 0) {
                    Image("mg_daruma").resizable().scaledToFit().frame(height: 150.s).offset(y: 8.s)
                    ForEach(pieces) { p in
                        Text(p.kana).font(.custom(Fonts.rounded, size: 30.s)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.35)
                            .shadow(color: .black.opacity(0.5), radius: 0, x: 1, y: 1)
                            .frame(width: pw, height: ph)
                            .background(Capsule().fill(p.color).overlay(Capsule().stroke(Color.ink, lineWidth: 3)))
                            .offset(x: p.out ? (p.fromLeft ? w : -w) : 0)
                            .rotationEffect(.degrees(p.out ? (p.fromLeft ? 20 : -20) : 0))
                            .animation(.easeIn(duration: 0.28), value: p.out)
                            .contentShape(Rectangle())
                            .onTapGesture { strike(p, at: CGPoint(x: w * 0.5, y: 0)) }
                    }
                }
                .rotationEffect(.degrees(fall ? 75 : (wobble ? 4 : 0)), anchor: .bottom)
                .animation(fall ? .easeIn(duration: 0.5) : .default.repeatCount(4, autoreverses: true).speed(4), value: wobble)
                .animation(.easeIn(duration: 0.5), value: fall)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: pieces.map(\.id))
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, h * 0.06)
                // the stand
                RoundedRectangle(cornerRadius: 4.s).fill(Color(hex: 0x7A4A21)).frame(width: pw + 60.s, height: 14.s)
                    .position(x: w / 2, y: h * 0.94 + 8.s)
                if let p = hammerAt {
                    KJPicView("🔨", size: 69.s).position(p).transition(.scale.combined(with: .opacity)).allowsHitTesting(false)
                }
                // strikes left before the daruma falls
                HStack(spacing: 4.s) {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: i < strikes ? "xmark.circle.fill" : "circle")
                            .foregroundStyle(i < strikes ? Color.danger : Color.white)
                            .font(.system(size: 18.s, weight: .bold))
                    }
                }
                .position(x: w * 0.85, y: h * 0.33)
            }
        }
        .onChange(of: ctx.running) { _, on in if on { newAsk() } }
        .onChange(of: ctx.round) { _, _ in reset() }
        .onAppear { reset() }
    }

    private func newPiece() -> Piece {
        Piece(kana: letters.randomElement() ?? "あ", color: colors.randomElement() ?? .blue)
    }

    private func reset() {
        token += 1
        pieces = (0..<5).map { _ in newPiece() }
        // every letter different
        var seen = Set<String>()
        for i in pieces.indices {
            if seen.contains(pieces[i].kana) { pieces[i].kana = letters.filter { !seen.contains($0) }.randomElement() ?? pieces[i].kana }
            seen.insert(pieces[i].kana)
        }
        ask = nil; strikes = 0; fall = false
    }

    private func newAsk() {
        guard ctx.running, let k = pieces.filter({ !$0.out }).randomElement()?.kana else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { ask = MGAsk.pick(k, hits: ctx.hits) }
        mgSpeak(ask)
    }

    private func strike(_ p: Piece, at: CGPoint) {
        guard ctx.running, !fall, !p.out, let a = ask?.answer, let i = pieces.firstIndex(where: { $0.id == p.id }) else { return }
        if p.kana == a {
            pieces[i].fromLeft = Bool.random()
            pieces[i].out = true
            AudioManager.shared.se(.mgSlap, volume: 0.8)
            AudioManager.shared.se(.mgPokon)
            ctx.good(i == pieces.count - 1 ? 150 : 100, at: CGPoint(x: 0.5, y: 0.6), word: a)
            strikes = 0
            let id = p.id
            later(0.3) {
                pieces.removeAll { $0.id == id }
                // a new block slides in at the bottom, different from the others
                var n = newPiece()
                let on = pieces.map(\.kana)
                n.kana = letters.filter { !on.contains($0) }.randomElement() ?? n.kana
                pieces.append(n)
                newAsk()
            }
        } else {
            strikes += 1
            wobble.toggle()
            ctx.bad(at: CGPoint(x: 0.5, y: 0.6))
            if strikes >= 3 {
                // the daruma topples over: start a new one
                fall = true
                AudioManager.shared.se(.boyon)
                ctx.pop("たおれた！", at: CGPoint(x: 0.5, y: 0.45), color: .danger)
                let my = token
                later(1.1) {
                    guard my == token else { return }
                    reset()
                    newAsk()
                }
            }
        }
    }
}

// MARK: - 14. きんぎょすくい: scoop the goldfish with the letter (wrong ones tear the paper)

struct MGKingyo: View {
    @ObservedObject var ctx: MGCtx
    let letters: [String]

    struct Fish: Identifiable {
        let id = UUID()
        var kana: String
        var p: CGPoint          // 0...1
        var heading: Double     // radians
        var speed: Double
        var caught: Double?     // 0...1 while flying to the bowl
    }
    @State private var fish: [Fish] = []
    @State private var ask: MGAsk?
    @State private var poi = 3
    @State private var ripple: (p: CGPoint, id: UUID)?
    @State private var bowl = 0
    @State private var token = 0
    @State private var clock = Timer.publish(every: 1.0 / 30, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                ForEach(fish) { f in
                    let pos = position(f, w, h)
                    ZStack {
                        Image("mg_kingyo").resizable().scaledToFit().frame(height: 96.s)
                            .rotationEffect(.radians(f.heading + .pi / 2))
                        Text(f.kana).font(.custom(Fonts.rounded, size: 24.s)).foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.35)
                            .padding(4.s).background(Circle().fill(Color.white.opacity(0.85)))
                    }
                    .scaleEffect(f.caught != nil ? 1 - CGFloat(f.caught!) * 0.6 : 1)
                    .frame(width: 110.s, height: 110.s)
                    .contentShape(Circle())
                    .onTapGesture { scoop(f, at: pos, size: g.size) }
                    .position(pos)
                }
                if let r = ripple {
                    Circle().stroke(Color.white, lineWidth: 4).frame(width: 90.s, height: 90.s)
                        .position(r.p).id(r.id)
                        .transition(.asymmetric(insertion: .scale(scale: 0.3).combined(with: .opacity), removal: .scale(scale: 1.6).combined(with: .opacity)))
                        .allowsHitTesting(false)
                }
                MGPrompt(ask: ask).position(x: w * 0.5, y: h * 0.22)
                // the paper scoop (poi) and the bowl
                HStack(spacing: 4.s) {
                    ForEach(0..<3, id: \.self) { i in
                        ZStack {
                            Circle().fill(i < poi ? Color.white : Color.white.opacity(0.25))
                            Circle().stroke(Color(hex: 0xE05050), lineWidth: 4)
                        }
                        .frame(width: 26.s, height: 26.s)
                    }
                }
                .padding(6.s).background(Capsule().fill(Color.black.opacity(0.35)))
                .position(x: w * 0.2, y: h * 0.93)
                HStack(spacing: 4.s) {
                    KJPicView("🥣", size: 32.2.s)
                    Text("× \(bowl)").font(.display(20.s)).foregroundStyle(Color.ink)
                }
                .padding(.horizontal, 8.s).background(Capsule().fill(Color.white.opacity(0.9)))
                .position(x: w * 0.82, y: h * 0.93)
            }
        }
        .onReceive(clock) { _ in step() }
        .onChange(of: ctx.running) { _, on in if on { newAsk() } }
        .onChange(of: ctx.round) { _, _ in reset() }
        .onAppear { reset() }
    }

    private func position(_ f: Fish, _ w: CGFloat, _ h: CGFloat) -> CGPoint {
        if let c = f.caught {
            let e = CGFloat(c)
            let from = CGPoint(x: w * f.p.x, y: h * f.p.y)
            return CGPoint(x: from.x + (w * 0.82 - from.x) * e, y: from.y + (h * 0.92 - from.y) * e - sin(e * .pi) * 60.s)
        }
        return CGPoint(x: w * f.p.x, y: h * f.p.y)
    }

    private func newFish() -> Fish {
        let on = fish.map(\.kana)
        let k = letters.filter { !on.contains($0) }.randomElement() ?? letters.randomElement() ?? "あ"
        return Fish(kana: k, p: CGPoint(x: CGFloat.random(in: 0.15...0.85), y: CGFloat.random(in: 0.38...0.85)),
                    heading: Double.random(in: 0...(2 * .pi)), speed: Double.random(in: 0.05...0.1))
    }

    private func reset() {
        token += 1
        fish = []
        for _ in 0..<7 { fish.append(newFish()) }
        ask = nil; poi = 3; bowl = 0
    }

    private func newAsk() {
        guard ctx.running, let k = fish.filter({ $0.caught == nil }).randomElement()?.kana else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { ask = MGAsk.pick(k, hits: ctx.hits) }
        mgSpeak(ask)
    }

    private func step() {
        let dt = 1.0 / 30
        for i in fish.indices {
            if let c = fish[i].caught {
                fish[i].caught = min(1, c + dt / 0.6)
                continue
            }
            // wander: turn a little, bounce off the rim
            fish[i].heading += Double.random(in: -0.25...0.25)
            let sp = fish[i].speed * (1 + 0.02 * Double(ctx.hits))
            var x = Double(fish[i].p.x) + cos(fish[i].heading) * sp * dt
            var y = Double(fish[i].p.y) + sin(fish[i].heading) * sp * dt * 0.6
            if x < 0.1 || x > 0.9 { fish[i].heading = .pi - fish[i].heading; x = min(0.9, max(0.1, x)) }
            if y < 0.36 || y > 0.86 { fish[i].heading = -fish[i].heading; y = min(0.86, max(0.36, y)) }
            fish[i].p = CGPoint(x: x, y: y)
        }
        // landed in the bowl: a new fish swims in
        for i in fish.indices where (fish[i].caught ?? 0) >= 1 {
            fish[i] = newFish()
            bowl += 1
            AudioManager.shared.se(.kira, volume: 0.5)
        }
    }

    private func scoop(_ f: Fish, at p: CGPoint, size: CGSize) {
        guard ctx.running, f.caught == nil, let a = ask?.answer, let i = fish.firstIndex(where: { $0.id == f.id }) else { return }
        withAnimation(.easeOut(duration: 0.3)) { ripple = (p, UUID()) }
        let rid = ripple?.id
        later(0.35) { if ripple?.id == rid { withAnimation { ripple = nil } } }
        let at = CGPoint(x: p.x / size.width, y: p.y / size.height - 0.06)
        if f.kana == a {
            AudioManager.shared.se(.mgSplash, volume: 0.8)
            fish[i].caught = 0
            ctx.good(100, at: at, word: a)
            let my = token
            later(0.4) { if my == token { newAsk() } }
        } else {
            AudioManager.shared.se(.mgBloop)
            fish[i].heading += .pi
            fish[i].speed = min(0.25, fish[i].speed * 2)
            ctx.bad(at: at, shakeIt: false)
            poi -= 1
            if poi <= 0 {
                // the paper tore: a new scoop
                AudioManager.shared.se(.sad, volume: 0.6)
                ctx.pop("やぶれた！", at: CGPoint(x: 0.2, y: 0.85), color: .danger)
                ctx.score = max(0, ctx.score - 100)
                later(0.6) { poi = 3 }
            }
        }
    }
}
