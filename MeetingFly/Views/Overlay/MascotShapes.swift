import SwiftUI

/// A simple rocket silhouette, nose pointing right, matching the plane's
/// side-profile convention: rounded nose cone, cylindrical body, two rear fins.
struct RocketSilhouetteShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let bodyTop = h * 0.30
        let bodyBottom = h * 0.70
        let noseX = w * 0.97
        let tailX = w * 0.22

        var path = Path()
        path.move(to: CGPoint(x: tailX, y: bodyTop))
        path.addLine(to: CGPoint(x: w * 0.65, y: bodyTop))
        path.addQuadCurve(to: CGPoint(x: noseX, y: h * 0.5), control: CGPoint(x: w * 0.92, y: bodyTop))
        path.addQuadCurve(to: CGPoint(x: w * 0.65, y: bodyBottom), control: CGPoint(x: w * 0.92, y: bodyBottom))
        path.addLine(to: CGPoint(x: tailX, y: bodyBottom))
        path.closeSubpath()

        // Rear fins.
        path.move(to: CGPoint(x: tailX + w * 0.05, y: bodyTop + h * 0.02))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: tailX + w * 0.16, y: bodyTop + h * 0.06))
        path.closeSubpath()

        path.move(to: CGPoint(x: tailX + w * 0.05, y: bodyBottom - h * 0.02))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.addLine(to: CGPoint(x: tailX + w * 0.16, y: bodyBottom - h * 0.06))
        path.closeSubpath()

        return path
    }
}

/// A flying-saucer silhouette: a flattened saucer rim with a dome on top.
struct SaucerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let rimRect = CGRect(x: 0, y: rect.height * 0.45, width: rect.width, height: rect.height * 0.32)
        path.addEllipse(in: rimRect)
        let domeRect = CGRect(x: rect.width * 0.28, y: 0, width: rect.width * 0.44, height: rect.height * 0.58)
        path.addEllipse(in: domeRect)
        return path
    }
}

/// A single insect wing: a rounded teardrop, used twice (mirrored) for bees
/// and four times (two sizes) for butterflies.
struct WingShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.15), control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: rect.midX + rect.width * 0.1, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.15), control: CGPoint(x: rect.midX - rect.width * 0.1, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Three short, fading capsules trailing behind any glyph to read as "moving
/// fast," used uniformly across mascots so each one's silhouette can stay
/// simple without needing its own bespoke motion cue.
struct SpeedLines: View {
    let height: CGFloat

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(Color.secondary.opacity(0.22 - Double(index) * 0.06))
                    .frame(width: height * 0.34, height: 2.5)
            }
        }
    }
}
