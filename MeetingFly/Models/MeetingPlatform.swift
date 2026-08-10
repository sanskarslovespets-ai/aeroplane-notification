import SwiftUI

/// A video-conferencing platform detected from an event's location, notes, or URL.
enum MeetingPlatform: String, Codable, CaseIterable, Identifiable {
    case googleMeet
    case zoom
    case microsoftTeams
    case webex
    case facetime
    case other
    case none

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .googleMeet: return "Google Meet"
        case .zoom: return "Zoom"
        case .microsoftTeams: return "Microsoft Teams"
        case .webex: return "Webex"
        case .facetime: return "FaceTime"
        case .other: return "Video Call"
        case .none: return "In Person / No Link"
        }
    }

    var symbolName: String {
        switch self {
        case .googleMeet: return "video.fill"
        case .zoom: return "video.circle.fill"
        case .microsoftTeams: return "person.2.fill"
        case .webex: return "video.badge.waveform"
        case .facetime: return "video.fill"
        case .other: return "link.circle.fill"
        case .none: return "calendar"
        }
    }

    var tintColor: Color {
        switch self {
        case .googleMeet: return Color(red: 0.0, green: 0.66, blue: 0.42)
        case .zoom: return Color(red: 0.16, green: 0.47, blue: 0.98)
        case .microsoftTeams: return Color(red: 0.31, green: 0.29, blue: 0.87)
        case .webex: return Color(red: 0.0, green: 0.72, blue: 0.65)
        case .facetime: return Color(red: 0.19, green: 0.82, blue: 0.35)
        case .other: return .secondary
        case .none: return .secondary
        }
    }
}
