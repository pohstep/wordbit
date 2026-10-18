import AppKit
import AVFoundation
import Combine
import Foundation

enum AppTab: Hashable {
    case today, review, quiz, pictures, saved, settings

    var symbol: String {
        switch self {
        case .today: return Theme.CardKind.word.symbol
        case .review: return Theme.CardKind.review.symbol
        case .quiz: return Theme.CardKind.quiz.symbol
        case .pictures: return Theme.CardKind.pictures.symbol
        case .saved: return Theme.CardKind.saved.symbol
        case .settings: return "gearshape"
        }
    }

    var kind: Theme.CardKind? {
        switch self {
        case .today: return .word
        case .review: return .review
        case .quiz: return .quiz
        case .pictures: return .pictures
        case .saved: return .saved
        case .settings: return nil
        }
    }
}

struct ReviewCard: Codable, Equatable {
    var box: Int
    var due: String
}

struct StreakState: Codable, Equatable {
    var current: Int = 0
    var best: Int = 0
    var lastDay: String? = nil
}

struct SettingsState: Codable, Equatable {
    var showChinese: Bool = true
    var voiceIdentifier: String? = nil
    /// AVSpeechUtterance rate. 0.5 is the system default.
    var speechRate: Double = 0.5
    var dailyReminder: Bool = false
    /// Daily reminder clock time. Ignored until dailyReminder is on.
    var reminderHour: Int = 8
    var reminderMinute: Int = 0
    /// "auto", "en", or "zh-Hans". "auto" follows the Mac's first language.
    var interfaceLanguage: String = "auto"

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        showChinese = try container.decodeIfPresent(Bool.self, forKey: .showChinese) ?? true
        voiceIdentifier = try container.decodeIfPresent(String.self, forKey: .voiceIdentifier)
        speechRate = try container.decodeIfPresent(Double.self, forKey: .speechRate) ?? 0.5
        dailyReminder = try container.decodeIfPresent(Bool.self, forKey: .dailyReminder) ?? false
        let hour = try container.decodeIfPresent(Int.self, forKey: .reminderHour) ?? 8
        let minute = try container.decodeIfPresent(Int.self, forKey: .reminderMinute) ?? 0
        reminderHour = min(23, max(0, hour))
        reminderMinute = min(59, max(0, minute))
        let storedLanguage = try container.decodeIfPresent(String.self, forKey: .interfaceLanguage) ?? "auto"
        interfaceLanguage = InterfaceLanguage.normalized(storedLanguage)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(showChinese, forKey: .showChinese)
        try container.encodeIfPresent(voiceIdentifier, forKey: .voiceIdentifier)
        try container.encode(speechRate, forKey: .speechRate)
        try container.encode(dailyReminder, forKey: .dailyReminder)
        try container.encode(reminderHour, forKey: .reminderHour)
        try container.encode(reminderMinute, forKey: .reminderMinute)
        try container.encode(interfaceLanguage, forKey: .interfaceLanguage)
    }

    private enum CodingKeys: String, CodingKey {
        case showChinese, voiceIdentifier, speechRate, dailyReminder
        case reminderHour, reminderMinute, interfaceLanguage
    }
}

enum UpdateState: Equatable {
    case idle
    case checking
    case upToDate
    case available(version: String, page: String)
    case failed
}

struct FlagState: Codable, Equatable {
    var backfillDone: Bool = false
    var seenReviewOffer: String = "pending"
    var offerWords: [String] = []
    var didRegisterLoginItem: Bool = false
    var didAttemptLegacyLoginCleanup: Bool = false
}

struct DiskState: Codable, Equatable {
    var schema: Int = 2
    var seen: [String: String] = [:]
    var saved: [String] = []
    var review: [String: ReviewCard] = [:]
    var streak: StreakState = StreakState()
    var quizHistory: [String: Int] = [:]
    var settings: SettingsState = SettingsState()
    var flags: FlagState = FlagState()
}

enum ReviewGrade { case again, good, easy }

enum WeekDotStyle { case filled, ring, missed, upcoming }

struct WeekDot: Identifiable {
    var id: String { key }
    let key: String
    let letter: String
    let style: WeekDotStyle
}

struct QuizSession: Equatable {
    var dateKey: String
    var questions: [QuizQuestion]
    var index: Int
    var picked: Int?
    var results: [Bool]
    var finished: Bool
    var scoreLocked: Bool
    var savedScore: Int
    var revealing: Bool
}

