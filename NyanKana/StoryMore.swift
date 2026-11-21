import Foundation

/// More short scenes so the stage openings / endings rarely repeat.
/// Area scenes use that area's grammar, so even the chat is practice.
extension StoryBank {
    typealias Scene = [StoryLine]

    static let areaIntros: [Area: [Scene]] = [
        .lv1: [
            [.init(.ken, "I see a bakery. It smells good!", "パン屋が|見える。|いいにおい！", "빵집이 보여. 냄새 좋다!", "我看到麵包店了。好香！"),
             .init(.nyan, "But the baker can't say 'bread' now!", "でも|パン屋さん、|今は|「パン」って|言えないにゃ！", "그런데 빵집 주인이 지금 '빵'이라고 말을 못 해!", "但是麵包師傅現在說不出「麵包」了！")],
            [.init(.rin, "Did you eat breakfast, Ken?", "ケン、|朝ごはん|食べた？", "켄, 아침 먹었어?", "健，你吃早餐了嗎？"),
             .init(.ken, "Yes, I did. I ate two rice balls!", "うん、|食べたよ。|おにぎり|2個！", "응, 먹었어. 주먹밥 두 개!", "嗯，吃了。吃了兩個飯糰！")],
            [.init(.nyan, "Look! The signs have no words.", "見て！|看板に|字がないにゃ。", "봐! 간판에 글자가 없어.", "你看！招牌上沒有字。"),
             .init(.rin, "We can fix that. Let's go!", "わたしたちが|直せるよ。|行こう！", "우리가 고칠 수 있어. 가자!", "我們可以修好的。走吧！")],
            [.init(.ken, "Where is the station?", "駅は|どこ？", "역이 어디야?", "車站在哪裡？"),
             .init(.nyan, "It is next to the park. Follow me!", "公園の|となりにゃ。|ついてきて！", "공원 옆에 있어. 따라와!", "在公園旁邊。跟我來！")],
        ],
        .lv2: [
            [.init(.rin, "Tomorrow will be sunny, I think.", "明日は|晴れると|思うな。", "내일은 맑을 것 같아.", "我想明天會是晴天。"),
             .init(.ken, "Then we must clear this street today!", "じゃあ|今日中に|この通りを|片づけなきゃ！", "그럼 오늘 안에 이 거리를 정리해야 해!", "那我們今天就得把這條街清乾淨！")],
            [.init(.nyan, "This tower is taller than the one in Starter Street.", "このタワー、|スターター通りのより|高いにゃ。", "이 타워는 스타터 거리의 것보다 높아.", "這座塔比新手大街的還高。"),
             .init(.rin, "It is the tallest building in the city!", "街で|いちばん|高い|建物だね！", "도시에서 가장 높은 건물이야!", "是城市裡最高的建築！")],
            [.init(.ken, "Can you hear the robots?", "ロボットの|声、|聞こえる？", "로봇 소리 들려?", "你聽得到機器人的聲音嗎？"),
             .init(.nyan, "They are going to sing when the words come back!", "言葉が|戻ったら|歌いだすにゃ！", "말이 돌아오면 노래하기 시작할 거야!", "等語言回來，它們就會唱歌！")],
            [.init(.rin, "You should drink some water, Ken.", "ケン、|お水を|飲んだ|ほうがいいよ。", "켄, 물 좀 마시는 게 좋겠어.", "健，你應該喝點水。"),
             .init(.ken, "Thanks. I want to win this time!", "ありがとう。|今回は|勝ちたい！", "고마워. 이번엔 이기고 싶어!", "謝謝。這次我想贏！")],
        ],
        .lv3: [
            [.init(.nyan, "Have you ever seen a trophy that talks?", "しゃべる|トロフィーを|見たこと|あるにゃ？", "말하는 트로피 본 적 있어?", "你看過會說話的獎盃嗎？"),
             .init(.ken, "No, I have never seen one!", "ううん、|一度も|ないよ！", "아니, 한 번도 없어!", "沒有，從來沒看過！")],
            [.init(.rin, "This plaza was built for the festival.", "この広場は|お祭りのために|作られたんだって。", "이 광장은 축제를 위해 지어졌대.", "這個廣場是為了祭典而建的。"),
             .init(.nyan, "But the music has been stolen!", "でも|音楽が|ぬすまれちゃったにゃ！", "그런데 음악을 도둑맞았어!", "但是音樂被偷走了！")],
            [.init(.ken, "The boy who lost his ball is crying.", "ボールを|なくした|男の子が|泣いてる。", "공을 잃어버린 남자아이가 울고 있어.", "弄丟球的男孩在哭。"),
             .init(.rin, "Let's find it for him!", "いっしょに|さがしてあげよう！", "같이 찾아 주자!", "我們幫他找吧！")],
            [.init(.nyan, "I have just remembered something important.", "大事なこと、|今|思い出したにゃ。", "중요한 걸 방금 기억해 냈어.", "我剛想起一件重要的事。"),
             .init(.rin, "What is it?", "なあに？", "뭔데?", "是什麼？"),
             .init(.nyan, "The trophy that the Gobbles want is in this plaza!", "ゴブルズが|ねらってる|トロフィーは|この広場にあるにゃ！", "고블스가 노리는 트로피가 이 광장에 있어!", "高布斯想要的獎盃就在這個廣場！")],
        ],
        .lv4: [
            [.init(.rin, "The hotel manager asked us to help.", "ホテルの|支配人に|手伝ってって|頼まれたよ。", "호텔 지배인이 우리에게 도와 달라고 했어.", "飯店經理請我們幫忙。"),
             .init(.ken, "Let's make this hotel lively again!", "このホテルを|また|にぎやかにしよう！", "이 호텔을 다시 활기차게 만들자!", "讓這間飯店再次熱鬧起來吧！")],
            [.init(.nyan, "The guests had already left when we arrived.", "ぼくたちが|着いたとき、|お客さんは|もう|帰ってたにゃ。", "우리가 도착했을 때 손님들은 이미 떠났어.", "我們到的時候，客人已經離開了。"),
             .init(.rin, "We will bring them back.", "連れ戻そう。", "다시 데려오자.", "我們把他們帶回來吧。")],
            [.init(.ken, "This sofa looks comfortable.", "このソファ、|座り心地|よさそう。", "이 소파 편해 보여.", "這張沙發看起來很舒服。"),
             .init(.nyan, "No time to sit! Something is moving behind it!", "座ってる|ひまはないにゃ！|後ろで|何か|動いてる！", "앉을 시간 없어! 뒤에서 뭔가 움직여!", "沒時間坐！後面有東西在動！")],
            [.init(.rin, "The bellboy told me to be careful on the third floor.", "ベルボーイさんが|3階は|気をつけてって|言ってた。", "벨보이가 3층에서는 조심하라고 했어.", "行李員叫我在三樓要小心。"),
             .init(.ken, "Then we must be ready for anything.", "じゃあ|何が来ても|いいように|しよう。", "그럼 무엇이든 대비해야겠다.", "那我們要做好萬全準備。")],
        ],
        .lv5: [
            [.init(.rin, "If I were a flower, I would bloom right now.", "もし|わたしが|花だったら、|今すぐ|咲くのにな。", "내가 꽃이라면 지금 바로 필 텐데.", "如果我是花，現在就會綻放。"),
             .init(.nyan, "You would be a very noisy flower!", "とっても|にぎやかな|花になるにゃ！", "엄청 시끄러운 꽃이 될 거야!", "那會是一朵很吵的花！")],
            [.init(.ken, "I wish the garden had its colors back.", "庭に|色が|戻ればいいのに。", "정원에 색이 돌아오면 좋을 텐데.", "真希望花園恢復色彩。"),
             .init(.rin, "Then let's make it happen!", "じゃあ|わたしたちで|戻そう！", "그럼 우리가 돌려놓자!", "那我們就讓它實現吧！")],
            [.init(.nyan, "If you hadn't practiced, you couldn't have come this far.", "練習してなかったら、|ここまで|来られなかったにゃ。", "연습하지 않았다면 여기까지 오지 못했을 거야.", "如果沒有練習，就走不到這裡了。"),
             .init(.ken, "Practice really works!", "練習って|本当に|効くね！", "연습은 정말 효과가 있어!", "練習真的有用！")],
            [.init(.rin, "This is the garden where the If Queen lives.", "ここが|イフの女王が|住む|庭だよ。", "여기가 이프 여왕이 사는 정원이야.", "這裡是如果女王住的花園。"),
             .init(.ken, "It looks as if it were asleep.", "まるで|眠ってるみたいだ。", "마치 잠들어 있는 것 같아.", "看起來好像在沉睡。")],
        ],
        .lv6: [
            [.init(.nyan, "It is logic that the Gobbles use here.", "ここで|ゴブルズが|使うのは|論理にゃ。", "여기서 고블스가 쓰는 건 논리야.", "高布斯在這裡用的是邏輯。"),
             .init(.ken, "Then we will answer with grammar!", "じゃあ|文法で|答えてやる！", "그럼 문법으로 답하겠어!", "那我們就用文法回答！")],
            [.init(.rin, "Never have I seen so many machines.", "こんなに|たくさんの|機械、|見たことない。", "이렇게 많은 기계는 본 적이 없어.", "我從沒見過這麼多機器。"),
             .init(.nyan, "Not only machines, but also tiny monsters!", "機械だけじゃなく、|小さな|モンスターも|いるにゃ！", "기계뿐만 아니라 작은 몬스터도 있어!", "不只機器，還有小怪物！")],
            [.init(.ken, "Although it looks difficult, we can do it.", "難しそうだけど、|ぼくたちなら|できる。", "어려워 보이지만 우리는 할 수 있어.", "雖然看起來很難，我們做得到。"),
             .init(.rin, "Yes. The more we try, the stronger we get!", "うん。|やればやるほど|強くなるよ！", "응. 하면 할수록 강해져!", "嗯。越努力就越強！")],
            [.init(.nyan, "Wear goggles in case something explodes!", "何か|爆発しても|いいように|ゴーグルを|つけるにゃ！", "뭔가 폭발할 경우에 대비해 고글을 써!", "戴上護目鏡以防爆炸！"),
             .init(.ken, "Got it. Safety first!", "了解。|安全第一！", "알았어. 안전 제일!", "知道了。安全第一！")],
        ],
        .graduation: [
            [.init(.rin, "We have come a long way since Starter Street.", "スターター通りから|ずいぶん|遠くまで|来たね。", "스타터 거리에서 정말 멀리 왔네.", "從新手大街走到這裡，我們走了好遠。"),
             .init(.ken, "And we have learned so much!", "それに|たくさん|学んだ！", "그리고 정말 많이 배웠어!", "而且學到了好多！")],
            [.init(.nyan, "The castle is silent. Not a single word.", "お城は|しーんと|してるにゃ。|ひとことも|ない。", "성은 조용해. 단 한마디도 없어.", "城堡一片寂靜，連一個字都沒有。"),
             .init(.rin, "Then we will fill it with words.", "なら|言葉で|いっぱいに|しよう。", "그럼 말로 가득 채우자.", "那我們就用語言把它填滿。")],
            [.init(.ken, "If we hadn't met, I wouldn't be here.", "出会ってなかったら、|ぼくは|ここに|いなかった。", "우리가 만나지 않았다면 나는 여기 없었을 거야.", "如果我們沒相遇，我就不會在這裡。"),
             .init(.nyan, "Thank you for coming with me, both of you.", "ふたりとも、|ついてきてくれて|ありがとにゃ。", "둘 다 함께 와 줘서 고마워.", "謝謝你們兩個陪我來。")],
        ],
    ]

