import SwiftUI

// MARK: - First-launch guide (also opened from 「あそび方」)

struct GuideView: View {
    var onDone: () -> Void
    @State private var page = 0

    private struct Page {
        let title: String
        let lines: [String]
        let art: AnyView
        let color: Color
    }

    /// built once (rebuilding all five pages with their pictures on every redraw made swiping stutter)
    private let pages: [Page] = GuideView.makePages()

    init(onDone: @escaping () -> Void) { self.onDone = onDone }

    private static func makePages() -> [Page] {
        [
            Page(title: T("ようこそ\nワーディアへ！", "워디아에\n온 걸 환영해!", "歡迎來到\n沃迪亞！"),
                 lines: [T("英語の島「ワーディア」から、|ことばが|消えちゃった！", "영어의 섬 「워디아」에서 말이 사라졌어!", "英語之島「沃迪亞」的語言消失了！"),
                         T("英語を|食べちゃう|ゴブルズの|しわざだにゃ。|ケンとリンと|いっしょに|取り戻そう！", "영어를 먹어 버리는 고블스의 짓이야. 켄, 린과 함께 되찾자!", "都是會吃英文的高布斯搞的鬼喵。和肯、琳一起奪回來吧！")],
                 art: AnyView(HStack(alignment: .bottom, spacing: -14) {
                     Image("ken_full").resizable().scaledToFit().frame(height: 190.s)
                     Image("nyan").resizable().scaledToFit().frame(height: 96.s).zIndex(1)
                     Image("rin_full").resizable().scaledToFit().frame(height: 154.s)
                 }), color: Color(hex: 0xFFD66B)),
            Page(title: T("マップで\nステージを選ぼう", "맵에서\n스테이지를 고르자", "在地圖上\n選關卡"),
                 lines: [T("中1から|高3まで、|7つの|エリアが|あるよ。|最後は|サイレンス城の|卒業試験！", "중1부터 고3까지 7개의 지역이 있어. 마지막은 사일런스 성의 졸업 시험!", "從國一到高三共有7個區域，最後是沉默城的畢業考！"),
                         T("むずかしさは|EASY・NORMAL・HARDから|選べるよ。", "난이도는 EASY·NORMAL·HARD 중에서 고를 수 있어.", "難度可選 EASY・NORMAL・HARD。")],
                 art: AnyView(Image("map").resizable().scaledToFit().frame(height: 210.s)
                     .clipShape(RoundedRectangle(cornerRadius: 18.s))
                     .overlay(RoundedRectangle(cornerRadius: 18.s).stroke(Color.ink, lineWidth: 3))),
                 color: Color(hex: 0x8FD0FF)),
            Page(title: T("正しい英語で\nゴブルズをたおそう", "올바른 영어로\n고블스를 물리치자", "用正確的英文\n打倒高布斯"),
                 lines: [T("答えると|「ことばの玉」が|飛んでいくよ。|メーターが|なくなる前に|答えよう。", "답하면 「말의 구슬」이 날아가. 미터가 다 떨어지기 전에 답하자.", "答對就會射出「語言球」。在計時條歸零前作答吧。"),
                         T("答え方は|選択・キーボード・|手書き・声の|4つ。|アイテムも|使えるよ。", "답하는 방법은 선택·키보드·손글씨·목소리 4가지. 아이템도 쓸 수 있어.", "作答方式有選擇、鍵盤、手寫、語音4種，也能使用道具。"),
                         T("声で|答えるとき、|HARDは|穴うめ問題も|文ぜんぶを|読もう。|話す力が|ぐんと|つくよ。", "목소리로 답할 때 HARD에서는 빈칸 문제도 문장 전체를 읽자. 말하기 실력이 쑥쑥 늘어.", "用語音作答時，HARD模式的填空題也要念出整句，口說能力會大幅提升。")],
                 art: AnyView(HStack(alignment: .bottom, spacing: 12.s) {
                     Image("ken_full").resizable().scaledToFit().frame(height: 170.s)
                     Image(systemName: "sparkles").font(.system(size: 40.s, weight: .black)).foregroundStyle(Color.sun).padding(.bottom, 80.s)
                     Image("gob_03").resizable().scaledToFit().frame(height: 120.s)
                 }), color: Color(hex: 0xFF9FC6)),
            Page(title: T("ボスをたおすと\n真の姿が…！", "보스를 물리치면\n진짜 모습이…!", "打倒頭目\n就會現出真面目…！"),
                 lines: [T("各エリアの|最後には|ボスが|待っているよ。", "각 지역의 마지막에는 보스가 기다리고 있어.", "每個區域的最後都有頭目在等著。"),
                         T("ボスを|たおすと、|新しい|服が|もらえるよ。|クローゼットで|着せ替えよう！", "보스를 물리치면 새 옷을 받을 수 있어. 옷장에서 갈아입히자!", "打倒頭目可以得到新衣服，到衣櫃換裝吧！")],
                 art: AnyView(HStack(alignment: .bottom, spacing: 8.s) {
                     Image("boss_silence").resizable().scaledToFit().frame(height: 180.s)
                     Image("ui_dress").resizable().scaledToFit().frame(height: 80.s)
                 }), color: Color(hex: 0xC9B6FF)),
            Page(title: T("おべんきょうで\nもっと強くなる", "공부로\n더 강해지자", "用學習\n變得更強"),
                 lines: [T("たんごトレーニングで|ことばのたまごを|育てよう。|書き取り・リスニング・|発音も|練習できるよ。", "단어 트레이닝으로 말의 알을 키우자. 받아쓰기·리스닝·발음도 연습할 수 있어.", "用單字訓練培育語言蛋，也能練習聽寫、聽力和發音。"),
                         T("卒業すると|TOEICモードが|開くよ。|毎日|続けると|ごほうびも！", "졸업하면 TOEIC 모드가 열려. 매일 하면 보상도!", "畢業後會開放TOEIC模式，每天持續還有獎勵！")],
                 art: AnyView(HStack(alignment: .bottom, spacing: 10.s) {
                     Image("vocab_pet2").resizable().scaledToFit().frame(height: 130.s)
                     Image("nyan").resizable().scaledToFit().frame(height: 120.s)
                     Image("st_toeic").resizable().scaledToFit().frame(height: 90.s)
                 }), color: Color(hex: 0x9BE8CB)),
        ]
    }

