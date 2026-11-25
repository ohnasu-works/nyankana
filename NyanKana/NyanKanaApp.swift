import SwiftUI

/// にゃんグリッシュ — app entry.
@main
struct NyanKanaApp: App {
    @StateObject private var app = AppState.shared

    init() {
        Fonts.registerAll()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(app)
                .environmentObject(app.settings)
                .environmentObject(app.dev)
                .preferredColorScheme(.light)
        }
    }
}

/// Switches between the top-level screens. Each screen fills the window (no scrolling at the top level).
struct RootView: View {
    @EnvironmentObject var app: AppState
    @AppStorage("guide.seen") private var guideSeen = false
    @State private var rewards: [Reward] = []
    @State private var showInvite = false
    @AppStorage("premium.invited") private var invited = false

    var body: some View {
        ZStack {
            switch app.screen {
            // geometryGroup: each screen is laid out first and then slides in as one piece
            // (without it, the map's labels and pictures flew in from their own starting points)
            case .home:      HomeView().transition(.opacity)
            case .map:       StageMapView().geometryGroup().transition(.move(edge: .trailing))
            case .study:     KJStudyView { app.go(.home) }.geometryGroup().transition(.move(edge: .trailing))
            case .zukan:     KJZukanView().geometryGroup().transition(.move(edge: .trailing))
            case .record:    KJRecordView().geometryGroup().transition(.move(edge: .trailing))
            case .closet:    ClosetView().geometryGroup().transition(.move(edge: .trailing))
            case .settings:  SettingsView().geometryGroup().transition(.move(edge: .trailing))
            case .kana:      KanaJourneyView().transition(.opacity)
            case .game(let stage): GameScreen(stage: stage).id(stage).transition(.opacity)
            }
            // new costumes / TOEIC unlock, celebrated once when back from a game or study
            if !rewards.isEmpty {
                RewardView(rewards: rewards, graduated: rewards.contains(.outfit(.aloha))) {
                    RewardCenter.mark(rewards)
                    withAnimation { rewards = [] }
                    later(0.4) { checkInvite() }
                }
                .transition(.opacity).zIndex(10)
            }
            // premium introduced once, after the first mid-boss (Lv1 stage 10)
            if showInvite {
                PremiumInviteView {
                    withAnimation { showInvite = false }
                }
                .transition(.opacity).zIndex(11)
            }
        }
        .onChange(of: app.screen) { _, s in checkRewards(s) }
        .fullScreenCover(isPresented: Binding(get: { !guideSeen }, set: { if !$0 { guideSeen = true } })) {
            GuideView { guideSeen = true }
        }
        .animation(.easeInOut(duration: 0.25), value: app.screen)
        .sheet(item: $app.sheet) { sheet in
            switch sheet {
            case .items:  ItemListView()
            // large on iPad: the small form sheet cut off the pictures and the text
            case .howTo:  KJHowToSheet().presentationDetents([.large]).modifier(PageSizedSheet())
            case .shop:   ShopView()
            }
        }
        .onAppear {
            AudioManager.shared.start()
            #if DEBUG && targetEnvironment(simulator)
            later(2.0) { VoiceAudit.run() }
            #endif
        }
    }
}

extension RootView {
    func checkRewards(_ s: Screen) {
        if case .game = s { return }
        guard rewards.isEmpty else { return }
        later(0.6) {
            if case .game = app.screen { return }
            let r = RewardCenter.pending(app)
            if !r.isEmpty { withAnimation { rewards = r } } else { checkInvite() }
        }
    }
}

/// 「あそび方」 opens the same pages as the first-launch guide
struct GuideSheet: View {
    @Environment(\.dismiss) var dismiss
    var body: some View { GuideView { dismiss() } }
}


/// iPad: show a sheet at page size (iOS 18+), so tall content is not cut off
struct PageSizedSheet: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) { content.presentationSizing(.page) } else { content }
    }
}

extension RootView {
    func checkInvite() {
        guard !invited, !showInvite, rewards.isEmpty, !app.isPremium, !app.dev.unlocks else { return }
        if case .game = app.screen { return }
        guard app.progress.clearedStages(in: .lv1) >= 10 else { return }
        invited = true
        withAnimation { showInvite = true }
    }
}

/// One-time introduction of premium (not shown again after it is closed).
struct PremiumInviteView: View {
    var onClose: () -> Void
    @EnvironmentObject var app: AppState
    @ObservedObject private var store = Store.shared

    var body: some View {
        ZStack {
            Color.ink.opacity(0.6).ignoresSafeArea()
            PaperCard {
                VStack(spacing: 12.s) {
                    Image(systemName: "crown.fill").font(.system(size: 40.s, weight: .black)).foregroundStyle(Color(hex: 0xFFB800))
                    Text(jp(T("中ボス|クリア|おめでとう！", "중간 보스 클리어 축하해!", "恭喜打倒中頭目！"))).font(.display(22.s)).foregroundStyle(Color.ink)
                        .multilineTextAlignment(.center)
                    Text(jp(T("プレミアムに|すると、|もっと|快適に|遊べるよ", "프리미엄이면 더 쾌적하게 즐길 수 있어", "升級高級版，玩得更舒適"))).font(.ui(14.s)).foregroundStyle(Color.ink.opacity(0.8))
                        .multilineTextAlignment(.center)
                    VStack(alignment: .leading, spacing: 6.s) {
                        row("nosign", T("広告なし", "광고 없음", "無廣告"))
                        row("briefcase.fill", T("TOEICモードを|すぐ開放", "TOEIC 모드 즉시 해금", "立即解鎖TOEIC模式"))
                        row("tshirt.fill", T("限定衣装|「ゆかた」", "한정 의상 「유카타」", "限定服裝「浴衣」"))
                        row("cart.fill", T("買い切り|（月額では|ありません）", "한 번만 결제 (월정액 아님)", "一次買斷（非月費）"))
                    }
                    if Store.onSale {
                        Text(jp(T("今だけ|半額|（12月26日まで）", "지금만 반값 (12월 26일까지)", "限時半價（至12月26日）"))).font(.ui(14.s)).foregroundStyle(Color.popDeep)
                    }
                    PopButton(title: T("くわしく見る", "자세히 보기", "查看詳情") + "  " + store.priceLabel, height: 54) {
                        AudioManager.shared.se(.decide)
                        onClose()
                        app.sheet = .shop
                    }
                    PopButton(title: T("あとで", "나중에", "稍後再說"), color: .white, height: 44) {
                        AudioManager.shared.se(.tap); onClose()
                    }
                }
            }
            .frame(maxWidth: 400.s)
            .padding(.horizontal, 24)
        }
    }

    private func row(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 8.s) {
            Image(systemName: icon).font(.system(size: 15.s, weight: .bold)).foregroundStyle(Color.popDeep).frame(width: 22.s)
            Text(jp(text)).font(.ui(14.s)).foregroundStyle(Color.ink)
        }
    }
}
