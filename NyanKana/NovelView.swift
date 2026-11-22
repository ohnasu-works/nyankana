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
    @State private var slow = AppState.shared.settings.slowVoice
    @State private var lastSaid: NovelLine?
    @State private var metPartner = UserDefaults.standard.bool(forKey: "nyankana.metPartner")
    @State private var metNyan = UserDefaults.standard.bool(forKey: "nyankana.metNyan")

    private var current: NovelLine? {
        guard pos < steps.count, case .line(let l) = steps[pos] else { return nil }
        return l
    }

    var body: some View {
        GeometryReader { g in
            let boxH = max(170, g.size.height * 0.25)
            ZStack(alignment: .bottom) {
                backdrop(g)
                if still == nil { cast(g, boxH: boxH) }
                if let l = current, l.t == "choice", let opts = l.options {
                    choices(opts, in: l).padding(.bottom, boxH + 12)
                }
                textBox.frame(height: boxH)
                controls
                if setup { setupPanel }
            }
            .frame(width: g.size.width, height: g.size.height)
            .contentShape(Rectangle())
            .onTapGesture { if current?.t != "choice" { advance() } }
        }
        .ignoresSafeArea()
        .onAppear(perform: start)
        .sheet(isPresented: $showLog) { logSheet }
    }

    // MARK: picture (fills the whole screen in portrait too: the middle of the wide picture)

    @ViewBuilder private func backdrop(_ g: GeometryProxy) -> some View {
        ZStack {
            Color.black
            if let img = UIImage(named: background) {
                Image(uiImage: img).resizable().scaledToFill()
                    .frame(width: g.size.width, height: g.size.height).clipped()
            } else {
                LinearGradient(colors: [Color(hex: 0x2B3A67), Color(hex: 0xE9A9B8)], startPoint: .top, endPoint: .bottom)
            }
            if let s = still, let img = UIImage(named: s) {
                // a key scene: blurred copy behind, the whole picture on top
                Image(uiImage: img).resizable().scaledToFill()
                    .frame(width: g.size.width, height: g.size.height).clipped()
                    .blur(radius: 22).overlay(Color.black.opacity(0.25))
                Image(uiImage: img).resizable().scaledToFit()
                    .frame(maxWidth: g.size.width - 24, maxHeight: g.size.height * 0.62)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .black.opacity(0.45), radius: 12, y: 6)
                    .frame(maxHeight: .infinity, alignment: .center)
                    .padding(.bottom, g.size.height * 0.18)
                    .transition(.opacity)
            }
            LinearGradient(colors: [.clear, .black.opacity(0.55)], startPoint: .center, endPoint: .bottom)
        }
        .frame(width: g.size.width, height: g.size.height)
        .animation(.easeInOut(duration: 0.3), value: still)
    }

    /// ソラ / ユイ on the left and Nyan on the right are always there once met; the one speaking stands out.
    @ViewBuilder private func cast(_ g: GeometryProxy, boxH: CGFloat) -> some View {
        let who = current?.who
        HStack(alignment: .bottom, spacing: 0) {
            if metPartner {
                Image(partnerFace).resizable().scaledToFit()
                    .frame(maxWidth: g.size.width * 0.62, maxHeight: g.size.height * 0.6)
                    .brightness(who == "partner" ? 0 : -0.22)
                    .scaleEffect(who == "partner" ? 1.03 : 1, anchor: .bottom)
                    .offset(y: who == "partner" ? -6 : 0)
            }
            Spacer(minLength: 0)
            if metNyan {
                Image(nyanFace).resizable().scaledToFit()
                    .frame(maxWidth: g.size.width * 0.4, maxHeight: g.size.height * 0.32)
                    .brightness(who == "nyan" ? 0 : -0.22)
                    .scaleEffect(who == "nyan" ? 1.06 : 1, anchor: .bottom)
                    .offset(y: who == "nyan" ? -8 : 0)
            }
        }
        .padding(.horizontal, 6)
        .padding(.bottom, boxH - 18)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: current)
    }

    /// a face for the line: the words give the feeling (！ happy, ！？ surprised, …… sad or thinking)
    private func mood(_ text: String) -> String {
        if text.contains("!?") || text.contains("！？") || text.contains("えっ") || text.contains("うわ") { return "surprised" }
        if text.contains("ごめん") || text.contains("さびし") || text.contains("泣") { return "sad" }
        if text.hasPrefix("……") || text.contains("かな") || text.hasSuffix("？") { return "think" }
        if text.contains("！") || text.contains("!") || text.contains("うれし") || text.contains("よかった") { return "smile" }
        return "full"
    }
    private var partnerFace: String {
        let base = Traveler.isSora ? "sora" : "yui"
        guard let l = current, l.who == "partner", let t = l.ja else { return base + "_full" }
        return base + "_" + mood(t)
    }
    private var nyanFace: String {
        guard let l = current, l.who == "nyan", let t = l.ja else { return "nk_nyan" }
        if l.tip == true { return "nk_nyan_tip" }
        switch mood(t) {
        case "surprised": return "nk_nyan_surprised"
        case "sad": return "nk_nyan_sad"
        case "think": return "nk_nyan_think"
        case "smile": return "nk_nyan_joy"
        default: return t.contains("オレ") ? "nk_nyan_proud" : "nk_nyan"
        }
    }

    // MARK: words (over the picture)

    private func choices(_ opts: [NovelOption], in l: NovelLine) -> some View {
        VStack(spacing: 10) {
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
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: 560)
    }

    private var textBox: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let l = current {
                // a choice: the question stays in the box (the previous line), the answers float above
                let shown: NovelLine? = l.t == "choice" ? lastSaid : l
                if let shown {
                    HStack(spacing: 8) {
                        if let n = speakerName(shown) {
                            Text(n).font(.ui(15)).foregroundStyle(.white)
                                .padding(.horizontal, 12).padding(.vertical, 4)
                                .background(Capsule().fill(shown.who == "nyan" ? Color.orange : shown.who == "partner" ? Color.sky : Color.gray))
                        }
                        if shown.tip == true {
                            Label(T("ニャンのミニ講座", "냥의 미니 강좌", "喵的迷你講座"), systemImage: "lightbulb.fill")
                                .font(.ui(12)).foregroundStyle(Color.orange)
                        }
                    }
                    Text(Traveler.fill(shown.ja ?? "")).font(.en(shown.t == "nar" ? 20 : 22))
                        .foregroundStyle(shown.t == "nar" ? Color.white.opacity(0.9) : .white)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(Traveler.fill(sub(shown.en, shown.ko, shown.zh))).font(.ui(14, bold: false))
                        .foregroundStyle(.white.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                if l.t != "choice" {
                    HStack { Spacer(); Image(systemName: "chevron.down").foregroundStyle(.white.opacity(0.5)) }
                }
            }
        }
        .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 22).fill(Color.black.opacity(0.66)).padding(.horizontal, 8).padding(.bottom, 8))
    }

    private var controls: some View {
        VStack {
            HStack(spacing: 8) {
                Spacer()
                pill(slow ? "🐢 ON" : "🐢") {
                    slow.toggle()
                    AppState.shared.settings.slowVoice = slow
                    speakCurrent()
                }
                pill(auto ? "AUTO ●" : "AUTO") { auto.toggle(); if auto { scheduleAuto() } }
                pill("LOG") { showLog = true }
                pill("SKIP") { finish() }
            }
            .padding(.horizontal, 12).padding(.top, 54)
            Spacer()
        }
    }

    private func pill(_ s: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(s).font(.ui(13)).foregroundStyle(.white)
                .padding(.horizontal, 13).padding(.vertical, 7)
                .background(Capsule().fill(.black.opacity(0.5)))
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
            case .scene(let bg): if !bg.isEmpty { background = bg }; still = nil; pos += 1
            case .line(let l) where l.t == "bg": background = l.img ?? background; still = nil; pos += 1
            case .line(let l) where l.t == "still": withAnimation { still = l.img.map { $0.replacingOccurrences(of: "{P}", with: Traveler.isSora ? "ソラ" : "ユイ") } }; pos += 1
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
        if let l = current, l.t != "choice" {
            lastSaid = l
            if l.who == "partner", !metPartner { metPartner = true; UserDefaults.standard.set(true, forKey: "nyankana.metPartner") }
            if l.who == "nyan", !metNyan { metNyan = true; UserDefaults.standard.set(true, forKey: "nyankana.metNyan") }
        }
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
