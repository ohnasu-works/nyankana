import SwiftUI

/// What one character looks and sounds like in story scenes and on the battlefield.
struct CastInfo {
    var name: String
    var image: String
    var left = false
    var boss = false
    var scale: CGFloat = 1
    var voice: Speaker.Voice = .normal
}

/// A character id ("ken", "will", "willFree", "cake"…). Stored as a plain string in story JSON.
struct Cast: Codable, Hashable {
    let id: String
    init(_ id: String) { self.id = id }
    init(from decoder: Decoder) throws { id = try decoder.singleValueContainer().decode(String.self) }
    func encode(to encoder: Encoder) throws { var c = encoder.singleValueContainer(); try c.encode(id) }

    static let ken = Cast("ken"), rin = Cast("rin"), nyan = Cast("nyan")
    static let bee = Cast("bee"), beeFree = Cast("beeFree"), stapler = Cast("stapler")

    private var info: CastInfo { Cast.table[id] ?? Cast.table["nyan"]! }
    var name: String { info.name }
    /// costumes for ソラ / ユイ are not drawn yet, so the travel clothes are always shown
    var image: String { (id == "ken" || id == "rin") ? info.image : (Cast.outfitImage[id] ?? info.image) }
    /// costume picture per kid ("ken" -> "ken_uniform"), set by `Outfit.sync`
    static var outfitImage: [String: String] = [:]
    var leftSide: Bool { info.left }
    var isBoss: Bool { info.boss }
    /// height in the story scene, relative to Ken / Rin
    var storyScale: CGFloat { info.scale }
    var voice: Speaker.Voice { info.voice }

    static let table: [String: CastInfo] = {
        var t: [String: CastInfo] = [
            // にゃんカナ: the partner ソラ (id "ken") or ユイ (id "rin"); the ids are kept from にゃんグリッシュ
            "ken": .init(name: L10n.current == .ja ? "ソラ" : "Sora", image: "sora_full", left: true, voice: .init(pitch: 0.9, rate: 0.95)),
            "rin": .init(name: L10n.current == .ja ? "ユイ" : "Yui", image: "yui_full", scale: 0.97,
                       voice: .init(pitch: 1.15, rate: 0.95)),
            "nyan": .init(name: "Nyan", image: "nyan", left: true, scale: 0.45, voice: .init(pitch: 1.6, rate: 1.05)),
        ]
        for b in BossProfile.bosses {
            t[b.key] = .init(name: b.name, image: "boss_\(b.key)", boss: true, scale: 1.55, voice: b.voice)
            t[b.key + "Free"] = .init(name: b.freeName, image: "boss_\(b.key)_free", boss: false, scale: 0.85, voice: b.freeVoice)   // human again: about Ken's size
        }
        for m in BossProfile.mids {
            t[m.key] = .init(name: m.name, image: "mid_\(m.key)", boss: true, scale: 1.45, voice: m.voice)
        }
        return t
    }()
}

/// A boss or mid boss: who it is and what it says in battle.
struct BossProfile {
    var key: String
    var name: String
    var freeName: String = ""
    var voice: Speaker.Voice
    var freeVoice: Speaker.Voice = .normal
    var intro: L4
    var half: L4
    var out: L4

    var cast: Cast { Cast(key) }
    var freeCast: Cast { Cast(key + "Free") }
    var image: String { (BossProfile.mids.contains { $0.key == key } ? "mid_" : "boss_") + key }
    var freeImage: String { "boss_\(key)_free" }

    /// four-language text: English line + subtitles
    struct L4 { var en, ja, ko, zh: String }

