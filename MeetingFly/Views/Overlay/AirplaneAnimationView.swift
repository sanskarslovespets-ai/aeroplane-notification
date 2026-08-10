import SwiftUI

/// The full reminder: a small plane in the lead, towing the meeting details
/// behind it on a banner — its own take on a tow-banner, not a literal copy of
/// any reference art. The overall left-to-right flight across the screen is
/// driven externally by `OverlaySession` moving the containing window; this
/// view only animates in place (propeller spin, banner flutter, gentle pitch,
/// fade-in).
struct AirplaneAnimationView: View {
    let meeting: Meeting
    let mascot: ReminderMascot
    let airplaneSize: AirplaneSize
    let showJoinButton: Bool
    let onJoinTapped: () -> Void

    @State private var planeWobble: Double = -2
    @State private var bannerFlutter: Double = -1.5
    @State private var appeared = false

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            MeetingBannerCardView(meeting: meeting, showJoinButton: showJoinButton, onJoinTapped: onJoinTapped)
                .rotationEffect(.degrees(bannerFlutter), anchor: .trailing)

            TowLineShape()
                .stroke(Color.secondary.opacity(0.5), style: StrokeStyle(lineWidth: 1.25, lineCap: .round))
                .frame(width: 30, height: 14)

            MascotGlyph(mascot: mascot, pointSize: airplaneSize.pointSize, wobble: planeWobble)
        }
        .fixedSize()
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.96)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .onAppear {
            withAnimation(.easeOut(duration: 0.35)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                planeWobble = 3
            }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                bannerFlutter = 1.5
            }
        }
    }
}
