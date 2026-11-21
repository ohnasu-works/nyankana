import SwiftUI
import UIKit

/// The island map of Wordia. Pick an area, then a stage and a difficulty.
struct StageMapView: View {
    @EnvironmentObject var app: AppState
    @EnvironmentObject var settings: SettingsStore
    @State private var selected: Area = .lv1
    @State private var showStages = false

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // map, fitted above the bottom sheet
                mapPicture
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(-1)          // the map shrinks; the card below always fits
                sheet
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                    .frame(maxWidth: UIScale.isPad ? 640 : .infinity)
                AdBannerSlot()      // free version only
            }
            .background(Color(hex: 0xA8E4F2).ignoresSafeArea())
            .overlay(alignment: .topLeading) { BackChip { app.go(.home) }.padding(.leading, 14).padding(.top, 6) }
        }
        .fullScreenCover(isPresented: $showStages) { StageListView(area: selected) }
        .onAppear {
            AudioManager.shared.playBGM(.home)
            Task { await AdManager.shared.start() }
            // open where you played last; straight to its stage list when coming back from a stage
            if app.isUnlocked(app.lastArea) { selected = app.lastArea }
            if app.openStageList { app.openStageList = false; showStages = true }
        }
    }

    /// The wide map (island in the middle, sea and small islands on both sides) fills the area.
    /// Island node positions are given on the original island picture, which sits at x 226…798 of 1024.
    private var mapPicture: some View {
        GeometryReader { g in
            // square picture that fills the area, but never so big that the island (about 8%…94% of the
            // picture's height) is cut at the top or bottom — on iPad the sea simply shows at the sides
            let side = min(max(g.size.width, g.size.height), g.size.height / 0.9)
            let px = { (x: CGFloat) in side * (226 + x * 572) / 1024 }
            let nodeScale = min(1, g.size.height / 560)
            ZStack(alignment: .topLeading) {
                MapPicture.image.resizable().frame(width: side, height: side)
                ForEach(Area.allCases) { area in
                    let c = CGPoint(x: px(area.mapPoint.x), y: side * area.mapPoint.y)
                    mapLabel(area, center: c, scale: nodeScale, left: (side - g.size.width) / 2, width: g.size.width)
                    node(area).scaleEffect(nodeScale).position(c)
                }
                Image("nyan").resizable().scaledToFit().frame(width: side * 0.07)
                    // above the circle; at the castle (top edge) Nyan stands beside it instead
                    .position(x: px(selected.mapPoint.x) - (selected == .graduation ? side * 0.075 : 0),
                              y: side * selected.mapPoint.y - (selected == .graduation ? side * 0.01 : side * 0.075))
                    .hop(6, period: 0.45)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selected)
            }
            .frame(width: side, height: side)
            .position(x: g.size.width / 2, y: g.size.height / 2)
        }
        .overlay(alignment: .topLeading) {
            // the logo sits under the back button, away from the stage names
            // the small reading goes above the logo so it never runs into the area-5 name below
            VStack(alignment: .leading, spacing: -2) {
                // the small reading only where it is not just "Wordia" again
                if L10n.current == .ja || L10n.current == .ko || L10n.current == .zhHant {
                    OutlinedText(L("map.title"), font: .ui(11.s), width: 2.5, shadow: 0).padding(.leading, 6)
                }
                OutlinedText("WORDIA", font: .custom(Fonts.display, size: 22.s), fill: .sun, width: 3.5, shadow: 3)
            }
            .rotationEffect(.degrees(-4))
            .padding(.leading, 16).padding(.top, 46.s + (UIScale.isPad ? 30 : 0))   // iPad: the back button sits 30 lower
            .allowsHitTesting(false)
        }
    }

    private func node(_ area: Area) -> some View {
        let open = app.isUnlocked(area)
        return Button {
            AudioManager.shared.se(.decide, rate: 1.2, volume: 0.6)
            withAnimation { selected = area }
        } label: {
            VStack(spacing: 2) {
                Group {
                    if open { Text(area.badge).font(.en(20.s)) } else { UIIcon("ui_lock|🔒", size: 16.s) }
                }
                    .foregroundStyle(open ? Color.white : Color.ink)
                    .frame(width: 42.s, height: 42.s)
                    .background(Circle().fill(open ? Color.pop : Color(hex: 0xD9D4EA)))
                    .overlay(Circle().stroke(Color.ink, lineWidth: 4))
                    .overlay(Circle().stroke(Color.sun, lineWidth: area == selected ? 4 : 0).padding(-6))
                    .background(Circle().fill(Color.ink).offset(y: 4))
            }
        }
        .buttonStyle(.plain)
    }

    /// Where each area's name goes: beside the circle, on the sea side; the middle ones go below.
    private enum LabelSide { case left, right, below }
    private func labelSide(_ a: Area) -> LabelSide {
        switch a {
        // (with the smaller common font the castle's name fits below it without touching area 6;
        // on its left it ran into the back button in longer languages)
        case .graduation: return .below
        case .lv3, .lv5: return .left
        default: return .right
        }
    }

    /// The name split in two lines at a natural point ("ロジック／研究所", "로직／연구소").
    private func twoLines(_ name: String) -> String? {
        if L10n.current == .ja {
            for suf in ["研究所", "通り", "広場", "花園"] where name.hasSuffix(suf) && name.count > suf.count + 1 {
                return String(name.dropLast(suf.count)) + "\n" + suf
            }
            return nil
        }
        if let r = name.range(of: " ", options: .backwards) { return name.replacingCharacters(in: r, with: "\n") }
        return name.count >= 4 ? String(name.dropLast(2)) + "\n" + String(name.suffix(2)) : nil
    }

    @ViewBuilder
    private func mapLabel(_ area: Area, center c: CGPoint, scale k: CGFloat, left: CGFloat, width: CGFloat) -> some View {
        // one size for every name (no shrinking to fit): long names go on two lines instead
        let font = Font.ui(16.s * k)
        let r = 25.s * k                     // circle radius + ring
        let pill = { (t: String) in
            Text(t).font(font).foregroundStyle(Color.ink).multilineTextAlignment(.center)
                .lineSpacing(-1)
                .padding(.horizontal, 9 * k).padding(.vertical, 3 * k)
                .background(RoundedRectangle(cornerRadius: 14 * k).fill(.white)
                    .overlay(RoundedRectangle(cornerRadius: 14 * k).stroke(Color.ink, lineWidth: 2.5))
                    .background(RoundedRectangle(cornerRadius: 14 * k).fill(Color.ink).offset(y: 3)))
                .contentShape(Rectangle())
                .onTapGesture {
                    AudioManager.shared.se(.decide, rate: 1.2, volume: 0.6)
                    withAnimation { selected = area }
                }
        }
        let name = area.name
        let label = ViewThatFits(in: .horizontal) {
            pill(name).fixedSize()
            if let two = twoLines(name) { pill(two).fixedSize() }
            pill(twoLines(name) ?? name).fixedSize()
        }
        switch labelSide(area) {
        case .below:
            label.frame(width: min(width - 16, 320.s)).position(x: c.x, y: c.y + r + 22.s * k)
        case .right:
            let x0 = c.x + r + 4, avail = max(60, left + width - 8 - x0)
            label.frame(width: avail, alignment: .leading).position(x: x0 + avail / 2, y: c.y)
        case .left:
            let x1 = c.x - r - 4, avail = max(60, x1 - left - 8)
            label.frame(width: avail, alignment: .trailing).position(x: x1 - avail / 2, y: c.y)
        }
    }

    /// "ST.16" / "BOSS" / "MID" for the stage the continue button starts
    private var continueLabel: String {
        let next = min(app.progress.clearedStages(in: selected) + 1, selected.stageCount)
        if next == selected.stageCount { return "BOSS" }
        return next % 10 == 0 ? "ST.\(next) MID" : "ST.\(next)"
    }

    private var sheet: some View {
        let open = app.isUnlocked(selected)
        return PaperCard {
            VStack(spacing: 8.s) {
                HStack(spacing: 12) {
                    Group {
                        if let img = selected.bossImage { Image(img).resizable().scaledToFit() }
                        else { Image("gob_03").resizable().scaledToFit().colorMultiply(.black).opacity(0.25) }
                    }
                    .frame(width: 84.s, height: 84.s)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(selected.levelLabel)　\(selected.name)").font(.display(20.s)).foregroundStyle(Color.ink)
                            .lineLimit(1).minimumScaleFactor(0.55)
                        Text(jp(selected.grammarHint)).font(.ui(12.s)).foregroundStyle(Color.ink.opacity(0.6))
                            .lineLimit(1).minimumScaleFactor(0.7)
                        HStack(alignment: .bottom) {
                            Text(L("map.cleared", app.progress.clearedStages(in: selected), selected.stageCount)).font(.ui(12.s)).foregroundStyle(Color.ink.opacity(0.6))
                            Spacer(minLength: 4)
                            AnswerModePicker()   // one small button: the map keeps its full size
                        }
                    }
                    Spacer(minLength: 0)
                }
                DifficultyPicker()
                PopButton(title: open ? "▶ " + L(app.progress.clearedStages(in: selected) == 0 ? "map.first" : "map.start") + "  " + continueLabel : L("common.locked"), color: open ? .sun : Color(hex: 0xE6E2F0), height: 58) {
                    guard open else { return }
                    AudioManager.shared.se(.decide)
                    let next = min(app.progress.clearedStages(in: selected) + 1, selected.stageCount)
                    app.go(.game(StageRef(area: selected, index: next, difficulty: settings.difficulty)))
                }
                PopButton(title: L("map.stages"), color: .white, height: 46) { if open { AudioManager.shared.se(.tap); showStages = true } }
            }
        }
    }
}

