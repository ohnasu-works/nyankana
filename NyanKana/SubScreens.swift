import SwiftUI

/// Common frame for sub screens: pop background, ribbon title, back chip.
struct SubScreen<Content: View>: View {
    var title: String
    var color: Color = .pop
    var bg: Color = Color(hex: 0x8FD0FF)
    @ViewBuilder var content: () -> Content
    @EnvironmentObject var app: AppState

    var body: some View {
        ZStack {
            PopBackdrop(base: bg)
            VStack(spacing: 14.s) {
                HStack(alignment: .bottom, spacing: 10.s) {
                    BackChip { app.go(.home) }
                    RibbonTitle(text: title, color: color)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14)
                .padding(.top, 6)
                content()
                    .frame(maxWidth: UIScale.isPad ? 760 : .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct ZukanView: View {
    @EnvironmentObject var app: AppState
    @State private var pick: ZukanEntry?
    @State private var tab = 0
    @State private var area: Area = .lv1
    @State private var reward: String?

    var body: some View {
        SubScreen(title: L("home.zukan"), color: .grass, bg: Color(hex: 0xB9EDB0)) {
            ScrollView {
                LazyVStack(spacing: 14.s) {
                    summary
                    tabs
                    switch tab {
                    case 0: stageTab
                    case 1:
                        section(T("ボス", "보스", "頭目"), ZukanEntry.bosses, big: true)
                        section(T("中ボス", "중간 보스", "中頭目"), ZukanEntry.mids, big: true)
                    case 2:
                        section(T("レアキャラ", "레어 캐릭터", "稀有角色"), ZukanEntry.rares, big: true)
                        section(T("イベントの敵", "이벤트 적", "活動敵人"), ZukanEntry.events, big: true)
                    default:
                        section(T("ゴブルズ", "고블스", "高布斯"), ZukanEntry.gobbles, big: false)
                    }
                }
                .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 30)
            }
        }
        .sheet(item: $pick) { e in detail(e).presentationDetents([.medium, .large]) }
        .overlay(alignment: .top) {
            if let r = reward {
                Text(r).font(.ui(15)).foregroundStyle(Color.ink).padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Capsule().fill(Color.sun).overlay(Capsule().stroke(Color.ink, lineWidth: 2.5)))
                    .padding(.top, 70).transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear { claimRewards(); AudioManager.shared.playBGM(.track("zukan")) }
    }

    // MARK: header

    private var registered: Int { ZukanEntry.everything.filter { app.progress.zukanSeen[$0.id, default: 0] > 0 }.count }

    private var summary: some View {
        let all = ZukanEntry.everything
        let seen = registered
        let saved = all.filter { app.progress.zukanSaved[$0.id, default: 0] > 0 }.count
        let shiny = all.filter { app.progress.zukanSeen[$0.id + "*", default: 0] > 0 }.count
        let next = ZukanReward.milestones.first { $0 > seen }
        return VStack(spacing: 8.s) {
            HStack(spacing: 10.s) {
                stat(T("であった", "만남", "遇見"), "\(seen)/\(all.count)")
                stat(T("たすけた", "구함", "救出"), "\(saved)")
                stat(T("色違い", "색이 다른", "異色"), "\(shiny)")
            }
            if let next {
                let prev = ZukanReward.milestones.last { $0 <= seen } ?? 0
                VStack(spacing: 3) {
                    Text(jp(T("次の|ごほうびまで", "다음 보상까지", "距離下個獎勵")) + " \(next - seen)").font(.ui(12.s)).foregroundStyle(Color.ink)
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white)
                            Capsule().fill(Color.sun).frame(width: g.size.width * CGFloat(seen - prev) / CGFloat(max(1, next - prev)))
                        }
                        .overlay(Capsule().stroke(Color.ink, lineWidth: 2))
                    }
                    .frame(height: 12.s)
                }
            }
            Text(jp(ZukanReward.title(seen))).font(.display(16.s)).foregroundStyle(Color.popDeep)
        }
    }

    private func stat(_ k: String, _ v: String) -> some View {
        VStack(spacing: 2) {
            Text(v).font(.en(22.s)).foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.6)
            Text(jp(k)).font(.ui(11.s)).foregroundStyle(Color.ink.opacity(0.6))
        }
        .frame(maxWidth: .infinity).padding(.vertical, 8.s)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.ink, lineWidth: 2.5)))
    }

    private var tabs: some View {
        HStack(spacing: 6.s) {
            tabButton(0, T("ステージ", "스테이지", "關卡"))
            tabButton(1, T("ボス", "보스", "頭目"))
            tabButton(2, T("レア", "레어", "稀有"))
            tabButton(3, T("ゴブルズ", "고블스", "高布斯"))
        }
    }

    private func tabButton(_ i: Int, _ t: String) -> some View {
        Button { AudioManager.shared.se(.tap); tab = i } label: {
            Text(jp(t)).font(.ui(13.s)).foregroundStyle(tab == i ? Color.white : Color.ink)
                .frame(maxWidth: .infinity, minHeight: 34.s)
                .background(Capsule().fill(tab == i ? Color.grass : Color.white).overlay(Capsule().stroke(Color.ink, lineWidth: 2)))
        }
        .buttonStyle(.plain)
    }

    // MARK: stage tab

    private var stageTab: some View {
        VStack(spacing: 12.s) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6.s) {
                    ForEach(Area.allCases) { a in
                        let list = StageFoes.area(a)
                        let got = list.filter { app.progress.zukanSeen[$0.id, default: 0] > 0 }.count
                        Button { AudioManager.shared.se(.tap); area = a } label: {
                            VStack(spacing: 0) {
                                Text(a.levelLabel).font(.en(13.s))
                                Text("\(got)/\(list.count)").font(.en(11.s)).opacity(0.7)
                            }
                            .foregroundStyle(Color.ink).padding(.horizontal, 10.s).padding(.vertical, 4.s)
                            .background(RoundedRectangle(cornerRadius: 10).fill(area == a ? Color.sun : Color.white).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.ink, lineWidth: area == a ? 2.5 : 1.5)))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            PaperCard {
                VStack(alignment: .leading, spacing: 8.s) {
                    PopHeading(text: T("ステージごとの|敵", "스테이지별 적", "各關卡的敵人"))
                    Text(jp(T("それぞれの|ステージにしか|出ない|敵だよ。|まだ会っていない|敵を|さがしに行こう！", "각 스테이지에만 나오는 적이야. 아직 못 만난 적을 찾으러 가자!", "只會出現在該關卡的敵人。去找還沒遇過的敵人吧！")))
                        .font(.ui(11.s, bold: false)).foregroundStyle(Color.ink.opacity(0.65))
                    ForEach(StageFoes.normalStages(area), id: \.self) { st in
                        let ids = StageFoes.exclusive(area, st)
                        let sp = Difficulty.allCases.compactMap { d in StageFoes.special(area, st, d).map { (d, $0) } }
                        let complete = (ids + sp.map { $0.1 }).allSatisfy { app.progress.zukanSeen[$0, default: 0] > 0 }
                        HStack(alignment: .top, spacing: 6.s) {
                            VStack(spacing: 0) {
                                Text("ST").font(.en(10.s)).opacity(0.6)
                                Text("\(st)").font(.en(18.s))
                                Group { if complete { UIIcon("ui_hanamaru|💮", size: 18.s) } }
                            }
                            .foregroundStyle(Color.ink).frame(width: 34.s)
                            VStack(spacing: 4.s) {
                                HStack(spacing: 6.s) {
                                    ForEach(ids, id: \.self) { id in
                                        if let e = ZukanEntry.stage(id) { cell(e, big: false) }
                                    }
                                }
                                HStack(spacing: 4.s) {
                                    ForEach(sp.indices, id: \.self) { k in
                                        if let e = ZukanEntry.stage(sp[k].1) {
                                            cell(e, big: false).overlay(alignment: .topLeading) { diffBadge(sp[k].0) }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 2.s)
                    }
                }
            }
            residentsRow(area)
        }
    }

    /// The area's residents, all in a grid at the bottom, each with the English words hidden in its name
    private func residentsRow(_ area: Area) -> some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 8.s) {
                PopHeading(text: jp(area.name) + "  " + jp(T("の住人", "의 주민", "的居民")))
                Text(jp(T("名前の|中に|英単語が|かくれているよ。|タップして|調べよう！", "이름 속에 영어 단어가 숨어 있어. 눌러서 알아보자!", "名字裡藏著英文單字。點一下看看！")))
                    .font(.ui(11.s, bold: false)).foregroundStyle(Color.ink.opacity(0.65))
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                    ForEach(ZukanEntry.area(area)) { e in cell(e, big: false) }
                }
            }
        }
    }

    // MARK: cells

    private func diffBadge(_ d: Difficulty) -> some View {
        let c: Color = d == .easy ? Color(hex: 0x6FD08C) : d == .normal ? Color(hex: 0x5BB8FF) : Color(hex: 0xFF5A5A)
        return Text(d.title).font(.en(9.5.s)).foregroundStyle(Color.white)
            .padding(.horizontal, 4).padding(.vertical, 1)
            .background(Capsule().fill(c).overlay(Capsule().stroke(Color.ink, lineWidth: 1.2)))
            .offset(x: -2, y: -4)
    }

    private func section(_ title: String, _ list: [ZukanEntry], big: Bool) -> some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 10.s) {
                PopHeading(text: title)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: big ? 3 : 4), spacing: 8) {
                    ForEach(list) { e in cell(e, big: big) }
                }
            }
        }
    }

    private func cell(_ e: ZukanEntry, big: Bool) -> some View {
        let seen = app.progress.zukanSeen[e.id, default: 0] > 0
        let saved = app.progress.zukanSaved[e.id, default: 0] > 0
        let shiny = app.progress.zukanSeen[e.id + "*", default: 0] > 0
        return Button { if seen { AudioManager.shared.se(.tap); pick = e } else if !e.meaning.isEmpty { AudioManager.shared.se(.boyon, volume: 0.5) } } label: {
            VStack(spacing: 2) {
                ZStack(alignment: .topTrailing) {
                    Image(e.image).resizable().scaledToFit()
                        .frame(height: (big ? 74 : 56).s)
                        .colorMultiply(seen ? .white : .black).opacity(seen ? 1 : 0.25)
                    HStack(spacing: 1) {
                        if shiny { UIIcon("ui_sparkle|✨", size: 11.s) }
                        if saved { Image(systemName: "heart.fill").font(.system(size: 11.s)).foregroundStyle(Color.popDeep) }
                    }
                }
                if !e.meaning.isEmpty {
                    // a word card: the English word big, its meaning below; not met yet -> the meaning is the hint
                    Text(seen ? e.name : "？？？").font(.en(13.s)).foregroundStyle(Color.ink.opacity(seen ? 1 : 0.6))
                        .lineLimit(1).minimumScaleFactor(0.5)
                    Text(jp(e.meaning)).font(.ui(11.s)).foregroundStyle(Color.popDeep)
                        .lineLimit(1).minimumScaleFactor(0.6)
                } else {
                    Text(seen ? e.name : (e.hint.isEmpty ? "？？？" : jp(e.hint))).font(.ui(11.s)).foregroundStyle(Color.ink.opacity(seen ? 1 : 0.6))
                        .lineLimit(1).minimumScaleFactor(0.6)
                    let parts = NameParts.short(e.name)
                    if seen && !parts.isEmpty {
                        Text(parts).font(.en(10.s)).foregroundStyle(Color.grape).lineLimit(1).minimumScaleFactor(0.6)
                    }
                }
            }
            .frame(maxWidth: .infinity).padding(6.s)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.ink.opacity(0.3), lineWidth: 1.5)))
        }
        .buttonStyle(.plain)
    }

    private func detail(_ e: ZukanEntry) -> some View {
        let saved = app.progress.zukanSaved[e.id, default: 0]
        let shiny = app.progress.zukanSeen[e.id + "*", default: 0] > 0
        return ScrollView {
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    Image(e.image).resizable().scaledToFit().frame(height: 150)
                    if shiny { Image(e.image).resizable().scaledToFit().frame(height: 150).hueRotation(.degrees(162)).overlay(alignment: .topTrailing) { UIIcon("ui_sparkle|✨", size: 30) } }
                    if let f = e.freed, saved > 0 { Image(systemName: "arrow.right").font(.title2.bold()); Image(f).resizable().scaledToFit().frame(height: 150) }
                }
                HStack(spacing: 10) {
                    Text(e.name).font(.en(28)).foregroundStyle(Color.ink)
                    Group {
                        Button { e.speak() } label: {
                            Image(systemName: "speaker.wave.2.fill").font(.system(size: 16, weight: .bold)).foregroundStyle(Color.ink)
                                .frame(width: 40, height: 34).background(RoundedRectangle(cornerRadius: 9).fill(Color.sun).overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.ink, lineWidth: 2)))
                        }
                        .buttonStyle(.plain)
                    }
                }
                if !e.meaning.isEmpty { Text(e.meaning).font(.ui(18)).foregroundStyle(Color.ink) }
                let parts = NameParts.of(e.name)
                if !parts.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(jp(T("名前の|ひみつ", "이름의 비밀", "名字的秘密"))).font(.ui(13)).foregroundStyle(Color.grape)
                        ForEach(parts.indices, id: \.self) { i in
                            HStack(spacing: 8) {
                                Button { Speaker.shared.say(parts[i].en.replacingOccurrences(of: "-", with: "")) } label: {
                                    Image(systemName: "speaker.wave.2.fill").font(.system(size: 12, weight: .bold)).foregroundStyle(Color.ink)
                                        .frame(width: 30, height: 26).background(RoundedRectangle(cornerRadius: 7).fill(Color.sun).overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.ink, lineWidth: 1.5)))
                                }
                                .buttonStyle(.plain)
                                Text(parts[i].en).font(.en(17)).foregroundStyle(Color.ink)
                                Text("＝ " + jp(parts[i].meaning)).font(.ui(14)).foregroundStyle(Color.ink.opacity(0.8))
                            }
                        }
                    }
                    .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.grape, lineWidth: 2)))
                }
                if !e.tag.isEmpty {
                    Text(jp(e.tag)).font(.ui(12)).foregroundStyle(.white).padding(.horizontal, 10).padding(.vertical, 3).background(Capsule().fill(Color.grape))
                }
                if !e.area.isEmpty { Text(jp(e.area)).font(.ui(14)).foregroundStyle(Color.ink.opacity(0.7)) }
                HStack(spacing: 20) {
                    Text(jp(T("であった", "만남", "遇見")) + " \(app.progress.zukanSeen[e.id, default: 0])").font(.ui(14))
                    Text(jp(T("たすけた", "구함", "救出")) + " \(saved)").font(.ui(14))
                }
                .foregroundStyle(Color.ink)
                if !e.lines.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        PopHeading(text: T("セリフ", "대사", "台詞"), color: .grape)
                        ForEach(Array(e.lines.enumerated()), id: \.offset) { _, l in
                            HStack(alignment: .top, spacing: 10) {
                                Button { Speaker.shared.say(l.en, voice: l.voice) } label: {
                                    Image(systemName: "speaker.wave.2.fill").font(.system(size: 14, weight: .bold)).foregroundStyle(Color.ink)
                                        .frame(width: 34, height: 30).background(RoundedRectangle(cornerRadius: 8).fill(Color.sun).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.ink, lineWidth: 2)))
                                }
                                .buttonStyle(.plain)
                                VStack(alignment: .leading, spacing: 2) {
                                    if !l.label.isEmpty { Text(jp(l.label)).font(.ui(10)).foregroundStyle(Color.ink.opacity(0.5)) }
                                    Text(l.en).font(.en(16)).foregroundStyle(Color.ink).fixedSize(horizontal: false, vertical: true)
                                    if !l.sub.isEmpty { Text(l.sub).font(.ui(12, bold: false)).foregroundStyle(Color.ink.opacity(0.65)).fixedSize(horizontal: false, vertical: true) }
                                }
                            }
                        }
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.ink, lineWidth: 2)))
                }
                if !shiny {
                    Text(jp(T("色違いは|まだ|見つかっていない…", "색이 다른 버전은 아직 못 찾았어…", "還沒找到異色版…"))).font(.ui(12, bold: false)).foregroundStyle(Color.ink.opacity(0.5))
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .background(Color.paper.ignoresSafeArea())
        .onAppear { e.speak() }                       // every entry says its name when opened
        .onDisappear { Speaker.shared.stop() }
    }

    // MARK: rewards

    private func claimRewards() {
        let seen = registered
        var claimed = UserDefaults.standard.integer(forKey: "zukan.claimed")
        var got: [String] = []
        for (i, m) in ZukanReward.milestones.enumerated() where m <= seen && i >= claimed {
            let k = ItemKind.allCases[i % ItemKind.allCases.count]
            var slots = app.progress.items
            while slots.count < 3 { slots.append("") }
            if let at = slots.prefix(3).firstIndex(where: { ItemKind(rawValue: $0) == nil }) { slots[at] = k.rawValue; app.progress.items = Array(slots.prefix(3)); got.append(k.name) }
            claimed = i + 1
        }
        guard claimed != UserDefaults.standard.integer(forKey: "zukan.claimed") else { return }
        UserDefaults.standard.set(claimed, forKey: "zukan.claimed")
        app.save()
        AudioManager.shared.se(.levelUp)
        withAnimation(.spring()) { reward = jp(T("図鑑の|ごほうび！", "도감 보상!", "圖鑑獎勵！")) + " " + got.joined(separator: "・") }
        later(2.6) { withAnimation { reward = nil } }
    }
}

