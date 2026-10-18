import SwiftUI

struct ReviewView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Metrics.cardGap) {
                if !model.pendingOfferWords.isEmpty {
                    OfferCard()
                }
                if let word = model.dueEntries().first?.word, let entry = model.library.entry(for: word) {
                    FlashCard(entry: entry, due: model.dueCount)
                } else {
                    empty
                }
            }
            .padding(.horizontal, Theme.Metrics.edge)
            .padding(.vertical, Theme.Space.s)
        }
    }

    private var empty: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Theme.Eyebrow(text: "Review", kind: .review)
            Text("Nothing due")
                .font(Theme.Typeface.title)
                .foregroundColor(Theme.Palette.ink)
            Text("You're clear for today. Cards come back on the day they're due.")
                .font(Theme.Typeface.body)
                .foregroundColor(Theme.Palette.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if !model.countedToday {
                Button("Take today's quiz") { model.show(.quiz) }
                    .buttonStyle(Theme.SolidButtonStyle(kind: .review))
                    .padding(.top, Theme.Space.xs)
            }
        }
        .glassCard(.review)
    }
}

struct FlashCard: View {
    let entry: WordEntry
    let due: Int
    @EnvironmentObject var model: AppModel
    @State private var flipped = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            HStack {
                Theme.Eyebrow(text: "Review", kind: .review)
                Spacer()
                Text(due == 1 ? "1 due" : "\(due) due")
                    .font(Theme.Typeface.caption)
                    .foregroundColor(Theme.CardKind.review.accentText)
            }
            Button {
                flipped.toggle()
            } label: {
                VStack(alignment: .leading, spacing: Theme.Space.s) {
                    if !flipped {
                        Text(entry.word)
                            .font(Theme.Typeface.display)
                            .foregroundColor(Theme.Palette.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        Text("Tap to show the meaning")
                            .font(Theme.Typeface.caption)
                            .foregroundColor(Theme.Palette.inkSecondary)
                    } else {
                        Text(entry.definition)
                            .font(Theme.Typeface.body)
                            .foregroundColor(Theme.Palette.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        if model.disk.settings.showChinese && !entry.cn.isEmpty {
                            Text(entry.cn)
                                .font(Theme.Typeface.gloss)
                                .foregroundColor(Theme.Palette.inkSecondary)
                        }
                        if !entry.example.isEmpty {
                            Text("“\(entry.example)”")
                                .font(Theme.Typeface.example)
                                .foregroundColor(Theme.Palette.inkSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
                .padding(Theme.Space.m)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.inner, style: .continuous)
                        .fill(Theme.CardKind.review.softFill)
                )
            }
            .buttonStyle(PlainButtonStyle())

            if flipped {
                HStack(spacing: Theme.Space.s) {
                    Button("Again") { model.grade(word: entry.word, grade: .again) }
                        .buttonStyle(Theme.SolidButtonStyle(kind: .quiz))
                    Button("Good") { model.grade(word: entry.word, grade: .good) }
                        .buttonStyle(Theme.SolidButtonStyle(kind: .review))
                    Button("Easy") { model.grade(word: entry.word, grade: .easy) }
                        .buttonStyle(Theme.SolidButtonStyle(kind: .word))
                }
            }
        }
        .glassCard(.review)
        .onChange(of: entry.word) { _ in flipped = false }
    }
}

struct QuizScreen: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Metrics.cardGap) {
                content
            }
            .padding(.horizontal, Theme.Metrics.edge)
            .padding(.vertical, Theme.Space.s)
        }
        .onAppear { model.ensureQuiz() }
    }

    @ViewBuilder
    private var content: some View {
        if let session = model.quiz, !session.questions.isEmpty {
            if session.finished && !session.revealing {
                QuizResult(session: session)
            } else if session.questions.indices.contains(session.index) {
                QuizCard(session: session, question: session.questions[session.index])
            }
        } else {
            LoadErrorCard(
                title: "Quiz isn't ready",
                detail: "The word list didn't have enough entries to build five questions."
            )
        }
    }
}

struct QuizCard: View {
    let session: QuizSession
    let question: QuizQuestion
    @EnvironmentObject var model: AppModel

