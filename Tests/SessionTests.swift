import Foundation

@main struct SessionTests {
    static func main() throws {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let session = FocusSession(name: "Pomodoro", start: start, focusEnd: start.addingTimeInterval(1500), end: start.addingTimeInterval(1800), blocksApps: true)
        assert(session.phase(at: start) == .focus)
        assert(session.phase(at: start.addingTimeInterval(1499)) == .focus)
        assert(session.phase(at: start.addingTimeInterval(1500)) == .rest)
        assert(session.phase(at: start.addingTimeInterval(1799)) == .rest)
        assert(session.phase(at: start.addingTimeInterval(1800)) == .finished)
        let restored = try JSONDecoder().decode(FocusSession.self, from: JSONEncoder().encode(session))
        assert(restored.id == session.id && restored.focusEnd == session.focusEnd)
        let noBreak = FocusSession(name: "Stunde", start: start, focusEnd: start.addingTimeInterval(3600), end: start.addingTimeInterval(3600), blocksApps: true)
        assert(noBreak.phase(at: start.addingTimeInterval(3600)) == .finished)
        let midnight = Date(timeIntervalSince1970: 1_799_967_000)
        let crossing = FocusSession(name: "Nacht", start: midnight, focusEnd: midnight.addingTimeInterval(3600), end: midnight.addingTimeInterval(3900), blocksApps: true)
        assert(crossing.phase(at: midnight.addingTimeInterval(3601)) == .rest)
        print("8 session boundary/persistence checks passed")
    }
}
