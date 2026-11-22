import SwiftUI

/// Costumes for Ken and Rin. The worn costume is stored in `ProgressStore.wearing` ("ken" -> "ken.uniform")
/// and is used everywhere the kid appears (closet, story scenes).
enum Outfit: String, CaseIterable, Identifiable {
    // one costume for clearing each level, plus a study reward and a premium one
    case normal = "default", uniform, street, sports, suit, garden, lab, hero, pajama, yukata
    // study rewards: the word egg grows, each skill is mastered, and study streaks
    case egg, picnic, cafe, gown, royal, dj, idol, detective, pilot, winter, beach, party
    // mastery rewards: every stage at three stars, then every other costume
    case starry, legend
    var id: String { rawValue }

    static let kids = ["ken", "rin"]

    func image(_ kid: String) -> String { self == .normal ? "\(kid)_full" : "\(kid)_\(rawValue)" }

    var name: String {
        switch self {
        case .normal: T("いつもの服", "평상복", "平常服")
        case .uniform: T("制服", "교복", "制服")
        case .street: T("ストリート", "스트리트", "街頭風")
        case .garden: T("ガーデン", "가든", "花園風")
        case .lab: T("研究者", "연구원", "研究員")
        case .pajama: T("にゃんこパジャマ", "냥이 잠옷", "貓咪睡衣")
        case .sports: T("スポーツウェア", "스포츠웨어", "運動服")
        case .suit: T("スーツ", "정장", "西裝")
        case .hero: T("ワーディアの勇者", "워디아의 용사", "沃迪亞的勇者")
        case .yukata: T("ゆかた", "유카타", "浴衣")
        case .egg: T("たまごパーカー", "달걀 후드티", "蛋蛋連帽衫")
        case .picnic: T("春のピクニック", "봄 피크닉", "春季野餐")
        case .cafe: T("ブックカフェ", "북카페", "書店咖啡")
        case .gown: T("卒業ガウン", "졸업 가운", "畢業袍")
        case .royal: kidRoyal
        case .dj: T("DJ", "DJ", "DJ")
        case .idol: T("アイドル", "아이돌", "偶像")
        case .detective: T("名探偵", "명탐정", "名偵探")
        case .pilot: T("パイロット", "파일럿", "機長")
        case .winter: T("冬のコート", "겨울 코트", "冬季大衣")
        case .beach: T("夏のビーチ", "여름 해변", "夏日海灘")
        case .party: T("パーティー", "파티", "派對")
        case .starry: T("星空の旅人", "별하늘 여행자", "星空旅人")
        case .legend: T("ワーディアの伝説", "워디아의 전설", "沃迪亞的傳說")
        }
    }
    private var kidRoyal: String { T("王子さま・お姫さま", "왕자님·공주님", "王子・公主") }

    /// how to get it (shown while locked)
    var condition: String {
        switch self {
        case .normal: ""
        case .uniform: T("Lv1を|クリア", "Lv1 클리어", "通關Lv1")
        case .street: T("Lv2を|クリア", "Lv2 클리어", "通關Lv2")
        case .garden: T("Lv5を|クリア", "Lv5 클리어", "通關Lv5")
        case .lab: T("Lv6を|クリア", "Lv6 클리어", "通關Lv6")
        case .pajama: T("おべんきょうを|3日する", "공부 3일 하기", "學習3天")
        case .sports: T("Lv3を|クリア", "Lv3 클리어", "通關Lv3")
        case .suit: T("Lv4を|クリア", "Lv4 클리어", "通關Lv4")
        case .hero: T("卒業を|クリア", "졸업 클리어", "通關畢業")
        case .yukata: T("プレミアム|限定", "프리미엄 한정", "高級版限定")
        case .egg: T("ことばのたまごを|10語|育てる", "단어 10개 익히기", "培育10個單字")
        case .picnic: T("ことばのたまごを|50語|育てる", "단어 50개 익히기", "培育50個單字")
        case .cafe: T("ことばのたまごを|200語|育てる", "단어 200개 익히기", "培育200個單字")
        case .gown: T("ことばのたまごを|500語|育てる", "단어 500개 익히기", "培育500個單字")
        case .royal: T("ことばのたまごを|1000語|育てる", "단어 1000개 익히기", "培育1000個單字")
        case .dj: T("リスニングで|100問|正解", "리스닝 100문제 정답", "聽力答對100題")
        case .idol: T("スピーキングで|100問|正解", "스피킹 100문제 정답", "口說答對100題")
        case .detective: T("書き取りで|100問|正解", "받아쓰기 100문제 정답", "聽寫答對100題")
        case .pilot: T("TOEIC模試で|500点|以上", "TOEIC 모의고사 500점 이상", "TOEIC模擬考500分以上")
        case .winter: T("べんきょうを|7日|連続", "공부 7일 연속", "連續學習7天")
        case .beach: T("べんきょうを|30日|連続", "공부 30일 연속", "連續學習30天")
        case .party: T("べんきょうを|100日|連続", "공부 100일 연속", "連續學習100天")
        case .starry: T("ぜんぶの|ステージで|★3", "모든 스테이지 ★3", "所有關卡★3")
        case .legend: T("ほかの|衣装を|ぜんぶ|集める", "다른 의상 모두 모으기", "收集其他所有服裝")
        }
    }

