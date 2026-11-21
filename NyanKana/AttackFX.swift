import SwiftUI

/// How an enemy attacks when its meter runs out. Each has its own motion, sound and screen effect.
enum AttackKind: CaseIterable {
    case bite, lick, stomp, spit, spin, roar

    /// seconds from the start of the motion to the hit
    var impact: Double {
        switch self {
        case .bite: 0.42
        case .lick: 0.5
        case .stomp: 0.75
        case .spit: 0.62
        case .spin: 0.55
        case .roar: 0.6
        }
    }

    /// what Nyan shouts when it hits
    var shout: String {
        switch self {
        case .bite: T("かまれた！", "물렸다!", "被咬了！")
        case .lick: T("なめられた！|ベトベト…", "핥아졌다! 끈적끈적…", "被舔了！黏黏的…")
        case .stomp: T("ふみつぶされた！", "짓밟혔다!", "被踩扁了！")
        case .spit: T("ネバネバを|はかれた！", "끈적이를 뱉었다!", "被吐黏液了！")
        case .spin: T("体当たり！", "몸통 박치기!", "被撞飛了！")
        case .roar: T("大声で|ことばが|ふっとんだ！", "큰 소리에 말이 날아갔다!", "大吼把語言吹飛了！")
        }
    }

    static func pick(big: Bool) -> AttackKind {
        big ? [.stomp, .roar, .spin, .bite].randomElement()! : allCases.randomElement()!
    }
}

/// A thrown thing (bomb, knife, rock...) flying at the screen during the quick quiz.
/// flying: grows as the timer runs out / hit: fills the screen with a bang / deflected: spins away and drops.
struct MissileView: View {
    let missile: GameModel.Missile
    let progress: Double
    @State private var start = Date()

    var body: some View {
        TimelineView(.animation) { ctx in
            scene(t: tNow(ctx.date))
        }
        .allowsHitTesting(false)
        .onAppear { start = Date() }
    }

    private func tNow(_ d: Date) -> CGFloat {
        let dur = missile.state == .hit ? 0.35 : 0.85
        guard missile.state != .flying else { return 0 }
        return CGFloat(min(1, max(0, d.timeIntervalSince(start) / dur)))
    }

    private func scene(t: CGFloat) -> some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let p = CGFloat(max(0, missile.state == .deflected ? missile.at : missile.state == .hit ? 1 : progress))
            let size = w * (0.09 + 0.33 * p)
            let x = w * CGFloat(missile.fromX + (0.5 - missile.fromX) * Double(p))
            let y = h * (0.36 + 0.16 * p)
            let turn = missile.spin ? Double(p) * 900 : sin(Double(p) * 24) * 10
            ZStack {
                switch missile.state {
                case .flying:
                    // a soft shadow under it tells you it is coming closer
                    Ellipse().fill(Color.black.opacity(0.18)).frame(width: size * 0.8, height: size * 0.18)
                        .position(x: x, y: min(h * 0.92, y + size * 0.75))
                    Image(missile.image).resizable().scaledToFit().frame(width: size)
                        .rotationEffect(.degrees(turn))
                        .position(x: x, y: y)
                case .hit:
                    Image(missile.image).resizable().scaledToFit().frame(width: size * (1 + 1.8 * t))
                        .rotationEffect(.degrees(turn))
                        .opacity(Double(1 - t * 0.8))
                        .position(x: w * 0.5, y: h * 0.52)
                    ForEach(0..<12, id: \.self) { i in
                        Capsule().fill(i % 2 == 0 ? Color.sun : Color.white)
                            .overlay(Capsule().stroke(Color.ink, lineWidth: 2))
                            .frame(width: 14, height: h * 0.2 * t)
                            .offset(y: -h * 0.22 * t)
                            .rotationEffect(.degrees(Double(i) * 30))
                            .position(x: w * 0.5, y: h * 0.52)
                    }
                    OutlinedText("BANG!", font: .en(54), fill: .sun).scaleEffect(0.5 + t * 0.7).opacity(Double(t)).position(x: w * 0.5, y: h * 0.5)
                case .deflected:
                    // knocked up and away, then it falls to the ground
                    let dir: CGFloat = missile.fromX < 0.5 ? -1 : 1
                    Image(missile.image).resizable().scaledToFit().frame(width: size * (1 - 0.25 * t))
                        .rotationEffect(.degrees(turn + Double(t) * 600 * Double(dir)))
                        .position(x: x + dir * w * 0.3 * t, y: y - h * 0.22 * t + h * 0.85 * t * t)
                        .opacity(Double(1 - max(0, t - 0.75) * 4))
                    if t < 0.5 {
                        Image(systemName: "sparkle").font(.system(size: 60, weight: .black)).foregroundStyle(Color.sun)
                            .scaleEffect(0.6 + t * 1.6).opacity(Double(1 - t * 2)).position(x: x, y: y)
                    }
                }
            }
            .frame(width: w, height: h)
        }
    }
}

