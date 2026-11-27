import SwiftUI

// MARK: - しゅうめ（周回）：1しゅうめ ソラ・やさしい → 2しゅうめ ユイ・ふつう（かんじ＋ふりがな）→ 3しゅうめ ふたり・むずかしい（ふりがな なし）
// ステージは KJLaps.swift（gen_laps.py が作る）。同じ 7つの ちほうを、むずかしく なって もう一度 まわる。

enum KJLap {
    static let count = 3

    /// the round shown on the map (remembered)
    static var selected: Int {
        get { min(count, max(1, UserDefaults.standard.integer(forKey: "kj.lap"))) }
        set { UserDefaults.standard.set(newValue, forKey: "kj.lap") }
    }
    /// the round of the stage being played now (set when a stage opens)
    static var playing = 1

    /// a round opens when its first stage is open (= the last boss of the round before is beaten)
    static func open(_ lap: Int) -> Bool {
        guard lap > 1 else { return true }
        guard bought else { return false }
        guard let first = KJC1.stages.first(where: { $0.lap == lap }) else { return false }
        return KJC1.unlocked(first.id)
    }

    /// rounds 2 and 3 come with the purchase (round 1 — all the kana — is free)
    static var bought: Bool { AppState.shared.isPremium || AppState.shared.dev.unlocks }

    static func name(_ lap: Int) -> String { "\(lap)しゅうめ" }
    /// who travels with Nyan
    static func partner(_ lap: Int) -> String { lap == 1 ? "ソラ" : lap == 2 ? "ユイ" : "ソラ＋ユイ" }
    static func partnerFaces(_ lap: Int) -> [String] { lap == 1 ? ["sora_full"] : lap == 2 ? ["yui_smile"] : ["sora_full", "yui_smile"] }
    static func level(_ lap: Int) -> String {
        switch lap {
        case 1: return KJ.t("Easy · hiragana", "簡單・平假名", "쉬움・히라가나")
        case 2: return KJ.t("Normal · kanji with furigana", "普通・漢字＋注音", "보통・한자＋후리가나")
        default: return KJ.t("Hard · kanji, no furigana", "困難・漢字無注音", "어려움・후리가나 없음")
        }
    }

    // MARK: difficulty of the round being played

    /// how fast the minions dive in a battle
    /// (only a little: the questions themselves get harder — look-alike letters, kanji, more reading)
    static var speed: Double { [1.0, 1.08, 1.15][max(0, min(2, playing - 1))] }
    /// battles: how often a question is "how is this read?" instead of "find the sound"
    static var readChance: Double { [0.4, 0.55, 0.65][max(0, min(2, playing - 1))] }
    /// hearts in a battle
    static var hearts: Int { playing >= 3 ? 2 : 3 }
    /// mini-games: the goal goes up a little each round
    static var miniTarget: Double { [1.0, 1.0, 1.1][max(0, min(2, playing - 1))] }
    /// kanji words count as readable (from round 2 every taught word may be asked)
    static var kanji: Bool { playing >= 2 }
    /// round 2: the reading is shown over kanji
    static var furigana: Bool { playing == 2 }
}

extension KJData {
    /// how a word is read: one kanji (日 → にち) or a kanji word of round 2 / 3 (食べる → たべる)
    static func yomi(_ s: String) -> String? { readings[s] ?? readingsLap[s] }
    /// kanji that look alike (rounds 2-3 games and battles use them as traps)
    static let lookAlike3: [[String]] = [["木", "本", "休", "体"], ["土", "上", "下"], ["天", "大", "太", "犬"], ["雨", "雪", "電"], ["右", "石", "左"],
        ["東", "車", "西"], ["町", "田", "男"], ["月", "目", "日"], ["口", "日", "田"], ["百", "白"], ["四", "西"], ["人", "入", "八"], ["力", "九"],
        ["千", "十"], ["円", "内"], ["手", "千"], ["子", "字"], ["火", "水"], ["前", "後"], ["春", "夏"], ["花", "化"], ["空", "雪"], ["門", "間"],
        ["北", "南"], ["気", "元"], ["海", "母"]]
}

/// a word with its reading over it in round 2 (ふりがな); plain in rounds 1 and 3
struct KJFuri: View {
    let text: String
    var size: CGFloat
    var font: Font? = nil
    var color: Color = Color.ink
    var force: Bool? = nil

    init(_ text: String, size: CGFloat, font: Font? = nil, color: Color = Color.ink, force: Bool? = nil) {
        self.text = text; self.size = size; self.font = font; self.color = color; self.force = force
    }

    private var ruby: String? {
        guard force ?? KJLap.furigana, KJSimilar.hasKanji(text), let r = KJData.yomi(text) else { return nil }
        return r
    }

    var body: some View {
        VStack(spacing: 0) {
            if let r = ruby {
                Text(r).font(.ui(max(10, size * 0.3), bold: false)).foregroundStyle(color.opacity(0.75))
                    .lineLimit(1).minimumScaleFactor(0.5)
            }
            Text(text).font(font ?? .custom(Fonts.rounded, size: size)).foregroundStyle(color)
                .lineLimit(1).minimumScaleFactor(0.4)
        }
    }
}

/// the map's round switcher: 1しゅうめ ソラ / 2しゅうめ ユイ / 3しゅうめ ふたり
struct KJLapSwitch: View {
    @Binding var lap: Int

    var body: some View {
        HStack(spacing: 6.s) {
            ForEach(1...KJLap.count, id: \.self) { n in
                let ok = KJLap.open(n)
                Button {
                    guard ok else {
                        // a paid round: show the shop; otherwise it opens after the last boss of the round before
                        if n > 1 && !KJLap.bought { AudioManager.shared.se(.decide); AppState.shared.sheet = .shop }
                        else { AudioManager.shared.se(.wrong, volume: 0.5) }
                        return
                    }
                    AudioManager.shared.se(.decide)
                    withAnimation(.easeInOut(duration: 0.2)) { lap = n }
                    KJLap.selected = n
                } label: {
                    HStack(spacing: 3.s) {
                        if ok {
                            HStack(spacing: -8.s) {
                                ForEach(KJLap.partnerFaces(n), id: \.self) { f in
                                    Image(f).resizable().scaledToFit().frame(height: 26.s)
                                }
                            }
                        } else {
                            Image(systemName: n > 1 && !KJLap.bought ? "crown.fill" : "lock.fill").font(.system(size: 12.s, weight: .bold))
                        }
                        Text(KJLap.name(n)).font(.custom(Fonts.rounded, size: 12.s)).lineLimit(1).minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(lap == n ? Color.white : Color.ink.opacity(ok ? 1 : 0.45))
                    .padding(.horizontal, 8.s).padding(.vertical, 4.s)
                    .frame(maxWidth: .infinity)
                    .background(Capsule().fill(lap == n ? Color.pop : ok ? Color.white : Color(hex: 0xD9D4EA)))
                    .overlay(Capsule().stroke(Color.ink, lineWidth: 2.5))
                }
                .buttonStyle(PressStyle(radius: 16.s, depth: 3))
            }
        }
        .padding(.horizontal, 14.s)
    }
}
