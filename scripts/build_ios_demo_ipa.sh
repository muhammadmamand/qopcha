#!/usr/bin/env bash
# =============================================================================
# build_ios_demo_ipa.sh — build a demo IPA for قۆپچە (com.qopcha.Qopcha)
#
# MUST run on macOS with Xcode. Cannot run on Windows.
#
# Prerequisites
# -------------
# 1. Mac with Xcode + CocoaPods (`sudo gem install cocoapods` or brew).
# 2. Flutter stable on PATH (`flutter doctor` shows iOS toolchain OK).
# 3. Apple Developer Program (paid) for TestFlight / shareable demo.
# 4. Open ios/Runner.xcworkspace once in Xcode → Runner target → Signing
#    & Capabilities → select your Team (Automatic signing). Bundle ID is
#    already com.qopcha.Qopcha.
# 5. App Store Connect: create an app with the same bundle ID.
#
# TestFlight (default — best for demos)
# -------------------------------------
#   ./scripts/build_ios_demo_ipa.sh
#   Upload build/ios/ipa/*.ipa with Transporter or:
#     xcrun altool --upload-app -f build/ios/ipa/*.ipa -t ios \
#       --apiKey YOUR_KEY --apiIssuer YOUR_ISSUER
#   Then invite testers in App Store Connect → TestFlight.
#
# Ad Hoc (raw IPA for registered devices only)
# --------------------------------------------
#   ./scripts/build_ios_demo_ipa.sh --ad-hoc
#   Install via Apple Configurator / Xcode Devices, or a link + manifest.
#
# One device + Mac (no IPA file needed)
# -------------------------------------
#   flutter run --release -d <iphone_device_id>
#
# Codemagic (no local Mac)
# ------------------------
# 1. Push this repo to GitHub/GitLab.
# 2. Connect it at https://codemagic.io
# 3. Enable iOS code signing (App Store Connect API key + automatic certs).
# 4. Build workflow: flutter build ipa --release
# 5. Download the IPA artifact or publish to TestFlight from Codemagic.
#
# Do not commit certificates, .p12, or provisioning profiles to git.
# =============================================================================

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

EXPORT_PLIST="$ROOT/ios/ExportOptions-AppStore.plist"
MODE="app-store-connect"

if [[ "${1:-}" == "--ad-hoc" ]]; then
  EXPORT_PLIST="$ROOT/ios/ExportOptions-AdHoc.plist"
  MODE="ad-hoc"
fi

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "error: this script must run on macOS with Xcode (not Windows/Linux)." >&2
  echo "       Use a Mac, or Codemagic / another cloud Mac CI." >&2
  exit 1
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "error: flutter not found on PATH." >&2
  exit 1
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "error: xcodebuild not found. Install Xcode from the App Store." >&2
  exit 1
fi

echo "==> Flutter pub get"
flutter pub get

if [[ -f "$ROOT/ios/Podfile" ]]; then
  echo "==> pod install"
  (cd "$ROOT/ios" && pod install --repo-update)
fi

echo "==> Building IPA (export: $MODE)"
flutter build ipa --release --export-options-plist="$EXPORT_PLIST"

IPA_DIR="$ROOT/build/ios/ipa"
echo ""
echo "Done. IPA output:"
if [[ -d "$IPA_DIR" ]]; then
  ls -la "$IPA_DIR"/*.ipa 2>/dev/null || ls -la "$IPA_DIR"
else
  echo "  (check build/ios/ for archive / export logs)"
fi
echo ""
if [[ "$MODE" == "app-store-connect" ]]; then
  echo "Next: upload the .ipa to App Store Connect (Transporter), then TestFlight."
else
  echo "Next: install the Ad Hoc .ipa on devices registered in your developer portal."
fi