    private func pageBody(_ p: Page, k: CGFloat, font: CGFloat, title: CGFloat) -> some View {
        VStack(spacing: 18.s * max(0.6, k)) {
            Spacer(minLength: 0)
            p.art.scaleEffect(k).frame(height: 210.s * k).frame(maxWidth: .infinity)
            OutlinedText(p.title, font: .display(title.s), width: 3, shadow: 0)
                .multilineTextAlignment(.center)
            VStack(alignment: .leading, spacing: 10.s * max(0.7, k)) {
                ForEach(p.lines, id: \.self) { l in
                    Text(jp(l)).font(.ui(font.s, bold: false)).foregroundStyle(Color.ink).fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16.s * max(0.75, k))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 18.s).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 18.s).stroke(Color.ink, lineWidth: 3)))
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 8)
    }

    var body: some View {
        ZStack {
            pages[page].color.ignoresSafeArea().animation(.easeInOut, value: page)
            VStack(spacing: 16.s) {
                HStack {
                    Spacer()
                    Button { AudioManager.shared.se(.tap); onDone() } label: {
                        Text(T("スキップ", "건너뛰기", "略過")).font(.ui(14.s)).foregroundStyle(Color.ink)
                            .padding(.horizontal, 14.s).padding(.vertical, 7.s)
                            .background(Capsule().fill(Color.white.opacity(0.8)).overlay(Capsule().stroke(Color.ink, lineWidth: 2)))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 22)
                .padding(.top, UIScale.isPad ? 30 : 0)
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        let p = pages[i]
                        // centred; on a short screen the picture and text shrink step by step so it never scrolls
                        ViewThatFits(in: .vertical) {
                            pageBody(p, k: 1.0, font: 16, title: 24)
                            pageBody(p, k: 0.75, font: 15, title: 22)
                            pageBody(p, k: 0.55, font: 14, title: 20)
                            pageBody(p, k: 0.42, font: 13, title: 18)
                        }
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { i in
                        Capsule().fill(i == page ? Color.ink : Color.ink.opacity(0.25)).frame(width: i == page ? 22 : 8, height: 8)
                    }
                }
                .animation(.spring(response: 0.3), value: page)
                PopButton(title: page == pages.count - 1 ? T("はじめる！", "시작하기!", "開始！") : T("つぎへ", "다음", "下一頁"),
                          color: page == pages.count - 1 ? .pop : .white, textColor: page == pages.count - 1 ? .white : .ink) {
                    AudioManager.shared.se(.decide)
                    if page == pages.count - 1 { onDone() } else { withAnimation { page += 1 } }
                }
                .padding(.horizontal, 22).padding(.bottom, 10)
            }
            .frame(maxWidth: UIScale.isPad ? 640 : .infinity)
        }
    }
}

// MARK: - Rewards: new costumes and TOEIC unlock are celebrated once

enum Reward: Identifiable, Hashable {
    case outfit(Outfit), toeic
    var id: String { switch self { case .outfit(let o): "o." + o.rawValue; case .toeic: "toeic" } }
}

