import SwiftUI

/// The world map: Japan, one pin per chapter (region). Like にゃんグリッシュ's island map:
/// pick a region on the map, then play on from the card below or open its stage list.
struct KJJapanMap: View {
    @Binding var chapter: Int
    var play: (Int) -> Void
    var home: () -> Void
    var playground: () -> Void
    var openCourse: () -> Void

    /// where each region's pin sits on the map picture (0…1 of its width / height)
    static let pins: [Int: CGPoint] = [
        1: CGPoint(x: 0.66, y: 0.57),   // 関東（とうきょうタワー）
        2: CGPoint(x: 0.72, y: 0.41),   // 東北
        3: CGPoint(x: 0.81, y: 0.18),   // 北海道
        4: CGPoint(x: 0.53, y: 0.53),   // 中部（ふじさん）
        5: CGPoint(x: 0.45, y: 0.67),   // 関西
        6: CGPoint(x: 0.31, y: 0.65),   // 中国・四国
        7: CGPoint(x: 0.20, y: 0.72)    // 九州・沖縄
    ]
    /// which side of the pin the region's name goes (toward the sea, away from the other pins)
    enum Side { case left, right, above, below }
    static let side: [Int: Side] = [1: .right, 2: .right, 3: .left, 4: .above, 5: .below, 6: .above, 7: .below]

