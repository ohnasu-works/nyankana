import SwiftUI

// MARK: - Area enemies (picture book)

/// Six enemies drawn for each area: cute, gross and creepy-cute ones.
enum AreaFoes {
    static func images(_ a: Area) -> [String] { (0..<6).map { "zk_\(a.rawValue)_\($0)" } }

    static let names: [String: String] = {
        let n: [[String]] = [
            ["Posty", "Vendy", "Signal Eyes", "Trashy", "Peeper", "Ringaling"],
            ["Hoverby", "Dronny", "Dust Gulp", "Crackphone", "Neon Fang", "Dish Eye"],
            ["Trophie", "Medalie", "Spit Whistle", "Patchball", "Shouter", "Candy Eyes"],
            ["Pillowpuff", "Dingbell", "Cloche Mouth", "Stinky Slipper", "Eyelier", "Zipkey"],
            ["Sprinkle", "Rosie", "Cabbage Snail", "Fungmouth", "Hive Eyes", "Hose Snake"],
            ["Flasky", "Magnetto", "Sludge Tube", "Calcuscream", "Brain Bulb", "Gear Eye"],
            ["Candlet", "Melody Box", "Drool Knight", "Bite Book", "Long Knight", "Hush Bell"],
        ]
        var d: [String: String] = [:]
        for (a, row) in n.enumerated() { for (i, s) in row.enumerated() { d["zk_\(a + 1)_\(i)"] = s } }
        for (i, s) in GameEvents.rareNames.enumerated() { d[GameEvents.rares[i]] = s }
        for (i, s) in ["Octo Thief", "Cart Grabber", "Bat Case"].enumerated() { d["kidnap_\(i)"] = s }
        for (i, p) in GameEvents.possessed.enumerated() { d["poss_\(i + 3)"] = p.monsterName }
        return d
    }()
}

// MARK: - Event data

/// A line for event scenes: English (spoken) + subtitles.
struct EventLine: Equatable {
    var en: String, ja: String, ko: String, zh: String
    /// lines built at run time (with a name inside) cannot be looked up in the tables, so they carry their own
    var vi: String? = nil, es: String? = nil, pt: String? = nil
    var sub: String {
        switch L10n.current {
        case .ja: jp(ja); case .ko: ko; case .zhHant: zh; case .en: ""
        case .vi: vi ?? Tr.text(ja); case .es: es ?? Tr.text(ja); case .ptBR: pt ?? Tr.text(ja)
        }
    }
}

/// What the event card shows over the street.
struct EventScene: Equatable {
    enum Tone { case talk, help, evil, thanks, rare }
    var image: String
    var line: EventLine
    var tone: Tone
}

enum GameEvents {
    // Rare runaway: like a metal slime. Short timer, big reward.
    static let rares = ["rare_0", "rare_1", "rare_2"]
    static let rareNames = ["Silver Mochi", "Gold Mochi", "Rainbow Mochi"]
    static let rareScore = [3000, 6000, 15000]
    static func rollRare() -> Int { let r = Double.random(in: 0..<1); return r < 0.06 ? 2 : r < 0.3 ? 1 : 0 }
    static func rareFound(_ k: Int) -> EventLine {
        let n = rareNames[k]
        return .init(en: "A wild \(n)! Answer fast!", ja: "\(n)が|あらわれた！|すぐ|答えて！", ko: "\(n) 등장! 빨리 답해!", zh: "\(n)出現了！快回答！",
                     vi: "\(n) xuất hiện! Trả lời nhanh!", es: "¡Apareció \(n)! ¡Responde rápido!", pt: "\(n) apareceu! Responda rápido!")
    }
    static func rareGot(_ k: Int) -> EventLine {
        let n = rareNames[k]
        return .init(en: "You caught the \(n)!", ja: "\(n)を|つかまえた！", ko: "\(n)을(를) 잡았다!", zh: "抓到\(n)了！",
                     vi: "Bắt được \(n) rồi!", es: "¡Atrapaste a \(n)!", pt: "Você pegou \(n)!")
    }
    static let rareRan = EventLine(en: "It ran away...", ja: "にげられた…", ko: "도망쳤다…", zh: "逃走了…")

