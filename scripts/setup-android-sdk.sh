#!/usr/bin/env bash
# Install Android SDK to ~/Android/Sdk (no sudo) and configure Flutter.
# Requires Java 17 — install first: sudo apt install -y openjdk-17-jdk
set -euo pipefail

SDK_ROOT="${ANDROID_HOME:-$HOME/Android/Sdk}"
CMD_TOOLS="$SDK_ROOT/cmdline-tools/latest"
ZIP_URL="https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip"
TMP_ZIP="/tmp/android-cmdline-tools.zip"
JDK_DIR="$HOME/.local/jdk-17"

# Flutter 3.41 defaults
PLATFORMS="platforms;android-36"
BUILD_TOOLS="build-tools;36.0.0"
PACKAGES="platform-tools $PLATFORMS $BUILD_TOOLS"

setup_java() {
  if command -v java >/dev/null 2>&1; then
    return 0
  fi
  if [[ -x "$JDK_DIR/bin/java" ]]; then
    export JAVA_HOME="$JDK_DIR"
    export PATH="$JAVA_HOME/bin:$PATH"
    return 0
  fi
  echo "Java is required for the Android SDK tools."
  echo ""
  echo "Install Java (recommended):"
  echo "  sudo apt install -y openjdk-17-jdk"
  echo ""
  echo "Then re-run: ./scripts/setup-android-sdk.sh"
  exit 1
}

setup_java

echo "Android SDK will be installed to: $SDK_ROOT"
mkdir -p "$SDK_ROOT"

if [[ ! -x "$CMD_TOOLS/bin/sdkmanager" ]]; then
  echo "Downloading Android command-line tools…"
  curl -fsSL "$ZIP_URL" -o "$TMP_ZIP"
  mkdir -p "$SDK_ROOT/cmdline-tools"
  unzip -qo "$TMP_ZIP" -d "$SDK_ROOT/cmdline-tools"
  mv "$SDK_ROOT/cmdline-tools/cmdline-tools" "$CMD_TOOLS"
  rm -f "$TMP_ZIP"
fi

export ANDROID_HOME="$SDK_ROOT"
export ANDROID_SDK_ROOT="$SDK_ROOT"
export PATH="$CMD_TOOLS/bin:$SDK_ROOT/platform-tools:$PATH"

echo "Installing SDK packages (may take a few minutes)…"
yes | sdkmanager --sdk_root="$SDK_ROOT" --licenses >/dev/null 2>&1 || true
sdkmanager --sdk_root="$SDK_ROOT" $PACKAGES

flutter config --android-sdk "$SDK_ROOT"

echo ""
echo "Add to ~/.bashrc (recommended):"
echo "  export ANDROID_HOME=\"$SDK_ROOT\""
echo "  export ANDROID_SDK_ROOT=\"$SDK_ROOT\""
echo "  export PATH=\"\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$PATH\""
echo ""
flutter doctor --android-licenses 2>/dev/null || true
flutter doctor -v | sed -n '/Android toolchain/,/^[^ ]/p' | head -15
echo ""
echo "Done. Build APK with: ./scripts/build-install-apk.sh"
