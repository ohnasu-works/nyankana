import SwiftUI

/// にゃんカナ: costumes for Sora and Nyan. The worn costume is stored in `ProgressStore.wearing` ("sora" -> "sora.ninja")
/// and is used everywhere they appear (closet, home).
enum Outfit: String, CaseIterable, Identifiable {
    // one costume for clearing each region, plus study rewards
    case normal = "default", yukata, happi, snow, ninja, samurai, school, aloha, chef, hakama, kitsune, pajama, kendo, haregi, castle
    var id: String { rawValue }

    static let kids = ["sora", "yui", "nyan"]

    func image(_ kid: String) -> String {
        if self == .normal { return kid == "nyan" ? "nyan" : "\(kid)_full" }
        return "\(kid)_\(rawValue)"
    }

    var name: String {
        switch self {
        case .normal: T("いつもの服", "평상복", "平常服")
        case .yukata: T("ゆかた", "유카타", "浴衣")
        case .happi: T("まつりの はっぴ", "축제 핫피", "祭典法被")
        case .snow: T("ゆきの コート", "눈 코트", "雪地外套")
        case .ninja: T("にんじゃ", "닌자", "忍者")
        case .samurai: T("さむらい", "사무라이", "武士")
        case .school: T("せいふく", "교복", "制服")
        case .aloha: T("かりゆし", "가리유시", "嘉利吉衫")
        case .chef: T("すしやさん", "초밥 장인", "壽司師傅")
        case .hakama: T("はかま", "하카마", "袴")
        case .kitsune: T("きつね", "여우", "狐狸")
        case .pajama: T("パジャマ", "잠옷", "睡衣")
        case .kendo: T("けんどう", "검도복", "劍道服")
        case .haregi: T("はれぎ", "설빔 기모노", "新年和服")
        case .castle: T("おしろの いしょう", "성의 의상", "城堡服裝")
        }
    }

    /// the chapter whose boss gives this costume
    private var chapter: Int? { [Outfit.yukata: 1, .happi: 2, .snow: 3, .ninja: 4, .samurai: 5, .school: 6, .aloha: 7][self] }

    /// days in a row that give this costume
    var streakDays: Int? { KJDaily.goals.first { $0.outfit == self }?.days }

    /// how to get it (shown while locked)
    var condition: String {
        if let c = chapter {
            let n = KJC1.chapterNames[c]?.ja ?? ""
            return T("\(n)を|クリア", "\(n) 클리어", "通關\(n)")
        }
        switch self {
        case .chef: return T("トレーニングで|300問|正解", "트레이닝 300문제 정답", "訓練答對300題")
        case .hakama: return T("JLPT もしで|80点|以上", "JLPT 모의고사 80점 이상", "JLPT模擬考80分以上")
        case .kitsune: return T("ぜんぶの|ステージを|クリア", "모든 스테이지 클리어", "通關所有關卡")
        case .pajama: return T("トレーニングで|50問|正解", "트레이닝 50문제 정답", "訓練答對50題")
        case .kendo, .haregi, .castle:
            let n = streakDays ?? 0
            return T("まいにち|\(n)日|れんぞく", "\(n)일 연속", "連續\(n)天")
        default: return ""
        }
    }

    func unlocked(_ app: AppState) -> Bool {
        if app.dev.unlocks { return true }
        if self == .normal { return true }
        if let c = chapter { return KJC1.stages(in: c).last.map { KJC1.stars($0.id) > 0 } ?? false }
        switch self {
        case .chef: return KJTrainMode.totalCorrect >= 300
        case .hakama: return KJTrainMode.mock.best >= 80
        case .kitsune: return KJC1.stages.allSatisfy { KJC1.stars($0.id) > 0 }
        case .pajama: return KJTrainMode.totalCorrect >= 50
        case .kendo, .haregi, .castle: return KJDaily.best >= (streakDays ?? 0)
        default: return false
        }
    }

    /// longest study streak ever (so a broken streak keeps the costume)
    @MainActor static func bestStreak(_ app: AppState) -> Int {
        let now = app.study.streak, saved = UserDefaults.standard.integer(forKey: "study.bestStreak")
        if now > saved { UserDefaults.standard.set(now, forKey: "study.bestStreak") }
        return max(now, saved)
    }

