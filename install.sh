#!/bin/bash
# Build Wordbit with the Xcode Command Line Tools and install it to ~/Applications.
# Usage: ./install.sh
#        ./install.sh --build-only
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v swiftc >/dev/null 2>&1; then
  echo "swiftc was not found. Install the Xcode Command Line Tools first:" >&2
  echo "  xcode-select --install" >&2
  exit 1
fi

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64|arm64) ;;
  *) echo "This script supports Intel (x86_64) and Apple silicon (arm64). This Mac is ${ARCH}." >&2; exit 1 ;;
esac

BUILD_ONLY=0
if [ "${1:-}" = "--build-only" ]; then
  BUILD_ONLY=1
fi

APP="build/Wordbit.app"
BIN="$APP/Contents/MacOS/Wordbit"
rm -rf build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

echo "Compiling for ${ARCH}-apple-macos13.0"
swiftc -O -target "${ARCH}-apple-macos13.0" \
  -framework AppKit \
  -framework SwiftUI \
  -framework AVFoundation \
  -framework ServiceManagement \
  -framework UserNotifications \
  -o "$BIN" \
  Sources/*.swift

cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/words.json Resources/pictures.json "$APP/Contents/Resources/"
cp Resources/menubar-natural-18.png Resources/menubar-natural-18@2x.png "$APP/Contents/Resources/"
cp DATA-LICENSES.md LICENSE "$APP/Contents/Resources/"

if [ -d Resources/AppIcon.iconset ]; then
  echo "Packing the app icon"
  iconutil -c icns Resources/AppIcon.iconset -o "$APP/Contents/Resources/AppIcon.icns"
else
  echo "Drawing the app icon"
  "$BIN" --make-iconset build/AppIcon.iconset
  iconutil -c icns build/AppIcon.iconset -o "$APP/Contents/Resources/AppIcon.icns"
fi

echo "Signing (ad-hoc)"
codesign --force --deep -s - "$APP"

echo "Checking the word list, quiz, and pictures"
"$BIN" --check

if [ "$BUILD_ONLY" -eq 1 ]; then
  echo "Built $APP"
  exit 0
fi

# pkill only. AppleScript "quit app" can stall on an Automation permission prompt.
pkill -x Wordbit >/dev/null 2>&1 || true
pkill -x WordOfTheDay >/dev/null 2>&1 || true
sleep 0.4

mkdir -p "$HOME/Applications"
rm -rf "$HOME/Applications/Word of the Day.app"
rm -rf "$HOME/Applications/Wordbit.app"
cp -R "$APP" "$HOME/Applications/Wordbit.app"
codesign --force --deep -s - "$HOME/Applications/Wordbit.app"

echo "Installed to ~/Applications/Wordbit.app"
echo "Open it from Finder. The first time, if macOS blocks it, right-click the app and choose Open."
