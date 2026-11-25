import SwiftUI
import UserNotifications

// MARK: - きょうの ミッション：毎日もどってくる理由（3つのミッション・連続日数・自動ふくしゅう・おしらせ）

enum KJDaily {
    enum Mission: String, CaseIterable, Identifiable {
        case stage, review, speak
        var id: String { rawValue }
        var ja: String {
            switch self {
            case .stage: "ステージを 1つ クリア"
            case .review: "ふくしゅう 10もん"
            case .speak: "はつおん 1かい"
            }
        }
        var sub: String {
            switch self {
            case .stage: KJ.t("Clear one stage", "通關1個關卡", "스테이지 1개 클리어")
            case .review: KJ.t("Review 10 questions", "複習10題", "복습 10문제")
            case .speak: KJ.t("One speaking round", "練習發音1次", "발음 연습 1회")
            }
        }
        var icon: String {
            switch self {
            case .stage: "map.fill"
            case .review: "arrow.counterclockwise.circle.fill"
            case .speak: "mic.fill"
            }
        }
        var color: Color {
            switch self {
            case .stage: Color(hex: 0xFFD6E8)
            case .review: Color(hex: 0xE6DCFF)
            case .speak: Color(hex: 0xD3F5E6)
            }
        }
    }

    /// streak rewards (days in a row → costume)
    static let goals: [(days: Int, outfit: Outfit)] = [(7, .kendo), (30, .haregi), (100, .castle)]

    static func key(_ d: Date = Date()) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: d)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    private static let logKey = "kj.daily.log"
    static var log: [String: [String]] {
        get { (UserDefaults.standard.dictionary(forKey: logKey) as? [String: [String]]) ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: logKey) }
    }

    static func done(_ m: Mission, on d: Date = Date()) -> Bool { log[key(d)]?.contains(m.rawValue) == true }
    static func count(on d: Date = Date()) -> Int { log[key(d)]?.count ?? 0 }
    static var allDoneToday: Bool { count() >= Mission.allCases.count }

    static func mark(_ m: Mission) {
        var l = log
        let k = key()
        var today = l[k] ?? []
        guard !today.contains(m.rawValue) else { return }
        today.append(m.rawValue)
        l[k] = today
        // keep about a year and a half
        if l.count > 550 { for old in l.keys.sorted().prefix(l.count - 550) { l[old] = nil } }
        log = l
        _ = best
        KJReminder.refresh()
    }

    /// days in a row with at least one mission (today may still be open)
    static var streak: Int {
        let cal = Calendar.current, l = log
        var d = Date(), n = 0
        if (l[key(d)] ?? []).isEmpty { d = cal.date(byAdding: .day, value: -1, to: d)! }
        while !(l[key(d)] ?? []).isEmpty { n += 1; d = cal.date(byAdding: .day, value: -1, to: d)! }
        return n
    }

    /// the longest streak ever (a broken streak keeps the costumes already earned)
    static var best: Int {
        let now = streak, saved = UserDefaults.standard.integer(forKey: "kj.daily.best")
        if now > saved { UserDefaults.standard.set(now, forKey: "kj.daily.best") }
        return max(now, saved)
    }
}

// MARK: - 自動ふくしゅう：おぼえた ことばを 1日後・3日後・1週間後… に もういちど

