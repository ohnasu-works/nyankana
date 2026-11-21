import SwiftUI
import UIKit

struct StoryLine: Codable, Hashable {
    var who: Cast
    var en: String
    var ja: String
    var ko: String? = nil
    var zh: String? = nil
    /// subtitle in the UI language (Japanese is the fallback)
    var sub: String {
        switch L10n.current {
        case .ja: ja
        case .ko: ko ?? ja.replacingOccurrences(of: "|", with: "")
        case .zhHant: zh ?? ja.replacingOccurrences(of: "|", with: "")
        case .en: ""          // the spoken English line is already on screen
        default: Tr.text(ja)
        }
    }
    init(_ who: Cast, _ en: String, _ ja: String, _ ko: String? = nil, _ zh: String? = nil) {
        self.who = who; self.en = en; self.ja = ja; self.ko = ko; self.zh = zh
    }
}

enum StoryKind { case intro, outro }

/// Story scenes. Each chapter (area) has its own opening and ending, every boss and mid boss
/// has an entrance, and the other stages get short scenes.
enum StoryBank {
    static func lines(_ ref: StageRef, _ kind: StoryKind) -> [StoryLine] {
        if let file = loaded(ref, kind) { return file }
        let last = ref.index == ref.area.stageCount
        let mid = ref.index % 10 == 0 && !last
        switch (kind, ref.index) {
        case (.intro, 1): return chapterIntro[ref.area] ?? shortIntros[0]
        case (.outro, _) where last: return chapterOutro[ref.area] ?? shortOutros[0]
        case (.intro, _) where last: return bossIntro(ref.area)
        case (.intro, _) where mid: return midIntro(ref.area.mid(ref.index), ref.index)
        case (.outro, _) where mid: return midOutro(ref.area.mid(ref.index), ref.index)
        case (.intro, _): return freshScene(ref, .intro)
        case (.outro, _): return freshScene(ref, .outro)
        }
    }

    /// Chapter backgrounds: bg_<area>_intro / bg_<area>_outro when bundled, else the shared ones.
    static func background(_ ref: StageRef, _ kind: StoryKind) -> String {
        let name = "bg_\(ref.area.rawValue)_\(kind == .outro ? "outro" : "intro")"
        if UIImage(named: name) != nil { return name }
        return kind == .intro ? "bg_intro" : "bg_outro"
    }

    private static func loaded(_ ref: StageRef, _ kind: StoryKind) -> [StoryLine]? {
        guard let url = Bundle.main.url(forResource: "story_\(ref.area.rawValue)", withExtension: "json"),
              let d = try? Data(contentsOf: url),
              let all = try? JSONDecoder().decode([String: [StoryLine]].self, from: d) else { return nil }
        return all["\(ref.index)-\(kind == .intro ? "intro" : "outro")"]
    }

    // MARK: - boss / mid boss scenes

    static func bossIntro(_ a: Area) -> [StoryLine] {
        let b = a.boss
        if a == .graduation {
            return [
                .init(.nyan, "This is the Castle of Silence. The last Gobble King is here.", "ここが|サイレンス城。|最後の|ゴブルの王が|いるにゃ。", "여기가 사일런스 성이야. 마지막 고블 왕이 있어.", "這裡就是寂靜城。最後的高布王就在這裡。"),
                .init(.rin, "Everything we have learned brought us here.", "今まで|学んだ|ぜんぶが、|わたしたちを|ここまで|連れてきたんだね。", "지금까지 배운 모든 것이 우리를 여기까지 데려왔어.", "我們學到的一切，帶我們來到了這裡。"),
                .init(b.cast, b.intro),
                .init(.ken, "Words can hurt, but they can also heal. We will show you!", "言葉は|人を|傷つけることも|あるけど、|いやすことも|できる。|見せてやる！", "말은 상처를 줄 수도 있지만, 치유할 수도 있어. 보여 줄게!", "語言會傷人，但也能療癒人心。我們證明給你看！"),
                .init(.nyan, "Every grammar point you know is your weapon. Go!", "知ってる|文法|ぜんぶが|武器にゃ。|行けー！", "알고 있는 문법 전부가 무기야. 가자!", "你們會的每個文法都是武器。上吧！"),
            ]
        }
        return [
            .init(.nyan, "This is it. The boss is near!", "いよいよにゃ。|ボスが|近くに|いる！", "드디어야. 보스가 가까이 있어!", "終於到了。頭目就在附近！"),
            .init(b.cast, b.intro),
            .init(.rin, "We are not afraid of you!", "あなたなんか|こわくない！", "너 따위 하나도 안 무서워!", "我們才不怕你！"),
            .init(.ken, "Ready, Rin? Here we go!", "準備は|いい、|リン？|いくぞ！", "준비됐어, 린? 간다!", "準備好了嗎，凜？上吧！"),
        ]
    }

