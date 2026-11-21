import SwiftUI
import CoreText

// MARK: - Fonts

enum Fonts {
    static let display = "DelaGothicOne-Regular"     // chunky logo / labels
    static let rounded = "RoundedMplus1c-ExtraBold"  // Japanese UI
    static let roundedBold = "RoundedMplus1c-Bold"
    static let english = "Fredoka-Bold"              // English text

    static func registerAll() {
        let names = ["DelaGothicOne-Regular", "MPLUSRounded1c-ExtraBold", "MPLUSRounded1c-Bold", "Fredoka-Bold"]
        for n in names {
            if let url = Bundle.main.url(forResource: n, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }
}

extension Font {
    /// Chunky display type. Korean / Chinese fall back to the system's heavy rounded font.
    /// iPhone: there is room to spare, so small text grows the most (nothing under 13 pt) and large text a little
    static func phone(_ size: CGFloat) -> CGFloat {
        guard !UIScale.isPad else { return size }
        return size < 16 ? max(13, size * 1.15) : size * 1.06
    }
    static func display(_ size: CGFloat) -> Font {
        let size = phone(size)
        return L10n.current == .ja ? .custom(Fonts.display, size: size) : .system(size: size, weight: .black, design: .rounded)
    }
    static func ui(_ size: CGFloat, bold: Bool = true) -> Font {
        let size = phone(size)
        return L10n.current == .ja ? .custom(bold ? Fonts.rounded : Fonts.roundedBold, size: size) : .system(size: size, weight: bold ? .heavy : .bold, design: .rounded)
    }
    /// the language being learned (Japanese): M PLUS Rounded, which also has Latin letters
    static func en(_ size: CGFloat) -> Font { .custom(Fonts.roundedBold, size: phone(size)) }
}

// MARK: - Colours (pop palette)

extension Color {
    static let ink = Color(hex: 0x231F4A)
    static let paper = Color(hex: 0xFFFAF1)
    static let pop = Color(hex: 0xFF6FAE)
    static let popDeep = Color(hex: 0xFF4F93)
    static let mint = Color(hex: 0x3FD6A6)
    static let mintDeep = Color(hex: 0x2FBF8F)
    static let sun = Color(hex: 0xFFD93B)
    static let sunDeep = Color(hex: 0xFFC21A)
    static let sky = Color(hex: 0x3BB8FF)
    static let grass = Color(hex: 0x6ED45E)
    static let orange = Color(hex: 0xFF9A2E)
    static let grape = Color(hex: 0xA57CF8)
    static let danger = Color(hex: 0xFF5A5F)

    init(hex: UInt32, alpha: Double = 1) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255, opacity: alpha)
    }
}

// MARK: - Device scale (iPad shows everything larger)

enum UIScale {
    static var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    /// multiply sizes by this on iPad
    static var k: CGFloat { isPad ? 1.4 : 1.0 }
}

extension CGFloat { var s: CGFloat { self * UIScale.k } }
extension Double { var s: CGFloat { CGFloat(self) * UIScale.k } }
extension Int { var s: CGFloat { CGFloat(self) * UIScale.k } }

// MARK: - Japanese line breaking
/// Japanese strings carry "|" where a line may break. Everywhere else a word joiner keeps
/// the characters together, so a line never breaks in the middle of a word.
func jp(_ s: String) -> String {
    guard L10n.current == .ja else { return s.replacingOccurrences(of: "|", with: "") }
    // text without | marks (question data, word meanings...): find the phrase breaks automatically
    let marked = s.contains("|") ? s : JPBreak.mark(s)
    guard marked.contains("|") || s.contains("|") || JPBreak.hasJapanese(s) else { return s }
    let parts = marked.split(separator: "|", omittingEmptySubsequences: false)
    return parts.map { seg in seg.map(String.init).joined(separator: "\u{2060}") }.joined(separator: "\u{200B}")
}


/// Simple phrase splitter for Japanese text that has no | marks:
/// a line may break after 、, before 「, and where hiragana (particles / endings) is followed by a new word.
enum JPBreak {
    private static func kind(_ c: Character) -> Int {
        guard let u = c.unicodeScalars.first?.value else { return 0 }
        if (0x3041...0x309F).contains(u) { return 1 }                 // hiragana
        if (0x30A0...0x30FF).contains(u) || u == 0xFF70 { return 2 }  // katakana
        if (0x4E00...0x9FFF).contains(u) || u == 0x3005 { return 3 }  // kanji, 々
        if c.isLetter || c.isNumber { return 4 }                      // latin / digits
        return 0
    }
    static func hasJapanese(_ s: String) -> Bool { s.contains { (1...3).contains(kind($0)) } }
    /// characters that must never start a line
    private static let noStart: Set<Character> = Set("、。，．！？!?」』）)ー〜…ぁぃぅぇぉっゃゅょゎァィゥェォッャュョヮ・：:")
    private static let particles: Set<Character> = Set("はがをでにもへ")

    static func mark(_ s: String) -> String {
        let c = Array(s)
        guard c.count > 6, hasJapanese(s) else { return s }
        var cut: [Int] = []
        for i in 1..<c.count {
            let p = c[i - 1], q = c[i]
            if noStart.contains(q) { continue }
            let kp = kind(p), kq = kind(q)
            if "、，".contains(p) || "「『（(".contains(q) || "」』）)".contains(p) { cut.append(i); continue }
            if kp == 1 && (kq == 2 || kq == 3 || kq == 4) { cut.append(i) }
        }
        // a long run with no natural break (e.g. all hiragana): also allow a break after a particle
        var segs: [[Character]] = []
        var start = 0
        for k in cut + [c.count] { segs.append(Array(c[start..<k])); start = k }
        var out: [String] = []
        for seg in segs {
            if seg.count > 10 {
                let mid = seg.count / 2
                let options = (3..<(seg.count - 2)).filter { particles.contains(seg[$0 - 1]) && kind(seg[$0 - 2]) >= 2 && kind(seg[$0]) == 1 && !noStart.contains(seg[$0]) }
                if let j = options.min(by: { abs($0 - mid) < abs($1 - mid) }) {
                    out.append(String(seg[..<j])); out.append(String(seg[j...])); continue
                }
            }
            out.append(String(seg))
        }
        return out.joined(separator: "|")
    }
}