    static func wearing(_ kid: String, _ app: AppState) -> Outfit {
        let v = app.progress.wearing[kid] ?? ""
        return Outfit(rawValue: String(v.split(separator: ".").last ?? "")) ?? .normal
    }

    /// an unlocked costume that was never shown in the closet
    static func hasNew(_ app: AppState) -> Bool {
        kids.contains { k in allCases.contains { $0 != .normal && $0.unlocked(app) && !app.progress.outfits.contains("\(k).\($0.rawValue)") } }
    }

    /// keep story scenes in sync with what the kids wear
    static func sync(_ app: AppState) {
        for k in kids { Cast.outfitImage[k] = wearing(k, app).image(k) }
    }
}

// MARK: - Closet screen

struct ClosetView: View {
    @EnvironmentObject var app: AppState
    @State private var kid = "sora"
    @State private var hop = 0

    var body: some View {
        SubScreen(title: L("home.closet"), color: .pop, bg: Color(hex: 0xFFC9E0)) {
            // the two kids and the Ken / Rin switch stay in place; only the clothes below scroll
            VStack(spacing: 12.s) {
                VStack(spacing: 12.s) {
                    stage
                    picker
                }
                .padding(.horizontal, 16).padding(.top, 6)
                ScrollView {
                    VStack(spacing: 14.s) {
                        grid
                        Text(jp(T("着せ替えた服は|お話の|場面でも|着てくれるよ。", "갈아입힌 옷은 이야기 장면에서도 입고 나와.", "換上的衣服在故事場景中也會穿著喔。")))
                            .font(.ui(12.s, bold: false)).foregroundStyle(Color.ink.opacity(0.6))
                    }
                    .padding(.horizontal, 16).padding(.top, 4).padding(.bottom, 30)
                }
            }
        }
        .onAppear { Outfit.sync(app) }
        .onDisappear { markSeen() }
    }

    /// the two kids (and Nyan) in what they wear now
    private var stage: some View {
        HStack(alignment: .bottom, spacing: 0) {
            let hs = KidLook.heights([Outfit.wearing("sora", app).image("sora"), Outfit.wearing("yui", app).image("yui")], height: 230.s, maxHeight: 250.s)
            kidImage("sora", height: hs[0])
            kidImage("yui", height: hs[1])
            kidImage("nyan", height: 150.s)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8.s)
        .background(
            RoundedRectangle(cornerRadius: 22.s).fill(Color.white.opacity(0.55))
                .overlay(RoundedRectangle(cornerRadius: 22.s).stroke(Color.ink, lineWidth: 2.5))
        )
    }

