import Foundation

enum MeetingDateFormatting {
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    /// e.g. "10:00 AM – 10:30 AM"
    static func timeRange(start: Date, end: Date) -> String {
        "\(timeFormatter.string(from: start)) – \(timeFormatter.string(from: end))"
    }

    static func time(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }

    /// e.g. "Starts in 5 minutes" / "Starting now" / "Started 2 minutes ago"
    static func relativeStart(from now: Date, to start: Date) -> String {
        let interval = start.timeIntervalSince(now)
        let minutes = Int((interval / 60).rounded())
        if minutes > 1 {
            return "Starts in \(minutes) minutes"
        } else if minutes == 1 {
            return "Starts in 1 minute"
        } else if minutes == 0 {
            return "Starting now"
        } else {
            let ago = abs(minutes)
            return ago == 1 ? "Started 1 minute ago" : "Started \(ago) minutes ago"
        }
    }

    /// e.g. "30 min" or "1 hr 15 min"
    static func durationLabel(_ interval: TimeInterval) -> String {
        let totalMinutes = max(0, Int((interval / 60).rounded()))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours == 0 {
            return "\(minutes) min"
        } else if minutes == 0 {
            return "\(hours) hr"
        } else {
            return "\(hours) hr \(minutes) min"
        }
    }
}