/// One line in the picture book (English + subtitle, played with the speaker's voice).
struct ZukanLine {
    var label: String
    var en: String
    var sub: String
    var voice: Speaker.Voice?
    static func of(_ p: BossProfile) -> [ZukanLine] {
        func sub(_ l: BossProfile.L4) -> String { L10n.current == .ko ? l.ko : L10n.current == .zhHant ? l.zh : l.ja }
        return [
            ZukanLine(label: T("登場", "등장", "登場"), en: p.intro.en, sub: sub(p.intro), voice: p.voice),
            ZukanLine(label: T("ピンチ", "위기", "危機"), en: p.half.en, sub: sub(p.half), voice: p.voice),
            ZukanLine(label: T("たおされたとき", "쓰러졌을 때", "被打倒時"), en: p.out.en, sub: sub(p.out), voice: p.freeName.isEmpty ? p.voice : p.freeVoice),
        ]
    }
}

enum ZukanReward {
    static let milestones = [10, 25, 50, 80, 120, 160, 200, 250, 300, 350, 400, 450, 550, 650, 750, 850, 950]
    static func title(_ n: Int) -> String {
        switch n {
        case ..<25: T("ずかん|ビギナー", "도감 비기너", "圖鑑新手")
        case ..<80: T("ずかん|ハンター", "도감 헌터", "圖鑑獵人")
        case ..<200: T("ずかん|コレクター", "도감 컬렉터", "圖鑑收藏家")
        case ..<350: T("ずかん|はかせ", "도감 박사", "圖鑑博士")
        case ..<650: T("ずかん|マスター", "도감 마스터", "圖鑑大師")
        default: T("でんせつの|ずかん王", "전설의 도감왕", "傳說圖鑑王")
        }
    }
}

