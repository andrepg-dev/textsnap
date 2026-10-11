#!/usr/bin/env bash
# Creates a self-signed code signing identity in the login keychain (once).
#
# Ad-hoc signatures change on every build, and macOS ties privacy grants
# (Screen Recording) to the signature, so each rebuild silently loses the grant.
# A stable certificate keeps the app's designated requirement identical across builds.
set -euo pipefail

NAME="${1:-TextSnap Local Signing}"
KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"

if security find-certificate -c "$NAME" "$KEYCHAIN" >/dev/null 2>&1; then
    echo "Identity '$NAME' already exists"
    exit 0
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
PASSWORD="$(uuidgen)"

/usr/bin/openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
    -subj "/CN=$NAME" \
    -addext "basicConstraints=critical,CA:false" \
    -addext "keyUsage=critical,digitalSignature" \
    -addext "extendedKeyUsage=critical,codeSigning" \
    -keyout "$WORK/key.pem" -out "$WORK/cert.pem" 2>/dev/null
/usr/bin/openssl pkcs12 -export -inkey "$WORK/key.pem" -in "$WORK/cert.pem" \
    -name "$NAME" -passout "pass:$PASSWORD" -out "$WORK/identity.p12"

security import "$WORK/identity.p12" -k "$KEYCHAIN" -P "$PASSWORD" -T /usr/bin/codesign
echo "Created identity '$NAME'"
