import SwiftUI
import SceneKit
import UIKit
import GameController

/// Game screen: 3D street on top, answer panel below. Items sit at the bottom right of the street
/// view so they are easy to reach with a thumb.
struct GameScreen: View {
    @EnvironmentObject var app: AppState
    @EnvironmentObject var dev: DevSettings
    @EnvironmentObject var settings: SettingsStore
    @StateObject private var m: GameModel

    init(stage: StageRef) { _m = StateObject(wrappedValue: GameModel(ref: stage)) }

    var body: some View {
        ZStack {
            GeometryReader { g in
                // iPad / Mac in landscape: the answers sit beside the street, on the hand you use
                let wide = g.size.width > g.size.height * 1.15
                let left = AppState.shared.settings.leftHanded
                if wide {
                    HStack(spacing: 0) {
                        if left { AnswerPanel(m: m, side: .left).frame(width: min(480, g.size.width * 0.4)) }
                        stage
                        if !left { AnswerPanel(m: m, side: .right).frame(width: min(480, g.size.width * 0.4)) }
                    }
                } else {
                    VStack(spacing: 0) {
                        stage
                        AnswerPanel(m: m)
                    }
                }
            }
            .background(Color.ink.ignoresSafeArea())
            .background(GameKeys(m: m))
            // a new item flies into its empty slot in the tray (bottom left of the street)
            .overlayPreferenceValue(ItemTrayKey.self) { a in
                GeometryReader { g in
                    if let k = m.flyingItem {
                        let r = a.map { g[$0] }
                        let slot = CGFloat(m.items.firstIndex(where: { $0 == nil }) ?? 2)
                        let to = r.map { CGPoint(x: $0.minX + 6.s + 24.s + slot * 54.s, y: $0.midY) } ?? CGPoint(x: 90.s, y: g.size.height * 0.6)
                        FlyingItem(kind: k, target: to)
                    }
                }
            }
            if m.paused { pauseMenu }
            if case .story(let kind) = m.phase {
                // にゃんカナ: the travel story (novel scenes); the old English scenes are not shown
                NovelView(scenes: NovelBank.scenes(m.ref, kind)) { m.storyDone(kind) }
                    .transition(.opacity)
            }
            if m.phase == .result {
                ResultView(m: m).transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: m.phase)
        .onAppear { m.appear() }
        .onDisappear { m.disappear() }
        .statusBarHidden(true)
    }

    /// the street with everything drawn over it
    private var stage: some View {
        ZStack {
            GameSceneView(world: m.world) { m.tapFoe($0) }
            Color.white.opacity(m.arenaFlash ? 0.9 : 0).allowsHitTesting(false)
            Color(hex: 0xFFF8D6).opacity(m.thunder).allowsHitTesting(false)
            effects
            VStack(spacing: 6.s) {
                hud
                // kidnapped person: a small "help!" badge under the HUD, out of the way of the foes
                if let c = m.helpChip {
                    HStack { helpBadge(c); Spacer() }
                        .transition(.scale(scale: 0.6, anchor: .topLeading).combined(with: .opacity))
                }
                Spacer()
                if let e = m.event { HStack { EventCard(scene: e); Spacer() } }
                // boss lines are only spoken now (the text is in the picture book)
                // a fixed slot for Nyan's line: when the line disappears, the card above no longer jumps down
                ZStack(alignment: .leading) {
                    if let t = m.talk { HStack { nyanTalk(t); Spacer() }.transition(.opacity) }
                }
                .frame(height: 44.s)
                .animation(.easeInOut(duration: 0.2), value: m.talk)
                HStack(alignment: .bottom, spacing: 8.s) {
                    // 13. にゃんカナ's boss battle has no items
                    if !KanaRescue.active { itemTray }
                    Spacer(minLength: 0)
                    if m.foes.count > 1 { targetChips }
                }
            }
            .padding(.horizontal, 12.s)
            .padding(.bottom, 10.s)
            if m.forkChoice { forkPicker }
        }
        .clipped()
    }

    private func helpBadge(_ img: String) -> some View {
        HStack(spacing: 4.s) {
            Image(img).resizable().scaledToFit().frame(width: 34.s, height: 40.s)
            Text("HELP!").font(.en(14.s)).foregroundStyle(Color.popDeep)
            UIIcon("ui_heart|❤️", size: 14.s)
        }
        .padding(.leading, 4.s).padding(.trailing, 10.s).padding(.vertical, 2.s)
        .background(Capsule().fill(Color(hex: 0xFFE3EC)).overlay(Capsule().stroke(Color.ink, lineWidth: 2.5)))
        .modifier(HelpPulse())
    }

    // MARK: HUD

    /// iPad: kept below the window buttons (•••) at the top left
    private var hud: some View { hudRow.padding(.top, UIScale.isPad ? 30 : 0) }

    private var hudRow: some View {
        HStack(spacing: 8.s) {
            Button { AudioManager.shared.se(.tap); m.paused = true } label: {
                Image(systemName: "pause.fill").font(.system(size: 16.s, weight: .black)).foregroundStyle(Color.ink)
                    .frame(width: 40.s, height: 40.s)
                    .background(Circle().fill(Color.white).overlay(Circle().stroke(Color.ink, lineWidth: 3)))
            }
            .buttonStyle(PressStyle(radius: 30, depth: 3))
            HStack(spacing: 2.s) {
                ForEach(0..<m.maxLives, id: \.self) { i in
                    Image(systemName: i < m.lives ? "heart.fill" : "heart")
                        .font(.system(size: 17.s, weight: .black))
                        .foregroundStyle(i < m.lives ? Color.popDeep : Color.ink.opacity(0.35))
                }
            }
            .padding(.horizontal, 10.s).padding(.vertical, 7.s)
            .background(Capsule().fill(Color.white).overlay(Capsule().stroke(Color.ink, lineWidth: 3)))
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(m.score)").font(.en(22.s)).foregroundStyle(.white)
                    .shadow(color: .ink, radius: 0, x: 2, y: 2)
                Text("\(m.ref.area.levelLabel)-\(m.ref.index)  \(m.progressText)")
                    .font(.en(12.s)).foregroundStyle(Color.ink)
                    .padding(.horizontal, 8.s).padding(.vertical, 1)
                    .background(Capsule().fill(Color.sun))
            }
        }
        .padding(.top, 8.s)
    }

