#!/usr/bin/env bash
# Read-only release readiness check. This never prints secret values.
set -euo pipefail
REPO="peter-dietrich/fun-city"
cd "$(dirname "$0")/.."
command -v gh >/dev/null || { echo "Install GitHub CLI: brew install gh"; exit 1; }
gh auth status -h github.com >/dev/null 2>&1 || { echo "Run gh auth login first"; exit 1; }

echo "Fun City release prerequisites for $REPO"
echo "-------------------------------------------"
names="$(gh secret list -R "$REPO" --json name --jq '.[].name')"
missing=0
for name in \
  SPARKLE_PUBLIC_ED_KEY SPARKLE_EDDSA_PRIVATE_KEY \
  APPLE_DEVELOPER_ID_CERT_BASE64 APPLE_DEVELOPER_ID_CERT_PASSWORD \
  APPLE_SIGNING_IDENTITY APPLE_ID APPLE_TEAM_ID APPLE_APP_SPECIFIC_PASSWORD
do
  if printf '%s\n' "$names" | grep -Fxq "$name"; then
    echo "[set]     $name"
  else
    echo "[missing] $name"
    missing=1
  fi
done
if command -v xcodebuild >/dev/null 2>&1; then
  echo "[ok]      Xcode command-line tools available"
else
  echo "[missing] xcodebuild"
  missing=1
fi
echo
if [[ "$missing" == 0 ]]; then
  echo "All named secrets exist. Values, validity, signing identity,"
  echo "Apple notarization and live self-updates still require release testing."
else
  echo "Missing prerequisites. Do not create a public v* release tag."
fi
exit "$missing"
