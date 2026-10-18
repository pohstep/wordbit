//
//  Theme.swift — Wordbit v2 design tokens (18 Oct 2026)
//
//  Target: macOS 13 (Ventura), SwiftUI + AppKit. No APIs newer than macOS 13.
//  Frosted glass = SwiftUI `.ultraThinMaterial` (NSVisualEffectView underneath).
//  Every card = material + neutral "wash" + per-card accent tint. The wash is what
//  keeps body text >= 4.5:1 over any wallpaper (see DESIGN.md §1 for the model).
//
//  Usage:
//      VStack { ... }.glassCard(.word)
//      Button("Good") { ... }.buttonStyle(Theme.SolidButtonStyle(kind: .review))
//      Text(entry.word).font(Theme.Typeface.headword).foregroundColor(Theme.Palette.ink)
//

import SwiftUI
import AppKit

// MARK: - Dynamic colour helper (light / dark, incl. vibrant appearances)

extension NSColor {
    /// sRGB colour from 0xRRGGBB.
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: alpha)
    }

    /// Appearance-aware colour. Resolves per view, so it follows the system
    /// light/dark setting and the vibrant appearances used inside popovers.
    static func wb(light: UInt32, dark: UInt32,
                   lightAlpha: CGFloat = 1, darkAlpha: CGFloat = 1) -> NSColor {
        NSColor(name: nil, dynamicProvider: { appearance in
            let match = appearance.bestMatch(from: [.aqua, .darkAqua, .vibrantLight, .vibrantDark])
            let isDark = (match == .darkAqua || match == .vibrantDark)
            return isDark ? NSColor(hex: dark, alpha: darkAlpha)
                          : NSColor(hex: light, alpha: lightAlpha)
        })
    }
}

extension Color {
    /// Light/dark SwiftUI colour (macOS 12+ `Color(nsColor:)`).
    static func wb(light: UInt32, dark: UInt32,
                   lightAlpha: CGFloat = 1, darkAlpha: CGFloat = 1) -> Color {
        Color(nsColor: NSColor.wb(light: light, dark: dark,
                                  lightAlpha: lightAlpha, darkAlpha: darkAlpha))
    }
}

// MARK: - Theme

enum Theme {

    // MARK: Palette (neutrals)

    enum Palette {
        /// Primary text. Worst-case 10.1:1 light / 7.2:1 dark over tinted glass.
        static let ink           = Color.wb(light: 0x16151B, dark: 0xF7F6FA)
        /// Secondary text (IPA, example, origin). Worst-case >= 4.99 light / 5.08 dark.
        static let inkSecondary  = Color.wb(light: 0x4A4855, dark: 0xD2CFDC)
        /// Tertiary: placeholders, inactive dots, disabled. ~3:1 only — never for body text.
        static let inkTertiary   = Color.wb(light: 0x6E6B7A, dark: 0xA9A5B8)

        /// Neutral wash laid over the material on every card (the readability layer).
        static let cardWash      = Color.wb(light: 0xFFFFFF, dark: 0x121216,
                                            lightAlpha: 0.72, darkAlpha: 0.70)
        /// Lighter wash for the popover body behind the cards.
        static let popoverWash   = Color.wb(light: 0xFFFFFF, dark: 0x16161A,
                                            lightAlpha: 0.28, darkAlpha: 0.34)
        /// 1 pt inner edge that reads as a glass rim.
        static let cardStroke    = Color.wb(light: 0xFFFFFF, dark: 0xFFFFFF,
                                            lightAlpha: 0.70, darkAlpha: 0.10)
        static let separator     = Color.wb(light: 0x16151B, dark: 0xFFFFFF,
                                            lightAlpha: 0.10, darkAlpha: 0.12)
        static let cardShadow    = Color.wb(light: 0x2B1E5C, dark: 0x000000,
                                            lightAlpha: 0.12, darkAlpha: 0.40)
        /// Hover / pressed fill for icon buttons and rows.
        static let hoverFill     = Color.wb(light: 0x16151B, dark: 0xFFFFFF,
                                            lightAlpha: 0.07, darkAlpha: 0.10)
        /// Correct / wrong feedback (quiz, pictures). Text-safe on card glass.
        static let success       = Color.wb(light: 0x1E6B2E, dark: 0x8BE79A)
        static let danger        = Color.wb(light: 0xA5162F, dark: 0xFF9AA8)
    }

    // MARK: Card kinds (one accent per card type)

    enum CardKind: String, CaseIterable {
        case word, streak, review, quiz, pictures, saved

        /// (light fill, light text-safe, dark fill, dark text-safe)
        private var hexes: (UInt32, UInt32, UInt32, UInt32) {
            switch self {
            case .word:     return (0x6A4DF4, 0x4626C9, 0xA895FF, 0xC9BFFF) // violet
            case .streak:   return (0xFF7A1A, 0x8F3600, 0xFF9D4D, 0xFFC291) // flame orange
            case .review:   return (0x14B8A6, 0x055A51, 0x3EE0CB, 0x8AF0E2) // teal
            case .quiz:     return (0xF0407A, 0x9C1243, 0xFF7AA6, 0xFFB3CC) // pink
            case .pictures: return (0x4CC33A, 0x1E5E14, 0x7BE36B, 0xAEF0A3) // leaf green
            case .saved:    return (0xF5B400, 0x6B4500, 0xFFCB3D, 0xFFDE85) // star gold
            }
        }

