import ActivityKit
import Foundation

struct FocusAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var start: Date
        var focusEnd: Date
        var end: Date
    }
    var name: String
}
