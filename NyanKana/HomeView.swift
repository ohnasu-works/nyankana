import SwiftUI
import UIKit

/// Home: logo, four equal big tiles (game / study / zukan / record) and a small row.
/// Everything fits one screen without scrolling, on iPhone and iPad.
struct HomeView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        GeometryReader { geo in
            let maxW = min(geo.size.width - 28, UIScale.isPad ? 680 : 480)
            let gap = 12.s
            let tileW = (maxW - gap) / 2
            let logoH = 92.s, smallH = 78.s
            // the premium badge has its own row above the logo, so it never covers the logo
            let badgeH: CGFloat = app.isPremium ? 0 : 40.s
            // the big tiles share what is left; GAME / STUDY are taller than ZUKAN / RECORD
            let rest = geo.size.height - logoH - smallH - (app.isPremium ? 0 : badgeH + gap) - gap * 4 - 20
            let unit = min(tileW * 1.25, rest / 2.3)
            let h1 = unit * 1.3, h2 = unit * 1.0
            ZStack {
                Dots(color: .white.opacity(0.3), gap: 22, radius: 2.6).ignoresSafeArea()
                VStack(spacing: gap) {
                    Spacer(minLength: 0)
                    if !app.isPremium {
                        premiumBadge
                            .frame(maxWidth: .infinity, alignment: .center)
                            .frame(height: badgeH)
                    }
                    logo.frame(height: logoH)
                    HStack(spacing: gap) {
                        gameTile(tileW).frame(width: tileW, height: h1)
                        studyTile(tileW).frame(width: tileW, height: h1)
                    }
                    HStack(spacing: gap) {
                        zukanTile(tileW).frame(width: tileW, height: h2)
                        recordTile(tileW).frame(width: tileW, height: h2)
                    }
                    smallRow(maxW).frame(height: smallH)
                    Spacer(minLength: 0)
                }
                .frame(width: maxW)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .background(Sunburst(center: .init(x: 0.5, y: 0.2)).ignoresSafeArea())
        .onAppear {
            AudioManager.shared.playBGM(.home)
            DispatchQueue.main.async { MapPicture.warmUp() }   // so the map is ready when GAME is tapped
        }
    }

    // MARK: premium entry

    /// small crown button: opens the purchase screen. During the launch sale it says "half price".
    private var premiumBadge: some View {
        Button { AudioManager.shared.se(.tap); app.sheet = .shop } label: {
            HStack(spacing: 4) {
                Image(systemName: "crown.fill").font(.system(size: 13.s, weight: .black)).foregroundStyle(Color(hex: 0xFFB800))
                VStack(alignment: .leading, spacing: 0) {
                    Text(L("home.shop")).font(.ui(12.s)).foregroundStyle(Color.ink)
                    if Store.onSale {
                        Text(T("今だけ半額", "지금만 반값", "限時半價")).font(.ui(10.s)).foregroundStyle(Color.popDeep)
                    }
                }
                .lineLimit(1).fixedSize()
            }
            .padding(.horizontal, 10.s).padding(.vertical, 6.s)
            .background(Capsule().fill(Color.white).overlay(Capsule().stroke(Color.ink, lineWidth: 2.5)))
        }
        .buttonStyle(.plain)
    }

    // MARK: logo

    /// Japanese: the kana logo. Every other language: the same logo in English letters ("Nyanglish"),
    /// with the name / a short tagline in that language on the little blue tag.
    private var logo: some View {
        let ja = L10n.current == .ja
        let word = ja ? "にゃんグリッシュ" : "Nyanglish"
        let size: CGFloat = (UIScale.isPad ? 50 : 34) * (ja ? 1 : 1.12)
        return ZStack(alignment: .bottomTrailing) {
            HStack(spacing: ja ? -2 : 0) {
                ForEach(Array(word.enumerated()), id: \.offset) { i, ch in
                    OutlinedText(String(ch), font: .custom(Fonts.display, size: size), fill: ja ? logoColor(i) : latinLogoColor(i), width: 3.5, shadow: 3.5)
                        .rotationEffect(.degrees(i % 2 == 0 ? -4 : 5))
                        .offset(y: i % 2 == 0 ? 0 : -3)
                }
            }
            .rotationEffect(.degrees(-3))
            Text(ja ? "Nyanglish" : logoTag)
                .font([.ko, .zhHant, .vi].contains(L10n.current) ? .ui(13.s) : .en(13.s)).foregroundStyle(.white)
                .padding(.horizontal, 10).padding(.vertical, 3)
                .fixedSize()
                .background(Rectangle().fill(Color.sky).overlay(Rectangle().stroke(Color.ink, lineWidth: 3)))
                .rotationEffect(.degrees(-8))
                .offset(x: 6, y: 18.s)
        }
        .padding(.bottom, 14.s)
    }

