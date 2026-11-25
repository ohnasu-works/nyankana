import SwiftUI

// MARK: - にゃんカナの ずかん（ボス・ザコ ようかい・なかま・ことば）

enum KJZukan {
    /// all minion pictures (nk_001 …), split into the seven regions
    static let allMinions: [String] = (1...437).map { String(format: "nk_%03d", $0) }.filter { UIImage(named: $0) != nil }
    static func minions(_ chapter: Int) -> [String] {
        let all = allMinions
        guard !all.isEmpty else { return ["nk_342"] }
        let per = max(1, all.count / 7)
        let c = max(1, min(7, chapter)) - 1
        let end = c == 6 ? all.count : min(all.count, (c + 1) * per)
        return Array(all[min(c * per, all.count - 1)..<end])
    }

    private static let key = "kj.zukan.seen"
    static var seen: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: key) ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: key) }
    }
    static func see(_ img: String) {
        var s = seen
        if s.insert(img).inserted { seen = s }
    }

    struct Boss { var chapter: Int; var image: String; var ja, en, zh, ko: String; var mid: Bool }
    static let bosses: [Boss] = [
        Boss(chapter: 1, image: "boss_kyubi", ja: "きゅうびの きつね", en: "Nine-tailed Fox", zh: "九尾狐", ko: "구미호", mid: false),
        Boss(chapter: 2, image: "boss_will", ja: "かっぱ", en: "Kappa", zh: "河童", ko: "갓파", mid: false),
        Boss(chapter: 3, image: "boss_have", ja: "ゆきおんな", en: "Snow Woman", zh: "雪女", ko: "설녀", mid: false),
        Boss(chapter: 4, image: "boss_seven", ja: "てんぐ", en: "Tengu", zh: "天狗", ko: "덴구", mid: false),
        Boss(chapter: 5, image: "boss_if", ja: "おに", en: "Oni", zh: "鬼", ko: "오니", mid: false),
        Boss(chapter: 6, image: "boss_logic", ja: "たぬき", en: "Tanuki", zh: "狸貓", ko: "너구리", mid: false),
        Boss(chapter: 7, image: "boss_silence", ja: "キジムナー", en: "Kijimuna", zh: "樹精", ko: "키지무나", mid: false),
        Boss(chapter: 1, image: "mid_karakasa", ja: "からかさおばけ", en: "Umbrella Ghost", zh: "傘妖", ko: "우산 요괴", mid: true),
    ] + (2...7).map { c in Boss(chapter: c, image: "zk_\(c)_3", ja: "\(KJC1.chapterNames[c]?.ja ?? "")の ちゅうボス", en: "Mid-boss of \(KJC1.chapterNames[c]?.en ?? "")", zh: "\(KJC1.chapterNames[c]?.zh ?? "")的中頭目", ko: "\(KJC1.chapterNames[c]?.ko ?? "")의 중간 보스", mid: true) }

    /// beaten: its stage has a star
    static func beaten(_ b: Boss) -> Bool {
        KJC1.stages(in: b.chapter).contains { s in (b.mid ? s.kind == .mid : s.kind == .boss) && KJC1.stars(s.id) > 0 }
    }

    /// words met in cleared stages
    static var learnedWords: Set<String> {
        Set(KJC1.stages.filter { KJC1.stars($0.id) > 0 }.flatMap(\.words))
    }
}

struct KJZukanView: View {
    @EnvironmentObject var app: AppState
    @State private var tab = 0
    @State private var chapter = 1
    @State private var show: (image: String, name: String, sub: String)?