    // MARK: area bosses (Lv1…graduation)
    static let bosses: [BossProfile] = [
        .init(key: "bee", name: "Miss Bee", freeName: "Miss Bee", voice: .init(pitch: 1.55, rate: 0.95), freeVoice: .init(pitch: 1.3, rate: 0.95),
              intro: .init(en: "Bzzz! I am Miss Bee! Your words are mine!", ja: "ブーン！|わたしは|ミス・ビー！|あなたの言葉は|わたしのものよ！", ko: "윙윙! 나는 미스 비! 너희 말은 전부 내 거야!", zh: "嗡嗡！我是比小姐！你們的話都是我的！"),
              half: .init(en: "Ouch! That stings!", ja: "いたっ！|しみるわ！", ko: "아야! 따가워!", zh: "好痛！好刺！"),
              out: .init(en: "Thank you... I am free!", ja: "ありがとう…|自由に|なれたわ！", ko: "고마워… 이제 자유야!", zh: "謝謝……我自由了！")),
        .init(key: "will", name: "Clockwork Will", freeName: "Will", voice: .init(pitch: 0.7, rate: 0.9), freeVoice: .init(pitch: 0.9, rate: 0.95),
              intro: .init(en: "Tick-tock! I will stop every clock. You will never be on time!", ja: "チクタク！|すべての時計を|止めてやる。|おまえたちは|もう|間に合わないぞ！", ko: "째깍째깍! 모든 시계를 멈추겠다. 너희는 절대 제시간에 못 올 거야!", zh: "滴答滴答！我要讓所有時鐘停下來。你們永遠趕不上！"),
              half: .init(en: "What? You are faster than my clock!", ja: "なに？|ぼくの時計より|速いだと！", ko: "뭐? 내 시계보다 빠르다니!", zh: "什麼？你們比我的時鐘還快！"),
              out: .init(en: "Thank you. I will fix the town clocks right now!", ja: "ありがとう。|今すぐ|町の時計を|直すよ！", ko: "고마워. 지금 바로 마을 시계를 고칠게!", zh: "謝謝你們。我現在就去修好鎮上的時鐘！")),
        .init(key: "have", name: "Mr. Have", freeName: "Mr. Have", voice: .init(pitch: 0.95, rate: 1.05), freeVoice: .init(pitch: 1.0, rate: 1.0),
              intro: .init(en: "Welcome! Have you ever seen a show like this? I have taken every word!", ja: "ようこそ！|こんなショーを|見たことが|あるかい？|言葉は|全部|いただいたよ！", ko: "어서 와! 이런 쇼 본 적 있어? 단어는 전부 내가 가져갔지!", zh: "歡迎！你看過這樣的表演嗎？所有的字都被我拿走了！"),
              half: .init(en: "Oh no! I have never lost a show before!", ja: "なんと！|ショーで|負けたことは|一度も|ないのに！", ko: "이럴 수가! 쇼에서 진 적은 한 번도 없는데!", zh: "不會吧！我的表演從來沒輸過！"),
              out: .init(en: "The words have come back. This trophy was made for you!", ja: "言葉が|戻ってきた。|このトロフィーは|きみたちの|ものだ！", ko: "단어들이 돌아왔어. 이 트로피는 너희를 위해 만들어진 거야!", zh: "字都回來了。這座獎盃是為你們做的！")),
        .init(key: "seven", name: "Concierge Seven", freeName: "Seven", voice: .init(pitch: 0.8, rate: 0.9), freeVoice: .init(pitch: 0.95, rate: 0.95),
              intro: .init(en: "Welcome to Hotel Seven. Words make guests noisy, so I keep the hotel silent.", ja: "ホテル・セブンへ|ようこそ。|言葉は|お客様を|うるさくする。|だから|静かに|させて|いただきます。", ko: "호텔 세븐에 오신 걸 환영합니다. 말은 손님을 시끄럽게 하니, 호텔을 조용히 유지하겠습니다.", zh: "歡迎光臨七號飯店。言語會讓客人吵鬧，所以我讓飯店保持安靜。"),
              half: .init(en: "Your English makes me nervous!", ja: "きみたちの英語は|わたしを|落ち着かなく|させる！", ko: "너희 영어 때문에 긴장되잖아!", zh: "你們的英文讓我好緊張！"),
              out: .init(en: "I was working for the Gobbles. Now I can welcome real guests again.", ja: "ゴブルズに|使われていました。|これで|また|本当のお客様を|お迎えできます。", ko: "고블스에게 이용당하고 있었어요. 이제 다시 진짜 손님을 맞을 수 있어요.", zh: "我一直在替高布斯做事。現在終於能再迎接真正的客人了。")),
        .init(key: "if", name: "Madame If", freeName: "Madame If", voice: .init(pitch: 1.35, rate: 0.9), freeVoice: .init(pitch: 1.2, rate: 0.95),
              intro: .init(en: "If I had all the words, I would be the only star!", ja: "もし|すべての言葉が|わたしのものなら、|わたしだけが|スターに|なれるのに！", ko: "모든 단어가 내 것이라면, 나만 스타가 될 텐데!", zh: "如果所有的字都是我的，我就會是唯一的明星！"),
              half: .init(en: "If only I had practiced more!", ja: "もっと|練習して|おけば|よかった！", ko: "연습을 더 했더라면!", zh: "要是我多練習一點就好了！"),
              out: .init(en: "If you hadn't come, I would still be wearing that mask.", ja: "あなたたちが|来なかったら、|今も|あの仮面を|つけていたわ。", ko: "너희가 오지 않았다면, 난 아직도 그 가면을 쓰고 있었을 거야.", zh: "如果你們沒有來，我現在還戴著那個面具。")),
        .init(key: "logic", name: "Dr. Logic", freeName: "Dr. Logic", voice: .init(pitch: 0.75, rate: 1.0), freeVoice: .init(pitch: 0.9, rate: 0.95),
              intro: .init(en: "Never have I seen such clever kids. However, logic says you will lose!", ja: "これほど|賢い子どもは|見たことがない。|しかし、|論理的に|きみたちの|負けだ！", ko: "이렇게 똑똑한 아이들은 처음 봐. 하지만 논리적으로 너희가 진다!", zh: "我從沒見過這麼聰明的孩子。不過，按照邏輯，你們會輸！"),
              half: .init(en: "It is your grammar that breaks my theory!", ja: "わたしの理論を|崩しているのは、|きみたちの|文法だ！", ko: "내 이론을 무너뜨리는 건 바로 너희 문법이야!", zh: "打破我理論的，正是你們的文法！"),
              out: .init(en: "Not only did you free me, but you also saved my research.", ja: "わたしを|助けただけで|なく、|研究まで|救ってくれた。", ko: "나를 구했을 뿐 아니라, 내 연구까지 지켜 주었구나.", zh: "你們不只救了我，還救了我的研究。")),
        .init(key: "silence", name: "King Silence", freeName: "Prince Leo", voice: .init(pitch: 0.5, rate: 0.8), freeVoice: .init(pitch: 1.15, rate: 0.95),
              intro: .init(en: "Silence is golden. Without words, no one can hurt anyone. That is why I took them all.", ja: "沈黙は|金なり。|言葉が|なければ、|誰も|傷つかない。|だから|すべて|奪ったのだ。", ko: "침묵은 금이다. 말이 없으면 아무도 상처받지 않아. 그래서 전부 빼앗은 것이다.", zh: "沉默是金。沒有語言，就沒有人會受傷。所以我把它們全部奪走了。"),
              half: .init(en: "Impossible! Little by little, your words are breaking my spell!", ja: "ばかな！|きみたちの言葉が|少しずつ|わたしの魔法を|解いていく！", ko: "말도 안 돼! 너희 말이 조금씩 내 마법을 깨고 있어!", zh: "不可能！你們的話正一點一點地破解我的魔法！"),
              out: .init(en: "...Thank you. I had forgotten how warm words can be.", ja: "…ありがとう。|言葉が|こんなに|温かいなんて、|忘れていたよ。", ko: "…고마워. 말이 이렇게 따뜻하다는 걸 잊고 있었어.", zh: "……謝謝。我都忘了，語言原來可以這麼溫暖。")),
    ]

