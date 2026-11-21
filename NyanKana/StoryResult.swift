import SwiftUI

/// Story scene: full-screen background, characters on both sides, English line + subtitle.
struct StoryView: View {
    let lines: [StoryLine]
    let background: String
    var done: () -> Void
    @EnvironmentObject var settings: SettingsStore
    @State private var i = 0
    @State private var pop = false

    private var line: StoryLine { lines[min(i, lines.count - 1)] }
    private var leftCast: Cast? { lines.prefix(i + 1).last { $0.who.leftSide }?.who }
    private var rightCast: Cast? { lines.prefix(i + 1).last { !$0.who.leftSide }?.who }

    var body: some View {
        ZStack {
            // the picture fills the screen but never sets the layout size (it used to push the text box off iPad screens)
            GeometryReader { g in
                Image(background).resizable().scaledToFill()
                    .frame(width: g.size.width, height: g.size.height).clipped()
            }
            .ignoresSafeArea()
            LinearGradient(colors: [.clear, Color.ink.opacity(0.35)], startPoint: .center, endPoint: .bottom).ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    smallButton(settings.subtitles ? L("story.subOn") : L("story.subOff")) { settings.subtitles.toggle() }
                    smallButton("SKIP ▶▶") { finish() }
                }
                .padding(.horizontal, 14.s).padding(.top, 10.s)
                Spacer()
                // each side gets its own part of the width, so nobody overlaps or runs off the screen.
                // With a boss on screen the boss gets ~60% and the kids are drawn a little smaller.
                GeometryReader { g in
                    let bossR = rightCast?.isBoss == true
                    let leftW = g.size.width * (bossR ? 0.4 : 0.5)
                    let rightW = g.size.width - leftW
                    HStack(alignment: .bottom, spacing: 0) {
                        character(leftCast, active: line.who.leftSide, width: leftW, height: g.size.height, kidScale: bossR ? 0.82 : 1)
                            .frame(width: leftW, height: g.size.height, alignment: .bottom)
                        character(rightCast, active: !line.who.leftSide, width: rightW, height: g.size.height, kidScale: 1)
                            .frame(width: rightW, height: g.size.height, alignment: .bottom)
                    }
                }
                .padding(.horizontal, 6.s)
                .frame(maxHeight: UIScale.isPad ? 620 : 400)
                dialog
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { advance() }
        .onAppear { speak() }
    }

    private func character(_ c: Cast?, active: Bool, width: CGFloat, height: CGFloat, kidScale: CGFloat) -> some View {
        Group {
            if let c {
                let base: CGFloat = UIScale.isPad ? 520 : 330
                Image(c.image).resizable().scaledToFit()
                    .frame(maxWidth: width, maxHeight: min(height, base * c.storyScale * (c.isBoss ? 1 : kidScale)), alignment: .bottom)
                    .scaleEffect(active ? (pop ? 1.03 : 1) : 0.98, anchor: .bottom)
                    .saturation(active ? 1 : 0.7)
                    .opacity(active ? 1 : 0.85)
                    .shadow(color: .ink.opacity(0.3), radius: 0, x: 4, y: 4)
                    .animation(.spring(response: 0.25, dampingFraction: 0.5), value: pop)
                    .animation(.easeOut(duration: 0.2), value: active)
            }
        }
    }

    private var dialog: some View {
        VStack(alignment: .leading, spacing: 8.s) {
            HStack {
                Text(line.who.name).font(.en(17.s)).foregroundStyle(.white)
                    .padding(.horizontal, 14.s).padding(.vertical, 4.s)
                    .background(Capsule().fill(line.who.leftSide ? Color.sky : Color.pop).overlay(Capsule().stroke(Color.ink, lineWidth: 3)))
                Spacer()
                Button { speak() } label: {
                    Image(systemName: "speaker.wave.2.fill").font(.system(size: 17.s, weight: .bold)).foregroundStyle(Color.ink)
                        .frame(width: 40.s, height: 34.s)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.sun).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.ink, lineWidth: 2.5)))
                }
                .buttonStyle(.plain)
            }
            Text(line.en).font(.en(24.s)).foregroundStyle(Color.ink).fixedSize(horizontal: false, vertical: true)
            if settings.subtitles {
                Text(jp(line.sub)).font(.ui(15.s, bold: false)).foregroundStyle(Color.ink.opacity(0.7)).fixedSize(horizontal: false, vertical: true)
            }
            HStack {
                Spacer()
                Text("\(i + 1)/\(lines.count)  ▼").font(.en(12.s)).foregroundStyle(Color.ink.opacity(0.5))
            }
        }
        .padding(18.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 22).fill(Color.paper).overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.ink, lineWidth: 4)))
        .background(RoundedRectangle(cornerRadius: 22).fill(Color.ink).offset(y: 6))
        .padding(.horizontal, 14.s)
        .padding(.bottom, 14.s)
        .frame(maxWidth: UIScale.isPad ? 820 : .infinity)
    }

    private func smallButton(_ t: String, _ a: @escaping () -> Void) -> some View {
        Button(action: a) {
            Text(t).font(.ui(12.s)).foregroundStyle(Color.ink)
                .padding(.horizontal, 12.s).padding(.vertical, 6.s)
                .background(Capsule().fill(Color.white).overlay(Capsule().stroke(Color.ink, lineWidth: 2.5)))
        }
        .buttonStyle(.plain)
    }

    private func advance() {
        AudioManager.shared.se(.tap, rate: 1.5, volume: 0.4)
        if i + 1 >= lines.count { finish(); return }
        i += 1
        pop.toggle()
        speak()
    }

    private func speak() { Speaker.shared.say(line.en, voice: line.who.voice) }
    private func finish() { Speaker.shared.stop(); done() }
}

