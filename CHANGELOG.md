# Changelog

## v2.2.1 — 2026-10-19

- **Always your Mac's local time.** The new word and the streak follow the clock on this Mac. The time zone setting is gone, and an older saved time zone choice is ignored. Your progress, Saved words and streak are kept.

## v2.2.0 — 2026-10-19

- **Interface language.** English is the source language. Every menu, tab, setting, hint, notification and the About text also has Simplified Chinese. The app follows the Mac: Simplified Chinese when the first language is Chinese, English otherwise. **Settings → Language** is **Automatic (follow Mac)**, **English**, or **简体中文**, and it switches straight away. Dates use the system locale's formatter (no fixed British day-month pattern). Automatic follows the Mac's locale; English or 简体中文 follows that language's locale. The words stay English, and the meanings are in Chinese today.
- **About.** Settings shows **Wordbit** and the version from the app. **Check for updates** asks GitHub only when you click it, then says you're up to date or that a version is available, with a download page and `brew upgrade --cask wordbit`. It does not download by itself, and it does not check in the background. Offline, it just says it couldn't check. **Reset progress** asks first, then deletes `state.json`.
- **Open at login stays off** until you turn it on. A new install no longer turns it on by itself.

## v2.1.0 — 2026-10-18

- **Your time zone.** The new word and the streak follow the Mac's own time zone. Saved dates and streaks stay as plain dates, so they carry over.
- **Reminder time.** Pick the time. The reminder stays off until you turn it on. The note now says to allow notifications in System Settings if macOS blocks them.
- **Day-one hints.** An empty Review tab (before you have done anything) and an empty Saved tab point you to the Quiz and Pictures tabs.
- **Universal build.** One app for Intel and Apple-chip Macs.
- **install.sh** opens the app when it finishes, prints the macOS 15 "Open Anyway" steps, and says so when it removes the older "Word of the Day" app.
- **Homebrew cask** recipe at `packaging/homebrew/Casks/wordbit.rb`.
- Removed the Settings note about the old Word of the Day login item.

## v2.0.0 — 2026-10-18

The first public release. Wordbit replaces the older "Word of the Day" app.

- **New name and look:** Wordbit, with a new frosted panel, a red dictionary icon, and a little book in the menu bar.
- **Six tabs:** Today, Review, Quiz, Pictures, Saved and Settings.
- **Review boxes:** words come back after 1 day, 3 days, 1 week, 2 weeks, 1 month and 3 months. Again sends a word back to Box 1, Good moves it up one box, Easy moves it up two.
- **Daily quiz:** five questions a day, the same for everyone on that date.
- **Pictures game:** 156 harder emoji words, each with look-alike wrong answers.
- **Saved words** with search.
- **Daily streak:** a day counts when the quiz or the due reviews are finished. No streak freezes.
- **Chinese meanings** for every word (from ECDICT). Chinese meanings checked by AI — corrections welcome. One click hides them.
- **Speech:** hear the word or the example, with your choice of voice and speed.
- **Optional daily reminder** at 8:00, off by default.
- **Works fully offline.** No network connection at all.
- **Download a `.dmg`** from Releases. It is unsigned; the README shows how to open it the first time.
- Keeps the 400 words from version 1, in the same order, so the word for each date is unchanged.

## v1 — Word of the Day

- A private menu bar app showing one word a day. Not released publicly.
