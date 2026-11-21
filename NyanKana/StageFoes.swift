import SwiftUI
import UIKit

/// Every normal stage has two enemies of its own (never seen anywhere else),
/// plus one more for each difficulty (EASY / NORMAL / HARD only).
/// The names are the English words for the objects, so the picture book teaches vocabulary too.
@MainActor
enum StageFoes {
    struct Info: Identifiable {
        let id: String
        let en: String
        let ja: String, ko: String, zh: String
        /// 0 cute, 1 gross, 2 creepy-cute
        let type: Int
        let area: Area
        let stage: Int
        var meaning: String { T(ja, ko, zh) }
        /// set for the enemies that only appear on one difficulty
        var diff: Difficulty? = nil
        var typeLabel: String {
            let t: String
            switch type {
            case 0: t = T("かわいい", "귀여움", "可愛")
            case 1: t = T("キモい", "징그러움", "噁心")
            case 3: t = T("つよい", "강함", "強悍")
            default: t = T("キモかわ", "징그귀여움", "噁心可愛")
            }
            guard let diff else { return t }
            return t + " ・ " + diff.title + T("限定", " 한정", "限定")
        }
    }

    static func normalStages(_ a: Area) -> [Int] { (1...a.stageCount).filter { $0 % 10 != 0 } }

    static let all: [Info] = {
        var out: [Info] = []
        for line in raw.split(separator: "\n") {
            let f = line.split(separator: "|").map(String.init)
            guard f.count == 6 else { continue }
            let parts = f[0].split(separator: "_").map(String.init)
            // st_{area}_{k}: the two shared stage enemies / sd_{area}_{e|n|h}_{k}: one per stage per difficulty
            guard parts.count == 3 || parts.count == 4, let a = Int(parts[1]), let k = Int(parts.last!), let area = Area(rawValue: a) else { continue }
            // difficulty enemies are added as their pictures arrive: skip any without a picture yet
            if parts.count == 4 && UIImage(named: f[0]) == nil { continue }
            var diff: Difficulty? = nil
            if parts.count == 4 {
                switch parts[2] { case "e": diff = .easy; case "n": diff = .normal; default: diff = .hard }
            }
            let normals = normalStages(area)
            let stage = normals[k % normals.count]
            out.append(Info(id: f[0], en: f[1], ja: f[2], ko: f[3], zh: f[4], type: Int(f[5]) ?? 0, area: area, stage: stage, diff: diff))
        }
        return out
    }()
    static let byID: [String: Info] = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    /// the stage's own two enemies
    static func exclusive(_ a: Area, _ index: Int) -> [String] { all.filter { $0.area == a && $0.stage == index && $0.diff == nil }.map(\.id) }
    /// the stage's enemy that only shows up on this difficulty
    static func special(_ a: Area, _ index: Int, _ d: Difficulty) -> String? { all.first { $0.area == a && $0.stage == index && $0.diff == d }?.id }
    static func area(_ a: Area) -> [Info] { all.filter { $0.area == a }.sorted { ($0.stage, $0.id) < ($1.stage, $1.id) } }

