import SwiftUI
import AppKit

struct PermissionsView: View {
    @EnvironmentObject var meetingManager: MeetingManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Calendar Access")
                        .font(.headline)
                    Text(statusLabel)
                        .font(.subheadline)
                        .foregroundStyle(statusColor)
                }
                Spacer()
            }

            Text("MeetingFly reads your calendar locally, on your Mac, to know when a meeting is about to start so it can fly the reminder across your screen. Nothing is uploaded anywhere — event data never leaves your device.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            switch meetingManager.permissionState {
            case .notDetermined:
                VStack(alignment: .leading, spacing: 10) {
                    InfoRow(icon: "calendar", text: "Needed to see your upcoming meetings and their times.")
                    InfoRow(icon: "bell.badge", text: "You'll get a reminder 5 minutes before each meeting by default — configurable above.")
                    InfoRow(icon: "hand.raised", text: "You can revoke this anytime from System Settings.")
                }
                .padding(14)
                .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))

                Button("Grant Calendar Access") {
                    Task { await meetingManager.requestAccess() }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

            case .requesting:
                ProgressView()
                    .controlSize(.small)

            case .denied, .restricted:
                VStack(alignment: .leading, spacing: 8) {
                    Text("Calendar access was denied or is restricted. MeetingFly can't see your meetings until it's enabled:")
                        .font(.callout)
                    Text("System Settings → Privacy & Security → Calendars → enable MeetingFly")
                        .font(.callout.monospaced())
                        .padding(8)
                        .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))

                    HStack {
                        Button("Open Privacy Settings") {
                            openCalendarPrivacySettings()
                        }
                        Button("I've Updated It — Check Again") {
                            meetingManager.refreshPermissionState()
                        }
                    }
                }

            case .authorized, .limited:
                Label("MeetingFly can read your calendars.", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(20)
        .frame(width: 460)
    }

    private var statusLabel: String {
        switch meetingManager.permissionState {
        case .notDetermined: return "Not yet requested"
        case .requesting: return "Requesting…"
        case .authorized: return "Granted"
        case .limited: return "Limited access"
        case .denied: return "Denied"
        case .restricted: return "Restricted by device policy"
        }
    }

    private var statusColor: Color {
        switch meetingManager.permissionState {
        case .authorized, .limited: return .green
        case .denied, .restricted: return .red
        case .notDetermined, .requesting: return .secondary
        }
    }

    private func openCalendarPrivacySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") else { return }
        NSWorkspace.shared.open(url)
    }
}

private struct InfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .frame(width: 16)
                .foregroundStyle(Color.accentColor)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
