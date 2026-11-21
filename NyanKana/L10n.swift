import Foundation

/// UI text in Japanese, Korean and Traditional Chinese.
/// The English learning content itself is shared; only explanations and UI are translated.
/// Japanese line breaks: use "|" in Japanese strings where a line may break (see JPText).
enum L10n: String, CaseIterable {
    case ja, ko, zhHant = "zh-Hant", vi, es, ptBR = "pt-BR", en

    /// the three original languages carry their text inline; the others come from Lang/tr_<code>.json (see Tr)
    var isTable: Bool { self == .vi || self == .es || self == .ptBR || self == .en }

    static var current: L10n = resolve("")

    static func resolve(_ setting: String) -> L10n {
        if let l = L10n(rawValue: setting) { return l }
        let pref = Locale.preferredLanguages.first ?? "ja"
        if pref.hasPrefix("ko") { return .ko }
        if pref.hasPrefix("zh") { return .zhHant }
        if pref.hasPrefix("ja") { return .ja }
        if pref.hasPrefix("vi") { return .vi }
        if pref.hasPrefix("es") { return .es }
        if pref.hasPrefix("pt") { return .ptBR }
        return .en       // every other country: English
    }

    var displayName: String {
        switch self {
        case .ja: "日本語"; case .ko: "한국어"; case .zhHant: "繁體中文"
        case .vi: "Tiếng Việt"; case .es: "Español"; case .ptBR: "Português (Brasil)"; case .en: "English"
        }
    }
}

/// Look up a UI string. Missing keys fall back to Japanese, then to the key itself.
func L(_ key: String) -> String {
    let lang = L10n.current
    if let t = STRINGS[key]?[lang] { return t }
    if let ja = STRINGS[key]?[.ja] { return lang.isTable ? Tr.text(ja) : ja }
    return key
}

func L(_ key: String, _ args: CVarArg...) -> String { String(format: L(key), arguments: args) }