/// One picture-book entry (the id is the enemy picture name, the same key the game records).
struct ZukanEntry: Identifiable {
    let id: String
    var image: String { id }
    var name: String
    var area: String = ""
    var freed: String? = nil
    /// shown under the silhouette while not met yet (where to find it)
    var hint: String = ""
    var meaning: String = ""
    var tag: String = ""
    /// what this enemy says (bosses, mid bosses, possessed people)
    var lines: [ZukanLine] = []

    /// what the entry says when opened: its name, in its own voice
    var spoken: String {
        return name
    }
    var voice: Speaker.Voice {
        if let v = lines.first?.voice { return v }
        // names are English words to learn: read them in the normal, clear voice
        return .normal
    }
    func speak() { Speaker.shared.say(spoken, voice: voice) }

    static let bosses: [ZukanEntry] = Area.allCases.map { a in
        ZukanEntry(id: a.boss.image, name: a.boss.name, area: a.name, freed: a.boss.freeImage, hint: a.levelLabel, lines: ZukanLine.of(a.boss))
    }
    static let mids: [ZukanEntry] = Area.allCases.filter { $0 != .graduation }.flatMap { a in
        [10, 20].map { i in ZukanEntry(id: a.mid(i).image, name: a.mid(i).name, area: a.name, hint: a.levelLabel + "-\(i)", lines: ZukanLine.of(a.mid(i))) }
    }
    static let rares: [ZukanEntry] = GameEvents.rares.enumerated().map { ZukanEntry(id: $1, name: GameEvents.rareNames[$0], area: T("ごくまれに|あらわれる", "아주 드물게 나타남", "極少出現")) }
    static let events: [ZukanEntry] =
        GameEvents.kidnappers.map { ZukanEntry(id: $0, name: AreaFoes.names[$0] ?? "", area: T("人を|さらう", "사람을 납치함", "會綁架人")) }
        + GameEvents.possessed.map { p in ZukanEntry(id: p.monster, name: p.monsterName, area: T("取り憑かれた|町の人", "빙의된 마을 사람", "被附身的居民"), freed: p.normal,
            lines: (p.talk + [p.turn, p.freed]).map { ZukanLine(label: "", en: $0.en, sub: $0.sub, voice: nil) }) }
    static func area(_ a: Area) -> [ZukanEntry] { ((a.rawValue <= 3 ? EnemyTable.moji(a) : []) + EnemyTable.monsters(a)).map { ZukanEntry(id: $0, name: AreaFoes.names[$0] ?? "", area: a.name, hint: a.levelLabel) } }
    static func stage(_ id: String) -> ZukanEntry? {
        guard let i = StageFoes.byID[id] else { return nil }
        return ZukanEntry(id: i.id, name: i.en, area: i.area.levelLabel + " " + i.area.name + "  ST.\(i.stage)",
                          hint: i.area.levelLabel + "-\(i.stage)" + (i.diff.map { " " + $0.title } ?? ""), meaning: i.meaning, tag: i.typeLabel)
    }
    static let stageAll: [ZukanEntry] = StageFoes.all.compactMap { stage($0.id) }
    static var everything: [ZukanEntry] { bosses + mids + rares + events + Area.allCases.flatMap { area($0) } + stageAll + gobbles }
    static let gobbles: [ZukanEntry] =
        ((0..<16).map { String(format: "gob_%02d", $0) } + (0..<8).map { "kimo_b\($0)" } + (0..<8).map { "kimo_a\($0)" })
            .enumerated().map { i, id in
                // named after what they look like: the picture book teaches the word (No. shows while not met yet)
                let g = GobbleNames.table[id]
                return ZukanEntry(id: id, name: g?.en ?? "No.\(i + 1)", hint: "No.\(i + 1)", meaning: g?.meaning ?? "")
            }
}

