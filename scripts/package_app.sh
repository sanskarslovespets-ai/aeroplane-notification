#!/bin/bash
# Builds MeetingFly with Swift Package Manager (Command Line Tools only — no
# Xcode required) and assembles a real, double-clickable MeetingFly.app bundle
# at the repo root. Re-run this any time after pulling source changes to
# refresh the installed app; see README.md for the install step that follows.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> Building release binary"
swift build -c release

BIN_PATH="$(swift build -c release --show-bin-path)/MeetingFly"
APP_PATH="MeetingFly.app"

echo "==> Assembling $APP_PATH"
rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS"
cp "$BIN_PATH" "$APP_PATH/Contents/MacOS/MeetingFly"
cp "Info-Release.plist" "$APP_PATH/Contents/Info.plist"

echo "==> Ad-hoc code signing"
codesign --force --deep -s - "$APP_PATH"

echo "==> Done: $(pwd)/$APP_PATH"
codesign -dv "$APP_PATH" 2>&1 | grep Identifier
