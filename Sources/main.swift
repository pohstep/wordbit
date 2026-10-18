import AppKit
import Combine
import SwiftUI
import UserNotifications

let aboutBlurb = "Made by @pohstep_x027 on X, new to vibe coding and open to suggestions and to learning."

let creditsText = """
\(aboutBlurb)

Definitions and examples from Wiktionary (CC BY-SA 4.0) via kaikki.org, \
with some from Princeton WordNet 3.0. Pronunciations from Wiktionary or the \
CMU Pronouncing Dictionary. Chinese glosses from ECDICT (MIT). Chinese meanings checked by AI — corrections welcome.
"""

final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate, UNUserNotificationCenterDelegate {
    let library = WordLibrary()
    lazy var model = AppModel(library: library)
    let login = LoginItem()
    var statusItem: NSStatusItem!
    let popover = NSPopover()
    var hosting: NSHostingController<AnyView>!
    var bag = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(togglePopover(_:))
        }

        let root = AnyView(RootView().environmentObject(model).environmentObject(login))
        hosting = NSHostingController(rootView: root)
        hosting.sizingOptions = []
        hosting.view.wantsLayer = true
        hosting.view.layer?.backgroundColor = NSColor.clear.cgColor

        popover.contentViewController = hosting
        popover.contentSize = NSSize(width: Theme.Metrics.popover.width, height: Theme.Metrics.popover.height)
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self

        buildMenu()
        model.bootstrap(login: login)
        updateStatusImage()

        model.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                DispatchQueue.main.async { self?.updateStatusImage() }
            }
            .store(in: &bag)

        if CommandLine.arguments.contains("--show") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { self.showPopover() }
        }
    }

    func popoverDidShow(_ notification: Notification) {
        guard let window = popover.contentViewController?.view.window else { return }
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
    }

    func popoverDidClose(_ notification: Notification) {
        model.speech.stop()
    }

    func buildMenu() {
        let main = NSMenu()
        let appItem = NSMenuItem()
        main.addItem(appItem)
        let appMenu = NSMenu()
        let about = appMenu.addItem(withTitle: "About Wordbit", action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit Wordbit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu

        let editItem = NSMenuItem()
        main.addItem(editItem)
        let edit = NSMenu(title: "Edit")
        edit.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        edit.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        edit.addItem(NSMenuItem.separator())
        edit.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        edit.addItem(NSMenuItem.separator())
        let copyWord = edit.addItem(withTitle: "Copy Word", action: #selector(copyWord), keyEquivalent: "C")
        copyWord.target = self
        editItem.submenu = edit
        NSApp.mainMenu = main
    }

    @objc func showAbout() {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        let options: [NSApplication.AboutPanelOptionKey: Any] = [
            .credits: NSAttributedString(string: creditsText, attributes: attrs)
        ]
        NSApp.orderFrontStandardAboutPanel(options: options)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func copyWord() {
        model.copyEntry(model.displayedEntry)
    }

    func updateStatusImage() {
        guard let button = statusItem?.button else { return }
        let due = model.dueCount
        button.image = Self.statusImage(due: due > 0)
        button.toolTip = due > 0 ? "Wordbit — \(due) to review" : "Wordbit"
    }

    @objc func togglePopover(_ sender: Any?) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            showPopover()
        }
    }

    func showPopover() {
        guard let button = statusItem.button else { return }
        model.refreshClock()
        login.refresh()
        updateStatusImage()
        popover.contentSize = NSSize(width: Theme.Metrics.popover.width, height: Theme.Metrics.popover.height)
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        showPopover()
        completionHandler()
    }

    static let menuIcon: NSImage? = {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        for name in ["menubar-natural-18", "menubar-natural-18@2x"] {
            guard let url = Bundle.main.url(forResource: name, withExtension: "png"),
                  let data = try? Data(contentsOf: url),
                  let rep = NSBitmapImageRep(data: data) else { continue }
            rep.size = size
            image.addRepresentation(rep)
        }
        if image.representations.isEmpty { return nil }
        image.isTemplate = false
        return image
    }()

    static func statusImage(due: Bool) -> NSImage {
        if let icon = menuIcon {
            if !due { return icon }
            let badged = NSImage(size: icon.size, flipped: false) { rect in
                icon.draw(in: rect)
                // Blue dot with a white ring, so it reads on the oxblood book and on light or dark bars.
                let dot = NSRect(x: rect.maxX - 6.4, y: rect.maxY - 6.4, width: 6, height: 6)
                NSColor.white.setFill()
                NSBezierPath(ovalIn: dot).fill()
                NSColor.systemBlue.setFill()
                NSBezierPath(ovalIn: dot.insetBy(dx: 1, dy: 1)).fill()
                return true
            }
            badged.isTemplate = false
            return badged
        }
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { rect in
            let inset = rect.insetBy(dx: 1.2, dy: 1.2)
            let box = NSBezierPath(roundedRect: inset, xRadius: 4, yRadius: 4)
            box.lineWidth = 1.3
            NSColor.black.setStroke()
            box.stroke()
            let letter = inset.insetBy(dx: inset.width * 0.20, dy: inset.height * 0.22)
            drawW(in: letter, color: .black, lineWidth: 1.35)
            if due {
                NSColor.black.setFill()
                NSBezierPath(ovalIn: NSRect(x: rect.maxX - 6.2, y: rect.maxY - 6.2, width: 4.6, height: 4.6)).fill()
            }
            return true
        }
        image.isTemplate = true
        return image
    }

    static func drawW(in rect: NSRect, color: NSColor, lineWidth: CGFloat) {
        let path = NSBezierPath()
        let left = rect.minX
        let right = rect.maxX
        let top = rect.maxY
        let bottom = rect.minY
        let width = rect.width
        path.move(to: NSPoint(x: left, y: top))
        path.line(to: NSPoint(x: left + width * 0.25, y: bottom))
        path.line(to: NSPoint(x: left + width * 0.50, y: top))
        path.line(to: NSPoint(x: left + width * 0.75, y: bottom))
        path.line(to: NSPoint(x: right, y: top))
        path.lineWidth = lineWidth
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        color.setStroke()
        path.stroke()
    }
}