    static let areaOutros: [Area: [Scene]] = [
        .lv1: [
            [.init(.rin, "The baker is smiling again!", "パン屋さんが|また|笑ってる！", "빵집 아저씨가 다시 웃고 있어!", "麵包師傅又笑了！"),
             .init(.ken, "I want to buy some bread later.", "あとで|パンを|買いたいな。", "나중에 빵 사고 싶어.", "我等一下想買麵包。")],
            [.init(.nyan, "You used 'be' and 'do' very well!", "be動詞も|一般動詞も|ばっちりにゃ！", "be동사도 일반동사도 완벽해!", "be動詞和一般動詞都用得很好！"),
             .init(.rin, "Practice makes perfect!", "練習あるのみ！", "연습이 완벽을 만들어!", "熟能生巧！")],
            [.init(.ken, "I was a little scared, but now I am fine.", "ちょっと|こわかったけど、|もう|平気。", "조금 무서웠지만 이제 괜찮아.", "剛剛有點怕，但現在沒事了。"),
             .init(.nyan, "You were very brave!", "とても|勇敢だったにゃ！", "정말 용감했어!", "你很勇敢！")],
        ],
        .lv2: [
            [.init(.ken, "The robots are singing now!", "ロボットたちが|歌ってる！", "로봇들이 노래하고 있어!", "機器人在唱歌了！"),
             .init(.rin, "They sing better than I do!", "わたしより|上手！", "나보다 잘 부르네!", "唱得比我還好！")],
            [.init(.nyan, "You will be able to read the signs tomorrow, too.", "明日も|看板が|読めるにゃ。", "내일도 간판을 읽을 수 있을 거야.", "明天也能看懂招牌了。"),
             .init(.ken, "Because we brought the words back!", "言葉を|取り戻したからね！", "말을 되찾았으니까!", "因為我們把語言找回來了！")],
            [.init(.rin, "That was the most exciting battle so far!", "今までで|いちばん|わくわくした|戦いだった！", "지금까지 중 가장 신나는 싸움이었어!", "那是到目前為止最刺激的戰鬥！"),
             .init(.nyan, "And the next one will be even more exciting!", "次は|もっと|わくわくするにゃ！", "다음은 더 신날 거야!", "下一場會更刺激！")],
        ],
        .lv3: [
            [.init(.ken, "The festival music has come back!", "お祭りの|音楽が|戻ってきた！", "축제 음악이 돌아왔어!", "祭典的音樂回來了！"),
             .init(.rin, "Let's dance!", "おどろう！", "춤추자!", "來跳舞吧！")],
            [.init(.nyan, "The trophy was found by the boy!", "トロフィーは|男の子が|見つけたにゃ！", "트로피는 남자아이가 찾았어!", "獎盃被男孩找到了！"),
             .init(.rin, "He looks so happy.", "すごく|うれしそう。", "정말 기뻐 보여.", "他看起來好開心。")],
            [.init(.ken, "I have never felt this strong before.", "こんなに|強くなった気がしたの、|はじめて。", "이렇게 강해진 느낌은 처음이야.", "我從沒覺得自己這麼強過。"),
             .init(.nyan, "That's the power of present perfect!", "それが|現在完了の|力にゃ！", "그게 현재완료의 힘이야!", "這就是現在完成式的力量！")],
        ],
        .lv4: [
            [.init(.rin, "The guests made the lobby noisy again.", "お客さんたちが|ロビーを|またにぎやかに|してくれた。", "손님들이 로비를 다시 시끌벅적하게 만들었어.", "客人們讓大廳又熱鬧起來了。"),
             .init(.ken, "That's a good kind of noise!", "いい|にぎやかさだね！", "좋은 소란이네!", "這是好的熱鬧！")],
            [.init(.nyan, "The manager let us stay for free tonight!", "支配人が|今夜|タダで|泊めてくれるって！", "지배인이 오늘 밤 무료로 묵게 해 준대!", "經理讓我們今晚免費住宿！"),
             .init(.rin, "Yay! I want the room with a view.", "やった！|景色のいい|部屋がいい。", "야호! 전망 좋은 방이 좋아.", "太好了！我想要景觀房。")],
            [.init(.ken, "I heard someone laughing in the hall.", "廊下で|だれかが|笑ってるのが|聞こえた。", "복도에서 누군가 웃는 소리가 들렸어.", "我聽到有人在走廊笑。"),
             .init(.nyan, "The hotel is waking up!", "ホテルが|目を覚ましてるにゃ！", "호텔이 깨어나고 있어!", "飯店正在甦醒！")],
        ],
        .lv5: [
            [.init(.rin, "The flowers are blooming as if they were singing.", "花が|歌ってるみたいに|咲いてる。", "꽃들이 노래하듯이 피어나고 있어.", "花朵像在唱歌一樣綻放著。"),
             .init(.ken, "I wish I had a camera.", "カメラが|あればなあ。", "카메라가 있으면 좋을 텐데.", "要是有相機就好了。")],
            [.init(.nyan, "Without you two, this garden would have stayed gray.", "ふたりが|いなかったら、|この庭は|灰色のままだったにゃ。", "너희 둘이 없었다면 이 정원은 계속 회색이었을 거야.", "沒有你們，這座花園就會一直是灰色的。"),
             .init(.rin, "We are happy to help!", "役に立てて|うれしい！", "도울 수 있어서 기뻐!", "能幫上忙真開心！")],
            [.init(.ken, "If only every day were like this!", "毎日が|こんなだったら|いいのに！", "매일이 이렇다면 좋을 텐데!", "要是每天都像這樣就好了！"),
             .init(.nyan, "Then keep studying every day!", "じゃあ|毎日|勉強するにゃ！", "그럼 매일 공부해!", "那就每天都讀書吧！")],
        ],
        .lv6: [
            [.init(.ken, "It was teamwork that solved the puzzle.", "パズルを|解いたのは|チームワークだった。", "퍼즐을 푼 건 팀워크였어.", "解開謎題的是團隊合作。"),
             .init(.rin, "Logic plus friends equals victory!", "論理|たす|友だちは|勝利！", "논리 더하기 친구는 승리!", "邏輯加朋友等於勝利！")],
            [.init(.nyan, "Not only did you win, but you also learned a lot.", "勝っただけじゃなく、|たくさん|学んだにゃ。", "이겼을 뿐만 아니라 많이 배웠어.", "你們不只贏了，也學到很多。"),
             .init(.ken, "The lab feels warm now.", "研究所が|あたたかく|感じる。", "연구소가 따뜻하게 느껴져.", "研究所感覺溫暖了起來。")],
            [.init(.rin, "No sooner had we won than the lights came on!", "勝ったとたん、|明かりがついた！", "이기자마자 불이 켜졌어!", "我們一贏，燈就亮了！"),
             .init(.nyan, "The machines are thanking you!", "機械たちが|お礼を|言ってるにゃ！", "기계들이 고맙다고 하고 있어!", "機器們在向你們道謝！")],
        ],
        .graduation: [
            [.init(.rin, "One more step to the top.", "てっぺんまで|あと少し。", "꼭대기까지 한 걸음 더.", "再一步就到頂了。"),
             .init(.ken, "We can do it. Together.", "いける。|いっしょなら。", "할 수 있어. 함께라면.", "我們做得到。一起的話。")],
            [.init(.nyan, "I can hear a tiny voice in the castle.", "お城の中から|小さな声が|聞こえるにゃ。", "성 안에서 작은 목소리가 들려.", "我聽到城堡裡有微弱的聲音。"),
             .init(.rin, "Someone is waiting for us.", "だれかが|待ってるんだね。", "누군가 우리를 기다리고 있어.", "有人在等我們。")],
        ],
    ]