    private var targetChips: some View {
        // three or more enemies: smaller chips, so the row never gets wider than an iPhone screen
        let many = m.foes.count >= 3 && !UIScale.isPad
        return HStack(spacing: (many ? 5 : 8).s) {
            if KeyHint.on && !many { KeyHint(text: "Tab") }
            ForEach(m.foes) { f in
                Button { m.tapFoe(f.id) } label: {
                    VStack(spacing: 3) {
                        Image(f.image).resizable().scaledToFit().frame(height: (many ? 28 : 34).s)
                        Meter(value: f.meter).frame(width: (many ? 38 : 50).s, height: 7.s)
                    }
                    .padding((many ? 5 : 6).s)
                    .background(RoundedRectangle(cornerRadius: 12).fill(f.id == m.targetID ? Color.sun : Color.white.opacity(0.85)))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.ink, lineWidth: f.id == m.targetID ? 3 : 2))
                    .opacity(f.attacking ? 0.4 : 1)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func bossBubble(_ l: StoryLine) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(l.en).font(.en(14.s)).foregroundStyle(Color.ink).lineLimit(2).minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 12.s).padding(.vertical, 6.s)
        .frame(maxWidth: 300.s, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.ink, lineWidth: 3)))
        .rotationEffect(.degrees(-1.5))
        .transition(.scale.combined(with: .opacity))
    }

    private func nyanTalk(_ t: String) -> some View {
        HStack(spacing: 4) {
            Image("nyan").resizable().scaledToFit().frame(width: 40.s, height: 40.s)
            Text(jp(t)).font(.ui(13.s)).foregroundStyle(Color.ink)
                .padding(.horizontal, 10.s).padding(.vertical, 6.s)
                .background(Capsule().fill(Color.white).overlay(Capsule().stroke(Color.ink, lineWidth: 2.5)))
        }
        .transition(.move(edge: .leading).combined(with: .opacity))
    }

    private var itemTray: some View {
        HStack(spacing: 6.s) {
            ForEach(0..<3, id: \.self) { i in
                let k = i < m.items.count ? m.items[i] : nil
                Button { if k != nil { m.use(slot: i) } } label: {
                    Group { if let k { UIIcon(k.icon, size: 26.s) } else { Color.clear } }
                        .frame(width: 48.s, height: 48.s)
                        .background(Circle().fill(k == nil ? Color.white.opacity(0.35) : Color.sun))
                        .overlay(Circle().stroke(Color.ink, lineWidth: 3))
                        .overlay(alignment: .bottom) { if KeyHint.on { KeyHint(text: "⌘\(i + 1)").offset(y: 8.s) } }
                }
                .buttonStyle(PressStyle(radius: 30, depth: k == nil ? 0 : 4))
                .disabled(k == nil)
            }
        }
        .padding(6.s)
        .background(Capsule().fill(Color.ink.opacity(0.35)))
        .anchorPreference(key: ItemTrayKey.self, value: .bounds) { $0 }
    }

    @ViewBuilder private var effects: some View {
        if m.timeStopLeft > 0 {
            Color(hex: 0x7FC8FF, alpha: 0.22).allowsHitTesting(false)
            VStack { Spacer(); Text("TIME STOP  \(Int(ceil(m.timeStopLeft)))").font(.en(20.s)).foregroundStyle(.white).shadow(color: .ink, radius: 0, x: 2, y: 2).padding(.bottom, 80.s) }
                .allowsHitTesting(false)
        }
        if m.feverLeft > 0 { FeverFrame(left: m.feverLeft).allowsHitTesting(false) }
        if let mm = m.missile { MissileView(missile: mm, progress: m.missileProgress).id(mm.state) }
        if let k = m.hitFX { HitOverlay(kind: k).transition(.opacity) }
        if m.flash == .damage { Color.danger.opacity(0.45).allowsHitTesting(false) }
        if m.flash == .heal { Color.mint.opacity(0.35).allowsHitTesting(false) }
    }

    private var forkPicker: some View {
        ForkPicker { left in m.chooseRoute(left: left) }
            .transition(.scale(scale: 0.6).combined(with: .opacity))
    }

    private var pauseMenu: some View {
        ZStack {
            Color.ink.opacity(0.55).ignoresSafeArea()
            PaperCard {
                VStack(spacing: 12.s) {
                    OutlinedText("PAUSE", font: .en(34.s), fill: .sun)
                    // switch how to answer in the middle of a stage
                    HStack(spacing: 6.s) {
                        ForEach(AnswerMode.allCases) { a in
                            let on = m.answerMode == a
                            Button {
                                AudioManager.shared.se(.decide, rate: 1.3, volume: 0.5)
                                m.answerMode = a
                                AppState.shared.settings.answerMode = a
                            } label: {
                                VStack(spacing: 2) {
                                    Image(systemName: a.icon).font(.system(size: 16.s, weight: .bold))
                                    Text(a.title).font(.ui(11.s)).lineLimit(1).minimumScaleFactor(0.6)
                                }
                                .foregroundStyle(Color.ink)
                                .frame(maxWidth: .infinity).frame(height: 50.s)
                                .background(RoundedRectangle(cornerRadius: 12).fill(on ? Color(hex: 0xBFD7FF) : .white).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.ink, lineWidth: on ? 2.5 : 1.5)))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    PopButton(title: L("game.resume"), color: .mint) { AudioManager.shared.se(.tap); m.paused = false }
                    PopButton(title: L("game.retry"), color: .white) { AudioManager.shared.se(.tap); m.restart() }
                    PopButton(title: L("game.quit"), color: Color(hex: 0xFFB3CF)) {
                        if KanaRescue.active { KanaRescue.quit() } else { app.goStageList() }
                    }
                }
            }
            .frame(maxWidth: 360.s)
            .padding(30.s)
        }
    }
}