/// Full-screen hit effect drawn over the street.
struct HitOverlay: View {
    let kind: AttackKind
    @State private var t: CGFloat = 0

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                switch kind {
                case .bite:
                    // two rows of teeth closing
                    TeethRow().fill(Color.white).overlay(TeethRow().stroke(Color.ink, lineWidth: 3))
                        .frame(height: h * 0.22).offset(y: -h * 0.39 + t * h * 0.16)
                    TeethRow().fill(Color.white).overlay(TeethRow().stroke(Color.ink, lineWidth: 3))
                        .rotationEffect(.degrees(180)).frame(height: h * 0.22).offset(y: h * 0.39 - t * h * 0.16)
                case .lick, .spit:
                    // slime splats
                    ForEach(0..<7, id: \.self) { i in
                        let x = CGFloat([0.18, 0.72, 0.45, 0.85, 0.3, 0.6, 0.1][i]) * w
                        let y = CGFloat([0.25, 0.2, 0.5, 0.62, 0.75, 0.38, 0.55][i]) * h
                        Splat(seed: i).fill(kind == .lick ? Color(hex: 0xFF8FC0).opacity(0.85) : Color(hex: 0x9BE36B).opacity(0.85))
                            .overlay(Splat(seed: i).stroke(Color.ink.opacity(0.6), lineWidth: 2))
                            .frame(width: (70 + CGFloat(i % 3) * 30) * (0.4 + t * 0.6), height: (70 + CGFloat(i % 3) * 30) * (0.4 + t * 0.6))
                            .position(x: x, y: y + t * 12)
                    }
                case .stomp:
                    // big footprint + cracks
                    Image(systemName: "pawprint.fill").font(.system(size: 220)).foregroundStyle(Color.ink.opacity(0.75))
                        .scaleEffect(1.6 - t * 0.6).opacity(Double(t))
                    ForEach(0..<6, id: \.self) { i in
                        Rectangle().fill(Color.ink).frame(width: 4, height: h * 0.35 * t)
                            .rotationEffect(.degrees(Double(i) * 60 + 15)).offset(y: 0)
                    }
                case .spin:
                    // claw scratches
                    ForEach(0..<3, id: \.self) { i in
                        Capsule().fill(Color.danger).frame(width: 12, height: h * 0.7 * t)
                            .rotationEffect(.degrees(28)).offset(x: CGFloat(i - 1) * 46)
                    }
                    ForEach(0..<6, id: \.self) { i in
                        Image(systemName: "star.fill").font(.system(size: 30)).foregroundStyle(Color.sun)
                            .offset(x: cos(Double(i) + Double(t) * 4) * 120, y: sin(Double(i) + Double(t) * 4) * 70 - 60)
                    }
                case .roar:
                    // shock-wave rings
                    ForEach(0..<4, id: \.self) { i in
                        Circle().stroke(Color.white.opacity(0.8 - Double(i) * 0.15), lineWidth: 10)
                            .frame(width: (CGFloat(i) * 120 + 80) * (0.5 + t), height: (CGFloat(i) * 120 + 80) * (0.5 + t))
                    }
                    OutlinedText("!!!", font: .en(70), fill: .sun).scaleEffect(0.6 + t * 0.6)
                }
            }
            .frame(width: w, height: h)
        }
        .allowsHitTesting(false)
        .onAppear { withAnimation(.spring(response: 0.25, dampingFraction: 0.55)) { t = 1 } }
    }
}

