import SwiftUI

// MARK: - ばめんの かいわ（2周目 N5・3周目 N4）
// ゲームの「はなそう」マスと、まなぶの「かいわ」タブで つかう。ことばは KJScenes.swift（gen_scenes.py が作る）

struct KJScene: Identifiable {
    struct Line { var me: Bool; var ja: String; var kana: String; var en: String; var zh: String; var ko: String
        var meaning: String { KJ.t(en, zh, ko) }
    }
    var id: String
    var lap: Int
    var chapter: Int
    var face: String
    var ja: String, en: String, zh: String, ko: String
    var lines: [Line]

    var title: String { KJ.t(en, zh, ko) }
    /// the picture of the person you talk to (a stand-in until its own picture exists)
    var faceImage: String { UIImage(named: face) != nil ? face : (["npc_friend", "npc_grandma", "npc_teacher"].contains(face) ? "yui_smile" : "npc_nakamise") }

    /// the two scenes of a region in a round
    static func of(lap: Int, chapter: Int) -> [KJScene] { all.filter { $0.lap == lap && $0.chapter == chapter } }
    static func find(_ id: String) -> KJScene? { all.first { $0.id == id } }

    /// your line is said in one voice, the other person's in theirs
    static func say(_ l: Line, in s: KJScene) { Speaker.shared.sayRole(l.ja, role: l.me ? "kp" : s.face) }
}

/// play a scene: the other person speaks, you pick what to say back (from its meaning)
struct KJSceneTalk: View {
    let scene: KJScene
    var lap = 2
    var finished: (_ stars: Int, _ score: Int) -> Void

    @State private var i = 0                // the line now
    @State private var choices: [String] = []
    @State private var picked: String?
    @State private var right = 0
    @State private var asked = 0
    @State private var shown: [Int] = []    // the lines already on screen

    private var lines: [KJScene.Line] { scene.lines }

