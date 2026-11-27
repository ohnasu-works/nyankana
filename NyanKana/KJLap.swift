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
    /// the round whose look (colors, map music) is on screen: the map's round, or the stage's
    static var look = 1

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

/// the bosses of rounds 2 and 3 (new yokai; round 1 keeps the first seven)
struct KJLapBoss {
    var role: String        // its recorded voice
    var image: String
    var ja: String, en: String, zh: String, ko: String   // its name
    var intro: String, half: String, out: String         // what it says in the battle
}

extension KJLap {
    static let bosses: [Int: [Int: KJLapBoss]] = [
        2: [
            1: .init(role: "rokuro", image: "boss2_rokuro", ja: "ろくろくび", en: "Rokurokubi", zh: "轆轤首", ko: "로쿠로쿠비",
                     intro: "くびを のばして、かんじを ぜんぶ たべちゃうわよ。", half: "まだまだ くびは のびるわよ！", out: "くびが こんがらがった……まいったわ。"),
            2: .init(role: "zashiki", image: "boss2_zashiki", ja: "ざしきわらし", en: "Zashiki-warashi", zh: "座敷童子", ko: "자시키와라시",
                     intro: "あそぼ！ かんじを まちがえたら、ずっと ここに いてね。", half: "えへへ、まだ まけないよ！", out: "まけた〜。また あそんでね！"),
            3: .init(role: "koro", image: "boss2_koro", ja: "コロポックル", en: "Korpokkur", zh: "克魯波克魯", ko: "코로폿쿠루",
                     intro: "ふきの はの したに、かんじを かくしたよ。", half: "ちいさくても つよいんだぞ！", out: "みつかっちゃった。ふきの はを どうぞ。"),
            4: .init(role: "yamanba", image: "boss2_yamanba", ja: "やまんば", en: "Yamanba", zh: "山姥", ko: "야만바",
                     intro: "ふりがなに たよって いるね？ ためして あげよう！", half: "ほう、なかなか やるね。", out: "見事だね。その かんじ、もう あんたの ものだよ。"),
            5: .init(role: "nurari", image: "boss2_nurari", ja: "ぬらりひょん", en: "Nurarihyon", zh: "滑瓢", ko: "누라리횬",
                     intro: "わしは ようかいの おやぶん。この かんじが よめるかな？", half: "ふぉっふぉっ、おもしろい。", out: "まいった……。ユイ、つよいのう。"),
            6: .init(role: "inugami", image: "boss2_inugami", ja: "いぬがみ", en: "Inugami", zh: "犬神", ko: "이누가미",
                     intro: "ワン！ この かんじ、においで わかるか？", half: "グルル……まだだ！", out: "ワン……。おまえたちの かちだ。"),
            7: .init(role: "ittan", image: "boss2_ittan", ja: "いったんもめん", en: "Ittan-momen", zh: "一反木綿", ko: "잇탄모멘",
                     intro: "ひらひら〜。かんじを ぜんぶ つつんで とんで いくよ！", half: "かぜに のって、まだまだ とぶよ！", out: "ほどけちゃった……。かんじは かえすよ。"),
        ],
        3: [
            1: .init(role: "gasha", image: "boss3_gasha", ja: "がしゃどくろ", en: "Gashadokuro", zh: "餓者髑髏", ko: "가샤도쿠로",
                     intro: "ふりがなの ない せかいへ ようこそ。", half: "ガシャガシャ……まだ たおれんぞ。", out: "二人の ちから……みごとだ。"),
            2: .init(role: "namahage", image: "boss3_namahage", ja: "なまはげ", en: "Namahage", zh: "生剝鬼", ko: "나마하게",
                     intro: "わるい 子は いねが〜！ ふりがな なしで よめるか！", half: "うおお、なかなか いい 子だ！", out: "いい 子たちだ。もう 来ないぞ。"),
            3: .init(role: "tsurara", image: "boss3_tsurara", ja: "つららおんな", en: "Tsurara-onna", zh: "冰柱女", ko: "쓰라라온나",
                     intro: "あなたたちの ことば、とかして みせて……。", half: "つめたい かぜを ふかせて あげる……。", out: "……もう さむくない。"),
            4: .init(role: "satori", image: "boss3_satori", ja: "さとり", en: "Satori", zh: "覺", ko: "사토리",
                     intro: "おまえの かんがえ、ぜんぶ よめるぞ。かんじは よめるかな？", half: "むむ、かんがえが よめない……！", out: "もう 何も おしえる ことは ない。"),
            5: .init(role: "tsuchigumo", image: "boss3_tsuchigumo", ja: "つちぐも", en: "Tsuchigumo", zh: "土蜘蛛", ko: "쓰치구모",
                     intro: "三人 そろったか！ この あみから にげられるか！", half: "あみが きれた！？", out: "いっしょに たこやき、食べに いこう。"),
            6: .init(role: "umibozu", image: "boss3_umibozu", ja: "うみぼうず", en: "Umibozu", zh: "海坊主", ko: "우미보즈",
                     intro: "なみの ように、かんじが おしよせるぞ！", half: "ざぶーん！ まだまだ！", out: "まいった。もう うみは しずかだ。"),
            7: .init(role: "shisa", image: "boss3_shisa", ja: "シーサー", en: "Shisa", zh: "風獅爺", ko: "시사",
                     intro: "さいごの しれん！ ぜんぶ おぼえてるか、ためして みよう！", half: "ガオー！ まだ おわらないぞ！", out: "すごい！ もう 日本語の たびびとだね。"),
        ],
    ]
    static func boss(lap: Int, chapter: Int) -> KJLapBoss? { bosses[lap]?[chapter] }
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