@MainActor
enum RewardCenter {
    private static let key = "reward.celebrated"
    private static var done: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: key) ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: key) }
    }

    static func all(_ app: AppState) -> [Reward] {
        var r: [Reward] = Outfit.allCases.filter { $0 != .normal && $0.unlocked(app) }.map { .outfit($0) }
        if app.toeicUnlocked { r.append(.toeic) }
        return r
    }

    /// rewards earned since the last check (none while the developer unlock is on)
    static func pending(_ app: AppState) -> [Reward] {
        if app.dev.unlocks { return [] }
        if !UserDefaults.standard.bool(forKey: "reward.seeded") {
            UserDefaults.standard.set(true, forKey: "reward.seeded")
            done = Set(all(app).map(\.id))   // existing progress is not celebrated again
            return []
        }
        let d = done
        return all(app).filter { !d.contains($0.id) }
    }

    static func mark(_ r: [Reward]) { done = done.union(r.map(\.id)) }
}

struct RewardView: View {
    let rewards: [Reward]
    var graduated: Bool
    var onDone: () -> Void
    @EnvironmentObject var app: AppState
    @State private var i = 0
    @State private var pop = false

    var body: some View {
        ZStack {
            Color.ink.opacity(0.7).ignoresSafeArea()
            Sunburst(a: Color(hex: 0xFFE27A), b: Color(hex: 0xFFC83D), center: .init(x: 0.5, y: 0.42), rays: 18)
                .opacity(0.55).ignoresSafeArea()
            VStack(spacing: 14.s) {
                if graduated && i == 0 {
                    OutlinedText(jp(T("卒業|おめでとう！", "졸업 축하해!", "恭喜畢業！")), font: .display(34.s), fill: .sun, width: 4, shadow: 0)
                        .multilineTextAlignment(.center)
                }
                OutlinedText("GET!", font: .en(54.s), fill: .white, width: 4, shadow: 0)
                    .scaleEffect(pop ? 1 : 0.4)
                card(rewards[i])
                    .scaleEffect(pop ? 1 : 0.6).opacity(pop ? 1 : 0)
                if rewards.count > 1 {
                    Text("\(i + 1) / \(rewards.count)").font(.en(15.s)).foregroundStyle(.white)
                }
                PopButton(title: i + 1 < rewards.count ? T("つぎへ", "다음", "下一個") : T("やったね！", "해냈다!", "太棒了！"), color: .pop, textColor: .white) {
                    AudioManager.shared.se(.decide)
                    if i + 1 < rewards.count { pop = false; i += 1; appear() } else { onDone() }
                }
                .frame(maxWidth: 360.s)
            }
            .padding(24)
        }
        .onAppear {
            AudioManager.shared.se(graduated ? .fanfareBoss : .clear, volume: 0.9)
            appear()
        }
    }

    private func appear() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.55).delay(0.1)) { pop = true }
        if i > 0 { AudioManager.shared.se(.itemGet, volume: 0.8) }
    }

    @ViewBuilder private func card(_ r: Reward) -> some View {
        VStack(spacing: 10.s) {
            switch r {
            case .outfit(let o):
                HStack(alignment: .bottom, spacing: -10.s) {
                    Image(o.image("sora")).resizable().scaledToFit().frame(height: 210.s)
                    Image(o.image("nyan")).resizable().scaledToFit().frame(height: 150.s)
                }
                Text(jp(T("新しい服", "새 옷", "新衣服"))).font(.ui(13.s)).foregroundStyle(Color.ink.opacity(0.6))
                Text(jp(o.name)).font(.display(24.s)).foregroundStyle(Color.ink)
                Text(jp(T("クローゼットで|着せ替えよう！", "옷장에서 갈아입히자!", "到衣櫃換上吧！"))).font(.ui(13.s, bold: false)).foregroundStyle(Color.ink)
            case .toeic:
                Image("st_toeic").resizable().scaledToFit().frame(height: 150.s)
                Text(jp(T("TOEICモード|解放！", "TOEIC 모드 해금!", "TOEIC模式解鎖！"))).font(.display(24.s)).foregroundStyle(Color.ink)
                Text(jp(T("おべんきょうの|TOEICで、|Part 1〜7と|本格模試に|挑戦できるよ。", "공부의 TOEIC에서 Part 1~7과 실전 모의고사에 도전할 수 있어.", "在學習的TOEIC中，可以挑戰Part 1～7和正式模擬考。")))
                    .font(.ui(13.s, bold: false)).foregroundStyle(Color.ink).multilineTextAlignment(.center)
            }
        }
        .padding(18.s)
        .frame(maxWidth: 360.s)
        .background(RoundedRectangle(cornerRadius: 24.s).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 24.s).stroke(Color.ink, lineWidth: 3.5)))
        .background(RoundedRectangle(cornerRadius: 24.s).fill(Color.ink).offset(y: 6))
    }
}
