import SwiftUI
import ActivityKit
import UserNotifications

@MainActor @Observable
final class FocusController {
    var session = SessionStore.session
    var presets: [FocusPreset] = {
        guard let data = UserDefaults.standard.data(forKey: "presets"),
              let values = try? JSONDecoder().decode([FocusPreset].self, from: data) else { return FocusPreset.defaults }
        return values
    }()
    var message: String?
    var busy = false
    func add(_ preset: FocusPreset) {
        presets.append(preset)
        UserDefaults.standard.set(try? JSONEncoder().encode(presets), forKey: "presets")
    }
    func refresh() {
        session = SessionStore.session
        if let session, session.phase(at: .now) == .finished {
            Task { await finish() }
        }
    }
    func start(_ preset: FocusPreset) async {
        guard !busy, session == nil else { return }
        busy = true
        defer { busy = false }
        let now = Date.now
        let focusEnd = now.addingTimeInterval(Double(preset.minutes * 60))
        let newSession = FocusSession(name: preset.name, start: now, focusEnd: focusEnd,
                                      end: focusEnd.addingTimeInterval(Double(preset.breakMinutes * 60)), blocksApps: false)
        SessionStore.session = newSession
        session = newSession
        if ActivityAuthorizationInfo().areActivitiesEnabled {
            do {
                for old in Activity<FocusAttributes>.activities { await old.end(nil, dismissalPolicy: .immediate) }
                _ = try Activity.request(attributes: FocusAttributes(name: preset.name), content: ActivityContent(
                    state: FocusAttributes.ContentState(start: now, focusEnd: focusEnd, end: newSession.end),
                    staleDate: newSession.end), pushType: nil)
            } catch { message = "Der Fokus läuft, aber die Sperrbildschirm-Anzeige konnte nicht starten: \(error.localizedDescription)" }
        } else { message = "Der Fokus läuft. Aktiviere Live-Aktivitäten in den iPhone-Einstellungen für die Sperrbildschirm-Anzeige." }
        await scheduleNotifications(newSession)
    }
    func finish() async {
        guard !busy else { return }
        busy = true
        defer { busy = false }
        session = nil
        SessionStore.session = nil
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        for activity in Activity<FocusAttributes>.activities { await activity.end(nil, dismissalPolicy: .immediate) }
    }
    private func scheduleNotifications(_ session: FocusSession) async {
        let center = UNUserNotificationCenter.current()
        guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true else { return }
        let events: [(String, Date)] = session.end > session.focusEnd
            ? [("Geschafft! Deine Pause beginnt.", session.focusEnd), ("Deine Pause ist vorbei. Bereit für die nächste Lernrunde?", session.end)]
            : [("Geschafft! Deine Fokuszeit ist vorbei.", session.focusEnd)]
        for (index, event) in events.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "Fokus"
            content.body = event.0
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, event.1.timeIntervalSinceNow), repeats: false)
            try? await center.add(UNNotificationRequest(identifier: "fokus-\(index)", content: content, trigger: trigger))
        }
    }
}