// MARK: - answer panel

struct AnswerPanel: View {
    enum Side { case bottom, left, right }
    @ObservedObject var m: GameModel
    var side: Side = .bottom
    @EnvironmentObject var dev: DevSettings
    @FocusState private var typing: Bool
    @State private var shake: CGFloat = 0

    var body: some View {
        VStack(spacing: 10.s) {
            if let r = m.reveal {
                revealView(r)
            } else if let f = m.target, f.active {
                Meter(value: f.meter).frame(height: 10.s)
                question(f)
                answers(f.question)
            } else {
                idle
            }
            Spacer(minLength: 0)
            if dev.enabled && dev.devButtons { devRow }
        }
        .padding(.horizontal, 14.s)
        .padding(.top, 12.s)
        .padding(.bottom, 8.s)
        .frame(maxWidth: .infinity)
        .frame(height: side == .bottom ? (inAppKeys ? 384 : (dev.enabled && dev.devButtons ? 326 : 290).s) : nil, alignment: .top)   // fixed: the screen never jumps
        .frame(maxHeight: side == .bottom ? nil : .infinity, alignment: .top)
        .padding(.top, side == .bottom ? 0 : 20.s)
        .background(
            ZStack { Color.paper; Dots(color: Color(hex: 0xFFE9B8), gap: 16, radius: 1.6) }
                .clipShape(panelShape)
                .overlay(panelShape.stroke(Color.ink, lineWidth: 4))
                .ignoresSafeArea(edges: side == .bottom ? .bottom : .vertical)
        )
        .offset(x: shake)
        .onChange(of: m.wrongToken) { _, _ in
            withAnimation(.spring(response: 0.08, dampingFraction: 0.2)) { shake = 10 }
            Task { @MainActor in try? await Task.sleep(nanoseconds: 90_000_000); withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) { shake = 0 } }
        }
    }

    /// iPhone typing uses our own keyboard, which needs a taller panel (the send key was pushed off screen)
    private var inAppKeys: Bool { m.answerMode == .keyboard && !UIScale.isPad && !KeyHint.on }

    private var panelShape: UnevenRoundedRectangle {
        switch side {
        case .bottom: UnevenRoundedRectangle(topLeadingRadius: 26, topTrailingRadius: 26)
        case .right: UnevenRoundedRectangle(topLeadingRadius: 26, bottomLeadingRadius: 26)
        case .left: UnevenRoundedRectangle(bottomTrailingRadius: 26, topTrailingRadius: 26)
        }
    }

    private var idle: some View {
        VStack(spacing: 8.s) {
            Spacer(minLength: 0)
            Image("nyan").resizable().scaledToFit().frame(height: 150.s).hop(8)
            Text(jp(L(m.forkChoice ? "game.which" : "game.walking"))).font(.ui(15.s)).foregroundStyle(Color.ink.opacity(0.7))
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }

    private func revealView(_ r: String) -> some View {
        VStack(spacing: 6.s) {
            Text(L("game.correctIs")).font(.ui(14.s)).foregroundStyle(Color.popDeep)
            Button { Speaker.shared.say(r) } label: {
                HStack(spacing: 6) {
                    Text(r).font(.en(24.s)).foregroundStyle(Color.ink).multilineTextAlignment(.center)
                    Image(systemName: "speaker.wave.2.fill").foregroundStyle(Color.sky)
                }
            }
            .buttonStyle(.plain)
            Text(jp(L("game.remember"))).font(.ui(12.s, bold: false)).foregroundStyle(Color.ink.opacity(0.6))
        }
        .frame(maxWidth: .infinity, minHeight: 150.s)
    }

    @ViewBuilder private func question(_ f: Foe) -> some View {
        let q = f.question
        VStack(spacing: 6.s) {
            HStack(alignment: .top) {
                if f.held != nil {
                    HStack(spacing: 2) {
                        Image(systemName: "bolt.fill").font(.system(size: 11.s, weight: .black))
                        Text(jp(T("早押し", "빨리", "搶答"))).font(.ui(12.s))
                    }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8.s).padding(.vertical, 2).background(Capsule().fill(Color.orange))
                        .fixedSize()
                } else if f.isBig {
                    HStack(spacing: 3) {
                        Image("ui_heart").resizable().scaledToFit().frame(height: 15.s)
                        Text("\(f.hpMax - f.hits)").font(.en(13.s)).foregroundStyle(.white)
                    }
                        .padding(.horizontal, 8.s).padding(.vertical, 2).background(Capsule().fill(Color.popDeep))
                        .fixedSize()
                }
                Text(jp(q.meaning)).font(.ui(16.s)).foregroundStyle(Color.ink)
                    .lineLimit(3).minimumScaleFactor(0.85).fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)
                modeToggle
            }
            switch q.kind {
            case .blank:
                sentenceWithBlank(q)
            case .order:
                orderBuilt(q)
            case .sentence:
                EmptyView()
            }
        }
    }

    private var modeToggle: some View {
        Button {
            AudioManager.shared.se(.tap, rate: 1.4, volume: 0.5)
            m.answerMode = m.answerMode == .keyboard ? .choice : .keyboard
            AppState.shared.settings.answerMode = m.answerMode   // keep it for the next stage too
        } label: {
            Image(systemName: m.answerMode == .keyboard ? "hand.tap.fill" : "keyboard.fill")
                .font(.system(size: 15.s, weight: .bold)).foregroundStyle(Color.ink)
                .frame(width: 34.s, height: 30.s)
                .background(RoundedRectangle(cornerRadius: 9).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.ink, lineWidth: 2)))
        }
        .buttonStyle(.plain)
    }

    private func sentenceWithBlank(_ q: Question) -> some View {
        // one ＿ per kana of the answer when typing (a hint of its length), a short blank otherwise
        let n = m.answerMode == .choice ? max(2, min(5, q.a.count)) : max(1, min(10, (q.kana ?? q.a).count))
        let blank = String(repeating: "＿", count: n)
        let len = q.pre.count + q.post.count
        return (Text(q.pre) + Text(blank).foregroundColor(.popDeep) + Text(q.post))
            .font(.en((len > 22 ? 19 : len > 14 ? 21 : 25).s * (m.answerMode == .keyboard && !UIScale.isPad ? 0.84 : 1))).foregroundStyle(Color.ink)
            .lineLimit(4).minimumScaleFactor(0.85)
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4.s)
    }

    private func orderBuilt(_ q: Question) -> some View {
        FlowRow(spacing: 6.s) {
            ForEach(Array(m.picked.enumerated()), id: \.offset) { pos, i in
                Button { m.unpick(pos) } label: { tile(m.tiles[i], filled: true) }.buttonStyle(.plain)
            }
            if m.picked.count < q.words.count { tile("…", filled: false) }
        }
        .frame(maxWidth: .infinity, minHeight: 44.s)
    }

    @ViewBuilder private func answers(_ q: Question) -> some View {
        let useKeyboard = m.answerMode == .keyboard && q.kind != .sentence
        let useHand = m.answerMode == .handwriting && q.kind != .sentence
        if useHand {
            // write the answer with Apple Pencil or a finger
            HandwritingPad(height: (UIScale.isPad ? 150 : 110).s) { text in m.typed = text; m.submitTyped() }
                .id(q.full)
        } else if useKeyboard && !UIScale.isPad && !KeyHint.on {
            // iPhone: our own keyboard inside the answer panel (the system one shrank the game to a strip)
            VStack(spacing: 6) {
                HStack {
                    Text(m.typed.isEmpty ? L("game.type") : m.typed)
                        .font(.en(22)).foregroundStyle(m.typed.isEmpty ? Color.ink.opacity(0.35) : Color.ink)
                        .lineLimit(1).minimumScaleFactor(0.5)
                    Rectangle().fill(Color.popDeep).frame(width: 2, height: 24).opacity(0.8)
                    Spacer(minLength: 0)
                }
                .padding(.leading, 12).padding(.trailing, 76).frame(height: 46)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.ink, lineWidth: 3)))
                .overlay(alignment: .trailing) {
                    // the send key sits next to the answer so it can never be pushed off screen
                    Button { m.submitTyped() } label: {
                        Image(systemName: "paperplane.fill").font(.system(size: 19, weight: .bold)).foregroundStyle(Color.ink)
                            .frame(width: 64, height: 46)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.mint).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.ink, lineWidth: 3)))
                    }
                    .buttonStyle(PressStyle(radius: 14, depth: 3))
                }
                InAppKeyboard(text: $m.typed) { m.submitTyped() }
            }
        } else if useKeyboard {
            HStack(spacing: 8.s) {
                TextField(L("game.type"), text: $m.typed)
                    .font(.en(22.s))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.default)   // the Japanese (kana) keyboard is fine here
                    .submitLabel(.go)
                    .focused($typing)
                    .onSubmit { m.submitTyped(); typing = true }
                    // Tab inside the answer box switches the enemy instead of leaving the box
                    .onKeyPress(.tab, phases: .down) { press in
                        m.cycleTarget(press.modifiers.contains(.shift) ? -1 : 1)
                        return .handled
                    }
                    .padding(.horizontal, 12.s).frame(height: 52.s)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.ink, lineWidth: 3)))
                Button { m.submitTyped() } label: {
                    Image(systemName: "paperplane.fill").font(.system(size: 20.s, weight: .bold)).foregroundStyle(Color.ink)
                        .frame(width: 56.s, height: 52.s)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.mint).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.ink, lineWidth: 3)))
                }
                .buttonStyle(PressStyle(radius: 14, depth: 4))
            }
            .onAppear { typing = true }
        } else {
            if m.answerMode == .voice {
                // say the answer (the buttons still work too)
                HStack(spacing: 10.s) {
                    MicButton(size: 54.s) { heard in m.submitVoice(heard) }
                    MicStatus(hint: m.voiceFullSentence
                              ? T("HARD：|穴うめも|文ぜんぶを|英語で|読もう", "HARD: 빈칸 문제도 문장 전체를 영어로 읽자", "HARD：填空題也要把整句用英文念出來")
                              : T("マイクを押して|答えを|英語で言おう", "마이크를 누르고 답을 영어로 말하자", "按下麥克風用英文說出答案"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            switch q.kind {
            case .blank:
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10.s), GridItem(.flexible(), spacing: 10.s)], spacing: 10.s) {
                    let long = m.choices.contains { $0.count > 12 }
                    ForEach(m.choices, id: \.self) { c in
                        choiceButton(c, font: .en(long ? 16.s : 22.s), height: long ? 46 : 54)
                    }
                }
            case .sentence:
                VStack(spacing: 6.s) {
                    ForEach(m.choices, id: \.self) { c in choiceButton(c, font: .en(c.count > 44 ? 14.s : 16.s), height: 46, compact: true) }
                }
            case .order:
                FlowRow(spacing: 8.s) {
                    ForEach(Array(m.tiles.enumerated()), id: \.offset) { i, w in
                        if m.picked.contains(i) {
                            tile(w, filled: false, big: true)
                        } else {
                            Button { m.pickTile(i) } label: { tile(w, filled: true, big: true) }
                                .buttonStyle(PressStyle(radius: 12, depth: 4))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func choiceButton(_ c: String, font: Font, height: CGFloat = 54, compact: Bool = false) -> some View {
        Button { if !m.gone.contains(c) { m.choose(c) } } label: {
            // long sentences: fixed-height buttons whose text shrinks to fit, so lines never spill over the frame
            Text(jp(c)).font(font).foregroundStyle(Color.ink).lineLimit(compact ? 2 : 3).minimumScaleFactor(compact ? 0.6 : 0.8)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: !compact)
                .padding(.vertical, compact ? 2 : 4)
                .frame(maxWidth: .infinity, minHeight: height.s, maxHeight: compact ? height.s : nil)
                .padding(.horizontal, 6)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.ink, lineWidth: 3)))
                .overlay(alignment: .topLeading) {
                    if KeyHint.on, let n = m.choices.firstIndex(of: c) { KeyHint(text: "\(n + 1)").padding(4) }
                }
        }
        .buttonStyle(PressStyle(radius: 14, depth: 4))
        // easy: a wrong button fades out but keeps its place, so the others don't move around
        .opacity(m.gone.contains(c) ? 0 : 1)
        .allowsHitTesting(!m.gone.contains(c))
        .accessibilityHidden(m.gone.contains(c))
        .animation(.easeOut(duration: 0.25), value: m.gone)
    }

    private func tile(_ w: String, filled: Bool, big: Bool = false) -> some View {
        Text(w).font(.en(big ? 21.s : 19.s)).foregroundStyle(filled ? Color.ink : Color.ink.opacity(0.25))
            .padding(.horizontal, 12.s).frame(minHeight: big ? 46.s : 38.s)
            .background(RoundedRectangle(cornerRadius: 12).fill(filled ? (big ? Color.sun : Color.white) : Color.ink.opacity(0.06)))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.ink.opacity(filled ? 1 : 0.3), lineWidth: filled ? 2.5 : 1.5))
    }

    private var devRow: some View {
        HStack(spacing: 6.s) {
            devButton(L("dev.correct"), .mint) { m.devCorrect() }
            devButton(L("dev.wrong"), Color(hex: 0xFFB3CF)) { m.devWrong() }
            devButton(L("dev.timeout"), .white) { m.devTimeout() }
        }
    }

    private func devButton(_ t: String, _ c: Color, _ a: @escaping () -> Void) -> some View {
        Button(action: a) {
            Text("DEV " + t).font(.ui(12.s)).foregroundStyle(Color.ink)
                .frame(maxWidth: .infinity, minHeight: 32.s)
                .background(RoundedRectangle(cornerRadius: 8).fill(c).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.ink, style: StrokeStyle(lineWidth: 2, dash: [4, 3]))))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - small views

