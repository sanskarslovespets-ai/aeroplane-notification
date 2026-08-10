# MeetingFly

A native macOS menu-bar utility that flies a small character across your screen a
few minutes before every calendar meeting, with the meeting details attached.
Ten selectable characters (airplane, rocket, dog, cat, and more) — see Settings
→ Animation.

## Download

Grab the latest `MeetingFly-x.y.z.dmg` from the
[Releases page](https://github.com/sanskarslovespets-ai/aeroplane-notification/releases/latest),
open it, and drag **MeetingFly.app** into **Applications**.

**This build isn't notarized** (that requires a paid Apple Developer ID
account) — macOS Gatekeeper will block the first launch with "Apple could not
verify this app is free of malware." To open it anyway:

1. Try double-clicking it once (it'll be blocked — that's expected).
2. Open **System Settings → Privacy & Security**, scroll down, and you'll see
   *"MeetingFly.app was blocked"* with an **Open Anyway** button. Click it.
3. Confirm **Open** in the dialog that follows.

You only need to do this once. If you'd rather build from source (no
Gatekeeper prompt at all, since locally-built apps aren't quarantined), see
"Building without Xcode" below — it needs nothing but the free Xcode Command
Line Tools.

## Requirements

- macOS 14.0 (Sonoma) or later to run
- Xcode 15 or later to build (Xcode 16+ recommended if you're on macOS 15/26 SDKs)
- No third-party dependencies — everything is built on EventKit, SwiftUI, AppKit,
  UserNotifications, and ServiceManagement

## Opening the project

This project was scaffolded with [XcodeGen](https://github.com/yonaskolb/XcodeGen)
from `project.yml`, which is the source of truth for build settings, entitlements,
and Info.plist contents. The generated `MeetingFly.xcodeproj` is already checked
in and ready to open — you do **not** need XcodeGen installed just to build and run:

```bash
open MeetingFly.xcodeproj
```

If you ever edit `project.yml` (e.g. to add a file group or change a setting),
regenerate the project with:

```bash
brew install xcodegen   # if you don't have it
xcodegen generate
```

### First build

1. Open `MeetingFly.xcodeproj` in Xcode.
2. Select the **MeetingFly** scheme and your Mac as the run destination.
3. In the target's **Signing & Capabilities** tab, choose your own Team (Automatic
   signing is already configured in `project.yml`) — Calendar access and App
   Sandbox entitlements require a real signing identity, even for local runs.
4. Build & run (⌘R).

MeetingFly has no onboarding window — on first launch it just sits in the menu
bar. Click the airplane icon and it offers **"Grant Calendar Access…"** directly
whenever permission hasn't been decided yet; clicking it triggers the standard
macOS permission prompt. If you deny it (or want to change your mind later),
the menu also offers **"Open Privacy Settings…"**, or use **Settings →
Permissions**.

### Trying it immediately

You don't need a real meeting to see the airplane: open **Settings → Animation**
and click **Test Airplane Reminder**. There's also a **"Use mock meeting data for
testing"** toggle in the same tab for exercising the menu bar / next-meeting UI
without a live calendar event.

### Building without Xcode (Command Line Tools only)

If Xcode isn't available, `Package.swift` (repo root) builds and runs the exact
same source tree with just the Xcode Command Line Tools:

```bash
swift build -c release
./scripts/package_app.sh          # assembles a real MeetingFly.app from the release build
cp -R MeetingFly.app /Applications/
```

This path exists because it's how this project was actually built, run, and
debugged in an environment without Xcode installed — see "How this was actually
verified" below. It uses a separate bundle identifier
(`com.meetingfly.app.spm-dev`, set in `Info-SPM.plist`) so it never shares a
Calendar-permission or login-item identity with a real Xcode-built install.

## Project structure

```
MeetingFly/
  App/
    MeetingFlyApp.swift        SwiftUI @main entry point. Deliberately has almost no
                                real UI in it — see "Why AppKit, not MenuBarExtra" below.
    AppDelegate.swift          Owns MeetingManager/ReminderScheduler/StatusItemController
  Models/
    Meeting.swift               Value-type snapshot of an EKEvent occurrence
    MeetingPlatform.swift       Zoom/Meet/Teams/Webex/FaceTime enum + styling
    ReminderSettings.swift      Central @AppStorage-backed settings store
  Managers/
    MeetingManager.swift        EventKit access, permission handling, event fetch/refresh
    ReminderScheduler.swift     Reliable "fire N minutes before" scheduling
    StatusItemController.swift  Menu bar icon, its menu, AND the Settings window —
                                 all plain AppKit; see below for why
    LaunchAtLoginManager.swift  SMAppService wrapper
    NotificationManager.swift   Optional sound + local notification
  Views/
    Overlay/                   The airplane panel, its animation, and the info card
    Settings/                  Settings window tabs (General/Reminders/Meeting Types/
                                Animation/Permissions) — plain SwiftUI views, just not
                                hosted in a SwiftUI Settings scene (see below)
  Utilities/
    MeetingLinkDetector.swift  Parses event location/notes/URL for a conferencing link
    DateFormatting.swift       "Starts in 5 minutes" / time-range formatting
  Resources/
    Info.plist, MeetingFly.entitlements, Assets.xcassets
```

## Architecture notes

**Frameworks used, and why:**

- **EventKit** — the only calendar API used; no third-party calendar service is
  required. `EKEventStore.events(matching:)` already expands recurring events into
  concrete occurrences, so MeetingFly doesn't implement any recurrence-rule math
  itself. `EKEventStoreChangedNotification` drives re-fetching on edits/new events
  without polling.
- **AppKit**, for every actual window in the app, including the ones you might
  expect to be plain SwiftUI — see the dedicated section below.
- **ServiceManagement (`SMAppService`)** — modern launch-at-login registration,
  no legacy helper-app bundle.
- **UserNotifications** — optional system notification alongside the airplane.
- **Combine** — used narrowly, to fan out EventKit/settings/system change events
  (`meetingsDidChange`, wake-from-sleep, clock/timezone-change notifications) into
  a single "rebuild the schedule" trigger in `ReminderScheduler`.

### Why AppKit, not `MenuBarExtra` / `Settings` — read this before changing the menu bar or Settings code

This wasn't a style choice. The first version of this app used SwiftUI's
`MenuBarExtra` scene for the menu bar icon and a SwiftUI `Settings` scene for
preferences — the "obviously correct," modern approach. On the macOS version
this was built and tested against (26.6), that combination was **genuinely
broken**: opening *any* second window-producing SwiftUI scene while
`MenuBarExtra` was active — a hand-built `NSWindow`, or even the standard
`Settings` scene opened the officially-supported way — intermittently sent
SwiftUI into a self-sustaining status-item update loop that pegged a full CPU
core indefinitely, until macOS's own unresponsive-app watchdog killed the
process. This was confirmed, not guessed at: real synthesized clicks (via
`cliclick`) against the actually-running, actually-installed app, sampled with
`sample`/`ps`, repeated across batches of trials with a roughly 60% failure
rate on the `MenuBarExtra`-based version.

The fix was to stop using `MenuBarExtra` and the `Settings` scene entirely:

- **`StatusItemController`** owns a plain `NSStatusItem` with an `NSMenu`,
  rebuilt fresh from current app state every time `NSMenuDelegate.menuWillOpen`
  fires. This is the original, decade-plus-battle-tested way menu bar apps have
  always worked, predating `MenuBarExtra`.
- **Settings** is a hand-built `NSWindow` + `NSHostingController` wrapping the
  same `SettingsView()` SwiftUI content, opened imperatively from
  `StatusItemController.openSettingsWindow()` — not a SwiftUI `Settings` scene.
  (Two different ways of triggering a real `Settings` scene from code were
  tried and both failed here too: the private
  `NSApp.sendAction(Selector(("showSettingsWindow:")), ...)` trick silently
  opened nothing — confirmed via `CGWindowListCopyWindowInfo`, not just a
  CPU-usage guess — and a correctly-declared `@Environment(\.openSettings)`
  action *did* open the window, but only while `MenuBarExtra` was also still
  in the picture, and inherited the same CPU-loop problem.)
- `MeetingFlyApp.swift`'s `body` is now `Settings { EmptyView() }` purely
  because SwiftUI's `App` protocol requires at least one `Scene` — it is
  intentionally never opened.

Re-verified clean across 16 consecutive trials (real clicks, both the menu
bar icon and "Settings…") after this change, including the actual installed
`/Applications/MeetingFly.app`, with **zero** CPU-loop reproductions.

**If you're tempted to switch back to `MenuBarExtra`/`Settings` for the nicer
API** (e.g. because a future macOS/Xcode fixes the underlying bug): test it
the same way — real clicks via `cliclick`, a batch of at least 5-10 trials,
watching `ps`/`sample` for a pegged core, not just "it compiled and looked
fine once."

**AppKit specifics for the overlay:**

- `AirplaneOverlayWindow` is an `NSPanel` with `.nonactivatingPanel` in its style
  mask — this is the mechanism that lets its "Join Meeting" button be clickable
  *without* the panel ever becoming key or activating the app (`canBecomeKey`/
  `canBecomeMain` are also hard-overridden to `false` as a second guard). That's
  what satisfies "must never steal focus."
- The overlay window is sized tightly around the airplane + card (not full-screen),
  and animated by moving the actual window frame across the screen with a 60fps
  `Timer`. Because the window itself is small, there's no invisible full-screen
  layer intercepting clicks on your desktop — only the visible pixels are ever
  hit-testable.
- One `AirplaneOverlayWindow` is created per target `NSScreen` for multi-monitor
  support.

**Scheduling reliability** (`ReminderScheduler.swift`): rather than a repeating
"check every few seconds" timer, the scheduler arms exactly one `DispatchSourceTimer`
for the *next* reminder's fire date. The whole schedule is rebuilt from scratch
(cheap, since EventKit already gives us the expanded event list) whenever:
calendar data changes, a relevant setting changes, the Mac wakes from sleep
(`NSWorkspace.didWakeNotification`), the system clock changes (`NSSystemClockDidChange`),
the timezone changes (`NSSystemTimeZoneDidChange`), or the app launches. Already-fired
reminders are tracked by a stable `eventIdentifier + occurrence start date` key,
persisted in `UserDefaults` and pruned against the live event list, so relaunches
and back-to-back rebuilds never double-fire a reminder. If the scheduler discovers
it's already past a fire date when it wakes up (e.g. the Mac was asleep through it)
and the meeting hasn't ended yet, it fires immediately instead of silently skipping it.

**A real macOS limitation worth knowing about:** apps in native fullscreen own a
separate Space. MeetingFly's overlay panel sets
`collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]`
and `level = .screenSaver` so it *can* draw over another app's fullscreen Space as
an auxiliary overlay — but macOS reserves this behavior at the system's discretion.
Some fullscreen contexts (Keynote presenter mode, some games/video players in a
"do not disturb while presenting" state) can suppress all overlays outright, and
there's no public API to force through that. This is a platform constraint, not a
bug in the app.

**Reminder characters** (`ReminderMascot`, `MascotGlyph.swift`, `MascotShapes.swift`):
ten selectable lead characters — airplane, paper airplane, rocket, hot air
balloon, UFO, dog, cat, bird, bee, butterfly — all sharing the same
tow-banner mechanic in `AirplaneAnimationView.swift`; only the glyph and its
idle motion (wobble, wing flap, flame flicker, etc.) differ per character.
Airplane/rocket/balloon/UFO/bee/butterfly are hand-drawn `Shape`s; dog/cat/bird
are SF Symbols (`dog.fill`/`cat.fill`/`bird.fill`) dressed up with the same
trailing speed-lines and shadow treatment so they read at a consistent visual
weight next to the custom-drawn ones. The Settings picker (`AnimationSettingsView.swift`)
shows a static emoji grid rather than ten live animations at once — selecting
a character fires a real test reminder so you see the actual animated glyph
immediately, without the settings window itself needing to run ten
simultaneous animations.

## Settings reference

| Tab | Contains |
|---|---|
| General | Launch at login, show/hide menu bar icon, sound, system notification, Join button, pause all reminders |
| Reminders | Lead time (1/5/10/15/custom minutes) |
| Meeting Types | All events / attendees-only / video-link-only filter |
| Animation | Enable/disable, duration, character size, character picker (10 options — see below), target screen(s), mock mode, Test Reminder Animation |
| Permissions | Live Calendar authorization status, request/re-check, deep link to System Settings |

## How this was actually verified

No Xcode.app was available in the environment this was built in — only the
Command Line Tools. Rather than stop at "it compiles," the app was actually
built, ad-hoc code-signed, packaged into a real `.app`, installed to
`/Applications`, and driven with real synthesized mouse clicks (`cliclick`,
which — unlike AppleScript/System Events — doesn't require Accessibility
permission) while watching `ps`/`sample`/`CGWindowListCopyWindowInfo` for
actual behavior, not just process-alive/CPU-idle as a proxy. That process is
what found and fixed the `MenuBarExtra` CPU-loop bug documented above — it
would **not** have been caught by a typecheck or a single manual run, since
it was intermittent (roughly 40% of runs looked fine).

What's still unverified: full native-fullscreen overlay behavior, and
multi-monitor behavior on an actual multi-display setup (the test machine
this was verified on is single-display).

## Known limitations / follow-ups

- App icon and Dock/menu-bar artwork ship as placeholders (`Assets.xcassets` has
  the correct slots wired up in `Info.plist` — drop real image assets into
  `AppIcon.appiconset` when you have them).
