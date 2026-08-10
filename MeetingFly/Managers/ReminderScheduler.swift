import Foundation
import Combine
import AppKit

/// Computes exact fire dates for meeting reminders and reliably triggers a callback
/// at (meeting start − lead time), no matter what the process was doing at that moment.
///
/// Design notes:
/// - We never run a repeating "check every few seconds" timer. Instead we arm a single
///   `DispatchSourceTimer` for the *next* fire date only, then re-arm after it fires.
/// - The full schedule is rebuilt (not incrementally patched) whenever: calendar data
///   changes, relevant settings change, the Mac wakes from sleep, the system clock or
///   timezone changes, or the app launches. Rebuilding from scratch off of EventKit's
///   already-expanded event list is what makes recurring events and edits "just work" —
///   there's no separate recurrence state to keep in sync.
/// - Already-fired reminders are tracked by a stable `Meeting.id` (event identifier +
///   occurrence start date) in `firedMeetingIDs`, persisted to `UserDefaults` so a
///   relaunch within the same lookahead window doesn't re-show a reminder that already
///   fired, and pruned of anything outside the lookahead window to stay small.
@MainActor
final class ReminderScheduler: ObservableObject {
    @Published private(set) var nextMeeting: Meeting?
    @Published private(set) var nextMeetingFireDate: Date?

    /// Invoked exactly once per meeting occurrence, on the main actor, at fire time.
    var onReminderTriggered: ((Meeting) -> Void)?

    private let meetingManager: MeetingManager
    private let settings: ReminderSettings
    private var cancellables: Set<AnyCancellable> = []
    private var timer: DispatchSourceTimer?
    private var firedMeetingIDs: Set<String> {
        didSet { persistFiredIDs() }
    }

    private static let firedIDsDefaultsKey = "firedMeetingIDs"

    init(meetingManager: MeetingManager, settings: ReminderSettings) {
        self.meetingManager = meetingManager
        self.settings = settings
        self.firedMeetingIDs = Set(UserDefaults.standard.stringArray(forKey: Self.firedIDsDefaultsKey) ?? [])

        meetingManager.meetingsDidChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.rebuildSchedule() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSWorkspace.didWakeNotification)
            .sink { [weak self] _ in self?.rebuildSchedule() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .NSSystemClockDidChange)
            .sink { [weak self] _ in self?.rebuildSchedule() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)
            .sink { [weak self] _ in self?.rebuildSchedule() }
            .store(in: &cancellables)
    }

    /// Call after settings that affect scheduling change (lead time, meeting filter).
    func settingsDidChange() {
        rebuildSchedule()
    }

    /// Cancels the pending timer and re-derives it from the current meeting list.
    /// Safe to call as often as needed.
    func rebuildSchedule() {
        timer?.cancel()
        timer = nil

        pruneFiredIDs()

        let candidates = filteredMeetings()
        nextMeeting = candidates.first

        let leadSeconds = TimeInterval(settings.effectiveLeadMinutes * 60)
        let now = Date()

        // Find the soonest not-yet-fired reminder among upcoming candidates.
        let upcomingFireDates: [(meeting: Meeting, fireDate: Date)] = candidates
            .filter { !firedMeetingIDs.contains($0.id) }
            .map { ($0, $0.startDate.addingTimeInterval(-leadSeconds)) }
            .sorted { $0.fireDate < $1.fireDate }

        guard let next = upcomingFireDates.first else {
            nextMeetingFireDate = nil
            return
        }

        nextMeetingFireDate = next.fireDate

        // If we're already past (or exactly at) the fire date — e.g. the Mac was asleep
        // through it — fire immediately instead of silently dropping the reminder,
        // as long as the meeting hasn't already started+ended.
        if next.fireDate <= now {
            if next.meeting.endDate > now {
                fire(next.meeting)
            } else {
                firedMeetingIDs.insert(next.meeting.id)
                rebuildSchedule()
            }
            return
        }

        armTimer(fireDate: next.fireDate, meeting: next.meeting)
    }

    private func armTimer(fireDate: Date, meeting: Meeting) {
        let interval = fireDate.timeIntervalSinceNow
        let source = DispatchSource.makeTimerSource(queue: .main)
        source.schedule(deadline: .now() + max(0, interval))
        source.setEventHandler { [weak self] in
            guard let self else { return }
            self.timer = nil
            self.fire(meeting)
        }
        timer = source
        source.resume()
    }

    private func fire(_ meeting: Meeting) {
        guard !firedMeetingIDs.contains(meeting.id) else {
            rebuildSchedule()
            return
        }
        firedMeetingIDs.insert(meeting.id)

        if !settings.remindersPaused {
            onReminderTriggered?(meeting)
        }

        // Immediately compute the next reminder so back-to-back meetings both fire.
        rebuildSchedule()
    }

    private func filteredMeetings() -> [Meeting] {
        meetingManager.upcomingMeetings.filter { meeting in
            switch settings.meetingFilter {
            case .all:
                return true
            case .withAttendeesOnly:
                return meeting.hasAttendees
            case .withVideoLinkOnly:
                return meeting.platform != .none
            }
        }
    }

    private func pruneFiredIDs() {
        let liveIDs = Set(meetingManager.upcomingMeetings.map(\.id))
        firedMeetingIDs.formIntersection(liveIDs)
    }

    private func persistFiredIDs() {
        UserDefaults.standard.set(Array(firedMeetingIDs), forKey: Self.firedIDsDefaultsKey)
    }

    /// Used by the "Test Airplane Reminder" button: fires immediately without touching
    /// the real fired-IDs bookkeeping for actual meetings.
    func triggerTestReminder() {
        onReminderTriggered?(Meeting.demo())
    }
}
