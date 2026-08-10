import SwiftUI

struct MeetingTypesSettingsView: View {
    @EnvironmentObject var scheduler: ReminderScheduler
    @ObservedObject private var settings = ReminderSettings.shared

    var body: some View {
        Form {
            Section {
                Picker("Trigger reminders for", selection: Binding(
                    get: { settings.meetingFilter },
                    set: { newValue in
                        settings.meetingFilter = newValue
                        scheduler.settingsDidChange()
                    }
                )) {
                    ForEach(MeetingFilter.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
                .pickerStyle(.radioGroup)
            } header: {
                Text("Which Events Count as Meetings")
            } footer: {
                Text("Applies to every calendar EventKit exposes. Cancelled events and all-day events are always excluded.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}