    var body: some View {
        VStack(spacing: 0) {
            mapPicture
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .layoutPriority(-1)      // the map shrinks; the card below always fits
            card
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 12.s)
                .padding(.bottom, 8.s)
                .frame(maxWidth: UIScale.isPad ? 640 : .infinity)
        }
        .background(Color(hex: 0xA8E4F2).ignoresSafeArea())
        .overlay(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 6.s) {
                BackChip { home() }
                VStack(alignment: .leading, spacing: -2) {
                    OutlinedText("にっぽん", font: .ui(12.s), width: 2.5, shadow: 0).padding(.leading, 6)
                    OutlinedText("NIPPON", font: .display(24.s), fill: .sun, width: 3.5, shadow: 3)
                }
                .rotationEffect(.degrees(-4))
                .allowsHitTesting(false)
            }
            .padding(.leading, 14.s).padding(.top, 6.s)
        }
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 8.s) {
                Button {
                    AudioManager.shared.se(.decide)
                    playground()
                } label: {
                    HStack(spacing: 4.s) {
                        KJPicView("🎮", size: 18.4.s)
                        Text("あそびば").font(.custom(Fonts.rounded, size: 14.s)).foregroundStyle(Color.ink)
                    }
                    .padding(.horizontal, 12.s).padding(.vertical, 6.s)
                    .background(Capsule().fill(Color.mint).overlay(Capsule().stroke(Color.ink, lineWidth: 2.5)))
                }
                .buttonStyle(PressStyle(radius: 16.s, depth: 3))
                KJSlowButton()
            }
            .padding(.trailing, 14.s).padding(.top, 6.s)
        }
    }

    // MARK: map

    private func open(_ ch: Int) -> Bool {
        guard let first = KJC1.stages(in: ch).first else { return false }
        return KJC1.unlocked(first.id)
    }
    private func cleared(_ ch: Int) -> Int { KJC1.stages(in: ch).filter { KJC1.stars($0.id) > 0 }.count }

    private var mapPicture: some View {
        GeometryReader { g in
            // a square picture as big as fits (the whole of Japan always shows)
            let side = min(g.size.width, g.size.height)
            let k = min(1, side / 400)
            ZStack(alignment: .topLeading) {
                Image("map_japan").resizable().frame(width: side, height: side)
                ForEach(1...7, id: \.self) { ch in
                    let p = Self.pins[ch] ?? .zero
                    let c = CGPoint(x: side * p.x, y: side * p.y)
                    let d = 26.s * k
                    switch Self.side[ch] ?? .right {
                    case .right: label(ch, k: k, align: .leading).position(x: c.x + d, y: c.y)
                    case .left: label(ch, k: k, align: .trailing).position(x: c.x - d, y: c.y)
                    case .above: label(ch, k: k, align: .bottom).position(x: c.x, y: c.y - d - 2.s * k)
                    case .below: label(ch, k: k, align: .top).position(x: c.x, y: c.y + d + 4.s * k)
                    }
                    pin(ch).scaleEffect(k).position(c)
                }
                let sp = Self.pins[chapter] ?? .zero
                Image("nyan").resizable().scaledToFit().frame(width: side * 0.08)
                    .position(x: side * sp.x, y: side * sp.y - 40.s * k)
                    .hop(6, period: 0.45)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: chapter)
                    .allowsHitTesting(false)
            }
            .frame(width: side, height: side)
            .position(x: g.size.width / 2, y: g.size.height / 2)
        }
    }

    private func select(_ ch: Int) {
        AudioManager.shared.se(.decide, rate: 1.2, volume: 0.6)
        withAnimation { chapter = ch }
    }

    private func pin(_ ch: Int) -> some View {
        let ok = open(ch)
        let done = KJC1.stages(in: ch).last.map { KJC1.stars($0.id) > 0 } ?? false
        return Button { select(ch) } label: {
            Group {
                if ok { Text("\(ch)").font(.display(18.s)) }
                else { Image(systemName: "lock.fill").font(.system(size: 15.s, weight: .bold)) }
            }
            .foregroundStyle(ok ? Color.white : Color.ink)
            .frame(width: 36.s, height: 36.s)
            .background(Circle().fill(ok ? Color.pop : Color(hex: 0xD9D4EA)))
            .overlay(Circle().stroke(Color.ink, lineWidth: 4))
            .overlay(Circle().stroke(Color.sun, lineWidth: ch == chapter ? 4 : 0).padding(-6))
            .background(Circle().fill(Color.ink).offset(y: 4))
            .overlay(alignment: .topTrailing) {
                if done {
                    Image(systemName: "star.fill").font(.system(size: 10.s, weight: .black)).foregroundStyle(Color.sun)
                        .padding(3.s).background(Circle().fill(Color.ink))
                        .offset(x: 6.s, y: -6.s)
                }
            }
        }
        .buttonStyle(.plain)
    }

    /// the region's name in a white pill, beside the pin
    private func label(_ ch: Int, k: CGFloat, align: Alignment) -> some View {
        let name = KJC1.chapterNames[ch]?.ja ?? ""
        // the long names go on two lines at the ・ (ちゅうごく / しこく)
        let text = name.replacingOccurrences(of: "・", with: "・\n")
        return Text(text)
            .font(.custom(Fonts.rounded, size: 13.s * k)).foregroundStyle(Color.ink)
            .multilineTextAlignment(align == .leading ? .leading : align == .trailing ? .trailing : .center)
            .lineSpacing(-2)
            .fixedSize()
            .padding(.horizontal, 8 * k).padding(.vertical, 3 * k)
            .background(RoundedRectangle(cornerRadius: 12 * k).fill(.white)
                .overlay(RoundedRectangle(cornerRadius: 12 * k).stroke(Color.ink, lineWidth: 2.5))
                .background(RoundedRectangle(cornerRadius: 12 * k).fill(Color.ink).offset(y: 3)))
            // grow away from the pin
            .fixedSize()
            .frame(width: 1, height: 1, alignment: align)
            .onTapGesture { select(ch) }
    }

    // MARK: the card under the map

    private var course: [KJC1.Stage] { KJC1.stages(in: chapter) }
    private var nextStage: KJC1.Stage? {
        course.first { KJC1.unlocked($0.id) && KJC1.stars($0.id) == 0 } ?? (open(chapter) ? course.first : nil)
    }
    private var bossImage: String { course.last { $0.kind == .boss }?.bossImage ?? "boss_kyubi" }
    /// the letters this region teaches: "は〜ろ"
    private var lettersNote: String {
        let ls = course.filter { $0.kind == .lesson }.flatMap(\.newKana)
        guard let a = ls.first, let b = ls.last else { return "" }
        return a == b ? a : "\(a)〜\(b)"
    }

    private var card: some View {
        let ok = open(chapter)
        let done = cleared(chapter)
        return PaperCard {
            VStack(spacing: 8.s) {
                HStack(spacing: 12.s) {
                    Image(bossImage).resizable().scaledToFit()
                        .frame(width: 84.s, height: 84.s)
                        .saturation(ok ? 1 : 0).opacity(ok ? 1 : 0.5)
                    VStack(alignment: .leading, spacing: 2.s) {
                        Text("だい\(chapter)しょう　\(KJC1.chapterNames[chapter]?.ja ?? "")")
                            .font(.display(20.s)).foregroundStyle(Color.ink)
                            .lineLimit(1).minimumScaleFactor(0.55)
                        Text(KJC1.chapterName(chapter) + (lettersNote.isEmpty ? "" : "｜" + lettersNote))
                            .font(.ui(12.s)).foregroundStyle(Color.ink.opacity(0.6))
                            .lineLimit(1).minimumScaleFactor(0.7)
                        Text(KJ.t("\(done) / \(course.count) cleared", "\(done) / \(course.count) 過關", "\(done) / \(course.count) 클리어"))
                            .font(.ui(12.s)).foregroundStyle(Color.ink.opacity(0.6))
                    }
                    Spacer(minLength: 0)
                }
                PopButton(title: playTitle(ok: ok, done: done), color: ok ? .sun : Color(hex: 0xE6E2F0), height: 58) {
                    guard ok, let s = nextStage else { AudioManager.shared.se(.wrong, volume: 0.5); return }
                    AudioManager.shared.se(.decide)
                    play(s.id)
                }
                PopButton(title: KJ.t("Choose a stage", "選擇關卡", "스테이지 고르기"), color: .white, height: 46) {
                    guard ok else { AudioManager.shared.se(.wrong, volume: 0.5); return }
                    AudioManager.shared.se(.tap)
                    openCourse()
                }
            }
        }
    }

    private func playTitle(ok: Bool, done: Int) -> String {
        guard ok else { return KJ.t("Clear the region before", "通關前一個地區後開放", "앞 지역을 클리어하면 열려요") }
        let st = nextStage.map { "  " + KJC1.label($0.id) } ?? ""
        return "▶ " + (done == 0 ? KJ.t("Start", "開始", "시작") : KJ.t("Continue", "繼續", "이어서")) + st
    }
}

/// にゃんカナ: each region has its own music (bgm_kj1 … bgm_kj7)
enum KJMusic {
    static var chapter = 1
    static func play(_ ch: Int? = nil) {
        if let ch { chapter = max(1, min(7, ch)) }
        AudioManager.shared.playBGM(.track("kj\(chapter)"))
    }
}
