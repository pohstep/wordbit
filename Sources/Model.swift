import Foundation

// MARK: - Calendar
//
// The word for a calendar date is the number of days since 2026-01-01, same
// order as v1, always in the Mac's own time zone. Saved dates are plain
// "yyyy-MM-dd" strings, so they carry over.

enum LocalDay {
    static var timeZone: TimeZone {
        TimeZone.current
    }

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    static var epoch: Date {
        var parts = DateComponents()
        parts.year = 2026
        parts.month = 1
        parts.day = 1
        parts.timeZone = timeZone
        return calendar.date(from: parts)!
    }

    static func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    /// Days from 2026-01-01 in the Mac's time zone. 1 Jan 2026 is 0, matching v1.
    static func dayNumber(_ date: Date) -> Int {
        calendar.dateComponents([.day], from: startOfDay(epoch), to: startOfDay(date)).day ?? 0
    }

    static func key(_ date: Date) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    static func date(from key: String) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        var components = DateComponents()
        components.year = parts[0]
        components.month = parts[1]
        components.day = parts[2]
        components.timeZone = timeZone
        return calendar.date(from: components)
    }

    static func addDays(_ days: Int, to date: Date) -> Date {
        calendar.date(byAdding: .day, value: days, to: startOfDay(date)) ?? date
    }

    /// Monday = 0 ... Sunday = 6.
    static func mondayIndex(_ date: Date) -> Int {
        let weekday = calendar.component(.weekday, from: date) // 1 = Sunday
        return (weekday + 5) % 7
    }

    /// Locale order comes from `locale` (the Mac's locale, or the language
    /// the user picked). The template is not a fixed British day-month string.
    static func displayDate(_ date: Date, locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.setLocalizedDateFormatFromTemplate("EEEEMMMMd")
        return formatter.string(from: date)
    }

    /// One short weekday mark, Sunday-first, in `locale`.
    static func narrowWeekday(_ date: Date, locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        let symbols = formatter.veryShortWeekdaySymbols ?? []
        let weekday = calendar.component(.weekday, from: date)
        let index = weekday - 1
        if index >= 0 && index < symbols.count {
            return symbols[index]
        }
        return ""
    }
}

// MARK: - Bundled entries

struct WordEntry: Codable, Identifiable, Equatable {
    var id: String { word }
    let word: String
    let ipa: String
    let pos: String
    let definition: String
    let example: String
    let origin: String
    let cn: String
    let source: String

    static let missing = WordEntry(
        word: "missing", ipa: "", pos: "",
        definition: "words.json could not be loaded.",
        example: "", origin: "", cn: "", source: ""
    )
}

struct PictureEntry: Codable, Identifiable, Equatable {
    var id: String { word }
    let word: String
    let glyph: String
    let cn: String
    let distractorGroup: String
    let level: Int
    let symbol: String
    /// Hand-picked look-alike or same-category wrong answers (plain words).
    let distractors: [String]?
}

final class WordLibrary {
    let words: [WordEntry]
    let pictures: [PictureEntry]
    let failed: Bool
    private let byLower: [String: WordEntry]

    var isUsable: Bool { !failed && words.count == 400 }

    init() {
        let loadedWords = WordLibrary.load([WordEntry].self, "words")
        let loadedPictures = WordLibrary.load([PictureEntry].self, "pictures")
        if let loadedWords = loadedWords, !loadedWords.isEmpty {
            words = loadedWords
            failed = false
        } else {
            words = []
            failed = true
        }
        pictures = loadedPictures ?? []
        var index: [String: WordEntry] = [:]
        for entry in words {
            index[entry.word.lowercased()] = entry
        }
        byLower = index
    }

    func index(on date: Date) -> Int {
        let count = words.count
        guard count > 0 else { return 0 }
        let day = LocalDay.dayNumber(date)
        return ((day % count) + count) % count
    }

    func entry(on date: Date) -> WordEntry {
        guard !words.isEmpty else { return .missing }
        return words[index(on: date)]
    }

    func entry(for word: String) -> WordEntry? {
        byLower[word.lowercased()]
    }

