import AppKit
import Combine
import Foundation

/// Owns the app's long-lived managers and wires them together. MeetingFly has no
/// Dock icon (`.accessory` activation policy, set in Info.plist via `LSUIElement`)
/// and never opens any window on its own at launch.
///
/// The menu bar icon is a plain AppKit `NSStatusItem` (`StatusItemController`),
/// not SwiftUI's `MenuBarExtra` — see that file's header comment for why: on
/// this OS version, `MenuBarExtra` coexisting with any other window-producing
/// scene intermittently pegged a CPU core, confirmed by repeated real clicks
/// on the running app. `AppDelegate` no longer needs to proactively open
/// anything itself either; `StatusItemController`'s menu offers a direct
/// "Grant Calendar Access…" item whenever permission hasn't been decided yet —
/// discovering that by opening the menu is the expected first move in any
/// menu-bar-only app anyway.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let meetingManager = MeetingManager()
    let scheduler: ReminderScheduler
    private var statusItemController: StatusItemController?

    private var cancellables: Set<AnyCancellable> = []

    override init() {
        self.scheduler = ReminderScheduler(meetingManager: meetingManager, settings: .shared)
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItemController = StatusItemController(meetingManager: meetingManager, scheduler: scheduler)

        scheduler.onReminderTriggered = { meeting in
            AirplaneOverlayController.shared.show(meeting: meeting, settings: .shared)
        }

        if ReminderSettings.shared.notificationEnabled {
            NotificationManager.requestAuthorizationIfNeeded()
        }

        if ReminderSettings.shared.mockModeEnabled || meetingManager.permissionState == .authorized || meetingManager.permissionState == .limited {
            meetingManager.refresh()
        }

        // Recheck permission when the app regains focus, e.g. after the user grants
        // access in System Settings and switches back — no reason to make them
        // relaunch the app for that to take effect.
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in self?.meetingManager.refreshPermissionState() }
            .store(in: &cancellables)

        scheduler.rebuildSchedule()

        // Dev/QA hook only: lets the airplane reminder be exercised headlessly
        // (e.g. from a shell script) without clicking "Test Airplane Reminder"
        // in Settings. Has no effect unless this exact env var is set.
        let env = ProcessInfo.processInfo.environment
        if env["MEETINGFLY_TEST_REMINDER"] == "1" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.scheduler.triggerTestReminder()
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