    var body: some View {
        let entry = model.library.entry(for: question.word)
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            HStack {
                Theme.Eyebrow(text: "Quiz", kind: .quiz)
                Spacer()
                Text("\(session.index + 1) of \(session.questions.count)")
                    .font(Theme.Typeface.caption)
                    .foregroundColor(Theme.CardKind.quiz.accentText)
            }
            progress
            if question.kind == .meaning {
                Text("What does this mean?")
                    .font(Theme.Typeface.caption)
                    .foregroundColor(Theme.Palette.inkSecondary)
                HStack(spacing: Theme.Space.s) {
                    Text(question.word)
                        .font(Theme.Typeface.title)
                        .foregroundColor(Theme.Palette.ink)
                    if let pos = entry?.pos, !pos.isEmpty {
                        Theme.Chip(text: pos, kind: .quiz)
                    }
                }
            } else {
                Text("Fill in the blank")
                    .font(Theme.Typeface.caption)
                    .foregroundColor(Theme.Palette.inkSecondary)
                Text("“\(question.prompt)”")
                    .font(Theme.Typeface.example)
                    .foregroundColor(Theme.Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if (session.picked != nil || session.revealing), model.disk.settings.showChinese, let cn = entry?.cn, !cn.isEmpty {
                Text(cn)
                    .font(Theme.Typeface.gloss)
                    .foregroundColor(Theme.Palette.inkSecondary)
            }
            VStack(spacing: Theme.Space.s) {
                ForEach(question.options.indices, id: \.self) { index in
                    AnswerTile(
                        title: question.options[index],
                        kind: .quiz,
                        mark: answerMark(
                            index: index,
                            picked: session.picked,
                            answer: question.answerIndex,
                            reveal: session.revealing
                        )
                    ) {
                        model.pickQuiz(option: index)
                    }
                }
            }
            if session.revealing {
                Button(session.index + 1 >= session.questions.count ? "Done" : "Next") {
                    model.advanceReveal()
                }
                .buttonStyle(Theme.SolidButtonStyle(kind: .quiz))
            } else if session.picked != nil {
                Button(session.index + 1 >= session.questions.count ? "See score" : "Next") {
                    model.advanceQuiz()
                }
                .buttonStyle(Theme.SolidButtonStyle(kind: .quiz))
            }
        }
        .glassCard(.quiz)
    }

    private var progress: some View {
        HStack(spacing: 6) {
            ForEach(session.questions.indices, id: \.self) { index in
                Circle()
                    .fill(dotFill(index))
                    .overlay(Circle().strokeBorder(dotStroke(index), lineWidth: 1))
                    .frame(width: 8, height: 8)
            }
            Spacer()
        }
    }

    private func dotFill(_ index: Int) -> Color {
        if index < session.results.count {
            return session.results[index] ? Theme.Palette.success : Theme.Palette.danger
        }
        if index == session.index && !session.revealing {
            return Theme.CardKind.quiz.accent
        }
        return Color.clear
    }

    private func dotStroke(_ index: Int) -> Color {
        if index < session.results.count {
            return session.results[index] ? Theme.Palette.success : Theme.Palette.danger
        }
        return Theme.CardKind.quiz.accent
    }
}

struct QuizResult: View {
    let session: QuizSession
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Theme.Eyebrow(text: "Quiz", kind: .quiz)
            HStack(alignment: .lastTextBaseline, spacing: Theme.Space.xs) {
                Text("\(session.savedScore)")
                    .font(Theme.Typeface.stat)
                    .foregroundColor(Theme.Palette.ink)
                Text("of \(session.questions.count)")
                    .font(Theme.Typeface.body)
                    .foregroundColor(Theme.Palette.inkSecondary)
            }
            Text(blurb)
                .font(Theme.Typeface.body)
                .foregroundColor(Theme.Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            if model.countedToday {
                Text("Today counts toward your streak.")
                    .font(Theme.Typeface.caption)
                    .foregroundColor(Theme.CardKind.quiz.accentText)
            }
            Button("See the answers") { model.startReveal() }
                .buttonStyle(Theme.SolidButtonStyle(kind: .quiz))
                .padding(.top, Theme.Space.xs)
        }
        .glassCard(.quiz)
    }

    private var blurb: String {
        switch session.savedScore {
        case 5: return "All five. That one will stay with you."
        case 4: return "Four out of five. Close."
        case 3: return "Three out of five. Worth another look."
        default: return "A hard set. Today still counts, because you finished."
        }
    }
}

