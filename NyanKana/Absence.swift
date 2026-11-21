import SwiftUI

/// Like Duolingo: when you have not studied for a while, Nyan and the word pet look lonely.
/// "Days away" = days since the last day anything was studied (today counts as 0).
@MainActor
enum Absence {
    static func days(_ app: AppState) -> Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let f = DateFormatter(); f.calendar = Calendar(identifier: .gregorian); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "yyyy-MM-dd"
        let studied = app.study.done.filter { !$0.value.isEmpty }.keys.compactMap { f.date(from: $0) }
            + app.vocab.days.filter { $0.value > 0 }.keys.compactMap { f.date(from: $0) }
        guard let last = studied.max() else { return 0 }
        return max(0, cal.dateComponents([.day], from: cal.startOfDay(for: last), to: today).day ?? 0)
    }
    /// 0 fine, 1 a little lonely (missed yesterday), 2 sad (3+ days)
    static func mood(_ app: AppState) -> Int { let d = days(app); return d >= 3 ? 2 : d >= 2 ? 1 : 0 }

    static func line(_ mood: Int) -> String {
        mood >= 2 ? T("さみしかった|にゃ…|きょうは|いっしょに|べんきょう|しよう？", "외로웠다냥… 오늘은 같이 공부할래?", "好寂寞喵……今天一起學習吧？")
                  : T("きのうは|会えなかったにゃ。|きょうも|がんばろう！", "어제는 못 만났다냥. 오늘도 힘내자!", "昨天沒見到你喵。今天也加油吧！")
    }
}

/// Lonely look: a little gray, drooping, with a small rain cloud and a tear.
struct LonelyLook: ViewModifier {
    let mood: Int
    var size: CGFloat
    func body(content: Content) -> some View {
        content
            .saturation(mood >= 2 ? 0.45 : mood == 1 ? 0.8 : 1)
            .rotationEffect(.degrees(mood >= 2 ? -8 : 0), anchor: .bottom)
            .overlay(alignment: .top) {
                if mood >= 1 {
                    Image(systemName: mood >= 2 ? "cloud.rain.fill" : "cloud.fill")
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: size * 0.32, weight: .bold))
                        .foregroundStyle(Color(hex: 0x8FA3C7))
                        .offset(x: size * 0.18, y: -size * 0.28)
                        .modifier(Hop(amount: 2, period: 1.6))
                }
            }
            .overlay(alignment: .center) {
                if mood >= 2 {
                    Image(systemName: "drop.fill").font(.system(size: size * 0.12)).foregroundStyle(Color.sky)
                        .offset(x: -size * 0.14, y: -size * 0.02)
                }
            }
    }
}
