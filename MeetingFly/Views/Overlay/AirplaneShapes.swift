import SwiftUI

/// A small single-prop plane, side profile, nose pointing right — drawn as one
/// filled silhouette (fuselage + tail fin + tailplane + wing) rather than using
/// the generic SF Symbol, so the reminder has a shape of its own.
struct PlaneSilhouetteShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let bodyTop = h * 0.36
        let bodyBottom = h * 0.64
        let noseX = w * 0.98
        let tailX = w * 0.08

        var path = Path()

        // Fuselage: tapers to a rounded nose on the right, a rounded tail on the left.
        path.move(to: CGPoint(x: tailX, y: h * 0.5))
        path.addQuadCurve(to: CGPoint(x: w * 0.30, y: bodyTop), control: CGPoint(x: tailX, y: bodyTop))
        path.addLine(to: CGPoint(x: w * 0.78, y: bodyTop))
        path.addQuadCurve(to: CGPoint(x: noseX, y: h * 0.5), control: CGPoint(x: w * 0.95, y: bodyTop))
        path.addQuadCurve(to: CGPoint(x: w * 0.78, y: bodyBottom), control: CGPoint(x: w * 0.95, y: bodyBottom))
        path.addLine(to: CGPoint(x: w * 0.30, y: bodyBottom))
        path.addQuadCurve(to: CGPoint(x: tailX, y: h * 0.5), control: CGPoint(x: tailX, y: bodyBottom))
        path.closeSubpath()

        // Tail fin, pointing up.
        path.move(to: CGPoint(x: w * 0.12, y: bodyTop + h * 0.02))
        path.addLine(to: CGPoint(x: w * 0.20, y: 0))
        path.addLine(to: CGPoint(x: w * 0.31, y: bodyTop + h * 0.02))
        path.closeSubpath()

        // Tailplane, pointing down.
        path.move(to: CGPoint(x: w * 0.10, y: bodyBottom - h * 0.02))
        path.addLine(to: CGPoint(x: w * 0.08, y: h))
        path.addLine(to: CGPoint(x: w * 0.27, y: bodyBottom - h * 0.02))
        path.closeSubpath()

        // Wing, crossing the fuselage.
        let wingCenterX = w * 0.50
        let wingHalfWidth = w * 0.075
        path.addEllipse(in: CGRect(x: wingCenterX - wingHalfWidth, y: h * 0.03, width: wingHalfWidth * 2, height: h * 0.94))

        return path
    }
}

/// A friendly little plane: the silhouette above, filled with a soft gradient
/// and a subtle cockpit highlight, plus a continuously spinning propeller at
/// the nose for a touch of life even while the flight path itself is steady.
struct AirplaneGlyph: View {
    let pointSize: CGFloat
    let wobble: Double

    @State private var propellerSpin: Double = 0

    private var size: CGSize { CGSize(width: pointSize * 1.55, height: pointSize * 0.92) }

    var body: some View {
        ZStack {
            PlaneSilhouetteShape()
                .fill(
                    LinearGradient(
                        colors: [Color.accentColor, Color.accentColor.opacity(0.78)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    PlaneSilhouetteShape()
                        .stroke(Color.black.opacity(0.12), lineWidth: 0.75)
                )

            // Cockpit highlight — a small bright bump, purely decorative.
            Ellipse()
                .fill(Color.white.opacity(0.55))
                .frame(width: size.width * 0.12, height: size.height * 0.16)
                .offset(x: size.width * 0.14, y: -size.height * 0.06)

            propeller
                .offset(x: size.width * 0.49)
        }
        .frame(width: size.width, height: size.height)
        .shadow(color: .black.opacity(0.22), radius: 5, x: 0, y: 3)
        .rotationEffect(.degrees(wobble))
        .onAppear {
            withAnimation(.linear(duration: 0.35).repeatForever(autoreverses: false)) {
                propellerSpin = 360
            }
        }
    }

    private var propeller: some View {
        ZStack {
            Circle()
                .fill(Color.secondary.opacity(0.22))
                .frame(width: size.height * 0.5, height: size.height * 0.5)

            ForEach([0.0, 90.0], id: \.self) { baseAngle in
                Capsule()
                    .fill(Color.secondary.opacity(0.85))
                    .frame(width: size.height * 0.06, height: size.height * 0.46)
                    .rotationEffect(.degrees(baseAngle + propellerSpin))
            }

            Circle()
                .fill(Color.secondary)
                .frame(width: size.height * 0.12, height: size.height * 0.12)
        }
    }
}

/// The banner's attachment edge (right, facing the plane) is rounded; the
/// trailing edge (left) is cut into a shallow swallowtail, echoing a classic
/// tow-banner without literally illustrating one.
struct BannerPennantShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let r = min(14, h / 2)
        let notch = min(w * 0.14, 30)
        let notchDepth = h * 0.22

        var path = Path()
        path.move(to: CGPoint(x: notch, y: 0))
        path.addLine(to: CGPoint(x: w - r, y: 0))
        path.addArc(center: CGPoint(x: w - r, y: r), radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: w, y: h - r))
        path.addArc(center: CGPoint(x: w - r, y: h - r), radius: r, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        path.addLine(to: CGPoint(x: notch, y: h))
        path.addLine(to: CGPoint(x: notch * 0.35, y: h - notchDepth))
        path.addLine(to: CGPoint(x: notch, y: h / 2))
        path.addLine(to: CGPoint(x: notch * 0.35, y: notchDepth))
        path.closeSubpath()
        return path
    }
}

/// A thin, gently sagging tow line between the banner and the plane.
struct TowLineShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let sag = rect.height * 0.6
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control: CGPoint(x: rect.midX, y: rect.midY + sag)
        )
        return path
    }
}