struct RecordView: View {
    @EnvironmentObject var app: AppState
    @State private var lesson: GrammarLesson?

    var body: some View {
        SubScreen(title: L("home.record"), color: .sky) {
            ScrollView {
                VStack(spacing: 14.s) {
                    totals
                    analysisCard
                    PaperCard {
                        VStack(alignment: .leading, spacing: 10.s) {
                            PopHeading(text: T("ステージ", "스테이지", "關卡"))
                            ForEach(Area.allCases) { a in areaRow(a) }
                        }
                    }
                    PaperCard {
                        VStack(alignment: .leading, spacing: 8.s) {
                            PopHeading(text: T("おべんきょう", "공부", "學習"))
                            row(T("連続日数", "연속 일수", "連續天數"), "\(app.study.streak)")
                            row(T("勉強した日", "공부한 날", "學習天數"), "\(Set(app.study.visits).union(app.study.done.keys).count)")
                            row(T("はなまる", "꽃도장", "花丸"), "\(app.study.done.keys.filter { k in (app.study.done[k]?.count ?? 0) >= 3 }.count)")
                            row(T("にがてな問題", "약점 문제", "弱點題目"), "\(app.study.weak.count)")
                            row(T("60秒チャレンジ ベスト", "60초 챌린지 최고", "60秒挑戰 最佳"), "\(app.study.best["flash"] ?? 0)")
                            if app.toeicUnlocked { row("TOEIC Part 5 BEST", "\(app.study.best["toeic"] ?? 0)/10") }
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 30)
            }
        }
    }

    // MARK: self-analysis

    private struct SkillDef { let key: String; let name: String; let color: Color; let tip: String }
    private var skillDefs: [SkillDef] {[
        .init(key: "vocab", name: T("単語", "단어", "單字"), color: .mint, tip: T("「たんご|トレーニング」で|毎日|少しずつ", "「단어 트레이닝」으로 매일 조금씩", "用「單字訓練」每天一點點")),
        .init(key: "grammar", name: T("文法", "문법", "文法"), color: .sun, tip: T("「きょうほん」で|ルールを|読んでから|「にがて復習」へ", "「교본」으로 규칙을 읽고 「약점 복습」으로", "先讀「教本」的規則，再做「弱點複習」")),
        .init(key: "listening", name: T("リスニング", "리스닝", "聽力"), color: .pop, tip: T("勉強の|「リスニング」と|「書き取り」が|おすすめ", "공부의 「리스닝」과 「받아쓰기」를 추천", "推薦學習裡的「聽力」和「聽寫」")),
        .init(key: "writing", name: T("ライティング", "라이팅", "寫作"), color: .sky, tip: T("「書き取り」と|「ならべかえ」で|英文を|組み立てよう", "「받아쓰기」와 「순서 맞추기」로 문장을 만들자", "用「聽寫」和「重組句子」練習造句")),
        .init(key: "speaking", name: T("発音", "발음", "發音"), color: .grape, tip: T("「発音チャレンジ」と|「にがて音」で|声に|出そう", "「발음 챌린지」와 「어려운 소리」로 소리 내 보자", "用「發音挑戰」和「難發的音」大聲練習")),
    ]}

    private func rate(_ v: [Int]?) -> Double? { guard let v, v.count == 2, v[1] > 0 else { return nil }; return Double(v[0]) / Double(v[1]) }

    private var analysisCard: some View {
        let pts = app.study.points.compactMap { k, v -> (id: String, r: Double, n: Int)? in
            guard v.count == 2, v[1] >= 3 else { return nil }; return (k, Double(v[0]) / Double(v[1]), v[1])
        }
        let weak = pts.filter { $0.r < 0.8 }.sorted { $0.r < $1.r }.prefix(5)
        let strong = pts.filter { $0.r >= 0.85 }.sorted { $0.r > $1.r }.prefix(3)
        let lowest = skillDefs.compactMap { d -> (SkillDef, Double)? in
            guard let r = rate(app.study.skills[d.key]), (app.study.skills[d.key]?[1] ?? 0) >= 5 else { return nil }; return (d, r)
        }.min { $0.1 < $1.1 }
        return PaperCard {
            VStack(alignment: .leading, spacing: 10.s) {
                PopHeading(text: T("じぶん|分析", "자기 분석", "自我分析"))
                Text(jp(T("ゲームと|勉強で|答えた|問題から、|正解率を|出しています", "게임과 공부에서 답한 문제로 정답률을 계산해요", "根據遊戲和學習中作答的題目計算正確率")))
                    .font(.ui(12.s, bold: false)).foregroundStyle(Color.ink.opacity(0.6))
                // skills
                ForEach(skillDefs, id: \.key) { d in skillBar(d) }
                if let lowest {
                    HStack(alignment: .top, spacing: 8.s) {
                        Image("nyan").resizable().scaledToFit().frame(height: 44.s)
                        Text(jp(T("いちばんの|伸びしろは|「\(lowest.0.name)」！|", "가장 성장할 부분은 「\(lowest.0.name)」! ", "最有進步空間的是「\(lowest.0.name)」！", vi: "Phần dễ tiến bộ nhất: “\(lowest.0.name)”! ", es: "Donde más puedes mejorar: “\(lowest.0.name)”! ", pt: "Onde você mais pode melhorar: “\(lowest.0.name)”! ", en: "Most room to grow: “\(lowest.0.name)”! ") + lowest.0.tip))
                            .font(.ui(13.s)).foregroundStyle(Color.ink).fixedSize(horizontal: false, vertical: true)
                            .padding(10.s)
                            .background(RoundedRectangle(cornerRadius: 12.s).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 12.s).stroke(Color.ink, lineWidth: 2)))
                    }
                }
                // grammar points
                Text(jp(T("にがてな|文法", "약한 문법", "弱點文法"))).font(.display(17.s)).foregroundStyle(Color.popDeep).padding(.top, 4.s)
                if weak.isEmpty {
                    Text(jp(pts.isEmpty
                         ? T("問題を|もう少し|解くと、|にがてな|文法が|ここに|出ます", "문제를 조금 더 풀면 약한 문법이 여기에 나와요", "再多答一些題目，弱點文法就會出現在這裡")
                         : T("いまのところ、|にがてな|文法は|ありません。|すごい！", "지금은 약한 문법이 없어요. 대단해!", "目前沒有弱點文法。好厲害！")))
                        .font(.ui(13.s, bold: false)).foregroundStyle(Color.ink.opacity(0.65))
                } else {
                    ForEach(weak, id: \.id) { p in pointRow(p.id, p.r, p.n, weak: true) }
                }
                if !strong.isEmpty {
                    Text(jp(T("とくいな|文法", "강한 문법", "拿手文法"))).font(.display(17.s)).foregroundStyle(Color.mintDeep).padding(.top, 4.s)
                    ForEach(strong, id: \.id) { p in pointRow(p.id, p.r, p.n, weak: false) }
                }
            }
        }
        .sheet(item: $lesson) { l in NavigationStack { LessonView(lesson: l) }.environmentObject(app) }
        .onAppear { AudioManager.shared.playBGM(.track("record")) }
    }

