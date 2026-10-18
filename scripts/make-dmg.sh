#!/bin/bash
# Build a universal Wordbit disk image (Intel and Apple chip).
# install.sh compiles -target arm64-apple-macos13 and -target x86_64-apple-macos13,
# then joins them with lipo -create. This script packages that app.
# Usage: ./scripts/make-dmg.sh
set -euo pipefail
cd "$(dirname "$0")/.."

./install.sh --build-only

VERSION="$(plutil -extract CFBundleShortVersionString raw Resources/Info.plist)"
STAGE="build/dmg-root"
DMG="build/Wordbit-${VERSION}.dmg"

rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -R build/Wordbit.app "$STAGE/Wordbit.app"
ln -s /Applications "$STAGE/Applications"

rm -f "$DMG"
hdiutil create -volname "Wordbit" -srcfolder "$STAGE" -ov -format UDZO "$DMG"
echo "Built $DMG"
shasum -a 256 "$DMG"
echo "Universal check:"
lipo -info "build/Wordbit.app/Contents/MacOS/Wordbit"