    /// the tag under the English-letter logo
    private var logoTag: String {
        switch L10n.current {
        case .ko: "냥글리시"
        case .zhHant: "喵格利許"
        case .vi: "Học tiếng Anh"
        case .es: "Aprende inglés"
        case .ptBR: "Aprenda inglês"
        default: "English Quest"
        }
    }

    /// N y = pink, a n = orange, g l = blue, i s h = green (the same colour run as the kana logo)
    private func latinLogoColor(_ i: Int) -> Color {
        switch i { case 0, 1: .pop; case 2, 3: .orange; case 4, 5: .sky; default: .mint }
    }

    private func logoColor(_ i: Int) -> Color {
        switch i { case 0, 1: .pop; case 2: .orange; case 3, 4: .sky; default: .mint }
    }

    // MARK: tiles

    private func gameTile(_ w: CGFloat) -> some View {
        PopTile(label: L("home.game"), sub: "GAME", labelSize: fit(L("home.game"), w)) { app.go(.map) } content: {
            ZStack {
                Sunburst(a: Color(hex: 0xFF8FC0), b: Color(hex: 0xFF6AA8), center: .init(x: 0.5, y: 0.55), rays: 16)
                StarBurst().fill(Color(hex: 0xFFF3A8)).frame(width: 150.s, height: 150.s).opacity(0.85)
                // the kids in the clothes chosen in the closet; a little apart so Ken's arm is not hidden
                GeometryReader { g in
                    let h = g.size.height
                    HStack(alignment: .bottom, spacing: -h * 0.16) {
                        Image(Outfit.wearing("ken", app).image("ken")).resizable().scaledToFit().frame(height: h)
                            .rotationEffect(.degrees(-3), anchor: .bottom)
                        Image(Outfit.wearing("rin", app).image("rin")).resizable().scaledToFit().frame(height: h * 0.82)
                            .rotationEffect(.degrees(3), anchor: .bottom)
                    }
                    .frame(width: g.size.width, height: h, alignment: .bottom)
                }
                .padding(.top, 6.s).padding(.bottom, 30.s)
            }
        }
    }

