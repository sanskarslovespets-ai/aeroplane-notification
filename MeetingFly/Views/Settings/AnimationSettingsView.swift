import SwiftUI

struct AnimationSettingsView: View {
    @EnvironmentObject var scheduler: ReminderScheduler
    @EnvironmentObject var meetingManager: MeetingManager
    @ObservedObject private var settings = ReminderSettings.shared

    var body: some View {
        Form {
            Section {
                Toggle("Enable reminder animation", isOn: $settings.animationEnabled)

                VStack(alignment: .leading) {
                    HStack {
                        Text("Duration")
                        Spacer()
                        Text("\(settings.animationDuration, specifier: "%.1f")s")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $settings.animationDuration, in: 4...14, step: 0.5)
                }
                .disabled(!settings.animationEnabled)

                Picker("Character size", selection: Binding(
                    get: { settings.airplaneSize },
                    set: { settings.airplaneSize = $0 }
                )) {
                    ForEach(AirplaneSize.allCases) { size in
                        Text(size.label).tag(size)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(!settings.animationEnabled)
            } header: {
                Text("Animation")
            }

            Section {
                MascotPickerGrid(selection: Binding(
                    get: { settings.mascot },
                    set: { newValue in
                        settings.mascot = newValue
                        scheduler.triggerTestReminder()
                    }
                ))
                .disabled(!settings.animationEnabled)
            } header: {
                Text("Character")
            } footer: {
                Text("Picking a character shows a quick preview of it flying.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Picker("Show on", selection: Binding(
                    get: { settings.screenTarget },
                    set: { settings.screenTarget = $0 }
                )) {
                    ForEach(OverlayScreenTarget.allCases) { target in
                        Text(target.label).tag(target)
                    }
                }
                .pickerStyle(.radioGroup)
            } header: {
                Text("Display")
            }

            Section {
                Toggle("Use mock meeting data for testing", isOn: Binding(
                    get: { settings.mockModeEnabled },
                    set: { newValue in
                        settings.mockModeEnabled = newValue
                        meetingManager.refresh()
                        scheduler.settingsDidChange()
                    }
                ))
                .help("When enabled, the menu bar and \"Next meeting\" summary use a few generated demo meetings instead of your real calendar — useful for development without waiting for a real event or granting Calendar access.")

                Button {
                    scheduler.triggerTestReminder()
                } label: {
                    Label("Test Reminder Animation", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
            } header: {
                Text("Testing")
            } footer: {
                Text("Triggers the reminder animation immediately with a demo meeting, without waiting for a real one.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

/// A 5-column grid of the ten reminder characters, each a tappable tile
/// showing a cheap emoji preview (the real in-flight glyph is the animated,
/// hand-drawn/SF Symbol view in `MascotGlyph.swift` — this grid stays simple
/// and static so ten simultaneous live animations don't run in Settings).
private struct MascotPickerGrid: View {
    @Binding var selection: ReminderMascot

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(ReminderMascot.allCases) { mascot in
                Button {
                    selection = mascot
                } label: {
                    VStack(spacing: 4) {
                        Text(mascot.previewEmoji)
                            .font(.system(size: 22))
                        Text(mascot.label)
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundStyle(selection == mascot ? .white : .secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selection == mascot ? Color.accentColor : Color.primary.opacity(0.05))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