        /// Vivid accent: icons, dots, progress, glows. Not guaranteed for small text.
        var accent: Color { let h = hexes; return .wb(light: h.0, dark: h.2) }
        /// Accent for text (labels, chips, links). >= 4.5:1 worst case on its card.
        var accentText: Color { let h = hexes; return .wb(light: h.1, dark: h.3) }
        /// Glass tint laid over the wash (10% light / 14% dark).
        var tint: Color { let h = hexes; return .wb(light: h.0, dark: h.2, lightAlpha: 0.10, darkAlpha: 0.14) }
        /// Corner glow (top-trailing radial). Kept away from body text.
        var glow: Color { let h = hexes; return .wb(light: h.0, dark: h.2, lightAlpha: 0.22, darkAlpha: 0.22) }
        /// Solid button fill + its label colour (>= 7:1).
        var solidFill: Color { let h = hexes; return .wb(light: h.1, dark: h.2) }
        var onSolid: Color { .wb(light: 0xFFFFFF, dark: 0x16151B) }
        /// Soft button / chip fill (pair with accentText).
        var softFill: Color { let h = hexes; return .wb(light: h.0, dark: h.2, lightAlpha: 0.14, darkAlpha: 0.20) }

        /// SF Symbol used as the card / tab glyph (all exist on macOS 13).
        var symbol: String {
            switch self {
            case .word:     return "character.book.closed"
            case .streak:   return "flame.fill"
            case .review:   return "rectangle.on.rectangle.angled"
            case .quiz:     return "checklist"
            case .pictures: return "photo.on.rectangle.angled"
            case .saved:    return "star.fill"
            }
        }
    }

    // MARK: Spacing (4-pt grid)

    enum Space {
        static let xxs: CGFloat = 2
        static let xs: CGFloat  = 4
        static let s: CGFloat   = 8
        static let m: CGFloat   = 12
        static let l: CGFloat   = 16
        static let xl: CGFloat  = 20
        static let xxl: CGFloat = 24
    }

    // MARK: Radii (all .continuous)

    enum Radius {
        static let card: CGFloat    = 18   // cards
        static let inner: CGFloat   = 12   // answer tiles, flashcard face, search field
        static let control: CGFloat = 9    // buttons
        static let chip: CGFloat    = 6    // POS chip, badges
        static let dot: CGFloat     = 5    // streak day dot (10 pt circle)
    }

    // MARK: Layout metrics

    enum Metrics {
        static let popover = CGSize(width: 360, height: 520)
        static let edge: CGFloat        = 12   // popover inset to cards
        static let cardPadding: CGFloat = 16
        static let cardGap: CGFloat     = 10
        static let headerHeight: CGFloat = 32
        static let tabBarHeight: CGFloat = 50
        static let iconButton: CGFloat  = 26   // hit target for speaker / star / copy
        static let answerTileHeight: CGFloat = 40
        static let streakDot: CGFloat   = 10
        static let cardShadowRadius: CGFloat = 14
        static let cardShadowY: CGFloat = 6
    }

    // MARK: Type scale (SF Pro / SF Pro Rounded / New York — all system, no bundle)

    enum Typeface {
        /// Headword. New York (system serif). Long words: .minimumScaleFactor(0.6).
        static let headword  = Font.system(size: 30, weight: .semibold, design: .serif)
        /// Flashcard front / picture-game answer word.
        static let display   = Font.system(size: 26, weight: .semibold, design: .serif)
        /// Card titles, screen titles.
        static let title     = Font.system(size: 15, weight: .semibold, design: .default)
        /// Definition, quiz options, list rows.
        static let body      = Font.system(size: 13, weight: .regular, design: .default)
        static let bodyEmph  = Font.system(size: 13, weight: .semibold, design: .default)
        /// Example sentence (serif italic so it reads as a quotation).
        static let example   = Font.system(size: 13, weight: .regular, design: .serif).italic()
        /// Chinese gloss (falls back to PingFang SC automatically).
        static let gloss     = Font.system(size: 13, weight: .regular, design: .default)
        /// IPA + part of speech line.
        static let meta      = Font.system(size: 12, weight: .regular, design: .default)
        /// Origin line, helper text, button labels in tight rows.
        static let caption   = Font.system(size: 11, weight: .medium, design: .default)
        /// Uppercase eyebrow ("WORD OF THE DAY"). Use with .tracking(0.6) on Text.
        static let eyebrow   = Font.system(size: 10, weight: .bold, design: .rounded)
        /// Big numbers (streak, score, due count).
        static let stat      = Font.system(size: 26, weight: .bold, design: .rounded).monospacedDigit()
        static let statSmall = Font.system(size: 13, weight: .semibold, design: .rounded).monospacedDigit()
        /// Tab labels.
        static let tab       = Font.system(size: 10, weight: .medium, design: .default)
        /// Emoji / SF Symbol hero in the picture game.
        static let pictureHero = Font.system(size: 72, weight: .regular, design: .default)
        /// Icon buttons (speaker, star, copy).
        static let icon      = Font.system(size: 13, weight: .semibold, design: .default)
    }