    // MARK: mid bosses (stage 10 and 20 of Lv1…Lv6, no duplicates)
    static let mids: [BossProfile] = [
        mid("stapler", "Jumbo Stapler", 0.55, 0.85,
            ("STAPLE! I am Jumbo Stapler! Clack, clack!", "ホチキス！|おれは|ジャンボ・ステープラー！", "스테이플! 나는 점보 스테이플러! 철컥철컥!", "釘！我是巨無霸釘書機！喀嚓喀嚓！"),
            ("Ugh! You are strong!", "うっ！|おまえ、|強いな！", "윽! 너 세구나!", "嗚！你好強！"),
            ("Clack... I am just a stapler again.", "カチャ…|ただの|ホチキスに|戻ったよ。", "철컥… 다시 평범한 스테이플러가 됐어.", "喀嚓……我又變回普通的釘書機了。")),
        mid("cake", "Party Cake", 1.45, 1.0,
            ("Happy birthday to me! I ate your words. They were sweet!", "わたしの|お誕生日！|あなたたちの言葉、|食べちゃった。|甘かったわ！", "내 생일 축하해! 너희 말을 먹었어. 달콤했지!", "祝我生日快樂！我吃掉了你們的字，好甜喔！"),
            ("My candles! You blew them out!", "ろうそくが！|吹き消されちゃった！", "내 촛불! 너희가 꺼 버렸어!", "我的蠟燭！被你們吹熄了！"),
            ("Let's share the cake. Words are better together!", "ケーキは|みんなで|分けよう。|言葉も|いっしょの方が|いいね！", "케이크는 같이 나눠 먹자. 말도 함께일 때 더 좋아!", "一起分蛋糕吧。字也是大家一起比較好！")),
        mid("car", "Zoom Car", 1.1, 1.15,
            ("Vroom! I will be faster than you. You can't catch me!", "ブーン！|おれは|おまえたちより|速くなる。|追いつけないぞ！", "부릉! 내가 너희보다 빠를 거야. 날 못 잡아!", "轟轟！我會比你們更快。你們追不上我！"),
            ("Hey! You are quicker than I thought!", "おい！|思ったより|速いな！", "야! 생각보다 빠르잖아!", "喂！你們比我想的還快！"),
            ("I will drive slowly in town from now on.", "これからは|町の中を|ゆっくり|走るよ。", "이제부터 마을에서는 천천히 달릴게.", "從現在起，我在鎮上會慢慢開。")),
        mid("balloons", "Balloon Bunch", 1.7, 1.05,
            ("We want to fly higher than the clouds! Give us more words!", "雲より|高く|飛びたいの！|もっと|言葉を|ちょうだい！", "구름보다 높이 날고 싶어! 단어를 더 줘!", "我們想飛得比雲還高！再給我們更多字！"),
            ("Pop! You are better than us!", "パン！|わたしたちより|上手！", "펑! 너희가 우리보다 잘하네!", "砰！你們比我們厲害！"),
            ("It is fun to float with friends.", "友だちと|いっしょに|浮かぶのは|楽しいね。", "친구들이랑 함께 떠 있는 건 즐거워.", "和朋友一起飄浮好開心。")),
        mid("spotlight", "Spotlight Sam", 1.0, 1.0,
            ("Look at me! I have been the star of this plaza for years!", "見てくれ！|この広場で|何年も|スターだったんだ！", "날 봐! 난 몇 년 동안 이 광장의 스타였어!", "看我！我在這個廣場當了好幾年的明星！"),
            ("I have never been so dazzled!", "こんなに|まぶしいのは|初めてだ！", "이렇게 눈부신 건 처음이야!", "我從來沒這麼眼花過！"),
            ("You have shown me a better light.", "きみたちが|もっと|いい光を|見せてくれた。", "너희가 더 좋은 빛을 보여 줬어.", "你們讓我看見了更好的光。")),
        mid("curtain", "Curtain Queen", 1.25, 0.9,
            ("The show has been closed. No one is allowed on my stage!", "ショーは|閉幕したわ。|わたしの舞台には|誰も|上がらせない！", "공연은 끝났어. 아무도 내 무대에 오를 수 없어!", "表演已經落幕了。誰都不准上我的舞台！"),
            ("My curtain has been torn!", "幕が|やぶられたわ！", "내 커튼이 찢어졌어!", "我的布幕被撕破了！"),
            ("The curtain is opened again. Enjoy the show!", "幕が|また|開いたわ。|ショーを|楽しんでね！", "막이 다시 열렸어. 공연을 즐겨!", "布幕又拉開了。好好享受表演吧！")),
        mid("suitcase", "Big Suitcase", 0.7, 0.9,
            ("I keep every word inside me. Nobody makes me open!", "言葉は|全部|中に|しまってある。|誰にも|開けさせないぞ！", "모든 단어는 내 안에 있어. 아무도 날 열게 못 해!", "所有的字都裝在我裡面。誰都別想讓我打開！"),
            ("You found my lock number!", "鍵の番号が|ばれた！", "내 자물쇠 번호를 알아냈잖아!", "被你們找到密碼了！"),
            ("Please take the words back. They make the guests happy.", "言葉を|返すよ。|お客さんが|喜ぶからね。", "단어를 돌려줄게. 손님들이 기뻐하니까.", "把字還給你們吧。這樣客人會很開心。")),
        mid("elevator", "Elevator Eddie", 0.9, 1.0,
            ("Going down! I had stopped every floor before you came.", "下へまいります！|きみたちが|来る前に|全部の階を|止めておいたよ。", "내려갑니다! 너희가 오기 전에 모든 층을 멈춰 놨지.", "往下囉！你們來之前，我已經停掉所有樓層了。"),
            ("Ding! You have reached the top!", "チーン！|最上階に|着いたね！", "딩! 꼭대기 층에 도착했어!", "叮！你們到頂樓了！"),
            ("I will take everyone up again.", "また|みんなを|上まで|運ぶよ。", "다시 모두를 위층으로 데려다줄게.", "我會再把大家送上樓。")),
        mid("teacup", "Teacup Tilly", 1.5, 0.95,
            ("If you were polite, I would pour you some tea!", "あなたたちが|礼儀正しければ、|お茶を|いれて|あげるのに！", "너희가 예의 바르다면, 차를 따라 줄 텐데!", "如果你們有禮貌，我就會幫你們倒茶！"),
            ("Oh dear! I wish I hadn't spilled!", "あらまあ！|こぼさなければ|よかった！", "어머나! 쏟지 않았더라면 좋았을 걸!", "哎呀！要是沒打翻就好了！"),
            ("Shall we have tea together?", "いっしょに|お茶に|しましょうか？", "같이 차 한잔할까?", "要不要一起喝茶？")),
        mid("pot", "Honey Pot", 0.65, 0.85,
            ("If I had more honey, I would never share the words!", "もっと|はちみつが|あれば、|言葉なんか|分けて|やらないのに！", "꿀이 더 있다면, 단어는 절대 안 나눠 줄 텐데!", "如果我有更多蜂蜜，就絕不會分享這些字！"),
            ("Sticky! I wish I had stayed in the kitchen!", "ベタベタ！|台所に|いれば|よかった！", "끈적끈적! 부엌에 있을 걸 그랬어!", "黏黏的！早知道就待在廚房了！"),
            ("If you like, take some honey with you.", "よかったら、|はちみつを|持っていって。", "괜찮으면 꿀 좀 가져가.", "如果你們喜歡，就帶點蜂蜜走吧。")),
        mid("robot", "Robo Bolt", 0.6, 0.9,
            ("Beep. Only by deleting words can I keep this lab quiet.", "ピピッ。|言葉を|消すことで|しか、|研究所を|静かに|できない。", "삐빅. 단어를 지워야만 이 연구소를 조용히 할 수 있다.", "嗶嗶。只有刪除文字，我才能讓研究所保持安靜。"),
            ("Error! It is your logic that I cannot compute!", "エラー！|計算できないのは|きみたちの|論理だ！", "오류! 내가 계산할 수 없는 건 바로 너희 논리야!", "錯誤！我無法計算的正是你們的邏輯！"),
            ("System clear. Thank you, friends.", "システム正常。|ありがとう、|友よ。", "시스템 정상. 고마워, 친구들.", "系統正常。謝謝你們，朋友。")),
        mid("microscope", "Micro Scope", 1.2, 1.0,
            ("Rarely do I see such tiny mistakes. Let me look closer!", "これほど|小さな|まちがいは|めったに|見ない。|よく|見せて！", "이렇게 작은 실수는 좀처럼 못 보지. 더 자세히 보자!", "我很少看到這麼小的錯誤。讓我仔細看看！"),
            ("So it was not a mistake after all!", "まちがいでは|なかったのか！", "결국 실수가 아니었구나!", "原來那根本不是錯誤！"),
            ("Now I can see the beauty of each word.", "これで|ひとつひとつの|言葉の|美しさが|見える。", "이제 단어 하나하나의 아름다움이 보여.", "現在我能看見每一個字的美了。")),
    ]