    static func midIntro(_ m: BossProfile, _ index: Int) -> [StoryLine] {
        let react: [StoryLine] = index >= 20
            ? [.init(.rin, "Another big one! Stay calm, Ken.", "また|大きいのが|来た！|落ち着いて、|ケン。", "또 큰 녀석이야! 침착해, 켄.", "又來一個大傢伙！冷靜點，健。"),
               .init(.nyan, "Its questions are long sentences. Read to the end!", "長い文の|問題にゃ。|最後まで|読んでね！", "긴 문장 문제야. 끝까지 읽어!", "它的題目是長句子。要讀到最後喔！")]
            : [.init(.ken, "Wow, it is huge!", "うわ、|でかい！", "우와, 엄청 커!", "哇，好大！"),
               .init(.nyan, "Its questions are long sentences. Read them carefully!", "あいつの|問題は|長い文にゃ。|よく読んでね！", "저 녀석 문제는 긴 문장이야. 잘 읽어!", "它的題目是長句子。仔細讀喔！")]
        return [.init(m.cast, m.intro)] + react
    }

    static func midOutro(_ m: BossProfile, _ index: Int) -> [StoryLine] {
        [.init(m.cast, m.out),
         index >= 20 ? .init(.ken, "The boss is just ahead. Let's keep going!", "ボスは|もうすぐだ。|進もう！", "보스가 바로 앞이야. 계속 가자!", "頭目就在前面了。繼續前進！")
                     : .init(.rin, "Good job, team! Let's go on.", "ナイス|チームワーク！|先へ|行こう。", "팀워크 최고! 계속 가자.", "團隊合作真棒！繼續走吧。")]
    }

    // MARK: - chapter openings (stage 1)