    static let raw = """
st_1_0|Pencil|えんぴつ|연필|鉛筆|0
st_1_1|Eraser|消しゴム|지우개|橡皮擦|0
st_1_2|Ruler|定規|자|尺|0
st_1_3|Glue Stick|スティックのり|딱풀|口紅膠|1
st_1_4|Scissors|はさみ|가위|剪刀|1
st_1_5|Homework|宿題|숙제|作業|1
st_1_6|Crayon Box|クレヨン箱|크레용 상자|蠟筆盒|2
st_1_7|Pencil Sharpener|えんぴつけずり|연필깎이|削鉛筆機|2
st_1_8|Backpack|リュック|배낭|背包|2
st_1_9|Rice Ball|おにぎり|주먹밥|飯糰|0
st_1_10|Bento Box|弁当箱|도시락|便當盒|0
st_1_11|Juice Box|紙パックジュース|팩 주스|鋁箔包果汁|0
st_1_12|Cup Noodles|カップめん|컵라면|杯麵|1
st_1_13|Sandwich|サンドイッチ|샌드위치|三明治|1
st_1_14|Milk Carton|牛乳パック|우유팩|牛奶盒|1
st_1_15|Melon Bread|メロンパン|메론빵|菠蘿麵包|2
st_1_16|Canned Coffee|缶コーヒー|캔커피|罐裝咖啡|2
st_1_17|Chopsticks|はし|젓가락|筷子|2
st_1_18|Fire Hydrant|消火栓|소화전|消防栓|0
st_1_19|Bus Stop Sign|バス停の標識|버스 정류장 표지판|公車站牌|0
st_1_20|Kick Scooter|キックスクーター|킥보드|滑板車|0
st_1_21|Parking Meter|パーキングメーター|주차 미터기|停車計時器|1
st_1_22|Traffic Cone|三角コーン|교통 콘|三角錐|1
st_1_23|Street Lamp|街灯|가로등|路燈|1
st_1_24|Road Roller|ロードローラー|로드 롤러|壓路機|2
st_1_25|Shopping Bag|買い物袋|쇼핑백|購物袋|2
st_1_26|Newspaper|新聞|신문|報紙|2
st_1_27|Slide|すべり台|미끄럼틀|溜滑梯|0
st_1_28|Swing|ブランコ|그네|鞦韆|0
st_1_29|Sand Bucket|砂場のバケツ|모래 양동이|沙桶|0
st_1_30|Seesaw|シーソー|시소|翹翹板|1
st_1_31|Water Fountain|水飲み場|음수대|飲水機|1
st_1_32|Trash Bin|ゴミ箱|쓰레기통|垃圾桶|1
st_1_33|Jungle Gym|ジャングルジム|정글짐|攀爬架|2
st_1_34|Kite|たこ|연|風箏|2
st_1_35|Paper Airplane|紙飛行機|종이비행기|紙飛機|2
st_1_36|Alarm Clock|目覚まし時計|알람 시계|鬧鐘|0
st_1_37|Toothbrush|歯ブラシ|칫솔|牙刷|0
st_1_38|Umbrella|かさ|우산|雨傘|0
st_1_39|Sock|くつ下|양말|襪子|1
st_1_40|Pillowcase|まくらカバー|베갯잇|枕頭套|1
st_1_41|Slipper|スリッパ|슬리퍼|拖鞋|1
st_1_42|Tissue Box|ティッシュ箱|티슈 상자|面紙盒|2
st_1_43|Hair Dryer|ドライヤー|드라이어|吹風機|2
st_1_44|Washing Machine|洗濯機|세탁기|洗衣機|2
st_1_45|Teapot|ティーポット|찻주전자|茶壺|0
st_1_46|Frying Pan|フライパン|프라이팬|平底鍋|0
st_1_47|Rice Cooker|炊飯器|밥솥|電鍋|0
st_1_48|Sponge|スポンジ|스펀지|海綿|1
st_1_49|Garbage Bag|ゴミ袋|쓰레기봉투|垃圾袋|1
st_1_50|Toaster|トースター|토스터|烤麵包機|1
st_1_51|Refrigerator|冷蔵庫|냉장고|冰箱|2
st_1_52|Ladle|おたま|국자|湯勺|2
st_1_53|Gas Stove|ガスコンロ|가스레인지|瓦斯爐|2
st_2_0|Earbuds|イヤホン|이어폰|耳機|0
st_2_1|Smartwatch|スマートウォッチ|스마트워치|智慧手錶|0
st_2_2|VR Goggles|VRゴーグル|VR 고글|VR眼鏡|0
st_2_3|Game Controller|ゲームコントローラー|게임 컨트롤러|遊戲手把|1
st_2_4|Tablet|タブレット|태블릿|平板|1
st_2_5|USB Stick|USBメモリ|USB 메모리|隨身碟|1
st_2_6|Webcam|ウェブカメラ|웹캠|網路攝影機|2
st_2_7|Mouse|マウス|마우스|滑鼠|2
st_2_8|Keyboard|キーボード|키보드|鍵盤|2
st_2_9|Helper Robot|お手伝いロボ|도우미 로봇|幫手機器人|0
st_2_10|Robot Dog|ロボット犬|로봇 강아지|機器狗|0
st_2_11|Delivery Robot|配達ロボ|배달 로봇|外送機器人|0
st_2_12|Rusty Robot|さびたロボ|녹슨 로봇|生鏽機器人|1
st_2_13|Robot Arm|ロボットアーム|로봇 팔|機械手臂|1
st_2_14|Vending Robot|自販機ロボ|자판기 로봇|販賣機器人|1
st_2_15|Security Camera|防犯カメラ|방범 카메라|監視器|2
st_2_16|Cleaning Robot|おそうじロボ|청소 로봇|掃地機器人|2
st_2_17|TV Robot|テレビ頭ロボ|TV 로봇|電視機器人|2
st_2_18|Electric Scooter|電動スクーター|전동 스쿠터|電動滑板車|0
st_2_19|Minibus|ミニバス|미니버스|小巴|0
st_2_20|Flying Car|空飛ぶ車|하늘을 나는 차|飛天車|0
st_2_21|Hoverboard|ホバーボード|호버보드|懸浮滑板|1
st_2_22|Monorail|モノレール|모노레일|單軌電車|1
st_2_23|Charging Station|充電スタンド|충전소|充電站|1
st_2_24|Drone|ドローン|드론|無人機|2
st_2_25|Jetpack|ジェットパック|제트팩|噴射背包|2
st_2_26|Bubble Car|バブルカー|버블카|泡泡車|2
st_2_27|Battery|電池|건전지|電池|0
st_2_28|Plug|コンセントプラグ|플러그|插頭|0
st_2_29|Light Switch|スイッチ|스위치|開關|0
st_2_30|Cable|ケーブル|케이블|電線|1
st_2_31|Solar Panel|ソーラーパネル|태양광 패널|太陽能板|1
st_2_32|Power Strip|電源タップ|멀티탭|延長線|1
st_2_33|Spark Plug|点火プラグ|점화 플러그|火星塞|2
st_2_34|Charger|充電器|충전기|充電器|2
st_2_35|Power Tower|鉄塔|송전탑|電塔|2
st_2_36|Rocket|ロケット|로켓|火箭|0
st_2_37|UFO|UFO|UFO|幽浮|0
st_2_38|Space Helmet|宇宙ヘルメット|우주 헬멧|太空頭盔|0
st_2_39|Asteroid|小惑星|소행성|小行星|1
st_2_40|Moon Rock|月の石|월석|月球岩石|1
st_2_41|Antenna|アンテナ|안테나|天線|1
st_2_42|Telescope|望遠鏡|망원경|望遠鏡|2
st_2_43|Satellite|人工衛星|인공위성|人造衛星|2
st_2_44|Planet|惑星|행성|行星|2
st_2_45|Hologram|ホログラム|홀로그램|全息投影|0
st_2_46|QR Code|QRコード|QR 코드|QR碼|0
st_2_47|Balloon|ふうせん|풍선|氣球|0
st_2_48|Chat Bubble|ふきだし|말풍선|對話框|1
st_2_49|Loading Spinner|読みこみマーク|로딩 표시|讀取圖示|1
st_2_50|Error Window|エラー画面|오류 창|錯誤視窗|1
st_2_51|Cloud Server|クラウドサーバー|클라우드 서버|雲端伺服器|2
st_2_52|3D Printer|3Dプリンター|3D 프린터|3D印表機|2
st_2_53|Password Lock|パスワードロック|비밀번호 잠금|密碼鎖|2
st_3_0|Baseball|野球ボール|야구공|棒球|0
st_3_1|Tennis Ball|テニスボール|테니스공|網球|0
st_3_2|Volleyball|バレーボール|배구공|排球|0
st_3_3|Rugby Ball|ラグビーボール|럭비공|橄欖球|1
st_3_4|Bowling Pin|ボウリングのピン|볼링핀|保齡球瓶|1
st_3_5|Hockey Puck|ホッケーのパック|하키 퍽|冰球|1
st_3_6|Golf Ball|ゴルフボール|골프공|高爾夫球|2
st_3_7|Shuttlecock|シャトル|셔틀콕|羽毛球|2
st_3_8|Paddle|卓球ラケット|탁구채|桌球拍|2
st_3_9|Takoyaki|たこ焼き|다코야키|章魚燒|0
st_3_10|Candy Apple|りんごあめ|사과 사탕|蘋果糖|0
st_3_11|Cotton Candy|わたあめ|솜사탕|棉花糖|0
st_3_12|Yakisoba|焼きそば|야키소바|炒麵|1
st_3_13|Corn Dog|アメリカンドッグ|콘도그|熱狗棒|1
st_3_14|Shaved Ice|かき氷|빙수|剉冰|1
st_3_15|Taiyaki|たい焼き|붕어빵|鯛魚燒|2
st_3_16|Grilled Squid|イカ焼き|오징어구이|烤魷魚|2
st_3_17|Choco Banana|チョコバナナ|초코 바나나|巧克力香蕉|2
st_3_18|Goldfish|金魚|금붕어|金魚|0
st_3_19|Water Balloon|ヨーヨー風船|요요 풍선|水球|0
st_3_20|Mask|お面|가면|面具|0
st_3_21|Lantern|ちょうちん|등롱|燈籠|1
st_3_22|Cork Gun|コルク銃|코르크 총|軟木塞槍|1
st_3_23|Ring Toss|輪投げ|고리 던지기|套圈圈|1
st_3_24|Firework|花火|불꽃놀이|煙火|2
st_3_25|Drum|太鼓|북|太鼓|2
st_3_26|Hand Fan|うちわ|부채|團扇|2
st_3_27|Dumbbell|ダンベル|덤벨|啞鈴|0
st_3_28|Jump Rope|なわとび|줄넘기|跳繩|0
st_3_29|Stopwatch|ストップウォッチ|스톱워치|碼錶|0
st_3_30|Towel|タオル|수건|毛巾|1
st_3_31|Sneaker|スニーカー|운동화|運動鞋|1
st_3_32|Water Bottle|水筒|물병|水壺|1
st_3_33|Whistle|ホイッスル|호루라기|哨子|2
st_3_34|Kettlebell|ケトルベル|케틀벨|壺鈴|2
st_3_35|Yoga Mat|ヨガマット|요가 매트|瑜伽墊|2
st_3_36|Trumpet|トランペット|트럼펫|小號|0
st_3_37|Snare Drum|小太鼓|작은북|小鼓|0
st_3_38|Tambourine|タンバリン|탬버린|鈴鼓|0
st_3_39|Tuba|チューバ|튜바|低音號|1
st_3_40|Violin|バイオリン|바이올린|小提琴|1
st_3_41|Maracas|マラカス|마라카스|沙鈴|1
st_3_42|Cymbals|シンバル|심벌즈|鈸|2
st_3_43|Recorder|リコーダー|리코더|直笛|2
st_3_44|Metronome|メトロノーム|메트로놈|節拍器|2
st_3_45|Ribbon Badge|リボンバッジ|리본 배지|緞帶徽章|0
st_3_46|Confetti Cannon|紙ふぶき砲|꽃가루 대포|彩帶砲|0
st_3_47|Podium|表彰台|시상대|頒獎台|0
st_3_48|Champagne|シャンパン|샴페인|香檳|1
st_3_49|Scoreboard|スコアボード|점수판|記分板|1
st_3_50|Camera|カメラ|카메라|相機|1
st_3_51|Microphone|マイク|마이크|麥克風|2
st_3_52|Red Carpet|レッドカーペット|레드카펫|紅地毯|2
st_3_53|Pom-pom|ポンポン|응원 술|彩球|2
st_4_0|Rubber Duck|おもちゃのアヒル|고무 오리|小黃鴨|0
st_4_1|Soap|石けん|비누|肥皂|0
st_4_2|Shampoo|シャンプー|샴푸|洗髮精|0
st_4_3|Bath Towel|バスタオル|목욕 수건|浴巾|1
st_4_4|Bath Mat|バスマット|욕실 매트|浴墊|1
st_4_5|Shower Head|シャワーヘッド|샤워기|蓮蓬頭|1
st_4_6|Toilet Paper|トイレットペーパー|화장지|衛生紙|2
st_4_7|Bathtub|浴そう|욕조|浴缸|2
st_4_8|Hand Mirror|手鏡|손거울|手鏡|2
st_4_9|Lamp|スタンドライト|스탠드|檯燈|0
st_4_10|Remote Control|リモコン|리모컨|遙控器|0
st_4_11|Mini Fridge|ミニ冷蔵庫|미니 냉장고|小冰箱|0
st_4_12|Hanger|ハンガー|옷걸이|衣架|1
st_4_13|Curtain|カーテン|커튼|窗簾|1
st_4_14|Safe|金庫|금고|保險箱|1
st_4_15|Wardrobe|洋服だんす|옷장|衣櫃|2
st_4_16|Telephone|電話|전화기|電話|2
st_4_17|Door Sign|ドアプレート|문패|門牌|2
st_4_18|Croissant|クロワッサン|크루아상|可頌|0
st_4_19|Pancake|パンケーキ|팬케이크|鬆餅|0
st_4_20|Wine Glass|ワイングラス|와인잔|酒杯|0
st_4_21|Omelet|オムレツ|오믈렛|歐姆蛋|1
st_4_22|Steak|ステーキ|스테이크|牛排|1
st_4_23|Teacup|ティーカップ|찻잔|茶杯|1
st_4_24|Bread Basket|パンかご|빵 바구니|麵包籃|2
st_4_25|Jelly|ゼリー|젤리|果凍|2
st_4_26|Gravy Boat|グレイビーボート|그레이비 보트|醬汁壺|2
st_4_27|Luggage Cart|荷物カート|짐 카트|行李推車|0
st_4_28|Potted Palm|鉢植えのヤシ|야자 화분|盆栽椰子|0
st_4_29|Umbrella Stand|かさ立て|우산꽂이|傘架|0
st_4_30|Revolving Door|回転ドア|회전문|旋轉門|1
st_4_31|Lost And Found|落とし物箱|분실물 상자|失物招領箱|1
st_4_32|Sofa|ソファ|소파|沙發|1
st_4_33|Grandfather Clock|柱時計|괘종시계|落地鐘|2
st_4_34|Desk Bell|呼び鈴|호출 벨|服務鈴|2
st_4_35|Elevator Button|エレベーターのボタン|엘리베이터 버튼|電梯按鈕|2
st_4_36|Iron|アイロン|다리미|熨斗|0
st_4_37|Laundry Basket|洗濯かご|빨래 바구니|洗衣籃|0
st_4_38|Mop|モップ|대걸레|拖把|0
st_4_39|Bucket|バケツ|양동이|水桶|1
st_4_40|Vacuum Cleaner|掃除機|청소기|吸塵器|1
st_4_41|Clothespin|洗濯ばさみ|빨래집게|曬衣夾|1
st_4_42|Detergent|洗剤|세제|洗衣粉|2
st_4_43|Duster|はたき|먼지떨이|雞毛撢子|2
st_4_44|Bedsheet|シーツ|침대 시트|床單|2
st_4_45|Swim Ring|うき輪|튜브|游泳圈|0
st_4_46|Sunglasses|サングラス|선글라스|太陽眼鏡|0
st_4_47|Beach Ball|ビーチボール|비치볼|沙灘球|0
st_4_48|Pool Noodle|プールヌードル|수영 누들|浮力棒|1
st_4_49|Deck Chair|デッキチェア|선베드|躺椅|1
st_4_50|Flip-flop|ビーチサンダル|조리|夾腳拖|1
st_4_51|Sunscreen|日焼け止め|선크림|防曬乳|2
st_4_52|Parasol|パラソル|파라솔|陽傘|2
st_4_53|Snorkel|シュノーケル|스노클|呼吸管|2
st_5_0|Ladybug|テントウムシ|무당벌레|瓢蟲|0
st_5_1|Butterfly|チョウ|나비|蝴蝶|0
st_5_2|Bumblebee|マルハナバチ|호박벌|熊蜂|0
st_5_3|Caterpillar|イモムシ|애벌레|毛毛蟲|1
st_5_4|Stink Bug|カメムシ|노린재|椿象|1
st_5_5|Mosquito|カ|모기|蚊子|1
st_5_6|Mantis|カマキリ|사마귀|螳螂|2
st_5_7|Beetle|カブトムシ|딱정벌레|甲蟲|2
st_5_8|Spider|クモ|거미|蜘蛛|2
st_5_9|Sunflower|ひまわり|해바라기|向日葵|0
st_5_10|Tulip|チューリップ|튤립|鬱金香|0
st_5_11|Daisy|デイジー|데이지|雛菊|0
st_5_12|Cactus|サボテン|선인장|仙人掌|1
st_5_13|Flytrap|ハエトリグサ|파리지옥|捕蠅草|1
st_5_14|Dandelion|タンポポ|민들레|蒲公英|1
st_5_15|Rose|バラ|장미|玫瑰|2
st_5_16|Mushroom|キノコ|버섯|蘑菇|2
st_5_17|Bonsai|盆栽|분재|盆栽|2
st_5_18|Shovel|シャベル|삽|鏟子|0
st_5_19|Rake|くまで|갈퀴|耙子|0
st_5_20|Wheelbarrow|一輪車|외바퀴 손수레|手推車|0
st_5_21|Boot|長ぐつ|장화|雨靴|1
st_5_22|Compost Bin|たい肥箱|퇴비통|堆肥桶|1
st_5_23|Scarecrow|かかし|허수아비|稻草人|1
st_5_24|Seed Packet|種の袋|씨앗 봉투|種子包|2
st_5_25|Flowerpot|植木鉢|화분|花盆|2
st_5_26|Garden Gnome|庭のこびと|정원 난쟁이|花園小矮人|2
st_5_27|Strawberry|いちご|딸기|草莓|0
st_5_28|Tomato|トマト|토마토|番茄|0
st_5_29|Carrot|にんじん|당근|胡蘿蔔|0
st_5_30|Eggplant|なす|가지|茄子|1
st_5_31|Onion|たまねぎ|양파|洋蔥|1
st_5_32|Pumpkin|かぼちゃ|호박|南瓜|1
st_5_33|Corn|とうもろこし|옥수수|玉米|2
st_5_34|Pea Pod|えんどう豆|완두콩|豌豆莢|2
st_5_35|Watermelon|すいか|수박|西瓜|2
st_5_36|Frog|カエル|개구리|青蛙|0
st_5_37|Lily Pad|ハスの葉|연잎|荷葉|0
st_5_38|Koi|コイ|잉어|鯉魚|0
st_5_39|Tadpole|オタマジャクシ|올챙이|蝌蚪|1
st_5_40|Log|丸太|통나무|木頭|1
st_5_41|Duck|アヒル|오리|鴨子|1
st_5_42|Pond Snail|タニシ|우렁이|田螺|2
st_5_43|Dragonfly|トンボ|잠자리|蜻蜓|2
st_5_44|Pond Rock|池の石|연못 돌|池塘石頭|2
st_5_45|Sparrow|スズメ|참새|麻雀|0
st_5_46|Squirrel|リス|다람쥐|松鼠|0
st_5_47|Rabbit|ウサギ|토끼|兔子|0
st_5_48|Mole|モグラ|두더지|鼴鼠|1
st_5_49|Crow|カラス|까마귀|烏鴉|1
st_5_50|Hedgehog|ハリネズミ|고슴도치|刺蝟|1
st_5_51|Owl|フクロウ|부엉이|貓頭鷹|2
st_5_52|Worm|ミミズ|지렁이|蚯蚓|2
st_5_53|Nest|鳥の巣|새 둥지|鳥巢|2
st_6_0|Test Tube Rack|試験管立て|시험관대|試管架|0
st_6_1|Pipette|スポイト|스포이트|滴管|0
st_6_2|Petri Dish|シャーレ|페트리 접시|培養皿|0
st_6_3|Flask|フラスコ|플라스크|燒瓶|1
st_6_4|Burner|バーナー|버너|本生燈|1
st_6_5|Goggles|保護ゴーグル|보안경|護目鏡|1
st_6_6|Measuring Cylinder|メスシリンダー|눈금실린더|量筒|2
st_6_7|Funnel|ろうと|깔때기|漏斗|2
st_6_8|Thermometer|温度計|온도계|溫度計|2
st_6_9|Chip|チップ|칩|晶片|0
st_6_10|Floppy Disk|フロッピー|플로피 디스크|磁碟片|0
st_6_11|Hard Drive|ハードディスク|하드 디스크|硬碟|0
st_6_12|Circuit Board|基板|회로 기판|電路板|1
st_6_13|Server|サーバー|서버|伺服器|1
st_6_14|Monitor|モニター|모니터|螢幕|1
st_6_15|Router|ルーター|공유기|路由器|2
st_6_16|Printer|プリンター|프린터|印表機|2
st_6_17|Robot Vacuum|ロボット掃除機|로봇 청소기|掃地機器人|2
st_6_18|Cube|立方体|정육면체|立方體|0
st_6_19|Pyramid|ピラミッド|피라미드|金字塔|0
st_6_20|Sphere|球|구|球體|0
st_6_21|Abacus|そろばん|주판|算盤|1
st_6_22|Protractor|分度器|각도기|量角器|1
st_6_23|Compass|コンパス|컴퍼스|圓規|1
st_6_24|Dice|サイコロ|주사위|骰子|2
st_6_25|Puzzle Piece|パズルのピース|퍼즐 조각|拼圖片|2
st_6_26|Magnifying Glass|虫めがね|돋보기|放大鏡|2
st_6_27|Amoeba|アメーバ|아메바|變形蟲|0
st_6_28|Bacteria|細菌|세균|細菌|0
st_6_29|DNA|DNA|DNA|DNA|0
st_6_30|Virus|ウイルス|바이러스|病毒|1
st_6_31|Germ|ばい菌|병균|病菌|1
st_6_32|Cell|細胞|세포|細胞|1
st_6_33|Plankton|プランクトン|플랑크톤|浮游生物|2
st_6_34|Water Bear|クマムシ|물곰|水熊蟲|2
st_6_35|Jellyfish|クラゲ|해파리|水母|2
st_6_36|Spring|ばね|스프링|彈簧|0
st_6_37|Gearbox|ギアボックス|기어박스|齒輪箱|0
st_6_38|Wrench|スパナ|스패너|扳手|0
st_6_39|Screw|ねじ|나사|螺絲|1
st_6_40|Hammer|かなづち|망치|鐵鎚|1
st_6_41|Bolt|ボルト|볼트|螺栓|1
st_6_42|Drill|ドリル|드릴|電鑽|2
st_6_43|Pulley|滑車|도르래|滑輪|2
st_6_44|Piston|ピストン|피스톤|活塞|2
st_6_45|Atom|原子|원자|原子|0
st_6_46|Crystal|結晶|결정|結晶|0
st_6_47|Molecule|分子|분자|分子|0
st_6_48|Toxic Barrel|有毒ドラム缶|유독 드럼통|有毒桶|1
st_6_49|Element Tile|元素カード|원소 카드|元素卡|1
st_6_50|Lava Lamp|ラバランプ|라바 램프|熔岩燈|1
st_6_51|Prism|プリズム|프리즘|稜鏡|2
st_6_52|Tesla Coil|テスラコイル|테슬라 코일|特斯拉線圈|2
st_6_53|Beaker Bot|ビーカーロボ|비커 로봇|燒杯機器人|2
st_7_0|Torch|たいまつ|횃불|火把|0
st_7_1|Shield|盾|방패|盾牌|0
st_7_2|Banner|城の旗|성 깃발|城堡旗幟|0
st_7_3|Goblet|さかずき|술잔|高腳杯|1
st_7_4|Cannon|大砲|대포|大砲|1
st_7_5|Dungeon Key|地下牢のかぎ|지하 감옥 열쇠|地牢鑰匙|1
st_7_6|Treasure Chest|宝箱|보물 상자|寶箱|2
st_7_7|Throne|王座|왕좌|王座|2
st_7_8|Armor Boots|よろいのブーツ|갑옷 부츠|盔甲靴|2
st_7_9|Potion|ポーション|물약|藥水|0
st_7_10|Crystal Ball|水晶玉|수정 구슬|水晶球|0
st_7_11|Broom|ほうき|빗자루|掃帚|0
st_7_12|Scroll|巻物|두루마리|卷軸|1
st_7_13|Cauldron|大なべ|가마솥|大鍋|1
st_7_14|Candle|ろうそく|양초|蠟燭|1
st_7_15|Wizard Hat|魔法使いの帽子|마법사 모자|巫師帽|2
st_7_16|Magic Mirror|魔法の鏡|마법 거울|魔鏡|2
st_7_17|Skull Lantern|どくろランタン|해골 랜턴|骷髏燈|2
sd_1_e_0|Marshmallow|マシュマロ|마시멜로|棉花糖|0
sd_1_e_1|Pudding|プリン|푸딩|布丁|0
sd_1_e_2|Cotton Ball|わた|솜뭉치|棉球|0
sd_1_e_3|Soap Bubble|シャボン玉|비눗방울|肥皂泡|0
sd_1_e_4|Mitten|ミトン|벙어리장갑|連指手套|0
sd_1_e_5|Teddy Bear|テディベア|테디베어|泰迪熊|0
sd_1_e_6|Beanie|ニット帽|비니|毛線帽|0
sd_1_e_7|Dumpling|だんご|경단|糯米糰子|0
sd_1_e_8|Muffin|マフィン|머핀|瑪芬|0
sd_1_e_9|Sticker|シール|스티커|貼紙|0
sd_1_e_10|Lollipop|ペロペロキャンディ|막대사탕|棒棒糖|0
sd_1_e_11|Gummy Candy|グミ|젤리|軟糖|0
sd_1_e_12|Hand Warmer|カイロ|핫팩|暖暖包|0
sd_1_e_13|Nightlight|常夜灯|수면등|小夜燈|0
sd_1_e_14|Bib|よだれかけ|턱받이|圍兜|0
sd_1_e_15|Rattle|ガラガラ|딸랑이|搖鈴|0
sd_1_e_16|Building Block|つみき|블록|積木|0
sd_1_e_17|Picture Book|絵本|그림책|繪本|0
sd_1_e_18|Ball of Yarn|毛糸玉|털실 뭉치|毛線球|0
sd_1_e_19|Jelly Bean|ジェリービーンズ|젤리빈|雷根糖|0
sd_1_e_20|Doughnut|ドーナツ|도넛|甜甜圈|0
sd_1_e_21|Egg|たまご|달걀|蛋|0
sd_1_e_22|Tangerine|みかん|귤|橘子|0
sd_1_e_23|Snowball|雪玉|눈뭉치|雪球|0
sd_1_e_24|Cushion|クッション|쿠션|靠墊|0
sd_1_e_25|Piggy Bank|ブタの貯金箱|돼지 저금통|小豬撲滿|0
sd_1_e_26|Rubber Ball|ゴムボール|고무공|橡膠球|0
sd_1_n_0|Tricycle|三輪車|세발자전거|三輪車|0
sd_1_n_1|Bicycle|自転車|자전거|腳踏車|0
sd_1_n_2|Taxi|タクシー|택시|計程車|0
sd_1_n_3|Drain|排水口|배수구|排水孔|1
sd_1_n_4|Puddle|水たまり|물웅덩이|水窪|1
sd_1_n_5|Telephone Pole|電柱|전봇대|電線桿|1
sd_1_n_6|Doormat|玄関マット|현관 매트|門墊|2
sd_1_n_7|Calendar|カレンダー|달력|月曆|2
sd_1_n_8|Mug|マグカップ|머그컵|馬克杯|2
sd_1_n_9|Spoon|スプーン|숟가락|湯匙|0
sd_1_n_10|Fork|フォーク|포크|叉子|0
sd_1_n_11|Ketchup|ケチャップ|케첩|番茄醬|0
sd_1_n_12|Mayonnaise|マヨネーズ|마요네즈|美乃滋|1
sd_1_n_13|Notebook|ノート|공책|筆記本|1
sd_1_n_14|Stapler|ホッチキス|스테이플러|釘書機|1
sd_1_n_15|Thumbtack|画びょう|압정|圖釘|2
sd_1_n_16|Chalk|チョーク|분필|粉筆|2
sd_1_n_17|Blackboard|黒板|칠판|黑板|2
sd_1_n_18|School Desk|学校の机|책상|課桌|0
sd_1_n_19|Lunch Tray|給食トレー|급식판|餐盤|0
sd_1_n_20|Wallet|さいふ|지갑|錢包|0
sd_1_n_21|House Key|家のかぎ|집 열쇠|家門鑰匙|1
sd_1_n_22|Dirty Laundry|洗濯物の山|빨래 더미|髒衣服堆|1
sd_1_n_23|Flashlight|懐中電灯|손전등|手電筒|1
sd_1_n_24|Electric Fan|扇風機|선풍기|電風扇|2
sd_1_n_25|Air Conditioner|エアコン|에어컨|冷氣機|2
sd_1_n_26|Sticky Note|ふせん|포스트잇|便利貼|2
sd_1_h_0|Bulldozer|ブルドーザー|불도저|推土機|3
sd_1_h_1|Dump Truck|ダンプカー|덤프트럭|砂石車|3
sd_1_h_2|Fire Engine|消防車|소방차|消防車|3
sd_1_h_3|Garbage Truck|ゴミ収集車|쓰레기차|垃圾車|3
sd_1_h_4|Excavator|ショベルカー|굴착기|挖土機|3
sd_1_h_5|Crane|クレーン|크레인|起重機|3
sd_1_h_6|Jackhammer|削岩機|착암기|鑽地機|3
sd_1_h_7|Chainsaw|チェーンソー|전기톱|鏈鋸|3
sd_1_h_8|Pressure Cooker|圧力なべ|압력솥|壓力鍋|3
sd_1_h_9|Blender|ミキサー|믹서기|果汁機|3
sd_1_h_10|Microwave|電子レンジ|전자레인지|微波爐|3
sd_1_h_11|Lawn Mower|芝刈り機|잔디깎기|割草機|3
sd_1_h_12|Paper Shredder|シュレッダー|문서 세단기|碎紙機|3
sd_1_h_13|Thundercloud|雷雲|먹구름|雷雲|3
sd_1_h_14|Typhoon|台風|태풍|颱風|3
sd_1_h_15|Snowplow|除雪車|제설차|剷雪車|3
sd_1_h_16|Tow Truck|レッカー車|견인차|拖吊車|3
sd_1_h_17|Concrete Mixer|ミキサー車|레미콘|水泥車|3
sd_1_h_18|Iron Gate|鉄の門|철문|鐵門|3
sd_1_h_19|Padlock|南京錠|자물쇠|掛鎖|3
sd_1_h_20|Guard Dog|番犬|경비견|看門狗|3
sd_1_h_21|Siren|サイレン|사이렌|警笛|3
sd_1_h_22|Exam Paper|テスト用紙|시험지|考卷|3
sd_1_h_23|Report Card|通知表|성적표|成績單|3
sd_1_h_24|School Bell|チャイム|학교 종|上課鐘|3
sd_1_h_25|Fire Alarm|火災報知器|화재경보기|火災警報器|3
sd_1_h_26|Wrecking Ball|解体用の鉄球|철거용 쇠공|拆除鐵球|3
sd_2_e_0|Pixel|ピクセル|픽셀|像素|0
sd_2_e_1|Emoji|絵文字|이모지|表情符號|0
sd_2_e_2|Mini Robot|ミニロボ|미니 로봇|迷你機器人|0
sd_2_e_3|Smart Speaker|スマートスピーカー|스마트 스피커|智慧音箱|0
sd_2_e_4|Heart Icon|ハートアイコン|하트 아이콘|愛心圖示|0
sd_2_e_5|Wi-Fi Signal|Wi-Fiマーク|와이파이 신호|Wi-Fi訊號|0
sd_2_e_6|Like Button|いいねボタン|좋아요 버튼|按讚鍵|0
sd_2_e_7|Cursor|カーソル|커서|游標|0
sd_2_e_8|Notification Bell|通知ベル|알림 종|通知鈴|0
sd_2_e_9|Toy Rocket|おもちゃのロケット|장난감 로켓|玩具火箭|0
sd_2_e_10|Robot Cat|ロボネコ|로봇 고양이|機器貓|0
sd_2_e_11|Glow Stick|ペンライト|야광봉|螢光棒|0
sd_2_e_12|Digital Pet|デジタルペット|디지털 펫|電子寵物|0
sd_2_e_13|Game Cartridge|ゲームカセット|게임 카트리지|遊戲卡帶|0
sd_2_e_14|Joystick|ジョイスティック|조이스틱|搖桿|0
sd_2_e_15|LED Bulb|LED電球|LED 전구|LED燈泡|0
sd_2_e_16|Phone Case|スマホケース|휴대폰 케이스|手機殼|0
sd_2_e_17|Selfie Stick|自撮り棒|셀카봉|自拍棒|0
sd_2_e_18|Power Bank|モバイルバッテリー|보조배터리|行動電源|0
sd_2_e_19|Comet|すい星|혜성|彗星|0
sd_2_e_20|Little Star|小さな星|작은 별|小星星|0
sd_2_e_21|Alien Baby|宇宙人の赤ちゃん|아기 외계인|外星寶寶|0
sd_2_e_22|Space Food|宇宙食|우주식|太空食物|0
sd_2_e_23|Smiley Face|スマイル|스마일|笑臉|0
sd_2_e_24|Download Arrow|ダウンロード矢印|다운로드 화살표|下載箭頭|0
sd_2_e_25|Folder|フォルダ|폴더|資料夾|0
sd_2_e_26|Save Button|保存ボタン|저장 버튼|儲存鍵|0
sd_2_n_0|E-reader|電子書籍リーダー|전자책 단말기|電子書閱讀器|0
sd_2_n_1|Laptop|ノートパソコン|노트북|筆電|0
sd_2_n_2|Headphones|ヘッドホン|헤드폰|耳機|0
sd_2_n_3|Speaker|スピーカー|스피커|喇叭|1
sd_2_n_4|Scanner|スキャナー|스캐너|掃描器|1
sd_2_n_5|Projector|プロジェクター|프로젝터|投影機|1
sd_2_n_6|Graphics Card|グラフィックボード|그래픽 카드|顯示卡|2
sd_2_n_7|Digital Clock|デジタル時計|디지털 시계|電子鐘|2
sd_2_n_8|SIM Card|SIMカード|유심|SIM卡|2
sd_2_n_9|Memory Card|メモリーカード|메모리 카드|記憶卡|0
sd_2_n_10|Stylus|タッチペン|터치펜|觸控筆|0
sd_2_n_11|Barcode|バーコード|바코드|條碼|0
sd_2_n_12|Robot Waiter|配膳ロボ|서빙 로봇|送餐機器人|1
sd_2_n_13|Self-Driving Car|自動運転車|자율주행차|自駕車|1
sd_2_n_14|Maglev Train|リニア|자기부상열차|磁浮列車|1
sd_2_n_15|Spaceship|宇宙船|우주선|太空船|2
sd_2_n_16|Space Station|宇宙ステーション|우주정거장|太空站|2
sd_2_n_17|Rover|探査車|탐사차|探測車|2
sd_2_n_18|Meteor|流れ星|유성|流星|0
sd_2_n_19|Radar|レーダー|레이더|雷達|0
sd_2_n_20|Smart Glasses|スマートグラス|스마트 안경|智慧眼鏡|0
sd_2_n_21|Spam Mail|迷惑メール|스팸 메일|垃圾郵件|1
sd_2_n_22|Pop-up Ad|ポップアップ広告|팝업 광고|彈出廣告|1
sd_2_n_23|Computer Bug|バグ|버그|程式錯誤|1
sd_2_n_24|Tangled Wire|からまった線|엉킨 전선|纏繞的電線|2
sd_2_n_25|Smart Lock|スマートロック|스마트 도어락|智慧門鎖|2
sd_2_n_26|Robot Chef|ロボットシェフ|로봇 요리사|機器人廚師|2
sd_2_h_0|Giant Robot|巨大ロボ|거대 로봇|巨型機器人|3
sd_2_h_1|Battle Drone|戦闘ドローン|전투 드론|戰鬥無人機|3
sd_2_h_2|Laser Cannon|レーザー砲|레이저포|雷射砲|3
sd_2_h_3|Computer Virus|コンピューターウイルス|컴퓨터 바이러스|電腦病毒|3
sd_2_h_4|Firewall|ファイアウォール|방화벽|防火牆|3
sd_2_h_5|Hacker Bot|ハッカーボット|해커 봇|駭客機器人|3
sd_2_h_6|Black Hole|ブラックホール|블랙홀|黑洞|3
sd_2_h_7|Supernova|超新星|초신성|超新星|3
sd_2_h_8|Mothership|宇宙人の母艦|외계 모선|外星母艦|3
sd_2_h_9|Robot Tank|ロボット戦車|로봇 탱크|機器人坦克|3
sd_2_h_10|Plasma Ball|プラズマボール|플라스마 볼|電漿球|3
sd_2_h_11|Power Plant|発電所|발전소|發電廠|3
sd_2_h_12|Generator|発電機|발전기|發電機|3
sd_2_h_13|Electromagnet|電磁石|전자석|電磁鐵|3
sd_2_h_14|Rocket Booster|ロケットブースター|로켓 부스터|火箭推進器|3
sd_2_h_15|Space Junk|宇宙ゴミ|우주 쓰레기|太空垃圾|3
sd_2_h_16|Cyborg|サイボーグ|사이보그|生化人|3
sd_2_h_17|Supercomputer|スーパーコンピューター|슈퍼컴퓨터|超級電腦|3
sd_2_h_18|Glitch|グリッチ|글리치|故障畫面|3
sd_2_h_19|Blue Screen|ブルースクリーン|블루스크린|藍屏|3
sd_2_h_20|Overheating Phone|熱くなったスマホ|과열된 휴대폰|過熱手機|3
sd_2_h_21|Power Surge|過電流|전력 서지|電湧|3
sd_2_h_22|Solar Flare|太陽フレア|태양 플레어|太陽閃焰|3
sd_2_h_23|Laser Gate|レーザーゲート|레이저 게이트|雷射門|3
sd_2_h_24|Security Robot|警備ロボ|경비 로봇|保全機器人|3
sd_2_h_25|Space Pirate Ship|宇宙海賊船|우주 해적선|太空海盜船|3
sd_2_h_26|Magnetic Storm|磁気嵐|자기 폭풍|磁暴|3
sd_3_e_0|Ping-Pong Ball|ピンポン玉|탁구공|乒乓球|0
sd_3_e_1|Bouncy Castle|ふわふわ遊具|에어바운스|充氣城堡|0
sd_3_e_2|Basketball|バスケットボール|농구공|籃球|0
sd_3_e_3|Glow Bracelet|光るブレスレット|야광 팔찌|螢光手環|0
sd_3_e_4|Lucky Cat|招き猫|마네키네코|招財貓|0
sd_3_e_5|Headband|ヘアバンド|헤어밴드|髮帶|0
sd_3_e_6|Wristband|リストバンド|손목 밴드|護腕|0
sd_3_e_7|Cheer Flag|応援旗|응원 깃발|加油旗|0
sd_3_e_8|Popcorn|ポップコーン|팝콘|爆米花|0
sd_3_e_9|Ice Cream Cone|ソフトクリーム|소프트아이스크림|霜淇淋|0
sd_3_e_10|Pinwheel|かざぐるま|바람개비|風車|0
sd_3_e_11|Yo-yo|ヨーヨー|요요|溜溜球|0
sd_3_e_12|Wind Chime|風鈴|풍경|風鈴|0
sd_3_e_13|Daruma|だるま|오뚝이|不倒翁|0
sd_3_e_14|Kendama|けん玉|켄다마|劍玉|0
sd_3_e_15|Harmonica|ハーモニカ|하모니카|口琴|0
sd_3_e_16|Xylophone|木琴|실로폰|木琴|0
sd_3_e_17|Ukulele|ウクレレ|우쿨렐레|烏克麗麗|0
sd_3_e_18|Triangle|トライアングル|트라이앵글|三角鐵|0
sd_3_e_19|Castanets|カスタネット|캐스터네츠|響板|0
sd_3_e_20|Music Box|オルゴール|오르골|音樂盒|0
sd_3_e_21|Party Hat|パーティー帽|파티 모자|派對帽|0
sd_3_e_22|Cupcake|カップケーキ|컵케이크|杯子蛋糕|0
sd_3_e_23|Gift Box|プレゼント箱|선물 상자|禮物盒|0
sd_3_e_24|Sparkler|線香花火|불꽃 막대|仙女棒|0
sd_3_e_25|Beanbag|お手玉|오자미|沙包|0
sd_3_e_26|Hula Hoop|フラフープ|훌라후프|呼拉圈|0
sd_3_n_0|Bowling Ball|ボウリングの球|볼링공|保齡球|0
sd_3_n_1|Baseball Glove|グローブ|야구 글러브|棒球手套|0
sd_3_n_2|Baseball Bat|バット|야구 방망이|球棒|0
sd_3_n_3|Helmet|ヘルメット|헬멧|安全帽|1
sd_3_n_4|Goal Net|ゴールネット|골네트|球門網|1
sd_3_n_5|Basketball Hoop|バスケットゴール|농구 골대|籃框|1
sd_3_n_6|Racket|ラケット|라켓|球拍|2
sd_3_n_7|Skateboard|スケボー|스케이트보드|滑板|2
sd_3_n_8|Surfboard|サーフボード|서핑보드|衝浪板|2
sd_3_n_9|Ski|スキー板|스키|滑雪板|0
sd_3_n_10|Ice Skate|スケート靴|스케이트|溜冰鞋|0
sd_3_n_11|Boxing Glove|ボクシンググローブ|권투 장갑|拳擊手套|0
sd_3_n_12|Sports Drink|スポーツドリンク|스포츠음료|運動飲料|1
sd_3_n_13|Ice Pack|保冷剤|아이스팩|冰袋|1
sd_3_n_14|Bandage|ばんそうこう|반창고|OK繃|1
sd_3_n_15|Mascot Costume|着ぐるみ|인형탈|布偶裝|2
sd_3_n_16|Guitar|ギター|기타|吉他|2
sd_3_n_17|Piano|ピアノ|피아노|鋼琴|2
sd_3_n_18|Saxophone|サックス|색소폰|薩克斯風|0
sd_3_n_19|Harp|ハープ|하프|豎琴|0
sd_3_n_20|Accordion|アコーディオン|아코디언|手風琴|0
sd_3_n_21|Karaoke Machine|カラオケ機|노래방 기계|卡拉OK機|1
sd_3_n_22|Disco Ball|ミラーボール|미러볼|迷幻球|1
sd_3_n_23|Jukebox|ジュークボックス|주크박스|點唱機|1
sd_3_n_24|Festival Float|山車|축제 수레|花車|2
sd_3_n_25|Taiko Drum|和太鼓|일본 북|太鼓|2
sd_3_n_26|Ticket|チケット|티켓|門票|2
sd_3_h_0|Pitching Machine|ピッチングマシン|피칭 머신|投球機|3
sd_3_h_1|Barbell|バーベル|바벨|槓鈴|3
sd_3_h_2|Punching Bag|サンドバッグ|샌드백|沙袋|3
sd_3_h_3|Hurdle|ハードル|허들|跨欄|3
sd_3_h_4|Shot Put|砲丸|투포환|鉛球|3
sd_3_h_5|Treadmill|ランニングマシン|러닝머신|跑步機|3
sd_3_h_6|Sumo Ring|土俵|씨름판|相撲台|3
sd_3_h_7|Racing Car|レーシングカー|경주용 자동차|賽車|3
sd_3_h_8|Motorbike|バイク|오토바이|摩托車|3
sd_3_h_9|Jet Ski|水上バイク|제트스키|水上摩托車|3
sd_3_h_10|Roller Coaster|ジェットコースター|롤러코스터|雲霄飛車|3
sd_3_h_11|Ferris Wheel|観覧車|대관람차|摩天輪|3
sd_3_h_12|Haunted House|お化け屋敷|귀신의 집|鬼屋|3
sd_3_h_13|Drop Tower|フリーフォール|자이로드롭|自由落體|3
sd_3_h_14|Dragon Dance|龍の舞|용춤|舞龍|3
sd_3_h_15|Giant Firework|大玉花火|대형 불꽃|大型煙火|3
sd_3_h_16|Bass Drum|大太鼓|큰북|大鼓|3
sd_3_h_17|Electric Guitar|エレキギター|일렉 기타|電吉他|3
sd_3_h_18|Pipe Organ|パイプオルガン|파이프 오르간|管風琴|3
sd_3_h_19|Amplifier|アンプ|앰프|擴大機|3
sd_3_h_20|Gong|ドラ|징|鑼|3
sd_3_h_21|Bagpipe|バグパイプ|백파이프|風笛|3
sd_3_h_22|Conductor's Baton|指揮棒|지휘봉|指揮棒|3
sd_3_h_23|Grand Piano|グランドピアノ|그랜드 피아노|平台鋼琴|3
sd_3_h_24|Stadium|スタジアム|경기장|體育場|3
sd_3_h_25|Red Card|レッドカード|레드카드|紅牌|3
sd_3_h_26|Championship Belt|チャンピオンベルト|챔피언 벨트|冠軍腰帶|3
sd_4_e_0|Bath Bomb|バスボム|배스밤|沐浴球|0
sd_4_e_1|Loofah|ボディスポンジ|샤워볼|浴花|0
sd_4_e_2|Cotton Swab|綿棒|면봉|棉花棒|0
sd_4_e_3|Bathrobe|バスローブ|목욕 가운|浴袍|0
sd_4_e_4|Shower Cap|シャワーキャップ|샤워캡|浴帽|0
sd_4_e_5|Sleep Mask|アイマスク|수면 안대|眼罩|0
sd_4_e_6|Room Key|ルームキー|객실 키|房卡|0
sd_4_e_7|Mint Candy|ミントキャンディ|박하사탕|薄荷糖|0
sd_4_e_8|Teabag|ティーバッグ|티백|茶包|0
sd_4_e_9|Sugar Cube|角砂糖|각설탕|方糖|0
sd_4_e_10|Macaron|マカロン|마카롱|馬卡龍|0
sd_4_e_11|Cream Puff|シュークリーム|슈크림|泡芙|0
sd_4_e_12|Waffle|ワッフル|와플|格子鬆餅|0
sd_4_e_13|Seashell|貝がら|조개껍데기|貝殼|0
sd_4_e_14|Starfish|ヒトデ|불가사리|海星|0
sd_4_e_15|Sandcastle|砂の城|모래성|沙堡|0
sd_4_e_16|Straw Hat|麦わら帽子|밀짚모자|草帽|0
sd_4_e_17|Snow Globe|スノードーム|스노볼|雪花球|0
sd_4_e_18|Postcard|絵はがき|엽서|明信片|0
sd_4_e_19|Keychain|キーホルダー|열쇠고리|鑰匙圈|0
sd_4_e_20|Hot Spring Egg|温泉たまご|온천 달걀|溫泉蛋|0
sd_4_e_21|Wash Bucket|湯おけ|목욕 바가지|澡盆|0
sd_4_e_22|Coconut|ココナッツ|코코넛|椰子|0
sd_4_e_23|Tropical Drink|トロピカルドリンク|열대 음료|熱帶飲料|0
sd_4_e_24|Hammock|ハンモック|해먹|吊床|0
sd_4_e_25|Seagull|カモメ|갈매기|海鷗|0
sd_4_e_26|Lip Balm|リップクリーム|립밤|護唇膏|0
sd_4_n_0|Suitcase|スーツケース|여행 가방|行李箱|0
sd_4_n_1|Ice Bucket|アイスペール|얼음 통|冰桶|0
sd_4_n_2|Minibar|ミニバー|미니바|迷你吧|0
sd_4_n_3|Plunger|ラバーカップ|뚫어뻥|馬桶吸盤|1
sd_4_n_4|Hairball|髪の毛のかたまり|머리카락 뭉치|毛髮團|1
sd_4_n_5|Toilet|トイレ|변기|馬桶|1
sd_4_n_6|King-Size Bed|キングベッド|킹사이즈 침대|特大床|2
sd_4_n_7|Coat Rack|コートかけ|옷걸이 스탠드|衣帽架|2
sd_4_n_8|Room Service Cart|ルームサービスワゴン|룸서비스 카트|客房服務推車|2
sd_4_n_9|Spaghetti|スパゲッティ|스파게티|義大利麵|0
sd_4_n_10|Pizza|ピザ|피자|披薩|0
sd_4_n_11|Hamburger|ハンバーガー|햄버거|漢堡|0
sd_4_n_12|Moldy Bread|カビたパン|곰팡이 핀 빵|發霉麵包|1
sd_4_n_13|Dirty Dishes|汚れたお皿|더러운 접시|髒盤子|1
sd_4_n_14|Hot Dog|ホットドッグ|핫도그|熱狗|1
sd_4_n_15|Menu|メニュー|메뉴|菜單|2
sd_4_n_16|Salt Shaker|塩入れ|소금통|鹽罐|2
sd_4_n_17|Pepper Mill|ペッパーミル|후추 그라인더|胡椒研磨器|2
sd_4_n_18|Rubber Boat|ゴムボート|고무보트|橡皮艇|0
sd_4_n_19|Life Jacket|救命胴衣|구명조끼|救生衣|0
sd_4_n_20|Ice Pop|アイスキャンディー|아이스바|冰棒|0
sd_4_n_21|Seaweed|海藻|해초|海藻|1
sd_4_n_22|Sea Cucumber|ナマコ|해삼|海參|1
sd_4_n_23|Crab|カニ|게|螃蟹|1
sd_4_n_24|Cooler Box|クーラーボックス|아이스박스|保冷箱|2
sd_4_n_25|Diving Board|飛び込み台|다이빙대|跳水板|2
sd_4_n_26|Soup Bowl|スープ皿|수프 그릇|湯碗|2
sd_4_h_0|Shark|サメ|상어|鯊魚|3
sd_4_h_1|Octopus|タコ|문어|章魚|3
sd_4_h_2|Giant Squid|ダイオウイカ|대왕오징어|大王魷魚|3
sd_4_h_3|Whirlpool|うず潮|소용돌이|漩渦|3
sd_4_h_4|Giant Wave|大波|큰 파도|巨浪|3
sd_4_h_5|Pirate Ship|海賊船|해적선|海盜船|3
sd_4_h_6|Anchor|いかり|닻|船錨|3
sd_4_h_7|Cruise Ship|豪華客船|크루즈선|郵輪|3
sd_4_h_8|Lighthouse|灯台|등대|燈塔|3
sd_4_h_9|Cursed Painting|呪いの絵|저주받은 그림|被詛咒的畫|3
sd_4_h_10|Elevator|エレベーター|엘리베이터|電梯|3
sd_4_h_11|Boiler|ボイラー|보일러|鍋爐|3
sd_4_h_12|Sauna Stove|サウナストーブ|사우나 난로|桑拿爐|3
sd_4_h_13|Jacuzzi|ジャグジー|자쿠지|按摩浴缸|3
sd_4_h_14|Hot Spring|温泉|온천|溫泉|3
sd_4_h_15|Water Slide|ウォータースライダー|워터슬라이드|滑水道|3
sd_4_h_16|Speedboat|モーターボート|모터보트|快艇|3
sd_4_h_17|Golden Key|金のかぎ|황금 열쇠|金鑰匙|3
sd_4_h_18|Vault Door|金庫の扉|금고 문|金庫門|3
sd_4_h_19|Giant Wok|大きな中華なべ|큰 웍|大炒鍋|3
sd_4_h_20|Lobster|ロブスター|랍스터|龍蝦|3
sd_4_h_21|Pufferfish|フグ|복어|河豚|3
sd_4_h_22|Moray Eel|ウツボ|곰치|鯙|3
sd_4_h_23|Sea Serpent|海ヘビ|바다뱀|海蛇|3
sd_4_h_24|Hurricane|ハリケーン|허리케인|颶風|3
sd_4_h_25|Volcanic Island|火山島|화산섬|火山島|3
sd_4_h_26|Ghost Ship|幽霊船|유령선|幽靈船|3
sd_5_e_0|Clover|クローバー|클로버|幸運草|0
sd_5_e_1|Acorn|どんぐり|도토리|橡實|0
sd_5_e_2|Pinecone|まつぼっくり|솔방울|松果|0
sd_5_e_3|Chick|ひよこ|병아리|小雞|0
sd_5_e_4|Hamster|ハムスター|햄스터|倉鼠|0
sd_5_e_5|Kitten|子ねこ|아기 고양이|小貓|0
sd_5_e_6|Puppy|子犬|강아지|小狗|0
sd_5_e_7|Lamb|子ひつじ|새끼 양|小羊|0
sd_5_e_8|Duckling|子ガモ|새끼 오리|小鴨|0
sd_5_e_9|Chipmunk|シマリス|줄무늬다람쥐|花栗鼠|0
sd_5_e_10|Hummingbird|ハチドリ|벌새|蜂鳥|0
sd_5_e_11|Firefly|ホタル|반딧불이|螢火蟲|0
sd_5_e_12|Cherry|さくらんぼ|체리|櫻桃|0
sd_5_e_13|Peach|もも|복숭아|桃子|0
sd_5_e_14|Apple|りんご|사과|蘋果|0
sd_5_e_15|Blueberry|ブルーベリー|블루베리|藍莓|0
sd_5_e_16|Grape|ぶどう|포도|葡萄|0
sd_5_e_17|Seedling|芽|새싹|嫩芽|0
sd_5_e_18|Cherry Blossom|桜|벚꽃|櫻花|0
sd_5_e_19|Morning Glory|アサガオ|나팔꽃|牽牛花|0
sd_5_e_20|Lavender|ラベンダー|라벤더|薰衣草|0
sd_5_e_21|Dewdrop|しずく|이슬방울|露珠|0
sd_5_e_22|Rainbow|にじ|무지개|彩虹|0
sd_5_e_23|Butterfly Net|虫とり網|잠자리채|捕蟲網|0
sd_5_e_24|Birdhouse|巣箱|새집|鳥屋|0
sd_5_e_25|Panda Cub|子パンダ|아기 판다|熊貓寶寶|0
sd_5_e_26|Koala|コアラ|코알라|無尾熊|0
sd_5_n_0|Ant|アリ|개미|螞蟻|0
sd_5_n_1|Grasshopper|バッタ|메뚜기|蚱蜢|0
sd_5_n_2|Cicada|セミ|매미|蟬|0
sd_5_n_3|Cockroach|ゴキブリ|바퀴벌레|蟑螂|1
sd_5_n_4|Slug|ナメクジ|민달팽이|蛞蝓|1
sd_5_n_5|Fly|ハエ|파리|蒼蠅|1
sd_5_n_6|Moth|ガ|나방|蛾|2
sd_5_n_7|Stag Beetle|クワガタ|사슴벌레|鍬形蟲|2
sd_5_n_8|Centipede|ムカデ|지네|蜈蚣|2
sd_5_n_9|Lemon|レモン|레몬|檸檬|0
sd_5_n_10|Banana|バナナ|바나나|香蕉|0
sd_5_n_11|Pineapple|パイナップル|파인애플|鳳梨|0
sd_5_n_12|Rotten Apple|腐ったりんご|썩은 사과|爛蘋果|1
sd_5_n_13|Natto|納豆|낫토|納豆|1
sd_5_n_14|Durian|ドリアン|두리안|榴槤|1
sd_5_n_15|Green Pepper|ピーマン|피망|青椒|2
sd_5_n_16|Broccoli|ブロッコリー|브로콜리|花椰菜|2
sd_5_n_17|Garlic|にんにく|마늘|大蒜|2
sd_5_n_18|Turtle|カメ|거북|烏龜|0
sd_5_n_19|Fox|キツネ|여우|狐狸|0
sd_5_n_20|Deer|シカ|사슴|鹿|0
sd_5_n_21|Toad|ヒキガエル|두꺼비|蟾蜍|1
sd_5_n_22|Bat|コウモリ|박쥐|蝙蝠|1
sd_5_n_23|Raccoon|アライグマ|너구리|浣熊|1
sd_5_n_24|Lizard|トカゲ|도마뱀|蜥蜴|2
sd_5_n_25|Hermit Crab|ヤドカリ|소라게|寄居蟹|2
sd_5_n_26|Weasel|イタチ|족제비|黃鼠狼|2
sd_5_h_0|Hornet|スズメバチ|말벌|虎頭蜂|3
sd_5_h_1|Scorpion|サソリ|전갈|蠍子|3
sd_5_h_2|Tarantula|タランチュラ|타란툴라|狼蛛|3
sd_5_h_3|Rhinoceros Beetle|カブトムシ|장수풍뎅이|獨角仙|3
sd_5_h_4|Poison Ivy|ツタウルシ|덩굴옻나무|毒藤|3
sd_5_h_5|Thorn Bush|いばら|가시덤불|荊棘叢|3
sd_5_h_6|Pitcher Plant|ウツボカズラ|벌레잡이통풀|豬籠草|3
sd_5_h_7|Poison Mushroom|毒キノコ|독버섯|毒菇|3
sd_5_h_8|Jack-o'-lantern|ジャック・オ・ランタン|잭오랜턴|南瓜燈|3
sd_5_h_9|Bear|クマ|곰|熊|3
sd_5_h_10|Wolf|オオカミ|늑대|狼|3
sd_5_h_11|Wild Boar|イノシシ|멧돼지|野豬|3
sd_5_h_12|Eagle|ワシ|독수리|老鷹|3
sd_5_h_13|Hyena|ハイエナ|하이에나|鬣狗|3
sd_5_h_14|Crocodile|ワニ|악어|鱷魚|3
sd_5_h_15|Gorilla|ゴリラ|고릴라|大猩猩|3
sd_5_h_16|Rhino|サイ|코뿔소|犀牛|3
sd_5_h_17|Lion|ライオン|사자|獅子|3
sd_5_h_18|Tornado|竜巻|토네이도|龍捲風|3
sd_5_h_19|Wildfire|山火事|산불|野火|3
sd_5_h_20|Avalanche|なだれ|눈사태|雪崩|3
sd_5_h_21|Quicksand|流砂|모래 늪|流沙|3
sd_5_h_22|Dead Tree|枯れ木|고목|枯樹|3
sd_5_h_23|Swamp|沼|늪|沼澤|3
sd_5_h_24|Vulture|ハゲワシ|대머리독수리|禿鷹|3
sd_5_h_25|Piranha|ピラニア|피라냐|食人魚|3
sd_5_h_26|Leech|ヒル|거머리|水蛭|3
sd_6_e_0|Paper Clip|クリップ|클립|迴紋針|0
sd_6_e_1|Bubble Wand|シャボン玉の輪|비눗방울 막대|泡泡棒|0
sd_6_e_2|Marble|ビー玉|구슬|彈珠|0
sd_6_e_3|Snowflake|雪の結晶|눈송이|雪花|0
sd_6_e_4|Kaleidoscope|万華鏡|만화경|萬花筒|0
sd_6_e_5|Lucky Seven|ラッキーセブン|행운의 7|幸運7|0
sd_6_e_6|Plus Sign|プラス記号|더하기 기호|加號|0
sd_6_e_7|Zero|ゼロ|영|零|0
sd_6_e_8|Pi|円周率|원주율|圓周率|0
sd_6_e_9|Equal Sign|イコール|등호|等號|0
sd_6_e_10|Raindrop|雨つぶ|빗방울|雨滴|0
sd_6_e_11|Ice Cube|氷|얼음|冰塊|0
sd_6_e_12|Pebble|小石|조약돌|小石子|0
sd_6_e_13|Feather|羽根|깃털|羽毛|0
sd_6_e_14|Lens|レンズ|렌즈|鏡片|0
sd_6_e_15|Stardust|星くず|별가루|星塵|0
sd_6_e_16|Spark|火花|불꽃|火花|0
sd_6_e_17|Paper Cup Phone|糸電話|실 전화기|傳聲筒|0
sd_6_e_18|Hourglass|砂時計|모래시계|沙漏|0
sd_6_e_19|Paper Crane|折り鶴|종이학|紙鶴|0
sd_6_e_20|Spinning Top|こま|팽이|陀螺|0
sd_6_e_21|Electron|電子|전자|電子|0
sd_6_e_22|Photon|光子|광자|光子|0
sd_6_e_23|Yeast|酵母|효모|酵母|0
sd_6_e_24|Moss|コケ|이끼|苔蘚|0
sd_6_e_25|Bouncy Ball|スーパーボール|탱탱볼|彈力球|0
sd_6_e_26|Slime|スライム|슬라임|史萊姆|0
sd_6_n_0|Microscope|顕微鏡|현미경|顯微鏡|0
sd_6_n_1|Litmus Paper|リトマス紙|리트머스 종이|石蕊試紙|0
sd_6_n_2|Lab Coat|白衣|실험 가운|實驗袍|0
sd_6_n_3|Mold|カビ|곰팡이|黴菌|1
sd_6_n_4|Sludge|ヘドロ|오물|汙泥|1
sd_6_n_5|Lab Rat|実験用ネズミ|실험용 쥐|實驗鼠|1
sd_6_n_6|Skeleton Model|骨格模型|골격 모형|骨骼模型|2
sd_6_n_7|Anatomy Model|人体模型|인체 모형|人體模型|2
sd_6_n_8|Brain in a Jar|びんの中の脳|병 속의 뇌|瓶中大腦|2
sd_6_n_9|Graph Paper|方眼紙|모눈종이|方格紙|0
sd_6_n_10|Set Square|三角定規|삼각자|三角尺|0
sd_6_n_11|Cone|円すい|원뿔|圓錐|0
sd_6_n_12|Equation|方程式|방정식|方程式|1
sd_6_n_13|Fraction|分数|분수|分數|1
sd_6_n_14|Square Root|ルート|제곱근|平方根|1
sd_6_n_15|Infinity|無限大|무한대|無限|2
sd_6_n_16|Pentagon|五角形|오각형|五邊形|2
sd_6_n_17|Cylinder|円柱|원기둥|圓柱|2
sd_6_n_18|Globe|地球儀|지구본|地球儀|0
sd_6_n_19|Fossil|化石|화석|化石|0
sd_6_n_20|Volcano Model|火山の模型|화산 모형|火山模型|0
sd_6_n_21|Rusty Nail|さびたくぎ|녹슨 못|生鏽釘子|1
sd_6_n_22|Oil Spill|油もれ|기름 유출|漏油|1
sd_6_n_23|Smog|スモッグ|스모그|霧霾|1
sd_6_n_24|Laser Pointer|レーザーポインター|레이저 포인터|雷射筆|2
sd_6_n_25|Barometer|気圧計|기압계|氣壓計|2
sd_6_n_26|Seismograph|地震計|지진계|地震儀|2
sd_6_h_0|Rogue AI|暴走AI|폭주 AI|失控AI|3
sd_6_h_1|Reactor|原子炉|원자로|反應爐|3
sd_6_h_2|Particle Accelerator|粒子加速器|입자 가속기|粒子加速器|3
sd_6_h_3|Mutant Plant|突然変異植物|돌연변이 식물|突變植物|3
sd_6_h_4|Acid Pool|酸の池|산성 웅덩이|酸池|3
sd_6_h_5|Poison Gas|毒ガス|독가스|毒氣|3
sd_6_h_6|Superbug|耐性菌|슈퍼버그|超級細菌|3
sd_6_h_7|Nanobot|ナノボット|나노봇|奈米機器人|3
sd_6_h_8|Clone|クローン|클론|複製人|3
sd_6_h_9|Meteorite|隕石|운석|隕石|3
sd_6_h_10|Magma|マグマ|마그마|岩漿|3
sd_6_h_11|Earthquake|地震|지진|地震|3
sd_6_h_12|Thunderbolt|雷|벼락|霹靂|3
sd_6_h_13|Blizzard|吹雪|눈보라|暴風雪|3
sd_6_h_14|Liquid Nitrogen|液体窒素|액체 질소|液態氮|3
sd_6_h_15|Volcano|火山|화산|火山|3
sd_6_h_16|Unsolvable Equation|解けない方程式|풀 수 없는 방정식|無解方程式|3
sd_6_h_17|Paradox|パラドックス|역설|悖論|3
sd_6_h_18|Maze|迷路|미로|迷宮|3
sd_6_h_19|Black Box|ブラックボックス|블랙박스|黑盒子|3
sd_6_h_20|Time Machine|タイムマシン|타임머신|時光機|3
sd_6_h_21|Hydraulic Press|油圧プレス|유압 프레스|液壓機|3
sd_6_h_22|Steam Engine|蒸気機関|증기 기관|蒸汽機|3
sd_6_h_23|Robot Factory|ロボット工場|로봇 공장|機器人工廠|3
sd_6_h_24|Mainframe|大型コンピューター|메인프레임|大型主機|3
sd_6_h_25|Dynamo|ダイナモ|다이너모|直流發電機|3
sd_6_h_26|Centrifuge|遠心分離機|원심분리기|離心機|3
sd_7_e_0|Magic Wand|魔法のつえ|마법 지팡이|魔杖|0
sd_7_e_1|Spell Book|魔法書|마법책|魔法書|0
sd_7_e_2|Wishing Star|願い星|소원별|許願星|0
sd_7_e_3|Tiny Crown|小さな王冠|작은 왕관|小王冠|0
sd_7_e_4|Glass Slipper|ガラスのくつ|유리 구두|玻璃鞋|0
sd_7_e_5|Pumpkin Carriage|かぼちゃの馬車|호박 마차|南瓜馬車|0
sd_7_e_6|Baby Dragon|子ドラゴン|아기 용|小龍|0
sd_7_e_7|Wax Seal|封ろう|봉랍|封蠟|0
sd_7_e_8|Fairy|妖精|요정|小精靈|0
sd_7_n_0|Magic Carpet|魔法のじゅうたん|마법 양탄자|魔毯|0
sd_7_n_1|Treasure Map|宝の地図|보물 지도|藏寶圖|0
sd_7_n_2|Pocket Watch|懐中時計|회중시계|懷錶|0
sd_7_n_3|Mummy|ミイラ|미라|木乃伊|1
sd_7_n_4|Sewer Rat|ドブネズミ|시궁쥐|溝鼠|1
sd_7_n_5|Cobweb|クモの巣|거미줄|蜘蛛網|1
sd_7_n_6|Ghost|おばけ|유령|鬼魂|2
sd_7_n_7|Gargoyle|ガーゴイル|가고일|石像鬼|2
sd_7_n_8|Candelabra|燭台|촛대|燭台|2
sd_7_h_0|Dragon|ドラゴン|드래곤|巨龍|3
sd_7_h_1|Dark Wizard|闇の魔法使い|흑마법사|黑巫師|3
sd_7_h_2|Golem|ゴーレム|골렘|石魔像|3
sd_7_h_3|Minotaur|ミノタウロス|미노타우로스|牛頭人|3
sd_7_h_4|Cyclops|サイクロプス|키클롭스|獨眼巨人|3
sd_7_h_5|Phoenix|不死鳥|불사조|不死鳥|3
sd_7_h_6|Hydra|ヒドラ|히드라|九頭蛇|3
sd_7_h_7|Vampire|吸血鬼|뱀파이어|吸血鬼|3
sd_7_h_8|Werewolf|おおかみ男|늑대인간|狼人|3
"""
}
