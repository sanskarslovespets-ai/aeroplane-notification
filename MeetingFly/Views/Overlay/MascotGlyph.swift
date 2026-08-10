import SwiftUI

/// Dispatches to the right lead-character glyph for the selected
/// `ReminderMascot`, all sized and animated consistently so swapping mascots
/// in Settings never changes the overall reminder's layout or pacing — only
/// the character towing the banner.
struct MascotGlyph: View {
    let mascot: ReminderMascot
    let pointSize: CGFloat
    let wobble: Double

    var body: some View {
        switch mascot {
        case .airplane:
            AirplaneGlyph(pointSize: pointSize, wobble: wobble)
        case .paperPlane:
            SymbolMascotGlyph(systemName: "paperplane.fill", pointSize: pointSize, wobble: wobble, baseRotation: -40, tint: Color.accentColor)
        case .rocket:
            RocketGlyph(pointSize: pointSize, wobble: wobble)
        case .hotAirBalloon:
            BalloonGlyph(pointSize: pointSize, wobble: wobble)
        case .ufo:
            SaucerGlyph(pointSize: pointSize, wobble: wobble)
        case .dog:
            SymbolMascotGlyph(systemName: "dog.fill", pointSize: pointSize, wobble: wobble, baseRotation: 0, tint: .brown)
        case .cat:
            SymbolMascotGlyph(systemName: "cat.fill", pointSize: pointSize, wobble: wobble, baseRotation: 0, tint: .orange)
        case .bird:
            SymbolMascotGlyph(systemName: "bird.fill", pointSize: pointSize, wobble: wobble, baseRotation: 0, tint: .teal)
        case .bee:
            BeeGlyph(pointSize: pointSize, wobble: wobble)
        case .butterfly:
            ButterflyGlyph(pointSize: pointSize, wobble: wobble)
        }
    }
}

/// SF Symbol-backed mascots (dog/cat/bird/paper airplane): a consistent
/// circular badge behind the symbol keeps their visual weight in line with
/// the hand-drawn glyphs, plus the shared trailing speed lines.
private struct SymbolMascotGlyph: View {
    let systemName: String
    let pointSize: CGFloat
    let wobble: Double
    let baseRotation: Double
    let tint: Color

    var body: some View {
        ZStack(alignment: .trailing) {
            SpeedLines(height: pointSize)
                .offset(x: -pointSize * 0.62)

            Image(systemName: systemName)
                .resizable()
                .scaledToFit()
                .frame(width: pointSize * 0.78, height: pointSize * 0.78)
                .foregroundStyle(
                    LinearGradient(colors: [tint, tint.opacity(0.75)], startPoint: .top, endPoint: .bottom)
                )
                .rotationEffect(.degrees(baseRotation + wobble))
                .shadow(color: .black.opacity(0.22), radius: 5, x: 0, y: 3)
        }
        .frame(width: pointSize * 1.7, height: pointSize * 0.92, alignment: .trailing)
    }
}

private struct RocketGlyph: View {
    let pointSize: CGFloat
    let wobble: Double

    @State private var flameScale: CGFloat = 0.7

    private var size: CGSize { CGSize(width: pointSize * 1.55, height: pointSize * 0.8) }

    var body: some View {
        ZStack(alignment: .trailing) {
            SpeedLines(height: pointSize)
                .offset(x: -pointSize * 0.62)

            ZStack {
                // Flame, behind the body, flickering.
                Triangle()
                    .fill(
                        LinearGradient(colors: [.orange, .yellow.opacity(0.7)], startPoint: .trailing, endPoint: .leading)
                    )
                    .frame(width: size.width * 0.22, height: size.height * 0.34)
                    .scaleEffect(x: flameScale, y: 1, anchor: .trailing)
                    .offset(x: -size.width * 0.36)

                RocketSilhouetteShape()
                    .fill(LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.78)], startPoint: .top, endPoint: .bottom))
                    .overlay(RocketSilhouetteShape().stroke(Color.black.opacity(0.12), lineWidth: 0.75))
                    .frame(width: size.width, height: size.height)

                Circle()
                    .fill(Color.white.opacity(0.55))
                    .frame(width: size.height * 0.22, height: size.height * 0.22)
                    .offset(x: size.width * 0.12)
            }
            .rotationEffect(.degrees(wobble))
        }
        .frame(width: size.width + pointSize * 0.5, height: size.height, alignment: .trailing)
        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.18).repeatForever(autoreverses: true)) {
                flameScale = 1.25
            }
        }
    }
}

private struct BalloonGlyph: View {
    let pointSize: CGFloat
    let wobble: Double

    private var size: CGSize { CGSize(width: pointSize * 0.95, height: pointSize * 1.35) }

