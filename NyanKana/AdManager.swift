import SwiftUI
import UIKit
import AppTrackingTransparency
import Combine
#if canImport(GoogleMobileAds)
@preconcurrency import GoogleMobileAds
#endif
#if canImport(UserMessagingPlatform)
@preconcurrency import UserMessagingPlatform
#elseif canImport(GoogleMobileAds)
// Without Google's consent message, ads would reach Europe with no consent: stop the build instead.
#error("UserMessagingPlatform is missing: add it to the target (Frameworks, Libraries, and Embedded Content)")
#endif

/// Ad settings. Release IDs are created in the AdMob console (にゃんグリッシュ バナー / 全画面).
enum AdConfig {
    // Google's official test IDs: always filled, never pay out (never tap real ads yourself)
    private static let testBanner = "ca-app-pub-3940256099942544/2934735716"
    private static let testInterstitial = "ca-app-pub-3940256099942544/4411468910"
    // にゃんグリッシュ (AdMob app ca-app-pub-8450156108746031~6813737541)
    private static let liveBanner = "ca-app-pub-8450156108746031/5314108562"
    private static let liveInterstitial = "ca-app-pub-8450156108746031/7062304505"
    /// Xcode and TestFlight builds show Google's test ads (real ads are not served before release,
    /// and a tester must not click real ads); only the App Store version uses the real ads.
    static var bannerUnitID: String { DevSettings.allowed ? testBanner : liveBanner }
    static var interstitialUnitID: String { DevSettings.allowed ? testInterstitial : liveInterstitial }
}

/// How often the full-screen ad appears (same rules as にゃんパス):
/// every 3rd finished stage, at least 3 minutes apart, never in the first 10 minutes after install.
enum AdPolicy {
    static let everyRounds = 3
    static let minInterval: TimeInterval = 180
    static let graceAfterInstall: TimeInterval = 600

    static func shouldShowInterstitial(roundsSinceLast: Int, lastShown: Date?, installDate: Date, now: Date) -> Bool {
        guard now.timeIntervalSince(installDate) >= graceAfterInstall else { return false }
        guard roundsSinceLast >= everyRounds else { return false }
        if let lastShown, now.timeIntervalSince(lastShown) < minInterval { return false }
        return true
    }
}

/// Ads only in the free version, and only around the game mode (the study mode stays ad-free).
@MainActor
final class AdManager: ObservableObject {
    static let shared = AdManager()

    var isEnabled: Bool { !AppState.shared.isPremium }
    @Published private(set) var isStarted = false
    private var isStarting = false
    private var roundsSinceLast = 0
    private var lastShown: Date?
    private let installDate: Date
    #if canImport(GoogleMobileAds)
    private var interstitial: InterstitialAd?
    #endif

    private init() {
        let d = UserDefaults.standard
        if let saved = d.object(forKey: "nyankana.ads.installDate") as? Date { installDate = saved }
        else { installDate = Date(); d.set(installDate, forKey: "nyankana.ads.installDate") }
        #if canImport(UserMessagingPlatform)
        // known from the last launch already, so Settings can show the button before any ad screen is opened
        privacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
        #endif
        watchActive()
    }

    /// tracking permission → SDK start → load the full-screen ad (first time the game map opens)
    /// Europe / UK / Switzerland (GDPR) and some US states: Google's consent message (UMP) comes first,
    /// then Apple's tracking dialog, then the ad SDK. Elsewhere UMP shows nothing.
    func start() async {
        guard isEnabled, !isStarted, !isStarting else { return }
        isStarting = true
        defer { isStarting = false }
        await askConsent()
        await askTracking()
        #if canImport(UserMessagingPlatform)
        guard ConsentInformation.shared.canRequestAds else { return }
        #endif
        // banners and full-screen ads are requested only from here on (after consent and the tracking answer)
        isStarted = true
        #if canImport(GoogleMobileAds)
        MobileAds.shared.start(completionHandler: nil)
        loadInterstitial()
        #endif
    }

    /// true where the law needs a "privacy choices" entry in Settings (Europe etc.)
    @Published private(set) var privacyOptionsRequired = false

    private func askConsent() async {
        #if canImport(UserMessagingPlatform)
        do {
            try await ConsentInformation.shared.requestConsentInfoUpdate(with: RequestParameters())
            try? await Task.sleep(nanoseconds: 600_000_000)
            if let root = UIApplication.shared.topViewController {
                try await ConsentForm.loadAndPresentIfRequired(from: root)
            }
        } catch {
            // no network etc.: try again next launch (ads still start if consent was given before)
        }
        privacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
        #endif
    }

    /// Settings > "Privacy choices": change the consent given in the Google message
    func showPrivacyOptions() async {
        #if canImport(UserMessagingPlatform)
        guard let root = UIApplication.shared.topViewController else { return }
        try? await ConsentForm.presentPrivacyOptionsForm(from: root)
        if !isStarted { await start() }
        #endif
    }