    private func skillBar(_ d: SkillDef) -> some View {
        let v = app.study.skills[d.key]
        let r = rate(v)
        return HStack(spacing: 8.s) {
            Text(jp(d.name)).font(.ui(13.s)).foregroundStyle(Color.ink).frame(width: 92.s, alignment: .leading)
                .lineLimit(1).minimumScaleFactor(0.7)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.ink.opacity(0.1))
                    Capsule().fill(d.color).frame(width: g.size.width * CGFloat(r ?? 0))
                        .overlay(Capsule().stroke(Color.ink, lineWidth: r == nil ? 0 : 1.5))
                }
            }
            .frame(height: 14.s)
            Text(r.map { "\(Int(($0 * 100).rounded()))%" } ?? "—").font(.en(14.s)).foregroundStyle(Color.ink).frame(width: 46.s, alignment: .trailing)
        }
    }

    private func pointRow(_ id: String, _ r: Double, _ n: Int, weak: Bool) -> some View {
        let l = Library.lessons.first { $0.id == id }
        return Button { if let l { AudioManager.shared.se(.decide); lesson = l } } label: {
            HStack(spacing: 8.s) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(jp(l?.title ?? id)).font(.ui(14.s)).foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.7)
                    if let l { Text(l.pattern).font(.en(11.s)).foregroundStyle(Color.ink.opacity(0.55)).lineLimit(1) }
                }
                Spacer(minLength: 4)
                Text("\(Int((r * 100).rounded()))%").font(.en(17.s)).foregroundStyle(weak ? Color.popDeep : Color.mintDeep)
                Text("\(n)" + jp(T("問", "문", "題"))).font(.ui(11.s)).foregroundStyle(Color.ink.opacity(0.5))
                if l != nil && weak {
                    Text(jp(T("教本", "교본", "教本"))).font(.ui(11.s)).foregroundStyle(Color.ink)
                        .padding(.horizontal, 8.s).padding(.vertical, 3.s)
                        .background(Capsule().fill(Color.sun).overlay(Capsule().stroke(Color.ink, lineWidth: 1.5)))
                }
            }
            .padding(.horizontal, 10.s).padding(.vertical, 7.s)
            .background(RoundedRectangle(cornerRadius: 12.s).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 12.s).stroke(Color.ink.opacity(0.4), lineWidth: 1.5)))
        }
        .buttonStyle(.plain)
    }

    private var totals: some View {
        let r = app.progress.results.values
        let stars = r.reduce(0) { $0 + $1.stars }
        let best = r.map(\.bestScore).max() ?? 0
        return HStack(spacing: 10.s) {
            box("ui_star|⭐️", "\(stars)", T("スター", "스타", "星星"))
            box("ui_trophy|🏆", "\(best)", T("ベストスコア", "최고 점수", "最高分"))
            box("ui_check|✅", "\(app.study.totalCorrect)", T("正解した数", "정답 수", "答對數"))
        }
    }

    private func box(_ icon: String, _ v: String, _ k: String) -> some View {
        VStack(spacing: 2) {
            UIIcon(icon, size: 22.s)
            Text(v).font(.en(22.s)).foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.5)
            Text(jp(k)).font(.ui(11.s)).foregroundStyle(Color.ink.opacity(0.6))
        }
        .frame(maxWidth: .infinity).padding(.vertical, 10.s)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.ink, lineWidth: 2.5)))
    }

    private func areaRow(_ a: Area) -> some View {
        let n = app.progress.clearedStages(in: a)
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(a.levelLabel).font(.en(15.s)).foregroundStyle(Color.ink)
                Text(jp(a.name)).font(.ui(13.s)).foregroundStyle(Color.ink.opacity(0.7)).lineLimit(1)
                Spacer()
                Text("\(n)/\(a.stageCount)").font(.en(15.s)).foregroundStyle(n == a.stageCount ? Color.mintDeep : Color.ink)
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.ink.opacity(0.1))
                    Capsule().fill(n == a.stageCount ? Color.mint : Color.sky).frame(width: g.size.width * CGFloat(n) / CGFloat(a.stageCount))
                }
            }
            .frame(height: 8.s)
        }
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack { Text(jp(k)).font(.ui(14.s)).foregroundStyle(Color.ink.opacity(0.75)); Spacer(); Text(v).font(.en(18.s)).foregroundStyle(Color.ink) }
    }
}

