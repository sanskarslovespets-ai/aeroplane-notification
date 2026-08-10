import SwiftUI

private enum SettingsTab: Hashable {
    case general, reminders, meetingTypes, animation, permissions
}

/// Root of the Settings window (the SwiftUI `Settings` scene's content).
struct SettingsView: View {
    @EnvironmentObject var meetingManager: MeetingManager
    @EnvironmentObject var scheduler: ReminderScheduler
    @State private var selectedTab: SettingsTab = .general

    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView()
                .tag(SettingsTab.general)
                .tabItem { Label("General", systemImage: "gearshape") }

            ReminderSettingsView()
                .tag(SettingsTab.reminders)
                .tabItem { Label("Reminders", systemImage: "clock") }

            MeetingTypesSettingsView()
                .tag(SettingsTab.meetingTypes)
                .tabItem { Label("Meeting Types", systemImage: "person.2") }

            AnimationSettingsView()
                .tag(SettingsTab.animation)
                .tabItem { Label("Animation", systemImage: "airplane") }

            PermissionsView()
                .tag(SettingsTab.permissions)
                .tabItem { Label("Permissions", systemImage: "lock.shield") }
        }
        .frame(width: 460)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear {
            // Land straight on Permissions when access hasn't been sorted out
            // yet — the most useful place to start for anyone who opened
            // Settings before granting Calendar access.
            switch meetingManager.permissionState {
            case .notDetermined, .denied, .restricted:
                selectedTab = .permissions
            case .authorized, .limited, .requesting:
                break
            }
        }
    }
}
