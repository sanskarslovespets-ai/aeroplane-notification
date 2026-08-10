import Foundation

/// Detects a video-conferencing platform and join URL from a calendar event's
/// location, notes, and URL fields. EventKit doesn't give us a structured
/// "conferencing" field on macOS the way Google Calendar's API does, so we
/// pattern-match the freeform text the same way a human would scan it.
enum MeetingLinkDetector {
    private struct Rule {
        let platform: MeetingPlatform
        let hostFragments: [String]
    }

    private static let rules: [Rule] = [
        Rule(platform: .googleMeet, hostFragments: ["meet.google.com"]),
        Rule(platform: .zoom, hostFragments: ["zoom.us", "zoom.com"]),
        Rule(platform: .microsoftTeams, hostFragments: ["teams.microsoft.com", "teams.live.com"]),
        Rule(platform: .webex, hostFragments: ["webex.com"]),
        Rule(platform: .facetime, hostFragments: ["facetime.apple.com"]),
    ]

    /// All candidate URLs found across an event's URL, location, and notes fields.
    private static func candidateURLs(for meeting: Meeting) -> [URL] {
        var urls: [URL] = []
        if let url = meeting.url {
            urls.append(url)
        }
        for text in [meeting.location, meeting.notes].compactMap({ $0 }) {
            urls.append(contentsOf: extractURLs(from: text))
        }
        return urls
    }

    private static func extractURLs(from text: String) -> [URL] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return []
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return detector.matches(in: text, options: [], range: range).compactMap { $0.url }
    }

    static func detectPlatform(for meeting: Meeting) -> MeetingPlatform {
        let urls = candidateURLs(for: meeting)
        for url in urls {
            guard let host = url.host?.lowercased() else { continue }
            for rule in rules where rule.hostFragments.contains(where: { host.contains($0) }) {
                return rule.platform
            }
        }
        // Fall back to plain-text keyword scanning (some invites paste "Zoom Meeting"
        // without an actual clickable link in the fields EventKit exposes).
        let haystack = [meeting.notes, meeting.location].compactMap { $0 }.joined(separator: " ").lowercased()
        if haystack.contains("zoom") { return .zoom }
        if haystack.contains("google meet") || haystack.contains("meet.google") { return .googleMeet }
        if haystack.contains("teams.microsoft") || haystack.contains("microsoft teams") { return .microsoftTeams }
        if haystack.contains("webex") { return .webex }

        if !urls.isEmpty { return .other }
        return .none
    }

    static func detectJoinURL(for meeting: Meeting) -> URL? {
        let urls = candidateURLs(for: meeting)
        // Prefer a URL matching a known platform's host over an arbitrary link.
        for rule in rules {
            if let match = urls.first(where: { url in
                guard let host = url.host?.lowercased() else { return false }
                return rule.hostFragments.contains { host.contains($0) }
            }) {
                return match
            }
        }
        return urls.first
    }
}