struct Meter: View {
    var value: Double
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.ink.opacity(0.15))
                Capsule().fill(color).frame(width: max(0, g.size.width * (1 - value)))
            }
            .overlay(Capsule().stroke(Color.ink, lineWidth: 2))
        }
    }
    private var color: Color { value < 0.5 ? .mint : value < 0.8 ? .sun : .danger }
}

/// The item icon pops in the middle, then flies into the tray at the bottom right.
struct FlyingItem: View {
    let kind: ItemKind
    var target: CGPoint
    @State private var stage = 0
    var body: some View {
        GeometryReader { g in
            VStack(spacing: 4) {
                UIIcon(kind.icon, size: 54.s)
                    .frame(width: 96.s, height: 96.s)
                    .background(Circle().fill(Color.sun).overlay(Circle().stroke(Color.ink, lineWidth: 4)))
                if stage == 1 { Text(kind.name).font(.ui(16.s)).foregroundStyle(.white).shadow(color: .ink, radius: 0, x: 2, y: 2) }
            }
            .scaleEffect(stage == 0 ? 0.2 : stage == 1 ? 1 : 0.45)
            .position(stage == 2 ? target : CGPoint(x: g.size.width / 2, y: g.size.height * 0.32))
            .opacity(stage == 2 ? 0.2 : 1)
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { stage = 1 }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 500_000_000)
                withAnimation(.easeIn(duration: 0.35)) { stage = 2 }
            }
        }
    }
}

