import SwiftUI

// MARK: - data (Content/story_ch1.json, made from 04_台本 by build_story.py)

struct NovelLine: Decodable, Hashable {
    var t: String                 // nar / say / choice / bg / still
    var ja: String? = nil
    var en: String? = nil
    var ko: String? = nil
    var zh: String? = nil
    var who: String? = nil        // nyan / partner / other
    var name: String? = nil       // the speaker's name when who == other
    var tip: Bool? = nil          // ニャンのミニ講座
    var img: String? = nil
    var options: [NovelOption]? = nil
}

struct NovelOption: Decodable, Hashable {
    var ja: String
    var en: String
    var ko: String? = nil
    var zh: String? = nil
    var ok: Bool
    var reply: [NovelLine]
}

struct NovelScene: Decodable, Hashable {
    var id: String
    var bg: String
    var lines: [NovelLine]
}

/// Who the player is: the name they typed and the partner they chose (ソラ or ユイ).
enum Traveler {
    private static let nameKey = "nyankana.playerName", partnerKey = "nyankana.partner"
    static var name: String {
        get { UserDefaults.standard.string(forKey: nameKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: nameKey) }
    }
    /// "sora" or "yui"; empty until chosen
    static var partner: String {
        get { UserDefaults.standard.string(forKey: partnerKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: partnerKey) }
    }
    static var isSora: Bool { partner != "yui" }
    static var partnerCast: Cast { isSora ? .ken : .rin }
    static var ready: Bool { !name.isEmpty && !partner.isEmpty }

    /// 〈名前〉 → the player's name; 〈A／B〉 → A for ソラ, B for ユイ
    static func fill(_ s: String) -> String {
        var out = s.replacingOccurrences(of: "〈名前〉", with: name.isEmpty ? "あなた" : name)
        while let open = out.range(of: "〈"), let close = out.range(of: "〉", range: open.upperBound..<out.endIndex) {
            let inner = String(out[open.upperBound..<close.lowerBound])
            let parts = inner.components(separatedBy: "／")
            let pick = parts.count == 2 ? (isSora ? parts[0] : parts[1]) : inner
            out.replaceSubrange(open.lowerBound..<close.upperBound, with: pick)
        }
        return out
    }
}

enum NovelBank {
    private static let ch1: [String: [NovelScene]] = {
        guard let url = Bundle.main.url(forResource: "story_ch1", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let d = try? JSONDecoder().decode([String: [NovelScene]].self, from: data) else { return [:] }
        return d
    }()
    private static let seenKey = "nyankana.seenScenes"
    private static var seen: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: seenKey) ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: seenKey) }
    }
    static func markSeen(_ scenes: [NovelScene]) { seen.formUnion(scenes.map { $0.id }) }

    /// Which scenes play before / after a stage of chapter 1 (each scene only the first time).
    /// The other chapters have no scenes yet (their scripts are translated next), so nothing is shown there.
    static func scenes(_ ref: StageRef, _ kind: StoryKind) -> [NovelScene] {
        guard ref.area == .lv1 else { return [] }
        let last = ref.index == ref.area.stageCount
        let ids: [String]
        switch (kind, ref.index) {
        case (.intro, 1): ids = (ch1["prologue"] ?? []).map { "p." + $0.id } + ["シーン1", "シーン2", "シーン2-a", "シーン3", "シーン4"]
        case (.intro, 3): ids = ["シーン5"]
        case (.intro, 5): ids = ["シーン5-a"]
        case (.outro, 6): ids = ["シーン6", "シーン7"]
        case (.intro, 9): ids = ["シーン8", "シーン8-a"]
        case (.intro, 13): ids = ["シーン9"]
        case (.intro, 17): ids = ["シーン10"]
        case (.intro, 21): ids = ["シーン11"]
        case (.intro, _) where last: ids = ["シーン11-a"]
        case (.outro, _) where last: ids = ["シーン12"]
        default: ids = []
        }
        let pro = Dictionary((ch1["prologue"] ?? []).map { ("p." + $0.id, NovelScene(id: "p." + $0.id, bg: $0.bg, lines: $0.lines)) }, uniquingKeysWith: { a, _ in a })
        let main = Dictionary((ch1["ch1"] ?? []).map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let s = seen
        return ids.compactMap { pro[$0] ?? main[$0] }.filter { !s.contains($0.id) }
    }
}

// MARK: - the novel screen

/// Story scenes like a visual novel: the picture on top, the Japanese line with the meaning under it,
/// choices that teach (a wrong answer gets a funny reply and the question again), auto / skip / log.
struct NovelView: View {
    let scenes: [NovelScene]
    let done: () -> Void