    private static func mid(_ key: String, _ name: String, _ pitch: Float, _ rate: Float,
                            _ i: (String, String, String, String), _ h: (String, String, String, String), _ o: (String, String, String, String)) -> BossProfile {
        .init(key: key, name: name, voice: .init(pitch: pitch, rate: rate),
              intro: .init(en: i.0, ja: i.1, ko: i.2, zh: i.3), half: .init(en: h.0, ja: h.1, ko: h.2, zh: h.3), out: .init(en: o.0, ja: o.1, ko: o.2, zh: o.3))
    }
}

extension Area {
    var boss: BossProfile { BossProfile.bosses[rawValue - 1] }
    /// mid boss of stage 10 / 20 (any other index maps to the nearest one)
    func mid(_ index: Int) -> BossProfile {
        let n = min(BossProfile.mids.count - 1, (min(rawValue, 6) - 1) * 2 + (index >= 20 ? 1 : 0))
        return BossProfile.mids[n]
    }
    var bossImage: String? { boss.image }
}

extension StoryLine {
    init(_ who: Cast, _ t: BossProfile.L4) { self.init(who, t.en, t.ja, t.ko, t.zh) }
}

/// What bosses say on the battlefield (spoken in English, subtitle in the UI language).
enum BossVoice {
    case intro, half, out
    static func line(_ kind: Foe.Kind, ref: StageRef, _ v: BossVoice, profile: BossProfile? = nil, shadow: Bool = false) -> StoryLine {
        let p = profile ?? (kind == .mid ? ref.area.mid(ref.index) : ref.area.boss)
        if shadow {
            // a shadow only echoes the king's will
            switch v {
            case .intro: return .init(p.cast, .init(en: "The king's silence... gave me back my shape.", ja: "王の|沈黙が…|わたしを|よみがえらせた。", ko: "왕의 침묵이… 나를 되살렸다.", zh: "王的沉默……讓我重生了。"))
            case .half: return .init(p.cast, p.half)
            case .out: return .init(p.cast, .init(en: "This shadow... fades away...", ja: "この影も…|消えていく…", ko: "이 그림자도… 사라져 간다…", zh: "這道影子……也要消失了……"))
            }
        }
        switch v {
        case .intro: return .init(p.cast, p.intro)
        case .half: return .init(p.cast, p.half)
        case .out: return .init(kind == .boss ? p.freeCast : p.cast, p.out)
        }
    }
}
