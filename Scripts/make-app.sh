#!/usr/bin/env bash
# Builds a universal (Apple silicon + Intel) release of Thumbrail.app, ad-hoc
# signs it, and zips it for distribution.
#
#   ./Scripts/make-app.sh            # version from Info.plist
#   VERSION=0.2.0 ./Scripts/make-app.sh
#
# Icon: drop a 1024x1024 PNG at Resources/AppIcon.png (or a ready-made
# Resources/AppIcon.icns) and it is bundled automatically.
set -euo pipefail
cd "$(dirname "$0")/.."

PLIST=Resources/Info.plist
VERSION=${VERSION:-$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$PLIST")}

swift build -c release --arch arm64 --arch x86_64
BIN=$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/Thumbrail

APP=build/Thumbrail.app
rm -rf build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Thumbrail"
cp "$PLIST" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set CFBundleShortVersionString $VERSION" "$APP/Contents/Info.plist"

if [[ -f Resources/AppIcon.icns ]]; then
    cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
elif [[ -f Resources/AppIcon.png ]]; then
    ICONSET=build/AppIcon.iconset
    mkdir -p "$ICONSET"
    for size in 16 32 128 256 512; do
        sips -z $size $size Resources/AppIcon.png --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
        sips -z $((size * 2)) $((size * 2)) Resources/AppIcon.png --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
    done
    iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
    rm -rf "$ICONSET"
fi

codesign --force --sign - "$APP"

ZIP=build/Thumbrail-$VERSION.zip
ditto -c -k --keepParent "$APP" "$ZIP"

echo "Built $APP"
echo "Packaged $ZIP"