    // Kidnap: a townsperson is being carried off. Beat the kidnapper before it gets away -> heal.
    static let kidnappers = ["kidnap_0", "kidnap_1", "kidnap_2"]
    static let captives = (0..<6).map { "capt_\($0)" }
    static let help: [EventLine] = [
        .init(en: "Help! Somebody help me!", ja: "たすけて！|だれか|たすけて！", ko: "살려 줘! 누가 좀 도와줘!", zh: "救命！誰來救救我！"),
        .init(en: "Please save me! It's taking me away!", ja: "おねがい、|たすけて！|連れていかれちゃう！", ko: "제발 구해 줘! 끌려가고 있어!", zh: "拜託救救我！我要被帶走了！"),
        .init(en: "Help! I don't want to lose my words!", ja: "たすけて！|ことばを|とられたくない！", ko: "도와줘! 말을 빼앗기기 싫어!", zh: "救命！我不想失去語言！"),
    ]
    static let kidnapRule = EventLine(en: "Beat it before it escapes!", ja: "にげられる前に|たおそう！|助けると|ライフ回復！", ko: "도망가기 전에 쓰러뜨리자! 구하면 라이프 회복!", zh: "在它逃走前打倒它！救出後恢復生命！")
    static let thanks: [EventLine] = [
        .init(en: "Thank you so much! Here, take this!", ja: "ありがとう！|これ、|受け取って！", ko: "정말 고마워! 이거 받아!", zh: "謝謝你！這個給你！"),
        .init(en: "You saved me! You're my hero!", ja: "助かった！|きみは|ヒーローだよ！", ko: "살았다! 넌 나의 영웅이야!", zh: "得救了！你是我的英雄！"),
        .init(en: "Thank you! I feel full of energy!", ja: "ありがとう！|元気が|出てきた！", ko: "고마워! 힘이 난다!", zh: "謝謝！我充滿活力了！"),
    ]
    static let gotAway = EventLine(en: "Oh no, it got away...", ja: "ああ、|にげられた…", ko: "아, 놓쳤다…", zh: "啊，被逃走了…")

    // Possessed: a friendly townsperson talks to you... then turns into a monster.
    struct Possessed {
        var normal: String
        var monster: String
        var monsterName: String
        var talk: [EventLine]
        var turn: EventLine
        var freed: EventLine
    }
    static let possessed: [Possessed] = [
        .init(normal: "poss_0", monster: "poss_3", monsterName: "Dark Baker",
              talk: [.init(en: "Hello there! Would you like some fresh bread?", ja: "やあ！|焼きたての|パンは|いかが？", ko: "안녕! 갓 구운 빵 먹을래?", zh: "你好！要來點剛出爐的麵包嗎？"),
                     .init(en: "It's free... if you give me your WORDS!", ja: "タダだよ…|きみの|ことばを|くれるならね！", ko: "공짜야… 네 말을 준다면!", zh: "免費的…只要你把語言給我！")],
              turn: .init(en: "Your words look delicious!", ja: "きみの|ことば、|おいしそう！", ko: "네 말, 맛있어 보여!", zh: "你的語言看起來好好吃！"),
              freed: .init(en: "Huh? What was I doing? Thank you for saving me!", ja: "あれ？|わたし、|何を…？|助けてくれて|ありがとう！", ko: "어? 내가 뭘 하고 있었지? 구해 줘서 고마워!", zh: "咦？我剛剛在做什麼？謝謝你救了我！")),
        .init(normal: "poss_1", monster: "poss_4", monsterName: "Dark Clerk",
              talk: [.init(en: "Excuse me, could you check this document for me?", ja: "すみません、|この書類を|見てもらえますか？", ko: "실례지만, 이 서류 좀 봐 줄래요?", zh: "不好意思，可以幫我看一下這份文件嗎？"),
                     .init(en: "Just sign here... and hand over ALL your English!", ja: "ここに|サインして…|英語を|ぜんぶ|わたしなさい！", ko: "여기 사인하고… 영어를 전부 넘겨!", zh: "在這裡簽名…然後把英文全部交出來！")],
              turn: .init(en: "No more grammar for you!", ja: "文法は|もう|使わせない！", ko: "이제 문법은 못 쓰게 할 거야!", zh: "不准你再用文法！"),
              freed: .init(en: "Oh my... I was not myself. Thank you!", ja: "まあ…|わたし、|どうかしてたわ。|ありがとう！", ko: "어머… 내가 제정신이 아니었네. 고마워!", zh: "哎呀…我剛才不太對勁。謝謝你！")),
        .init(normal: "poss_2", monster: "poss_5", monsterName: "Dark Granny",
              talk: [.init(en: "My, what nice young people! Come closer, dears.", ja: "あら、|いい子たちだね。|もっと|近くに|おいで。", ko: "어머, 착한 아이들이구나. 더 가까이 오렴.", zh: "哎呀，真是好孩子。靠近一點吧。"),
                     .init(en: "Closer... so I can EAT your words!", ja: "もっと|近くに…|ことばを|食べてあげるから！", ko: "더 가까이… 네 말을 먹어 줄 테니!", zh: "再近一點…讓我吃掉你的語言！")],
              turn: .init(en: "Granny is hungry for words!", ja: "おばあちゃん、|ことばが|食べたいの！", ko: "할머니는 말이 먹고 싶단다!", zh: "奶奶想吃語言！"),
              freed: .init(en: "Oh dear, thank you. Here's a little treat for you.", ja: "おやまあ、|ありがとうね。|これ、|おやつだよ。", ko: "아이고, 고맙구나. 이건 간식이야.", zh: "哎呀，謝謝你們。這是給你們的點心。")),
    ]
    static let possessedWarn = EventLine(en: "Something is wrong...!", ja: "なにか|ようすが|おかしい…！", ko: "뭔가 이상해…!", zh: "好像有點不對勁…！")
}