    static let chapterIntro: [Area: [StoryLine]] = [
        .lv1: [
            .init(.nyan, "Ken! Rin! Wake up! This is bad!", "ケン！|リン！|起きて！|大変にゃ！", "켄! 린! 일어나! 큰일 났어!", "健！凜！快起來！不好了！"),
            .init(.ken, "What is it, Nyan?", "どうしたの、|ニャン？", "무슨 일이야, 냥?", "怎麼了，喵？"),
            .init(.nyan, "The Gobbles are here. They eat English words!", "ゴブルズが|来たにゃ。|英語の言葉を|食べちゃうんだ！", "고블스가 왔어. 영어 단어를 먹어 치운다고!", "高布斯來了。它們會吃掉英文單字！"),
            .init(.rin, "Look! The street is gray. The signs are empty!", "見て！|通りが|灰色だよ。|看板の文字も|消えてる！", "봐! 거리가 회색이야. 간판 글자도 사라졌어!", "你看！街道變成灰色了。招牌上的字也不見了！"),
            .init(.ken, "This is our town. We are not scared!", "ここは|ぼくたちの街だ。|こわくないぞ！", "여긴 우리 마을이야. 우린 안 무서워!", "這是我們的城鎮。我們不怕！"),
            .init(.nyan, "Make word orbs with correct English. They set the Gobbles free!", "正しい英語で|ことばの玉を|作るにゃ。|ゴブルズを|元に戻せるよ！", "올바른 영어로 말의 구슬을 만들어. 고블스를 원래대로 돌릴 수 있어!", "用正確的英文做出文字球，就能讓高布斯恢復原樣！"),
            .init(.rin, "Who is behind this?", "いったい|誰のしわざ？", "도대체 누구 짓이야?", "到底是誰做的？"),
            .init(.bee, "Bzzz! I am Miss Bee! This street is mine!", "ブーン！|わたしは|ミス・ビー！|この通りは|わたしのものよ！", "윙윙! 나는 미스 비! 이 거리는 내 거야!", "嗡嗡！我是比小姐！這條街是我的！"),
            .init(.ken, "She is not herself. A Gobble is on her head!", "様子が|変だ。|頭に|ゴブルが|いる！", "상태가 이상해. 머리에 고블이 있어!", "她不太對勁。她頭上有高布！"),
            .init(.rin, "Let's go, Ken! We are a team!", "行こう、|ケン！|わたしたちは|チームだよ！", "가자, 켄! 우린 한 팀이야!", "走吧，健！我們是一個團隊！"),
        ],
        .lv2: [
            .init(.ken, "This is Future Street. But all the clocks are stopped.", "ここが|フューチャー通り。|でも|時計が|全部|止まってる。", "여기가 퓨처 거리야. 그런데 시계가 전부 멈췄어.", "這裡是未來大街。可是所有的時鐘都停了。"),
            .init(.rin, "People can't plan their day. They are going to be late!", "これじゃ|予定が|立てられない。|みんな|遅刻しちゃう！", "이러면 하루 계획을 못 세워. 다들 지각하겠어!", "這樣大家沒辦法安排一天。大家都會遲到！"),
            .init(.nyan, "Here, you will learn will, can, must, and to plus verbs.", "ここでは|will、|can、|must、|そして|to＋動詞を|学ぶにゃ。", "여기서는 will, can, must, 그리고 to+동사를 배울 거야.", "在這裡，你們會學到 will、can、must，還有 to＋動詞。"),
            .init(.ken, "I want to be stronger than yesterday!", "昨日より|強く|なりたい！", "어제보다 더 강해지고 싶어!", "我想變得比昨天更強！"),
            .init(.rin, "We must find Will. Miss Bee said he needs help.", "ウィルを|探さなきゃ。|ミス・ビーが|困ってるって|言ってた。", "윌을 찾아야 해. 미스 비가 도움이 필요하다고 했어.", "我們一定要找到威爾。比小姐說他需要幫忙。"),
            .init(.nyan, "Be careful. Faster Gobbles will come!", "気をつけて。|もっと|速い|ゴブルズが|来るにゃ！", "조심해. 더 빠른 고블스가 올 거야!", "小心。更快的高布斯要來了！"),
        ],
        .lv3: [
            .init(.rin, "Trophy Plaza! I have wanted to come here for a long time.", "トロフィー広場！|ずっと|来たかったんだ。", "트로피 광장! 오래전부터 와 보고 싶었어.", "獎盃廣場！我一直很想來這裡。"),
            .init(.ken, "But the trophies have been stolen. The stage is empty.", "でも|トロフィーが|盗まれてる。|舞台も|からっぽだ。", "그런데 트로피가 도둑맞았어. 무대도 텅 비었어.", "可是獎盃都被偷了。舞台也空蕩蕩的。"),
            .init(.nyan, "Here, you will learn have plus past participle, and the passive voice.", "ここでは|現在完了と|受け身を|学ぶにゃ。", "여기서는 현재완료와 수동태를 배울 거야.", "在這裡，你們會學到現在完成式和被動語態。"),
            .init(.ken, "Have you ever seen a Gobble that dances?", "踊る|ゴブルを|見たこと|ある？", "춤추는 고블 본 적 있어?", "你看過會跳舞的高布嗎？"),
            .init(.rin, "Not yet. But I think we will see one soon!", "まだ|ない。|でも|すぐ|見られそう！", "아직. 그런데 곧 보게 될 것 같아!", "還沒有。不過應該很快就會看到！"),
        ],
        .lv4: [
            .init(.ken, "What a big hotel! But it is so quiet.", "大きな|ホテル！|でも|すごく|静かだ。", "엄청 큰 호텔이다! 그런데 너무 조용해.", "好大的飯店！可是好安靜。"),
            .init(.rin, "The guests look sad. Nobody is talking.", "お客さんが|悲しそう。|誰も|話してない。", "손님들이 슬퍼 보여. 아무도 말을 안 해.", "客人看起來好難過。沒有人在說話。"),
            .init(.nyan, "Here, you will learn the five sentence patterns. SVOC makes people happy!", "ここでは|5文型を|学ぶにゃ。|SVOCで|人を|笑顔に|するにゃ！", "여기서는 5형식을 배울 거야. SVOC로 사람들을 웃게 하자!", "在這裡，你們會學到五大句型。用 SVOC 讓大家開心！"),
            .init(.rin, "Let's make this hotel lively again.", "このホテルを|また|にぎやかに|しよう。", "이 호텔을 다시 활기차게 만들자.", "讓這間飯店再熱鬧起來吧。"),
            .init(.ken, "I'll call it Operation Room Service!", "名づけて|ルームサービス作戦！", "이름하여 룸서비스 작전!", "就叫它客房服務作戰！"),
        ],
        .lv5: [
            .init(.rin, "A garden full of masks... and the flowers are closed.", "仮面だらけの|花園…|花も|閉じちゃってる。", "가면투성이 꽃동산… 꽃도 다 오므렸어.", "到處都是面具的花園……花也都閉起來了。"),
            .init(.ken, "If the flowers opened, this place would be beautiful.", "花が|開いたら、|ここは|きれいなのに。", "꽃이 핀다면 여기는 아름다울 텐데.", "如果花開了，這裡一定很美。"),
            .init(.nyan, "That's it! Here, you will learn If I were... and If I had...!", "それにゃ！|ここでは|仮定法を|学ぶにゃ！", "바로 그거야! 여기서는 가정법을 배울 거야!", "就是那個！在這裡，你們會學到假設語氣！"),
            .init(.rin, "If I were a flower, I would want to be free.", "もし|わたしが|花なら、|自由に|なりたいな。", "내가 꽃이라면, 자유로워지고 싶을 거야.", "如果我是一朵花，我會想要自由。"),
            .init(.ken, "Then let's set them free!", "じゃあ|自由に|してあげよう！", "그럼 자유롭게 해 주자!", "那就讓它們自由吧！"),
        ],
        .lv6: [
            .init(.ken, "The Logic Lab... Everything here is a puzzle.", "ロジック研究所…|ここは|全部が|パズルだ。", "로직 연구소… 여기는 모든 게 퍼즐이야.", "邏輯研究所……這裡的一切都是謎題。"),
            .init(.rin, "The robots are deleting words one by one!", "ロボットが|言葉を|ひとつずつ|消してる！", "로봇들이 단어를 하나씩 지우고 있어!", "機器人正在一個一個刪除文字！"),
            .init(.nyan, "Here, you will learn emphasis, inversion, and words like however.", "ここでは|強調、|倒置、|そして|howeverのような|論理の言葉を|学ぶにゃ。", "여기서는 강조, 도치, 그리고 however 같은 논리 표현을 배울 거야.", "在這裡，你們會學到強調、倒裝，還有 however 這類邏輯用語。"),
            .init(.ken, "It is teamwork that makes us strong.", "ぼくたちを|強く|するのは、|チームワークだ。", "우리를 강하게 만드는 건 바로 팀워크야.", "讓我們變強的，正是團隊合作。"),
            .init(.rin, "Never have I felt so ready!", "こんなに|準備万端なのは|初めて！", "이렇게 준비된 느낌은 처음이야!", "我從來沒有這麼準備好過！"),
        ],
        .graduation: [
            .init(.nyan, "Look up. The Castle of Silence floats above Wordia.", "見上げて。|サイレンス城が|ワーディアの|上に|浮かんでるにゃ。", "위를 봐. 사일런스 성이 워디아 위에 떠 있어.", "抬頭看。寂靜城就飄在沃迪亞的上空。"),
            .init(.ken, "All the stolen words are in that castle.", "盗まれた|言葉は|全部|あの城に|ある。", "도둑맞은 단어들은 전부 저 성에 있어.", "被偷走的字全都在那座城堡裡。"),
            .init(.rin, "Miss Bee, Will, Mr. Have, Seven, Madame If, Dr. Logic... everyone is cheering for us.", "ミス・ビー、|ウィル、|ハヴさん、|セブン、|マダム・イフ、|ロジック博士…|みんなが|応援してくれてる。", "미스 비, 윌, 해브 씨, 세븐, 마담 이프, 로직 박사… 모두가 응원하고 있어.", "比小姐、威爾、哈夫先生、七號、如果夫人、邏輯博士……大家都在為我們加油。"),
            .init(.nyan, "This is the final test. Every grammar point you have learned will appear.", "これが|卒業試験にゃ。|今まで|学んだ|文法が|全部|出るよ。", "이게 졸업 시험이야. 지금까지 배운 문법이 전부 나와.", "這是畢業考。你們學過的所有文法都會出現。"),
            .init(.ken, "We are ready. Let's bring the words home!", "準備は|できてる。|言葉を|取り戻そう！", "준비됐어. 단어들을 되찾아 오자!", "我們準備好了。把字帶回家吧！"),
        ],
    ]