struct PicturesScreen: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Metrics.cardGap) {
                content
            }
            .padding(.horizontal, Theme.Metrics.edge)
            .padding(.vertical, Theme.Space.s)
        }
        .onAppear { model.ensurePictures() }
    }

    @ViewBuilder
    private var content: some View {
        if let round = model.pictures, !round.questions.isEmpty {
            if round.finished {
                PictureResult(round: round)
            } else if round.questions.indices.contains(round.index) {
                PictureCard(round: round, question: round.questions[round.index])
            }
        } else {
            LoadErrorCard(
                title: "Pictures didn't load",
                detail: "pictures.json is missing from the app. Run ./install.sh again."
            )
        }
    }
}

struct PictureCard: View {
    let round: PictureRound
    let question: PictureQuestion
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            HStack {
                Theme.Eyebrow(text: "Pictures", kind: .pictures)
                Spacer()
                Text("\(round.results.filter { $0 }.count)/\(round.questions.count)")
                    .font(Theme.Typeface.statSmall)
                    .foregroundColor(Theme.CardKind.pictures.accentText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Theme.CardKind.pictures.softFill))
            }
            HStack {
                Text("Which word is this?")
                    .font(Theme.Typeface.caption)
                    .foregroundColor(Theme.Palette.inkSecondary)
                Spacer()
                Theme.Chip(text: "Level \(question.level)", kind: .pictures)
            }
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.inner, style: .continuous)
                    .fill(Theme.CardKind.pictures.softFill)
                GlyphHero(glyph: question.glyph, symbol: question.symbol)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 132)
            if round.picked != nil && model.disk.settings.showChinese && !question.cn.isEmpty {
                Text(question.cn)
                    .font(Theme.Typeface.gloss)
                    .foregroundColor(Theme.Palette.inkSecondary)
                    .frame(maxWidth: .infinity)
            }
            if let picked = round.picked {
                HStack(spacing: 4) {
                    Image(systemName: picked == question.answerIndex ? "checkmark" : "xmark")
                    Text(picked == question.answerIndex ? "Correct" : "Answer: \(question.word)")
                }
                .font(Theme.Typeface.caption)
                .foregroundColor(picked == question.answerIndex ? Theme.Palette.success : Theme.Palette.danger)
            }
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Theme.Space.s),
                GridItem(.flexible(), spacing: Theme.Space.s)
            ], spacing: Theme.Space.s) {
                ForEach(question.options.indices, id: \.self) { index in
                    AnswerTile(
                        title: question.options[index],
                        kind: .pictures,
                        mark: answerMark(index: index, picked: round.picked, answer: question.answerIndex, reveal: false)
                    ) {
                        model.pickPicture(option: index)
                    }
                }
            }
            if round.picked != nil {
                Button(round.index + 1 >= round.questions.count ? "See score" : "Next") {
                    model.advancePicture()
                }
                .buttonStyle(Theme.SolidButtonStyle(kind: .pictures))
            }
        }
        .glassCard(.pictures)
    }
}

struct GlyphHero: View {
    let glyph: String
    let symbol: String

    var body: some View {
        if !glyph.isEmpty {
            Text(glyph)
                .font(Theme.Typeface.pictureHero)
        } else if !symbol.isEmpty {
            Image(systemName: symbol)
                .font(.system(size: 64, weight: .regular))
                .foregroundColor(Theme.CardKind.pictures.accent)
        } else {
            Text("?")
                .font(Theme.Typeface.display)
                .foregroundColor(Theme.Palette.inkTertiary)
        }
    }
}

struct PictureResult: View {
    let round: PictureRound
    @EnvironmentObject var model: AppModel

    var body: some View {
        let score = round.results.filter { $0 }.count
        let total = round.questions.count
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Theme.Eyebrow(text: "Pictures", kind: .pictures)
            HStack(alignment: .lastTextBaseline, spacing: Theme.Space.xs) {
                Text("\(score)")
                    .font(Theme.Typeface.stat)
                    .foregroundColor(Theme.Palette.ink)
                Text("of \(total)")
                    .font(Theme.Typeface.body)
                    .foregroundColor(Theme.Palette.inkSecondary)
            }
            Text(blurb(score: score, total: total))
                .font(Theme.Typeface.body)
                .foregroundColor(Theme.Palette.ink)
            Button("Play again") { model.replayPictures() }
                .buttonStyle(Theme.SolidButtonStyle(kind: .pictures))
                .padding(.top, Theme.Space.xs)
        }
        .glassCard(.pictures)
    }

    private func blurb(score: Int, total: Int) -> String {
        if score == total { return "A clean round." }
        if total > 0 && score * 5 >= total * 4 { return "Most of them stuck." }
        return "A few to look at again."
    }
}
