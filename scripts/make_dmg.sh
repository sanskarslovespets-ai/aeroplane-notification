#!/bin/bash
# Packages MeetingFly.app (built by package_app.sh) into a distributable,
# drag-to-Applications .dmg. Run package_app.sh first if MeetingFly.app is
# missing or stale.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:-1.0.0}"
APP_PATH="MeetingFly.app"
DMG_NAME="MeetingFly-${VERSION}.dmg"
STAGING_DIR=$(mktemp -d)

if [ ! -d "$APP_PATH" ]; then
  echo "error: $APP_PATH not found — run scripts/package_app.sh first" >&2
  exit 1
fi

echo "==> Staging DMG contents"
cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

echo "==> Building $DMG_NAME"
rm -f "$DMG_NAME"
hdiutil create -volname "MeetingFly" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_NAME"

rm -rf "$STAGING_DIR"
echo "==> Done: $(pwd)/$DMG_NAME"