struct PictureRound: Equatable {
    var dateKey: String
    var nonce: Int
    var questions: [PictureQuestion]
    var index: Int
    var picked: Int?
    var results: [Bool]
    var finished: Bool
}

struct VoiceChoice: Identifiable, Hashable {
    let identifier: String
    let label: String
    var id: String { identifier }
}

final class AppModel: ObservableObject {
    let library: WordLibrary
    let speech = SpeechController()
    @Published var disk = DiskState()
    @Published var tab: AppTab = .today
    @Published var dayOffset: Int = 0
    @Published var quiz: QuizSession?
    @Published var pictures: PictureRound?
    @Published var voices: [VoiceChoice] = []
    @Published var savedDetail: String?
    @Published var updateState: UpdateState = .idle
    @Published var resetNotice: String = ""
    private var loadedDay = ""

    init(library: WordLibrary) {
        self.library = library
    }

    static func storeURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        return base.appendingPathComponent("Wordbit", isDirectory: true).appendingPathComponent("state.json")
    }

    // MARK: Launch

    func bootstrap() {
        load()
        // New users start fresh: only today's word is marked seen.
        // Open at login stays off until the user turns it on in Settings.
        noteToday()
        loadedDay = LocalDay.key(Date())
        save()
        prepareVoices()
        let reminderOn = disk.settings.dailyReminder
        Reminder.restoreIfAuthorized(enabled: reminderOn) { [weak self] in
            self?.rescheduleReminderIfNeeded()
        }
    }

    func show(_ tab: AppTab) {
        self.tab = tab
        if tab == .quiz { ensureQuiz() }
        if tab == .pictures { ensurePictures() }
    }

    func refreshClock() {
        let key = LocalDay.key(Date())
        guard key != loadedDay else { return }
        loadedDay = key
        dayOffset = 0
        noteToday()
        save()
        quiz = nil
        pictures = nil
        ensureQuiz()
        ensurePictures()
    }

    // MARK: Today

    var displayedDate: Date { LocalDay.addDays(dayOffset, to: Date()) }

    var displayedEntry: WordEntry { library.entry(on: displayedDate) }

    var dateLabel: String { LocalDay.displayDate(displayedDate, locale: interfaceLocale) }

    func shiftDay(_ delta: Int) {
        let next = dayOffset + delta
        guard next <= 0 else { return }
        dayOffset = next
        markSeen(displayedEntry.word)
    }

    func goToday() {
        dayOffset = 0
    }

    func toggleChinese() {
        disk.settings.showChinese.toggle()
        save()
    }

    func isSaved(_ word: String) -> Bool { disk.saved.contains(word) }

    func reviewBox(_ word: String) -> Int? { disk.review[word]?.box }

    func toggleSaved(_ word: String) {
        if let index = disk.saved.firstIndex(of: word) {
            disk.saved.remove(at: index)
            if savedDetail == word { savedDetail = nil }
        } else {
            disk.saved.append(word)
            if disk.review[word] == nil {
                disk.review[word] = ReviewCard(box: 1, due: tomorrowKey())
            }
        }
        save()
    }

    func markSeen(_ word: String) {
        guard library.entry(for: word) != nil else { return }
        if disk.seen[word] == nil {
            disk.seen[word] = LocalDay.key(Date())
            save()
        }
    }

    func openSaved(_ word: String) {
        savedDetail = word
        markSeen(word)
    }

    func copyEntry(_ entry: WordEntry) {
        var lines = ["\(entry.word) (\(entry.pos))", entry.definition]
        if disk.settings.showChinese && !entry.cn.isEmpty { lines.append(entry.cn) }
        if !entry.example.isEmpty { lines.append("“\(entry.example)”") }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(lines.joined(separator: "\n"), forType: .string)
    }

    func speak(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        speech.speak(trimmed, voiceID: disk.settings.voiceIdentifier, rate: disk.settings.speechRate)
    }

    // MARK: Streak

    var countedToday: Bool { dayWasCounted(Date()) }

    func weekDots() -> [WeekDot] {
        let today = LocalDay.startOfDay(Date())
        let monday = LocalDay.addDays(-LocalDay.mondayIndex(today), to: today)
        let todayKey = LocalDay.key(today)
        let lastDate = disk.streak.lastDay.flatMap { LocalDay.date(from: $0) }.map { LocalDay.startOfDay($0) }
        let locale = interfaceLocale
        return (0..<7).map { offset in
            let date = LocalDay.addDays(offset, to: monday)
            let key = LocalDay.key(date)
            let style: WeekDotStyle
            if key == todayKey {
                style = dayWasCounted(date) ? .filled : .ring
            } else if dayWasCounted(date) {
                style = .filled
            } else if let lastDate = lastDate, date > lastDate && date < today {
                // Gap after the last counted day. Days before the streak
                // started stay faint; there are no freezes to mark.
                style = .missed
            } else {
                style = .upcoming
            }
            return WeekDot(key: key, letter: LocalDay.narrowWeekday(date, locale: locale), style: style)
        }
    }

    private func dayWasCounted(_ date: Date) -> Bool {
        guard disk.streak.current > 0,
              let lastKey = disk.streak.lastDay,
              let lastDate = LocalDay.date(from: lastKey) else { return false }
        let start = LocalDay.addDays(-(disk.streak.current - 1), to: lastDate)
        let day = LocalDay.startOfDay(date)
        return day >= LocalDay.startOfDay(start) && day <= LocalDay.startOfDay(lastDate)
    }

    private func markTodayCounted() {
        let today = LocalDay.key(Date())
        if disk.streak.lastDay == today { return }
        let yesterday = LocalDay.key(LocalDay.addDays(-1, to: Date()))
        if disk.streak.lastDay == yesterday {
            disk.streak.current += 1
        } else {
            disk.streak.current = 1
        }
        if disk.streak.current > disk.streak.best {
            disk.streak.best = disk.streak.current
        }
        disk.streak.lastDay = today
    }

    // MARK: Review

    func dueEntries() -> [(word: String, card: ReviewCard)] {
        let today = LocalDay.key(Date())
        return disk.review
            .filter { $0.value.due <= today }
            .map { (word: $0.key, card: $0.value) }
            .sorted { lhs, rhs in
                if lhs.card.due != rhs.card.due { return lhs.card.due < rhs.card.due }
                return lhs.word < rhs.word
            }
    }

    var dueCount: Int { dueEntries().count }

    /// First open: nothing saved, no quiz finished, streak still at zero.
    var showDayOneHint: Bool {
        disk.saved.isEmpty && disk.quizHistory.isEmpty && disk.streak.current == 0
    }

    var pendingOfferWords: [String] {
        guard disk.flags.seenReviewOffer == "pending" else { return [] }
        return disk.flags.offerWords.filter { disk.review[$0] == nil }.sorted()
    }

    func acceptOffer() {
        let words = pendingOfferWords
        for (index, word) in words.enumerated() {
            let spread = words.count > 40 ? index / 10 : 0
            disk.review[word] = ReviewCard(box: 1, due: LocalDay.key(LocalDay.addDays(1 + spread, to: Date())))
        }
        disk.flags.seenReviewOffer = "accepted"
        save()
    }

    func dismissOffer() {
        disk.flags.seenReviewOffer = "dismissed"
        save()
    }

    func grade(word: String, grade: ReviewGrade) {
        let hadDue = !dueEntries().isEmpty
        var card = disk.review[word] ?? ReviewCard(box: 1, due: LocalDay.key(Date()))
        switch grade {
        case .again:
            card.box = 1
        case .good:
            card.box = min(6, max(1, card.box) + 1)
        case .easy:
            card.box = min(6, max(1, card.box) + 2)
        }
        card.due = LocalDay.key(LocalDay.addDays(intervalDays(box: card.box), to: Date()))
        disk.review[word] = card
        if hadDue && dueEntries().isEmpty {
            markTodayCounted()
        }
        save()
    }

    private func intervalDays(box: Int) -> Int {
        let intervals = [1, 3, 7, 14, 30, 90]
        let index = min(6, max(1, box)) - 1
        return intervals[index]
    }

    // MARK: Quiz

    func ensureQuiz() {
        let key = LocalDay.key(Date())
        if quiz?.dateKey == key { return }
        let questions = QuizBuilder.build(
            words: library.words,
            todayIndex: library.index(on: Date()),
            seed: QuizBuilder.seed(for: key)
        )
        let existing = disk.quizHistory[key]
        quiz = QuizSession(
            dateKey: key,
            questions: questions,
            index: 0,
            picked: nil,
            results: [],
            finished: existing != nil,
            scoreLocked: existing != nil,
            savedScore: existing ?? 0,
            revealing: false
        )
    }

    func pickQuiz(option: Int) {
        guard var session = quiz, !session.finished, !session.revealing, session.picked == nil else { return }
        guard session.questions.indices.contains(session.index) else { return }
        let question = session.questions[session.index]
        guard option >= 0, option < question.options.count else { return }
        session.picked = option
        session.results.append(option == question.answerIndex)
        quiz = session
    }

    func advanceQuiz() {
        guard var session = quiz, session.picked != nil, !session.finished else { return }
        if session.index + 1 >= session.questions.count {
            let score = session.results.filter { $0 }.count
            if !session.scoreLocked {
                let key = LocalDay.key(Date())
                if disk.quizHistory[key] == nil {
                    disk.quizHistory[key] = score
                    markTodayCounted()
                    save()
                }
                session.scoreLocked = true
                session.savedScore = disk.quizHistory[key] ?? score
            }
            session.finished = true
            session.picked = nil
            quiz = session
        } else {
            session.index += 1
            session.picked = nil
            quiz = session
        }
    }

    func startReveal() {
        guard var session = quiz, session.finished else { return }
        session.revealing = true
        session.index = 0
        session.picked = nil
        quiz = session
    }

    func advanceReveal() {
        guard var session = quiz, session.revealing else { return }
        if session.index + 1 >= session.questions.count {
            session.revealing = false
            session.finished = true
            quiz = session
        } else {
            session.index += 1
            quiz = session
        }
    }

    // MARK: Pictures

    func ensurePictures() {
        let key = LocalDay.key(Date())
        if pictures?.dateKey == key { return }
        pictures = makePictureRound(dateKey: key, nonce: 0)
    }

    func replayPictures() {
        let key = LocalDay.key(Date())
        let nonce = (pictures?.nonce ?? 0) + 1
        pictures = makePictureRound(dateKey: key, nonce: nonce)
    }

    func pickPicture(option: Int) {
        guard var round = pictures, !round.finished, round.picked == nil else { return }
        guard round.questions.indices.contains(round.index) else { return }
        let question = round.questions[round.index]
        guard option >= 0, option < question.options.count else { return }
        round.picked = option
        round.results.append(option == question.answerIndex)
        pictures = round
    }

    func advancePicture() {
        guard var round = pictures, round.picked != nil, !round.finished else { return }
        if round.index + 1 >= round.questions.count {
            round.finished = true
            round.picked = nil
            pictures = round
        } else {
            round.index += 1
            round.picked = nil
            pictures = round
        }
    }

    private func makePictureRound(dateKey: String, nonce: Int) -> PictureRound {
        let questions = PictureBuilder.build(pictures: library.pictures, seedKey: "\(dateKey):\(nonce)")
        return PictureRound(
            dateKey: dateKey, nonce: nonce, questions: questions,
            index: 0, picked: nil, results: [], finished: false
        )
    }

    // MARK: Settings

    func prepareVoices() {
        let all = AVSpeechSynthesisVoice.speechVoices()
        let english = all.filter { $0.language.hasPrefix("en") }
        let rest = all.filter { !$0.language.hasPrefix("en") }
        let ordered = english.sorted { $0.name < $1.name } + rest.sorted {
            if $0.language != $1.language { return $0.language < $1.language }
            return $0.name < $1.name
        }
        voices = ordered.map { voice in
            VoiceChoice(identifier: voice.identifier, label: "\(voice.name) · \(voice.language)")
        }
    }

    func setVoice(_ identifier: String?) {
        disk.settings.voiceIdentifier = identifier
        save()
    }

    func setRate(_ rate: Double) {
        disk.settings.speechRate = min(0.6, max(0.35, rate))
        save()
    }

    func setReminder(_ on: Bool) {
        disk.settings.dailyReminder = on
        save()
        if on {
            Reminder.enable { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if !granted {
                        self.disk.settings.dailyReminder = false
                        self.save()
                    } else {
                        self.rescheduleReminderIfNeeded()
                    }
                }
            }
        } else {
            Reminder.disable()
        }
    }

    func setReminderTime(hour: Int, minute: Int) {
        let nextHour = min(23, max(0, hour))
        let nextMinute = min(59, max(0, minute))
        if disk.settings.reminderHour == nextHour && disk.settings.reminderMinute == nextMinute {
            return
        }
        disk.settings.reminderHour = nextHour
        disk.settings.reminderMinute = nextMinute
        save()
        if disk.settings.dailyReminder {
            rescheduleReminderIfNeeded()
        }
    }

    func setInterfaceLanguage(_ raw: String) {
        let next = InterfaceLanguage.normalized(raw)
        if disk.settings.interfaceLanguage == next {
            return
        }
        disk.settings.interfaceLanguage = next
        save()
        rescheduleReminderIfNeeded()
    }

    var appLanguage: AppLanguage {
        InterfaceLanguage.resolve(disk.settings.interfaceLanguage)
    }

    var resolvedLanguageCode: String {
        switch appLanguage {
        case .english: return InterfaceLanguage.english
        case .chinese: return InterfaceLanguage.chinese
        }
    }

    var interfaceLocale: Locale {
        InterfaceLanguage.locale(for: disk.settings.interfaceLanguage)
    }

    func tr(_ key: L10nKey) -> String {
        L10n.text(key, language: appLanguage)
    }

    func trf(_ key: L10nKey, _ args: CVarArg...) -> String {
        String(format: tr(key), arguments: args)
    }

    func tabTitle(_ tab: AppTab) -> String {
        switch tab {
        case .today: return tr(.tabToday)
        case .review: return tr(.tabReview)
        case .quiz: return tr(.tabQuiz)
        case .pictures: return tr(.tabPictures)
        case .saved: return tr(.tabSaved)
        case .settings: return tr(.tabSettings)
        }
    }

    func dueText(_ count: Int) -> String {
        if count <= 0 {
            return tr(.allClear)
        }
        return trf(.dueMany, count)
    }

    func rescheduleReminderIfNeeded() {
        guard disk.settings.dailyReminder else { return }
        Reminder.schedule(
            hour: disk.settings.reminderHour,
            minute: disk.settings.reminderMinute,
            title: tr(.notificationTitle),
            body: tr(.notificationBody)
        )
    }

    func checkForUpdates() {
        if case .checking = updateState {
            return
        }
        updateState = .checking
        let localVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        UpdateCheck.fetch(localVersion: localVersion) { [weak self] outcome in
            DispatchQueue.main.async {
                self?.updateState = outcome
            }
        }
    }

    func openUpdatePage() {
        if case .available(_, let page) = updateState {
            if let url = URL(string: page) {
                NSWorkspace.shared.open(url)
            }
        }
    }

    /// Asks first, then deletes only `state.json` and writes a fresh file.
    func confirmResetProgress() {
        resetNotice = ""
        let alert = NSAlert()
        alert.messageText = tr(.resetTitle)
        alert.informativeText = tr(.resetDetail)
        alert.alertStyle = .warning
        alert.addButton(withTitle: tr(.cancel))
        alert.addButton(withTitle: tr(.resetConfirm))
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if response != .alertSecondButtonReturn {
            return
        }
        if !deleteStateFile() {
            resetNotice = tr(.resetFailed)
            return
        }
        disk = DiskState()
        dayOffset = 0
        quiz = nil
        pictures = nil
        savedDetail = nil
        updateState = .idle
        noteToday()
        save()
        Reminder.disable()
    }

    private func deleteStateFile() -> Bool {
        let url = Self.storeURL()
        if url.lastPathComponent != "state.json" {
            return false
        }
        if url.deletingLastPathComponent().lastPathComponent != "Wordbit" {
            return false
        }
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                return false
            }
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                return false
            }
        }
        return true
    }

    func savedEntries(matching query: String) -> [WordEntry] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let entries = disk.saved.reversed().compactMap { library.entry(for: $0) }
        guard !trimmed.isEmpty else { return entries }
        return entries.filter {
            $0.word.lowercased().contains(trimmed)
                || $0.definition.lowercased().contains(trimmed)
                || $0.cn.contains(trimmed)
        }
    }

    // MARK: Persistence

    private func load() {
        let url = Self.storeURL()
        guard let data = try? Data(contentsOf: url) else {
            disk = DiskState()
            return
        }
        do {
            disk = try JSONDecoder().decode(DiskState.self, from: data)
        } catch {
            let bad = url.deletingLastPathComponent().appendingPathComponent("state.json.bad")
            try? FileManager.default.removeItem(at: bad)
            try? FileManager.default.moveItem(at: url, to: bad)
            disk = DiskState()
        }
    }

    private func save() {
        disk.schema = 2
        let url = Self.storeURL()
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(disk) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private func noteToday() {
        guard library.isUsable else { return }
        let entry = library.entry(on: Date())
        if disk.seen[entry.word] == nil {
            disk.seen[entry.word] = LocalDay.key(Date())
        }
        if disk.review[entry.word] == nil {
            disk.review[entry.word] = ReviewCard(box: 1, due: tomorrowKey())
        }
    }

    private func tomorrowKey() -> String {
        LocalDay.key(LocalDay.addDays(1, to: Date()))
    }
}
