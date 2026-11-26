import SwiftUI

// MARK: - にゃんカナの きろく（旅の進み具合・覚えた文字とことば・トレーニングと試験）

struct KJRecordView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        SubScreen(title: L("home.record"), color: .sky) {
            ScrollView {
                VStack(spacing: 14.s) {
                    summary
                    regions
                    study
                }
                .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 30)
            }
        }
        .onAppear { AudioManager.shared.playBGM(.track("record")) }
    }

    private var cleared: Int { KJC1.stages.filter { KJC1.stars($0.id) > 0 }.count }
    private var stars: Int { KJC1.stages.map { KJC1.stars($0.id) }.reduce(0, +) }
    private var lettersLearned: Int {
        Set(KJC1.stages.filter { KJC1.stars($0.id) > 0 }.flatMap(\.newKana)).count
    }

    private func stat(_ icon: String, _ value: String, _ label: String) -> some View {
        VStack(spacing: 2.s) {
            KJPicView(icon, size: 30.s)
            Text(value).font(.display(22.s)).foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.5)
            Text(label).font(.ui(11.s)).foregroundStyle(Color.ink.opacity(0.7)).lineLimit(1).minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 10.s)
        .background(RoundedRectangle(cornerRadius: 14.s).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 14.s).stroke(Color.ink, lineWidth: 2.5)))
    }

    private var summary: some View {
        VStack(spacing: 10.s) {
            HStack(spacing: 10.s) {
                stat("🗾", "\(cleared)/\(KJC1.stages.count)", KJ.t("Stages", "關卡", "스테이지"))
                stat("⭐", "\(stars)", KJ.t("Stars", "星星", "별"))
            }
            HStack(spacing: 10.s) {
                stat("あ", "\(lettersLearned)/\(KJData.letters.count)", KJ.t("Letters", "文字", "글자"))
                stat("📖", "\(KJZukan.learnedWords.count)", KJ.t("Words", "詞語", "단어"))
                stat("👻", "\(KJZukan.seen.count)", KJ.t("Yokai met", "遇見的妖怪", "만난 요괴"))
            }
        }
    }

    private var regions: some View {
        VStack(alignment: .leading, spacing: 8.s) {
            Text(KJ.t("The journey", "旅程", "여행")).font(.custom(Fonts.rounded, size: 16.s)).foregroundStyle(Color.ink)
            ForEach(1...7, id: \.self) { c in
                let list = KJC1.stages(in: c)
                let done = list.filter { KJC1.stars($0.id) > 0 }.count
                HStack(spacing: 10.s) {
                    Text("\(c)").font(.display(16.s)).foregroundStyle(.white)
                        .frame(width: 30.s, height: 30.s).background(Circle().fill(Color.pop).overlay(Circle().stroke(Color.ink, lineWidth: 2)))
                    VStack(alignment: .leading, spacing: 3.s) {
                        Text(KJC1.chapterNames[c]?.ja ?? "").font(.custom(Fonts.rounded, size: 14.s)).foregroundStyle(Color.ink)
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.ink.opacity(0.1))
                                Capsule().fill(Color.mint).frame(width: g.size.width * CGFloat(done) / CGFloat(max(list.count, 1)))
                            }
                        }
                        .frame(height: 10.s)
                    }
                    Text("\(done)/\(list.count)").font(.display(13.s)).foregroundStyle(Color.ink)
                }
            }
        }
        .padding(14.s)
        .background(RoundedRectangle(cornerRadius: 18.s).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 18.s).stroke(Color.ink, lineWidth: 2.5)))
    }

    private var study: some View {
        VStack(alignment: .leading, spacing: 8.s) {
            Text(KJ.t("Training & exam", "訓練與考試", "트레이닝과 시험")).font(.custom(Fonts.rounded, size: 16.s)).foregroundStyle(Color.ink)
            HStack {
                Text(KJ.t("Correct answers", "累計答對", "누적 정답")).font(.ui(13.s)).foregroundStyle(Color.ink)
                Spacer()
                Text("\(KJTrainMode.totalCorrect)").font(.display(16.s)).foregroundStyle(Color.ink)
            }
            ForEach(KJTrainMode.allCases) { m in
                HStack {
                    Image(systemName: m.icon).font(.system(size: 13.s, weight: .bold)).foregroundStyle(Color.ink).frame(width: 22.s)
                    Text(m.ja).font(.custom(Fonts.rounded, size: 13.s)).foregroundStyle(Color.ink)
                    Spacer()
                    Text(m.best > 0 ? (m == .mock ? "\(m.best) / 180" : "\(m.best)") : "—").font(.display(14.s)).foregroundStyle(Color.ink)
                }
            }
        }
        .padding(14.s)
        .background(RoundedRectangle(cornerRadius: 18.s).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 18.s).stroke(Color.ink, lineWidth: 2.5)))
    }
}
