#!/bin/bash
# Build Wordbit with the Xcode Command Line Tools and install it to ~/Applications.
# Compiles arm64 and x86_64, then joins them with lipo.
# Usage: ./install.sh
#        ./install.sh --build-only
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v swiftc >/dev/null 2>&1; then
  echo "swiftc was not found. Install the Xcode Command Line Tools first:" >&2
  echo "  xcode-select --install" >&2
  exit 1
fi

if ! command -v lipo >/dev/null 2>&1; then
  echo "lipo was not found. Install the Xcode Command Line Tools first:" >&2
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
SLICE_ARM="build/Wordbit-arm64"
SLICE_X64="build/Wordbit-x86_64"
rm -rf build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

compile_slice() {
  local target="$1"
  local output="$2"
  echo "Compiling for ${target}"
  swiftc -O -target "$target" \
    -framework AppKit \
    -framework SwiftUI \
    -framework AVFoundation \
    -framework ServiceManagement \
    -framework UserNotifications \
    -o "$output" \
    Sources/*.swift
}

compile_slice "arm64-apple-macos13" "$SLICE_ARM"
compile_slice "x86_64-apple-macos13" "$SLICE_X64"
echo "Joining both chip types"
lipo -create "$SLICE_ARM" "$SLICE_X64" -output "$BIN"
rm -f "$SLICE_ARM" "$SLICE_X64"
lipo -info "$BIN"

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
LEGACY="$HOME/Applications/Word of the Day.app"
if [ -d "$LEGACY" ]; then
  echo "Removing \"Word of the Day.app\" from ~/Applications. Wordbit replaces that older app."
  rm -rf "$LEGACY"
fi
rm -rf "$HOME/Applications/Wordbit.app"
cp -R "$APP" "$HOME/Applications/Wordbit.app"
codesign --force --deep -s - "$HOME/Applications/Wordbit.app"

echo "Installed to ~/Applications/Wordbit.app"
echo "Opening Wordbit."
echo "The first time, macOS stops it and says \"Apple could not verify…\". Let it through once:"
echo "  macOS 15 Sequoia or newer: click Done. Open System Settings → Privacy & Security, scroll down to \"Wordbit was blocked…\", click Open Anyway, and type your Mac password."
echo "  macOS 13 Ventura or 14 Sonoma: in ~/Applications, right-click (or Control-click) Wordbit, choose Open, then click Open again."
echo "  Or, in Terminal: xattr -dr com.apple.quarantine \"$HOME/Applications/Wordbit.app\""
open "$HOME/Applications/Wordbit.app" || true
