// 絵カード：ひとつの言葉に ひとつの絵（2026-11-27）
import SwiftUI
import UIKit

// MARK: - 絵文字を使わない：すべての絵は Gemini で描いたイラスト（Assets の pic_<コードポイント>）
// データの中では今まで通り 絵文字1文字を「絵の名前」として使い、画面に出すときに イラストへ置きかえる。

enum KJPic {
    /// "🍎" → "pic_1f34e" (variation selectors are ignored)
    static func name(_ e: String) -> String {
        "pic_" + e.unicodeScalars.filter { $0.value != 0xFE0F }.map { String($0.value, radix: 16) }.joined(separator: "_")
    }

    /// typographic marks that stay as text
    private static let keep: Set<Unicode.Scalar> = Set("★☆✕✔✓⇄⌘↓↑←→◯○●".unicodeScalars)

    static func isPic(_ ch: Character) -> Bool {
        ch.unicodeScalars.contains { s in
            guard !keep.contains(s), s.value > 0x2000 else { return false }
            return s.properties.isEmojiPresentation || (s.properties.isEmoji && s.value >= 0x2190)
        }
    }

    static func has(_ e: String) -> Bool { UIImage(named: name(e)) != nil }

    private static var cache: [String: UIImage] = [:]
    /// the drawing at `pt` points (for use inside Text)
    static func ui(_ e: String, pt: CGFloat) -> UIImage? {
        let key = "\(name(e))@\(Int(pt))"
        if let c = cache[key] { return c }
        guard let src = UIImage(named: name(e)) else { return nil }
        let s = pt / max(src.size.width, src.size.height)
        let size = CGSize(width: src.size.width * s, height: src.size.height * s)
        let img = UIGraphicsImageRenderer(size: size).image { _ in src.draw(in: CGRect(origin: .zero, size: size)) }
        cache[key] = img
        return img
    }

    /// a string with pictographs → Text with the drawings inline (wraps like text); a missing drawing is left out
    static func text(_ s: String, size: CGFloat) -> Text {
        var out = Text("")
        var plain = ""
        for ch in s {
            if isPic(ch) {
                if !plain.isEmpty { out = out + Text(plain); plain = "" }
                if let img = ui(String(ch), pt: size * 1.2) {
                    out = out + Text(Image(uiImage: img)).baselineOffset(-size * 0.22)
                }
            } else {
                plain.append(ch)
            }
        }
        if !plain.isEmpty { out = out + Text(plain) }
        return out
    }

    /// the string without pictographs (notifications, speech)
    static func strip(_ s: String) -> String {
        String(s.filter { !isPic($0) }).trimmingCharacters(in: .whitespaces)
    }

    /// the first pictograph in a string, if any
    static func first(_ s: String) -> String? { s.first { isPic($0) }.map(String.init) }
}

/// one drawing, square
struct KJPicView: View {
    let e: String
    let size: CGFloat
    init(_ e: String, size: CGFloat) { self.e = e; self.size = size }
    var body: some View {
        if KJPic.has(e) {
            Image(KJPic.name(e)).resizable().scaledToFit().frame(width: size, height: size)
        } else {
            Color.clear.frame(width: size, height: size)
        }
    }
}
