#!/usr/bin/env bash
# Builds build/TextSnap.app (release, signed).
# Signs with CODESIGN_IDENTITY, else the local identity from setup-signing.sh, else ad-hoc.
# Ad-hoc builds lose the Screen Recording grant on every rebuild; run setup-signing.sh once.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="TextSnap"
APP="$ROOT/build/$APP_NAME.app"
LOCAL_IDENTITY="TextSnap Local Signing"

if [[ -n "${CODESIGN_IDENTITY:-}" ]]; then
    IDENTITY="$CODESIGN_IDENTITY"
elif security find-certificate -c "$LOCAL_IDENTITY" >/dev/null 2>&1; then
    IDENTITY="$LOCAL_IDENTITY"
else
    echo "warning: no stable signing identity; run scripts/setup-signing.sh" >&2
    IDENTITY="-"
fi

swift build -c release --package-path "$ROOT"
BIN_DIR="$(swift build -c release --package-path "$ROOT" --show-bin-path)"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/$APP_NAME" "$APP/Contents/MacOS/$APP_NAME"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"

codesign --force --options runtime --sign "$IDENTITY" "$APP"
codesign --verify --strict "$APP"
echo "Built $APP"