    // MARK: - chapter endings (boss stage)

    static let chapterOutro: [Area: [StoryLine]] = [
        .lv1: [
            .init(.beeFree, "Where am I? Oh, you are my heroes!", "ここは|どこ？|…あなたたちが|助けてくれたのね！", "여긴 어디지? 아, 너희가 날 구해 줬구나!", "這裡是哪裡？啊，是你們救了我！"),
            .init(.rin, "You are free now, Miss Bee!", "もう|大丈夫だよ、|ミス・ビー！", "이제 괜찮아, 미스 비!", "妳自由了，比小姐！"),
            .init(.beeFree, "Thank you. I am a dance teacher. I am not a monster!", "ありがとう。|わたしは|ダンスの先生なの。|怪物じゃないわ！", "고마워. 난 댄스 선생님이야. 괴물이 아니라고!", "謝謝。我是舞蹈老師，不是怪物！"),
            .init(.ken, "Look! The street is bright again!", "見て！|通りが|明るく|なった！", "봐! 거리가 다시 밝아졌어!", "你看！街道又變亮了！"),
            .init(.nyan, "But the Gobbles are still in Wordia...", "でも、|ゴブルズは|まだ|ワーディアに|いるにゃ…", "하지만 고블스는 아직 워디아에 있어…", "可是高布斯還在沃迪亞……"),
            .init(.beeFree, "Will is in trouble too. He is on Future Street.", "ウィルも|困っているの。|彼は|フューチャー通りに|いるわ。", "윌도 곤란에 처했어. 퓨처 거리에 있어.", "威爾也有麻煩了。他在未來大街。"),
            .init(.ken, "OK! We are ready. Next stop, Future Street!", "よし！|準備はできてる。|次は|フューチャー通りだ！", "좋아! 준비됐어. 다음은 퓨처 거리다!", "好！我們準備好了。下一站，未來大街！"),
        ],
        .lv2: [
            .init(Cast("willFree"), "Oh... my head is clear now. Thank you, kids.", "ああ…|頭が|すっきりした。|ありがとう、|きみたち。", "아… 이제 머리가 맑아졌어. 고마워, 얘들아.", "啊……我的頭腦清醒了。謝謝你們，孩子們。"),
            .init(.ken, "The clocks are moving again!", "時計が|また|動き出した！", "시계가 다시 움직여!", "時鐘又開始走了！"),
            .init(Cast("willFree"), "I am a clockmaker. I will never stop time again. I promise.", "わたしは|時計職人。|もう|二度と|時間を|止めないと|約束するよ。", "난 시계공이야. 다시는 시간을 멈추지 않을게. 약속해.", "我是鐘錶匠。我保證再也不會讓時間停下來。"),
            .init(.rin, "Can you tell us where the next Gobble boss is?", "次の|ゴブルのボスが|どこに|いるか|教えて|くれる？", "다음 고블 보스가 어디 있는지 알려 줄래?", "你可以告訴我們下一個高布頭目在哪裡嗎？"),
            .init(Cast("willFree"), "It must be Trophy Plaza. The show there is going to start soon.", "トロフィー広場に|ちがいない。|もうすぐ|ショーが|始まるはずだ。", "분명 트로피 광장일 거야. 곧 그곳에서 쇼가 시작될 거야.", "一定是獎盃廣場。那裡的表演快要開始了。"),
            .init(.nyan, "To the plaza! You are better than ever!", "広場へ|行くにゃ！|今までで|一番|強いにゃ！", "광장으로 가자! 지금이 역대 최고야!", "前往廣場！你們比以前更強了！"),
        ],
        .lv3: [
            .init(Cast("haveFree"), "I have been under a Gobble's spell for months. What a long show!", "何か月も|ゴブルの|魔法に|かかっていた。|長いショーだったよ！", "몇 달 동안 고블의 마법에 걸려 있었어. 정말 긴 쇼였어!", "我被高布的魔法困了好幾個月。真是一場漫長的表演！"),
            .init(.rin, "The trophies have come back to the plaza!", "トロフィーが|広場に|戻ってきた！", "트로피가 광장으로 돌아왔어!", "獎盃回到廣場了！"),
            .init(Cast("haveFree"), "This one was made for the bravest team. That's you!", "これは|一番|勇敢な|チームの|ために|作られた。|きみたちのだ！", "이건 가장 용감한 팀을 위해 만들어졌어. 바로 너희야!", "這座是為最勇敢的團隊做的。就是你們！"),
            .init(.ken, "Thank you! Have you heard anything about the next boss?", "ありがとう！|次の|ボスのこと、|何か|聞いてる？", "고마워! 다음 보스에 대해 들은 거 있어?", "謝謝！你有聽說下一個頭目的事嗎？"),
            .init(Cast("haveFree"), "Yes. The Hotel District has been silent since last week.", "ああ。|ホテル街が|先週から|静まり返っているんだ。", "응. 호텔 거리가 지난주부터 조용해졌어.", "有。飯店街從上週開始就一片寂靜。"),
            .init(.nyan, "Next stop, the hotels! Pack your bags!", "次は|ホテル街にゃ！|荷物を|まとめて！", "다음은 호텔 거리야! 짐 싸!", "下一站，飯店街！收拾行李吧！"),
        ],
        .lv4: [
            .init(Cast("sevenFree"), "Welcome back, everyone. Please, make yourselves at home.", "皆さま、|おかえりなさいませ。|どうぞ|おくつろぎ|ください。", "여러분, 다시 오신 걸 환영합니다. 편히 쉬세요.", "各位，歡迎回來。請把這裡當自己家。"),
            .init(.rin, "Listen! The guests are laughing again.", "聞いて！|お客さんが|また|笑ってる。", "들어 봐! 손님들이 다시 웃고 있어.", "你聽！客人們又在笑了。"),
            .init(.ken, "Words make people happy. That's what we learned.", "言葉は|人を|幸せに|する。|それが|ぼくたちの|学んだことだ。", "말은 사람을 행복하게 해. 그게 우리가 배운 거야.", "語言讓人幸福。這就是我們學到的。"),
            .init(Cast("sevenFree"), "Madame If was my best guest. She went to the Garden of If and never came back.", "マダム・イフは|一番の|お客様でした。|イフの花園へ|行ったきり|戻らないのです。", "마담 이프는 최고의 손님이었어요. 이프의 꽃동산에 간 뒤로 돌아오지 않았어요.", "如果夫人是我最好的客人。她去了如果花園，就再也沒回來。"),
            .init(.nyan, "Then we will find her. To the garden!", "なら|探しに|行くにゃ。|花園へ！", "그럼 찾으러 가자. 꽃동산으로!", "那我們去找她。前往花園！"),
        ],
        .lv5: [
            .init(Cast("ifFree"), "The mask is gone... I can see the flowers again.", "仮面が|消えた…|また|花が|見えるわ。", "가면이 사라졌어… 다시 꽃이 보여.", "面具不見了……我又能看見花了。"),
            .init(.rin, "Look! Every flower is opening!", "見て！|花が|全部|開いていく！", "봐! 꽃이 전부 피어나고 있어!", "你看！每一朵花都在綻放！"),
            .init(Cast("ifFree"), "If I were you, I would be proud. You saved this garden.", "わたしが|あなたたちなら、|誇りに|思うわ。|この花園を|救ったのよ。", "내가 너희라면 자랑스러울 거야. 너희가 이 꽃동산을 구했어.", "如果我是你們，我會很驕傲。是你們救了這座花園。"),
            .init(.ken, "If we hadn't practiced, we couldn't have done it.", "練習して|いなかったら、|できなかったよ。", "연습하지 않았다면 해내지 못했을 거야.", "如果我們沒有練習，就做不到了。"),
            .init(Cast("ifFree"), "Dr. Logic's lab is over the hill. His robots have gone wild.", "丘の|向こうに|ロジック博士の|研究所が|あるわ。|ロボットが|暴走しているの。", "언덕 너머에 로직 박사의 연구소가 있어. 로봇들이 폭주하고 있어.", "山丘的另一邊是邏輯博士的研究所。他的機器人失控了。"),
            .init(.nyan, "Let's go! The end is getting close!", "行くにゃ！|ゴールは|近いにゃ！", "가자! 끝이 가까워지고 있어!", "出發！終點越來越近了！"),
        ],
        .lv6: [
            .init(Cast("logicFree"), "Remarkable. Not only your English but also your hearts are strong.", "見事だ。|英語だけで|なく、|心も|強い。", "훌륭하구나. 영어뿐만 아니라 마음도 강해.", "了不起。你們不只英文好，心也很堅強。"),
            .init(.rin, "Dr. Logic, who started all this?", "ロジック博士、|これは|全部|誰の|しわざなの？", "로직 박사님, 이 모든 걸 누가 시작했어요?", "邏輯博士，這一切是誰開始的？"),
            .init(Cast("logicFree"), "It was King Silence who sent the Gobbles. His castle floats in the sky.", "ゴブルズを|送ったのは|キング・サイレンスだ。|彼の城は|空に|浮かんでいる。", "고블스를 보낸 건 바로 킹 사일런스야. 그의 성은 하늘에 떠 있어.", "派出高布斯的，正是寂靜國王。他的城堡飄浮在天空中。"),
            .init(.ken, "Can we reach it?", "そこまで|行けるの？", "거기까지 갈 수 있어?", "我們到得了那裡嗎？"),
            .init(Cast("logicFree"), "Only those who have mastered every grammar point can enter.", "すべての|文法を|身につけた|者だけが|入れるのだ。", "모든 문법을 익힌 사람만 들어갈 수 있어.", "只有精通所有文法的人才能進入。"),
            .init(.nyan, "That's us! Next is the final test. Graduation!", "それは|ぼくたちにゃ！|次は|卒業試験にゃ！", "그건 바로 우리야! 다음은 졸업 시험이야!", "那就是我們！下一關是畢業考！"),
        ],
        .graduation: [
            .init(Cast("silenceFree"), "Who am I...? I am Leo. I was once the prince of this castle.", "ぼくは…|レオ。|昔、|この城の|王子だったんだ。", "나는… 레오. 예전에 이 성의 왕자였어.", "我是……里歐。我曾經是這座城堡的王子。"),
            .init(.rin, "Why did you take all the words?", "どうして|言葉を|全部|奪ったの？", "왜 단어를 전부 빼앗았어?", "你為什麼要奪走所有的字？"),
            .init(Cast("silenceFree"), "Someone said cruel words to me. So I thought a world without words would be safer.", "ひどい|言葉を|言われたんだ。|だから|言葉の|ない|世界の|ほうが|安全だと|思った。", "누가 나에게 상처 주는 말을 했어. 그래서 말이 없는 세상이 더 안전하다고 생각했어.", "有人對我說了很傷人的話。所以我以為沒有語言的世界會比較安全。"),
            .init(.ken, "Words hurt sometimes. But kind words can heal, too.", "言葉は|ときどき|人を|傷つける。|でも|やさしい|言葉は|人を|いやすんだ。", "말은 가끔 상처를 줘. 하지만 다정한 말은 치유도 해.", "語言有時會傷人。但溫柔的話也能療癒人。"),
            .init(.nyan, "You did it! All the words are flying back to Wordia!", "やったにゃ！|言葉が|全部|ワーディアに|帰っていく！", "해냈어! 단어들이 전부 워디아로 돌아가고 있어!", "你們成功了！所有的字都飛回沃迪亞了！"),
            .init(Cast("silenceFree"), "Thank you, Ken, Rin, and Nyan. Will you be my friends?", "ありがとう、|ケン、|リン、|ニャン。|ぼくと|友だちに|なってくれる？", "고마워, 켄, 린, 냥. 나랑 친구가 되어 줄래?", "謝謝你們，健、凜、喵。你們願意當我的朋友嗎？"),
            .init(.rin, "Of course! Friends talk a lot, you know!", "もちろん！|友だちは|たくさん|話すんだよ！", "물론이지! 친구는 말을 많이 하는 거야!", "當然！朋友就是要多聊天啊！"),
            .init(.nyan, "Congratulations on your graduation! Now, the real English adventure begins!", "卒業|おめでとうにゃ！|ここからが|本当の|英語の|冒険にゃ！", "졸업 축하해! 이제부터 진짜 영어 모험이 시작이야!", "恭喜畢業！真正的英文冒險，現在才開始！"),
        ],
    ]

