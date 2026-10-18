import SwiftUI

struct NeutralCard: ViewModifier {
    var padding: CGFloat = Theme.Metrics.cardPadding

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    shape.fill(.ultraThinMaterial)
                    shape.fill(Theme.Palette.cardWash)
                }
            )
            .clipShape(shape)
            .overlay(shape.strokeBorder(Theme.Palette.cardStroke, lineWidth: 1))
            .shadow(color: Theme.Palette.cardShadow, radius: Theme.Metrics.cardShadowRadius, x: 0, y: Theme.Metrics.cardShadowY)
    }
}

extension View {
    func neutralCard(padding: CGFloat = Theme.Metrics.cardPadding) -> some View {
        modifier(NeutralCard(padding: padding))
    }
}

struct SpeakerButton: View {
    let text: String
    let kind: Theme.CardKind
    var diameter: CGFloat = 30
    @EnvironmentObject var model: AppModel

    var body: some View {
        Button {
            model.speak(text)
        } label: {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: diameter >= 30 ? 13 : 10, weight: .semibold))
                .foregroundColor(kind.accentText)
                .frame(width: diameter, height: diameter)
                .background(Circle().fill(kind.softFill))
        }
        .buttonStyle(PlainButtonStyle())
        .help(model.tr(.helpSpeak))
        .accessibilityLabel(model.tr(.helpSpeak))
    }
}

struct OutlinePill: View {
    let text: String
    var body: some View {
        Text(text)
            .font(Theme.Typeface.caption)
            .foregroundColor(Theme.Palette.inkSecondary)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous)
                    .strokeBorder(Theme.Palette.separator, lineWidth: 1)
            )
    }
}

struct ChinesePill: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        let on = model.disk.settings.showChinese
        Button {
            model.toggleChinese()
        } label: {
            Text(on ? "中文 ✓" : "中文")
                .font(Theme.Typeface.caption)
                .foregroundColor(on ? Theme.CardKind.word.accentText : Theme.Palette.inkSecondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous)
                        .fill(on ? Theme.CardKind.word.softFill : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous)
                        .strokeBorder(on ? Color.clear : Theme.Palette.separator, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .help(model.tr(.helpChinese))
    }
}

enum AnswerMark { case idle, correct, wrong, dimmed }

struct AnswerTile: View {
    let title: String
    let kind: Theme.CardKind
    let mark: AnswerMark
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 6) {
                if mark == .correct {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Theme.Palette.success)
                } else if mark == .wrong {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Theme.Palette.danger)
                }
                Text(title)
                    .font(Theme.Typeface.body)
                    .foregroundColor(label)
                    .multilineTextAlignment(.leading)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: Theme.Metrics.answerTileHeight, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.inner, style: .continuous)
                    .fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.inner, style: .continuous)
                    .strokeBorder(border, lineWidth: mark == .idle ? 1 : 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .allowsHitTesting(mark == .idle)
        .opacity(mark == .dimmed ? 0.5 : 1)
    }

    private var label: Color {
        switch mark {
        case .correct: return Theme.Palette.success
        case .wrong: return Theme.Palette.danger
        default: return Theme.Palette.ink
        }
    }

    private var fill: Color {
        switch mark {
        case .correct: return Theme.Palette.success.opacity(0.14)
        case .wrong: return Theme.Palette.danger.opacity(0.12)
        default: return kind.softFill
        }
    }

    private var border: Color {
        switch mark {
        case .correct: return Theme.Palette.success
        case .wrong: return Theme.Palette.danger
        case .idle: return kind.accent.opacity(0.25)
        case .dimmed: return Theme.Palette.separator
        }
    }
}

func answerMark(index: Int, picked: Int?, answer: Int, reveal: Bool) -> AnswerMark {
    if reveal { return index == answer ? .correct : .dimmed }
    guard let picked = picked else { return .idle }
    if index == answer { return .correct }
    if index == picked { return .wrong }
    return .dimmed
}