    private func kidImage(_ k: String, height: CGFloat) -> some View {
        Image(Outfit.wearing(k, app).image(k)).resizable().scaledToFit().frame(height: height)
            .offset(y: kid == k ? CGFloat(-6 * (hop % 2)) : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.45), value: hop)
            .opacity(kid == k ? 1 : 0.85)
    }

    private var picker: some View {
        HStack(spacing: 10.s) {
            ForEach(Outfit.kids, id: \.self) { k in
                Button { AudioManager.shared.se(.tap); kid = k } label: {
                    Text(k == "sora" ? "ソラ" : k == "yui" ? "ユイ" : "ニャン").font(.custom(Fonts.rounded, size: 18.s))
                        .foregroundStyle(kid == k ? Color.white : Color.ink)
                        .frame(maxWidth: .infinity, minHeight: 40.s)
                        .background(Capsule().fill(kid == k ? (k == "sora" ? Color.mintDeep : k == "yui" ? Color.pop : Color.popDeep) : Color.white)
                            .overlay(Capsule().stroke(Color.ink, lineWidth: 2.5)))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var grid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10.s), count: UIScale.isPad ? 4 : 3), spacing: 10.s) {
            ForEach(Outfit.allCases) { o in card(o) }
        }
    }

    private func card(_ o: Outfit) -> some View {
        let open = o.unlocked(app)
        let on = Outfit.wearing(kid, app) == o
        let isNew = open && o != .normal && !app.progress.outfits.contains("\(kid).\(o.rawValue)")
        return Button {
            guard open else {
                AudioManager.shared.se(.tap)
                return
            }
            AudioManager.shared.se(.decide)
            app.progress.wearing[kid] = "\(kid).\(o.rawValue)"
            app.progress.outfits.insert("\(kid).\(o.rawValue)")
            app.save()
            Outfit.sync(app)
            hop += 1
        } label: {
            VStack(spacing: 3.s) {
                Image(o.image(kid)).resizable().scaledToFit().frame(height: 110.s)
                    .colorMultiply(open ? .white : .black).opacity(open ? 1 : 0.22)
                    .overlay { if !open { Image(systemName: "lock.fill").font(.system(size: 22.s, weight: .black)).foregroundStyle(Color.ink.opacity(0.7)) } }
                Text(jp(o.name)).font(.ui(12.s)).foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.6)
                if !open {
                    Text(jp(o.condition)).font(.ui(11.s, bold: false)).foregroundStyle(Color.ink.opacity(0.65))
                        .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.7)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 168.s, alignment: .top)
            .padding(6.s)
            .background(RoundedRectangle(cornerRadius: 14.s).fill(on ? Color(hex: 0xFFF3B0) : Color.white)
                .overlay(RoundedRectangle(cornerRadius: 14.s).stroke(on ? Color.popDeep : Color.ink, lineWidth: on ? 3.5 : 2)))
            .overlay(alignment: .topLeading) {
                if on { badge(T("きてる", "착용 중", "穿著中"), .popDeep) }
                else if isNew { badge("NEW", .sky) }
            }
        }
        .buttonStyle(PressStyle(radius: 14.s, depth: 3))
    }

    private func badge(_ t: String, _ c: Color) -> some View {
        Text(jp(t)).font(.ui(11.s)).foregroundStyle(.white)
            .padding(.horizontal, 7).padding(.vertical, 2)
            .background(Capsule().fill(c)).offset(x: -4, y: -6)
    }

    /// everything unlocked so far stops showing NEW once the closet was opened
    private func markSeen() {
        var changed = false
        for k in Outfit.kids { for o in Outfit.allCases where o.unlocked(app) {
            if app.progress.outfits.insert("\(k).\(o.rawValue)").inserted { changed = true }
        } }
        if changed { app.save() }
    }
}


// MARK: - Sora and Yui side by side: the same face size in every costume

enum KidLook {
    /// distance between the eyes, as a fraction of the picture height (measured from the art)
    static let eyes: [String: CGFloat] = ["sora_aloha": 0.1366, "sora_castle": 0.1506, "sora_chef": 0.1337, "sora_full": 0.1284, "sora_hakama": 0.1222, "sora_happi": 0.1267, "sora_haregi": 0.1334, "sora_kendo": 0.1267, "sora_kitsune": 0.1297, "sora_ninja": 0.1411, "sora_pajama": 0.125, "sora_samurai": 0.1397, "sora_school": 0.1244, "sora_snow": 0.1145, "sora_yukata": 0.1241, "yui_aloha": 0.1043, "yui_castle": 0.0849, "yui_chef": 0.1187, "yui_full": 0.1261, "yui_hakama": 0.1187, "yui_happi": 0.125, "yui_haregi": 0.0988, "yui_kendo": 0.1145, "yui_kitsune": 0.1077, "yui_ninja": 0.1212, "yui_pajama": 0.1253, "yui_samurai": 0.1291, "yui_school": 0.0904, "yui_snow": 0.1209, "yui_yukata": 0.1131]
    static let normalEyes: CGFloat = 0.128

    /// heights for pictures shown side by side so their faces match;
    /// the first picture gets `height` (smaller if another would not fit in `maxHeight`)
    static func heights(_ images: [String], height: CGFloat, maxHeight: CGFloat? = nil) -> [CGFloat] {
        let e = images.map { eyes[$0] ?? normalEyes }
        let eyePx = height * e[0]
        var hs = e.map { eyePx / $0 }
        if let m = maxHeight, let top = hs.max(), top > m { hs = hs.map { $0 * m / top } }
        return hs
    }
}