    var body: some View {
        VStack(spacing: 10.s) {
            Spacer(minLength: 58.s)
            HStack(spacing: 10.s) {
                Image(scene.faceImage).resizable().scaledToFit().frame(height: 96.s)
                VStack(alignment: .leading, spacing: 2.s) {
                    Text(scene.ja).font(.custom(Fonts.rounded, size: 18.s)).foregroundStyle(.white)
                    Text(scene.title).font(.ui(12.s, bold: false)).foregroundStyle(.white.opacity(0.85))
                }
                .shadow(color: .black.opacity(0.6), radius: 3)
                Spacer()
            }
            .padding(.horizontal, 18.s)
            ScrollViewReader { sv in
                ScrollView {
                    VStack(spacing: 8.s) {
                        ForEach(shown, id: \.self) { k in bubble(lines[k]).id(k) }
                    }
                    .padding(.horizontal, 14.s)
                }
                .onChange(of: shown) { _, s in if let l = s.last { withAnimation { sv.scrollTo(l, anchor: .bottom) } } }
            }
            if let cur = lines[safe: i], cur.me {
                // your turn: what you want to say, in your language → pick the Japanese
                VStack(spacing: 8.s) {
                    Text(KJ.duo("Say:", "要說：", "말하기:") + " " + cur.meaning)
                        .font(.ui(14.s)).foregroundStyle(Color.ink).multilineTextAlignment(.center)
                        .padding(.horizontal, 12.s).padding(.vertical, 6.s)
                        .background(RoundedRectangle(cornerRadius: 12.s).fill(Color.white.opacity(0.95)))
                    ForEach(choices, id: \.self) { c in
                        Button { answer(c) } label: {
                            Text(c).font(.ui(15.s)).foregroundStyle(Color.ink).multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12.s).padding(.vertical, 9.s)
                                .background(RoundedRectangle(cornerRadius: 14.s).fill(color(c, cur.ja)).overlay(RoundedRectangle(cornerRadius: 14.s).stroke(Color.ink, lineWidth: 2.5)))
                        }
                        .buttonStyle(.plain)
                        .disabled(picked != nil)
                    }
                }
                .padding(.horizontal, 16.s).padding(.bottom, 14.s)
            } else {
                Color.clear.frame(height: 40.s)
            }
        }
        .onAppear { next() }
    }

    private func bubble(_ l: KJScene.Line) -> some View {
        HStack {
            if l.me { Spacer(minLength: 40.s) }
            Button { KJScene.say(l, in: scene) } label: {
                VStack(alignment: l.me ? .trailing : .leading, spacing: 2.s) {
                    Text(l.ja).font(.ui(16.s)).foregroundStyle(Color.ink)
                    // round 2: the reading under it; round 3: no help
                    if lap <= 2 && l.kana != l.ja { Text(l.kana).font(.ui(11.s, bold: false)).foregroundStyle(Color.ink.opacity(0.6)) }
                    Text(l.meaning).font(.ui(11.s, bold: false)).foregroundStyle(Color.ink.opacity(0.55))
                }
                .multilineTextAlignment(l.me ? .trailing : .leading)
                .padding(.horizontal, 12.s).padding(.vertical, 8.s)
                .background(RoundedRectangle(cornerRadius: 16.s).fill(l.me ? Color(hex: 0xD8F5C8) : Color.white).overlay(RoundedRectangle(cornerRadius: 16.s).stroke(Color.ink, lineWidth: 2)))
            }
            .buttonStyle(.plain)
            if !l.me { Spacer(minLength: 40.s) }
        }
    }

    private func color(_ c: String, _ ans: String) -> Color {
        guard let p = picked else { return .white }
        if c == ans { return .mint }
        return c == p ? .danger : .white
    }

    /// the other person's lines play by themselves; stop at each of yours
    private func next() {
        guard let cur = lines[safe: i] else {
            let r = Double(right) / Double(max(1, asked))
            later(1.0) { finished(r >= 0.9 ? 3 : r >= 0.6 ? 2 : 1, right * 150) }
            return
        }
        if cur.me {
            picked = nil
            // wrong choices: other things you say in this scene, then in other scenes of the round
            var d = lines.filter { $0.me && $0.ja != cur.ja }.map(\.ja).shuffled()
            if d.count < 2 { d += KJScene.all.filter { $0.lap == scene.lap && $0.id != scene.id }.flatMap(\.lines).filter(\.me).map(\.ja).shuffled() }
            choices = ([cur.ja] + d.prefix(2)).shuffled()
        } else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { shown.append(i) }
            KJScene.say(cur, in: scene)
            let wait = 1.2 + Double(cur.ja.count) * 0.09
            i += 1
            later(wait) { next() }
        }
    }

    private func answer(_ c: String) {
        guard let cur = lines[safe: i], picked == nil else { return }
        picked = c
        asked += 1
        if c == cur.ja || AppState.shared.dev.anyRight { right += 1; AudioManager.shared.se(.kira) } else { AudioManager.shared.se(.wrong) }
        later(0.9) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { shown.append(i) }
            KJScene.say(cur, in: scene)
            let wait = 1.2 + Double(cur.ja.count) * 0.09
            i += 1
            later(wait) { next() }
        }
    }
}

/// まなぶ › かいわ: every scene, grouped by round; read · listen · practice
struct KJSceneList: View {
    @State private var open: KJScene?
    @State private var practice: KJScene?

    var body: some View {
        ZStack {
            if let s = practice {
                KJSceneTalk(scene: s, lap: s.lap) { _, _ in withAnimation { practice = nil } }
                    .transition(.move(edge: .trailing))
            } else if let s = open {
                detail(s).transition(.move(edge: .trailing))
            } else {
                list
            }
        }
    }

