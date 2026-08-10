import SwiftUI

@main
struct MeetingFlyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Every real window in this app — the status item's menu, the
        // Settings window, the airplane overlay — is managed imperatively via
        // AppKit (StatusItemController, AirplaneOverlayController), not as
        // SwiftUI scenes. On this OS version, SwiftUI's `MenuBarExtra` and
        // `Settings` scenes each proved unreliable in ways confirmed by direct
        // testing (a status-item update loop that pegged a CPU core, and a
        // `Settings` scene that silently failed to open at all depending on
        // how it was triggered) — see StatusItemController.swift for the full
        // account. `Settings { EmptyView() }` exists only because `App`
        // requires at least one `Scene`; it's intentionally never opened.
        Settings {
            EmptyView()
        }
    }
}