private let STRINGS: [String: [L10n: String]] = [
    // home
    "home.game": [.ja: "ゲーム", .ko: "게임", .zhHant: "遊戲"],
    "home.study": [.ja: "おべんきょう", .ko: "공부", .zhHant: "學習"],
    "home.zukan": [.ja: "ずかん", .ko: "도감", .zhHant: "圖鑑"],
    "home.record": [.ja: "きろく", .ko: "기록", .zhHant: "紀錄"],
    "home.closet": [.ja: "クローゼット", .ko: "옷장", .zhHant: "衣櫃"],
    "home.items": [.ja: "アイテム", .ko: "아이템", .zhHant: "道具"],
    "home.howto": [.ja: "あそび方", .ko: "플레이 방법", .zhHant: "玩法"],
    "home.settings": [.ja: "せってい", .ko: "설정", .zhHant: "設定"],
    "home.shop": [.ja: "プレミアム", .ko: "프리미엄", .zhHant: "高級版"],
    "home.streak": [.ja: "%d日連続", .ko: "%d일 연속", .zhHant: "連續%d天"],
    "home.tagline": [.ja: "ことばを|食べる|ゴブルズから|街を|取り戻せ！", .ko: "말을 먹는 고블즈에게서 마을을 되찾아라!", .zhHant: "從吃掉語言的哥布魯茲手中奪回城鎮！"],
    "common.back": [.ja: "もどる", .ko: "뒤로", .zhHant: "返回"],
    "common.close": [.ja: "とじる", .ko: "닫기", .zhHant: "關閉"],
    "common.home": [.ja: "ホーム", .ko: "홈", .zhHant: "首頁"],
    "common.soon": [.ja: "準備中", .ko: "준비 중", .zhHant: "準備中"],
    "common.locked": [.ja: "まだ行けないよ", .ko: "아직 갈 수 없어요", .zhHant: "還不能前往"],

    // map
    "map.title": [.ja: "ワーディア", .ko: "워디아", .zhHant: "沃迪亞"],
    "map.first": [.ja: "最初から", .ko: "처음부터", .zhHant: "從頭開始"],
    "map.start": [.ja: "つづきから", .ko: "이어서 하기", .zhHant: "繼續遊玩"],
    "map.stages": [.ja: "ステージを選ぶ", .ko: "스테이지 선택", .zhHant: "選擇關卡"],
    "map.boss": [.ja: "ボス：%@", .ko: "보스: %@", .zhHant: "頭目：%@"],
    "map.cleared": [.ja: "%d / %d クリア", .ko: "%d / %d 클리어", .zhHant: "通關 %d / %d"],
    "area.grad.short": [.ja: "卒業", .ko: "졸업", .zhHant: "畢業"],
    "area.1.name": [.ja: "スターター通り", .ko: "스타터 거리", .zhHant: "新手大街"],
    "area.2.name": [.ja: "フューチャー通り", .ko: "퓨처 거리", .zhHant: "未來大街"],
    "area.3.name": [.ja: "トロフィー広場", .ko: "트로피 광장", .zhHant: "獎盃廣場"],
    "area.4.name": [.ja: "ホテル街", .ko: "호텔 거리", .zhHant: "飯店街"],
    "area.5.name": [.ja: "イフの花園", .ko: "이프의 꽃동산", .zhHant: "如果花園"],
    "area.6.name": [.ja: "ロジック研究所", .ko: "로직 연구소", .zhHant: "邏輯研究所"],
    "area.7.name": [.ja: "サイレンス城", .ko: "사일런스 성", .zhHant: "寂靜城"],
    "area.1.boss": [.ja: "ミス・ビー", .ko: "미스 비", .zhHant: "比小姐"],
    "area.2.boss": [.ja: "ウィル", .ko: "윌", .zhHant: "威爾"],
    "area.3.boss": [.ja: "ミスター・ハヴ", .ko: "미스터 해브", .zhHant: "哈夫先生"],
    "area.4.boss": [.ja: "コンシェルジュ・セブン", .ko: "컨시어지 세븐", .zhHant: "禮賓員七號"],
    "area.5.boss": [.ja: "マダム・イフ", .ko: "마담 이프", .zhHant: "如果夫人"],
    "area.6.boss": [.ja: "ドクター・ロジック", .ko: "닥터 로직", .zhHant: "邏輯博士"],
    "area.7.boss": [.ja: "キング・サイレンス", .ko: "킹 사일런스", .zhHant: "寂靜國王"],
    "area.1.grammar": [.ja: "中1｜|be動詞・|一般動詞・|過去形", .ko: "중1｜be동사・일반동사・과거형", .zhHant: "國一｜be動詞・一般動詞・過去式"],
    "area.2.grammar": [.ja: "中2｜|未来・|助動詞・|不定詞・|比較", .ko: "중2｜미래・조동사・to부정사・비교", .zhHant: "國二｜未來式・助動詞・不定詞・比較"],
    "area.3.grammar": [.ja: "中3｜|現在完了・|受け身・|関係代名詞", .ko: "중3｜현재완료・수동태・관계대명사", .zhHant: "國三｜現在完成式・被動・關係代名詞"],
    "area.4.grammar": [.ja: "高1｜|5文型・|時制・|助動詞の発展", .ko: "고1｜5형식・시제・조동사 심화", .zhHant: "高一｜五大句型・時態・助動詞進階"],
    "area.5.grammar": [.ja: "高2｜|仮定法・|関係詞・|分詞構文", .ko: "고2｜가정법・관계사・분사구문", .zhHant: "高二｜假設語氣・關係詞・分詞構句"],
    "area.6.grammar": [.ja: "高3｜|強調・|倒置・|論理の言葉", .ko: "고3｜강조・도치・논리 표현", .zhHant: "高三｜強調・倒裝・邏輯用語"],
    "area.7.grammar": [.ja: "卒業試験｜|全範囲", .ko: "졸업 시험｜전 범위", .zhHant: "畢業考｜全範圍"],

    // difficulty
    "diff.easy.note": [.ja: "4択・ゆっくり\nライフ6", .ko: "4지선다・천천히\n라이프 6", .zhHant: "四選一・慢慢來\n生命6"],
    "diff.normal.note": [.ja: "ときどき2語\nライフ5", .ko: "가끔 두 단어\n라이프 5", .zhHant: "偶爾兩個字\n生命5"],
    "diff.hard.note": [.ja: "並べ替えも\nライフ4", .ko: "배열 문제도\n라이프 4", .zhHant: "也有排序\n生命4"],

    // answer modes
    "mode.choice": [.ja: "選択", .ko: "선택", .zhHant: "選擇"],
    "mode.keyboard": [.ja: "キーボード", .ko: "키보드", .zhHant: "鍵盤"],
    "mode.handwriting": [.ja: "手書き", .ko: "손글씨", .zhHant: "手寫"],
    "mode.voice": [.ja: "声", .ko: "음성", .zhHant: "語音"],

    // settings
    "set.title": [.ja: "せってい", .ko: "설정", .zhHant: "設定"],
    "set.sound": [.ja: "音", .ko: "소리", .zhHant: "聲音"],
    "set.bgm": [.ja: "BGM", .ko: "BGM", .zhHant: "背景音樂"],
    "set.se": [.ja: "効果音", .ko: "효과음", .zhHant: "音效"],
    "set.voice": [.ja: "英語の音声", .ko: "영어 음성", .zhHant: "英語語音"],
    "set.slow": [.ja: "ゆっくり読む", .ko: "천천히 읽기", .zhHant: "慢速朗讀"],
    "set.subtitles": [.ja: "日本語の字幕", .ko: "한국어 자막", .zhHant: "中文字幕"],
    "set.answer": [.ja: "答え方（はじめの設定）", .ko: "답하는 방법（기본）", .zhHant: "作答方式（預設）"],
    "set.lang": [.ja: "表示言語", .ko: "표시 언어", .zhHant: "顯示語言"],
    "set.lang.auto": [.ja: "端末に合わせる", .ko: "기기 설정 따르기", .zhHant: "跟隨裝置"],
    "set.version": [.ja: "バージョン", .ko: "버전", .zhHant: "版本"],
    "set.restore": [.ja: "購入を復元", .ko: "구매 복원", .zhHant: "恢復購買"],

    // dev
    "dev.title": [.ja: "開発モード", .ko: "개발 모드", .zhHant: "開發模式"],
    "dev.unlock": [.ja: "全部開放する", .ko: "전부 열기", .zhHant: "全部解鎖"],
    "dev.premium": [.ja: "プレミアムとして動かす", .ko: "프리미엄으로 실행", .zhHant: "以高級版執行"],
    "dev.buttons": [.ja: "ゲーム中に確認ボタンを出す（正解・まちがい・時間切れ）", .ko: "게임 중 확인 버튼 표시", .zhHant: "遊戲中顯示測試按鈕"],
    "dev.autoCorrect": [.ja: "どんな答えでも正解にする", .ko: "어떤 답이든 정답 처리", .zhHant: "任何答案都算正確"],
    "dev.noDamage": [.ja: "ライフが減らない", .ko: "라이프가 줄지 않음", .zhHant: "生命不減少"],
    "dev.fast": [.ja: "演出を速くする", .ko: "연출 빠르게", .zhHant: "加快動畫"],
    "dev.reset": [.ja: "記録をすべて消す", .ko: "기록 모두 삭제", .zhHant: "清除所有紀錄"],
    "dev.correct": [.ja: "正解", .ko: "정답", .zhHant: "正確"],
    "dev.wrong": [.ja: "まちがい", .ko: "오답", .zhHant: "錯誤"],
    "dev.timeout": [.ja: "時間切れ", .ko: "시간 초과", .zhHant: "時間到"],

    // game
    "game.which": [.ja: "どっちに|行く？", .ko: "어느 쪽으로 갈까?", .zhHant: "要往哪邊走？"],
    "game.left": [.ja: "ひだり", .ko: "왼쪽", .zhHant: "左邊"],
    "game.right": [.ja: "みぎ", .ko: "오른쪽", .zhHant: "右邊"],
    "game.resume": [.ja: "つづける", .ko: "계속하기", .zhHant: "繼續"],
    "game.retry": [.ja: "はじめから", .ko: "처음부터", .zhHant: "重新開始"],
    "game.quit": [.ja: "マップにもどる", .ko: "지도로 돌아가기", .zhHant: "回到地圖"],
    "game.choose": [.ja: "タップで|選べる", .ko: "탭해서 선택", .zhHant: "點選目標"],
    "game.close": [.ja: "おしい！|もう一回！", .ko: "아깝다! 한 번 더!", .zhHant: "差一點！再一次！"],
    "game.closeNear": [.ja: "おしい！|近づいてくるにゃ", .ko: "아깝다! 다가온다냥", .zhHant: "差一點！靠近了喵"],
    "game.eaten": [.ja: "食べられちゃった…|正解を|覚えよう", .ko: "먹혀버렸다… 정답을 기억하자", .zhHant: "被吃掉了…記住正確答案吧"],
    "game.answerWas": [.ja: "正解：", .ko: "정답: ", .zhHant: "正確答案："],
    "game.correctIs": [.ja: "正解は…", .ko: "정답은…", .zhHant: "正確答案是…"],
    "game.remember": [.ja: "タップで|もう一度|聞けるよ", .ko: "탭하면 다시 들을 수 있어요", .zhHant: "點一下可以再聽一次"],
    "game.itemFull": [.ja: "アイテムが|いっぱい", .ko: "아이템이 가득 찼어요", .zhHant: "道具滿了"],
    "game.lifeFull": [.ja: "ライフは|満タンだよ", .ko: "라이프가 가득해요", .zhHant: "生命已滿"],
    "game.noTarget": [.ja: "いまは|使えないよ", .ko: "지금은 쓸 수 없어요", .zhHant: "現在不能用"],
    "game.bonus": [.ja: "ラッキーゴブル！|アイテムを|持ってるよ", .ko: "럭키 고블! 아이템을 가지고 있어", .zhHant: "幸運哥布魯！帶著道具喔"],
    "game.escaped": [.ja: "にげられた！", .ko: "도망갔다!", .zhHant: "被逃走了！"],
    "game.walking": [.ja: "ゴブルズを|さがしてるよ…", .ko: "고블즈를 찾는 중…", .zhHant: "正在尋找哥布魯茲…"],
    "game.type": [.ja: "英語で入力", .ko: "영어로 입력", .zhHant: "用英文輸入"],
    "game.modeSoon": [.ja: "手書き・声は|準備中。|いまは|選んで|答えてね", .ko: "손글씨・음성은 준비 중. 지금은 선택해서 답해 주세요", .zhHant: "手寫・語音準備中，目前請用選擇作答"],
    // story / result
    "story.subOn": [.ja: "字幕 ON", .ko: "자막 ON", .zhHant: "字幕 ON"],
    "story.subOff": [.ja: "字幕 OFF", .ko: "자막 OFF", .zhHant: "字幕 OFF"],
    "res.score": [.ja: "スコア", .ko: "점수", .zhHant: "分數"],
    "res.combo": [.ja: "最大コンボ", .ko: "최대 콤보", .zhHant: "最大連擊"],
    "res.correct": [.ja: "正解した数", .ko: "정답 수", .zhHant: "答對題數"],
    "res.missed": [.ja: "覚えておきたい英語", .ko: "기억해 두고 싶은 영어", .zhHant: "想記住的英文"],
    "res.next": [.ja: "次のストーリーへ", .ko: "다음 스토리로", .zhHant: "前往下一段故事"],
    "res.study": [.ja: "おべんきょうへ", .ko: "공부하러", .zhHant: "去學習"],
    "res.retry": [.ja: "もう一度", .ko: "다시 하기", .zhHant: "再玩一次"],
    "res.map": [.ja: "ステージを選ぶ", .ko: "스테이지 선택", .zhHant: "選擇關卡"],
    "res.overNote": [.ja: "まちがえた|英語は|おべんきょうで|復習できるよ", .ko: "틀린 영어는 공부에서 복습할 수 있어요", .zhHant: "答錯的英文可以在學習模式複習"],
]


