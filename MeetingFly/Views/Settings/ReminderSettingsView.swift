import SwiftUI

struct ReminderSettingsView: View {
    @EnvironmentObject var scheduler: ReminderScheduler
    @ObservedObject private var settings = ReminderSettings.shared

    var body: some View {
        Form {
            Section {
                Picker("Remind me", selection: Binding(
                    get: { settings.leadTime },
                    set: { newValue in
                        settings.leadTime = newValue
                        scheduler.settingsDidChange()
                    }
                )) {
                    ForEach(ReminderLeadTime.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
                .pickerStyle(.menu)

                if settings.leadTime == .custom {
                    Stepper(value: Binding(
                        get: { settings.customLeadTimeMinutes },
                        set: { newValue in
                            settings.customLeadTimeMinutes = newValue
                            scheduler.settingsDidChange()
                        }
                    ), in: 1...60) {
                        Text("\(settings.customLeadTimeMinutes) minute\(settings.customLeadTimeMinutes == 1 ? "" : "s") before")
                    }
                }
            } header: {
                Text("Reminder Timing")
            } footer: {
                Text("The airplane appears this many minutes before each meeting starts.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}
