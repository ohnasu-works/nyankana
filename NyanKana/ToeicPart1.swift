import Foundation

extension ToeicData {
    /// Part 1 (photographs): image|A|B|C|D|answer|tip|tag — the four statements are only heard
    static let part1 = """
p1_01|A woman is drinking coffee.|A woman is typing on a laptop.|A woman is talking on the phone.|A woman is closing a window.|1|人物の動作を聞き取る問題。女性はノートパソコンで入力している（typing）。|people
p1_02|They're sitting at a table.|They're reading a document.|They're shaking hands.|They're opening a door.|2|2人は握手している（shaking hands）。They're で始まる文は2人の動作に注目。|people
p1_03|A man is cutting the grass.|A man is planting a tree.|A man is carrying a ladder.|A man is watering some plants.|3|男性はホースで植物に水をやっている（watering）。似た場面の別の動作に注意。|people
p1_04|Some bicycles are parked in a row.|A man is riding a bicycle.|Bicycles are being repaired.|The street is crowded with cars.|0|人がいない写真は「物の状態」を表す文が正解になりやすい。自転車が1列に止めてある（parked in a row）。|object
p1_05|A chef is washing dishes.|A chef is cutting vegetables.|A chef is tasting some soup.|A chef is opening an oven.|1|料理人は野菜を切っている（cutting vegetables）。写っていない動作を選ばない。|people
p1_06|People are getting off a bus.|A train is being cleaned.|Some people are waiting on a platform.|The platform is empty.|2|人々がホームで待っている（waiting on a platform）。bus と train の聞き間違いに注意。|people
p1_07|A woman is paying at a register.|A woman is putting on a coat.|A woman is stacking boxes.|A woman is pushing a shopping cart.|3|女性はカートを押している（pushing a shopping cart）。|people
p1_08|People are looking at a screen.|People are standing in line.|People are leaving the room.|The chairs are stacked in a corner.|0|会議の参加者が画面を見ている（looking at a screen）。|people
p1_09|A woman is reading a book.|A ladder is leaning against a bookshelf.|Books are piled on the floor.|The shelves are being painted.|1|人のいない写真。はしごが本棚に立てかけてある（leaning against）。being painted（今ぬられている）は人がいないと使えない。|object
p1_10|A man is hanging a picture.|A man is fixing a car.|A man is painting a wall.|A man is climbing a tree.|2|男性ははしごの上で壁をぬっている（painting a wall）。ladder だけで選ばないこと。|people
p1_11|People are swimming in the water.|A boat is being loaded with boxes.|A bridge crosses the river.|Some boats are tied up at a pier.|3|ボートが桟橋につないである（tied up at a pier）。人がいないので being loaded（今積まれている）は不正解。|passive
p1_12|A woman is handing something to a man.|A man is carrying a suitcase upstairs.|They're sitting on a sofa.|A woman is answering the phone.|0|受付の女性が男性に何かを手渡している（handing something to）。something のようなぼかした言い方も正解になる。|people
"""
}