struct ItemTrayKey: PreferenceKey {
    static let defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) { value = value ?? nextValue() }
}

/// Wraps children onto new lines (word tiles).
struct FlowRow: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let w = proposal.width ?? 360
        var x: CGFloat = 0, y: CGFloat = 0, row: CGFloat = 0, maxX: CGFloat = 0
        for s in subviews {
            let z = s.sizeThatFits(.unspecified)
            if x > 0 && x + z.width > w { y += row + spacing; x = 0; row = 0 }
            x += z.width + spacing; row = max(row, z.height); maxX = max(maxX, x - spacing)
        }
        return CGSize(width: min(w, maxX), height: y + row)
    }
    func placeSubviews(in b: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        // centre each row
        var rows: [[(Subviews.Element, CGSize)]] = [[]]
        var x: CGFloat = 0
        for s in subviews {
            let z = s.sizeThatFits(.unspecified)
            if x > 0 && x + z.width > b.width { rows.append([]); x = 0 }
            rows[rows.count - 1].append((s, z)); x += z.width + spacing
        }
        var y = b.minY
        for r in rows {
            let total = r.map(\.1.width).reduce(0, +) + spacing * CGFloat(max(0, r.count - 1))
            var cx = b.minX + (b.width - total) / 2
            let h = r.map(\.1.height).max() ?? 0
            for (s, z) in r { s.place(at: CGPoint(x: cx, y: y + (h - z.height) / 2), proposal: ProposedViewSize(z)); cx += z.width + spacing }
            y += h + spacing
        }
    }
}

