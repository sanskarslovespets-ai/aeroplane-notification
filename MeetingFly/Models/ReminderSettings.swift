import Foundation
import SwiftUI

/// How far before a meeting the airplane reminder fires.
enum ReminderLeadTime: Int, CaseIterable, Identifiable, Codable {
    case oneMinute = 1
    case fiveMinutes = 5
    case tenMinutes = 10
    case fifteenMinutes = 15
    case custom = -1

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .oneMinute: return "1 minute before"
        case .fiveMinutes: return "5 minutes before"
        case .tenMinutes: return "10 minutes before"
        case .fifteenMinutes: return "15 minutes before"
        case .custom: return "Custom"
        }
    }
}

/// Which screen(s) the airplane overlay should appear on.
enum OverlayScreenTarget: String, CaseIterable, Identifiable, Codable {
    case mainDisplay
    case currentDisplay
    case allDisplays

    var id: String { rawValue }

    var label: String {
        switch self {
        case .mainDisplay: return "Main Display"
        case .currentDisplay: return "Display with Mouse Cursor"
        case .allDisplays: return "All Displays"
        }
    }
}

/// Which calendar events should trigger a reminder at all.
enum MeetingFilter: String, CaseIterable, Identifiable, Codable {
    case all
    case withAttendeesOnly
    case withVideoLinkOnly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return "All Events"
        case .withAttendeesOnly: return "Only Meetings with Attendees"
        case .withVideoLinkOnly: return "Only Meetings with a Video Link"
        }
    }
}

/// Airplane visual size.
enum AirplaneSize: String, CaseIterable, Identifiable, Codable {
    case small, medium, large

    var id: String { rawValue }

    var label: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }

    var pointSize: CGFloat {
        switch self {
        case .small: return 28
        case .medium: return 40
        case .large: return 56
        }
    }
}

/// Which character flies the reminder across the screen, towing the meeting
/// banner behind it. All ten share the same tow-banner mechanic (see
/// `MascotGlyph.swift`); only the lead character and its idle motion differ.
enum ReminderMascot: String, CaseIterable, Identifiable, Codable {
    case airplane
    case paperPlane
    case rocket
    case hotAirBalloon
    case ufo
    case dog
    case cat
    case bird
    case bee
    case butterfly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .airplane: return "Airplane"
        case .paperPlane: return "Paper Airplane"
        case .rocket: return "Rocket"
        case .hotAirBalloon: return "Hot Air Balloon"
        case .ufo: return "UFO"
        case .dog: return "Dog"
        case .cat: return "Cat"
        case .bird: return "Bird"
        case .bee: return "Bee"
        case .butterfly: return "Butterfly"
        }
    }

    /// Used only as a quick, cheap preview glyph in the settings picker grid —
    /// the real in-flight glyph is the hand-drawn/SF Symbol view in `MascotGlyph.swift`.
    var previewEmoji: String {
        switch self {
        case .airplane: return "✈️"
        case .paperPlane: return "🛩️"
        case .rocket: return "🚀"
        case .hotAirBalloon: return "🎈"
        case .ufo: return "🛸"
        case .dog: return "🐶"
        case .cat: return "🐱"
        case .bird: return "🐦"
        case .bee: return "🐝"
        case .butterfly: return "🦋"
        }
    }
}

/// Central, `@AppStorage`-backed settings store. Every property mirrors one `UserDefaults`
/// key so it can be read from anywhere (menu bar, settings UI, scheduler) without plumbing.
final class ReminderSettings: ObservableObject {
    static let shared = ReminderSettings()

    private enum Keys {
        static let leadTimeMinutes = "leadTimeMinutes"
        static let customLeadTimeMinutes = "customLeadTimeMinutes"
        static let animationEnabled = "animationEnabled"
        static let animationDuration = "animationDuration"
        static let airplaneSize = "airplaneSize"
        static let mascot = "mascot"
        static let screenTarget = "screenTarget"
        static let meetingFilter = "meetingFilter"
        static let launchAtLogin = "launchAtLogin"
        static let showMenuBarIcon = "showMenuBarIcon"
        static let soundEnabled = "soundEnabled"
        static let notificationEnabled = "notificationEnabled"
        static let joinButtonEnabled = "joinButtonEnabled"
        static let remindersPaused = "remindersPaused"
        static let mockModeEnabled = "mockModeEnabled"
    }

    @AppStorage(Keys.leadTimeMinutes) var leadTimeRaw: Int = ReminderLeadTime.fiveMinutes.rawValue
    @AppStorage(Keys.customLeadTimeMinutes) var customLeadTimeMinutes: Int = 5
    @AppStorage(Keys.animationEnabled) var animationEnabled: Bool = true
    @AppStorage(Keys.animationDuration) var animationDuration: Double = 11.5
    @AppStorage(Keys.airplaneSize) var airplaneSizeRaw: String = AirplaneSize.medium.rawValue
    @AppStorage(Keys.mascot) var mascotRaw: String = ReminderMascot.airplane.rawValue
    @AppStorage(Keys.screenTarget) var screenTargetRaw: String = OverlayScreenTarget.currentDisplay.rawValue
    @AppStorage(Keys.meetingFilter) var meetingFilterRaw: String = MeetingFilter.all.rawValue
    @AppStorage(Keys.launchAtLogin) var launchAtLogin: Bool = false
    @AppStorage(Keys.showMenuBarIcon) var showMenuBarIcon: Bool = true
    @AppStorage(Keys.soundEnabled) var soundEnabled: Bool = true
    @AppStorage(Keys.notificationEnabled) var notificationEnabled: Bool = false
    @AppStorage(Keys.joinButtonEnabled) var joinButtonEnabled: Bool = true
    @AppStorage(Keys.remindersPaused) var remindersPaused: Bool = false
    @AppStorage(Keys.mockModeEnabled) var mockModeEnabled: Bool = false

    var leadTime: ReminderLeadTime {
        get { ReminderLeadTime(rawValue: leadTimeRaw) ?? .fiveMinutes }
        set { leadTimeRaw = newValue.rawValue }
    }

    /// Effective minutes-before-meeting used by the scheduler.
    var effectiveLeadMinutes: Int {
        leadTime == .custom ? max(1, customLeadTimeMinutes) : leadTime.rawValue
    }

    var airplaneSize: AirplaneSize {
        get { AirplaneSize(rawValue: airplaneSizeRaw) ?? .medium }
        set { airplaneSizeRaw = newValue.rawValue }
    }

    var mascot: ReminderMascot {
        get { ReminderMascot(rawValue: mascotRaw) ?? .airplane }
        set { mascotRaw = newValue.rawValue }
    }

    var screenTarget: OverlayScreenTarget {
        get { OverlayScreenTarget(rawValue: screenTargetRaw) ?? .currentDisplay }
        set { screenTargetRaw = newValue.rawValue }
    }

    var meetingFilter: MeetingFilter {
        get { MeetingFilter(rawValue: meetingFilterRaw) ?? .all }
        set { meetingFilterRaw = newValue.rawValue }
    }

    private init() {}
}
