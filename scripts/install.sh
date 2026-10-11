#!/usr/bin/env bash
# Builds, installs into /Applications (or ~/Applications if not writable) and launches TextSnap.
set -euo pipefail

source "$(dirname "$0")/config.sh"

"$ROOT/scripts/build.sh"

DEST="/Applications"
[[ -w "$DEST" ]] || DEST="$HOME/Applications"
mkdir -p "$DEST"

pkill -x "$APP_NAME" 2>/dev/null && sleep 0.5 || true
rm -rf "$DEST/$APP_NAME.app"
cp -R "$ROOT/build/$APP_NAME.app" "$DEST/"
open "$DEST/$APP_NAME.app"
echo "Installed $DEST/$APP_NAME.app"
