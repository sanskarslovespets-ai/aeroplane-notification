import Foundation
import ServiceManagement

/// Thin wrapper around `SMAppService` for "start at login". Using the modern
/// ServiceManagement API means no separate helper-app bundle or legacy
/// `SMLoginItemSetEnabled` plumbing is required.
enum LaunchAtLoginManager {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Attempts to register/unregister the app as a login item. Throws are surfaced
    /// to the caller so the Settings UI can show a real error instead of silently
    /// failing (this can happen if the app isn't in /Applications, for example).
    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            if SMAppService.mainApp.status != .enabled {
                try SMAppService.mainApp.register()
            }
        } else {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            }
        }
    }
}
