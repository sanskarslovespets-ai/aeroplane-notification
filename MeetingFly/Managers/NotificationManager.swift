import Foundation
import UserNotifications
import AppKit

/// Optional system sound + local notification that can accompany the airplane overlay.
/// Kept separate from the overlay so either can be toggled off independently in Settings.
enum NotificationManager {
    static func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func playReminderSound(enabled: Bool) {
        guard enabled else { return }
        NSSound(named: "Glass")?.play()
    }

    static func postNotification(for meeting: Meeting, enabled: Bool) {
        guard enabled else { return }
        let content = UNMutableNotificationContent()
        content.title = meeting.title
        content.body = "\(MeetingDateFormatting.relativeStart(from: Date(), to: meeting.startDate)) · \(MeetingDateFormatting.timeRange(start: meeting.startDate, end: meeting.endDate))"
        content.sound = nil // the airplane overlay's own sound (if enabled) already covers this

        let request = UNNotificationRequest(identifier: meeting.id, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}