func makeIconset(_ directory: String) {
    // AppKit image drawing wants an application object, even for this one-shot.
    _ = NSApplication.shared
    try? FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
    let sizes = [(16, 1), (16, 2), (32, 1), (32, 2), (128, 1), (128, 2), (256, 1), (256, 2), (512, 1), (512, 2)]
    for (points, scale) in sizes {
        let pixels = points * scale
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        ) else { continue }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        let side = CGFloat(pixels)
        let rect = NSRect(x: side * 0.08, y: side * 0.08, width: side * 0.84, height: side * 0.84)
        let path = NSBezierPath(roundedRect: rect, xRadius: side * 0.20, yRadius: side * 0.20)
        let start = NSColor(srgbRed: 0x6A / 255, green: 0x4D / 255, blue: 0xF4 / 255, alpha: 1)
        let end = NSColor(srgbRed: 0x46 / 255, green: 0x26 / 255, blue: 0xC9 / 255, alpha: 1)
        NSGradient(starting: start, ending: end)?.draw(in: path, angle: -90)
        let letter = rect.insetBy(dx: rect.width * 0.22, dy: rect.height * 0.24)
        AppDelegate.drawW(in: letter, color: .white, lineWidth: side * 0.045)
        NSGraphicsContext.restoreGraphicsState()
        let name = scale == 1 ? "icon_\(points)x\(points).png" : "icon_\(points)x\(points)@2x.png"
        if let data = rep.representation(using: .png, properties: [:]) {
            try? data.write(to: URL(fileURLWithPath: directory + "/" + name))
        }
    }
}

