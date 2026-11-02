import Foundation

// Only the main app reads session data. Live Activities receive their state via ActivityKit.
enum SessionStore {
    static var session: FocusSession? {
        get {
            guard let data = UserDefaults.standard.data(forKey: "session") else { return nil }
            return try? JSONDecoder().decode(FocusSession.self, from: data)
        }
        set {
            guard let newValue else {
                UserDefaults.standard.removeObject(forKey: "session")
                return
            }
            UserDefaults.standard.set(try? JSONEncoder().encode(newValue), forKey: "session")
        }
    }
}