/// SceneKit view; taps on enemies pick the target.
struct GameSceneView: UIViewRepresentable {
    let world: GameWorld
    var onTapFoe: (UUID) -> Void

    func makeUIView(context: Context) -> SCNView {
        let v = GameSCNView()
        let w = world
        v.onLayout = { size in if size.height > 0 { w.viewAspect = size.width / size.height } }
        v.scene = world.scene
        v.pointOfView = world.cam
        v.antialiasingMode = .multisampling2X
        v.preferredFramesPerSecond = 60
        v.rendersContinuously = true
        v.isPlaying = true
        world.view = v
        v.backgroundColor = UIColor(red: 0.6, green: 0.8, blue: 1, alpha: 1)
        v.addGestureRecognizer(UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.tap(_:))))
        return v
    }

    func updateUIView(_ v: SCNView, context: Context) {
        context.coordinator.parent = self
        if v.scene !== world.scene { v.scene = world.scene; v.pointOfView = world.cam; v.isPlaying = true }
        world.view = v
        if let g = v as? GameSCNView { let w = world; g.onLayout = { size in if size.height > 0 { w.viewAspect = size.width / size.height } } }
        if v.bounds.height > 0 { world.viewAspect = v.bounds.width / v.bounds.height }
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject {
        var parent: GameSceneView
        init(parent: GameSceneView) { self.parent = parent }
        @objc func tap(_ g: UITapGestureRecognizer) {
            guard let v = g.view as? SCNView else { return }
            let hits = v.hitTest(g.location(in: v), options: [.searchMode: SCNHitTestSearchMode.all.rawValue, .ignoreHiddenNodes: true])
            for h in hits { if let id = parent.world.foeID(of: h.node) { parent.onTapFoe(id); return } }
        }
    }
}