/// Translations for Vietnamese, Spanish, Portuguese (Brazil) and English.
/// Lang/tr_<code>.json maps the Japanese source text (without the "|" / "／" line-break marks) to the translation.
/// A missing entry falls back to English, then to the Japanese text.
enum Tr {
    private static var cache: [L10n: [String: String]] = [:]
    private static func table(_ l: L10n) -> [String: String] {
        if let t = cache[l] { return t }
        let code = l == .ptBR ? "pt" : l.rawValue
        var t: [String: String] = [:]
        if let url = Bundle.main.url(forResource: "tr_\(code)", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let d = try? JSONDecoder().decode([String: String].self, from: data) { t = d }
        cache[l] = t
        return t
    }
    static func key(_ ja: String) -> String {
        ja.replacingOccurrences(of: "|", with: "").replacingOccurrences(of: "／", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    /// translation of a Japanese source text into the current table language (or the given one)
    static func text(_ ja: String, _ lang: L10n = L10n.current) -> String {
        let k = key(ja)
        if let t = table(lang)[k] { return t }
        if lang != .en, let t = table(.en)[k] { return t }
        return k
    }
    static func has(_ ja: String, _ lang: L10n = L10n.current) -> Bool { table(lang)[key(ja)] != nil }

    /// Word meanings by headword (vocab_tr.json). Overrides the shared table where the same Japanese
    /// is also a UI text (「もう一度」 = "Try again"), and holds English clues that never contain the word itself.
    private static let vocabTable: [String: [String: String]] = {
        guard let url = Bundle.main.url(forResource: "vocab_tr", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let d = try? JSONDecoder().decode([String: [String: String]].self, from: data) else { return [:] }
        return d
    }()
    static func vocab(_ word: String, ja: String, _ lang: L10n = L10n.current) -> String {
        let code = lang == .ptBR ? "pt" : lang.rawValue
        if let t = vocabTable[word]?[code] { return t }
        return text(ja, lang)
    }
}