// MARK: - Settings (with hidden developer mode)

struct SettingsView: View {
    @EnvironmentObject var app: AppState
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var dev: DevSettings
    @State private var taps = 0

    var body: some View {
        SubScreen(title: L("set.title"), color: .grape, bg: Color(hex: 0xD6C6FF)) {
            Form {
                Section(L("set.sound")) {
                    slider(L("set.bgm"), $settings.bgmVolume)
                    slider(L("set.se"), $settings.seVolume)
                    slider(L("set.voice"), $settings.voiceVolume)
                    Toggle(L("set.slow"), isOn: $settings.slowVoice)
                    Picker(T("敵を倒した時の声", "적을 쓰러뜨렸을 때 목소리", "打倒敵人時的聲音"), selection: $settings.gameVoice) {
                        Text(T("女性", "여성", "女聲")).tag("f")
                        Text(T("男性", "남성", "男聲")).tag("m")
                    }
                    .onChange(of: settings.gameVoice) { _, v in Speaker.shared.say("Hello", gender: v == "m" ? .male : .female) }
                    Picker(T("勉強モードの英文の声", "공부 모드 영문 목소리", "學習模式英文的聲音"), selection: $settings.studyVoice) {
                        Text(T("女性", "여성", "女聲")).tag("f")
                        Text(T("男性", "남성", "男聲")).tag("m")
                    }
                    Picker(T("単語を読む声", "단어를 읽는 목소리", "唸單字的聲音"), selection: $settings.wordVoice) {
                        Text(T("女性", "여성", "女聲")).tag("f")
                        Text(T("男性", "남성", "男聲")).tag("m")
                    }
                    Toggle(L("set.subtitles"), isOn: $settings.subtitles)
                }
                Section(L("set.answer")) {
                    Picker(L("set.answer"), selection: $settings.answerMode) {
                        ForEach(AnswerMode.allCases) { m in Label(m.title, systemImage: m.icon).tag(m) }
                    }
                    .pickerStyle(.segmented)
                    .id(settings.lang)   // the segment titles are cached by UIKit: rebuild them when the language changes
                    Picker(T("利き手（iPad・Macの横画面）", "주로 쓰는 손 (iPad·Mac 가로 화면)", "慣用手（iPad・Mac橫向畫面）"), selection: $settings.leftHanded) {
                        Text(T("右手", "오른손", "右手")).tag(false)
                        Text(T("左手", "왼손", "左手")).tag(true)
                    }
                }
                Section(L("set.lang")) {
                    Picker(L("set.lang"), selection: $settings.lang) {
                        Text(L("set.lang.auto")).tag("")
                        ForEach(L10n.allCases, id: \.rawValue) { l in Text(l.displayName).tag(l.rawValue) }
                    }
                }
                Section {
                    if !app.isPremium {
                        Button { AudioManager.shared.se(.tap); app.sheet = .shop } label: {
                            Label(L("home.shop"), systemImage: "crown.fill")
                        }
                    }
                    Button(L("set.restore")) { Task { await Store.shared.restore() } }
                    if AdManager.shared.privacyOptionsRequired && !app.isPremium {
                        Button(T("広告のプライバシー設定", "광고 개인정보 설정", "廣告隱私設定")) { Task { await AdManager.shared.showPrivacyOptions() } }
                    }
                    HStack {
                        Text(L("set.version"))
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        taps += 1
                        if taps >= 7 && DevSettings.allowed { dev.enabled.toggle(); taps = 0; AudioManager.shared.se(.levelUp) }
                    }
                }
                if dev.enabled && DevSettings.allowed { DevPanel() }
            }
            .font(.ui(15.s))
            .scrollContentBackground(.hidden)
        }
    }