    var body: some View {
        VStack(spacing: 0) {
            Ellipse()
                .fill(LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.75)], startPoint: .top, endPoint: .bottom))
                .overlay(Ellipse().stroke(Color.black.opacity(0.1), lineWidth: 0.75))
                .frame(width: size.width, height: size.height * 0.68)

            Rectangle()
                .fill(Color.secondary.opacity(0.6))
                .frame(width: 1, height: size.height * 0.14)

            RoundedRectangle(cornerRadius: 3)
                .fill(Color(red: 0.55, green: 0.38, blue: 0.22))
                .frame(width: size.width * 0.42, height: size.height * 0.16)
        }
        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
        .rotationEffect(.degrees(wobble), anchor: .top)
        .frame(width: pointSize * 1.7, alignment: .center)
    }
}

private struct SaucerGlyph: View {
    let pointSize: CGFloat
    let wobble: Double

    @State private var lightsOn = false

    private var size: CGSize { CGSize(width: pointSize * 1.3, height: pointSize * 0.75) }

    var body: some View {
        ZStack(alignment: .trailing) {
            SpeedLines(height: pointSize)
                .offset(x: -pointSize * 0.58)

            ZStack {
                SaucerShape()
                    .fill(LinearGradient(colors: [Color.mint, Color.accentColor.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                    .overlay(SaucerShape().stroke(Color.black.opacity(0.12), lineWidth: 0.75))
                    .frame(width: size.width, height: size.height)

                HStack(spacing: size.width * 0.1) {
                    ForEach(0..<3, id: \.self) { _ in
                        Circle()
                            .fill(Color.yellow.opacity(lightsOn ? 1 : 0.35))
                            .frame(width: size.height * 0.12, height: size.height * 0.12)
                    }
                }
                .offset(y: size.height * 0.22)
            }
            .rotationEffect(.degrees(wobble * 0.4))
        }
        .frame(width: size.width + pointSize * 0.5, height: size.height, alignment: .trailing)
        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                lightsOn = true
            }
        }
    }
}

private struct BeeGlyph: View {
    let pointSize: CGFloat
    let wobble: Double

    @State private var wingFlap: CGFloat = 1.0

    private var size: CGSize { CGSize(width: pointSize * 0.85, height: pointSize * 0.55) }

    var body: some View {
        ZStack(alignment: .trailing) {
            SpeedLines(height: pointSize)
                .offset(x: -pointSize * 0.58)

            ZStack {
                HStack(spacing: -size.width * 0.1) {
                    WingShape()
                        .fill(Color.white.opacity(0.75))
                        .frame(width: size.width * 0.4, height: size.height * 0.85)
                        .scaleEffect(y: wingFlap, anchor: .bottom)
                    WingShape()
                        .fill(Color.white.opacity(0.75))
                        .frame(width: size.width * 0.4, height: size.height * 0.85)
                        .scaleEffect(x: -1, y: wingFlap, anchor: .bottom)
                }
                .offset(y: -size.height * 0.42)

                Capsule()
                    .fill(Color.black.opacity(0.85))
                    .frame(width: size.width, height: size.height)
                    .overlay(
                        HStack(spacing: size.width * 0.1) {
                            ForEach(0..<3, id: \.self) { _ in
                                Capsule().fill(Color.yellow).frame(width: size.width * 0.12)
                            }
                        }
                        .padding(.horizontal, size.width * 0.16)
                    )
                    .clipShape(Capsule())
            }
            .rotationEffect(.degrees(wobble))
        }
        .frame(width: size.width + pointSize * 0.55, height: pointSize * 0.9, alignment: .trailing)
        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.09).repeatForever(autoreverses: true)) {
                wingFlap = 0.55
            }
        }
    }
}

private struct ButterflyGlyph: View {
    let pointSize: CGFloat
    let wobble: Double

    @State private var wingFlap: CGFloat = 1.0

    private var size: CGSize { CGSize(width: pointSize * 1.1, height: pointSize * 0.95) }

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                VStack(spacing: -size.height * 0.05) {
                    WingShape().fill(Color.purple.opacity(0.85)).frame(width: size.width * 0.42, height: size.height * 0.52)
                    WingShape().fill(Color.purple.opacity(0.55)).frame(width: size.width * 0.30, height: size.height * 0.36)
                }
                .scaleEffect(x: wingFlap, anchor: .trailing)

                Capsule().fill(Color.black.opacity(0.75)).frame(width: 2.5, height: size.height * 0.8)

                VStack(spacing: -size.height * 0.05) {
                    WingShape().fill(Color.purple.opacity(0.85)).frame(width: size.width * 0.42, height: size.height * 0.52)
                        .scaleEffect(x: -1)
                    WingShape().fill(Color.purple.opacity(0.55)).frame(width: size.width * 0.30, height: size.height * 0.36)
                        .scaleEffect(x: -1)
                }
                .scaleEffect(x: wingFlap, anchor: .leading)
            }
        }
        .frame(width: pointSize * 1.7, height: size.height, alignment: .center)
        .shadow(color: .black.opacity(0.18), radius: 4, x: 0, y: 2)
        .rotationEffect(.degrees(wobble * 0.5))
        .onAppear {
            withAnimation(.easeInOut(duration: 0.22).repeatForever(autoreverses: true)) {
                wingFlap = 0.6
            }
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
