import Foundation

// Interface language.
// English is the source language (Sources/L10nEn.swift).
// Each extra language is one file with a switch over every L10nKey.
// Word entries (the English word, its definition, and its Chinese meaning)
// are not in these tables.

enum L10nKey: String, CaseIterable {
    case menuAbout
    case menuQuit
    case menuEdit
    case menuUndo
    case menuRedo
    case menuCut
    case menuCopy
    case menuPaste
    case menuSelectAll
    case menuCopyWord
    case tooltipIdle
    case tooltipDueMany
    case notificationTitle
    case notificationBody
    case tabToday
    case tabReview
    case tabQuiz
    case tabPictures
    case tabSaved
    case tabSettings
    case allClear
    case dueMany
    case helpPreviousDay
    case helpNextDay
    case helpBackToday
    case searchSaved
    case savedEmptyHint
    case savedNoMatch
    case helpRemoveSaved
    case helpSaveWord
    case helpCopyWord
    case chineseMeanings
    case showChinese
    case chineseChecked
    case helpChinese
    case voice
    case voiceDefault
    case slower
    case faster
    case rateNormal
    case rateSlow
    case rateFast
    case speakToday
    case helpSpeak
    case dailyReminder
    case remindMe
    case reminderTime
    case reminderNote
    case launchAtLogin
    case openAtLogin
    case approveLogin
    case language
    case languageAutomatic
    case languageEnglish
    case languageChinese
    case languageCaption
    case about
    case aboutVersion
    case aboutMadeBy
    case aboutCredits
    case showLicences
    case checkForUpdates
    case updateChecking
    case updateUpToDate
    case updateAvailable
    case updateDownload
    case updateFailed
    case updateBrew
    case resetProgress
    case resetTitle
    case resetDetail
    case resetConfirm
    case cancel
    case resetFailed
    case wordsDidntLoad
    case wordsMissing
    case wordOfTheDay
    case onThisDay
    case origin
    case inReviewBox
    case notInReview
    case streak
    case best
    case dayOne
    case dayMany
    case todayCountsTomorrow
    case finishQuizHint
    case takeQuizArrow
    case offerQuestionOne
    case offerQuestionMany
    case offerSpread
    case offerTomorrow
    case addThem
    case notNow
    case nothingDue
    case nothingDueDetail
    case takeTodaysQuiz
    case nothingYet
    case tryThe
    case orWord
    case tabWord
    case tapToShow
    case again
    case good
    case easy
    case quizNotReady
    case quizNotReadyDetail
    case quizProgress
    case whatDoesThisMean
    case fillBlank
    case done
    case next
    case seeScore
    case ofTotal
    case todayCountsStreak
    case seeAnswers
    case quizBlurb5
    case quizBlurb4
    case quizBlurb3
    case quizBlurbLow
    case picturesDidntLoad
    case picturesMissing
    case whichWord
    case level
    case correct
    case answerIs
    case playAgain
    case picturePerfect
    case pictureMost
    case pictureSome
}

enum AppLanguage: Equatable {
    case english
    case chinese
}

enum InterfaceLanguage {
    static let automatic = "auto"
    static let english = "en"
    static let chinese = "zh-Hans"

    static func normalized(_ stored: String) -> String {
        if stored == english || stored == chinese || stored == automatic {
            return stored
        }
        return automatic
    }

    /// Simplified Chinese when the Mac's first preferred language is zh.
    /// Anything else, including an empty list, stays English.
    static func resolve(_ stored: String) -> AppLanguage {
        let choice = normalized(stored)
        if choice == english {
            return .english
        }
        if choice == chinese {
            return .chinese
        }
        let preferred = Locale.preferredLanguages
        let first = preferred.first ?? ""
        if first.hasPrefix("zh") {
            return .chinese
        }
        return .english
    }

