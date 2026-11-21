import SwiftUI

// MARK: - Data

struct GrammarLesson: Identifiable {
    let id: String
    let title: String
    let pattern: String
    let rule: String
}


@MainActor
enum Library {
    static let lessons: [GrammarLesson] = GrammarData.raw.split(separator: "\n").compactMap { line in
        let f = line.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        guard f.count == 8 else { return nil }
        let title = T(f[1], f[2], f[3])
        let rule = L10n.current == .ja ? f[5].replacingOccurrences(of: "／", with: "|") : T(f[5], f[6], f[7])
        return GrammarLesson(id: f[0], title: title, pattern: f[4], rule: rule)
    }

    static var words: [VocabWord] { Vocab.all }

    /// every question in the game (all areas) — the source of example sentences
    static let bank: [Question] = {
        var out: [Question] = []
        var seen = Set<String>()
        for a in Area.allCases {
            let p = QuestionBank.pools(for: a)
            for q in p.single + p.phrase + p.order + p.mid + p.boss where seen.insert(q.full).inserted { out.append(q) }
        }
        return out
    }()

    /// grammar point -> the area where it first appears (textbook chapters)
    static let chapter: [String: Area] = {
        var d: [String: Area] = [:]
        for a in Area.allCases {
            let p = QuestionBank.pools(for: a)
            for q in p.single + p.phrase + p.order + p.mid + p.boss where d[q.point] == nil { d[q.point] = a }
        }
        return d
    }()

    static func examples(for point: String, max n: Int = 4) -> [Question] {
        Array(bank.filter { $0.point == point }.sorted { $0.full.count < $1.full.count }.prefix(n))
    }

    static func examples(for e: VocabWord, max n: Int = 3) -> [Question] {
        let keys = Set([e.word.lowercased()] + e.forms)
        return Array(bank.filter { q in
            let ws = q.full.lowercased().split(whereSeparator: { !$0.isLetter && $0 != "'" }).map(String.init)
            return ws.contains { keys.contains($0) }
        }.sorted { $0.full.count < $1.full.count }.prefix(n))
    }

    static func posLabel(_ p: String) -> String {
        switch p {
        case "名": T("名詞", "명사", "名詞")
        case "動": T("動詞", "동사", "動詞")
        case "形": T("形容詞", "형용사", "形容詞")
        case "副": T("副詞", "부사", "副詞")
        case "前": T("前置詞", "전치사", "介系詞")
        case "接": T("接続詞", "접속사", "連接詞")
        case "代": T("代名詞", "대명사", "代名詞")
        case "助": T("助動詞", "조동사", "助動詞")
        case "冠": T("冠詞", "관사", "冠詞")
        default: p
        }
    }
}

// MARK: - Textbook

struct TextbookView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var app: AppState

    var body: some View {
        NavigationStack {
            List {
                ForEach(Area.allCases) { a in
                    let ls = Library.lessons.filter { (Library.chapter[$0.id] ?? .lv1) == a }
                    if !ls.isEmpty {
                        Section(a.levelLabel + "  " + jp(a.name)) {
                            ForEach(ls) { l in
                                NavigationLink { LessonView(lesson: l) } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(jp(l.title)).font(.ui(15))
                                            Text(l.pattern).font(.en(12)).foregroundStyle(.secondary).lineLimit(1)
                                        }
                                        Spacer()
                                        if weakCount(l.id) > 0 {
                                            Text("\(weakCount(l.id))").font(.en(12)).foregroundStyle(.white)
                                                .padding(.horizontal, 7).padding(.vertical, 2).background(Capsule().fill(Color.popDeep))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(PopBackdrop(base: Color(hex: 0xFFD66B), calm: true))
            .navigationTitle(jp(T("きょうほん", "교본", "教本")))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button { dismiss() } label: { Label(L("common.back"), systemImage: "chevron.left").labelStyle(.titleAndIcon) } } }
        }
    }
    private func weakCount(_ point: String) -> Int { app.study.weak.filter { $0.q.point == point }.count }
}

struct LessonView: View {
    let lesson: GrammarLesson
    @EnvironmentObject var app: AppState
    @State private var reviewing = false

    var body: some View {
        ScrollView {
            PaperCard { VStack(alignment: .leading, spacing: 14) {
                Text(jp(lesson.title)).font(.display(24)).foregroundStyle(Color.ink)
                Text(lesson.pattern).font(.en(18)).foregroundStyle(Color.ink)
                    .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.sun.opacity(0.35)).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.ink, lineWidth: 2)))
                Text(jp(lesson.rule)).font(.ui(16, bold: false)).foregroundStyle(Color.ink)
                    .fixedSize(horizontal: false, vertical: true)
                PopHeading(text: T("れいぶん", "예문", "例句")).padding(.top, 4)
                ForEach(Library.examples(for: lesson.id)) { q in ExampleRow(q: q) }
                let weak = app.study.weak.filter { $0.q.point == lesson.id }.count
                if weak > 0 {
                    Text(jp(T("この|ポイントで|まちがえた|問題が", "이 포인트에서 틀린 문제가 ", "這個重點答錯的題目有")) + " \(weak) " + jp(T("問|あります。|正解すると|数が|へって、|0に|なると|消えるよ。", "문제 있어요. 맞히면 줄어들고 0이 되면 사라져요.", "題。答對就會減少，變成0就會消失。")))
                        .font(.ui(13, bold: false)).foregroundStyle(Color.popDeep)
                    // straight into a review of just this grammar point
                    PopButton(title: T("この文法のまちがいを復習する", "이 문법의 틀린 문제 복습", "複習這個文法的錯題"), color: .pop, textColor: .white, height: 48) {
                        AudioManager.shared.se(.decide); StudyPool.point = lesson.id; reviewing = true
                    }
                }
            } }
            .padding(16)
        }
        .background(PopBackdrop(base: Color(hex: 0xFFD66B), calm: true))
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $reviewing, onDismiss: { StudyPool.point = nil }) {
            StudySessionView(mode: .review) { reviewing = false; StudyPool.point = nil; app.save() }
                .environmentObject(app)
        }
    }
}