extension ToeicData {
    static let part1b = """
p1_13|A woman is ordering at a counter.|A woman is looking at a menu.|A waiter is pouring some water.|The tables are being wiped.|1|女性はメニューを見ている（looking at a menu）。写っていない店員の動作は選ばない。|people
p1_14|A man is opening a window.|A man is driving a truck.|A man is loading boxes into a truck.|A man is unpacking a suitcase.|2|男性はトラックに箱を積み込んでいる（loading ... into）。driving と loading の聞き分けに注意。|people
p1_15|A woman is using a copy machine.|A woman is typing a letter.|A woman is filing some folders.|A woman is fixing a printer.|0|女性はコピー機を使っている（using a copy machine）。fixing（修理している）とは違う。|people
p1_16|They're swimming in the sea.|They're sitting on a bench.|They're building a sandcastle.|They're walking along the shore.|3|2人は海辺を歩いている（walking along the shore）。|people
p1_17|People are sitting in the audience.|Chairs have been arranged in rows.|A stage is being built.|Some chairs are stacked against a wall.|1|人がいない写真。いすが列に並べてある（have been arranged in rows）。完了形の受け身は物の状態を表す。|object
p1_18|A man is riding a bicycle.|A man is buying a bicycle.|A man is repairing a bicycle.|A man is locking a bicycle.|2|男性は自転車を修理している（repairing）。bicycle だけでは選べないので動詞を聞く。|people
p1_19|A woman is painting a picture.|A woman is hanging a picture on a wall.|A woman is cleaning a window.|A woman is moving a sofa.|1|女性は壁に絵をかけている（hanging a picture）。painting（描いている）と区別。|people
p1_20|Pedestrians are crossing the street.|Cars are parked in a garage.|A bus is stopping at a station.|The road is being repaired.|0|歩行者が道を渡っている（crossing the street）。|people
p1_21|A man is pointing at a chart.|A man is erasing a whiteboard.|Some people are leaving a meeting.|A woman is handing out papers.|0|男性がグラフを指している（pointing at a chart）。|people
p1_22|A woman is buying some fruit.|Fruit is being washed.|Some fruit is displayed in baskets.|Baskets are piled on the ground.|2|人がいない写真。果物がかごに並べてある（displayed in baskets）。|object
p1_23|A woman is mopping a hallway.|A woman is sweeping the floor.|A woman is wiping a counter.|A woman is stocking shelves.|1|女性はほうきで床を掃いている（sweeping the floor）。mopping（モップがけ）と区別。|people
p1_24|They're looking at some plans.|They're climbing a ladder.|They're putting on helmets.|They're carrying some boards.|0|2人は図面を見ている（looking at some plans）。すでにヘルメットをかぶっている状態は putting on（かぶる動作）ではない。|people
"""
}