    // MARK: - short scenes for the other stages

    static let shortIntros: [[StoryLine]] = [
        [.init(.nyan, "The Gobbles are on this street too!", "この通りにも|ゴブルズが|いるにゃ！", "이 거리에도 고블스가 있어!", "這條街上也有高布斯！"),
         .init(.ken, "We are ready. Let's go!", "準備は|できてる。|行こう！", "준비됐어. 가자!", "我們準備好了。走吧！")],
        [.init(.rin, "This street is very quiet.", "この通り、|すごく|静かだね。", "이 거리 엄청 조용하다.", "這條街好安靜。"),
         .init(.nyan, "The words are gone. Get them back!", "言葉が|消えてるにゃ。|取り戻そう！", "단어가 사라졌어. 되찾자!", "字都不見了。把它們找回來！")],
        [.init(.ken, "Is that a Gobble?", "あれは|ゴブル？", "저거 고블이야?", "那是高布嗎？"),
         .init(.rin, "Yes, it is! Be careful, Ken!", "そうだよ！|気をつけて、|ケン！", "맞아! 조심해, 켄!", "沒錯！小心點，健！")],
        [.init(.nyan, "You are good at English now!", "英語が|上手に|なってきたにゃ！", "영어 실력이 늘었어!", "你們的英文變好了！"),
         .init(.rin, "Thank you, Nyan. We are a team!", "ありがとう、|ニャン。|わたしたちは|チームだよ！", "고마워, 냥. 우린 한 팀이야!", "謝謝你，喵。我們是一個團隊！")],
        [.init(.ken, "I hear something. The Gobbles are coming from the sky!", "何か|聞こえる。|空から|ゴブルズが|来るぞ！", "뭔가 들려. 하늘에서 고블스가 온다!", "我聽到聲音了。高布斯從天上來了！"),
         .init(.nyan, "Tap the enemy chips to choose your target!", "右下の|ボタンで|ねらう敵を|選べるにゃ！", "오른쪽 아래 버튼으로 노릴 적을 고를 수 있어!", "用右下角的按鈕選擇目標！")],
        [.init(.rin, "Don't forget the items. A bomb can save us!", "アイテムも|忘れずにね。|ボムは|助かるよ！", "아이템도 잊지 마. 폭탄이 도움이 될 거야!", "別忘了道具。炸彈能救我們！"),
         .init(.ken, "Got it. Let's keep the combo going!", "了解。|コンボを|つなげよう！", "알았어. 콤보를 이어 가자!", "知道了。讓連擊繼續下去！")],
    ]
    static let shortOutros: [[StoryLine]] = [
        [.init(.rin, "The shops are open again!", "お店が|また|開いたね！", "가게들이 다시 열었어!", "商店又開門了！"),
         .init(.ken, "We are a good team!", "ぼくたち、|いいチームだね！", "우리 좋은 팀이야!", "我們是很棒的團隊！")],
        [.init(.nyan, "Great job! The street is happy.", "よくやったにゃ！|通りが|喜んでる。", "잘했어! 거리가 기뻐하고 있어.", "做得好！街道很開心。"),
         .init(.ken, "Next street, please!", "次の通りへ|行こう！", "다음 거리로 가자!", "前往下一條街！")],
        [.init(.ken, "The colors are back!", "色が|戻った！", "색이 돌아왔어!", "顏色回來了！"),
         .init(.rin, "The Gobbles are cute now.", "ゴブルズも|かわいく|なったね。", "고블스도 귀여워졌네.", "高布斯也變可愛了。")],
        [.init(.nyan, "Are you tired?", "つかれた？", "피곤해?", "累了嗎？"),
         .init(.rin, "No, we are not tired!", "ううん、|つかれてないよ！", "아니, 하나도 안 피곤해!", "不，我們不累！")],
        [.init(.ken, "I remember the words from last time!", "前の|言葉、|ちゃんと|覚えてた！", "지난번 단어를 기억하고 있었어!", "我記得上次的字！"),
         .init(.nyan, "Review is power. Try the study mode too!", "復習は|力にゃ。|おべんきょうも|やってみてね！", "복습은 힘이야. 공부 모드도 해 봐!", "複習就是力量。也試試學習模式吧！")],
        [.init(.rin, "The people are talking again. I love that sound.", "みんなが|また|話してる。|この音、|大好き。", "사람들이 다시 이야기하고 있어. 이 소리 너무 좋아.", "大家又在聊天了。我好喜歡這個聲音。"),
         .init(.ken, "Me too. Let's keep going!", "ぼくも。|先へ|進もう！", "나도. 계속 가자!", "我也是。繼續前進吧！")],
    ]
}