    private func studyTile(_ w: CGFloat) -> some View {
        PopTile(label: L("home.study"), sub: "STUDY", labelSize: fit(L("home.study"), w)) { app.go(.study) } content: {
            ZStack {
                LinearGradient(colors: [Color(hex: 0x5FE0B6), Color.mintDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
                Dots()
                GeometryReader { g in
                    OutlinedText("A", font: .custom(Fonts.display, size: 44.s), fill: .sun, width: 3, shadow: 2).rotationEffect(.degrees(-12)).position(x: g.size.width * 0.17, y: g.size.height * 0.14)
                    OutlinedText("b", font: .custom(Fonts.display, size: 40.s), fill: Color(hex: 0xFF8FC0), width: 3, shadow: 2).rotationEffect(.degrees(10)).position(x: g.size.width * 0.15, y: g.size.height * 0.34)
                    OutlinedText("C", font: .custom(Fonts.display, size: 40.s), fill: Color(hex: 0xBFE9FF), width: 3, shadow: 2).rotationEffect(.degrees(6)).position(x: g.size.width * 0.19, y: g.size.height * 0.54)
                    Image("nyan").resizable().scaledToFit().frame(width: g.size.width * 0.66).rotationEffect(.degrees(6))
                        .modifier(LonelyLook(mood: Absence.mood(app), size: g.size.width * 0.66))
                        .position(x: g.size.width * 0.6, y: g.size.height * 0.4).hop(5, period: 0.7)
                }
            }
        }
    }

    private func zukanTile(_ w: CGFloat) -> some View {
        PopTile(label: L("home.zukan"), sub: "ZUKAN", labelSize: fit(L("home.zukan"), w)) { app.go(.zukan) } content: {
            ZStack {
                LinearGradient(colors: [Color(hex: 0x8BE07A), Color(hex: 0x4CBF5A)], startPoint: .topLeading, endPoint: .bottomTrailing)
                Dots()
                GeometryReader { g in
                    Image("gob_07").resizable().scaledToFit().frame(height: g.size.height * 0.4).position(x: g.size.width * 0.28, y: g.size.height * 0.3).bob()
                    Image("gob_09").resizable().scaledToFit().frame(height: g.size.height * 0.44).position(x: g.size.width * 0.74, y: g.size.height * 0.3).bob(delay: 0.5)
                    Image("gob_06").resizable().scaledToFit().frame(height: g.size.height * 0.3).position(x: g.size.width * 0.52, y: g.size.height * 0.5).bob(delay: 1)
                }
            }
        }
    }

    private func recordTile(_ w: CGFloat) -> some View {
        PopTile(label: L("home.record"), sub: "RECORD", labelSize: fit(L("home.record"), w)) { app.go(.record) } content: {
            ZStack {
                LinearGradient(colors: [Color(hex: 0x8FD0FF), Color(hex: 0x4B9CF5)], startPoint: .topLeading, endPoint: .bottomTrailing)
                Dots()
                GeometryReader { g in
                    HStack(alignment: .bottom, spacing: g.size.width * 0.05) {
                        bar(0.4, .sun); bar(0.7, Color(hex: 0xFF8FC0)); bar(0.55, Color(hex: 0x7DE0B8)); bar(0.95, .sun)
                    }
                    .frame(width: g.size.width * 0.56, height: g.size.height * 0.42, alignment: .bottom)
                    .position(x: g.size.width * 0.4, y: g.size.height * 0.36)
                    UIIcon("ui_trophy|🏆", size: 40.s).rotationEffect(.degrees(12)).position(x: g.size.width * 0.82, y: g.size.height * 0.24)
                }
            }
        }
    }

    private func bar(_ h: CGFloat, _ c: Color) -> some View {
        GeometryReader { g in
            VStack { Spacer(minLength: 0)
                UnevenRoundedRectangle(topLeadingRadius: 6, topTrailingRadius: 6).fill(c)
                    .overlay(UnevenRoundedRectangle(topLeadingRadius: 6, topTrailingRadius: 6).stroke(Color.ink, lineWidth: 3))
                    .frame(height: g.size.height * h)
            }
        }
    }

    /// tile label size that always fits inside the tile
    private func fit(_ label: String, _ w: CGFloat) -> CGFloat {
        min(32.s, (w - 30) / (CGFloat(label.count) + 0.6))
    }

    // MARK: small row

    private func smallRow(_ width: CGFloat) -> some View {
        let w = (width - 30.s) / 4
        let size = min(13.s, (w - 12) / 6.4)
        return HStack(spacing: 10.s) {
            small("ui_dress|👗", L("home.closet"), Stripes(a: Color(hex: 0xFF8FC0), b: Color(hex: 0xFF7AB3)), size) { app.go(.closet) }.frame(width: w)
                .overlay(alignment: .topTrailing) { if Outfit.hasNew(app) { Circle().fill(Color.popDeep).frame(width: 14, height: 14).overlay(Circle().stroke(Color.white, lineWidth: 2)).offset(x: 2, y: -2).allowsHitTesting(false) } }
            small("ui_heart|❤️", L("home.items"), Stripes(a: Color(hex: 0x4FD0D8), b: Color(hex: 0x36BCC6)), size) { app.sheet = .items }.frame(width: w)
            small("ui_question|❓", L("home.howto"), Stripes(a: Color(hex: 0xFFAD4F), b: Color(hex: 0xFF9A2E)), size) { app.sheet = .howTo }.frame(width: w)
            small("ui_gear|⚙️", L("home.settings"), Stripes(a: Color(hex: 0xB48CFF), b: Color(hex: 0x9F72F5)), size) { app.go(.settings) }.frame(width: w)
        }
    }

    private func small<B: View>(_ icon: String, _ label: String, _ bg: B, _ size: CGFloat, action: @escaping () -> Void) -> some View {
        Button {
            AudioManager.shared.se(.tap); action()
        } label: {
            VStack(spacing: 0) {
                UIIcon(icon, size: 28.s)
                OutlinedText(label, font: .ui(size), width: 2.5, shadow: 0).fixedSize()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 16.s, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16.s, style: .continuous).stroke(Color.ink, lineWidth: 3))
        }
        .buttonStyle(PressStyle(radius: 16.s, depth: 4))
    }
}


/// A drawn icon from the asset catalog ("name|fallback emoji"); the emoji is shown until the picture is added.
struct UIIcon: View {
    let name: String, emoji: String, size: CGFloat
    init(_ spec: String, size: CGFloat) {
        let p = spec.split(separator: "|", maxSplits: 1).map(String.init)
        name = p[0]; emoji = p.count > 1 ? p[1] : ""; self.size = size
    }
    var body: some View {
        if UIImage(named: name) != nil {
            Image(name).resizable().scaledToFit().frame(width: size * 1.25, height: size * 1.25)
        } else {
            Text(emoji).font(.system(size: size))
        }
    }
}
