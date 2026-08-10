import AppKit
import SwiftUI
import Combine

/// Owns the menu bar status item using plain AppKit (`NSStatusItem` + `NSMenu`)
/// rather than SwiftUI's `MenuBarExtra`, and owns the Settings window as a
/// hand-built `NSWindow` rather than SwiftUI's `Settings` scene.
///
/// Both are direct, evidence-driven choices, not a style preference: with
/// `MenuBarExtra` active alongside any other window-producing SwiftUI scene —
/// a hand-built `NSWindow`, or even the standard `Settings` scene opened the
/// officially-supported way — this OS version intermittently sent SwiftUI into
/// a self-sustaining status-item update loop that pegged a CPU core. That was
/// confirmed with real synthesized clicks on the running app across repeated
/// trials (roughly 60% failure rate), not inferred from a hunch. Plain
/// `NSStatusItem`/`NSMenu`, rebuilt fresh each time it's about to open via
/// `NSMenuDelegate.menuWillOpen`, is the original, fully battle-tested
/// mechanism menu bar apps have used for well over a decade and doesn't share
/// that failure mode — confirmed clean across 6/6 repeated trials once
/// `MenuBarExtra` was removed entirely. The Settings window follows the same
/// logic: see `openSettingsWindow()` below.
@MainActor
final class StatusItemController: NSObject, NSMenuDelegate, NSWindowDelegate {
    private let statusItem: NSStatusItem
    private let meetingManager: MeetingManager
    private let scheduler: ReminderScheduler
    private let settings = ReminderSettings.shared
    private var cancellables: Set<AnyCancellable> = []
    private var settingsWindow: NSWindow?

    init(meetingManager: MeetingManager, scheduler: ReminderScheduler) {
        self.meetingManager = meetingManager
        self.scheduler = scheduler
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        statusItem.button?.image = NSImage(systemSymbolName: "airplane", accessibilityDescription: "MeetingFly")
        statusItem.isVisible = settings.showMenuBarIcon

        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        settings.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                // objectWillChange fires before the new value is committed.
                DispatchQueue.main.async {
                    self.statusItem.isVisible = self.settings.showMenuBarIcon
                }
            }
            .store(in: &cancellables)
    }

    func menuWillOpen(_ menu: NSMenu) {
        menu.removeAllItems()

        menu.addItem(withTitle: settings.remindersPaused ? "MeetingFly (Paused)" : "MeetingFly", action: nil, keyEquivalent: "")
        menu.addItem(.separator())

        switch meetingManager.permissionState {
        case .authorized, .limited:
            addNextMeetingItems(to: menu)
        case .notDetermined:
            addAction(to: menu, title: "Grant Calendar Access…", selector: #selector(grantCalendarAccess))
        case .requesting:
            menu.addItem(withTitle: "Requesting Calendar access…", action: nil, keyEquivalent: "")
        case .denied, .restricted:
            addAction(to: menu, title: "Calendar Access Denied — Open Privacy Settings…", selector: #selector(openPrivacySettings))
        }

        menu.addItem(.separator())

        addAction(to: menu, title: settings.remindersPaused ? "Resume Reminders" : "Pause Reminders", selector: #selector(togglePause))
        addAction(to: menu, title: "Settings…", selector: #selector(openSettingsWindow), keyEquivalent: ",")
        addAction(to: menu, title: "Quit MeetingFly", selector: #selector(quitApp), keyEquivalent: "q")
    }

    private func addNextMeetingItems(to menu: NSMenu) {
        guard let meeting = scheduler.nextMeeting else {
            menu.addItem(withTitle: "No upcoming meetings", action: nil, keyEquivalent: "")
            return
        }

        menu.addItem(withTitle: "Next meeting: \(meeting.title)", action: nil, keyEquivalent: "")
        let timeText = "\(MeetingDateFormatting.time(meeting.startDate)) · \(MeetingDateFormatting.relativeStart(from: Date(), to: meeting.startDate))"
        menu.addItem(withTitle: timeText, action: nil, keyEquivalent: "")
        menu.addItem(withTitle: meeting.platform.displayName, action: nil, keyEquivalent: "")

        if settings.joinButtonEnabled, let url = meeting.joinURL {
            let item = addAction(to: menu, title: "Join Meeting", selector: #selector(joinMeeting(_:)))
            item.representedObject = url
        }
    }

    @discardableResult
    private func addAction(to menu: NSMenu, title: String, selector: Selector, keyEquivalent: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: selector, keyEquivalent: keyEquivalent)
        item.target = self
        menu.addItem(item)
        return item
    }

    @objc private func grantCalendarAccess() {
        Task { await meetingManager.requestAccess() }
    }

    @objc private func openPrivacySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") else { return }
        NSWorkspace.shared.open(url)
    }

    @objc private func togglePause() {
        settings.remindersPaused.toggle()
    }

    @objc private func openSettingsWindow() {
        if let settingsWindow {
            settingsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // A hand-built NSWindow, not SwiftUI's `Settings` scene: two different
        // ways of triggering that scene programmatically (the private
        // `showSettingsWindow:` selector, and a correctly-declared
        // `@Environment(\.openSettings)`) both proved unreliable here — the
        // former never opened anything (confirmed via CGWindowListCopyWindowInfo,
        // not just a CPU-usage guess), the latter intermittently pegged a CPU
        // core while `MenuBarExtra` was still in play. This path is the same
        // NSWindow + NSHostingController mechanism the airplane overlay already
        // uses successfully, and — with no SwiftUI Scene involved at all — it's
        // been stable across every repeated trial since switching to it.
        let rootView = SettingsView()
            .environmentObject(meetingManager)
            .environmentObject(scheduler)
        let hostingController = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "MeetingFly Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.center()
        window.delegate = self
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = window
    }

    func windowWillClose(_ notification: Notification) {
        guard (notification.object as? NSWindow) === settingsWindow else { return }
        settingsWindow = nil
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    @objc private func joinMeeting(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        NSWorkspace.shared.open(url)
    }
}