/// How to answer: one small button (tap to choose), so the map keeps its size.
struct AnswerModePicker: View {
    @EnvironmentObject var settings: SettingsStore
    var body: some View {
        Menu {
            ForEach(AnswerMode.allCases) { m in
                Button {
                    AudioManager.shared.se(.decide, rate: 1.3, volume: 0.5)
                    settings.answerMode = m
                } label: {
                    Label(m.title, systemImage: settings.answerMode == m ? "checkmark" : m.icon)
                }
            }
        } label: {
            VStack(spacing: 1) {
                Text(jp(T("答え方", "답하기", "作答"))).font(.ui(11.s)).foregroundStyle(Color.ink.opacity(0.6))
                HStack(spacing: 3) {
                    Image(systemName: settings.answerMode.icon).font(.system(size: 13.s, weight: .bold))
                    Text(settings.answerMode.title).font(.ui(13.s)).lineLimit(1).minimumScaleFactor(0.6)
                    Image(systemName: "chevron.down").font(.system(size: 10.s, weight: .black))
                }
                .foregroundStyle(Color.ink)
            }
            .padding(.horizontal, 10.s).padding(.vertical, 5.s)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: 0xBFD7FF)).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.ink, lineWidth: 2)))
        }
    }
}

/// EASY / NORMAL / HARD with the best rank of each.
struct DifficultyPicker: View {
    @EnvironmentObject var settings: SettingsStore
    var body: some View {
        HStack(spacing: 8) {
            ForEach(Difficulty.allCases) { d in
                Button {
                    AudioManager.shared.se(.decide, rate: 1.3, volume: 0.5)
                    settings.difficulty = d
                } label: {
                    VStack(spacing: 2) {
                        Text(d.title).font(.en(22.s))
                        Text(jp(d.note)).font(.ui(13.s)).multilineTextAlignment(.center).lineLimit(3).minimumScaleFactor(0.55).padding(.horizontal, 4)
                    }
                    .foregroundStyle(Color.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: 74.s)
                    .background(RoundedRectangle(cornerRadius: 14).fill(settings.difficulty == d ? color(d) : .white))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.ink, lineWidth: 3))
                }
                .buttonStyle(PressStyle(radius: 14, depth: 4))
            }
        }
    }
    private func color(_ d: Difficulty) -> Color {
        switch d { case .easy: Color(hex: 0xBFF0C4); case .normal: Color(hex: 0xFFE27A); case .hard: Color(hex: 0xFFB3CF) }
    }
}

