import Foundation

/// Where the residents' names come from: each name split into the English words it is made of,
/// so the picture book teaches words even with the made-up monster names.
enum NameParts {
    struct Part { var en: String; var ja: String; var ko: String; var zh: String
        var meaning: String { T(ja, ko, zh) }
    }
    private static func p(_ en: String, _ ja: String, _ ko: String, _ zh: String) -> Part { .init(en: en, ja: ja, ko: ko, zh: zh) }

    static let table: [String: [Part]] = [
        "Posty": [p("post", "郵便・ポスト", "우편·우체통", "郵件・郵筒")],
        "Vendy": [p("vending machine", "自動販売機", "자판기", "自動販賣機")],
        "Signal Eyes": [p("signal", "信号", "신호", "信號"), p("eyes", "目", "눈", "眼睛")],
        "Trashy": [p("trash", "ごみ", "쓰레기", "垃圾")],
        "Peeper": [p("peep", "のぞき見る", "엿보다", "偷看"), p("-er", "〜する人・もの", "~하는 것", "～的人/東西")],
        "Ringaling": [p("ring", "鳴る", "울리다", "響")],
        "Hoverby": [p("hover", "ふわっと浮く", "떠 있다", "懸浮")],
        "Dronny": [p("drone", "ドローン", "드론", "無人機")],
        "Dust Gulp": [p("dust", "ほこり", "먼지", "灰塵"), p("gulp", "ごくっと飲む", "꿀꺽 삼키다", "大口吞")],
        "Crackphone": [p("crack", "ひび", "금·균열", "裂痕"), p("phone", "電話", "전화", "電話")],
        "Neon Fang": [p("neon", "ネオン", "네온", "霓虹"), p("fang", "きば", "송곳니", "尖牙")],
        "Dish Eye": [p("dish", "お皿・アンテナ", "접시·안테나", "盤子・天線"), p("eye", "目", "눈", "眼睛")],
        "Trophie": [p("trophy", "トロフィー", "트로피", "獎盃")],
        "Medalie": [p("medal", "メダル", "메달", "獎牌")],
        "Spit Whistle": [p("spit", "つばをはく", "침을 뱉다", "吐口水"), p("whistle", "笛", "호루라기", "哨子")],
        "Patchball": [p("patch", "つぎあて", "덧댄 천", "補丁"), p("ball", "ボール", "공", "球")],
        "Shouter": [p("shout", "さけぶ", "외치다", "大喊"), p("-er", "〜する人・もの", "~하는 것", "～的人/東西")],
        "Candy Eyes": [p("candy", "あめ", "사탕", "糖果"), p("eyes", "目", "눈", "眼睛")],
        "Pillowpuff": [p("pillow", "まくら", "베개", "枕頭"), p("puff", "ふわっとしたもの", "푹신한 것", "蓬鬆")],
        "Dingbell": [p("ding", "チーン（音）", "딩 (소리)", "叮（聲音）"), p("bell", "ベル", "벨", "鈴")],
        "Cloche Mouth": [p("cloche", "料理のふた", "음식 뚜껑", "餐蓋"), p("mouth", "口", "입", "嘴")],
        "Stinky Slipper": [p("stinky", "くさい", "냄새나는", "臭的"), p("slipper", "スリッパ", "슬리퍼", "拖鞋")],
        "Eyelier": [p("eye", "目", "눈", "眼睛"), p("chandelier", "シャンデリア", "샹들리에", "吊燈")],
        "Zipkey": [p("zip", "ジッパー", "지퍼", "拉鍊"), p("key", "かぎ", "열쇠", "鑰匙")],
        "Sprinkle": [p("sprinkle", "水をまく", "물을 뿌리다", "灑水")],
        "Rosie": [p("rose", "バラ", "장미", "玫瑰")],
        "Cabbage Snail": [p("cabbage", "キャベツ", "양배추", "高麗菜"), p("snail", "カタツムリ", "달팽이", "蝸牛")],
        "Fungmouth": [p("fungus", "キノコ", "버섯·균", "菌菇"), p("mouth", "口", "입", "嘴")],
        "Hive Eyes": [p("hive", "ハチの巣", "벌집", "蜂巢"), p("eyes", "目", "눈", "眼睛")],
        "Hose Snake": [p("hose", "ホース", "호스", "水管"), p("snake", "ヘビ", "뱀", "蛇")],
        "Flasky": [p("flask", "フラスコ", "플라스크", "燒瓶")],
        "Magnetto": [p("magnet", "磁石", "자석", "磁鐵")],
        "Sludge Tube": [p("sludge", "ドロドロ", "진흙 같은 것", "爛泥"), p("tube", "管・試験管", "관·시험관", "管子")],
        "Calcuscream": [p("calculator", "電卓", "계산기", "計算機"), p("scream", "さけぶ", "비명 지르다", "尖叫")],
        "Brain Bulb": [p("brain", "脳", "뇌", "大腦"), p("bulb", "電球", "전구", "燈泡")],
        "Gear Eye": [p("gear", "歯車", "톱니바퀴", "齒輪"), p("eye", "目", "눈", "眼睛")],
        "Candlet": [p("candle", "ろうそく", "양초", "蠟燭"), p("-let", "小さい〜", "작은 ~", "小～")],
        "Melody Box": [p("melody", "メロディー", "멜로디", "旋律"), p("box", "箱", "상자", "盒子")],
        "Drool Knight": [p("drool", "よだれ", "침", "口水"), p("knight", "騎士", "기사", "騎士")],
        "Bite Book": [p("bite", "かむ", "물다", "咬"), p("book", "本", "책", "書")],
        "Long Knight": [p("long", "長い", "긴", "長的"), p("knight", "騎士", "기사", "騎士")],
        "Hush Bell": [p("hush", "しーっ（静かに）", "쉿 (조용히)", "噓（安靜）"), p("bell", "ベル", "벨", "鈴")],
    ]

