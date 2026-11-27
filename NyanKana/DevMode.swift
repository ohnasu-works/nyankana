import SwiftUI
import Combine
import UserNotifications

/// Developer settings. Opened by tapping the version number in Settings 7 times.
/// unlockAll + devButtons let you check every stage to the end AND check what happens on mistakes.
@MainActor
final class DevSettings: ObservableObject {
    private let d = UserDefaults.standard
    @Published var enabled: Bool { didSet { d.set(enabled, forKey: "dev.enabled") } }
    /// every area / stage / mode open
    @Published var unlockAll: Bool { didSet { d.set(unlockAll, forKey: "dev.unlockAll") } }
    @Published var simulatePremium: Bool { didSet { d.set(simulatePremium, forKey: "dev.premium") } }
    /// show 正解 / まちがい / 時間切れ buttons in the answer panel (check both paths)
    @Published var devButtons: Bool { didSet { d.set(devButtons, forKey: "dev.buttons") } }
    /// any input counts as correct (fast run to the end)
    @Published var autoCorrect: Bool { didSet { d.set(autoCorrect, forKey: "dev.autoCorrect") } }
    @Published var noDamage: Bool { didSet { d.set(noDamage, forKey: "dev.noDamage") } }
    @Published var fast: Bool { didSet { d.set(fast, forKey: "dev.fast") } }
    /// every normal stage gets a rare runaway, a kidnapper and a possessed townsperson
    @Published var forceEvents: Bool { didSet { d.set(forceEvents, forKey: "dev.events") } }
    /// the ⏭ button also skips the game itself (counts as a clear)
    @Published var skipGames: Bool { didSet { d.set(skipGames, forKey: "dev.skipGames") } }

    /// Developer mode exists only in builds from Xcode and in TestFlight — never in the App Store version.
    static let allowed: Bool = {
        #if DEBUG
        return true
        #else
        return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
        #endif
    }()
    /// all developer switches only work while developer mode is on (and allowed)
    var unlocks: Bool { enabled && unlockAll }
    var premium: Bool { enabled && simulatePremium }
    var canSkip: Bool { enabled && skipGames }
    var anyRight: Bool { enabled && autoCorrect }

    init() {
        enabled = DevSettings.allowed && d.bool(forKey: "dev.enabled")
        unlockAll = d.bool(forKey: "dev.unlockAll")
        simulatePremium = d.bool(forKey: "dev.premium")
        devButtons = d.bool(forKey: "dev.buttons")
        autoCorrect = d.bool(forKey: "dev.autoCorrect")
        noDamage = d.bool(forKey: "dev.noDamage")
        fast = d.bool(forKey: "dev.fast")
        forceEvents = d.bool(forKey: "dev.events")
        skipGames = d.bool(forKey: "dev.skipGames")
    }
}

struct DevPanel: View {
    @EnvironmentObject var dev: DevSettings
    @EnvironmentObject var app: AppState
    @State private var confirmReset = false
    @State private var showSounds = false
    @State private var showVoices = false
    @State private var note = ""

    var body: some View {
        Section(L("dev.title")) {
            // ── すすめ方
            Toggle("全部開放する（すべての地方・ステージ・衣装）", isOn: $dev.unlockAll)
            Toggle("ゲームも とばせる（⏭ でクリア扱い）", isOn: $dev.skipGames)
            Toggle("どんな答えでも正解にする", isOn: $dev.autoCorrect)
            Toggle("ハートが減らない（バトル）", isOn: $dev.noDamage)
            // ── 課金
            Toggle(L("dev.premium"), isOn: $dev.simulatePremium)
            Toggle("未購入として動かす（審査の録画用・次の起動から）", isOn: Binding(get: { ForceFreeFlag.isOn }, set: { ForceFreeFlag.set($0); app.objectWillChange.send() }))
            // ── まいにちの しくみ
            Button("れんぞく日数を ＋1日") { addStreak(1) }
            Button("れんぞく日数を 7日に（けんどう）") { setStreak(7) }
            Button("れんぞく日数を 30日に（はれぎ）") { setStreak(30) }
            Button("れんぞく日数を 100日に（おしろ）") { setStreak(100) }
            Button("きょうの ミッションを リセット") {
                var l = KJDaily.log; l[KJDaily.key()] = nil; KJDaily.log = l
                UserDefaults.standard.removeObject(forKey: "kj.daily.best")
                done("リセットしました")
            }
            Button("ふくしゅうを ぜんぶ きょうの分にする") {
                var a = KJSRS.all
                for k in a.keys { a[k] = [a[k]?.first ?? 0, KJSRS.today] }
                KJSRS.all = a
                done("\(a.count)こ を きょうの ふくしゅうに しました")
            }
            Button("「まいにち 1もん」を 10秒後に とどける") { testQuiz() }
            // ── ずかん
            Button("ずかんを ぜんぶ 見たことにする") {
                KJZukan.seen = Set(KJZukan.allMinions)
                done("ずかんを ぜんぶ ひらきました")
            }
            Button("効果音の聞き比べ") { showSounds = true }
                .sheet(isPresented: $showSounds) { NavigationStack { SoundTestView() } }
            Button("音声チェック（一覧）") { showVoices = true }
                .sheet(isPresented: $showVoices) { NavigationStack { KJVoiceCheckView() } }
            if !note.isEmpty { Text(note).font(.ui(13, bold: false)).foregroundStyle(.secondary) }
            Button(L("dev.reset"), role: .destructive) { confirmReset = true }
                .confirmationDialog(L("dev.reset"), isPresented: $confirmReset) {
                    Button(L("dev.reset"), role: .destructive) { resetAll() }
                }
        }
        .font(.ui(15))
    }

