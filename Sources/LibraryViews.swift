import AppKit
import SwiftUI

struct SavedView: View {
    @EnvironmentObject var model: AppModel
    @State private var query = ""

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Metrics.cardGap) {
                if let word = model.savedDetail, let entry = model.library.entry(for: word) {
                    Button {
                        model.savedDetail = nil
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Saved")
                        }
                        .font(Theme.Typeface.caption)
                        .foregroundColor(Theme.CardKind.saved.accentText)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    WordCard(entry: entry, heading: "Saved")
                } else {
                    list
                }
            }
            .padding(.horizontal, Theme.Metrics.edge)
            .padding(.vertical, Theme.Space.s)
        }
    }

    private var list: some View {
        let entries = model.savedEntries(matching: query)
        return VStack(alignment: .leading, spacing: Theme.Space.s) {
            HStack {
                Theme.Eyebrow(text: "Saved", kind: .saved)
                Spacer()
                Image(systemName: "star.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.CardKind.saved.accent)
            }
            HStack(spacing: Theme.Space.s) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.Palette.inkTertiary)
                TextField("Search saved words", text: $query)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(Theme.Typeface.body)
            }
            .padding(.horizontal, 10)
            .frame(height: 32)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.inner, style: .continuous)
                    .fill(Theme.Palette.hoverFill)
            )
            if model.disk.saved.isEmpty {
                Text("No saved words yet.")
                    .font(Theme.Typeface.body)
                    .foregroundColor(Theme.Palette.ink)
                    .padding(.top, Theme.Space.xs)
                Text("Tap the star on a word to keep it here.")
                    .font(Theme.Typeface.caption)
                    .foregroundColor(Theme.Palette.inkSecondary)
            } else if entries.isEmpty {
                Text("Nothing matches “\(query)”.")
                    .font(Theme.Typeface.body)
                    .foregroundColor(Theme.Palette.inkSecondary)
                    .padding(.top, Theme.Space.xs)
            } else {
                VStack(spacing: 0) {
                    ForEach(entries) { entry in
                        SavedRow(entry: entry)
                        if entry.word != entries.last?.word {
                            Rectangle()
                                .fill(Theme.Palette.separator)
                                .frame(height: 1)
                        }
                    }
                }
            }
        }
        .glassCard(.saved)
    }
}

struct SavedRow: View {
    let entry: WordEntry
    @EnvironmentObject var model: AppModel

