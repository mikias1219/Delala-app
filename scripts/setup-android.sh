#!/usr/bin/env bash
# One-time Android SDK setup. Requires: sudo apt install -y openjdk-17-jdk
set -euo pipefail
exec "$(dirname "$0")/setup-android-sdk.sh" "$@"
