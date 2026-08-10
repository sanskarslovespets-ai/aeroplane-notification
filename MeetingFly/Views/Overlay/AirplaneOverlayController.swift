import AppKit
import SwiftUI
import QuartzCore

/// Creates and drives one `OverlaySession` per target screen for a triggered meeting
/// reminder. Multiple sessions (from back-to-back meetings, or one meeting shown on
/// several displays) can be active at once; each is fully independent.
@MainActor
final class AirplaneOverlayController {
    static let shared = AirplaneOverlayController()

    private var activeSessions: [OverlaySession] = []

    private init() {}

    func show(meeting: Meeting, settings: ReminderSettings) {
        NotificationManager.playReminderSound(enabled: settings.soundEnabled)
        NotificationManager.postNotification(for: meeting, enabled: settings.notificationEnabled)

        guard settings.animationEnabled else { return }

        for screen in targetScreens(for: settings.screenTarget) {
            let session = OverlaySession(
                meeting: meeting,
                screen: screen,
                mascot: settings.mascot,
                airplaneSize: settings.airplaneSize,
                duration: settings.animationDuration,
                showJoinButton: settings.joinButtonEnabled
            )
            activeSessions.append(session)
            session.onFinished = { [weak self] in
                self?.activeSessions.removeAll { $0 === session }
            }
            session.start()
        }
    }

    private func targetScreens(for target: OverlayScreenTarget) -> [NSScreen] {
        switch target {
        case .mainDisplay:
            return NSScreen.main.map { [$0] } ?? []
        case .currentDisplay:
            let mouseLocation = NSEvent.mouseLocation
            let screen = NSScreen.screens.first { $0.frame.contains(mouseLocation) } ?? NSScreen.main
            return screen.map { [$0] } ?? []
        case .allDisplays:
            return NSScreen.screens
        }
    }
}

/// Owns a single airplane panel's lifecycle: positions it just off one edge of a
/// screen, animates it across using a lightweight 60fps display timer, and tears
/// itself down when the flight completes. The timer only exists while a reminder
/// is actively animating, so idle CPU/memory cost is effectively zero.
@MainActor
private final class OverlaySession {
    let meeting: Meeting
    private let screen: NSScreen
    private let mascot: ReminderMascot
    private let airplaneSize: AirplaneSize
    private let duration: Double
    private let showJoinButton: Bool

    private var panel: AirplaneOverlayWindow?
    private var timer: Timer?
    private var startTime: CFTimeInterval = 0
    private let contentSize = CGSize(width: 460, height: 150)

    var onFinished: (() -> Void)?

    init(meeting: Meeting, screen: NSScreen, mascot: ReminderMascot, airplaneSize: AirplaneSize, duration: Double, showJoinButton: Bool) {
        self.meeting = meeting
        self.screen = screen
        self.mascot = mascot
        self.airplaneSize = airplaneSize
        self.duration = max(3.0, duration)
        self.showJoinButton = showJoinButton
    }

    func start() {
        let frame = NSRect(origin: originForProgress(0), size: contentSize)
        let window = AirplaneOverlayWindow(contentRect: frame)

        let rootView = AirplaneAnimationView(
            meeting: meeting,
            mascot: mascot,
            airplaneSize: airplaneSize,
            showJoinButton: showJoinButton,
            onJoinTapped: { [weak self] in self?.openJoinLink() }
        )
        window.contentView = NSHostingView(rootView: rootView)
        window.alphaValue = 0
        window.orderFrontRegardless()
        panel = window

        startTime = CACurrentMediaTime()
        let displayTimer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(displayTimer, forMode: .common)
        timer = displayTimer
    }

    private func tick() {
        let elapsed = CACurrentMediaTime() - startTime
        let t = min(1.0, elapsed / duration)

        panel?.setFrameOrigin(originForProgress(t))
        panel?.alphaValue = alpha(for: t)

        if t >= 1.0 {
            finish()
        }
    }

    /// Horizontal position across the full screen width (with margin so the plane
    /// starts and ends fully off-screen): the plane accelerates off the entry
    /// edge, holds a steady cruise speed across the middle of the screen, then
    /// decelerates into the exit edge — rather than a single ease-in-out curve,
    /// whose fastest point sits right in the middle of the screen and reads as
    /// "too fast" even at a generous total duration. A small sine bob is layered
    /// on the vertical axis for a "flight" feel.
    private func originForProgress(_ t: Double) -> NSPoint {
        let startX = screen.frame.minX - contentSize.width - 60
        let endX = screen.frame.maxX + 60
        let eased = flightProgress(t)
        let x = startX + (endX - startX) * eased

        let elapsed = t * duration
        let bob = sin(elapsed * 2.2) * 5
        let baseY = screen.visibleFrame.maxY - contentSize.height - 40
        return NSPoint(x: x, y: baseY + bob)
    }

    private func alpha(for t: Double) -> CGFloat {
        let fadeInEnd = 0.08
        let fadeOutStart = 0.90
        if t < fadeInEnd {
            return CGFloat(t / fadeInEnd)
        } else if t > fadeOutStart {
            return CGFloat(max(0, 1 - (t - fadeOutStart) / (1 - fadeOutStart)))
        }
        return 1
    }

    /// Accelerate (0 → cruiseStart), cruise at constant speed (cruiseStart →
    /// cruiseEnd), decelerate (cruiseEnd → 1). Keeping the cruise segment at a
    /// constant rate — instead of easing all the way through — caps how fast the
    /// plane ever appears to move, no matter how it's tuned.
    private func flightProgress(_ t: Double) -> Double {
        let t = min(max(t, 0), 1)
        let cruiseStart = 0.22
        let cruiseEnd = 0.78
        let cruiseSpan = cruiseEnd - cruiseStart

        if t < cruiseStart {
            let local = t / cruiseStart
            return cruiseStart * local * local // ease-in: slow start, speeding up to cruise pace
        } else if t > cruiseEnd {
            let local = (t - cruiseEnd) / (1 - cruiseEnd)
            return cruiseEnd + (1 - cruiseEnd) * (1 - (1 - local) * (1 - local)) // ease-out: cruise pace slowing to a stop
        } else {
            let local = (t - cruiseStart) / cruiseSpan
            return cruiseStart + cruiseSpan * local // constant cruise speed
        }
    }

    private func finish() {
        timer?.invalidate()
        timer = nil
        panel?.orderOut(nil)
        panel?.close()
        panel = nil
        onFinished?()
    }

    private func openJoinLink() {
        guard let url = meeting.joinURL else { return }
        NSWorkspace.shared.open(url)
    }
}
