import SwiftUI

@main struct FokusApp: App {
    @State private var controller = FocusController()
    var body: some Scene {
        WindowGroup { FocusView(controller: controller).preferredColorScheme(.dark) }
    }
}
