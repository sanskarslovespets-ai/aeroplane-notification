import Foundation
import EventKit
import Combine

/// Owns the `EKEventStore`, handles Calendar permission, and turns raw `EKEvent`s
/// into `Meeting` snapshots. This is the only type in the app that talks to EventKit.
@MainActor
final class MeetingManager: ObservableObject {
    enum PermissionState: Equatable {
        case notDetermined
        case requesting
        case authorized
        case denied
        case restricted
        /// Full access granted but only write-only / limited on some OS versions.
        case limited
    }

    @Published private(set) var permissionState: PermissionState = .notDetermined
    @Published private(set) var upcomingMeetings: [Meeting] = []

    /// Fires whenever the underlying calendar data changes or a fresh fetch completes,
    /// so the scheduler knows to recompute reminder fire dates.
    let meetingsDidChange = PassthroughSubject<Void, Never>()

    private let eventStore = EKEventStore()
    private var changeObserver: NSObjectProtocol?
    /// How far ahead we look for meetings. Wide enough to always cover "the next
    /// meeting", narrow enough to keep enumeration fast.
    private let lookaheadInterval: TimeInterval = 60 * 60 * 24 * 3 // 3 days

    init() {
        permissionState = Self.currentPermissionState()
        observeStoreChanges()
    }

    deinit {
        if let changeObserver {
            NotificationCenter.default.removeObserver(changeObserver)
        }
    }

    private func observeStoreChanges() {
        changeObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: eventStore,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.refresh()
            }
        }
    }

    private static func currentPermissionState() -> PermissionState {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .notDetermined: return .notDetermined
        case .authorized: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        case .fullAccess: return .authorized
        case .writeOnly: return .limited
        @unknown default: return .denied
        }
    }

    /// Requests Calendar access. Safe to call repeatedly; EventKit only prompts once
    /// per authorization lifetime, subsequent calls just resolve with the stored decision.
    func requestAccess() async {
        permissionState = .requesting
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            permissionState = granted ? .authorized : .denied
            if granted {
                refresh()
            }
        } catch {
            permissionState = .denied
        }
    }

    /// Re-checks the OS-level authorization status, e.g. after the user returns from
    /// System Settings > Privacy & Security > Calendars.
    func refreshPermissionState() {
        let previous = permissionState
        permissionState = Self.currentPermissionState()
        if previous != .authorized && permissionState == .authorized {
            refresh()
        }
    }

    /// Re-fetches upcoming events from EventKit and publishes the result.
    /// Cheap enough to call on every store-changed notification and on wake/timer ticks.
    func refresh() {
        // Mock mode bypasses EventKit entirely — including the permission check —
        // so the menu bar, scheduler, and airplane can be exercised without ever
        // touching (or requiring access to) the real calendar.
        guard !ReminderSettings.shared.mockModeEnabled else {
            upcomingMeetings = Meeting.mockUpcoming()
            meetingsDidChange.send()
            return
        }

        guard permissionState == .authorized || permissionState == .limited else {
            upcomingMeetings = []
            return
        }

        let now = Date()
        let end = now.addingTimeInterval(lookaheadInterval)
        let calendars = eventStore.calendars(for: .event)
        let predicate = eventStore.predicateForEvents(withStart: now.addingTimeInterval(-60), end: end, calendars: calendars)

        // EKEventStore expands recurring events into individual EKEvent occurrences here,
        // so we don't need any recurrence-rule math of our own.
        let events = eventStore.events(matching: predicate)

        var seen = Set<String>()
        var meetings: [Meeting] = []
        for event in events {
            // Skip cancelled occurrences and all-day/no-specific-start-time events.
            if event.status == .canceled { continue }
            if event.isAllDay { continue }
            guard let meeting = Meeting(event: event) else { continue }
            guard meeting.startDate > now.addingTimeInterval(-30) else { continue }
            guard !seen.contains(meeting.id) else { continue }
            seen.insert(meeting.id)
            meetings.append(meeting)
        }

        upcomingMeetings = meetings.sorted { $0.startDate < $1.startDate }
        meetingsDidChange.send()
    }
}
