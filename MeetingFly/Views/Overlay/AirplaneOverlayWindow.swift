import AppKit

/// A borderless, non-activating panel used to display the flying airplane reminder.
///
/// Two properties are load-bearing for the "never steals focus" requirement:
/// - `.nonactivatingPanel` in the style mask means clicking a control inside this
///   panel (e.g. the Join Meeting button) does *not* activate MeetingFly or bring
///   the panel to key/main status — the click is delivered to the control in place.
/// - `canBecomeKey`/`canBecomeMain` are hard-overridden to `false` as a second layer
///   of protection, so even a programmatic `makeKey` call elsewhere in the app could
///   never turn this into a focus-stealing window.
final class AirplaneOverlayWindow: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovableByWindowBackground = false
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        worksWhenModal = true
        ignoresMouseEvents = false

        // .screenSaver keeps the reminder above nearly everything, including most
        // fullscreen app chrome; .canJoinAllSpaces + .fullScreenAuxiliary let it
        // follow the user into another app's fullscreen Space (see README for the
        // platform limits macOS still imposes here).
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
