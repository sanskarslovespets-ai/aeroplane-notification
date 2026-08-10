// swift-tools-version: 5.9
import Foundation
import PackageDescription

// This manifest exists so MeetingFly can be built and run with just the Xcode
// Command Line Tools (`swift build` / `swift run`) — no full Xcode.app required.
// It points at the exact same `MeetingFly/` source tree the XcodeGen-generated
// `MeetingFly.xcodeproj` uses, so there's one codebase for both paths.
//
// Because a plain SPM executable isn't a real `.app` bundle, an Info.plist is
// embedded directly into the Mach-O binary via a linker `-sectcreate` into the
// `__TEXT,__info_plist` section. macOS reads that section exactly like a real
// bundle's Info.plist, which is what makes `NSCalendarsUsageDescription` (and
// therefore the Calendar permission prompt) work, and is why `LSUIElement`
// correctly hides this from the Dock even when run this way.
//
// This deliberately uses `Info-SPM.plist` (repo root) rather than the real
// `MeetingFly/Resources/Info.plist`: the latter contains Xcode build-setting
// placeholders like `$(PRODUCT_BUNDLE_IDENTIFIER)` that only Xcode's build
// system substitutes — embedded raw via sectcreate they'd end up as literal,
// broken strings at runtime. Info-SPM.plist carries the same keys with
// concrete values, and a distinct bundle identifier, so this CLT/SPM dev build
// never shares a TCC/login-item identity with the real Xcode-built app.
let manifestDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let infoPlistPath = manifestDirectory.appendingPathComponent("Info-SPM.plist").path

let package = Package(
    name: "MeetingFly",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "MeetingFly",
            path: "MeetingFly",
            exclude: [
                "Resources/Assets.xcassets",
                "Resources/MeetingFly.entitlements",
                "Resources/Info.plist",
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", infoPlistPath,
                ])
            ]
        )
    ]
)
