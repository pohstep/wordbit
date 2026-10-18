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
                            Text(model.tr(.tabSaved))
                        }
                        .font(Theme.Typeface.caption)
                        .foregroundColor(Theme.CardKind.saved.accentText)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    WordCard(entry: entry, heading: model.tr(.tabSaved))
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
                Theme.Eyebrow(text: model.tr(.tabSaved), kind: .saved)
                Spacer()
                Image(systemName: "star.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.CardKind.saved.accent)
            }
            HStack(spacing: Theme.Space.s) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.Palette.inkTertiary)
                TextField(model.tr(.searchSaved), text: $query)
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
                EmptyTabHint()
                    .padding(.top, Theme.Space.xs)
                Text(model.tr(.savedEmptyHint))
                    .font(Theme.Typeface.caption)
                    .foregroundColor(Theme.Palette.inkSecondary)
            } else if entries.isEmpty {
                Text(model.trf(.savedNoMatch, query))
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
            .help(model.tr(.helpRemoveSaved))
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
                interfaceCard
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

    private var interfaceCard: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Text(model.tr(.language))
                .font(Theme.Typeface.title)
                .foregroundColor(Theme.Palette.ink)
            Picker(selection: Binding(
                get: { model.disk.settings.interfaceLanguage },
                set: { model.setInterfaceLanguage($0) }
            )) {
                Text(model.tr(.languageAutomatic)).tag(InterfaceLanguage.automatic)
                Text(model.tr(.languageEnglish)).tag(InterfaceLanguage.english)
                Text(model.tr(.languageChinese)).tag(InterfaceLanguage.chinese)
            } label: {
                Text(model.tr(.language))
            }
            .pickerStyle(MenuPickerStyle())
            .labelsHidden()
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(model.tr(.languageCaption))
                .font(Theme.Typeface.caption)
                .foregroundColor(Theme.Palette.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .neutralCard()
    }

    private var languageCard: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Text(model.tr(.chineseMeanings))
                .font(Theme.Typeface.title)
                .foregroundColor(Theme.Palette.ink)
            Toggle(isOn: Binding(
                get: { model.disk.settings.showChinese },
                set: { _ in model.toggleChinese() }
            )) {
                Text(model.tr(.showChinese))
                    .font(Theme.Typeface.body)
                    .foregroundColor(Theme.Palette.ink)
            }
            .toggleStyle(SwitchToggleStyle())
            Text(model.tr(.chineseChecked))
                .font(Theme.Typeface.caption)
                .foregroundColor(Theme.Palette.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .neutralCard()
    }

    private var speechCard: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Text(model.tr(.voice))
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
                        voiceRow(id: nil, label: model.tr(.voiceDefault))
                        ForEach(model.voices) { voice in
                            voiceRow(id: voice.identifier, label: voice.label)
                        }
                    }
                }
                .frame(maxHeight: 140)
            }
            HStack {
                Text(model.tr(.slower))
                Spacer()
                Text(rateLabel)
                Spacer()
                Text(model.tr(.faster))
            }
            .font(Theme.Typeface.caption)
            .foregroundColor(Theme.Palette.inkSecondary)
            Slider(value: Binding(
                get: { model.disk.settings.speechRate },
                set: { model.setRate($0) }
            ), in: 0.35...0.6)
            Button(model.tr(.speakToday)) {
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
        return model.tr(.voiceDefault)
    }

    private var rateLabel: String {
        let rate = model.disk.settings.speechRate
        if abs(rate - 0.5) < 0.02 { return model.tr(.rateNormal) }
        if rate < 0.5 { return model.tr(.rateSlow) }
        return model.tr(.rateFast)
    }

    private var reminderCard: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Text(model.tr(.dailyReminder))
                .font(Theme.Typeface.title)
                .foregroundColor(Theme.Palette.ink)
            Toggle(isOn: Binding(
                get: { model.disk.settings.dailyReminder },
                set: { model.setReminder($0) }
            )) {
                Text(model.tr(.remindMe))
                    .font(Theme.Typeface.body)
                    .foregroundColor(Theme.Palette.ink)
            }
            .toggleStyle(SwitchToggleStyle())
            DatePicker(selection: reminderTime, displayedComponents: DatePickerComponents.hourAndMinute) {
                Text(model.tr(.reminderTime))
            }
            .labelsHidden()
            Text(model.tr(.reminderNote))
                .font(Theme.Typeface.caption)
                .foregroundColor(Theme.Palette.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .neutralCard()
    }

    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                var parts = DateComponents()
                parts.hour = model.disk.settings.reminderHour
                parts.minute = model.disk.settings.reminderMinute
                return Calendar.current.date(from: parts) ?? Date()
            },
            set: { newValue in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                let hour = parts.hour ?? 8
                let minute = parts.minute ?? 0
                model.setReminderTime(hour: hour, minute: minute)
            }
        )
    }

    private var loginCard: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Text(model.tr(.launchAtLogin))
                .font(Theme.Typeface.title)
                .foregroundColor(Theme.Palette.ink)
            Toggle(isOn: Binding(
                get: { login.enabled || login.needsApproval },
                set: { modelSetLogin($0) }
            )) {
                Text(model.tr(.openAtLogin))
                    .font(Theme.Typeface.body)
                    .foregroundColor(Theme.Palette.ink)
            }
            .toggleStyle(SwitchToggleStyle())
            if login.needsApproval {
                Button(model.tr(.approveLogin)) { login.openSettings() }
                    .buttonStyle(Theme.SoftButtonStyle(kind: .word, height: 32))
            }
            if !login.lastError.isEmpty && !login.needsApproval {
                Text(login.lastError)
                    .font(Theme.Typeface.caption)
                    .foregroundColor(Theme.Palette.danger)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .neutralCard()
    }

    private func modelSetLogin(_ on: Bool) {
        login.set(on)
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Group {
                Text(model.tr(.about))
                    .font(Theme.Typeface.title)
                    .foregroundColor(Theme.Palette.ink)
                Text(model.trf(.aboutVersion, version))
                    .font(Theme.Typeface.body)
                    .foregroundColor(Theme.Palette.ink)
                Text(model.tr(.aboutMadeBy))
                    .font(Theme.Typeface.body)
                    .foregroundColor(Theme.Palette.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(model.tr(.aboutCredits))
                    .font(Theme.Typeface.caption)
                    .foregroundColor(Theme.Palette.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button(model.tr(.showLicences)) { showLicences() }
                    .buttonStyle(Theme.SoftButtonStyle(kind: .word, height: 32))
            }
            Group {
                updateSection
                Button(model.tr(.resetProgress)) { model.confirmResetProgress() }
                    .buttonStyle(Theme.SoftButtonStyle(kind: .word, height: 32))
                if !model.resetNotice.isEmpty {
                    Text(model.resetNotice)
                        .font(Theme.Typeface.caption)
                        .foregroundColor(Theme.Palette.danger)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Button(model.tr(.menuQuit)) { NSApp.terminate(nil) }
                    .buttonStyle(Theme.SoftButtonStyle(kind: .quiz, height: 32))
            }
        }
        .neutralCard()
    }

    private var updateSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            Button(model.tr(.checkForUpdates)) { model.checkForUpdates() }
                .buttonStyle(Theme.SoftButtonStyle(kind: .word, height: 32))
                .disabled(model.updateState == .checking)
            updateStatus
        }
    }

    @ViewBuilder
    private var updateStatus: some View {
        switch model.updateState {
        case .idle:
            EmptyView()
        case .checking:
            Text(model.tr(.updateChecking))
                .font(Theme.Typeface.caption)
                .foregroundColor(Theme.Palette.inkSecondary)
        case .upToDate:
            Text(model.tr(.updateUpToDate))
                .font(Theme.Typeface.caption)
                .foregroundColor(Theme.Palette.inkSecondary)
        case .failed:
            Text(model.tr(.updateFailed))
                .font(Theme.Typeface.caption)
                .foregroundColor(Theme.Palette.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        case .available(let version, _):
            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                Text(model.trf(.updateAvailable, version))
                    .font(Theme.Typeface.body)
                    .foregroundColor(Theme.Palette.ink)
                Button(model.tr(.updateDownload)) { model.openUpdatePage() }
                    .buttonStyle(Theme.SoftButtonStyle(kind: .word, height: 32))
                Text(model.tr(.updateBrew))
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundColor(Theme.Palette.inkSecondary)
            }
        }
    }

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "2.2.0"
    }

    private func showLicences() {
        if let url = Bundle.main.url(forResource: "DATA-LICENSES", withExtension: "md") {
            NSWorkspace.shared.open(url)
        }
    }
}
