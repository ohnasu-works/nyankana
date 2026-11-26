import SwiftUI

// MARK: - にゃんカナの あそびかた

struct KJHowToSheet: View {
    @Environment(\.dismiss) var dismiss
    private let items: [(String, String, String, String, String)] = [
        ("🗾", "にっぽんの たび", "Travel around Japan with Sora and Nyan. Yokai ate every letter — win them back region by region.",
         "和空與喵一起環遊日本。妖怪吃掉了所有文字，一個地區一個地區地把它們找回來吧。", "소라와 냥과 함께 일본을 여행해요. 요괴가 먹어 버린 글자를 지역마다 되찾아요."),
        ("📘", "きほんマス", "Learn new letters: listen, read, trace, then make words. Mistakes come back until you get them.",
         "學新文字：聽、讀、描寫，再拼成詞。答錯的題目會再出現直到答對。", "새 글자를 배워요: 듣고, 읽고, 따라 쓰고, 단어를 만들어요. 틀린 문제는 맞힐 때까지 다시 나와요."),
        ("📖", "ことばマス", "Practice the words of each place: hear a word, pick its spelling and its meaning.",
         "練習每個地方的詞語：聽詞選寫法和意思。", "그 지역의 단어를 연습해요: 듣고 표기와 뜻을 골라요."),
        ("🎮", "ゲームマス", "20 mini-games (karuta, sushi, ninja, taiko…) to use the letters you just learned.",
         "20種小遊戲（歌牌、壽司、忍者、太鼓…）練習剛學的文字。", "방금 배운 글자로 20가지 미니게임(가루타, 초밥, 닌자, 북…)을 해요."),
        ("⚔️", "しゅぎょう・バトル", "Tap the yokai with the letter you hear. In the boss battle, answer fast to save the letters!",
         "點選有聽到的文字的妖怪。頭目戰要快速作答救回文字！", "들은 글자를 가진 요괴를 터치해요. 보스전에서는 빨리 답해서 글자를 구해요!"),
        ("🐢", "ゆっくり", "The turtle button makes every voice slower.", "烏龜按鈕可以讓聲音變慢。", "거북이 버튼을 누르면 목소리가 느려져요."),
        ("✏️", "まなぶ", "Letter chart, practice, words, training (dictation, word order, listening, sound pairs, 60 seconds) and a JLPT N5-style exam.",
         "五十音表、練習、詞語、訓練（聽寫、排序、聽力、難分辨的音、60秒）和JLPT N5形式的考試。", "글자표, 연습, 단어, 트레이닝(받아쓰기·순서·듣기·헷갈리는 소리·60초)과 JLPT N5 형식 시험."),
        ("📚", "ずかん", "Bosses you beat, yokai you met and words you learned are collected here.",
         "打倒的頭目、遇到的妖怪和學會的詞語都收集在這裡。", "물리친 보스, 만난 요괴, 배운 단어가 모여요."),
        ("👘", "きせかえ", "Clear regions and keep studying to get new costumes for Sora and Nyan.",
         "通關地區、持續學習，就能得到空和喵的新服裝。", "지역을 클리어하고 공부하면 소라와 냥의 새 옷을 얻어요."),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(items, id: \.1) { i in
                        HStack(alignment: .top, spacing: 12) {
                            KJPicView(i.0, size: 36)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(i.1).font(.custom(Fonts.rounded, size: 18)).foregroundStyle(Color.ink)
                                Text(KJ.t(i.2, i.3, i.4)).font(.ui(14, bold: false)).foregroundStyle(Color.ink.opacity(0.8))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.ink, lineWidth: 2)))
                    }
                }
                .padding(16)
            }
            .background(Color(hex: 0xFFF6E0))
            .navigationTitle(L("home.howto"))
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button { dismiss() } label: { Label(L("common.back"), systemImage: "chevron.left").labelStyle(.titleAndIcon) } } }
        }
    }
}
