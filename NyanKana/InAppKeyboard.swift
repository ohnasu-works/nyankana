import SwiftUI

/// Hiragana keyboard built into the answer panel (the 50-sound table).
/// The system keyboard covered half the screen and squeezed the game into a strip.
/// Katakana answers are typed in hiragana too (answers are compared kana-blind).
struct InAppKeyboard: View {
    @Binding var text: String
    var submit: () -> Void

    /// columns of the table, read left to right (あ か さ … わ), five rows (a i u e o)
    private static let columns: [[String]] = [
        ["あ", "い", "う", "え", "お"], ["か", "き", "く", "け", "こ"], ["さ", "し", "す", "せ", "そ"],
        ["た", "ち", "つ", "て", "と"], ["な", "に", "ぬ", "ね", "の"], ["は", "ひ", "ふ", "へ", "ほ"],
        ["ま", "み", "む", "め", "も"], ["や", "", "ゆ", "", "よ"], ["ら", "り", "る", "れ", "ろ"],
        ["わ", "", "を", "", "ん"],
    ]

    var body: some View {
        GeometryReader { g in
            let gap: CGFloat = 4
            let keyW = (g.size.width - gap * 9) / 10
            let keyH: CGFloat = 30
            VStack(spacing: gap) {
                ForEach(0..<5, id: \.self) { r in
                    HStack(spacing: gap) {
                        ForEach(0..<10, id: \.self) { c in
                            let s = Self.columns[c][r]
                            if s.isEmpty { Color.clear.frame(width: keyW, height: keyH) } else { letter(s, keyW, keyH) }
                        }
                    }
                }
                HStack(spacing: gap) {
                    special(Text("゛゜").font(.en(16)), w: keyW * 2 + gap, h: keyH) { mark() }
                    special(Text("小").font(.en(16)), w: keyW * 1.5, h: keyH) { small() }
                    symbol("ー", keyW * 1.5, keyH)
                    symbol("、", keyW, keyH)
                    symbol("。", keyW, keyH)
                    symbol("？", keyW, keyH)
                    special(Image(systemName: "delete.left").font(.system(size: 16, weight: .bold)), w: keyW * 2 + gap, h: keyH) {
                        if !text.isEmpty { text.removeLast() }
                    }
                }
            }
            .frame(width: g.size.width)
        }
        .frame(height: 30 * 6 + 4 * 5)
    }

    // ゛ / ゜ on the last kana: か→が, は→ば→ぱ→は
    private static let marks: [Character: Character] = {
        var m: [Character: Character] = [:]
        let plain = Array("かきくけこさしすせそたちつてとはひふへほう")
        let voiced = Array("がぎぐげござじずぜぞだぢづでどばびぶべぼゔ")
        for (a, b) in zip(plain, voiced) { m[a] = b }
        let half = Array("ぱぴぷぺぽ")
        for (i, b) in Array("ばびぶべぼ").enumerated() { m[b] = half[i]; m[half[i]] = Array("はひふへほ")[i] }
        for (a, b) in zip(voiced, plain) where m[a] == nil { m[a] = b }
        return m
    }()
    private static let smalls: [Character: Character] = {
        var m: [Character: Character] = [:]
        for (a, b) in zip(Array("あいうえおつやゆよわ"), Array("ぁぃぅぇぉっゃゅょゎ")) { m[a] = b; m[b] = a }
        return m
    }()
    private func mark() { if let c = text.last, let n = Self.marks[c] { text.removeLast(); text.append(n) } }
    private func small() { if let c = text.last, let n = Self.smalls[c] { text.removeLast(); text.append(n) } }

    private func letter(_ s: String, _ w: CGFloat, _ h: CGFloat) -> some View {
        key(Text(s).font(.en(18)), w: w, h: h, fill: .white) { text += s }
    }

    private func symbol(_ s: String, _ w: CGFloat, _ h: CGFloat) -> some View {
        key(Text(s).font(.en(18)), w: w, h: h, fill: Color(hex: 0xEDEAF6)) { text += s }
    }

    private func special<L: View>(_ label: L, w: CGFloat, h: CGFloat, _ action: @escaping () -> Void) -> some View {
        key(label, w: w, h: h, fill: Color(hex: 0xEDEAF6), action)
    }

    private func key<L: View>(_ label: L, w: CGFloat, h: CGFloat, fill: Color, _ action: @escaping () -> Void) -> some View {
        Button {
            AudioManager.shared.se(.tap, rate: 1.5, volume: 0.25)
            action()
        } label: {
            label.foregroundStyle(Color.ink)
                .frame(width: w, height: h)
                .background(RoundedRectangle(cornerRadius: 7).fill(fill).overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.ink, lineWidth: 1.5)))
        }
        .buttonStyle(PressStyle(radius: 7, depth: 2))
    }
}
