import SwiftUI

/// English keyboard built into the answer panel (iPhone).
/// The system keyboard covered half the screen and squeezed the game into a strip.
struct InAppKeyboard: View {
    @Binding var text: String
    var submit: () -> Void
    @State private var shift = false

    private let rows = ["qwertyuiop", "asdfghjkl", "zxcvbnm"]

    var body: some View {
        GeometryReader { g in
            let gap: CGFloat = 5
            let keyW = (g.size.width - gap * 9) / 10
            let keyH: CGFloat = 39
            VStack(spacing: 6) {
                row(rows[0], keyW, keyH, gap)
                row(rows[1], keyW, keyH, gap)
                HStack(spacing: gap) {
                    special(Image(systemName: shift ? "shift.fill" : "shift"), w: keyW * 1.35, h: keyH) { shift.toggle() }
                    ForEach(Array(rows[2]), id: \.self) { c in letter(c, keyW, keyH) }
                    special(Image(systemName: "delete.left"), w: keyW * 1.35, h: keyH) {
                        if !text.isEmpty { text.removeLast() }
                    }
                }
                HStack(spacing: gap) {
                    symbol("'", keyW, keyH)
                    symbol(",", keyW, keyH)
                    key(Text("space").font(.en(15)), w: keyW * 5 + gap * 4, h: keyH, fill: .white) { text += " " }
                    symbol(".", keyW, keyH)
                    symbol("?", keyW, keyH)
                    symbol("-", keyW, keyH)
                }
            }
            .frame(width: g.size.width)
        }
        .frame(height: 39 * 4 + 6 * 3)
    }

    private func row(_ s: String, _ w: CGFloat, _ h: CGFloat, _ gap: CGFloat) -> some View {
        HStack(spacing: gap) { ForEach(Array(s), id: \.self) { c in letter(c, w, h) } }
    }

    private func letter(_ c: Character, _ w: CGFloat, _ h: CGFloat) -> some View {
        let s = shift ? String(c).uppercased() : String(c)
        return key(Text(s).font(.en(20)), w: w, h: h, fill: .white) {
            text += s
            shift = false
        }
    }

    private func symbol(_ s: String, _ w: CGFloat, _ h: CGFloat) -> some View {
        key(Text(s).font(.en(20)), w: w, h: h, fill: Color(hex: 0xEDEAF6)) { text += s }
    }

    private func special(_ icon: Image, w: CGFloat, h: CGFloat, _ action: @escaping () -> Void) -> some View {
        key(icon.font(.system(size: 17, weight: .bold)), w: w, h: h, fill: Color(hex: 0xEDEAF6), action)
    }

    private func key<L: View>(_ label: L, w: CGFloat, h: CGFloat, fill: Color, _ action: @escaping () -> Void) -> some View {
        Button {
            AudioManager.shared.se(.tap, rate: 1.5, volume: 0.25)
            action()
        } label: {
            label.foregroundStyle(Color.ink)
                .frame(width: w, height: h)
                .background(RoundedRectangle(cornerRadius: 8).fill(fill).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.ink, lineWidth: 1.5)))
        }
        .buttonStyle(PressStyle(radius: 8, depth: 2))
    }
}
