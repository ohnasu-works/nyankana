import SwiftUI

// MARK: - まなぶ（勉強モード）たたき台
// もじひょう（文字の表・覚え方）／れんしゅう（えらんだ文字で なぞり・しょどう・かるた・めくり）／ことば（絵と音）

struct KJStudyView: View {
    var back: () -> Void
    enum Tab: String, CaseIterable { case chart, words, train, exam }
    @State private var tab: Tab = .chart
    @State private var detail: KJLetter?
    @State private var playing: (kind: MGKind, letters: [String])?
    @State private var group = 0
    @State private var train: KJTrainMode?

    /// the letter groups in the order the journey teaches them
    static let groups: [(title: String, letters: [String])] = {
        KJC1.stages.filter { !$0.newKana.isEmpty }.map { s in
            let l = s.newKana
            return ("\(l.first ?? "")〜\(l.last ?? "")", l)
        }
    }()

    var body: some View {
        ZStack {
            if let t = train {
                KJTrainView(mode: t) {
                    AudioManager.shared.playBGM(.study)
                    withAnimation { train = nil }
                }
                .transition(.move(edge: .trailing))
            } else if let p = playing {
                MiniGameView(kind: p.kind, stage: KJC1.Stage(id: 950, ja: p.kind.title, en: p.kind.sub, zh: p.kind.sub, ko: p.kind.sub,
                                                              bg: p.kind.bg, kind: .mini, known: p.letters, mini: p.kind)) { _, _, _ in
                    AudioManager.shared.playBGM(.study)
                    withAnimation { playing = nil }
                }
                // quit in the middle of a game
                .overlay(alignment: .topLeading) {
                    BackChip {
                        AudioManager.shared.playBGM(.study)
                        withAnimation { playing = nil }
                    }
                    .padding(.leading, 14.s).padding(.top, 6.s)
                }
                .transition(.opacity)
            } else {
                main.transition(.opacity)
            }
        }
        .onAppear { AudioManager.shared.playBGM(.study) }
        // the letter card: always the same size, closes with ✕ or a tap outside
        .overlay {
            if let l = detail {
                ZStack {
                    Color.black.opacity(0.45).ignoresSafeArea()
                        .onTapGesture { withAnimation(.easeOut(duration: 0.2)) { detail = nil } }
                    KJLetterSheet(l: l) { withAnimation(.easeOut(duration: 0.2)) { detail = nil } }
                        .padding(.horizontal, 24.s)
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                }
            }
        }
    }