    private func done(_ s: String) { note = s; AudioManager.shared.se(.decide) }

    /// fake past days so the streak becomes n (today included)
    private func setStreak(_ n: Int) {
        var l = KJDaily.log
        let cal = Calendar.current
        for i in 0..<n {
            let d = cal.date(byAdding: .day, value: -i, to: Date())!
            if (l[KJDaily.key(d)] ?? []).isEmpty { l[KJDaily.key(d)] = ["stage"] }
        }
        KJDaily.log = l
        _ = KJDaily.best
        done("れんぞく \(KJDaily.streak)日 に しました")
    }
    private func addStreak(_ n: Int) { setStreak(KJDaily.streak + n) }

    private func testQuiz() {
        guard let q = KJReminder.quiz(seed: Int(Date().timeIntervalSince1970)) else { done("問題が つくれませんでした"); return }
        Task {
            let c = UNUserNotificationCenter.current()
            _ = try? await c.requestAuthorization(options: [.alert, .sound])
            let marks = ["A", "B", "C"]
            let actions = q.choices.enumerated().map { j, t in UNNotificationAction(identifier: "a\(j)", title: "\(marks[j]). \(t)", options: []) }
            c.setNotificationCategories([UNNotificationCategory(identifier: "kj.q.test", actions: actions, intentIdentifiers: [])])
            let content = UNMutableNotificationContent()
            content.title = "きょうの 1もん"
            content.subtitle = q.prompt
            content.body = KJPic.strip(q.head) + "\n" + q.choices.enumerated().map { "\(marks[$0.offset]). \($0.element)" }.joined(separator: "   ")
            content.categoryIdentifier = "kj.q.test"
            content.userInfo = ["answer": q.answer, "key": q.key, "reveal": q.reveal]
            try? await c.add(UNNotificationRequest(identifier: "kj.test", content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)))
            done("10秒後に とどきます（アプリを とじて まってね）")
            KJReminder.refresh()   // the real daily schedule keeps its categories
        }
    }

    /// everything にゃんカナ remembers (stages, stars, missions, review, zukan, outfits…)
    private func resetAll() {
        let d = UserDefaults.standard
        for k in d.dictionaryRepresentation().keys where k.hasPrefix("kj.") { d.removeObject(forKey: k) }
        app.progress = ProgressStore(); app.save()
        done("記録を すべて 消しました")
    }
}

/// Developer sound test: play both candidates of every sound and choose one.
struct SoundTestView: View {
    @State private var refresh = 0
    var body: some View {
        List {
            Section {
                Text(jp("それぞれ|①②を|聞いて、|良い方を|タップで|選んでね。|選んだ音が|ゲームで|使われます。")).font(.ui(13, bold: false))
            }
            ForEach(AudioManager.SE.newSet, id: \.self) { se in
                HStack {
                    Text(se.label).font(.ui(15))
                    Spacer()
                    ForEach(se.candidates, id: \.self) { n in
                        Button {
                            se.chosen = n
                            refresh += 1
                            AudioManager.shared.preview(se, n)
                        } label: {
                            Text(n == 1 ? "①" : "②")
                                .font(.system(size: 20, weight: .bold))
                                .frame(width: 48, height: 36)
                                .background(RoundedRectangle(cornerRadius: 10).fill(se.chosen == n ? Color.sun : Color.white))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.ink, lineWidth: se.chosen == n ? 3 : 1.5))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .id("\(se.rawValue)-\(refresh)")
            }
        }
        .navigationTitle("効果音の聞き比べ")
    }
}

/// Developer: start any mid boss / boss stage directly (to check images, voices and BGM).
struct BossJumpView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        List {
            ForEach(Area.allCases, id: \.self) { area in
                Section(area.name) {
                    let n = area.stageCount
                    ForEach([10, 20].filter { $0 < n }, id: \.self) { i in
                        row("中ボス（\(i)面）：\(area.mid(i).name)", image: area.mid(i).image, area: area, index: i)
                    }
                    row(area == .graduation ? "大ボス（\(n)面）：\(area.boss.name)" : "ボス（\(n)面）：\(area.boss.name)",
                        image: area.boss.image, area: area, index: n)
                }
            }
        }
        .navigationTitle("ボス・中ボスへ直行")
    }

    private func row(_ title: String, image: String, area: Area, index: Int) -> some View {
        Button {
            AudioManager.shared.se(.decide)
            dismiss()
            later(0.35) { app.go(.game(StageRef(area: area, index: index, difficulty: .normal))) }
        } label: {
            HStack(spacing: 12) {
                Image(image).resizable().scaledToFit().frame(width: 52, height: 52)
                Text(title).font(.ui(15)).foregroundStyle(Color.ink)
                Spacer()
                Image(systemName: "play.circle.fill").font(.system(size: 22)).foregroundStyle(Color.popDeep)
            }
        }
    }
}
