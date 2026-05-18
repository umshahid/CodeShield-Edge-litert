#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="CodeShield Edge"
BUNDLE_ID="com.codeshield.edge.mac"
BUILD_DIR="$ROOT_DIR/.build/release"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

cd "$ROOT_DIR"
swift build -c release --product CodeShieldMac

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$BUILD_DIR/CodeShieldMac" "$MACOS_DIR/CodeShieldMac"

/usr/libexec/PlistBuddy -c "Clear dict" "$CONTENTS_DIR/Info.plist" >/dev/null 2>&1 || true
/usr/libexec/PlistBuddy -c "Add :CFBundleName string $APP_NAME" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string $APP_NAME" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string $BUNDLE_ID" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string 1" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string 0.1.0" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundlePackageType string APPL" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string CodeShieldMac" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Add :LSMinimumSystemVersion string 14.0" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Add :NSHumanReadableCopyright string CodeShield Edge" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Add :NSMicrophoneUsageDescription string CodeShield uses the microphone to transcribe your call locally before gift-card codes are transmitted." "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Add :NSSpeechRecognitionUsageDescription string CodeShield uses speech recognition to detect gift-card scam requests during calls." "$CONTENTS_DIR/Info.plist"

echo "Built $APP_DIR"