struct ExampleRow: View {
    let q: Question
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button { Speaker.shared.say(q.full, gender: AppState.shared.settings.studyGender) } label: {
                Image(systemName: "speaker.wave.2.fill").font(.system(size: 15, weight: .bold)).foregroundStyle(Color.ink)
                    .frame(width: 36, height: 32)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.sun).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.ink, lineWidth: 2)))
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 2) {
                Text(q.full).font(.en(16)).foregroundStyle(Color.ink).fixedSize(horizontal: false, vertical: true)
                Text(jp(q.meaning)).font(.ui(13, bold: false)).foregroundStyle(Color.ink.opacity(0.65)).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Dictionary

struct DictionaryView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var level = 0

    private var hits: [VocabWord] {
        let base = level == 0 ? Library.words : Library.words.filter { $0.level == level }
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return base }
        let starts = base.filter { $0.word.lowercased().hasPrefix(q) || $0.forms.contains { $0.hasPrefix(q) } }
        let ids = Set(starts.map(\.id))
        let rest = base.filter { e in !ids.contains(e.id) && (e.word.lowercased().contains(q) || e.meaning.contains(q)) }
        return starts + rest
    }

    var body: some View {
        NavigationStack {
            List {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        chip(0, T("すべて", "전체", "全部"), .white)
                        ForEach(VocabLevel.allCases) { l in chip(l.rawValue, l.label, l.color) }
                    }
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                ForEach(hits) { e in
                NavigationLink { WordView(entry: e).environmentObject(app) } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        if let l = VocabLevel(rawValue: e.level) {
                            Text(l.label).font(.ui(9)).foregroundStyle(Color.ink).padding(.horizontal, 4).padding(.vertical, 1).background(Capsule().fill(l.color))
                        }
                        Text(e.word).font(.en(17)).foregroundStyle(Color.ink)
                        Text(Library.posLabel(e.pos)).font(.ui(10)).foregroundStyle(.white)
                            .padding(.horizontal, 5).padding(.vertical, 1).background(Capsule().fill(Color.sky))
                        Text(e.meaning).font(.ui(13, bold: false)).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                .listRowBackground(Color.white.opacity(0.92))
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(PopBackdrop(base: Color(hex: 0x9FD8FF), calm: true))
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always),
                        prompt: T("英語・意味で検索", "영어·뜻으로 검색", "用英文或意思搜尋"))
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .navigationTitle(jp(T("じしょ", "사전", "辭典")) + "  \(Library.words.count)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button { dismiss() } label: { Label(L("common.back"), systemImage: "chevron.left").labelStyle(.titleAndIcon) } } }
        }
    }

    private func chip(_ v: Int, _ t: String, _ c: Color) -> some View {
        Button { level = v } label: {
            Text(jp(t)).font(.ui(12)).foregroundStyle(Color.ink)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Capsule().fill(c).overlay(Capsule().stroke(level == v ? Color.ink : Color.ink.opacity(0.2), lineWidth: level == v ? 2 : 1)))
        }
        .buttonStyle(.plain)
    }
}

struct WordView: View {
    @EnvironmentObject var app: AppState
    let entry: VocabWord
    var body: some View {
        ScrollView {
            PaperCard { VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(entry.word).font(.en(34)).foregroundStyle(Color.ink)
                    Button { Speaker.shared.say(entry.word, gender: AppState.shared.settings.wordGender) } label: {
                        Image(systemName: "speaker.wave.2.fill").font(.system(size: 18, weight: .bold)).foregroundStyle(Color.ink)
                            .frame(width: 44, height: 38)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.sun).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.ink, lineWidth: 2.5)))
                    }
                    .buttonStyle(.plain)
                }
                Text(Library.posLabel(entry.pos)).font(.ui(12)).foregroundStyle(.white)
                    .padding(.horizontal, 8).padding(.vertical, 2).background(Capsule().fill(Color.sky))
                Text(entry.meaning).font(.ui(20)).foregroundStyle(Color.ink)
                if let b = app.vocab.box[entry.id] {
                    Text(b >= 4 ? jp(T("マスター済み", "마스터 완료", "已精通")) : jp(T("学習中", "학습 중", "學習中")) + " (\(b)/4)")
                        .font(.ui(12)).foregroundStyle(b >= 4 ? Color.mintDeep : Color.sky)
                }
                if !entry.forms.isEmpty {
                    Text(jp(T("変化形", "변화형", "變化形")) + "： " + entry.forms.joined(separator: ", "))
                        .font(.en(14)).foregroundStyle(Color.ink.opacity(0.7))
                }
                let ex = Library.examples(for: entry)
                if !ex.isEmpty {
                    PopHeading(text: T("れいぶん", "예문", "例句")).padding(.top, 6)
                    ForEach(ex) { q in ExampleRow(q: q) }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading) }
            .padding(16)
        }
        .background(PopBackdrop(base: Color(hex: 0xFFD66B), calm: true))
        .navigationBarTitleDisplayMode(.inline)
    }
}