    /// The tracking dialog sometimes does not appear when it is asked for during a screen change (seen on iPad),
    /// so wait until the app is really in front, ask, and ask again if the answer is still "not determined".
    private func askTracking() async {
        for i in 0..<4 {
            guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
            try? await Task.sleep(nanoseconds: i == 0 ? 1_000_000_000 : 1_500_000_000)
            guard UIApplication.shared.applicationState == .active else { continue }
            _ = await ATTrackingManager.requestTrackingAuthorization()
        }
    }

    /// the app came back to the front: if the dialog never appeared, show it now (before ads are loaded again)
    private var activeObserver: NSObjectProtocol?
    private func watchActive() {
        activeObserver = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
            Task { @MainActor in
                let m = AdManager.shared
                guard m.isEnabled, m.isStarted || m.isStarting, ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
                await m.askTracking()
            }
        }
    }

    /// call when leaving a stage's result screen
    func roundFinished() {
        guard isEnabled, isStarted else { return }
        roundsSinceLast += 1
        guard AdPolicy.shouldShowInterstitial(roundsSinceLast: roundsSinceLast, lastShown: lastShown,
                                              installDate: installDate, now: Date()) else { return }
        #if canImport(GoogleMobileAds)
        guard let ad = interstitial else { loadInterstitial(); return }
        roundsSinceLast = 0
        lastShown = Date()
        interstitial = nil
        AudioManager.shared.duck(true)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 700_000_000)
            if let root = UIApplication.shared.topViewController { ad.present(from: root) }
            AudioManager.shared.duck(false)
            self.loadInterstitial()
        }
        #endif
    }

    /// A full-screen ad after a mid boss or a boss is beaten (free version only).
    /// The game waits: `then` runs after the ad is closed (or right away when no ad is shown).
    /// Only the 3-minute gap applies here (not the "every 3rd stage" or first-10-minutes rules),
    /// and it counts as the latest ad, so the result screen right after does not show another one.
    func breakAd(then done: @escaping @MainActor () -> Void) {
        #if canImport(GoogleMobileAds)
        guard isEnabled, isStarted else { done(); return }
        if let lastShown, Date().timeIntervalSince(lastShown) < AdPolicy.minInterval { done(); return }
        guard let ad = interstitial, let root = UIApplication.shared.topViewController else { loadInterstitial(); done(); return }
        roundsSinceLast = 0
        lastShown = Date()
        interstitial = nil
        AudioManager.shared.duck(true)
        let watcher = AdCloseWatcher { [weak self] in
            AudioManager.shared.duck(false)
            self?.closeWatcher = nil
            self?.loadInterstitial()
            done()
        }
        closeWatcher = watcher
        ad.fullScreenContentDelegate = watcher
        ad.present(from: root)
        #else
        done()
        #endif
    }

    #if canImport(GoogleMobileAds)
    private var closeWatcher: AdCloseWatcher?

    private func loadInterstitial() {
        guard isEnabled, interstitial == nil else { return }
        InterstitialAd.load(with: AdConfig.interstitialUnitID, request: Request()) { [weak self] ad, _ in
            MainActor.assumeIsolated { self?.interstitial = ad }
        }
    }
    #endif
}

#if canImport(GoogleMobileAds)
/// tells the game when the full-screen ad is gone (closed, or it could not be shown)
final class AdCloseWatcher: NSObject, FullScreenContentDelegate {
    private var done: (@MainActor () -> Void)?
    init(_ done: @escaping @MainActor () -> Void) { self.done = done }
    private func finish() {
        Task { @MainActor in self.done?(); self.done = nil }
    }
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) { MainActor.assumeIsolated { finish() } }
    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) { MainActor.assumeIsolated { finish() } }
}
#endif

extension UIApplication {
    /// the front-most view controller (to present the full-screen ad on)
    @MainActor var topViewController: UIViewController? {
        let scene = connectedScenes.compactMap { $0 as? UIWindowScene }.first { $0.activationState == .foregroundActive }
        var top = scene?.windows.first { $0.isKeyWindow }?.rootViewController
        while let p = top?.presentedViewController { top = p }
        return top
    }
}

/// Banner at the bottom of a screen. Nothing in the premium version.
struct AdBannerSlot: View {
    @EnvironmentObject var app: AppState
    @ObservedObject private var ads = AdManager.shared
    var body: some View {
        #if canImport(GoogleMobileAds)
        if !app.isPremium && ads.isStarted {
            BannerAdView()
                .frame(width: 320, height: 50)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.9))
        }
        #else
        EmptyView()
        #endif
    }
}

#if canImport(GoogleMobileAds)
private struct BannerAdView: UIViewRepresentable {
    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = AdConfig.bannerUnitID
        banner.rootViewController = UIApplication.shared.topViewController
        banner.load(Request())
        return banner
    }
    func updateUIView(_ uiView: BannerView, context: Context) {
        if uiView.rootViewController == nil { uiView.rootViewController = UIApplication.shared.topViewController }
    }
}
#endif