// MARK: - Event card (shown over the street)

struct EventCard: View {
    let scene: EventScene
    var body: some View {
        HStack(alignment: .bottom, spacing: 6.s) {
            Image(scene.image).resizable().scaledToFit()
                .frame(width: 84.s, height: 110.s)
                .shadow(color: glow, radius: scene.tone == .evil || scene.tone == .rare ? 10 : 0)
                .modifier(Wobble(on: scene.tone == .help || scene.tone == .evil))
            VStack(alignment: .leading, spacing: 3.s) {
                Text(scene.line.en).font(.en(after ? 13.s : 15.s)).foregroundStyle(scene.tone == .evil ? Color.white : Color.ink)
                    .lineLimit(after ? 3 : 2).minimumScaleFactor(0.7)
                Text(scene.line.sub).font(.ui(11.s, bold: false))
                    .foregroundStyle(scene.tone == .evil ? Color.white.opacity(0.85) : Color.ink.opacity(0.7))
                    .lineLimit(2).minimumScaleFactor(0.7)
            }
            .padding(.horizontal, 12.s).padding(.vertical, 8.s)
            // after a rescue the person stands in the middle of the street: a smaller, lower bubble keeps them in view
            .frame(maxWidth: after ? 190.s : 260.s, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16.s).fill(fill).overlay(RoundedRectangle(cornerRadius: 16.s).stroke(Color.ink, lineWidth: 3)))
            .padding(.bottom, after ? 0 : 30.s)
        }
        .transition(.move(edge: .leading).combined(with: .opacity))
    }
    private var fill: Color {
        switch scene.tone {
        case .talk: .white
        case .help: Color(hex: 0xFFE3EC)
        case .evil: Color(hex: 0x5B2A86)
        case .thanks: Color(hex: 0xDDFBEA)
        case .rare: Color(hex: 0xFFF6C8)
        }
    }
    private var glow: Color { scene.tone == .evil ? Color.purple : Color.yellow }
    private var after: Bool { scene.tone == .thanks || scene.tone == .rare }
}

private struct Wobble: ViewModifier {
    let on: Bool
    @State private var t = false
    func body(content: Content) -> some View {
        content.rotationEffect(.degrees(on && t ? 4 : on ? -4 : 0))
            .onAppear { if on { withAnimation(.easeInOut(duration: 0.18).repeatForever(autoreverses: true)) { t = true } } }
    }
}
