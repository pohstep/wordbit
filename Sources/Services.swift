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

    static func restoreIfAuthorized(enabled: Bool, hour: Int, minute: Int) {
        guard enabled else { return }
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                schedule(hour: hour, minute: minute)
            }
        }
    }

    static func enable(hour: Int, minute: Int, completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            if granted { schedule(hour: hour, minute: minute) }
            completion(granted)
        }
    }

    static func disable() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    static func schedule(hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Wordbit"
        content.body = "Today's word is waiting. A quiz or a review keeps the streak."
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