    // MARK: Card modifier

    struct GlassCard: ViewModifier {
        let kind: CardKind
        var padding: CGFloat = Metrics.cardPadding

        func body(content: Content) -> some View {
            let shape = RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
            return content
                .padding(padding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    ZStack {
                        shape.fill(.ultraThinMaterial)          // frosted glass (macOS 12+)
                        shape.fill(Palette.cardWash)            // readability layer
                        shape.fill(kind.tint)                   // card colour
                        shape.fill(                             // accent glow, top-trailing
                            RadialGradient(colors: [kind.glow, Color.clear],
                                           center: .topTrailing,
                                           startRadius: 0, endRadius: 150)
                        )
                    }
                )
                .clipShape(shape)
                .overlay(shape.strokeBorder(Palette.cardStroke, lineWidth: 1))
                .shadow(color: Palette.cardShadow,
                        radius: Metrics.cardShadowRadius, x: 0, y: Metrics.cardShadowY)
        }
    }

    // MARK: Buttons

    /// Filled accent button (Review: Again / Good / Easy; Quiz: Next).
    struct SolidButtonStyle: ButtonStyle {
        let kind: CardKind
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(Typeface.bodyEmph)
                .foregroundColor(kind.onSolid)
                .frame(maxWidth: .infinity, minHeight: 32)
                .background(
                    RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                        .fill(kind.solidFill)
                )
                .opacity(configuration.isPressed ? 0.8 : 1)
                .contentShape(Rectangle())
        }
    }

    /// Soft tinted button / answer tile (quiz + picture options).
    struct SoftButtonStyle: ButtonStyle {
        let kind: CardKind
        var height: CGFloat = Metrics.answerTileHeight
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(Typeface.body)
                .foregroundColor(Palette.ink)
                .frame(maxWidth: .infinity, minHeight: height)
                .background(
                    RoundedRectangle(cornerRadius: Radius.inner, style: .continuous)
                        .fill(kind.softFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.inner, style: .continuous)
                        .strokeBorder(kind.accent.opacity(configuration.isPressed ? 0.6 : 0.25), lineWidth: 1)
                )
                .contentShape(Rectangle())
        }
    }

    /// Round icon button (speaker, star, copy) with hover fill.
    struct IconButtonStyle: ButtonStyle {
        let kind: CardKind
        func makeBody(configuration: Configuration) -> some View {
            IconButtonBody(configuration: configuration, kind: kind)
        }
        private struct IconButtonBody: View {
            let configuration: ButtonStyleConfiguration
            let kind: CardKind
            @State private var hover = false
            var body: some View {
                configuration.label
                    .font(Typeface.icon)
                    .foregroundColor(kind.accentText)
                    .frame(width: Metrics.iconButton, height: Metrics.iconButton)
                    .background(Circle().fill(hover || configuration.isPressed ? kind.softFill : Color.clear))
                    .contentShape(Circle())
                    .onHover { hover = $0 }
            }
        }
    }

    // MARK: Small components

    /// POS / status chip, e.g. "adjective".
    struct Chip: View {
        let text: String
        let kind: CardKind
        var body: some View {
            Text(text)
                .font(Typeface.caption)
                .foregroundColor(kind.accentText)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                        .fill(kind.softFill)
                )
        }
    }

    /// Card eyebrow: glyph + uppercase label in the card's accent.
    struct Eyebrow: View {
        let text: String
        let kind: CardKind
        var body: some View {
            HStack(spacing: Space.xs) {
                Image(systemName: kind.symbol)
                    .font(.system(size: 10, weight: .bold, design: .default))
                    .foregroundColor(kind.accent)
                Text(text.uppercased())
                    .font(Typeface.eyebrow)
                    .tracking(0.6)
                    .foregroundColor(kind.accentText)
            }
        }
    }

    /// AppKit-backed window glass for the popover body, if the host does not
    /// already provide one (MenuBarExtra(.window) does).
    struct WindowGlass: NSViewRepresentable {
        var material: NSVisualEffectView.Material = .popover
        func makeNSView(context: Context) -> NSVisualEffectView {
            let v = NSVisualEffectView()
            v.material = material
            v.blendingMode = .behindWindow
            v.state = .active
            return v
        }
        func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
            nsView.material = material
        }
    }
}

// MARK: - View sugar

extension View {
    func glassCard(_ kind: Theme.CardKind, padding: CGFloat = Theme.Metrics.cardPadding) -> some View {
        modifier(Theme.GlassCard(kind: kind, padding: padding))
    }

    /// Popover backdrop: window glass + light wash.
    func wordbitPopoverBackground() -> some View {
        background(
            ZStack {
                Theme.WindowGlass()
                Theme.Palette.popoverWash
            }
            .ignoresSafeArea()
        )
    }
}