    private func slider(_ title: String, _ v: Binding<Double>) -> some View {
        HStack { Text(title).frame(width: 110.s, alignment: .leading); Slider(value: v, in: 0...1) }
    }
}

// MARK: - Sheets

struct ItemListView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            List {
                ForEach(ItemKind.allCases) { k in
                    HStack(spacing: 14) {
                        UIIcon(k.icon, size: 30)
                            .frame(width: 52, height: 52)
                            .background(Circle().fill(Color.sun).overlay(Circle().stroke(Color.ink, lineWidth: 3)))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(k.name).font(.ui(17))
                            Text(jp(k.desc)).font(.ui(13, bold: false)).foregroundStyle(.secondary)
                            Text(k.voiceCommand).font(.en(13)).foregroundStyle(Color.popDeep)
                        }
                    }
                    .padding(.vertical, 4)
                }
                Text(jp(T("コインを|付けた敵を|助けると|もらえるよ。|金色の|ラッキーゴブルや、|おべんきょうの|合格でも|手に入る。|3つまで|持てて、|画面左下の|ボタンか|声で使えるよ。", "코인을 단 적을 구하면 받을 수 있어. 금색 럭키 고블이나 공부 합격으로도 얻을 수 있어. 3개까지 가질 수 있고, 화면 왼쪽 아래 버튼이나 목소리로 쓸 수 있어.", "救出帶著金幣的敵人就能得到。金色的幸運高布或學習合格也能獲得。最多可持有3個，用畫面左下的按鈕或聲音使用。"))).font(.ui(14, bold: false))
            }
            .navigationTitle(L("home.items"))
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button { dismiss() } label: { Label(L("common.back"), systemImage: "chevron.left").labelStyle(.titleAndIcon) } } }
        }
    }
}

