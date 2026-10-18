import Foundation
import SwiftUI

struct TodayView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Metrics.cardGap) {
                if model.library.failed {
                    LoadErrorCard(
                        title: model.tr(.wordsDidntLoad),
                        detail: model.tr(.wordsMissing)
                    )
                } else {
                    WordCard(entry: model.displayedEntry, heading: model.dayOffset == 0 ? model.tr(.wordOfTheDay) : model.tr(.onThisDay))
                    StreakCard()
                    if !model.pendingOfferWords.isEmpty {
                        OfferCard()
                    }
                }
            }
            .padding(.horizontal, Theme.Metrics.edge)
            .padding(.vertical, Theme.Space.s)
        }
    }
}

struct WordCard: View {
    let entry: WordEntry
    var heading: String
    @EnvironmentObject var model: AppModel
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: Theme.Space.xs) {
                Theme.Eyebrow(text: heading, kind: .word)
                Spacer(minLength: 4)
                Button {
                    model.toggleSaved(entry.word)
                } label: {
                    Image(systemName: model.isSaved(entry.word) ? "star.fill" : "star")
                }
                .buttonStyle(Theme.IconButtonStyle(kind: model.isSaved(entry.word) ? .saved : .word))
                .help(model.isSaved(entry.word) ? model.tr(.helpRemoveSaved) : model.tr(.helpSaveWord))

                Button {
                    model.copyEntry(entry)
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { copied = false }
                } label: {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                }
                .buttonStyle(Theme.IconButtonStyle(kind: .word))
                .help(model.tr(.helpCopyWord))
            }

            HStack(alignment: .center, spacing: Theme.Space.s) {
                Text(entry.word)
                    .font(Theme.Typeface.headword)
                    .foregroundColor(Theme.Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Spacer(minLength: 4)
                SpeakerButton(text: entry.word, kind: .word, diameter: 30)
            }
            .padding(.top, Theme.Space.xs)

            HStack(spacing: Theme.Space.s) {
                if !entry.ipa.isEmpty {
                    Text(entry.ipa)
                        .font(Theme.Typeface.meta)
                        .foregroundColor(Theme.Palette.inkSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                if !entry.pos.isEmpty {
                    Theme.Chip(text: entry.pos, kind: .word)
                }
            }
            .padding(.top, Theme.Space.xs)

            Text(entry.definition)
                .font(Theme.Typeface.body)
                .foregroundColor(Theme.Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)

            if model.disk.settings.showChinese && !entry.cn.isEmpty {
                Text(entry.cn)
                    .font(Theme.Typeface.gloss)
                    .foregroundColor(Theme.Palette.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Theme.Space.xs)
            }

            if !entry.example.isEmpty {
                HStack(alignment: .top, spacing: Theme.Space.s) {
                    RoundedRectangle(cornerRadius: 1, style: .continuous)
                        .fill(Theme.CardKind.word.accent)
                        .frame(width: 2)
                    Text("“\(entry.example)”")
                        .font(Theme.Typeface.example)
                        .foregroundColor(Theme.Palette.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 4)
                    SpeakerButton(text: entry.example, kind: .word, diameter: 26)
                }
                .padding(.top, 10)
            }

            if !entry.origin.isEmpty {
                (Text(model.tr(.origin)).foregroundColor(Theme.CardKind.word.accentText)
                    + Text(" · " + entry.origin).foregroundColor(Theme.Palette.inkSecondary))
                    .font(Theme.Typeface.caption)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Theme.Space.s)
            }

            HStack(spacing: Theme.Space.s) {
                ChinesePill()
                if let box = model.reviewBox(entry.word) {
                    OutlinePill(text: model.trf(.inReviewBox, box))
                } else {
                    OutlinePill(text: model.tr(.notInReview))
                }
                Spacer(minLength: 0)
            }
            .padding(.top, Theme.Space.m)
        }
        .glassCard(.word)
        .onAppear { model.markSeen(entry.word) }
    }
}

struct StreakCard: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            HStack {
                Theme.Eyebrow(text: model.tr(.streak), kind: .streak)
                Spacer()
                Text(model.trf(.best, model.disk.streak.best))
                    .font(Theme.Typeface.caption)
                    .foregroundColor(Theme.CardKind.streak.accentText)
            }
            HStack(alignment: .center, spacing: Theme.Space.m) {
                HStack(alignment: .lastTextBaseline, spacing: Theme.Space.xs) {
                    Text("\(model.disk.streak.current)")
                        .font(Theme.Typeface.stat)
                        .foregroundColor(Theme.Palette.ink)
                    Text(model.disk.streak.current == 1 ? model.tr(.dayOne) : model.tr(.dayMany))
                        .font(Theme.Typeface.body)
                        .foregroundColor(Theme.Palette.inkSecondary)
                }
                Spacer(minLength: 8)
                HStack(spacing: 5) {
                    ForEach(model.weekDots()) { dot in
                        VStack(spacing: 3) {
                            dotView(dot)
                            Text(dot.letter)
                                .font(Theme.Typeface.tab)
                                .foregroundColor(Theme.Palette.inkTertiary)
                        }
                    }
                }
            }
            hint
        }
        .glassCard(.streak, padding: 14)
    }

    @ViewBuilder
    private func dotView(_ dot: WeekDot) -> some View {
        let accent = Theme.CardKind.streak.accent
        Circle()
            .fill(dot.style == .filled ? accent : Color.clear)
            .overlay(
                Circle().strokeBorder(ringColor(dot, accent: accent), lineWidth: dot.style == .filled ? 0 : 1.4)
            )
            .frame(width: Theme.Metrics.streakDot, height: Theme.Metrics.streakDot)
            .opacity(dot.style == .upcoming ? 0.45 : 1)
    }

    private func ringColor(_ dot: WeekDot, accent: Color) -> Color {
        switch dot.style {
        case .ring: return accent
        case .filled: return accent
        case .missed, .upcoming: return Theme.Palette.inkTertiary
        }
    }

    @ViewBuilder
    private var hint: some View {
        if model.countedToday {
            Text(model.tr(.todayCountsTomorrow))
                .font(Theme.Typeface.caption)
                .foregroundColor(Theme.Palette.inkSecondary)
        } else {
            HStack(spacing: 0) {
                Text(model.tr(.finishQuizHint))
                    .foregroundColor(Theme.Palette.inkSecondary)
                Button(model.tr(.takeQuizArrow)) { model.show(.quiz) }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(Theme.CardKind.streak.accentText)
            }
            .font(Theme.Typeface.caption)
        }
    }
}

struct OfferCard: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        let count = model.pendingOfferWords.count
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Theme.Eyebrow(text: model.tr(.tabReview), kind: .review)
            Text(count == 1 ? model.tr(.offerQuestionOne) : model.trf(.offerQuestionMany, count))
                .font(Theme.Typeface.body)
                .foregroundColor(Theme.Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(count > 40 ? model.tr(.offerSpread) : model.tr(.offerTomorrow))
                .font(Theme.Typeface.caption)
                .foregroundColor(Theme.Palette.inkSecondary)
            HStack(spacing: Theme.Space.s) {
                Button(model.tr(.addThem)) { model.acceptOffer() }
                    .buttonStyle(Theme.SolidButtonStyle(kind: .review))
                Button(model.tr(.notNow)) { model.dismissOffer() }
                    .buttonStyle(Theme.SoftButtonStyle(kind: .review, height: 32))
            }
        }
        .glassCard(.review)
    }
}
