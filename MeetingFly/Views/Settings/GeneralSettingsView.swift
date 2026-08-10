import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject private var settings = ReminderSettings.shared
    @State private var launchAtLoginError: String?

    var body: some View {
        Form {
            Section {
                Toggle("Launch MeetingFly at login", isOn: Binding(
                    get: { settings.launchAtLogin },
                    set: { newValue in
                        settings.launchAtLogin = newValue
                        do {
                            try LaunchAtLoginManager.setEnabled(newValue)
                            launchAtLoginError = nil
                        } catch {
                            launchAtLoginError = error.localizedDescription
                            settings.launchAtLogin = LaunchAtLoginManager.isEnabled
                        }
                    }
                ))
                if let launchAtLoginError {
                    Text(launchAtLoginError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Toggle("Show menu bar icon", isOn: $settings.showMenuBarIcon)
                    .help("MeetingFly has no Dock icon — turning this off leaves no way to reach Settings until you turn it back on via Finder or relaunch.")
            } header: {
                Text("Startup")
            }

            Section {
                Toggle("Play a sound with each reminder", isOn: $settings.soundEnabled)
                Toggle("Show a system notification with each reminder", isOn: $settings.notificationEnabled)
                Toggle("Show \"Join Meeting\" button", isOn: $settings.joinButtonEnabled)
                Toggle("Pause all reminders", isOn: $settings.remindersPaused)
            } header: {
                Text("Behavior")
            }
        }
        .formStyle(.grouped)
    }
}
