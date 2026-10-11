#!/usr/bin/env bash
# Removes TextSnap: the app, its Screen Recording grant and its preferences.
# Once the app is gone, macOS drops it from Login Items on its own.
#
#   --remove-signing-identity   also delete the local code signing certificate
set -euo pipefail

source "$(dirname "$0")/config.sh"

pkill -x "$APP_NAME" 2>/dev/null || true

for dir in /Applications "$HOME/Applications"; do
    if [[ -d "$dir/$APP_NAME.app" ]]; then
        rm -rf "${dir:?}/$APP_NAME.app"
        echo "Removed $dir/$APP_NAME.app"
    fi
done

tccutil reset ScreenCapture "$BUNDLE_ID" >/dev/null 2>&1 && echo "Reset Screen Recording permission" || true
defaults delete "$BUNDLE_ID" >/dev/null 2>&1 && echo "Removed preferences" || true

if [[ "${1:-}" == "--remove-signing-identity" ]]; then
    security delete-identity -c "$SIGNING_IDENTITY" "$LOGIN_KEYCHAIN" >/dev/null 2>&1 \
        && echo "Removed signing identity '$SIGNING_IDENTITY'" || true
fi

echo "TextSnap uninstalled"