extension ToeicData {
    static let part1c = """
p1_25|A woman is hanging laundry.|A woman is cleaning a window.|A woman is watering some flowers.|A woman is planting a tree.|2|女性はじょうろで花に水をやっている（watering some flowers）。|people
p1_26|A man is feeding some birds.|A man is painting a bench.|A man is reading a newspaper.|A man is jogging in a park.|2|男性はベンチで新聞を読んでいる（reading a newspaper）。|people
p1_27|A waiter is washing glasses.|A waiter is carrying a tray.|A waiter is taking an order.|A waiter is setting a table.|1|ウェイターがトレーを運んでいる（carrying a tray）。|people
p1_28|Some documents are piled on a desk.|A lamp has been turned off.|A man is filing some documents.|The desk is being cleaned.|0|人がいない写真。書類が机に積まれている（piled on a desk）。being cleaned は人がいないと使えない。|object
p1_29|A woman is driving a car.|A woman is waiting at a bus stop.|A woman is crossing a bridge.|A woman is getting into a taxi.|3|女性がタクシーに乗りこもうとしている（getting into a taxi）。|people
p1_30|A man is moving some desks.|A man is vacuuming the carpet.|A man is fixing a computer.|A man is answering the phone.|1|男性は掃除機をかけている（vacuuming the carpet）。|people
p1_31|Some luggage is being weighed.|A plane is landing on a runway.|Passengers are boarding a plane.|Passengers are waiting in a terminal.|2|乗客が飛行機に乗りこんでいる（boarding a plane）。|people
p1_32|A table has been set for a meal.|Some dishes are being washed.|Chairs are stacked on a table.|People are eating dinner.|0|人がいない写真。食事の準備がしてある（has been set）。完了形の受け身は物の状態。|object
p1_33|A woman is folding some shirts.|A woman is hanging a mirror.|A woman is trying on a jacket.|A woman is paying for a coat.|2|女性はジャケットを試着している（trying on）。|people
p1_34|They're moving a monitor.|They're leaving the office.|They're looking at a monitor.|They're shaking hands.|2|2人は画面を見ている（looking at a monitor）。|people
p1_35|A man is sweeping a path.|A man is trimming a hedge.|A man is mowing the lawn.|A man is planting flowers.|2|男性は芝を刈っている（mowing the lawn）。|people
p1_36|Some chairs are being carried.|People are swimming in the sea.|Some umbrellas have been opened on a beach.|Umbrellas are stacked against a wall.|2|人がいない写真。パラソルが開いて立ててある（have been opened）。|object
p1_37|A man is parking a car.|A man is riding along a path.|A man is fishing in a river.|A man is repairing a bicycle.|1|男性は川沿いの道を自転車で走っている（riding along a path）。|people
p1_38|A woman is opening a window.|A woman is reading a book.|A woman is erasing a board.|A woman is writing on a whiteboard.|3|女性はホワイトボードに書いている（writing on a whiteboard）。erasing（消している）と区別。|people
p1_39|Two men are sitting on a sofa.|A truck is being washed.|Two men are carrying a sofa.|A door is being painted.|2|2人がソファを運んでいる（carrying a sofa）。|people
p1_40|Some pastries are displayed in a case.|A woman is buying some cake.|Some cakes are being baked.|A case is being cleaned.|0|人がいない写真。ケースにお菓子が並んでいる（displayed in a case）。|object
p1_41|A woman is taking a photograph.|A woman is painting a picture.|A woman is reading a sign.|A woman is entering a building.|0|女性はカメラで写真を撮っている（taking a photograph）。|people
p1_42|A man is buying some shoes.|A man is running on a track.|A man is stretching his arms.|A man is tying his shoe.|3|男性はくつひもを結んでいる（tying his shoe）。|people
p1_43|People are leaving a room.|People are seated in a waiting area.|People are standing in line.|Some magazines are being sold.|1|人々が待合室に座っている（seated in a waiting area）。|people
p1_44|A man is painting a shelf.|Cans are scattered on the floor.|Some cans are being opened.|Shelves have been stocked with cans.|3|人がいない写真。棚に缶が並べてある（have been stocked）。|object
p1_45|A woman is pouring some coffee.|A woman is opening a refrigerator.|A woman is washing a mug.|A woman is drinking some tea.|0|女性がコーヒーを注いでいる（pouring some coffee）。|people
p1_46|A man is leaving the stage.|A man is playing the guitar.|A man is setting up some chairs.|A man is adjusting a microphone.|3|男性はマイクを調整している（adjusting a microphone）。|people
p1_47|The parking lot is closed.|A man is parking a car.|Cars are being washed.|Cars are parked side by side.|3|人がいない写真。車が並んで止めてある（parked side by side）。|object
p1_48|A woman is pointing at a map.|A woman is carrying a backpack.|A woman is buying a ticket.|A woman is folding a map.|0|女性が地図を指さしている（pointing at a map）。リュックを持っているのは旅行者のほう。|people
p1_49|A man is opening a car door.|A man is driving a car.|A man is filling a tire with air.|A man is washing a car.|3|男性はスポンジで車を洗っている（washing a car）。|people
p1_50|People are walking on the road.|Cars are moving along the road.|Trees are lining both sides of the road.|Trees are being cut down.|2|人も車もいない写真。道の両側に木が並んでいる（lining both sides）。|object
p1_51|A woman is cleaning a stage.|A woman is stacking chairs.|A woman is sitting on a chair.|A woman is painting chairs.|1|女性がいすを積み重ねている（stacking chairs）。|people
p1_52|A man is reading at a desk.|A man is building a shelf.|A man is putting a book on a shelf.|A man is buying a book.|2|男性が本を棚に戻している（putting a book on a shelf）。|people
p1_53|Some people are eating outdoors.|People are waiting to be seated.|A waiter is cleaning a table.|The terrace is empty.|0|人々が屋外で食事をしている（eating outdoors）。|people
p1_54|A laptop has been left open on a desk.|Books are stacked by the window.|A cup is being filled.|A man is typing on a laptop.|0|人がいない写真。ノートパソコンが開いたまま置いてある（has been left open）。|object
p1_55|A woman is making a bed.|A woman is carrying a suitcase.|A woman is packing a suitcase.|A woman is ironing a shirt.|2|女性がスーツケースに荷物を詰めている（packing a suitcase）。|people
p1_56|A building is being painted.|Workers are climbing a tree.|Workers are standing on a scaffold.|Workers are taking a break.|2|作業員が足場の上に立っている（standing on a scaffold）。|people
p1_57|A man is talking to a clerk.|A man is boarding a train.|A man is reading a schedule.|A man is using a ticket machine.|3|男性は券売機を使っている（using a ticket machine）。|people
p1_58|Some flowers have been placed in vases.|Flowers are being delivered.|A woman is arranging flowers.|Vases are lined up on the floor.|0|人がいない写真。花が花びんに生けてある（have been placed）。|object
p1_59|They're painting a picture.|They're buying a painting.|They're looking at a painting.|They're hanging a painting.|2|2人は絵を見ている（looking at a painting）。|people
p1_60|A man is cooking a meal.|A man is washing dishes.|A man is opening a cabinet.|A man is working under a sink.|3|男性が流しの下で作業している（working under a sink）。|people
"""
}
