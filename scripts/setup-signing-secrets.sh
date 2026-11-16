#!/bin/bash
# Configure GitHub Actions signing for Fun City and seven games.
# Run on a trusted Mac. Never share .p12, keys, or passwords with anyone.
set -euo pipefail
set +x
umask 077

owner="peter-dietrich"
repos="fun-city vector-drift vector-siege vector-swarm vector-vortex vector-barrage vector-soar vector-aces"
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This setup helper requires macOS." >&2; exit 1
fi
command -v gh >/dev/null || { echo "Install gh first: brew install gh" >&2; exit 1; }
gh auth status >/dev/null || { echo "Authenticate with: gh auth login" >&2; exit 1; }

if [[ "$#" -eq 1 && "$1" == "--check" ]]; then
  echo "Listing GitHub Actions secret names only (values are never shown):"
  for name in $repos; do
    echo "=== $owner/$name ==="
    gh secret list --repo "$owner/$name"
  done
  exit 0
fi
if [[ "$#" -ne 0 ]]; then
  echo "Usage: bash scripts/setup-signing-secrets.sh [--check]" >&2; exit 2
fi

echo "Fun City: set six signing/notarization secrets in eight repositories."
echo "This DOES NOT release any application or upload raw certificates to a repository."
echo
security find-identity -v -p codesigning
echo
read -r -p "Absolute path to protected Developer ID Application .p12: " p12_file
if [[ ! -f "$p12_file" || "$p12_file" != *.p12 ]]; then
  echo "File must exist and end in .p12." >&2; exit 1
fi
read -r -p "Exact Developer ID Application identity (or SHA-1): " signing_identity
read -r -p "10-character Apple Developer Team ID: " team_id
read -r -p "Apple Account email used by notarytool: " apple_id
if [[ -z "$signing_identity" || ! "$team_id" =~ ^[A-Z0-9]{10}$ || "$apple_id" != *@* ]]; then
  echo "Provide a nonempty identity, valid Team ID, and email." >&2; exit 1
fi
read -r -s -p "Password protecting the exported .p12: " p12_password
printf '\n'
read -r -s -p "Apple app-specific notarization password (NOT normal Apple login): " notary_password
printf '\n'
if [[ -z "$p12_password" || -z "$notary_password" ]]; then
  echo "Both secret passwords are required." >&2; exit 1
fi
echo
echo "Targets:"
for name in $repos; do echo "  $owner/$name"; done
echo "Existing secrets of the same names will be replaced."
read -r -p "Type SET-SIGNING-SECRETS to proceed: " confirmation
if [[ "$confirmation" != "SET-SIGNING-SECRETS" ]]; then
  echo "Cancelled, no GitHub secrets were changed."
  exit 0
fi
for name in $repos; do
  target="$owner/$name"
  echo "Setting six secrets for $target..."
  base64 < "$p12_file" | tr -d '\r\n' | gh secret set APPLE_DEVELOPER_ID_CERT_BASE64 --repo "$target"
  printf '%s' "$p12_password" | gh secret set APPLE_DEVELOPER_ID_CERT_PASSWORD --repo "$target"
  printf '%s' "$signing_identity" | gh secret set APPLE_SIGNING_IDENTITY --repo "$target"
  printf '%s' "$apple_id" | gh secret set APPLE_ID --repo "$target"
  printf '%s' "$team_id" | gh secret set APPLE_TEAM_ID --repo "$target"
  printf '%s' "$notary_password" | gh secret set APPLE_APP_SPECIFIC_PASSWORD --repo "$target"
  echo "Configured $target."
done
unset p12_password notary_password signing_identity
echo "Signing secrets uploaded. Verify names with:"
echo "  bash scripts/setup-signing-secrets.sh --check"
echo "Do NOT publish v* tags before validating a signed pilot release."
