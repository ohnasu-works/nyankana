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
    // にゃんカナ: the yokai bosses (keys and picture names kept from にゃんグリッシュ: boss_<key>)
    // `en` holds the Japanese line (shown and spoken), `ja` the English subtitle
    static let bosses: [BossProfile] = [
        .init(key: "bee", name: "九尾のきつね", freeName: "九尾のきつね", voice: .init(pitch: 1.25, rate: 0.9), freeVoice: .init(pitch: 1.25, rate: 0.9),
              intro: .init(en: "ふふふ……わらわの　ばかしを、みやぶれるかえ？", ja: "Hohoho... can you see through my tricks?", ko: "후후후…… 나의 둔갑을 꿰뚫어 볼 수 있겠느냐?", zh: "呵呵呵……你能識破妾身的幻術嗎？"),
              half: .init(en: "なに！？　もじを　みわけるとは……！", ja: "What!? You can tell the letters apart...!", ko: "뭐라!? 글자를 구별하다니……!", zh: "什麼！？竟能分辨文字……！"),
              out: .init(en: "みごとじゃ。そなたの　かちじゃ。", ja: "Splendid. You win.", ko: "훌륭하구나. 너의 승리다.", zh: "了不起。是你贏了。")),
        .init(key: "will", name: "かっぱ", freeName: "かっぱ", voice: .init(pitch: 1.1, rate: 1.05), freeVoice: .init(pitch: 1.1, rate: 1.05),
              intro: .init(en: "キュウリ、もってる？　ないなら、しょうぶだ！", ja: "Got a cucumber? If not, let's battle!", ko: "오이 있어? 없으면 승부다!", zh: "有小黃瓜嗎？沒有的話，就來比一場！"),
              half: .init(en: "うわっ、あたまの　みずが　こぼれる！", ja: "Whoa, the water on my head is spilling!", ko: "으악, 머리의 물이 쏟아져!", zh: "哇，頭上的水要灑出來了！"),
              out: .init(en: "まいった！　ともだちに　なろう！", ja: "I give up! Let's be friends!", ko: "졌다! 친구가 되자!", zh: "我認輸！當朋友吧！")),
        .init(key: "have", name: "雪女", freeName: "雪女", voice: .init(pitch: 1.3, rate: 0.85), freeVoice: .init(pitch: 1.3, rate: 0.85),
              intro: .init(en: "さむい　なつに　してあげる……。", ja: "I'll give you a cold, cold summer...", ko: "추운 여름으로 만들어 줄게…….", zh: "讓你過一個寒冷的夏天……。"),
              half: .init(en: "あなたの　ことば、あたたかい……。", ja: "Your words are warm...", ko: "당신의 말, 따뜻해…….", zh: "你的話，好溫暖……。"),
              out: .init(en: "ありがとう。こおりが　とけたわ。", ja: "Thank you. The ice has melted.", ko: "고마워. 얼음이 녹았어.", zh: "謝謝。冰融化了。")),
        .init(key: "seven", name: "天狗", freeName: "天狗", voice: .init(pitch: 0.75, rate: 0.9), freeVoice: .init(pitch: 0.75, rate: 0.9),
              intro: .init(en: "わしは天狗。漢字が読めるか、ためしてやろう！", ja: "I am Tengu. Let's see if you can read kanji!", ko: "나는 텐구. 한자를 읽을 수 있는지 시험해 주마!", zh: "我是天狗。來試試你會不會讀漢字！"),
              half: .init(en: "むむ、なかなか　やるのう。", ja: "Hmm, not bad at all.", ko: "음, 제법이구나.", zh: "嗯，挺厲害的嘛。"),
              out: .init(en: "見事じゃ。この羽うちわを持っていけ。", ja: "Splendid. Take this feather fan.", ko: "훌륭하다. 이 깃털 부채를 가져가거라.", zh: "了不起。把這把羽扇帶走吧。")),
        .init(key: "if", name: "大江山の鬼", freeName: "大江山の鬼", voice: .init(pitch: 0.65, rate: 0.95), freeVoice: .init(pitch: 0.65, rate: 0.95),
              intro: .init(en: "おれは大江山の鬼！　豆なんか、こわくないぞ！", ja: "I'm the oni of Mt. Oe! I'm not scared of beans!", ko: "나는 오에산의 도깨비! 콩 따위 안 무서워!", zh: "我是大江山的鬼！我才不怕豆子！"),
              half: .init(en: "いたたた！　それ、本当に豆じゃないよな！？", ja: "Ow, ow! That's not really beans, is it!?", ko: "아야야! 그거 진짜 콩 아니지!?", zh: "好痛好痛！那不是真的豆子吧！？"),
              out: .init(en: "まいった……。いっしょに、たこ焼きを食べに行こう。", ja: "I give up... Let's go eat takoyaki together.", ko: "졌다……. 같이 다코야키 먹으러 가자.", zh: "我認輸……。一起去吃章魚燒吧。")),
        .init(key: "logic", name: "隠神刑部だぬき", freeName: "隠神刑部だぬき", voice: .init(pitch: 0.8, rate: 0.9), freeVoice: .init(pitch: 0.8, rate: 0.9),
              intro: .init(en: "ぽんぽこ！　八百八だぬきの親分、ここにあり！", ja: "Ponpoko! The boss of the 808 tanuki is here!", ko: "퐁포코! 팔백팔 너구리의 두목, 여기 있다!", zh: "砰砰！八百八狸的老大在此！"),
              half: .init(en: "ばけの皮が、はがれそうだ……！", ja: "My disguise is coming off...!", ko: "둔갑이 벗겨질 것 같아……!", zh: "偽裝快要被揭穿了……！"),
              out: .init(en: "おみごと。買い物のときは、気をつけるんだぞ。", ja: "Well done. Be careful when you go shopping.", ko: "훌륭해. 쇼핑할 때는 조심하거라.", zh: "厲害。買東西的時候要小心喔。")),
        .init(key: "silence", name: "キジムナー", freeName: "キジムナー", voice: .init(pitch: 1.45, rate: 1.0), freeVoice: .init(pitch: 1.45, rate: 1.0),
              intro: .init(en: "いっしょに　あそぼう！　ことば、ぜんぶ　おぼえてる？", ja: "Let's play! Do you remember all the words?", ko: "같이 놀자! 말, 전부 기억하고 있어?", zh: "一起玩吧！所有的詞都記得嗎？"),
              half: .init(en: "すごい！　たびで、たくさん　まなんだね。", ja: "Amazing! You learned a lot on your journey.", ko: "대단해! 여행에서 많이 배웠구나.", zh: "好厲害！你在旅途中學了很多呢。"),
              out: .init(en: "ちよに　よろしくね。……ずっと、まってたよ。", ja: "Say hi to Chiyo. ...I've been waiting all this time.", ko: "치요에게 안부 전해 줘. ……계속 기다렸어.", zh: "代我向千代問好。……我一直在等你。")),
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