enum KJSRS {
    private static let key = "kj.srs"
    static let gaps = [1, 3, 7, 14, 30, 60]
    /// item -> [box, due day]
    static var all: [String: [Int]] {
        get { (UserDefaults.standard.dictionary(forKey: key) as? [String: [Int]]) ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
    static var today: Int { Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0 }

    static func miss(_ k: String) {
        var a = all
        a[k] = [0, today + 1]
        all = a
    }
    static func hit(_ k: String) {
        var a = all
        if let v = a[k], v.count == 2 {
            guard v[1] <= today else { return }       // not due yet: nothing changes
            let box = min(v[0] + 1, gaps.count - 1)
            a[k] = [box, today + gaps[box]]
        } else {
            a[k] = [0, today + gaps[0]]              // learned today → see it again tomorrow
        }
        all = a
    }
    /// items to review today, the most overdue first
    static var due: [String] {
        let t = today
        return all.filter { $0.value.count == 2 && $0.value[1] <= t }.sorted { $0.value[1] < $1.value[1] }.map(\.key)
    }
}

// MARK: - おしらせ（毎日 19:00、ミッションが まだの日だけ）

enum KJReminder {
    static var on: Bool {
        get { UserDefaults.standard.bool(forKey: "kj.remind") }
        set { UserDefaults.standard.set(newValue, forKey: "kj.remind") }
    }
    static let hour = 19
    private static let ids = (0..<7).map { "kj.remind.\($0)" }

    static func enable(_ want: Bool, done: @escaping (Bool) -> Void) {
        guard want else { on = false; refresh(); done(false); return }
        Task {
            let ok = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            on = ok; refresh(); done(ok)
        }
    }

    static func refresh() {
        let c = UNUserNotificationCenter.current()
        c.removePendingNotificationRequests(withIdentifiers: ids)
        guard on else { return }
        let cal = Calendar.current
        let streak = KJDaily.streak
        let dueCount = KJSRS.due.count
        for i in 0..<7 {
            guard let day = cal.date(byAdding: .day, value: i, to: Date()),
                  let at = cal.date(bySettingHour: hour, minute: 0, second: 0, of: day) else { continue }
            if i == 0 && (KJDaily.allDoneToday || at < Date()) { continue }
            let content = UNMutableNotificationContent()
            content.title = "にゃんカナ"
            if i <= 1 && streak > 0 {
                content.body = KJ.t("Keep your \(streak)-day streak! Today's 3 missions are waiting.",
                                    "連續\(streak)天！今天的3個任務在等你喔。",
                                    "\(streak)일 연속! 오늘의 미션 3개가 기다려요.")
            } else if i <= 1 && dueCount > 0 {
                content.body = KJ.t("\(dueCount) words are ready to review. 3 minutes is enough!",
                                    "有\(dueCount)個詞可以複習了，3分鐘就好！",
                                    "복습할 단어가 \(dueCount)개 있어요. 3분이면 충분해요!")
            } else {
                content.body = KJ.t("Nyan is waiting! Let's do today's missions.",
                                    "喵在等你！來完成今天的任務吧。",
                                    "냥이 기다려요! 오늘의 미션을 해요.")
            }
            content.sound = .default
            let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: at)
            c.add(UNNotificationRequest(identifier: ids[i], content: content, trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)))
        }
    }
}

// MARK: - ホームの 小さな ボタン：🔥 れんぞく日数 と ミッションの ●●○