struct HowToView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(jp(T("英語を|食べちゃう|ゴブルズが、|街から|英語を|奪っていく！|正しい英語を|「ことばの玉」にして|ぶつけて、|元に戻そう。|正解するたびに、|街に色が|戻るよ。", "영어를 먹어 버리는 고블스가 거리에서 영어를 빼앗아 가! 올바른 영어를 「말의 구슬」로 만들어 던져서 되돌리자. 정답을 맞힐 때마다 거리에 색이 돌아와.", "會吃掉英文的高布斯，正在從城鎮奪走英文！把正確的英文變成「語言球」丟出去，讓一切恢復原狀吧。每答對一題，城鎮就會恢復色彩。")))
                    Text(jp(T("メーターが|なくなると|敵が|攻撃してくる。|2体以上いるときは、|タップで|答える敵を|選べるよ。", "미터가 다 떨어지면 적이 공격해 와. 적이 2마리 이상일 때는 탭해서 답할 적을 고를 수 있어.", "計時條歸零時，敵人就會攻擊。有兩隻以上的敵人時，可以點選要回答的對象。")))
                    Text(jp(T("答え方は|選択・キーボード・|手書き・声の|4つ。|いつでも|切り替えられるよ。", "답하는 방법은 선택·키보드·손글씨·목소리 4가지. 언제든 바꿀 수 있어.", "作答方式有選擇、鍵盤、手寫、語音4種，隨時都能切換。")))
                }
                .font(.ui(16, bold: false))
                .padding(20)
            }
            .navigationTitle(L("home.howto"))
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button { dismiss() } label: { Label(L("common.back"), systemImage: "chevron.left").labelStyle(.titleAndIcon) } } }
        }
    }
}

struct ShopView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var store = Store.shared
    @EnvironmentObject var app: AppState
    var body: some View {
        NavigationStack {
            ZStack {
                Sunburst(a: Color(hex: 0xFFE27A), b: Color(hex: 0xFFC83D), center: .init(x: 0.5, y: 0.28), rays: 18).ignoresSafeArea()
                ViewThatFits(in: .vertical) {
                    content
                    ScrollView { content }
                }
            }
            .task { if store.product == nil { await store.load() } }
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button { dismiss() } label: { Label(L("common.back"), systemImage: "chevron.left").labelStyle(.titleAndIcon) } } }
        }
    }

    private var content: some View {
        VStack(spacing: 14.s) {
            // Sora and Yui (Yui travels in round 2, both in round 3), with Nyan in front
            ZStack(alignment: .bottom) {
                HStack(alignment: .bottom, spacing: -30.s) {
                    Image("sora_full").resizable().scaledToFit().frame(height: 200.s)
                    Image("yui_full").resizable().scaledToFit().frame(height: 184.s)
                }
                Image("nyan").resizable().scaledToFit().frame(height: 86.s).offset(x: 6.s, y: 8.s).bob()
            }
            .frame(maxWidth: .infinity)
            .overlay(alignment: .topTrailing) {
                if Store.onSale && !app.isPremium {
                    Text(jp(T("今だけ|半額", "지금만\n반값", "限時\n半價")))
                        .font(.display(17.s)).foregroundStyle(.white).multilineTextAlignment(.center)
                        .padding(12.s)
                        .background(Circle().fill(Color.popDeep).overlay(Circle().stroke(Color.ink, lineWidth: 3)))
                        .rotationEffect(.degrees(12))
                }
            }
            HStack(spacing: 6.s) {
                Image(systemName: "crown.fill").foregroundStyle(Color(hex: 0xFFB800))
                Text(L("home.shop")).font(.display(28.s)).foregroundStyle(Color.ink)
            }
            PaperCard {
                VStack(alignment: .leading, spacing: 8.s) {
                    perk("2.circle.fill", KJ.both("Round 2 with Yui: JLPT N5 words & kanji", "第2輪（結衣）：JLPT N5 的詞語與漢字", "2회차 유이: JLPT N5 단어・한자"))
                    perk("3.circle.fill", KJ.both("Round 3 with Sora & Yui: JLPT N4, no furigana", "第3輪（兩人）：JLPT N4，無注音", "3회차 둘이서: JLPT N4, 후리가나 없음"))
                    perk("bubble.left.and.bubble.right.fill", KJ.both("Conversations for real scenes", "實際場景的會話", "실제 장면의 회화"))
                    perk("nosign", KJ.both("No ads", "無廣告", "광고 없음"))
                    perk("cart.fill", KJ.both("Pay once (not a subscription)", "一次買斷（非月費）", "한 번만 결제 (구독 아님)"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            if app.isPremium {
                Text(jp(T("購入済み|です。|ありがとう！", "구매 완료. 고마워요!", "已購買，謝謝！"))).font(.ui(16.s)).foregroundStyle(Color.mintDeep)
            } else {
                VStack(spacing: 4.s) {
                    PopButton(title: store.busy ? "…" : store.priceLabel) { Task { await store.buy() } }
                        .disabled(store.busy)
                    if Store.onSale {
                        Text(jp(T("12月26日まで|半額。|12月27日から|通常価格に|なります", "12월 26일까지 반값 · 12월 27일부터 정상가", "12月26日前半價・12月27日起恢復原價")))
                            .font(.ui(12.s, bold: false)).foregroundStyle(Color.ink.opacity(0.75)).multilineTextAlignment(.center)
                    }
                }
            }
            if let n = store.notice {
                Text(jp(n)).font(.ui(13.s, bold: false)).foregroundStyle(Color.popDeep).multilineTextAlignment(.center)
            }
            Button(L("set.restore")) { Task { await store.restore() } }.font(.ui(14.s)).foregroundStyle(Color.ink.opacity(0.7))
        }
        .frame(maxWidth: 460.s)
        .padding(.horizontal, 22)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
    }

    private func perk(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 10.s) {
            Image(systemName: icon).font(.system(size: 16.s, weight: .bold)).foregroundStyle(Color.popDeep).frame(width: 24.s)
            Text(jp(text)).font(.ui(15.s)).foregroundStyle(Color.ink).fixedSize(horizontal: false, vertical: true)
        }
    }
}
