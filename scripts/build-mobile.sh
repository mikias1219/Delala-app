#!/usr/bin/env bash
# Build Android APK — optimized for speed.
#
# Usage:
#   ./scripts/build-mobile.sh              # debug APK (~1–3 min after first build)
#   ./scripts/build-mobile.sh --release  # release APK (slower, for sharing)
#   ./scripts/build-mobile.sh --install  # build + USB install
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MOBILE="$ROOT/apps/mobile"
RELEASE=false
INSTALL=false
ALL_ABIS=false

for arg in "$@"; do
  case "$arg" in
    --release) RELEASE=true ;;
    --install) INSTALL=true ;;
    --all-abis) ALL_ABIS=true ;;
    --fast) ;; # default now; kept for compatibility
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

ARGS=(
  --target-platform android-arm64
  --dart-define=API_BASE_URL="$API_URL"
)

if ! $ALL_ABIS; then
  : # arm64 only (default)
else
  ARGS=() # all ABIs
fi

if $RELEASE; then
  echo "▶ Release APK (arm64) — API: $API_URL"
  flutter build apk --release "${ARGS[@]}"
  APK="$MOBILE/build/app/outputs/flutter-apk/app-release.apk"
else
  echo "▶ Debug APK (arm64, fastest) — API: $API_URL"
  echo "  (First build downloads Gradle deps once — can take 10–15 min; later builds ~1–3 min)"
  flutter build apk --debug "${ARGS[@]}"
  APK="$MOBILE/build/app/outputs/flutter-apk/app-debug.apk"
fi

echo ""
echo "APK: $APK"
ls -lh "$APK"

if $INSTALL && command -v adb >/dev/null && adb devices | grep -q 'device$'; then
  adb install -r "$APK"
  echo "Installed."
fi
