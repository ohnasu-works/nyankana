import SwiftUI

// MARK: - Outlined pop text (white fill, thick ink outline, drop shadow)

struct OutlinedText: View {
    var text: String
    var font: Font
    var fill: Color = .white
    var stroke: Color = .ink
    var width: CGFloat = 4
    var shadow: CGFloat = 4

    init(_ text: String, font: Font, fill: Color = .white, stroke: Color = .ink, width: CGFloat = 4, shadow: CGFloat = 4) {
        self.text = text; self.font = font; self.fill = fill; self.stroke = stroke; self.width = width; self.shadow = shadow
    }

    var body: some View {
        let t = Text(text).font(font)
        ZStack {
            // outline: the same text drawn around the centre
            ForEach(0..<16, id: \.self) { i in
                let a = Double(i) / 16 * 2 * .pi
                t.foregroundStyle(stroke).offset(x: cos(a) * width, y: sin(a) * width + shadow)
            }
            ForEach(0..<16, id: \.self) { i in
                let a = Double(i) / 16 * 2 * .pi
                t.foregroundStyle(stroke).offset(x: cos(a) * width, y: sin(a) * width)
            }
            t.foregroundStyle(fill)
        }
        .padding(width)
        .fixedSize()
    }
}

// MARK: - Backgrounds

/// Rotating sunburst rays (Rhythm-Heaven-like), drawn with Canvas.
struct Sunburst: View {
    var a: Color = .sun
    var b: Color = .sunDeep
    var center: UnitPoint = .init(x: 0.5, y: 0.35)
    var rays = 20
    var spin = true
    @State private var angle: Double = 0

    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(a))
            let c = CGPoint(x: size.width * center.x, y: size.height * center.y)
            let r = hypot(size.width, size.height)
            let step = 2 * Double.pi / Double(rays * 2)
            for i in 0..<rays {
                let s = Double(i * 2) * step + angle
                var p = Path()
                p.move(to: c)
                p.addLine(to: CGPoint(x: c.x + cos(s) * r, y: c.y + sin(s) * r))
                p.addLine(to: CGPoint(x: c.x + cos(s + step) * r, y: c.y + sin(s + step) * r))
                p.closeSubpath()
                ctx.fill(p, with: .color(b))
            }
        }
        .onAppear {
            guard spin else { return }
            withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) { angle = .pi * 2 }
        }
    }
}

/// Soft polka dots over any background.
struct Dots: View {
    var color: Color = .white.opacity(0.35)
    var gap: CGFloat = 20
    var radius: CGFloat = 2.6
    var body: some View {
        Canvas { ctx, size in
            var y: CGFloat = gap / 2
            var row = 0
            while y < size.height {
                var x: CGFloat = (row % 2 == 0 ? gap / 2 : gap)
                while x < size.width {
                    ctx.fill(Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)), with: .color(color))
                    x += gap
                }
                y += gap; row += 1
            }
        }
        .allowsHitTesting(false)
    }
}

/// Diagonal stripes (for small tiles).
struct Stripes: View {
    var a: Color
    var b: Color
    var width: CGFloat = 10
    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(a))
            var x: CGFloat = -size.height
            while x < size.width {
                var p = Path()
                p.move(to: CGPoint(x: x, y: size.height))
                p.addLine(to: CGPoint(x: x + size.height, y: 0))
                p.addLine(to: CGPoint(x: x + size.height + width, y: 0))
                p.addLine(to: CGPoint(x: x + width, y: size.height))
                ctx.fill(p, with: .color(b))
                x += width * 2
            }
        }
    }
}

/// A star burst shape.
struct StarBurst: Shape {
    var points = 8
    var inner: CGFloat = 0.62
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY), R = min(rect.width, rect.height) / 2
        for i in 0..<(points * 2) {
            let a = Double(i) / Double(points * 2) * 2 * .pi - .pi / 2
            let r = i % 2 == 0 ? R : R * inner
            let pt = CGPoint(x: c.x + cos(a) * r, y: c.y + sin(a) * r)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

// MARK: - Tiles and buttons

/// Big menu tile with thick outline and hard shadow; content draws the illustration inside.
struct PopTile<Content: View>: View {
    var label: String
    var sub: String
    var labelSize: CGFloat = 30
    var action: () -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                content()
                VStack(alignment: .leading, spacing: 4.s) {
                    OutlinedText(jp(label), font: .display(labelSize), width: 3.5.s, shadow: 3.s)
                        .lineLimit(1).minimumScaleFactor(0.5)
                    Text(sub)
                        .font(.en(12.s))
                        .foregroundStyle(Color.ink)
                        .padding(.horizontal, 10.s).padding(.vertical, 2.s)
                        .background(Capsule().fill(Color.sun).overlay(Capsule().stroke(Color.ink, lineWidth: 2)))
                }
                .rotationEffect(.degrees(-3))
                .padding(10.s)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18.s, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18.s, style: .continuous).stroke(Color.ink, lineWidth: 4))
        }
        .buttonStyle(PressStyle(radius: 18.s))
    }
}