    static let moreIntros: [Scene] = [
        [.init(.nyan, "Stretch your fingers. Ready?", "指を|のばして。|準備はいい？", "손가락 풀고. 준비됐어?", "伸展一下手指。準備好了嗎？"),
         .init(.rin, "Ready when you are!", "いつでも|いいよ！", "언제든지 좋아!", "隨時都可以！")],
        [.init(.ken, "Rin, what did you study today?", "リン、|今日は|何を|勉強した？", "린, 오늘 뭐 공부했어?", "凜，你今天讀了什麼？"),
         .init(.rin, "Twenty new words! Let's use them.", "新しい単語を|20個！|使ってみよう。", "새 단어 20개! 써 보자.", "二十個新單字！來用用看吧。")],
        [.init(.nyan, "I smell Gobbles. Lots of them!", "ゴブルズの|においがするにゃ。|たくさん！", "고블스 냄새가 나. 아주 많아!", "我聞到高布斯的味道。好多！"),
         .init(.ken, "Bring it on!", "かかってこい！", "덤벼라!", "放馬過來！")],
        [.init(.rin, L10n.current == .ja ? "Remember: read the Japanese first, then think in English." : L10n.current == .en ? "Remember: picture the scene first, then answer in English." : "Remember: read the meaning first, then think in English.", "まず|日本語を|読んで、|それから|英語で|考えてね。", "먼저 뜻을 읽고 영어로 생각해.", "記得：先看意思，再用英文思考。"),
         .init(.ken, "Got it, teacher Rin!", "了解、|リン先生！", "알겠습니다, 린 선생님!", "知道了，凜老師！")],
        [.init(.nyan, "If you get stuck, try the textbook later.", "つまずいたら、|あとで|教本を|見るにゃ。", "막히면 나중에 교본을 봐.", "卡住的話，之後看看教本吧。"),
         .init(.rin, "Good idea!", "いい考え！", "좋은 생각이야!", "好主意！")],
        [.init(.ken, "I feel lucky today.", "今日は|ついてる|気がする。", "오늘은 운이 좋은 것 같아.", "我今天覺得很幸運。"),
         .init(.nyan, "Maybe a Mochi will appear!", "モチが|出るかもにゃ！", "모치가 나올지도 몰라!", "說不定會出現麻糬！")],
        [.init(.rin, "Did you see that shadow?", "今の|影、|見た？", "방금 그림자 봤어?", "你看到剛才的影子了嗎？"),
         .init(.ken, "Yes. Something is hiding there.", "うん。|何か|かくれてる。", "응. 뭔가 숨어 있어.", "嗯。有東西躲在那裡。")],
        [.init(.nyan, "Speed is good, but correct is better!", "速さも|大事だけど、|正確さは|もっと|大事にゃ！", "속도도 좋지만 정확함이 더 중요해!", "速度很好，但正確更重要！"),
         .init(.ken, "Slow and steady!", "あわてず|確実に！", "천천히 확실하게!", "穩紮穩打！")],
        [.init(.rin, "I want to fill the picture book.", "図鑑を|うめたいな。", "도감을 채우고 싶어.", "我想把圖鑑填滿。"),
         .init(.nyan, "Every stage has its own monsters!", "ステージごとに|ちがう|モンスターがいるにゃ！", "스테이지마다 다른 몬스터가 있어!", "每一關都有不同的怪物！")],
        [.init(.ken, "My stomach is making noise.", "おなかが|鳴ってる。", "배에서 소리가 나.", "我的肚子在叫。"),
         .init(.rin, "Let's finish this street and eat lunch!", "この通りを|終わらせて|お昼にしよう！", "이 거리를 끝내고 점심 먹자!", "解決這條街再去吃午餐！")],
        [.init(.nyan, "Listen carefully to the English voice.", "英語の|声を|よく|聞くにゃ。", "영어 목소리를 잘 들어.", "仔細聽英文的聲音。"),
         .init(.ken, "Listening is half of learning!", "聞くことは|学びの|半分だ！", "듣기는 배움의 절반이야!", "聽力是學習的一半！")],
        [.init(.rin, "Ken, your combo was amazing last time.", "ケン、|この前の|コンボ、|すごかったね。", "켄, 지난번 콤보 대단했어.", "健，你上次的連擊好厲害。"),
         .init(.ken, "This time I'll get FEVER!", "今回は|フィーバーを|ねらう！", "이번엔 피버를 노릴 거야!", "這次我要觸發FEVER！")],
    ]

