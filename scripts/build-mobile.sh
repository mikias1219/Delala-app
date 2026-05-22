#!/usr/bin/env bash
# Build Android APK — optimized for speed (arm64 only by default).
#
# Usage:
#   ./scripts/build-mobile.sh              # release APK, ~2–5 min after first build
#   ./scripts/build-mobile.sh --fast       # debug APK, quickest for testing
#   ./scripts/build-mobile.sh --install    # release + install via USB
#   ./scripts/build-mobile.sh --all-abis   # fat APK (arm + arm64 + x64, slow)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MOBILE="$ROOT/apps/mobile"
INSTALL=false
FAST=false
ALL_ABIS=false

for arg in "$@"; do
  case "$arg" in
    --install) INSTALL=true ;;
    --fast) FAST=true ;;
    --all-abis) ALL_ABIS=true ;;
  esac
done

[[ -f "$ROOT/.env" ]] && set -a && source "$ROOT/.env" && set +a

if [[ -z "${ANDROID_HOME:-}" && -d "$HOME/Android/Sdk" ]]; then
  export ANDROID_HOME="$HOME/Android/Sdk"
  export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
fi

PORT="${PORT:-3010}"
IP="${LAN_IP:-$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')}"
API_URL="http://${IP}:${PORT}/${API_PREFIX:-api/v1}"

if [[ ! -d "${ANDROID_HOME:-}/platforms/android-36" ]]; then
  echo "Run: ./scripts/setup-android.sh" >&2
  exit 1
fi

flutter config --android-sdk "${ANDROID_HOME}" >/dev/null 2>&1 || true

cd "$MOBILE"

# Skip pub get if lockfile unchanged (saves ~5–15s)
LOCK_HASH_FILE="$ROOT/.dev/pubspec.hash"
CURRENT_HASH=$(md5sum pubspec.lock 2>/dev/null | cut -d' ' -f1 || echo none)
if [[ -f "$LOCK_HASH_FILE" ]] && [[ "$(cat "$LOCK_HASH_FILE")" == "$CURRENT_HASH" ]]; then
  echo "Dependencies up to date (skipped pub get)"
else
  flutter pub get
  mkdir -p "$ROOT/.dev"
  echo "$CURRENT_HASH" >"$LOCK_HASH_FILE"
fi

BUILD_ARGS=(--dart-define=API_BASE_URL="$API_URL")

# arm64 only = one native build instead of three (biggest speed win)
if ! $ALL_ABIS; then
  BUILD_ARGS+=(--target-platform android-arm64)
fi

if $FAST; then
  echo "Fast debug build (arm64) → API: $API_URL"
  flutter build apk --debug "${BUILD_ARGS[@]}"
  APK="$MOBILE/build/app/outputs/flutter-apk/app-debug.apk"
else
  echo "Release build (arm64) → API: $API_URL"
  flutter build apk --release "${BUILD_ARGS[@]}"
  APK="$MOBILE/build/app/outputs/flutter-apk/app-release.apk"
fi

echo "APK: $APK"
ls -lh "$APK"

if $INSTALL && command -v adb >/dev/null && adb devices | grep -q 'device$'; then
  adb install -r "$APK"
  echo "Installed."
fi