    private static func load<T: Decodable>(_ type: T.Type, _ name: String) -> T? {
        guard let url = resourceURL(name, "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private static func resourceURL(_ name: String, _ ext: String) -> URL? {
        if let url = Bundle.main.url(forResource: name, withExtension: ext) {
            return url
        }
        if let override = ProcessInfo.processInfo.environment["WORD_RESOURCES"] {
            let url = URL(fileURLWithPath: override).appendingPathComponent("\(name).\(ext)")
            if FileManager.default.fileExists(atPath: url.path) { return url }
        }
        return nil
    }
}

// MARK: - Seeded random (stable for a date)

struct SplitMix64: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

func fnv64(_ text: String) -> UInt64 {
    var hash: UInt64 = 14695981039346656037
    for byte in text.utf8 {
        hash ^= UInt64(byte)
        hash = hash &* 1099511628211
    }
    return hash == 0 ? 0x9E3779B97F4A7C15 : hash
}

// MARK: - Quiz

struct QuizQuestion: Identifiable, Equatable {
    enum Kind: Equatable { case meaning, blank }
    var id: String { word }
    let word: String
    let kind: Kind
    /// Masked example for a blank question. Empty for a meaning question.
    let prompt: String
    let options: [String]
    let answerIndex: Int
}

enum QuizBuilder {
    static func seed(for dayKey: String) -> UInt64 {
        fnv64("wordbit-quiz-v1:" + dayKey)
    }

    static func build(words: [WordEntry], todayIndex: Int, seed: UInt64) -> [QuizQuestion] {
        guard words.count >= 8, todayIndex >= 0, todayIndex < words.count else { return [] }
        var rng = SplitMix64(state: seed)
        var pool = words.indices.filter { $0 != todayIndex }
        pool.shuffle(using: &rng)
        var picked = [todayIndex]
        // Two study words share one definition. A quiz must not ask both,
        // or the same answer text would appear twice.
        var usedDefinitions = Set([words[todayIndex].definition])
        for index in pool where picked.count < 5 {
            let definition = words[index].definition
            if usedDefinitions.contains(definition) { continue }
            picked.append(index)
            usedDefinitions.insert(definition)
        }
        picked.shuffle(using: &rng)

        let bannedWords = Set(picked.map { words[$0].word.lowercased() })
        let bannedDefinitions = Set(picked.map { words[$0].definition })
        var questions: [QuizQuestion] = []

        for (offset, index) in picked.enumerated() {
            let entry = words[index]
            let preferBlank = offset % 2 == 1
            if preferBlank, let masked = mask(example: entry.example, word: entry.word) {
                let options = wordOptions(for: entry, words: words, banned: bannedWords, rng: &rng)
                if let question = make(entry: entry, kind: .blank, prompt: masked, options: options, answer: entry.word) {
                    questions.append(question)
                    continue
                }
            }
            let options = meaningOptions(for: entry, words: words, banned: bannedDefinitions, rng: &rng)
            if let question = make(entry: entry, kind: .meaning, prompt: "", options: options, answer: entry.definition) {
                questions.append(question)
            }
        }
        return questions
    }

    private static func make(entry: WordEntry, kind: QuizQuestion.Kind, prompt: String, options: [String], answer: String) -> QuizQuestion? {
        guard options.count == 4, Set(options).count == 4, let answerIndex = options.firstIndex(of: answer) else { return nil }
        return QuizQuestion(word: entry.word, kind: kind, prompt: prompt, options: options, answerIndex: answerIndex)
    }

    private static func wordOptions(for entry: WordEntry, words: [WordEntry], banned: Set<String>, rng: inout SplitMix64) -> [String] {
        var same = words.filter { $0.pos == entry.pos && !banned.contains($0.word.lowercased()) }
        if same.count < 3 {
            same = words.filter { !banned.contains($0.word.lowercased()) && $0.word.lowercased() != entry.word.lowercased() }
        }
        same.shuffle(using: &rng)
        var options = [entry.word]
        for item in same where options.count < 4 {
            if !options.contains(item.word) { options.append(item.word) }
        }
        guard options.count == 4 else { return [] }
        options.shuffle(using: &rng)
        return options
    }

    private static func meaningOptions(for entry: WordEntry, words: [WordEntry], banned: Set<String>, rng: inout SplitMix64) -> [String] {
        let same = words.filter { $0.pos == entry.pos && $0.word != entry.word }
        var options = collectMeanings(entry: entry, pool: same, banned: banned, rng: &rng)
        if options.count < 4 {
            options = collectMeanings(entry: entry, pool: words.filter { $0.word != entry.word }, banned: banned, rng: &rng)
        }
        guard options.count == 4 else { return [] }
        options.shuffle(using: &rng)
        return options
    }

    private static func collectMeanings(entry: WordEntry, pool: [WordEntry], banned: Set<String>, rng: inout SplitMix64) -> [String] {
        var copy = pool
        copy.shuffle(using: &rng)
        var options = [entry.definition]
        var seen = banned
        seen.insert(entry.definition)
        for item in copy where options.count < 4 {
            if seen.contains(item.definition) { continue }
            options.append(item.definition)
            seen.insert(item.definition)
        }
        return options
    }