    static let moreOutros: [Scene] = [
        [.init(.nyan, "Did you notice? You answered faster this time.", "気づいた？|今回は|答えるのが|速かったにゃ。", "눈치챘어? 이번엔 더 빨리 대답했어.", "你發現了嗎？這次答得更快了。"),
         .init(.ken, "Really? Yes!", "ほんと？|やった！", "정말? 앗싸!", "真的嗎？太好了！")],
        [.init(.rin, "The words you missed are waiting in the review.", "まちがえた|言葉は|復習で|待ってるよ。", "틀린 말은 복습에서 기다리고 있어.", "答錯的字在複習裡等著你。"),
         .init(.ken, "I'll beat them tomorrow!", "明日|やっつける！", "내일 해치울 거야!", "我明天就搞定它們！")],
        [.init(.nyan, "Another street is shining!", "また|ひとつ|通りが|かがやいたにゃ！", "또 하나의 거리가 빛나고 있어!", "又一條街道閃耀起來了！"),
         .init(.rin, "Wordia is getting brighter!", "ワーディアが|明るく|なってきた！", "워디아가 밝아지고 있어!", "沃迪亞越來越亮了！")],
        [.init(.ken, "I want to try this stage on hard mode.", "このステージ、|むずかしいモードでも|やってみたい。", "이 스테이지를 어려운 모드로도 해 보고 싶어.", "我想用困難模式挑戰這一關。"),
         .init(.nyan, "Hard mode has longer sentences. Good luck!", "むずかしいモードは|文が|長いにゃ。|がんばれ！", "어려운 모드는 문장이 길어. 힘내!", "困難模式的句子比較長。加油！")],
        [.init(.rin, "Let's take a short break.", "ちょっと|休けいしよう。", "잠깐 쉬자.", "休息一下吧。"),
         .init(.nyan, "Rest is part of studying, too!", "休むのも|勉強の|うちにゃ！", "쉬는 것도 공부의 일부야!", "休息也是讀書的一部分！")],
        [.init(.ken, "That monster looked funny.", "あのモンスター、|おもしろい顔|してたね。", "그 몬스터 웃긴 얼굴이었어.", "那個怪物的臉好好笑。"),
         .init(.rin, "Check the picture book! Its name is an English word.", "図鑑を|見てみて！|名前が|英単語なんだよ。", "도감을 봐! 이름이 영어 단어야.", "去看圖鑑！它的名字是英文單字。")],
        [.init(.nyan, "Three stars? Let's aim for that next time.", "星3つ？|次は|それを|ねらうにゃ。", "별 세 개? 다음엔 그걸 노리자.", "三顆星？下次以它為目標吧。"),
         .init(.ken, "Okay!", "オッケー！", "오케이!", "好！")],
        [.init(.rin, "I learned a new word from that sentence.", "今の|文で|新しい単語を|覚えた。", "방금 문장에서 새 단어를 배웠어.", "我從剛才的句子學到一個新單字。"),
         .init(.nyan, "Look it up in the dictionary later!", "あとで|辞書で|しらべるにゃ！", "나중에 사전에서 찾아봐!", "之後查查字典吧！")],
        [.init(.ken, "The townspeople are waving at us!", "町の人たちが|手を|ふってる！", "마을 사람들이 손을 흔들고 있어!", "鎮上的人在向我們揮手！"),
         .init(.rin, "Hello! You're welcome!", "こんにちは！|どういたしまして！", "안녕하세요! 천만에요!", "你好！不客氣！")],
        [.init(.nyan, "You're getting closer to the boss.", "ボスに|近づいてるにゃ。", "보스에게 가까워지고 있어.", "越來越接近頭目了。"),
         .init(.ken, "I can't wait!", "待ちきれない！", "못 기다리겠어!", "等不及了！")],
        [.init(.rin, "Study a little, play a little. That's the best way.", "少し|勉強して、|少し|遊ぶ。|それが|いちばん。", "조금 공부하고 조금 놀고. 그게 최고야.", "讀一點書，玩一點遊戲。這樣最好。"),
         .init(.nyan, "Rin is right!", "リンの|言うとおりにゃ！", "린 말이 맞아!", "凜說得對！")],
        [.init(.ken, "Every word we save makes someone smile.", "言葉を|ひとつ|助けるたびに、|だれかが|笑顔になる。", "말을 하나 구할 때마다 누군가가 웃어.", "每救回一個字，就有人露出笑容。"),
         .init(.rin, "That's why we keep going.", "だから|進み続けるんだね。", "그래서 계속 가는 거야.", "所以我們要繼續前進。")],
    ]

