import Foundation

struct FocusPreset: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var minutes: Int
    var breakMinutes: Int
    static let defaults = [
        FocusPreset(name: "Pomodoro", minutes: 25, breakMinutes: 5),
        FocusPreset(name: "Deep Work", minutes: 60, breakMinutes: 0),
        FocusPreset(name: "Lernmarathon", minutes: 50, breakMinutes: 10)
    ]
}

struct FocusSession: Codable, Identifiable {
    var id = UUID()
    var name: String
    var start: Date
    var focusEnd: Date
    var end: Date
    var blocksApps: Bool
    func phase(at date: Date) -> Phase {
        if date >= end { return .finished }
        return date >= focusEnd ? .rest : .focus
    }
    enum Phase { case focus, rest, finished }
}