    private var main: some View {
        ZStack {
            KJBackdrop(bg: "bg_mg_dojo", dim: 0.45)
            VStack(spacing: 10.s) {
                HStack {
                    BackChip { back() }
                    Spacer()
                    KJSlowButton()
                }
                .padding(.horizontal, 14.s).padding(.top, 6.s)
                RibbonTitle(text: "まなぶ", color: .grape, size: 24)
                // four tabs in one row
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6.s), count: 4), spacing: 6.s) {
                    ForEach(Tab.allCases, id: \.self) { t in
                        Button {
                            AudioManager.shared.se(.tap)
                            tab = t
                        } label: {
                            VStack(spacing: 0) {
                                Text(title(t)).font(.custom(Fonts.rounded, size: 14.s))
                                    .lineLimit(1).minimumScaleFactor(0.7)
                                // the meaning in the player's language, so the tabs are never confused
                                Text(sub(t)).font(.ui(10.s, bold: false)).opacity(0.75)
                                    .lineLimit(1).minimumScaleFactor(0.6)
                            }
                                .foregroundStyle(tab == t ? Color.white : Color.ink)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 6.s).padding(.vertical, 5.s)
                                .background(Capsule().fill(tab == t ? Color.grape : Color.white).overlay(Capsule().stroke(Color.ink, lineWidth: 2.5)))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16.s)
                switch tab {
                case .chart: chart
                case .words: wordList
                case .train: KJTrainMenu(modes: KJTrainMode.training, header: AnyView(practice)) { m in withAnimation { train = m } }
                case .exam: KJTrainMenu(modes: KJTrainMode.exams) { m in withAnimation { train = m } }
                }
            }
        }
    }

    private func title(_ t: Tab) -> String {
        switch t {
        case .chart: "もじひょう"
        case .words: "ことば"
        case .train: "れんしゅう"
        case .exam: "しけん"
        }
    }

    private func sub(_ t: Tab) -> String {
        switch t {
        case .chart: KJ.t("Letters", "文字表", "글자표")
        case .words: KJ.t("Words", "單字", "단어")
        case .train: KJ.t("Practice", "練習", "연습")
        case .exam: KJ.t("Test", "考試", "시험")
        }
    }

    // MARK: the letter chart

    private var chart: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14.s) {
                ForEach(Array(Self.groups.enumerated()), id: \.offset) { _, g in
                    VStack(alignment: .leading, spacing: 6.s) {
                        Text(g.title).font(.custom(Fonts.rounded, size: 13.s)).foregroundStyle(.white)
                            .padding(.horizontal, 10.s).padding(.vertical, 2.s)
                            .background(Capsule().fill(Color.ink.opacity(0.6)))
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6.s), count: 5), spacing: 6.s) {
                            ForEach(g.letters, id: \.self) { k in
                                Button {
                                    Speaker.shared.say(k)
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { detail = KJData.letter(k) }
                                } label: {
                                    VStack(spacing: 0) {
                                        Text(k).font(.custom(Fonts.rounded, size: k.count > 1 ? 20.s : 26.s)).foregroundStyle(Color.ink)
                                            .lineLimit(1).minimumScaleFactor(0.6)
                                        Text(KJData.romaji(k)).font(.ui(10.s, bold: false)).foregroundStyle(Color.ink.opacity(0.6))
                                    }
                                    .frame(maxWidth: .infinity).frame(height: 52.s)
                                    .background(RoundedRectangle(cornerRadius: 10.s).fill(Color.white.opacity(0.93)).overlay(RoundedRectangle(cornerRadius: 10.s).stroke(Color.ink, lineWidth: 2)))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16.s).padding(.bottom, 24.s)
        }
    }

    // MARK: practice with the letters you choose

    /// letter practice, shown at the top of the training tab
    private var practice: some View {
            VStack(spacing: 12.s) {
                Text(KJ.t("Letters: choose a row", "文字：選一行", "글자: 행을 골라요")).font(.ui(14.s)).foregroundStyle(.white)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6.s) {
                        ForEach(Array(Self.groups.enumerated()), id: \.offset) { i, g in
                            Button {
                                AudioManager.shared.se(.tap)
                                group = i
                            } label: {
                                Text(g.title).font(.custom(Fonts.rounded, size: 14.s))
                                    .foregroundStyle(group == i ? Color.white : Color.ink)
                                    .padding(.horizontal, 12.s).padding(.vertical, 8.s)
                                    .background(Capsule().fill(group == i ? Color.pop : Color.white).overlay(Capsule().stroke(Color.ink, lineWidth: 2)))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                let picked = Self.groups[safe: group]?.letters ?? KJC1.A
                Text(picked.joined(separator: " ")).font(.custom(Fonts.rounded, size: 26.s)).foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.6), radius: 2)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12.s), GridItem(.flexible(), spacing: 12.s)], spacing: 12.s) {
                    practiceCard(.nazori, KJ.t("Trace", "描寫", "따라 쓰기"), picked)
                    practiceCard(.shodo, KJ.t("Write from memory", "默寫", "기억해서 쓰기"), picked)
                    practiceCard(.karuta, KJ.t("Listen & tap", "聽音找字", "듣고 찾기"), picked)
                    practiceCard(.mekuri, KJ.t("Match the sounds", "配對讀音", "소리 짝짓기"), picked)
                }
            }
            .padding(.bottom, 8.s)
    }

    private func practiceCard(_ k: MGKind, _ label: String, _ letters: [String]) -> some View {
        Button {
            AudioManager.shared.se(.decide)
            // a few more letters so every game has enough to choose from
            var ls = letters
            if ls.count < 8, let i = Self.groups.firstIndex(where: { $0.letters == letters }), i > 0 {
                ls += Self.groups[i - 1].letters
            }
            withAnimation { playing = (k, ls) }
        } label: {
            VStack(spacing: 4.s) {
                KJPicView(k.icon, size: 39.1.s)
                Text(label).font(.custom(Fonts.rounded, size: 14.s)).foregroundStyle(Color.ink)
                    .lineLimit(1).minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 14.s)
            .background(RoundedRectangle(cornerRadius: 16.s).fill(Color.white.opacity(0.94)).overlay(RoundedRectangle(cornerRadius: 16.s).stroke(Color.ink, lineWidth: 3)))
        }
        .buttonStyle(PressStyle(radius: 16.s, depth: 4))
    }

    // MARK: words with pictures

    private var wordList: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8.s), GridItem(.flexible(), spacing: 8.s)], spacing: 8.s) {
                ForEach(KJData.words, id: \.ja) { w in
                    Button { Speaker.shared.say(w.ja) } label: {
                        HStack(spacing: 8.s) {
                            KJPicView(w.emoji, size: 32.2.s)
                            VStack(alignment: .leading, spacing: 0) {
                                Text(w.ja).font(.custom(Fonts.rounded, size: 17.s)).foregroundStyle(Color.ink)
                                    .lineLimit(1).minimumScaleFactor(0.6)
                                Text(w.meaning).font(.ui(11.s, bold: false)).foregroundStyle(Color.ink.opacity(0.65)).lineLimit(1)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(8.s)
                        .background(RoundedRectangle(cornerRadius: 12.s).fill(Color.white.opacity(0.93)).overlay(RoundedRectangle(cornerRadius: 12.s).stroke(Color.ink, lineWidth: 2)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16.s).padding(.bottom, 24.s)
        }
    }
}

/// Identifiable wrapper so a letter can drive a sheet
struct KJLetterBox: Identifiable {
    let l: KJLetter
    var id: String { l.kana }
}

struct KJLetterSheet: View {
    let l: KJLetter
    var close: () -> Void = {}
    var body: some View {
        VStack(spacing: 12.s) {
            HStack {
                Spacer()
                Button(action: close) {
                    Image(systemName: "xmark").font(.system(size: 18.s, weight: .black)).foregroundStyle(Color.ink)
                        .frame(width: 40.s, height: 40.s)
                        .background(Circle().fill(Color.white).overlay(Circle().stroke(Color.ink, lineWidth: 2.5)))
                }
                .buttonStyle(.plain)
            }
            Text(l.kana).font(.custom(Fonts.rounded, size: l.kana.count > 1 ? 72.s : 96.s)).foregroundStyle(Color.ink)
                .lineLimit(1).minimumScaleFactor(0.4)
                .lineLimit(1).minimumScaleFactor(0.5)
            Text(l.romaji).font(.display(26.s)).foregroundStyle(Color.popDeep)
            Text(l.aid).font(.ui(16.s)).foregroundStyle(Color.ink).multilineTextAlignment(.center).padding(.horizontal, 24.s)
            if !l.ja.isEmpty {
                Text(l.ja).font(.ui(13.s, bold: false)).foregroundStyle(Color.ink.opacity(0.6)).multilineTextAlignment(.center)
            }
            Button {
                Speaker.shared.say(l.kana)
            } label: {
                Label(KJ.t("Listen", "聽", "듣기"), systemImage: "speaker.wave.3.fill")
                    .font(.ui(16.s)).foregroundStyle(.white)
                    .padding(.horizontal, 22.s).padding(.vertical, 10.s)
                    .background(Capsule().fill(Color.sky))
            }
        }
        .padding(16.s)
        .padding(.bottom, 8.s)
        .frame(maxWidth: 420.s)
        .background(RoundedRectangle(cornerRadius: 26.s).fill(Color(hex: 0xFFFBF2)).overlay(RoundedRectangle(cornerRadius: 26.s).stroke(Color.ink, lineWidth: 3)))
    }
}
