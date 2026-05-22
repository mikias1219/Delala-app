#!/usr/bin/env bash
# Rebuild Android APK (no extra steps — just build).
# Usage: ./scripts/build-mobile.sh [--install]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MOBILE="$ROOT/apps/mobile"
INSTALL=false

[[ "${1:-}" == "--install" ]] && INSTALL=true

[[ -f "$ROOT/.env" ]] && set -a && source "$ROOT/.env" && set +a

if [[ -z "${ANDROID_HOME:-}" && -d "$HOME/Android/Sdk" ]]; then
  export ANDROID_HOME="$HOME/Android/Sdk"
  export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
fi

PORT="${PORT:-3010}"
IP="${LAN_IP:-$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')}"
API_URL="http://${IP}:${PORT}/${API_PREFIX:-api/v1}"
APK="$MOBILE/build/app/outputs/flutter-apk/app-release.apk"

if [[ ! -d "${ANDROID_HOME:-}/platforms/android-36" ]]; then
  echo "Run: ./scripts/setup-android.sh" >&2
  exit 1
fi

flutter config --android-sdk "${ANDROID_HOME}" >/dev/null 2>&1 || true

echo "API baked in: $API_URL"
cd "$MOBILE"
flutter pub get
flutter build apk --release --dart-define=API_BASE_URL="$API_URL"
echo "APK: $APK"

if $INSTALL && command -v adb >/dev/null && adb devices | grep -q 'device$'; then
  adb install -r "$APK"
  echo "Installed."
fi