/// Fork choice: a signpost with two big arrow signs that bounce; the picked one flashes and zooms.
struct ForkPicker: View {
    var choose: (Bool) -> Void
    @State private var appear = false
    @State private var wiggle = false
    @State private var picked: Bool?

    var body: some View {
        ZStack {
            Color.ink.opacity(0.25).allowsHitTesting(false)
            VStack(spacing: 6.s) {
                ZStack {
                    StarBurst(points: 14, inner: 0.78).fill(Color.sun).frame(width: 290.s, height: 110.s)
                        .overlay(StarBurst(points: 14, inner: 0.78).stroke(Color.ink, lineWidth: 3).frame(width: 290.s, height: 110.s))
                        .rotationEffect(.degrees(wiggle ? 3 : -3))
                    OutlinedText(jp(L("game.which")), font: .display(24.s), fill: .pop)
                }
                .scaleEffect(appear ? 1 : 0.3)
                ZStack(alignment: .top) {
                    // wooden post
                    RoundedRectangle(cornerRadius: 6).fill(Color(hex: 0xB9763A))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.ink, lineWidth: 3))
                        .frame(width: 22.s, height: 150.s)
                        .offset(y: 20.s)
                    VStack(spacing: 10.s) {
                        sign(left: true).offset(x: -46.s)
                        sign(left: false).offset(x: 46.s)
                    }
                }
            }
        }
        .onAppear {
            AudioManager.shared.se(.kira, volume: 0.8)
            withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) { appear = true }
            withAnimation(.easeInOut(duration: 0.5).repeatForever()) { wiggle = true }
        }
    }

    private func sign(left: Bool) -> some View {
        let isPicked = picked == left
        return Button {
            guard picked == nil else { return }
            AudioManager.shared.se(.decide)
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { picked = left }
            later(0.35) { choose(left) }
        } label: {
            HStack(spacing: 8.s) {
                if left { Image(systemName: "arrowshape.left.fill").font(.system(size: 26.s, weight: .black)) }
                Text(L(left ? "game.left" : "game.right")).font(.display(26.s))
                if !left { Image(systemName: "arrowshape.right.fill").font(.system(size: 26.s, weight: .black)) }
            }
            .foregroundStyle(.white)
            .shadow(color: .ink, radius: 0, x: 2, y: 2)
            .padding(.leading, left ? 34.s : 22.s).padding(.trailing, left ? 22.s : 34.s)
            .frame(width: 200.s, height: 70.s)
            .background(ArrowSign(left: left).fill(left ? Color.sky : Color.pop))
            .overlay(ArrowSign(left: left).stroke(Color.ink, lineWidth: 4))
            .background(ArrowSign(left: left).fill(Color.ink).offset(y: 6))
        }
        .buttonStyle(.plain)
        .rotationEffect(.degrees(wiggle ? (left ? -4 : 4) : (left ? 2 : -2)), anchor: left ? .trailing : .leading)
        .scaleEffect(isPicked ? 1.25 : (picked != nil ? 0.8 : (appear ? 1 : 0.2)))
        .opacity(picked != nil && !isPicked ? 0.3 : 1)
        .brightness(isPicked ? 0.15 : 0)
        .offset(x: appear ? 0 : (left ? -300 : 300))
    }
}