/// Hard drop shadow that collapses when pressed.
struct PressStyle: ButtonStyle {
    var radius: CGFloat = 16
    var depth: CGFloat = 6
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(Color.ink).offset(y: configuration.isPressed ? 2 : depth))
            .offset(y: configuration.isPressed ? depth - 2 : 0)
            .animation(.spring(response: 0.18, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Standard chunky button.
struct PopButton: View {
    var title: String
    var color: Color = .sun
    var textColor: Color = .ink
    var height: CGFloat = 56
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(jp(title))
                .font(.ui(min(19, height * 0.36).s))
                .foregroundStyle(textColor)
                .lineLimit(1).minimumScaleFactor(0.5)
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, minHeight: height.s)
                .background(RoundedRectangle(cornerRadius: 16.s, style: .continuous).fill(color))
                .overlay(RoundedRectangle(cornerRadius: 16.s, style: .continuous).stroke(Color.ink, lineWidth: 3))
        }
        .buttonStyle(PressStyle(radius: 16.s, depth: 5))
    }
}

/// Pink ribbon title used at the top of menu screens.
struct RibbonTitle: View {
    var text: String
    var color: Color = .pop
    var size: CGFloat = 24
    var body: some View {
        OutlinedText(jp(text), font: .display(size.s), width: 3, shadow: 0)
            .padding(.horizontal, 22.s).padding(.vertical, 4.s)
            .background(Capsule().fill(color).overlay(Capsule().stroke(Color.ink, lineWidth: 3)))
            .background(Capsule().fill(Color.ink).offset(y: 4))
            .rotationEffect(.degrees(-2))
    }
}

/// Back button for sub screens.
struct BackChip: View {
    var action: () -> Void
    var body: some View {
        Button { AudioManager.shared.se(.back); action() } label: {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left").font(.system(size: 14.s, weight: .black))
                Text(L("common.back")).font(.ui(14.s))
            }
            .foregroundStyle(Color.ink)
            .padding(.horizontal, 14.s).padding(.vertical, 8.s)
            .background(Capsule().fill(Color.white).overlay(Capsule().stroke(Color.ink, lineWidth: 3)))
        }
        .buttonStyle(PressStyle(radius: 30, depth: 3))
        .padding(.top, UIScale.isPad ? 30 : 0)      // iPad: below the window buttons (•••) at the top left
    }
}

/// Paper card used for sheets and panels.
struct PaperCard<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        content()
            .padding(16.s)
            .background(
                ZStack {
                    Color.paper
                    Dots(color: Color(hex: 0xFFE9B8), gap: 16, radius: 1.6)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 24.s, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24.s, style: .continuous).stroke(Color.ink, lineWidth: 4))
            .background(RoundedRectangle(cornerRadius: 24.s, style: .continuous).fill(Color.ink).offset(y: 8))
    }
}

/// Simple hop animation for characters.
struct Hop: ViewModifier {
    var amount: CGFloat = 8
    var period: Double = 0.8
    @State private var up = false
    func body(content: Content) -> some View {
        content.offset(y: up ? -amount : 0)
            .onAppear { withAnimation(.easeInOut(duration: period).repeatForever()) { up = true } }
    }
}

struct Bob: ViewModifier {
    var delay: Double = 0
    @State private var on = false
    func body(content: Content) -> some View {
        content.offset(y: on ? -10 : 0).rotationEffect(.degrees(on ? 6 : -6))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever()) { on = true }
                }
            }
    }
}

extension View {
    func hop(_ amount: CGFloat = 8, period: Double = 0.8) -> some View { modifier(Hop(amount: amount, period: period)) }
    func bob(delay: Double = 0) -> some View { modifier(Bob(delay: delay)) }
}