enum SelfCheck {
    static func run() -> Int32 {
        let library = WordLibrary()
        var problems: [String] = []
        if library.words.count != 400 { problems.append("words \(library.words.count), expected 400") }
        if library.pictures.count < 100 || library.pictures.count > 160 {
            problems.append("pictures \(library.pictures.count)")
        }
        let missingCN = library.words.filter { $0.cn.isEmpty }.count
        if missingCN > 0 { problems.append("words missing chinese \(missingCN)") }

        Shanghai.apply("china")
        if let day = Shanghai.date(from: "2026-10-18") {
            let index = library.index(on: day)
            let word = library.entry(on: day).word
            print("today 2026-10-18 index \(index) \(word)")
            if index != 290 || word != "derivative" {
                problems.append("day index drifted: \(index) \(word)")
            }
        }
        if let epoch = Shanghai.date(from: "2026-01-01"), library.entry(on: epoch).word != "dormant" {
            problems.append("epoch word is \(library.entry(on: epoch).word)")
        }
        Shanghai.apply("local")
        if let day = Shanghai.date(from: "2026-10-18") {
            let index = library.index(on: day)
            let word = library.entry(on: day).word
            print("local 2026-10-18 index \(index) \(word)")
            if index != 290 || word != "derivative" {
                problems.append("local zone day index drifted: \(index) \(word)")
            }
        }
        if let epoch = Shanghai.date(from: "2026-01-01"), library.entry(on: epoch).word != "dormant" {
            problems.append("local zone epoch word is \(library.entry(on: epoch).word)")
        }
        Shanghai.apply("china")

        let expectedBlanks = [
            ("convoluted", "convolute"),
            ("debilitate", "debilitating"),
            ("idiosyncrasy", "idiosyncrasies"),
            ("wane", "waned"),
            ("vex", "vexed")
        ]
        for (word, piece) in expectedBlanks {
            guard let entry = library.entry(for: word),
                  let masked = QuizBuilder.mask(example: entry.example, word: entry.word) else {
                problems.append("mask failed \(word)")
                continue
            }
            if !masked.contains("______") || masked.lowercased().contains(piece) {
                problems.append("mask missed \(word): \(masked)")
            }
        }

        var groups: [String: Int] = [:]
        var glyphs = Set<String>()
        for picture in library.pictures {
            groups[picture.distractorGroup, default: 0] += 1
            if picture.glyph.isEmpty { problems.append("empty glyph \(picture.word)") }
            if picture.cn.isEmpty { problems.append("empty picture cn \(picture.word)") }
            if !glyphs.insert(picture.glyph).inserted { problems.append("duplicate glyph \(picture.word)") }
            let wrong = (picture.distractors ?? []).map { $0.lowercased() }
            if wrong.count < 4 || Set(wrong).count != wrong.count || wrong.contains(picture.word.lowercased()) {
                problems.append("picture distractors \(picture.word)")
            }
        }
        for (group, count) in groups where count < 4 {
            problems.append("group \(group) has \(count)")
        }

        for key in ["2026-01-01", "2026-09-28", "2026-10-18"] {
            guard let date = Shanghai.date(from: key) else { continue }
            let questions = QuizBuilder.build(
                words: library.words,
                todayIndex: library.index(on: date),
                seed: QuizBuilder.seed(for: key)
            )
            if questions.count != 5 {
                problems.append("\(key) quiz count \(questions.count)")
                continue
            }
            let todayWord = library.entry(on: date).word
            if !questions.contains(where: { $0.word == todayWord }) {
                problems.append("\(key) quiz missed today's word")
            }
            if Set(questions.map { $0.word }).count != 5 {
                problems.append("\(key) duplicate quiz answers")
            }
            let answerWords = Set(questions.map { $0.word })
            for question in questions {
                guard let entry = library.entry(for: question.word) else {
                    problems.append("\(key) missing \(question.word)")
                    continue
                }
                if question.options.count != 4 || Set(question.options).count != 4 {
                    problems.append("\(key) \(question.word) options")
                }
                guard question.options.indices.contains(question.answerIndex) else {
                    problems.append("\(key) \(question.word) answer index")
                    continue
                }
                let expected = question.kind == .blank ? entry.word : entry.definition
                if question.options[question.answerIndex] != expected {
                    problems.append("\(key) \(question.word) answer text")
                }
                if question.options.filter({ $0 == expected }).count != 1 {
                    problems.append("\(key) \(question.word) answer shown twice")
                }
                if question.kind == .blank && !question.prompt.contains("______") {
                    problems.append("\(key) \(question.word) blank")
                }
                if question.kind == .blank {
                    for option in question.options where option != question.word && answerWords.contains(option) {
                        problems.append("\(key) answer \(option) reused as a choice")
                    }
                }
                if question.kind == .meaning {
                    let correct = question.options[question.answerIndex]
                    for other in questions where other.word != question.word && other.options.contains(correct) {
                        problems.append("\(key) definition reused")
                    }
                }
            }
        }

        let round = PictureBuilder.build(pictures: library.pictures, seedKey: "2026-10-18:0")
        if round.count != 10 { problems.append("picture round \(round.count)") }
        let pictureAnswers = Set(round.map { $0.word })
        for question in round {
            print("picture \(question.glyph) \(question.word): \(question.options.joined(separator: " / "))")
        }
        for question in round {
            if question.options.count != 4 || Set(question.options).count != 4 {
                problems.append("picture options \(question.word)")
            }
            if !question.options.indices.contains(question.answerIndex)
                || question.options[question.answerIndex] != question.word {
                problems.append("picture answer \(question.word)")
            }
            for option in question.options where option != question.word && pictureAnswers.contains(option) {
                problems.append("picture answer \(option) reused")
            }
            if question.glyph.isEmpty { problems.append("picture glyph \(question.word)") }
            let source = library.pictures.first { $0.word == question.word }
            let close = Set((source?.distractors ?? []).map { $0.lowercased() })
            for option in question.options where option != question.word && !close.contains(option.lowercased()) {
                problems.append("picture option \(option) is not a close distractor for \(question.word)")
            }
        }

        if problems.isEmpty {
            print("words \(library.words.count) pictures \(library.pictures.count)")
            print("ok")
            return 0
        }
        for problem in problems { print("fail: \(problem)") }
        return 1
    }
}

let arguments = CommandLine.arguments
if let index = arguments.firstIndex(of: "--make-iconset"), index + 1 < arguments.count {
    makeIconset(arguments[index + 1])
    exit(0)
}
if arguments.contains("--check") {
    exit(SelfCheck.run())
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