    var body: some View {
        SubScreen(title: L("home.zukan"), color: .grass, bg: Color(hex: 0xB9EDB0)) {
            VStack(spacing: 10.s) {
                tabs
                ScrollView {
                    VStack(spacing: 12.s) {
                        switch tab {
                        case 0: bossGrid
                        case 1: minionGrid
                        case 2: friends
                        default: words
                        }
                    }
                    .padding(.horizontal, 16).padding(.bottom, 30)
                }
            }
            .padding(.top, 6)
        }
        .overlay {
            if let s = show {
                ZStack {
                    Color.black.opacity(0.45).ignoresSafeArea().onTapGesture { show = nil }
                    VStack(spacing: 10.s) {
                        Image(s.image).resizable().scaledToFit().frame(height: 220.s)
                        Text(s.name).font(.custom(Fonts.rounded, size: 24.s)).foregroundStyle(Color.ink)
                        if !s.sub.isEmpty { Text(s.sub).font(.ui(14.s)).foregroundStyle(Color.ink.opacity(0.7)) }
                    }
                    .padding(24.s)
                    .background(RoundedRectangle(cornerRadius: 24.s).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 24.s).stroke(Color.ink, lineWidth: 3.5)))
                    .padding(30.s)
                    .onTapGesture { show = nil }
                }
            }
        }
        .onAppear { AudioManager.shared.playBGM(.track("zukan")) }
    }

    private var tabs: some View {
        HStack(spacing: 6.s) {
            ForEach(Array(["ボス", "ようかい", "なかま", "ことば"].enumerated()), id: \.offset) { i, t in
                Button { AudioManager.shared.se(.tap); tab = i } label: {
                    Text(t).font(.custom(Fonts.rounded, size: 14.s)).foregroundStyle(tab == i ? .white : Color.ink)
                        .frame(maxWidth: .infinity).padding(.vertical, 7.s)
                        .background(Capsule().fill(tab == i ? Color.grass : Color.white).overlay(Capsule().stroke(Color.ink, lineWidth: 2.5)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
    }

    private func cell(_ image: String, open: Bool, label: String, height: CGFloat) -> some View {
        VStack(spacing: 3.s) {
            Image(image).resizable().scaledToFit().frame(height: height)
                .colorMultiply(open ? .white : .black).opacity(open ? 1 : 0.25)
            Text(open ? label : "？？？").font(.ui(11.s)).foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity).padding(6.s)
        .background(RoundedRectangle(cornerRadius: 12.s).fill(Color.white.opacity(0.9)).overlay(RoundedRectangle(cornerRadius: 12.s).stroke(Color.ink, lineWidth: 2)))
    }

    private var bossGrid: some View {
        let got = KJZukan.bosses.filter(KJZukan.beaten).count
        return VStack(spacing: 10.s) {
            Text("\(got) / \(KJZukan.bosses.count)").font(.display(18.s)).foregroundStyle(Color.ink)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10.s), count: 2), spacing: 10.s) {
                ForEach(KJZukan.bosses, id: \.image) { b in
                    let open = KJZukan.beaten(b)
                    Button {
                        guard open else { AudioManager.shared.se(.wrong, volume: 0.4); return }
                        AudioManager.shared.se(.decide)
                        show = (b.image, b.ja, KJ.t(b.en, b.zh, b.ko))
                    } label: { cell(b.image, open: open, label: b.ja, height: 120.s) }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var minionGrid: some View {
        let list = KJZukan.minions(chapter)
        let seen = KJZukan.seen
        return VStack(spacing: 10.s) {
            // region picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6.s) {
                    ForEach(1...7, id: \.self) { c in
                        Button { AudioManager.shared.se(.tap); chapter = c } label: {
                            Text(KJC1.chapterNames[c]?.ja ?? "").font(.custom(Fonts.rounded, size: 13.s))
                                .foregroundStyle(chapter == c ? .white : Color.ink)
                                .padding(.horizontal, 10.s).padding(.vertical, 5.s)
                                .background(Capsule().fill(chapter == c ? Color.pop : Color.white).overlay(Capsule().stroke(Color.ink, lineWidth: 2)))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            Text("\(list.filter { seen.contains($0) }.count) / \(list.count)").font(.display(16.s)).foregroundStyle(Color.ink)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8.s), count: 4), spacing: 8.s) {
                ForEach(list, id: \.self) { m in
                    let open = seen.contains(m)
                    let no = "No.\(Int(m.dropFirst(3)) ?? 0)"
                    Button {
                        guard open else { return }
                        AudioManager.shared.se(.decide)
                        show = (m, no, KJ.t("A yokai minion that ate letters", "吃掉文字的小妖怪", "글자를 먹은 졸개 요괴"))
                    } label: { cell(m, open: open, label: no, height: 58.s) }
                    .buttonStyle(.plain)
                }
            }
            Text(KJ.t("Minions appear in battles. Meet them all!", "小嘍囉會在戰鬥中出現，全部見一次吧！", "졸개는 배틀에 나와요. 모두 만나 봐요!"))
                .font(.ui(11.s, bold: false)).foregroundStyle(Color.ink.opacity(0.6))
        }
    }

    private var friends: some View {
        let list: [(String, String, String)] = [
            ("sora_full", "ソラ", KJ.t("A boy traveling Japan with Nyan", "和喵一起旅行日本的少年", "냥과 일본을 여행하는 소년")),
            ("nyan", "ニャン", KJ.t("A talking cat who loves fish", "愛吃魚、會說話的貓", "생선을 좋아하는 말하는 고양이")),
            ("npc_nakamise", "なかみせの おみせの ひと", KJ.t("Shop keeper in Asakusa", "淺草的店員", "아사쿠사의 가게 주인")),
            ("npc_chinatown", "ちゅうかがいの おみせの ひと", KJ.t("Shop keeper in Yokohama Chinatown", "橫濱中華街的店員", "요코하마 차이나타운 가게 주인")),
            ("npc_akiba_fans", "あきはばらの ファン", KJ.t("Fans in Akihabara", "秋葉原的粉絲", "아키하바라의 팬")),
            ("npc_sanzaru", "さんざる", KJ.t("The three wise monkeys of Nikko", "日光的三猿", "닛코의 세 원숭이")),
            ("npc_tonbi", "とんび", KJ.t("A kite bird that snatches food", "會搶食物的老鷹", "음식을 낚아채는 솔개")),
        ]
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10.s), count: 2), spacing: 10.s) {
            ForEach(list, id: \.0) { f in
                Button { AudioManager.shared.se(.decide); show = (f.0, f.1, f.2) } label: { cell(f.0, open: true, label: f.1, height: 110.s) }
                    .buttonStyle(.plain)
            }
        }
    }

    private var words: some View {
        let learned = KJZukan.learnedWords
        let all = KJData.words
        return VStack(spacing: 10.s) {
            Text("\(all.filter { learned.contains($0.ja) }.count) / \(all.count)").font(.display(18.s)).foregroundStyle(Color.ink)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8.s), count: 3), spacing: 8.s) {
                ForEach(all, id: \.ja) { w in
                    let open = learned.contains(w.ja)
                    Button {
                        guard open else { return }
                        Speaker.shared.say(w.ja)
                    } label: {
                        VStack(spacing: 2.s) {
                            Text(open ? w.emoji : "❔").font(.system(size: 28.s))
                            Text(open ? w.ja : "？？？").font(.custom(Fonts.rounded, size: 15.s)).foregroundStyle(Color.ink)
                                .lineLimit(1).minimumScaleFactor(0.5)
                            Text(open ? w.meaning : "").font(.ui(10.s, bold: false)).foregroundStyle(Color.ink.opacity(0.65)).lineLimit(1).minimumScaleFactor(0.6)
                        }
                        .frame(maxWidth: .infinity).frame(height: 84.s)
                        .background(RoundedRectangle(cornerRadius: 12.s).fill(Color.white.opacity(open ? 0.95 : 0.6)).overlay(RoundedRectangle(cornerRadius: 12.s).stroke(Color.ink, lineWidth: 2)))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