private struct TeethRow: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
        let n = 8
        for i in (0..<n).reversed() {
            let x0 = r.minX + r.width * CGFloat(i + 1) / CGFloat(n), x1 = r.minX + r.width * CGFloat(i) / CGFloat(n)
            p.addLine(to: CGPoint(x: (x0 + x1) / 2, y: r.maxY))
            p.addLine(to: CGPoint(x: x1, y: r.midY))
        }
        p.closeSubpath()
        return p
    }
}

private struct Splat: Shape {
    let seed: Int
    func path(in r: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: r.midX, y: r.midY), R = min(r.width, r.height) / 2
        let n = 14
        for i in 0...n {
            let a = Double(i) / Double(n) * 2 * .pi
            let k = 0.55 + 0.45 * abs(sin(Double(seed * 7 + i * 3) * 1.7))
            let pt = CGPoint(x: c.x + cos(a) * R * k, y: c.y + sin(a) * R * k)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

// MARK: - Pop background used by the menu / study screens (same look as the title screen)

struct PopBackdrop: View {
    var base: Color
    /// fewer decorations (lists and long texts)
    var calm = false

    var body: some View {
        ZStack {
            base
            Sunburst(a: .clear, b: Color.white.opacity(calm ? 0.12 : 0.2), center: .init(x: 0.5, y: 0.08), rays: 18)
            Dots(color: .white.opacity(0.28), gap: 22, radius: 2.4)
            if !calm {
                GeometryReader { g in
                    let w = g.size.width, h = g.size.height
                    decor("A", .sun, 0.91 * w, 0.1 * h, -12, 0)   // top right, clear of the back button and Nyan
                    decor("b", Color(hex: 0xFF8FC0), 0.93 * w, 0.3 * h, 10, 0.4)
                    decor("C", Color(hex: 0xBFE9FF), 0.06 * w, 0.62 * h, 8, 0.8)
                    decor("!", .sun, 0.95 * w, 0.72 * h, -6, 1.2)
                    StarBurst().fill(Color.white.opacity(0.55)).frame(width: 34, height: 34).position(x: 0.05 * w, y: 0.45 * h).bob(delay: 0.3)
                    StarBurst().fill(Color.sun.opacity(0.7)).frame(width: 24, height: 24).position(x: 0.12 * w, y: 0.86 * h).bob(delay: 0.9)
                    StarBurst(points: 5, inner: 0.45).fill(Color.white.opacity(0.6)).frame(width: 22, height: 22).position(x: 0.82 * w, y: 0.92 * h).bob(delay: 0.6)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func decor(_ s: String, _ c: Color, _ x: CGFloat, _ y: CGFloat, _ r: Double, _ d: Double) -> some View {
        OutlinedText(s, font: .custom(Fonts.display, size: 34), fill: c, width: 3, shadow: 2)
            .rotationEffect(.degrees(r)).opacity(0.75).position(x: x, y: y).bob(delay: d)
    }
}

/// Section heading in the title-screen style (white outlined letters on a tilted ribbon).
struct PopHeading: View {
    var text: String
    var color: Color = .pop
    var body: some View {
        HStack(spacing: 6) {
            StarBurst(points: 5, inner: 0.45).fill(Color.sun).overlay(StarBurst(points: 5, inner: 0.45).stroke(Color.ink, lineWidth: 2)).frame(width: 20, height: 20)
            OutlinedText(jp(text), font: .display(17.s), width: 2.5, shadow: 2)
        }
        .padding(.horizontal, 12).padding(.vertical, 3)
        .background(Capsule().fill(color).overlay(Capsule().stroke(Color.ink, lineWidth: 2.5)))
        .rotationEffect(.degrees(-1.5))
    }
}
