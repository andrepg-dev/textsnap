# Shared settings for the scripts in this folder. Sourced, not executed.
# shellcheck shell=bash

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="TextSnap"
BUNDLE_ID="com.andreponce.TextSnap"
SIGNING_IDENTITY="TextSnap Local Signing"
LOGIN_KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"