    /// longest study streak ever (so a broken streak keeps the costume)
    @MainActor static func bestStreak(_ app: AppState) -> Int {
        let now = app.study.streak, saved = UserDefaults.standard.integer(forKey: "study.bestStreak")
        if now > saved { UserDefaults.standard.set(now, forKey: "study.bestStreak") }
        return max(now, saved)
    }

    /// three stars on every stage of every area (any difficulty)
    static func allThreeStars(_ app: AppState) -> Bool {
        Area.allCases.allSatisfy { a in
            (1...a.stageCount).allSatisfy { i in
                Difficulty.allCases.contains { (app.progress.results[ProgressStore.key(StageRef(area: a, index: i, difficulty: $0))]?.stars ?? 0) >= 3 }
            }
        }
    }

    func unlocked(_ app: AppState) -> Bool {
        if app.dev.unlocks { return true }
        func cleared(_ a: Area) -> Bool { app.progress.clearedStages(in: a) >= a.stageCount }
        switch self {
        case .normal: return true
        case .uniform: return cleared(.lv1)
        case .street: return cleared(.lv2)
        case .garden: return cleared(.lv5)
        case .lab: return cleared(.lv6)
        case .pajama: return app.study.days.filter { $0.value > 0 }.count >= 3
        case .sports: return cleared(.lv3)
        case .suit: return cleared(.lv4)
        case .hero: return cleared(.graduation)
        case .yukata: return app.isPremium
        case .egg, .picnic, .cafe, .gown, .royal:
            let need = [Outfit.egg: 1, .picnic: 2, .cafe: 3, .gown: 4, .royal: 5][self] ?? 9
            return VocabPet.stage(app.vocab.masteredCount) >= need
        case .dj: return (app.study.skills["listening"]?[0] ?? 0) >= 100
        case .idol: return (app.study.skills["speaking"]?[0] ?? 0) >= 100
        case .detective: return (app.study.skills["writing"]?[0] ?? 0) >= 100
        case .pilot: return (app.study.best["toeicMock"] ?? 0) >= 500
        case .winter: return Outfit.bestStreak(app) >= 7
        case .beach: return Outfit.bestStreak(app) >= 30
        case .party: return Outfit.bestStreak(app) >= 100
        case .starry: return Outfit.allThreeStars(app)
        case .legend:
            // every other costume except the premium-only one
            return Outfit.allCases.allSatisfy { $0 == .legend || $0 == .yukata || $0.unlocked(app) }
        }
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
    @State private var kid = "ken"
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
            kidImage("ken", height: 250.s)
            Image("nyan").resizable().scaledToFit().frame(height: 108.s).padding(.horizontal, -6)
            kidImage("rin", height: 202.s)   // top of her head at Ken's eye level
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
                    Text(Cast(k).name).font(.en(18.s))
                        .foregroundStyle(kid == k ? Color.white : Color.ink)
                        .frame(maxWidth: .infinity, minHeight: 40.s)
                        .background(Capsule().fill(kid == k ? (k == "ken" ? Color.mintDeep : Color.popDeep) : Color.white)
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
                if o == .yukata && !app.isPremium { app.sheet = .shop }
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