struct HeaderIcon: View {
    let name: String
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.Palette.inkSecondary)
                .frame(width: 26, height: 26)
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.35)
    }
}

struct HeaderBar: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        HStack(spacing: 6) {
            if model.tab == .today {
                todayTitle
                Spacer(minLength: 4)
                HeaderIcon(name: "chevron.left") { model.shiftDay(-1) }
                    .help(model.tr(.helpPreviousDay))
                HeaderIcon(name: "chevron.right", enabled: model.dayOffset < 0) { model.shiftDay(1) }
                    .help(model.tr(.helpNextDay))
            } else {
                Text(model.tabTitle(model.tab))
                    .font(Theme.Typeface.title)
                    .foregroundColor(Theme.Palette.ink)
                Spacer()
                if model.tab == .review {
                    Text(model.dueText(model.dueCount))
                        .font(Theme.Typeface.caption)
                        .foregroundColor(Theme.CardKind.review.accentText)
                }
            }
        }
        .frame(height: Theme.Metrics.headerHeight)
    }

    @ViewBuilder
    private var todayTitle: some View {
        if model.dayOffset == 0 {
            Text(model.tr(.tabToday))
                .font(Theme.Typeface.title)
                .foregroundColor(Theme.Palette.ink)
            Text(model.dateLabel)
                .font(Theme.Typeface.meta)
                .foregroundColor(Theme.Palette.inkSecondary)
                .lineLimit(1)
        } else {
            Button {
                model.goToday()
            } label: {
                Text(model.dateLabel)
                    .font(Theme.Typeface.title)
                    .foregroundColor(Theme.Palette.ink)
                    .lineLimit(1)
            }
            .buttonStyle(PlainButtonStyle())
            .help(model.tr(.helpBackToday))
        }
    }
}

struct TabBar: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        HStack(spacing: 0) {
            tab(.today)
            tab(.review, badge: model.dueCount)
            tab(.quiz)
            tab(.pictures)
            tab(.saved)
            tab(.settings)
        }
        .padding(.horizontal, 6)
        .frame(height: Theme.Metrics.tabBarHeight)
    }

    private func tab(_ item: AppTab, badge: Int = 0) -> some View {
        let selected = model.tab == item
        let kind = item.kind
        return Button {
            model.show(item)
        } label: {
            VStack(spacing: 2) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: item.symbol)
                        .font(.system(size: 15, weight: .semibold))
                    if badge > 0 {
                        Text(badge > 9 ? "9+" : "\(badge)")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.CardKind.review.onSolid)
                            .padding(.horizontal, 3)
                            .frame(minWidth: 12, minHeight: 12)
                            .background(Capsule().fill(Theme.CardKind.review.solidFill))
                            .offset(x: 8, y: -5)
                    }
                }
                Text(model.tabTitle(item))
                    .font(Theme.Typeface.tab)
                    .lineLimit(1)
            }
            .foregroundColor(selected ? (kind?.accentText ?? Theme.Palette.ink) : Theme.Palette.inkSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(selected ? (kind?.softFill ?? Theme.Palette.hoverFill) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RootView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            HeaderBar()
                .padding(.horizontal, Theme.Metrics.edge)
                .padding(.top, 8)
            Group {
                switch model.tab {
                case .today: TodayView()
                case .review: ReviewView()
                case .quiz: QuizScreen()
                case .pictures: PicturesScreen()
                case .saved: SavedView()
                case .settings: SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            TabBar()
        }
        .frame(width: Theme.Metrics.popover.width, height: Theme.Metrics.popover.height)
        .wordbitPopoverBackground()
    }
}

struct LoadErrorCard: View {
    let title: String
    let detail: String
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Text(title)
                .font(Theme.Typeface.title)
                .foregroundColor(Theme.Palette.ink)
            Text(detail)
                .font(Theme.Typeface.body)
                .foregroundColor(Theme.Palette.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .glassCard(.word)
    }
}
