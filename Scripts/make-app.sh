#!/usr/bin/env bash
# Builds a release binary and wraps it in an ad-hoc signed EdgePanel.app.
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release

APP=build/EdgePanel.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/EdgePanel "$APP/Contents/MacOS/EdgePanel"
cp Resources/Info.plist "$APP/Contents/Info.plist"
codesign --force --sign - "$APP"

echo "Built $APP"
echo "Run it with: open $APP"