/// Result: rank, score, words to remember, and where to go next.
struct ResultView: View {
    @ObservedObject var m: GameModel
    @EnvironmentObject var app: AppState
    @State private var show = false

    var body: some View {
        ZStack {
            if m.cleared { Sunburst().ignoresSafeArea() } else { Color(hex: 0x4A4870).ignoresSafeArea(); Dots(color: .white.opacity(0.12)).ignoresSafeArea() }
            // everything on one screen: shrink step by step, scroll only as the very last resort
            ViewThatFits(in: .vertical) {
                content(0)
                content(1)
                content(2)
                ScrollView { content(2) }
            }
        }
        .onAppear { withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) { show = true } }
    }

    @ViewBuilder private func content(_ level: Int) -> some View {
        let tight = level > 0
        VStack(spacing: (tight ? 9 : 14).s) {
            OutlinedText(m.cleared ? "STAGE CLEAR!" : "GAME OVER", font: .en((level == 0 ? 42 : level == 1 ? 36 : 30).s), fill: m.cleared ? .sun : .white)
                .scaleEffect(show ? 1 : 0.3).rotationEffect(.degrees(show ? -3 : -20))
                .padding(.top, (level == 0 ? 24 : 10).s)
            if !m.cleared {
                if tight {
                    HStack(spacing: 10.s) {
                        Image("nyan").resizable().scaledToFit().frame(height: (level == 1 ? 60 : 48).s)
                        Text(jp(L("res.overNote"))).font(.ui(14.s)).foregroundStyle(.white).fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: 460.s)
                } else {
                    Image("nyan").resizable().scaledToFit().frame(height: 90.s)
                    Text(jp(L("res.overNote"))).font(.ui(15.s)).foregroundStyle(.white).multilineTextAlignment(.center)
                }
            }
            PaperCard {
                VStack(spacing: (tight ? 8 : 10).s) {
                    if m.cleared {
                        HStack(spacing: 18.s) {
                            Text(m.rank).font(.en((tight ? 48 : 64).s)).foregroundStyle(Color.popDeep)
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 2) { ForEach(0..<3, id: \.self) { s in Image(systemName: s < m.stars ? "star.fill" : "star").foregroundStyle(Color.sunDeep) } }
                                    .font(.system(size: 22.s, weight: .black))
                                if m.newBest { Text("NEW BEST!").font(.en(14.s)).foregroundStyle(Color.mintDeep) }
                            }
                        }
                    }
                    if tight {
                        HStack(spacing: 6.s) {
                            stat(L("res.score"), "\(m.score)")
                            stat(L("res.combo"), "\(m.maxCombo)")
                            stat(L("res.correct"), "\(m.correctCount)")
                        }
                    } else {
                        row(L("res.score"), "\(m.score)")
                        row(L("res.combo"), "\(m.maxCombo)")
                        row(L("res.correct"), "\(m.correctCount)")
                    }
                    if !m.missed.isEmpty {
                        Divider()
                        Text(L("res.missed")).font(.ui(14.s)).foregroundStyle(Color.ink).frame(maxWidth: .infinity, alignment: .leading)
                        ForEach(Array(m.missed.prefix(level == 0 ? 5 : level == 1 ? 3 : 2).enumerated()), id: \.offset) { _, q in
                            Button { Speaker.shared.say(q.full) } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(q.full).font(.en((tight ? 14 : 16).s)).foregroundStyle(Color.ink).lineLimit(2).minimumScaleFactor(0.8)
                                        if level < 2 { Text(jp(q.meaning)).font(.ui(11.s, bold: false)).foregroundStyle(Color.ink.opacity(0.6)).lineLimit(1) }
                                    }
                                    Spacer()
                                    Image(systemName: "speaker.wave.2.fill").foregroundStyle(Color.sky)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .frame(maxWidth: 460.s)
            VStack(spacing: (tight ? 8 : 10).s) {
                if m.cleared, let next = m.nextStage {
                    PopButton(title: L("res.next"), color: .pop, textColor: .white) { AdManager.shared.roundFinished(); app.go(.game(next)) }
                }
                HStack(spacing: 10.s) {
                    PopButton(title: L("res.study"), color: .mint) { app.go(.study) }
                    PopButton(title: L("res.retry"), color: .white) { AudioManager.shared.se(.tap); AdManager.shared.roundFinished(); m.restart() }
                }
                HStack(spacing: 10.s) {
                    PopButton(title: L("res.map"), color: .sky) { AdManager.shared.roundFinished(); app.goStageList() }
                    PopButton(title: L("common.home"), color: .sun) { AdManager.shared.roundFinished(); app.go(.home) }
                }
            }
            .frame(maxWidth: 460.s)
        }
        .padding(.horizontal, 18.s)
        .padding(.bottom, (tight ? 12 : 30).s)
    }

    private func stat(_ k: String, _ v: String) -> some View {
        VStack(spacing: 1) {
            Text(k).font(.ui(11.s)).foregroundStyle(Color.ink.opacity(0.65)).lineLimit(1).minimumScaleFactor(0.7)
            Text(v).font(.en(20.s)).foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack { Text(k).font(.ui(15.s)).foregroundStyle(Color.ink.opacity(0.7)); Spacer(); Text(v).font(.en(22.s)).foregroundStyle(Color.ink) }
    }
}
