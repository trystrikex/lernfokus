import Foundation
import FamilyControls
import ManagedSettings

enum ScreenTimeStore {
    static let group = "group.de.fokuslern.app"
    static let defaults = UserDefaults(suiteName: group)!
    static let shield = ManagedSettingsStore(named: .init("fokus"))
    static var session: FocusSession? {
        get { read(FocusSession.self, key: "session") }
        set { write(newValue, key: "session") }
    }
    static var selection: FamilyActivitySelection {
        get { read(FamilyActivitySelection.self, key: "selection") ?? FamilyActivitySelection() }
        set { write(newValue, key: "selection") }
    }
    static func reconcile(at date: Date = .now) {
        guard let session, session.blocksApps, session.phase(at: date) == .focus else {
            shield.clearAllSettings()
            return
        }
        let selected = selection
        shield.shield.applications = selected.applicationTokens.isEmpty ? nil : selected.applicationTokens
        shield.shield.applicationCategories = selected.categoryTokens.isEmpty ? nil : .specific(selected.categoryTokens)
        shield.shield.webDomains = selected.webDomainTokens.isEmpty ? nil : selected.webDomainTokens
        shield.shield.webDomainCategories = selected.categoryTokens.isEmpty ? nil : .specific(selected.categoryTokens)
    }
    private static func read<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    private static func write<T: Encodable>(_ value: T?, key: String) {
        guard let value else { defaults.removeObject(forKey: key); return }
        defaults.set(try? JSONEncoder().encode(value), forKey: key)
    }
}