    static func mask(example: String, word: String) -> String? {
        let tokens = tokenize(example)
        let target = word.lowercased()
        if let exact = tokens.first(where: { $0.text.lowercased() == target }) {
            return replacing(example, exact.range, with: "______")
        }
        var best: (range: Range<String.Index>, shared: Int)?
        for token in tokens {
            guard isForm(token.text, of: word) else { continue }
            let shared = sharedPrefix(token.text.lowercased(), target)
            if best == nil || shared > best!.shared {
                best = (token.range, shared)
            }
        }
        if let best = best {
            return replacing(example, best.range, with: "______")
        }
        return nil
    }

    private static func isForm(_ token: String, of target: String) -> Bool {
        let left = token.lowercased()
        let right = target.lowercased()
        if left == right { return true }
        if inflected(left, lemma: right) || inflected(right, lemma: left) { return true }
        guard left.count >= 4, right.count >= 4 else { return false }
        let shared = sharedPrefix(left, right)
        let longer = max(left.count, right.count)
        return shared >= 5 && shared * 10 >= longer * 7
    }

    /// Whole lemma plus a short ending: waned, vexed. Kept narrow so a
    /// nearby word (order / or) is not blanked.
    private static func inflected(_ token: String, lemma: String) -> Bool {
        guard lemma.count >= 3, token.count > lemma.count, token.hasPrefix(lemma) else { return false }
        let suffix = String(token.dropFirst(lemma.count))
        return suffix == "s" || suffix == "es" || suffix == "ed" || suffix == "d" || suffix == "ing"
    }

    private static func sharedPrefix(_ left: String, _ right: String) -> Int {
        var count = 0
        for pair in zip(left, right) {
            if pair.0 != pair.1 { break }
            count += 1
        }
        return count
    }

    private static func tokenize(_ text: String) -> [(text: String, range: Range<String.Index>)] {
        var tokens: [(String, Range<String.Index>)] = []
        var index = text.startIndex
        while index < text.endIndex {
            let character = text[index]
            if character.isLetter || character == "'" || character == "’" {
                let start = index
                index = text.index(after: index)
                while index < text.endIndex {
                    let next = text[index]
                    if next.isLetter || next == "'" || next == "’" {
                        index = text.index(after: index)
                    } else {
                        break
                    }
                }
                tokens.append((String(text[start..<index]), start..<index))
            } else {
                index = text.index(after: index)
            }
        }
        return tokens
    }

    private static func replacing(_ text: String, _ range: Range<String.Index>, with blank: String) -> String {
        var copy = text
        copy.replaceSubrange(range, with: blank)
        return copy
    }
}

// MARK: - Pictures

struct PictureQuestion: Identifiable, Equatable {
    var id: String { word }
    let word: String
    let glyph: String
    let symbol: String
    let cn: String
    let level: Int
    let options: [String]
    let answerIndex: Int
}

enum PictureBuilder {
    static func build(pictures: [PictureEntry], seedKey: String, count: Int = 10) -> [PictureQuestion] {
        guard pictures.count >= 4 else { return [] }
        var rng = SplitMix64(state: fnv64("wordbit-pictures-v1:" + seedKey))
        var pool = pictures
        pool.shuffle(using: &rng)
        let selected = Array(pool.prefix(min(count, pool.count)))
        let answers = Set(selected.map { $0.word.lowercased() })
        var questions: [PictureQuestion] = []
        for entry in selected {
            let own = entry.word.lowercased()
            var picked = (entry.distractors ?? []).filter {
                $0.lowercased() != own && !answers.contains($0.lowercased())
            }
            picked.shuffle(using: &rng)
            var distractors = Array(picked.prefix(3))
            if distractors.count < 3 {
                var same = pictures.filter {
                    $0.distractorGroup == entry.distractorGroup
                        && $0.word.lowercased() != own
                        && !answers.contains($0.word.lowercased())
                        && !distractors.contains($0.word)
                }
                same.shuffle(using: &rng)
                for item in same where distractors.count < 3 {
                    distractors.append(item.word)
                }
            }
            if distractors.count < 3 {
                var rest = pictures.filter {
                    $0.word.lowercased() != own
                        && !answers.contains($0.word.lowercased())
                        && !distractors.contains($0.word)
                }
                rest.shuffle(using: &rng)
                for item in rest where distractors.count < 3 {
                    distractors.append(item.word)
                }
            }
            guard distractors.count == 3 else { continue }
            var options = distractors + [entry.word]
            options.shuffle(using: &rng)
            guard let answerIndex = options.firstIndex(of: entry.word) else { continue }
            questions.append(PictureQuestion(
                word: entry.word, glyph: entry.glyph, symbol: entry.symbol,
                cn: entry.cn, level: entry.level, options: options, answerIndex: answerIndex
            ))
        }
        return questions
    }
}
