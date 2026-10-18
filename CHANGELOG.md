# Changelog

## v2.1.0 — 2026-10-18

- **Your time zone.** The new word and the streak follow the Mac's own time zone. Settings can switch to China time (Asia/Shanghai). Saved dates and streaks stay as plain dates, so they carry over.
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