    /// Short scene for a normal stage: area scenes + shared ones, avoiding the ones seen recently.
    static func freshScene(_ ref: StageRef, _ kind: StoryKind) -> [StoryLine] {
        let pool: [Scene] = kind == .intro
            ? (areaIntros[ref.area] ?? []) + moreIntros + shortIntros + funIntros
            : (areaOutros[ref.area] ?? []) + moreOutros + shortOutros + funOutros
        let key = "story.recent.\(kind == .intro ? "i" : "o")"
        var recent = UserDefaults.standard.stringArray(forKey: key) ?? []
        let ids = pool.map { $0.first?.en ?? "" }
        let fresh = pool.indices.filter { !recent.contains(ids[$0]) }
        let i = (fresh.isEmpty ? Array(pool.indices) : fresh).randomElement() ?? 0
        recent.append(ids[i])
        if recent.count > max(4, pool.count * 2 / 3) { recent.removeFirst(recent.count - max(4, pool.count * 2 / 3)) }
        UserDefaults.standard.set(recent, forKey: key)
        return pool[i]
    }
}

/// Nyan's short lines during play — many variants so they don't feel repetitive.
enum GameTalk {
    static var praise: [String] { [
        T("ナイス！", "나이스!", "漂亮！"), T("その調子にゃ！", "그 기세야!", "保持下去！"),
        T("完璧にゃ！", "완벽해!", "完美！"), T("英語の|センス|あるにゃ！", "영어 센스 있다!", "很有英文天分！"),
        T("いいリズム！", "좋은 리듬!", "節奏很好！"), T("さすがにゃ！", "역시!", "不愧是你！"),
        T("覚えてたね！", "기억하고 있었구나!", "你記得耶！"), T("きもちいい〜！", "기분 좋아~!", "好爽快～！"),
        T("どんどん|いくにゃ！", "계속 가자!", "繼續衝！"), T("Good job!", "Good job!", "Good job!"),
    ] }
    static var miss: [String] { [
        T("おしい！|もう一回！", "아깝다! 한 번 더!", "差一點！再一次！"), T("落ち着いて|読むにゃ", "침착하게 읽어", "冷靜讀一下"),
        T("主語を|見てみて！", "주어를 봐!", "看看主詞！"), T("時制に|注意にゃ！", "시제에 주의!", "注意時態！"),
        T("あと|ちょっと！", "조금만 더!", "就差一點！"), T("近づいてくるにゃ！", "다가온다!", "靠近了！"),
        T("意味を|もう一度|見て！", "뜻을 다시 봐!", "再看一次意思！"), T("だいじょうぶ、|次は|いける！", "괜찮아, 다음엔 할 수 있어!", "沒關係，下次可以！"),
    ] }
}