struct KJDailyChip: View {
    var tap: () -> Void
    var body: some View {
        let n = KJDaily.streak
        Button { AudioManager.shared.se(.tap); tap() } label: {
            HStack(spacing: 6.s) {
                Image(systemName: "flame.fill").font(.system(size: 15.s, weight: .black))
                    .foregroundStyle(n > 0 ? Color(hex: 0xFF7A1A) : Color.ink.opacity(0.3))
                Text("\(n)").font(.display(16.s)).foregroundStyle(Color.ink)
                HStack(spacing: 3.s) {
                    ForEach(KJDaily.Mission.allCases) { m in
                        Circle().fill(KJDaily.done(m) ? Color.mint : Color.white)
                            .overlay(Circle().stroke(Color.ink, lineWidth: 1.5))
                            .frame(width: 10.s, height: 10.s)
                    }
                }
            }
            .padding(.horizontal, 12.s).padding(.vertical, 6.s)
            .background(Capsule().fill(Color.white).overlay(Capsule().stroke(Color.ink, lineWidth: 2.5)))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - きょうの ミッション 画面

struct KJDailyView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) var dismiss
    @State private var train: KJTrainMode?
    @State private var remind = KJReminder.on
    @State private var tick = 0

    var body: some View {
        ZStack {
            Color(hex: 0xFFF6E5).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16.s) {
                    header
                    missions
                    calendar
                    rewards
                    reminder
                }
                .padding(.horizontal, 18.s).padding(.vertical, 20.s)
                .id(tick)
            }
        }
        .fullScreenCover(item: $train) { m in
            KJTrainView(mode: m) { train = nil; tick += 1 }
        }
    }

    private var header: some View {
        let n = KJDaily.streak
        return VStack(spacing: 2.s) {
            HStack(spacing: 8.s) {
                Image(systemName: "flame.fill").font(.system(size: 34.s, weight: .black)).foregroundStyle(Color(hex: 0xFF7A1A))
                Text("\(n)").font(.display(44.s)).foregroundStyle(Color.ink)
                Text("にち れんぞく").font(.custom(Fonts.rounded, size: 18.s)).foregroundStyle(Color.ink)
            }
            Text(KJ.t("days in a row", "連續天數", "연속 일수")).font(.ui(12.s, bold: false)).foregroundStyle(Color.ink.opacity(0.6))
            if KJDaily.best > n {
                Text(KJ.t("Best: \(KJDaily.best) days", "最高紀錄：\(KJDaily.best)天", "최고 기록: \(KJDaily.best)일"))
                    .font(.ui(11.s, bold: false)).foregroundStyle(Color.ink.opacity(0.6))
            }
        }
    }

    private var missions: some View {
        VStack(spacing: 8.s) {
            title("きょうの ミッション", KJ.t("Today's missions", "今天的任務", "오늘의 미션"))
            ForEach(KJDaily.Mission.allCases) { m in
                let ok = KJDaily.done(m)
                Button {
                    guard !ok else { return }
                    AudioManager.shared.se(.decide)
                    switch m {
                    case .stage: dismiss(); later(0.3) { app.go(.kana) }
                    case .review: train = .review
                    case .speak: train = .speak
                    }
                } label: {
                    HStack(spacing: 12.s) {
                        Image(systemName: m.icon).font(.system(size: 22.s, weight: .bold)).foregroundStyle(Color.ink).frame(width: 30.s)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(m.ja).font(.custom(Fonts.rounded, size: 16.s)).foregroundStyle(Color.ink)
                            Text(m == .review && !KJSRS.due.isEmpty
                                 ? m.sub + KJ.t(" · \(KJSRS.due.count) due", "・待複習\(KJSRS.due.count)個", " · 복습 \(KJSRS.due.count)개")
                                 : m.sub)
                                .font(.ui(11.s, bold: false)).foregroundStyle(Color.ink.opacity(0.65))
                        }
                        Spacer(minLength: 0)
                        Image(systemName: ok ? "checkmark.circle.fill" : "play.circle.fill")
                            .font(.system(size: 26.s, weight: .bold)).foregroundStyle(ok ? Color.mintDeep : Color.popDeep)
                    }
                    .padding(12.s)
                    .background(RoundedRectangle(cornerRadius: 16.s).fill(ok ? Color.white.opacity(0.6) : m.color)
                        .overlay(RoundedRectangle(cornerRadius: 16.s).stroke(Color.ink, lineWidth: 2.5)))
                }
                .buttonStyle(.plain)
            }
            if KJDaily.allDoneToday {
                Text("ぜんぶ できた！ またあした ね。").font(.custom(Fonts.rounded, size: 15.s)).foregroundStyle(Color.popDeep)
                Text(KJ.t("All done! See you tomorrow.", "全部完成！明天見。", "다 했어요! 내일 또 만나요.")).font(.ui(11.s, bold: false)).foregroundStyle(Color.ink.opacity(0.6))
            }
        }
    }

    /// this month: a paw stamp on every day with a mission done
    private var calendar: some View {
        let cal = Calendar.current
        let now = Date()
        let first = cal.date(from: cal.dateComponents([.year, .month], from: now))!
        let days = cal.range(of: .day, in: .month, for: now)?.count ?? 30
        let lead = (cal.component(.weekday, from: first) - cal.firstWeekday + 7) % 7
        let today = cal.component(.day, from: now)
        let l = KJDaily.log
        return VStack(spacing: 6.s) {
            title("\(cal.component(.month, from: now))がつ", KJ.t("This month", "本月", "이번 달"))
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4.s), count: 7), spacing: 4.s) {
                ForEach(0..<(lead + days), id: \.self) { i in
                    if i < lead {
                        Color.clear.frame(height: 34.s)
                    } else {
                        let d = i - lead + 1
                        let date = cal.date(byAdding: .day, value: d - 1, to: first)!
                        let stamped = !(l[KJDaily.key(date)] ?? []).isEmpty
                        ZStack {
                            RoundedRectangle(cornerRadius: 8.s).fill(stamped ? Color(hex: 0xFFE1A8) : Color.white)
                                .overlay(RoundedRectangle(cornerRadius: 8.s).stroke(d == today ? Color.popDeep : Color.ink.opacity(0.25), lineWidth: d == today ? 2.5 : 1))
                            if stamped {
                                Image(systemName: "pawprint.fill").font(.system(size: 15.s)).foregroundStyle(Color(hex: 0xFF7A1A))
                            } else {
                                Text("\(d)").font(.ui(11.s, bold: false)).foregroundStyle(Color.ink.opacity(d > today ? 0.3 : 0.6))
                            }
                        }
                        .frame(height: 34.s)
                    }
                }
            }
        }
    }

    private var rewards: some View {
        let best = KJDaily.best
        return VStack(spacing: 6.s) {
            title("れんぞく ごほうび", KJ.t("Streak rewards", "連續獎勵", "연속 보상"))
            HStack(spacing: 10.s) {
                ForEach(Array(KJDaily.goals.enumerated()), id: \.offset) { _, g in
                    let got = best >= g.days
                    VStack(spacing: 4.s) {
                        Image(g.outfit.image("sora")).resizable().scaledToFit().frame(height: 70.s)
                            .saturation(got ? 1 : 0).opacity(got ? 1 : 0.45)
                        Text("\(g.days)にち").font(.display(13.s)).foregroundStyle(Color.ink)
                        Text(got ? g.outfit.name : "\(min(best, g.days)) / \(g.days)")
                            .font(.ui(10.s, bold: false)).foregroundStyle(Color.ink.opacity(0.65)).lineLimit(1).minimumScaleFactor(0.6)
                    }
                    .frame(maxWidth: .infinity).padding(8.s)
                    .background(RoundedRectangle(cornerRadius: 14.s).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 14.s).stroke(Color.ink, lineWidth: 2)))
                }
            }
            Text(KJ.t("Sora, Yui and Nyan all get the costume.", "索拉、結衣和喵都會得到服裝。", "소라, 유이, 냥 모두 의상을 받아요."))
                .font(.ui(10.s, bold: false)).foregroundStyle(Color.ink.opacity(0.6))
        }
    }

    private var reminder: some View {
        Toggle(isOn: Binding(get: { remind }, set: { v in
            remind = v
            KJReminder.enable(v) { ok in remind = ok }
        })) {
            VStack(alignment: .leading, spacing: 1) {
                Text("まいにち おしらせ（19:00）").font(.custom(Fonts.rounded, size: 15.s)).foregroundStyle(Color.ink)
                Text(KJ.t("Only on days you haven't finished yet", "只在還沒完成的日子提醒", "아직 안 한 날에만 알려요"))
                    .font(.ui(11.s, bold: false)).foregroundStyle(Color.ink.opacity(0.6))
            }
        }
        .tint(Color.mintDeep)
        .padding(12.s)
        .background(RoundedRectangle(cornerRadius: 16.s).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 16.s).stroke(Color.ink, lineWidth: 2)))
    }

    private func title(_ ja: String, _ sub: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8.s) {
            Text(ja).font(.custom(Fonts.rounded, size: 17.s)).foregroundStyle(Color.ink)
            Text(sub).font(.ui(11.s, bold: false)).foregroundStyle(Color.ink.opacity(0.55))
            Spacer(minLength: 0)
        }
    }
}