    static func of(_ name: String) -> [Part] { table[name] ?? [] }
    /// short form for a picture-book cell: "dust + gulp"
    static func short(_ name: String) -> String {
        of(name).map(\.en).filter { !$0.hasPrefix("-") }.joined(separator: " + ")
    }
}

/// The classic Gobbles are named after what they look like, so they teach a word too.
/// (Checked against the stage enemies' words: no word is used twice in the picture book.)
enum GobbleNames {
    struct Name { var en: String; var ja: String; var ko: String; var zh: String
        var meaning: String { T(ja, ko, zh) }
    }
    private static func n(_ en: String, _ ja: String, _ ko: String, _ zh: String) -> Name { .init(en: en, ja: ja, ko: ko, zh: zh) }

    static let table: [String: Name] = [
        "gob_00": n("Letter O", "アルファベットのO", "알파벳 O", "字母O"),
        "gob_01": n("Bell Pepper", "ピーマン", "피망", "青椒"),
        "gob_02": n("Cocoa", "ココア", "코코아", "可可"),
        "gob_03": n("Speech Bubble", "ふきだし", "말풍선", "對話框"),
        "gob_04": n("Flan", "プリン", "푸딩", "布丁"),
        "gob_05": n("Crayon", "クレヨン", "크레용", "蠟筆"),
        "gob_06": n("Kettle", "やかん", "주전자", "水壺"),
        "gob_07": n("Textbook", "教科書", "교과서", "課本"),
        "gob_08": n("Snowman", "雪だるま", "눈사람", "雪人"),
        "gob_09": n("Pear", "洋なし", "서양배", "西洋梨"),
        "gob_10": n("Taco", "タコス", "타코", "塔可餅"),
        "gob_11": n("Rucksack", "リュックサック", "배낭", "背包"),
        "gob_12": n("Cheeseburger", "チーズバーガー", "치즈버거", "起司漢堡"),
        "gob_13": n("Gamepad", "ゲームのコントローラー", "게임패드", "遊戲手把"),
        "gob_14": n("Spray Can", "スプレー缶", "스프레이 캔", "噴漆罐"),
        "gob_15": n("Paintbrush", "絵筆", "붓", "畫筆"),
        "kimo_b0": n("Lowercase g", "小文字のg", "소문자 g", "小寫的g"),
        "kimo_b1": n("Toothpaste", "歯みがき粉", "치약", "牙膏"),
        "kimo_b2": n("Smartphone", "スマートフォン", "스마트폰", "智慧型手機"),
        "kimo_b3": n("Donut", "ドーナツ", "도넛", "甜甜圈"),
        "kimo_b4": n("Megaphone", "メガホン", "메가폰", "擴音器"),
        "kimo_b5": n("Envelope", "ふうとう", "봉투", "信封"),
        "kimo_b6": n("Binoculars", "双眼鏡", "쌍안경", "雙筒望遠鏡"),
        "kimo_b7": n("Cereal", "シリアル", "시리얼", "麥片"),
        "kimo_a0": n("Capital A", "大文字のA", "대문자 A", "大寫的A"),
        "kimo_a1": n("Stamp", "切手", "우표", "郵票"),
        "kimo_a2": n("Television", "テレビ", "텔레비전", "電視"),
        "kimo_a3": n("Pretzel", "プレッツェル", "프레첼", "椒鹽捲餅"),
        "kimo_a4": n("Cloud", "雲", "구름", "雲"),
        "kimo_a5": n("Maraca", "マラカス", "마라카스", "沙鈴"),
        "kimo_a6": n("Dictionary", "辞書", "사전", "字典"),
        "kimo_a7": n("Medicine", "くすり", "약", "藥"),
    ]
}
