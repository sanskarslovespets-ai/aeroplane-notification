import SwiftUI

/// The meeting details, laid out inside the banner's rectangular body (the
/// swallowtail notch on the left is left clear of text/controls).
struct MeetingBannerCardView: View {
    let meeting: Meeting
    let showJoinButton: Bool
    let onJoinTapped: () -> Void

    private var relative: String { MeetingDateFormatting.relativeStart(from: Date(), to: meeting.startDate) }
    private var timeRange: String { MeetingDateFormatting.timeRange(start: meeting.startDate, end: meeting.endDate) }

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(meeting.title)
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text("\(relative) · \(timeRange)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 5) {
                    Image(systemName: meeting.platform.symbolName)
                        .font(.system(size: 10, weight: .semibold))
                    Text(meeting.platform.displayName)
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                    if let organizer = meeting.organizer {
                        Text("· \(organizer)")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .foregroundStyle(meeting.platform.tintColor)
            }

            if showJoinButton, meeting.joinURL != nil {
                Spacer(minLength: 4)
                Button(action: onJoinTapped) {
                    Text("Join")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(meeting.platform.tintColor)
            }
        }
        .padding(.leading, 30)
        .padding(.trailing, 16)
        .padding(.vertical, 14)
        .frame(width: 300, height: 106, alignment: .leading)
        .background(.regularMaterial, in: BannerPennantShape())
        .overlay(
            BannerPennantShape()
                .stroke(Color.primary.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 6)
    }
}