    private var list: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8.s) {
                ForEach([2, 3], id: \.self) { lap in
                    HStack(spacing: 6.s) {
                        Text(lap == 2 ? "2しゅうめ・N5" : "3しゅうめ・N4").font(.custom(Fonts.rounded, size: 16.s)).foregroundStyle(.white)
                        if !KJLap.bought { Image(systemName: "crown.fill").foregroundStyle(Color(hex: 0xFFB800)) }
                    }
                    .shadow(color: .black.opacity(0.5), radius: 2)
                    ForEach(KJScene.all.filter { $0.lap == lap }) { s in
                        Button {
                            guard KJLap.bought else { AudioManager.shared.se(.decide); AppState.shared.sheet = .shop; return }
                            AudioManager.shared.se(.decide)
                            withAnimation { open = s }
                        } label: {
                            HStack(spacing: 10.s) {
                                Image(s.faceImage).resizable().scaledToFit().frame(width: 40.s, height: 40.s)
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(s.ja).font(.custom(Fonts.rounded, size: 15.s)).foregroundStyle(Color.ink)
                                    Text(s.title).font(.ui(11.s, bold: false)).foregroundStyle(Color.ink.opacity(0.6))
                                }
                                Spacer()
                                Image(systemName: KJLap.bought ? "chevron.right" : "lock.fill").foregroundStyle(Color.ink.opacity(0.5))
                            }
                            .padding(10.s)
                            .background(RoundedRectangle(cornerRadius: 12.s).fill(Color.white.opacity(0.95)).overlay(RoundedRectangle(cornerRadius: 12.s).stroke(Color.ink, lineWidth: 2)))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16.s).padding(.bottom, 24.s)
        }
    }

    private func detail(_ s: KJScene) -> some View {
        VStack(spacing: 8.s) {
            HStack {
                BackChip { withAnimation { open = nil } }
                Spacer()
            }
            .padding(.horizontal, 14.s)
            HStack(spacing: 10.s) {
                Image(s.faceImage).resizable().scaledToFit().frame(height: 70.s)
                VStack(alignment: .leading) {
                    Text(s.ja).font(.custom(Fonts.rounded, size: 18.s)).foregroundStyle(.white)
                    Text(s.title).font(.ui(12.s, bold: false)).foregroundStyle(.white.opacity(0.85))
                }
                .shadow(color: .black.opacity(0.6), radius: 3)
                Spacer()
            }
            .padding(.horizontal, 16.s)
            ScrollView {
                VStack(spacing: 8.s) {
                    ForEach(Array(s.lines.enumerated()), id: \.offset) { _, l in
                        HStack {
                            if l.me { Spacer(minLength: 30.s) }
                            Button { KJScene.say(l, in: s) } label: {
                                VStack(alignment: l.me ? .trailing : .leading, spacing: 2.s) {
                                    Text(l.ja).font(.ui(16.s)).foregroundStyle(Color.ink)
                                    if l.kana != l.ja { Text(l.kana).font(.ui(11.s, bold: false)).foregroundStyle(Color.ink.opacity(0.6)) }
                                    Text(l.meaning).font(.ui(11.s, bold: false)).foregroundStyle(Color.ink.opacity(0.55))
                                }
                                .multilineTextAlignment(l.me ? .trailing : .leading)
                                .padding(.horizontal, 12.s).padding(.vertical, 8.s)
                                .background(RoundedRectangle(cornerRadius: 16.s).fill(l.me ? Color(hex: 0xD8F5C8) : Color.white).overlay(RoundedRectangle(cornerRadius: 16.s).stroke(Color.ink, lineWidth: 2)))
                            }
                            .buttonStyle(.plain)
                            if !l.me { Spacer(minLength: 30.s) }
                        }
                    }
                }
                .padding(.horizontal, 14.s)
            }
            HStack(spacing: 10.s) {
                PopButton(title: KJ.duo("Listen all", "全部聽", "전부 듣기"), color: .white) { playAll(s, from: 0) }
                PopButton(title: KJ.duo("Practice", "練習", "연습"), color: .mint) { Speaker.shared.stop(); withAnimation { practice = s } }
            }
            .padding(.horizontal, 16.s).padding(.bottom, 16.s)
        }
    }

    private func playAll(_ s: KJScene, from k: Int) {
        guard let l = s.lines[safe: k], open?.id == s.id else { return }
        KJScene.say(l, in: s)
        later(1.2 + Double(l.ja.count) * 0.09) { playAll(s, from: k + 1) }
    }
}
