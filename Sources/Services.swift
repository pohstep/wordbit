import AVFoundation
import Combine
import Foundation
import ServiceManagement
import UserNotifications

// MARK: - Speech

final class SpeechController {
    private let synth = AVSpeechSynthesizer()

    func speak(_ text: String, voiceID: String?, rate: Double) {
        if synth.isSpeaking {
            synth.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: text)
        if let voiceID = voiceID, let voice = AVSpeechSynthesisVoice(identifier: voiceID) {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        let clamped = min(0.6, max(0.35, rate))
        utterance.rate = Float(clamped)
        synth.speak(utterance)
    }

    func stop() {
        if synth.isSpeaking {
            synth.stopSpeaking(at: .immediate)
        }
    }
}

// MARK: - Launch at login

final class LoginItem: ObservableObject {
    @Published private(set) var status: SMAppService.Status = .notRegistered
    @Published private(set) var lastError: String = ""

    var enabled: Bool { status == .enabled }
    var needsApproval: Bool { status == .requiresApproval }

    init() { refresh() }

    func refresh() {
        status = SMAppService.mainApp.status
    }

    func set(_ on: Bool) {
        do {
            if on {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            lastError = ""
        } catch {
            lastError = error.localizedDescription
        }
        refresh()
        UserDefaults.standard.set(on, forKey: "launchAtLogin")
    }

    func openSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}

// MARK: - Optional daily reminder (off unless the user turns it on)

enum Reminder {
    static let identifier = "wordbit.daily"

    static func restoreIfAuthorized(enabled: Bool, onGranted: @escaping () -> Void) {
        guard enabled else { return }
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                DispatchQueue.main.async {
                    onGranted()
                }
            }
        }
    }

    static func enable(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            completion(granted)
        }
    }

    static func disable() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    static func schedule(hour: Int, minute: Int, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        var components = DateComponents()
        components.hour = min(23, max(0, hour))
        components.minute = min(59, max(0, minute))
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.add(request, withCompletionHandler: nil)
    }
}

// MARK: - Manual update check (only when the user clicks)

enum UpdateCheck {
    static let latestURL = "https://api.github.com/repos/pohstep/wordbit/releases/latest"
    static let releasesPage = "https://github.com/pohstep/wordbit/releases/latest"

    static func fetch(localVersion: String, completion: @escaping (UpdateState) -> Void) {
        guard let url = URL(string: latestURL) else {
            completion(.failed)
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("Wordbit", forHTTPHeaderField: "User-Agent")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            let outcome = interpret(data: data, response: response, error: error, localVersion: localVersion)
            completion(outcome)
        }
        task.resume()
    }

    static func interpret(data: Data?, response: URLResponse?, error: Error?, localVersion: String) -> UpdateState {
        if error != nil {
            return .failed
        }
        guard let http = response as? HTTPURLResponse else {
            return .failed
        }
        if http.statusCode != 200 {
            return .failed
        }
        guard let data = data else {
            return .failed
        }
        let object = try? JSONSerialization.jsonObject(with: data)
        guard let json = object as? [String: Any] else {
            return .failed
        }
        guard let tag = json["tag_name"] as? String else {
            return .failed
        }
        if tag.isEmpty {
            return .failed
        }
        let page = json["html_url"] as? String ?? releasesPage
        if isNewer(tag, than: localVersion) {
            return .available(version: displayVersion(tag), page: page)
        }
        return .upToDate
    }

    static func displayVersion(_ raw: String) -> String {
        strip(raw)
    }

    static func isNewer(_ remote: String, than local: String) -> Bool {
        let remoteParts = parts(remote)
        let localParts = parts(local)
        if let remoteParts = remoteParts, let localParts = localParts {
            let count = max(remoteParts.count, localParts.count)
            var index = 0
            while index < count {
                let left = index < remoteParts.count ? remoteParts[index] : 0
                let right = index < localParts.count ? localParts[index] : 0
                if left != right {
                    return left > right
                }
                index += 1
            }
            return false
        }
        let remoteText = strip(remote)
        let localText = strip(local)
        return remoteText != localText && remoteText > localText
    }

    static func strip(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("v") || text.hasPrefix("V") {
            text = String(text.dropFirst())
        }
        if let index = text.firstIndex(where: { $0 == "-" || $0 == "+" }) {
            text = String(text[..<index])
        }
        return text
    }

    static func parts(_ raw: String) -> [Int]? {
        let text = strip(raw)
        if text.isEmpty {
            return nil
        }
        var numbers: [Int] = []
        for piece in text.split(separator: ".") {
            if piece.isEmpty {
                return nil
            }
            if let number = Int(piece) {
                numbers.append(number)
            } else {
                return nil
            }
        }
        if numbers.isEmpty {
            return nil
        }
        return numbers
    }

    static func sampleProblems() -> [String] {
        var problems: [String] = []
        if isNewer("v2.3.0", than: "2.2.0") == false {
            problems.append("version 2.3")
        }
        if isNewer("v2.2.0", than: "2.2.0") {
            problems.append("version equal")
        }
        if isNewer("2.2", than: "2.2.0") {
            problems.append("version short")
        }
        if isNewer("v2.10.0", than: "2.9.0") == false {
            problems.append("version 2.10")
        }
        if isNewer("v2.0.0", than: "2.2.0") {
            problems.append("version older")
        }
        if displayVersion("v2.2.0") != "2.2.0" {
            problems.append("version display")
        }
        return problems
    }
}