    private enum Step: Hashable { case scene(String), line(NovelLine) }
    @State private var steps: [Step] = []
    @State private var pos = 0
    @State private var background = ""
    @State private var still: String?
    @State private var auto = false
    @State private var showLog = false
    @State private var log: [(String, String, String)] = []
    @State private var setup = !Traveler.ready
    @State private var nameField = ""
    @State private var autoToken = 0
    @State private var finished = false

    private var current: NovelLine? {
        guard pos < steps.count, case .line(let l) = steps[pos] else { return nil }
        return l
    }

    var body: some View {
        GeometryReader { g in
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 0) {
                    stage.frame(width: g.size.width, height: min(g.size.height * 0.58, g.size.width * 9 / 16 * (g.size.width > g.size.height ? 1.6 : 1)))
                        .clipped()
                    textBox.frame(maxHeight: .infinity)
                }
                .contentShape(Rectangle())
                .onTapGesture { if current?.t != "choice" { advance() } }
                controls
                if setup { setupPanel }
            }
        }
        .onAppear(perform: start)
        .sheet(isPresented: $showLog) { logSheet }
    }

    // MARK: picture

    private var stage: some View {
        ZStack(alignment: .bottom) {
            if let img = UIImage(named: background) {
                Image(uiImage: img).resizable().scaledToFill()
            } else {
                LinearGradient(colors: [Color(hex: 0x2B3A67), Color(hex: 0xE9A9B8)], startPoint: .top, endPoint: .bottom)
                Text(background).font(.ui(13)).foregroundStyle(.white.opacity(0.75)).padding(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            if let s = still, let img = UIImage(named: s) {
                Image(uiImage: img).resizable().scaledToFill().transition(.opacity)
            }
            if let who = current?.who, still == nil {
                if who == "partner" {
                    Image(Traveler.partnerCast.image).resizable().scaledToFit().frame(maxHeight: .infinity).padding(.top, 20)
                        .transition(.opacity)
                } else if who == "nyan" {
                    Image("nyan").resizable().scaledToFit().frame(height: 150).padding(.bottom, 6)
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: current)
    }

    // MARK: words

    private var textBox: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let l = current {
                if l.t == "choice", let opts = l.options {
                    ForEach(opts, id: \.self) { o in
                        Button { pick(o, in: l) } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(Traveler.fill(o.ja)).font(.en(20)).foregroundStyle(Color.ink)
                                Text(Traveler.fill(sub(o.en, o.ko, o.zh))).font(.ui(12, bold: false)).foregroundStyle(Color.ink.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 14).fill(.white).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.ink, lineWidth: 2)))
                        }
                        .buttonStyle(PressStyle(radius: 14, depth: 3))
                    }
                } else {
                    if let n = speakerName(l) {
                        Text(n).font(.ui(15)).foregroundStyle(.white)
                            .padding(.horizontal, 12).padding(.vertical, 4)
                            .background(Capsule().fill(l.who == "nyan" ? Color.orange : l.who == "partner" ? Color.sky : Color.gray))
                    }
                    if l.tip == true {
                        Label(T("ニャンのミニ講座", "냥의 미니 강좌", "喵的迷你講座"), systemImage: "lightbulb.fill")
                            .font(.ui(12)).foregroundStyle(Color.orange)
                    }
                    Text(Traveler.fill(l.ja ?? "")).font(.en(l.t == "nar" ? 20 : 22))
                        .foregroundStyle(l.t == "nar" ? Color.white.opacity(0.92) : .white)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(Traveler.fill(sub(l.en, l.ko, l.zh))).font(.ui(14, bold: false))
                        .foregroundStyle(.white.opacity(0.65))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    HStack { Spacer(); Image(systemName: "chevron.down").foregroundStyle(.white.opacity(0.5)) }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(l_tipBackground)
    }

    private var l_tipBackground: some View {
        LinearGradient(colors: [Color(hex: 0x1D2240), Color(hex: 0x10142A)], startPoint: .top, endPoint: .bottom)
    }

    private var controls: some View {
        VStack {
            HStack(spacing: 8) {
                Spacer()
                pill(auto ? "AUTO ●" : "AUTO") { auto.toggle(); if auto { scheduleAuto() } }
                pill("LOG") { showLog = true }
                pill("SKIP") { finish() }
            }
            .padding(.horizontal, 12).padding(.top, 8)
            Spacer()
        }
    }

    private func pill(_ s: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(s).font(.ui(12)).foregroundStyle(.white)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Capsule().fill(.black.opacity(0.45)))
        }
    }

    private var logSheet: some View {
        NavigationStack {
            List(Array(log.enumerated()), id: \.offset) { _, e in
                VStack(alignment: .leading, spacing: 3) {
                    if !e.0.isEmpty { Text(e.0).font(.ui(12)).foregroundStyle(.secondary) }
                    Text(e.1).font(.en(17))
                    Text(e.2).font(.ui(12, bold: false)).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("LOG")
            .toolbar { Button(T("とじる", "닫기", "關閉")) { showLog = false } }
        }
    }

    // MARK: name and partner (asked once, before the very first scene)

    private var setupPanel: some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()
            VStack(spacing: 16) {
                Text(T("あなたの名前は？", "당신의 이름은?", "你的名字是？")).font(.ui(20)).foregroundStyle(.white)
                TextField("Name", text: $nameField)
                    .font(.ui(20)).multilineTextAlignment(.center)
                    .padding(12).background(RoundedRectangle(cornerRadius: 12).fill(.white))
                    .frame(maxWidth: 320)
                Text(T("いっしょに旅をする相棒", "함께 여행할 파트너", "一起旅行的夥伴")).font(.ui(16)).foregroundStyle(.white)
                HStack(spacing: 14) {
                    partnerButton("sora", image: "sora_smile", label: "ソラ")
                    partnerButton("yui", image: "yui_smile", label: "ユイ")
                }
            }
            .padding(24)
        }
    }

    private func partnerButton(_ id: String, image: String, label: String) -> some View {
        Button {
            let n = nameField.trimmingCharacters(in: .whitespaces)
            guard !n.isEmpty else { return }
            Traveler.name = n
            Traveler.partner = id
            withAnimation { setup = false }
            speakCurrent()
        } label: {
            VStack(spacing: 6) {
                Image(image).resizable().scaledToFit().frame(height: 200)
                Text(label).font(.ui(18)).foregroundStyle(.white)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.12)))
        }
        .opacity(nameField.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
    }

    // MARK: flow

    private func sub(_ en: String?, _ ko: String?, _ zh: String?) -> String {
        switch L10n.current {
        case .ko: ko ?? en ?? ""
        case .zhHant: zh ?? en ?? ""
        default: en ?? ""
        }
    }

    private func speakerName(_ l: NovelLine) -> String? {
        switch l.who {
        case "nyan": "ニャン"
        case "partner": Traveler.isSora ? "ソラ" : "ユイ"
        case "other": l.name
        default: nil
        }
    }

    private func start() {
        guard !scenes.isEmpty else { finished = true; done(); return }
        steps = scenes.flatMap { s in [Step.scene(s.bg)] + s.lines.map { Step.line($0) } }
        pos = 0
        settle()
        if !setup { speakCurrent() }
    }

    /// apply scene / picture steps until a line to show
    private func settle() {
        while pos < steps.count {
            switch steps[pos] {
            case .scene(let bg): background = bg; still = nil; pos += 1
            case .line(let l) where l.t == "bg": background = l.img ?? background; still = nil; pos += 1
            case .line(let l) where l.t == "still": withAnimation { still = l.img }; pos += 1
            default: return
            }
        }
        finish()
    }

    private func advance() {
        guard !setup, pos < steps.count else { return }
        if let l = current, l.t != "choice" {
            log.append((speakerName(l) ?? "", Traveler.fill(l.ja ?? ""), Traveler.fill(sub(l.en, l.ko, l.zh))))
        }
        pos += 1
        settle()
        speakCurrent()
    }

    private func pick(_ o: NovelOption, in choice: NovelLine) {
        log.append(("▶︎", Traveler.fill(o.ja), Traveler.fill(sub(o.en, o.ko, o.zh))))
        let hasRight = choice.options?.contains { $0.ok } ?? false
        var insert = o.reply.map { Step.line($0) }
        // a wrong answer: the funny reply, then the same question again
        if hasRight && !o.ok { insert.append(.line(choice)) }
        AudioManager.shared.se(.tap, rate: o.ok ? 1.3 : 0.9, volume: 0.4)
        steps.insert(contentsOf: insert, at: pos + 1)
        pos += 1
        settle()
        speakCurrent()
    }

    private func speakCurrent() {
        guard !setup, let l = current, l.t != "choice", let ja = l.ja else { return }
        let text = Traveler.fill(ja)
        switch l.who {
        case "nyan": Speaker.shared.say(text, voice: Cast.nyan.voice)
        case "partner": Speaker.shared.say(text, voice: Traveler.partnerCast.voice, gender: Traveler.isSora ? .male : .female)
        default: Speaker.shared.say(text)
        }
        if auto { scheduleAuto() }
    }

    private func scheduleAuto() {
        autoToken += 1
        let token = autoToken
        let wait = 1.6 + Double((current?.ja ?? "").count) * 0.13
        DispatchQueue.main.asyncAfter(deadline: .now() + wait) {
            guard auto, token == autoToken, current?.t != "choice" else { return }
            advance()
        }
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        Speaker.shared.stop()
        NovelBank.markSeen(scenes)
        done()
    }
}
