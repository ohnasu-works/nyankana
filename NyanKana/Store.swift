import StoreKit
import Security
import Combine

/// Premium (non-consumable, one-time purchase) with StoreKit 2.
@MainActor
final class Store: ObservableObject {
    static let shared = Store()
    static let premiumID = "com.sunao.nyankana.premium"

    @Published private(set) var product: Product?
    /// shown under the buy button when the App Store can't be reached (instead of nothing happening)
    @Published var notice: String?
    @Published private(set) var busy = false
    /// DEBUG only (see AppState.isPremium): premium owned in this run's StoreKit
    @Published private(set) var debugOwned = false
    /// Review recording: act as NOT purchased (ignore saved / iCloud / earlier TestFlight purchases) and
    /// trust only a purchase made in this run. Xcode launch argument "-debugForceFree", or the developer switch
    /// (TestFlight / Xcode builds only; kept in the Keychain so it survives deleting and reinstalling the app).
    static let debugForceFree: Bool = ProcessInfo.processInfo.arguments.contains("-debugForceFree")
        || (DevSettings.allowed && ForceFreeFlag.isOn)

    var priceLabel: String { product?.displayPrice ?? "¥3,000" }

    /// launch sale: half price from the day the app goes live through Dec 26, 2026 (Japan time).
    /// No start date, so it is right whenever the release happens.
    /// The price itself comes from App Store Connect; this only switches the "half price" wording.
    static var onSale: Bool {
        var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let end = c.date(from: DateComponents(year: 2026, month: 12, day: 27))!
        return Date() < end
    }

    private var updates: Task<Void, Never>?

    private init() {
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let t) = result { await self?.apply(t); await t.finish() }
            }
        }
        Task { await load(); await refresh() }
    }

    func load() async {
        product = try? await Product.products(for: [Store.premiumID]).first
    }

    func buy() async {
        guard !busy else { return }
        busy = true; notice = nil
        defer { busy = false }
        if product == nil { await load() }
        guard let product else {
            notice = T("App Storeに|つながりませんでした。|少し時間を|おいて、|もう一度|おためしください。", "App Store에 연결할 수 없습니다. 잠시 후 다시 시도해 주세요.", "無法連線到App Store，請稍後再試。")
            return
        }
        do {
            let result = try await product.purchase()
            if case .success(let v) = result, case .verified(let t) = v { await apply(t); await t.finish() }
            if case .pending = result { notice = T("購入の|承認待ちです。", "구매 승인 대기 중입니다.", "購買等待核准中。") }
        } catch {
            notice = T("購入を|完了できませんでした。|もう一度|おためしください。", "구매를 완료하지 못했습니다. 다시 시도해 주세요.", "無法完成購買，請再試一次。")
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refresh()
    }

    func refresh() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result { await apply(t, restored: true) }
        }
    }

    private func apply(_ t: Transaction, restored: Bool = false) async {
        guard t.productID == Store.premiumID else { return }
        let owned = t.revocationDate == nil
        if Store.debugForceFree {
            // only a purchase made in this run counts (not the one already owned from before)
            if !restored { debugOwned = owned; AppState.shared.objectWillChange.send() }
            return
        }
        AppState.shared.progress.premium = owned
        AppState.shared.save()
    }
}

/// Developer switch "act as not purchased", stored in the Keychain (survives reinstalling the app).
enum ForceFreeFlag {
    private static let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                               kSecAttrService as String: "nyankana.dev",
                                               kSecAttrAccount as String: "forceFree"]
    static var isOn: Bool {
        var q = query; q[kSecReturnData as String] = true
        var out: AnyObject?
        return SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess
    }
    static func set(_ on: Bool) {
        SecItemDelete(query as CFDictionary)
        guard on else { return }
        var q = query; q[kSecValueData as String] = Data([1])
        SecItemAdd(q as CFDictionary, nil)
    }
}