/// Stage list for one area (30 stages laid out as a path).
/// Stage select as a winding course (board-game style): road, stage stones, stars, bosses.
struct StageListView: View {
    @EnvironmentObject var app: AppState
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.dismiss) var dismiss
    var area: Area

    private let perRow = 4
    private var rowH: CGFloat { 118.s }

    private var nextStage: Int { min(app.progress.clearedStages(in: area) + 1, area.stageCount) }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0xBFEFFF), Color(hex: 0x9EE6C8)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            GeometryReader { g in
                Image(scenery).resizable().scaledToFill().frame(width: g.size.width, height: g.size.height).clipped()
            }
            .ignoresSafeArea()
            Color.white.opacity(0.28).ignoresSafeArea()
            Dots(color: .white.opacity(0.35), gap: 24, radius: 2.4).ignoresSafeArea()
            VStack(spacing: 0) {
                header
                GeometryReader { g in
                    ScrollViewReader { proxy in
                        ScrollView {
                            course(width: min(g.size.width, 620))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20.s)
                        }
                        .onAppear {
                            // show the current stage from its top (stage 1 → the very top of the course)
                            DispatchQueue.main.async { proxy.scrollTo(nextStage, anchor: .top) }
                        }
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            // back at the top left, the title beside it (never under it): shorter / smaller when the name is long
            HStack(spacing: 8) {
                BackChip { dismiss() }
                ViewThatFits(in: .horizontal) {
                    RibbonTitle(text: "\(area.levelLabel)  \(area.name)", color: .pop)
                    RibbonTitle(text: area.name, color: .pop)
                    RibbonTitle(text: area.name, color: .pop, size: 19)
                    RibbonTitle(text: area.name, color: .pop, size: 15)
                }
                .frame(maxWidth: .infinity)
            }
            // difficulty (EASY / NORMAL / HARD) at the top right, under the title.
            // It is part of the fixed header, so the scrolling course starts below it and never covers it.
            HStack(spacing: 8) {
                Spacer()
                AnswerModePicker()   // change how to answer right before choosing a stage
                Text(settings.difficulty.title).font(.en(15.s)).foregroundStyle(Color.ink)
                    .padding(.horizontal, 12).padding(.vertical, 3)
                    .background(Capsule().fill(Color.sun).overlay(Capsule().stroke(Color.ink, lineWidth: 2.5)))
            }
        }
        .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 4)
        .zIndex(1)
    }

    /// Every area lays its course out differently (town blocks, circuit, parade wave, hotel stairs, river, gears, castle climb).
    private func layout(_ w: CGFloat) -> [CGPoint] {
        let n = area.stageCount, m: CGFloat = 50.s, inner = w - m * 2
        var p: [CGPoint] = []
        for k in 0..<n {
            let d = Double(k)
            switch area {
            case .lv1:      // town blocks: snake, 4 a row
                let row = k / 4, col = k % 4, c = row % 2 == 0 ? col : 3 - col
                p.append(CGPoint(x: m + CGFloat(c) * inner / 3, y: CGFloat(row) * 118.s + 60.s + (col % 2 == 0 ? 0 : 14.s)))
            case .lv2:      // circuit: sharp zigzag, 3 a row, sloping
                let row = k / 3, col = k % 3, c = row % 2 == 0 ? col : 2 - col
                p.append(CGPoint(x: m + CGFloat(c) * inner / 2, y: CGFloat(row) * 150.s + 60.s + CGFloat(col) * 24.s))   // rows far enough apart that stones never overlap
            case .lv3:      // festival parade: a soft wave
                p.append(CGPoint(x: w / 2 + CGFloat(sin(d * 0.75)) * inner * 0.42, y: CGFloat(k) * 64.s + 60.s))
            case .lv4:      // hotel: stairs going right, then left
                let s = k % 8, c = s < 4 ? s : 7 - s
                p.append(CGPoint(x: m + CGFloat(c) * inner / 3, y: CGFloat(k) * 70.s + 60.s))
            case .lv5:      // garden river: wide and narrow bends
                let amp = 0.25 + 0.17 * sin(d * 0.21)
                p.append(CGPoint(x: w / 2 + CGFloat(sin(d * 0.55) * amp) * inner, y: CGFloat(k) * 66.s + 60.s))
            case .lv6:      // lab: half gears, right and left in turn (an S of pipes, never crossing)
                let g = k / 5, j = k % 5
                let ry: CGFloat = 92.s, rx = inner * 0.42
                let cy = CGFloat(g) * (ry * 2 + 56.s) + ry + 60.s
                let ang = -Double.pi / 2 + Double(j) / 4.0 * Double.pi
                let side: CGFloat = g % 2 == 0 ? 1 : -1
                p.append(CGPoint(x: w / 2 + side * CGFloat(cos(ang)) * rx, y: cy + CGFloat(sin(ang)) * ry))
            case .graduation: // castle: climbing up from the bottom
                p.append(CGPoint(x: w / 2 + (k % 2 == 0 ? -1 : 1) * inner * 0.3, y: CGFloat(n - 1 - k) * 96.s + 70.s))
            }
        }
        return p
    }

    private var roadColor: Color {
        switch area {
        case .lv1: Color(hex: 0xFFF1C9)
        case .lv2: Color(hex: 0xCFF3FF)
        case .lv3: Color(hex: 0xFFE0F0)
        case .lv4: Color(hex: 0xFFF6DD)
        case .lv5: Color(hex: 0xE4F6C6)
        case .lv6: Color(hex: 0xE6DCFF)
        case .graduation: Color(hex: 0xEDE7F6)
        }
    }

    /// the area's scenery behind the course
    private var scenery: String { area == .lv1 ? "bg_intro" : "bg_\(area.rawValue)_intro" }

    private func course(width w: CGFloat) -> some View {
        let pts = layout(w)
        let h = (pts.map(\.y).max() ?? 0) + 80.s
        return ZStack(alignment: .topLeading) {
            // the road: a smooth curve through every stage
            Canvas { ctx, _ in
                var road = Path()
                road.move(to: pts[0])
                for i in 1..<pts.count {
                    let p0 = pts[max(0, i - 2)], p1 = pts[i - 1], p2 = pts[i], p3 = pts[min(pts.count - 1, i + 1)]
                    let c1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6)
                    let c2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)
                    road.addCurve(to: p2, control1: c1, control2: c2)
                }
                ctx.stroke(road, with: .color(Color.ink), style: StrokeStyle(lineWidth: 30.s, lineCap: .round, lineJoin: .round))
                ctx.stroke(road, with: .color(roadColor), style: StrokeStyle(lineWidth: 22.s, lineCap: .round, lineJoin: .round))
                ctx.stroke(road, with: .color(Color.ink.opacity(0.25)), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [8, 10]))
            }
            .frame(width: w, height: h)
            ForEach(1...area.stageCount, id: \.self) { i in
                // stones with an event label sit on top so the label is never hidden by the next stone
                stone(i).position(pts[i - 1]).zIndex(StageEvent.at(i, of: area.stageCount) != nil ? 1 : 0)
            }
            // small scroll anchors a little above each stone (a .position'ed view fills the whole course, so it can't be the target)
            ForEach(1...area.stageCount, id: \.self) { i in
                Color.clear.frame(width: 1, height: 1)
                    .offset(x: pts[i - 1].x, y: max(0, pts[i - 1].y - 90.s))
                    .id(i)
            }
        }
        .frame(width: w, height: h)
    }

    @ViewBuilder private func stone(_ i: Int) -> some View {
        let open = app.isUnlocked(stage: i, in: area)
        let res = app.progress.results[ProgressStore.key(StageRef(area: area, index: i, difficulty: settings.difficulty))]
        let isBoss = i == area.stageCount
        let isMid = i % 10 == 0 && !isBoss
        let isNext = i == nextStage && open
        let size: CGFloat = (isBoss ? 84 : isMid ? 72 : 58).s
        Button {
            guard open else { AudioManager.shared.se(.wrong, volume: 0.5); return }
            AudioManager.shared.se(.decide)
            dismiss()
            app.go(.game(StageRef(area: area, index: i, difficulty: settings.difficulty)))
        } label: {
            ZStack {
                Circle().fill(Color.ink).offset(y: 5).frame(width: size, height: size)
                Circle().fill(!open ? Color(hex: 0xD9D4EA) : isBoss ? Color(hex: 0xFF8FC0) : isMid ? Color(hex: 0xC3A6FF) : res != nil ? Color.sun : Color.white)
                    .overlay(Circle().stroke(Color.ink, lineWidth: 4))
                    .frame(width: size, height: size)
                if isBoss || isMid {
                    Image(isBoss ? area.boss.image : area.mid(i).image).resizable().scaledToFit()
                        .frame(width: size * 0.92, height: size * 0.92)
                        .saturation(open ? 1 : 0).opacity(open ? 1 : 0.6)
                        .offset(y: -6.s)
                } else if open {
                    Text("\(i)").font(.en(24.s)).foregroundStyle(Color.ink)
                } else {
                    Image(systemName: "lock.fill").font(.system(size: 20.s, weight: .bold)).foregroundStyle(Color.ink.opacity(0.45))
                }
                if isNext {
                    Circle().stroke(Color.popDeep, style: StrokeStyle(lineWidth: 4, dash: [6, 5]))
                        .frame(width: size + 14, height: size + 14)
                        .modifier(Spin())
                }
            }
            .frame(width: size + 16, height: size + 16)
            // event stages: a small picture of what waits there
            .overlay(alignment: .topTrailing) {
                if !isBoss && !isMid, let ev = StageEvent.at(i, of: area.stageCount), ev != .lucky {   // lucky (rare) stays a surprise
                    Image(ev.image).resizable().scaledToFit().frame(width: 40.s, height: 40.s)
                        .padding(2).background(Circle().fill(Color.white).overlay(Circle().stroke(Color.ink, lineWidth: 2)))
                        .saturation(open ? 1 : 0)
                        .offset(x: 8.s, y: -8.s)
                }
            }
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            VStack(spacing: 1) {
                if isBoss || isMid {
                    Text(isBoss ? "BOSS" : "\(i)").font(.en(11.s)).foregroundStyle(.white)
                        .padding(.horizontal, 7).background(Capsule().fill(isBoss ? Color.popDeep : Color.grape).overlay(Capsule().stroke(Color.ink, lineWidth: 2)))
                }
                if let res, res.stars > 0 {
                    HStack(spacing: 0) {
                        ForEach(0..<3, id: \.self) { k in
                            Image(systemName: "star.fill").font(.system(size: 11.s, weight: .black))
                                .foregroundStyle(k < res.stars ? Color.sunDeep : Color.ink.opacity(0.2))
                        }
                    }
                    .padding(.horizontal, 4).background(Capsule().fill(Color.white.opacity(0.9)))
                }
            }
            .offset(y: 16.s)
        }
        .overlay(alignment: .top) {
            if isNext {
                Image("nyan").resizable().scaledToFit().frame(width: 40.s)
                    .offset(y: -30.s).hop(6, period: 0.45)
            }
        }
    }
}

/// slow rotation for the "next stage" ring
struct Spin: ViewModifier {
    @State private var on = false
    func body(content: Content) -> some View {
        content.rotationEffect(.degrees(on ? 360 : 0))
            .onAppear { withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) { on = true } }
    }
}


/// The big map picture is decoded ahead of time (from the home screen), so it slides in together with
/// its labels instead of popping in a moment later.
enum MapPicture {
    private static let decoded: UIImage? = UIImage(named: "map_wide")?.preparingForDisplay()
    static var image: Image { decoded.map { Image(uiImage: $0) } ?? Image("map_wide") }
    static func warmUp() { _ = decoded }
}