    /// Automatic uses the Mac's locale. An explicit language uses that locale,
    /// still through DateFormatter's localized template (no fixed day-month order).
    static func locale(for stored: String) -> Locale {
        let choice = normalized(stored)
        if choice == chinese {
            return Locale(identifier: "zh-Hans")
        }
        if choice == english {
            return Locale(identifier: "en")
        }
        return Locale.autoupdatingCurrent
    }
}

enum L10n {
    static func text(_ key: L10nKey, language: AppLanguage) -> String {
        let value: String
        if language == .chinese {
            value = L10nZhHans.text(key)
        } else {
            value = L10nEn.text(key)
        }
        if value.isEmpty {
            return L10nEn.text(key)
        }
        return value
    }

    static func coverageProblems() -> [String] {
        var problems: [String] = []
        let sameOnPurpose: [L10nKey] = [
            .tooltipIdle, .notificationTitle, .aboutVersion,
            .languageEnglish, .languageChinese, .updateBrew
        ]
        for key in L10nKey.allCases {
            let english = L10nEn.text(key)
            let chinese = L10nZhHans.text(key)
            if english.isEmpty {
                problems.append("english empty \(key.rawValue)")
            }
            if chinese.isEmpty {
                problems.append("chinese empty \(key.rawValue)")
            }
            if formatSpecifiers(english) != formatSpecifiers(chinese) {
                problems.append("format \(key.rawValue)")
            }
            var allowed = false
            for item in sameOnPurpose where item == key {
                allowed = true
            }
            if english == chinese && !allowed {
                problems.append("untranslated \(key.rawValue)")
            }
        }
        if L10nEn.text(.updateUpToDate) != "You're up to date" {
            problems.append("up to date copy")
        }
        if L10nEn.text(.checkForUpdates) != "Check for updates" {
            problems.append("check copy")
        }
        if L10nEn.text(.updateDownload) != "Download" {
            problems.append("download copy")
        }
        if L10nEn.text(.languageAutomatic) != "Automatic (follow Mac)" {
            problems.append("language copy")
        }
        if L10nEn.text(.languageEnglish) != "English" {
            problems.append("english name")
        }
        if L10nEn.text(.languageChinese) != "简体中文" {
            problems.append("chinese name")
        }
        if L10nEn.text(.resetProgress) != "Reset progress" {
            problems.append("reset copy")
        }
        if L10nEn.text(.updateBrew) != "brew upgrade --cask wordbit" {
            problems.append("brew copy")
        }
        if L10nEn.text(.updateAvailable) != "Version %@ is available" {
            problems.append("available copy")
        }
        if !containsHan(L10nZhHans.text(.tabToday)) {
            problems.append("chinese today")
        }
        if !containsHan(L10nZhHans.text(.about)) {
            problems.append("chinese about")
        }
        if InterfaceLanguage.resolve(InterfaceLanguage.english) != .english {
            problems.append("resolve english")
        }
        if InterfaceLanguage.resolve(InterfaceLanguage.chinese) != .chinese {
            problems.append("resolve chinese")
        }
        if InterfaceLanguage.normalized("nope") != InterfaceLanguage.automatic {
            problems.append("normalize language")
        }
        return problems
    }

    static func containsHan(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            if scalar.value >= 0x4E00 && scalar.value <= 0x9FFF {
                return true
            }
        }
        return false
    }

    /// Specifier letters only, so "Version %@" and "已有新版本 %@" can be compared.
    static func formatSpecifiers(_ text: String) -> String {
        var output = ""
        var pending = false
        for scalar in text.unicodeScalars {
            if pending {
                if scalar.value == 37 {
                    pending = false
                    continue
                }
                if scalar.value == 64 || scalar.value == 100 {
                    output.append(Character(scalar))
                    pending = false
                    continue
                }
                let value = scalar.value
                let isFlag = value == 46 || value == 45 || value == 36 || (value >= 48 && value <= 57)
                if !isFlag {
                    pending = false
                }
                continue
            }
            if scalar.value == 37 {
                pending = true
            }
        }
        return output
    }
}
