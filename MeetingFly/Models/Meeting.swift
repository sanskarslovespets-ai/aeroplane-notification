import Foundation
import EventKit

/// A lightweight, value-type snapshot of a calendar event that MeetingFly cares about.
///
/// We intentionally copy the fields we need out of `EKEvent` rather than holding onto
/// EventKit objects: `EKEvent` instances are tied to their originating `EKEventStore`
/// and can become invalid the moment the store refreshes, which happens often.
struct Meeting: Identifiable, Hashable {
    /// Stable identity for a single occurrence of an event (recurring events share an
    /// `eventIdentifier` across occurrences, so we key on identifier + start date).
    let id: String
    let eventIdentifier: String
    let title: String
    let startDate: Date
    let endDate: Date
    let organizer: String?
    let notes: String?
    let location: String?
    let url: URL?
    let hasAttendees: Bool
    let attendeeCount: Int

    var duration: TimeInterval { endDate.timeIntervalSince(startDate) }

    var platform: MeetingPlatform {
        MeetingLinkDetector.detectPlatform(for: self)
    }

    var joinURL: URL? {
        MeetingLinkDetector.detectJoinURL(for: self)
    }

    init?(event: EKEvent) {
        guard let identifier = event.eventIdentifier, let start = event.startDate, let end = event.endDate else {
            return nil
        }
        self.eventIdentifier = identifier
        self.id = "\(identifier)|\(start.timeIntervalSince1970)"
        self.title = event.title?.isEmpty == false ? event.title! : "Untitled Meeting"
        self.startDate = start
        self.endDate = end
        self.organizer = event.organizer?.name
        self.notes = event.notes
        self.location = event.location
        self.url = event.url
        self.hasAttendees = (event.attendees?.count ?? 0) > 0
        self.attendeeCount = event.attendees?.count ?? 0
    }

    /// Convenience initializer used for the "Test Airplane Reminder" / mock preview mode.
    init(
        id: String = UUID().uuidString,
        eventIdentifier: String = UUID().uuidString,
        title: String,
        startDate: Date,
        endDate: Date,
        organizer: String? = nil,
        notes: String? = nil,
        location: String? = nil,
        url: URL? = nil,
        hasAttendees: Bool = true,
        attendeeCount: Int = 1
    ) {
        self.id = id
        self.eventIdentifier = eventIdentifier
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.organizer = organizer
        self.notes = notes
        self.location = location
        self.url = url
        self.hasAttendees = hasAttendees
        self.attendeeCount = attendeeCount
    }

    static func == (lhs: Meeting, rhs: Meeting) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Meeting {
    /// A demo meeting used by the "Test Airplane Reminder" button and mock mode.
    static func demo() -> Meeting {
        let now = Date()
        return Meeting(
            title: "Demo Meeting",
            startDate: now.addingTimeInterval(5 * 60),
            endDate: now.addingTimeInterval(35 * 60),
            organizer: "Alex Rivera",
            notes: "Join: https://meet.google.com/abc-defg-hij",
            location: nil,
            url: URL(string: "https://meet.google.com/abc-defg-hij"),
            hasAttendees: true,
            attendeeCount: 4
        )
    }

    /// A small, varied set of upcoming meetings used by Settings → Animation →
    /// "Use mock meeting data for testing" — lets the menu bar, next-meeting
    /// summary, and reminder scheduling all be exercised without Calendar access.
    static func mockUpcoming() -> [Meeting] {
        let now = Date()
        return [
            Meeting(
                title: "Product Review",
                startDate: now.addingTimeInterval(12 * 60),
                endDate: now.addingTimeInterval(42 * 60),
                organizer: "Priya Nair",
                url: URL(string: "https://zoom.us/j/1234567890"),
                hasAttendees: true,
                attendeeCount: 6
            ),
            Meeting(
                title: "1:1 with Manager",
                startDate: now.addingTimeInterval(48 * 60),
                endDate: now.addingTimeInterval(78 * 60),
                organizer: "Jordan Lee",
                url: URL(string: "https://meet.google.com/xyz-mock-123"),
                hasAttendees: true,
                attendeeCount: 2
            ),
            Meeting(
                title: "All-Hands",
                startDate: now.addingTimeInterval(2 * 60 * 60),
                endDate: now.addingTimeInterval(2 * 60 * 60 + 45 * 60),
                organizer: "Ops Team",
                url: URL(string: "https://teams.microsoft.com/l/meetup-join/mock"),
                hasAttendees: true,
                attendeeCount: 40
            ),
        ]
    }
}
