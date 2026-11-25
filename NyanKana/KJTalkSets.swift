import Foundation

// MARK: - かいわイベント（第2〜7章）：その地方らしい場面で、正しい ひとことを えらぶ

enum KJTalkSets {
    typealias Q = KJTalkEvent.Q
    static let sets: [Int: [Q]] = [
        // 東北：かいもの
        2: [
            Q(npc: "いらっしゃいませ！", face: "npc_nakamise", en: "You want an apple. Ask for one.", zh: "你想要一顆蘋果，請店員給你。", ko: "사과를 하나 사고 싶어요.", answer: "ひとつ ください"),
            Q(npc: "ひゃくえん です。", face: "npc_nakamise", en: "You want to know the price.", zh: "你想知道價錢。", ko: "가격을 알고 싶어요.", answer: "いくら ですか"),
            Q(npc: "まいど！", face: "npc_nakamise", en: "You got your apples. Say thanks.", zh: "拿到蘋果了，道謝吧。", ko: "사과를 받았어요. 고맙다고 해요.", answer: "ありがとう ございます"),
            Q(npc: "はい、これ ですね。", face: "npc_nakamise", en: "You point at the red one you want.", zh: "你指著想要的紅色那個。", ko: "원하는 빨간 것을 가리켜요.", answer: "これを ください"),
            Q(npc: "どうぞ、たべて みて！", face: "npc_nakamise", en: "You taste it. It's delicious!", zh: "你試吃了，很好吃！", ko: "맛을 봤어요. 맛있어요!", answer: "おいしい です"),
            Q(npc: "また きてね！", face: "npc_nakamise", en: "You are leaving the market.", zh: "你要離開市場了。", ko: "시장을 떠나요.", answer: "さようなら"),
        ],
        // 北海道：さむい・たべもの
        3: [
            Q(npc: "うー、さむいね！", face: "npc_chinatown", en: "It's snowing hard. Agree that it's cold.", zh: "雪下得很大，附和說好冷。", ko: "눈이 많이 와요. 춥다고 맞장구쳐요.", answer: "さむい ですね"),
            Q(npc: "ラーメン、どうぞ。", face: "npc_chinatown", en: "Your ramen arrives. What do you say before eating?", zh: "拉麵來了，吃之前要說什麼？", ko: "라멘이 나왔어요. 먹기 전에 뭐라고 해요?", answer: "いただきます"),
            Q(npc: "おそまつさまでした。", face: "npc_chinatown", en: "You finished eating. What do you say?", zh: "吃完了，要說什麼？", ko: "다 먹었어요. 뭐라고 해요?", answer: "ごちそうさま でした"),
            Q(npc: "あたたかい おちゃ、いる？", face: "npc_chinatown", en: "Yes, you'd like some, please.", zh: "好的，麻煩你了。", ko: "네, 부탁해요.", answer: "おねがいします"),
            Q(npc: "どこから きたの？", face: "npc_chinatown", en: "Say you came from Tokyo.", zh: "說你從東京來。", ko: "도쿄에서 왔다고 해요.", answer: "とうきょう から です"),
            Q(npc: "あぶない！ すべるよ！", face: "npc_chinatown", en: "You slipped and bumped into someone.", zh: "你滑倒撞到別人了。", ko: "미끄러져서 누군가와 부딪혔어요.", answer: "すみません"),
        ],
        // 中部：えき・みち
        4: [
            Q(npc: "どうしましたか？", face: "npc_nakamise", en: "You are looking for the station.", zh: "你在找車站。", ko: "역을 찾고 있어요.", answer: "えきは どこ ですか"),
            Q(npc: "あっちですよ。", face: "npc_nakamise", en: "You need the toilet.", zh: "你要找廁所。", ko: "화장실을 찾아요.", answer: "トイレは どこ ですか"),
            Q(npc: "まっすぐ いって ください。", face: "npc_nakamise", en: "You didn't catch that. Ask again.", zh: "你沒聽清楚，請對方再說一次。", ko: "못 알아들었어요. 다시 부탁해요.", answer: "もう いちど おねがいします"),
            Q(npc: "ふじさんが きれいですね。", face: "npc_nakamise", en: "You agree: Mt. Fuji is beautiful.", zh: "你也覺得富士山很美。", ko: "후지산이 예쁘다고 맞장구쳐요.", answer: "そう ですね"),
            Q(npc: "しんかんせんは 10じ です。", face: "npc_nakamise", en: "You understand the time.", zh: "你聽懂時間了。", ko: "시간을 알아들었어요.", answer: "わかりました"),
            Q(npc: "きをつけて！", face: "npc_nakamise", en: "You thank them for the help.", zh: "感謝對方的幫忙。", ko: "도와줘서 고마워요.", answer: "ありがとう ございます"),
        ],
        // 関西：レストラン
        5: [
            Q(npc: "なんめいさま ですか？", face: "npc_chinatown", en: "There are two of you.", zh: "你們有兩個人。", ko: "두 명이에요.", answer: "ふたり です"),
            Q(npc: "ごちゅうもんは？", face: "npc_chinatown", en: "You want to see the menu.", zh: "你想看菜單。", ko: "메뉴를 보고 싶어요.", answer: "メニューを ください"),
            Q(npc: "おのみものは？", face: "npc_chinatown", en: "You'd like water.", zh: "你想要水。", ko: "물을 원해요.", answer: "みずを ください"),
            Q(npc: "たこやき、どうですか？", face: "npc_chinatown", en: "Yes, that sounds good — please.", zh: "好啊，麻煩了。", ko: "좋아요, 부탁해요.", answer: "おねがいします"),
            Q(npc: "あつい から きをつけて！", face: "npc_chinatown", en: "It's hot, but tasty!", zh: "很燙但是好吃！", ko: "뜨겁지만 맛있어요!", answer: "おいしい です"),
            Q(npc: "ありがとう ございました！", face: "npc_chinatown", en: "You want to pay.", zh: "你要結帳。", ko: "계산하고 싶어요.", answer: "おかいけい おねがいします"),
        ],
        // 中国・四国：ホテル・からだ
        6: [
            Q(npc: "いらっしゃいませ。", face: "npc_nakamise", en: "You booked a room. Tell them your name.", zh: "你訂了房間，報上名字。", ko: "방을 예약했어요. 이름을 말해요.", answer: "よやく した ソラ です"),
            Q(npc: "かおいろが わるいですよ。", face: "npc_nakamise", en: "You have a headache.", zh: "你頭痛。", ko: "머리가 아파요.", answer: "あたまが いたい です"),
            Q(npc: "だいじょうぶ ですか？", face: "npc_nakamise", en: "You're fine now.", zh: "你現在沒事了。", ko: "이제 괜찮아요.", answer: "だいじょうぶ です"),
            Q(npc: "おんせんは あちらです。", face: "npc_nakamise", en: "You understand where it is.", zh: "你知道在哪了。", ko: "어디인지 알았어요.", answer: "わかりました"),
            Q(npc: "おやすみなさい。", face: "npc_nakamise", en: "You're going to bed.", zh: "你要睡了。", ko: "자러 가요.", answer: "おやすみなさい"),
            Q(npc: "おはよう ございます！", face: "npc_nakamise", en: "It's the next morning.", zh: "隔天早上。", ko: "다음 날 아침이에요.", answer: "おはよう ございます"),
        ],
        // 九州・沖縄：たびの おわり
        7: [
            Q(npc: "たのしかった？", face: "npc_chinatown", en: "Say the trip was fun.", zh: "說旅行很開心。", ko: "여행이 즐거웠다고 해요.", answer: "たのしかった です"),
            Q(npc: "にほんごが じょうずですね！", face: "npc_chinatown", en: "Be modest: not at all yet.", zh: "謙虛地說還差得遠。", ko: "겸손하게 아직 멀었다고 해요.", answer: "まだまだ です"),
            Q(npc: "また きてね！", face: "npc_chinatown", en: "Promise to come again.", zh: "約好會再來。", ko: "또 오겠다고 해요.", answer: "また きます"),
            Q(npc: "これ、おみやげ。", face: "npc_chinatown", en: "You got a souvenir. Say thanks.", zh: "收到伴手禮了，道謝吧。", ko: "기념품을 받았어요. 고맙다고 해요.", answer: "ありがとう ございます"),
            Q(npc: "しゃしん、とろうか？", face: "npc_chinatown", en: "Yes, please take one.", zh: "好的，麻煩你了。", ko: "네, 부탁해요.", answer: "おねがいします"),
            Q(npc: "げんきでね！", face: "npc_chinatown", en: "Say goodbye.", zh: "說再見。", ko: "작별 인사를 해요.", answer: "さようなら"),
        ],
    ]
}