    var body: some View {
        HStack(spacing: Theme.Space.s) {
            Button {
                model.openSaved(entry.word)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.word)
                        .font(Theme.Typeface.bodyEmph)
                        .foregroundColor(Theme.Palette.ink)
                    Text(model.disk.settings.showChinese && !entry.cn.isEmpty ? entry.cn : entry.pos)
                        .font(Theme.Typeface.caption)
                        .foregroundColor(Theme.Palette.inkSecondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            Image(systemName: "star.fill")
                .font(.system(size: 12))
                .foregroundColor(Theme.CardKind.saved.accent)
            Button {
                model.toggleSaved(entry.word)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Theme.Palette.inkSecondary)
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(PlainButtonStyle())
            .help("Remove from Saved")
        }
        .padding(.vertical, 8)
    }
}

struct SettingsView: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var login: LoginItem
    @State private var voicesOpen = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Metrics.cardGap) {
                languageCard
                speechCard
                reminderCard
                loginCard
                aboutCard
            }
            .padding(.horizontal, Theme.Metrics.edge)
            .padding(.vertical, Theme.Space.s)
        }
        .onAppear { model.prepareVoices() }
    }

    private var languageCard: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Text("Chinese meanings")
                .font(Theme.Typeface.title)
                .foregroundColor(Theme.Palette.ink)
            Toggle(isOn: Binding(
                get: { model.disk.settings.showChinese },
                set: { _ in model.toggleChinese() }
            )) {
                Text("Show 中文 under each word")
                    .font(Theme.Typeface.body)
                    .foregroundColor(Theme.Palette.ink)
            }
            .toggleStyle(SwitchToggleStyle())
            Text("Chinese meanings checked by AI — corrections welcome.")
                .font(Theme.Typeface.caption)
                .foregroundColor(Theme.Palette.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .neutralCard()
    }

    private var speechCard: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Text("Voice")
                .font(Theme.Typeface.title)
                .foregroundColor(Theme.Palette.ink)
            Button {
                voicesOpen.toggle()
            } label: {
                HStack {
                    Text(voiceLabel)
                        .font(Theme.Typeface.body)
                        .foregroundColor(Theme.Palette.ink)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: voicesOpen ? "chevron.up" : "chevron.down")
                        .foregroundColor(Theme.Palette.inkSecondary)
                }
                .padding(.horizontal, 10)
                .frame(height: 32)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.inner, style: .continuous)
                        .fill(Theme.Palette.hoverFill)
                )
            }
            .buttonStyle(PlainButtonStyle())
            if voicesOpen {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        voiceRow(id: nil, label: "English (United States)")
                        ForEach(model.voices) { voice in
                            voiceRow(id: voice.identifier, label: voice.label)
                        }
                    }
                }
                .frame(maxHeight: 140)
            }
            HStack {
                Text("Slower")
                Spacer()
                Text(rateLabel)
                Spacer()
                Text("Faster")
            }
            .font(Theme.Typeface.caption)
            .foregroundColor(Theme.Palette.inkSecondary)
            Slider(value: Binding(
                get: { model.disk.settings.speechRate },
                set: { model.setRate($0) }
            ), in: 0.35...0.6)
            Button("Speak today's word") {
                model.speak(model.library.entry(on: Date()).word)
            }
            .buttonStyle(Theme.SoftButtonStyle(kind: .word, height: 32))
        }
        .neutralCard()
    }

    private func voiceRow(id: String?, label: String) -> some View {
        let selected = model.disk.settings.voiceIdentifier == id
        return Button {
            model.setVoice(id)
            voicesOpen = false
        } label: {
            HStack {
                Text(label)
                    .font(Theme.Typeface.caption)
                    .foregroundColor(selected ? Theme.CardKind.word.accentText : Theme.Palette.ink)
                    .lineLimit(1)
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.CardKind.word.accentText)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var voiceLabel: String {
        if let id = model.disk.settings.voiceIdentifier,
           let match = model.voices.first(where: { $0.identifier == id }) {
            return match.label
        }
        return "English (United States)"
    }

    private var rateLabel: String {
        let rate = model.disk.settings.speechRate
        if abs(rate - 0.5) < 0.02 { return "Normal" }
        if rate < 0.5 { return "Slow" }
        return "Fast"
    }

    private var reminderCard: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Text("Daily reminder")
                .font(Theme.Typeface.title)
                .foregroundColor(Theme.Palette.ink)
            Toggle(isOn: Binding(
                get: { model.disk.settings.dailyReminder },
                set: { model.setReminder($0) }
            )) {
                Text("Nudge at 8:00")
                    .font(Theme.Typeface.body)
                    .foregroundColor(Theme.Palette.ink)
            }
            .toggleStyle(SwitchToggleStyle())
            Text("Off unless you turn it on. An ad-hoc signed app may not be allowed to notify.")
                .font(Theme.Typeface.caption)
                .foregroundColor(Theme.Palette.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .neutralCard()
    }

    private var loginCard: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Text("Launch at login")
                .font(Theme.Typeface.title)
                .foregroundColor(Theme.Palette.ink)
            Toggle(isOn: Binding(
                get: { login.enabled || login.needsApproval },
                set: { modelSetLogin($0) }
            )) {
                Text("Open Wordbit when you log in")
                    .font(Theme.Typeface.body)
                    .foregroundColor(Theme.Palette.ink)
            }
            .toggleStyle(SwitchToggleStyle())
            if login.needsApproval {
                Button("Approve in Login Items…") { login.openSettings() }
                    .buttonStyle(Theme.SoftButtonStyle(kind: .word, height: 32))
            }
            if !login.lastError.isEmpty && !login.needsApproval {
                Text(login.lastError)
                    .font(Theme.Typeface.caption)
                    .foregroundColor(Theme.Palette.danger)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text("If the old Word of the Day still opens at login, turn it off in System Settings. macOS doesn't let a new app delete that entry.")
                .font(Theme.Typeface.caption)
                .foregroundColor(Theme.Palette.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .neutralCard()
    }

    private func modelSetLogin(_ on: Bool) {
        login.set(on)
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Text("About")
                .font(Theme.Typeface.title)
                .foregroundColor(Theme.Palette.ink)
            Text("Wordbit \(version)")
                .font(Theme.Typeface.body)
                .foregroundColor(Theme.Palette.ink)
            Text("Made by @pohstep_x027 on X, new to vibe coding and open to suggestions and to learning.")
                .font(Theme.Typeface.body)
                .foregroundColor(Theme.Palette.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Text("Definitions and examples: Wiktionary (CC BY-SA 4.0) via kaikki.org, and Princeton WordNet 3.0. Pronunciations: Wiktionary and the CMU Pronouncing Dictionary. Chinese: ECDICT (MIT). Chinese meanings checked by AI — corrections welcome. Code: MIT, © 2026 badcookie.")
                .font(Theme.Typeface.caption)
                .foregroundColor(Theme.Palette.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("Show data licences") { showLicences() }
                .buttonStyle(Theme.SoftButtonStyle(kind: .word, height: 32))
            Button("Quit Wordbit") { NSApp.terminate(nil) }
                .buttonStyle(Theme.SoftButtonStyle(kind: .quiz, height: 32))
        }
        .neutralCard()
    }

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "2.0"
    }

    private func showLicences() {
        if let url = Bundle.main.url(forResource: "DATA-LICENSES", withExtension: "md") {
            NSWorkspace.shared.open(url)
        }
    }
}
