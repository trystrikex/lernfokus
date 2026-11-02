import DeviceActivity

final class FocusMonitor: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        ScreenTimeStore.reconcile()
    }
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        // Delayed callbacks must reconcile the current session, not unlock a newer one.
        ScreenTimeStore.reconcile()
    }
}