/// Signboard with a pointed end.
struct ArrowSign: Shape {
    var left: Bool
    func path(in r: CGRect) -> Path {
        let tip = r.height * 0.5
        var p = Path()
        if left {
            p.move(to: CGPoint(x: r.minX, y: r.midY))
            p.addLine(to: CGPoint(x: r.minX + tip, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX - 8, y: r.minY))
            p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + 8), control: CGPoint(x: r.maxX, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - 8))
            p.addQuadCurve(to: CGPoint(x: r.maxX - 8, y: r.maxY), control: CGPoint(x: r.maxX, y: r.maxY))
            p.addLine(to: CGPoint(x: r.minX + tip, y: r.maxY))
        } else {
            p.move(to: CGPoint(x: r.maxX, y: r.midY))
            p.addLine(to: CGPoint(x: r.maxX - tip, y: r.minY))
            p.addLine(to: CGPoint(x: r.minX + 8, y: r.minY))
            p.addQuadCurve(to: CGPoint(x: r.minX, y: r.minY + 8), control: CGPoint(x: r.minX, y: r.minY))
            p.addLine(to: CGPoint(x: r.minX, y: r.maxY - 8))
            p.addQuadCurve(to: CGPoint(x: r.minX + 8, y: r.maxY), control: CGPoint(x: r.minX, y: r.maxY))
            p.addLine(to: CGPoint(x: r.maxX - tip, y: r.maxY))
        }
        p.closeSubpath()
        return p
    }
}

/// Rainbow frame + badge while FEVER is on.
struct FeverFrame: View {
    var left: Double
    @State private var spin = false
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 0)
                .strokeBorder(AngularGradient(colors: [.pop, .sun, .mint, .sky, .grape, .pop], center: .center, angle: .degrees(spin ? 360 : 0)), lineWidth: 10)
                .opacity(0.85)
            VStack {
                HStack(spacing: 6) {
                    Text("FEVER").font(.en(22.s)).foregroundStyle(.white)
                    Text("×2").font(.en(18.s)).foregroundStyle(Color.sun)
                    Text("\(Int(ceil(left)))").font(.en(16.s)).foregroundStyle(.white.opacity(0.85))
                }
                .padding(.horizontal, 14).padding(.vertical, 4)
                .background(Capsule().fill(LinearGradient(colors: [.popDeep, .grape], startPoint: .leading, endPoint: .trailing)).overlay(Capsule().stroke(Color.ink, lineWidth: 2.5)))
                .scaleEffect(spin ? 1.06 : 0.96)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 14.s)
                .padding(.top, 128.s)   // under the score / stage label, clear of the hearts
                Spacer()
            }
        }
        .ignoresSafeArea()
        .onAppear { withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: true)) { spin = true } }
    }
}


/// SCNView that reports its size (the arena pictures are cropped to it).
final class GameSCNView: SCNView {
    var onLayout: ((CGSize) -> Void)?
    override func layoutSubviews() {
        super.layoutSubviews()
        onLayout?(bounds.size)
    }
}


// MARK: - hardware keyboard (iPad keyboard / Mac)

/// Small key label shown on buttons when a keyboard is connected.
struct KeyHint: View {
    var text: String
    static var on: Bool { ProcessInfo.processInfo.isiOSAppOnMac || GCKeyboard.coalesced != nil }
    var body: some View {
        Text(text).font(.system(size: 11.s, weight: .heavy, design: .rounded)).foregroundStyle(Color.ink)
            .padding(.horizontal, 5).padding(.vertical, 1)
            .background(RoundedRectangle(cornerRadius: 5).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.ink, lineWidth: 1.5)))
            .allowsHitTesting(false)
    }
}

/// Invisible buttons that hold the keyboard shortcuts of the game screen.
///  Tab / Shift+Tab: next / previous enemy · ⌘1–⌘3: items · 1–4: choices (when not typing) · Esc: pause
struct GameKeys: View {
    @ObservedObject var m: GameModel
    var body: some View {
        ZStack {
            Button("") { m.cycleTarget(1) }.keyboardShortcut(.tab, modifiers: [])
            Button("") { m.cycleTarget(-1) }.keyboardShortcut(.tab, modifiers: .shift)
            ForEach(0..<3, id: \.self) { i in
                Button("") { m.useSlot(i) }.keyboardShortcut(KeyEquivalent(Character("\(i + 1)")), modifiers: .command)
            }
            if m.answerMode != .keyboard {
                ForEach(0..<4, id: \.self) { i in
                    Button("") { if i < m.choices.count, !m.gone.contains(m.choices[i]) { m.choose(m.choices[i]) } }.keyboardShortcut(KeyEquivalent(Character("\(i + 1)")), modifiers: [])
                }
            }
            Button("") { if m.phase == .playing { m.paused = true } }.keyboardShortcut(.escape, modifiers: [])
        }
        .frame(width: 0, height: 0).opacity(0).accessibilityHidden(true)
    }
}


/// gentle pulse so the "help!" badge is noticed without covering anything
private struct HelpPulse: ViewModifier {
    @State private var on = false
    func body(content: Content) -> some View {
        content.scaleEffect(on ? 1.06 : 1, anchor: .leading)
            .onAppear { withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) { on = true } }
    }
}
