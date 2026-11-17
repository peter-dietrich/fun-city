#!/usr/bin/env bash
# One-time, user-controlled Sparkle signing setup for Fun City Arcade.
# Private key material is generated on this Mac, sent to GitHub Actions
# secrets over the authenticated GitHub CLI, then removed from temporary files.
# It is never printed or checked into the repository.
set -euo pipefail
umask 077

readonly REPOSITORY="peter-dietrich/fun-city"
readonly ACCOUNT="io.funcity.arcade"
readonly SPARKLE_VERSION="2.10.1"
SPARKLE_KEY_BACKUP_PATH="${SPARKLE_KEY_BACKUP_PATH:-}"
readonly SPARKLE_SHA256="1a856d2a9edb8e628de88121d7be04cf0e2167f8641650b78fca00b14244cf27"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Run this setup on your Mac, not on a GitHub runner or Linux machine." >&2
  exit 1
fi

for program in curl tar shasum gh; do
  if ! command -v "$program" >/dev/null 2>&1; then
    echo "Missing $program. Install GitHub CLI with: brew install gh" >&2
    exit 1
  fi
done

if ! gh auth status --hostname github.com >/dev/null 2>&1; then
  echo "Please authenticate the GitHub CLI with: gh auth login" >&2
  exit 1
fi

if ! gh repo view "$REPOSITORY" --json nameWithOwner >/dev/null 2>&1; then
  echo "Cannot access $REPOSITORY with the current GitHub CLI login." >&2
  exit 1
fi

temporary="$(mktemp -d -t fun-city-sparkle)"
trap 'rm -rf "$temporary"' EXIT

echo "Downloading the official Sparkle $SPARKLE_VERSION signing tools..."
curl --fail --location --retry 3 --silent --show-error \
  "https://github.com/sparkle-project/Sparkle/releases/download/$SPARKLE_VERSION/Sparkle-$SPARKLE_VERSION.tar.xz" \
  --output "$temporary/sparkle.tar.xz"
printf '%s  %s\n' "$SPARKLE_SHA256" "$temporary/sparkle.tar.xz" | shasum -a 256 --check >/dev/null

mkdir "$temporary/tools"
tar -xJf "$temporary/sparkle.tar.xz" -C "$temporary/tools"
generate_keys="$(find "$temporary/tools" -type f -name generate_keys -print -quit)"
sign_update="$(find "$temporary/tools" -type f -name sign_update -print -quit)"
if [[ -z "$generate_keys" || -z "$sign_update" ]]; then
  echo "Sparkle release does not contain the expected signing tools." >&2
  exit 1
fi
chmod +x "$generate_keys" "$sign_update"

# Reuse the pre-existing key if one was already prepared for this app.
# Never replace a key while its prior Keychain account remains available.
if ! public_key="$("$generate_keys" --account "$ACCOUNT" -p 2>/dev/null)"; then
  echo "No existing Fun City signing key was found. Generating one in your login Keychain..."
  "$generate_keys" --account "$ACCOUNT" >/dev/null
  public_key="$("$generate_keys" --account "$ACCOUNT" -p)"
else
  echo "Reusing the existing Fun City signing key from your login Keychain."
fi

public_key="$(printf '%s' "$public_key" | tr -d '\r\n')"
if [[ "$(printf '%s' "$public_key" | base64 -D | wc -c | tr -d '[:space:]')" != "32" ]]; then
  echo "The public signing key is not a valid Ed25519 32-byte key." >&2
  exit 1
fi

private_key_file="$temporary/sparkle-ed25519-private.key"
"$generate_keys" --account "$ACCOUNT" -x "$private_key_file"
chmod 600 "$private_key_file"
test -s "$private_key_file"

# Verify that the exported key can sign and verify a throwaway file.
printf 'Fun City signing-key verification\n' > "$temporary/key-check.bin"
signed_output="$("$sign_update" --ed-key-file "$private_key_file" "$temporary/key-check.bin")"
signature="$(printf '%s\n' "$signed_output" | sed -n 's/.*sparkle:edSignature="\([^"]*\)".*/\1/p')"
if [[ -z "$signature" ]]; then
  echo "Sparkle signature check failed." >&2
  exit 1
fi
"$sign_update" --verify --ed-key-file "$private_key_file" "$temporary/key-check.bin" "$signature" >/dev/null

# Do not write secrets to shell history, repo files, or chat transcripts.
echo "Uploading signing material to GitHub Actions secrets..."
printf '%s' "$public_key" | gh secret set SPARKLE_PUBLIC_ED_KEY --repo "$REPOSITORY"
gh secret set SPARKLE_EDDSA_PRIVATE_KEY --repo "$REPOSITORY" < "$private_key_file"

# Keep a copy ONLY on an encrypted backup drive, if requested by the user.
# The default is Keychain-only; the temporary plaintext export is removed.
if [[ -n "$SPARKLE_KEY_BACKUP_PATH" ]]; then
  if [[ -e "$SPARKLE_KEY_BACKUP_PATH" ]]; then
    echo "Backup already exists and was not overwritten: $SPARKLE_KEY_BACKUP_PATH" >&2
    exit 1
  fi
  install -m 600 "$private_key_file" "$SPARKLE_KEY_BACKUP_PATH"
  echo "Saved a restricted private-key backup to the path you specified."
else
  echo "IMPORTANT: Back up your Keychain-held signing key on encrypted external media."
  echo "Losing this key would break update signing for existing installations."
fi

echo
echo "Fun City Sparkle keys are configured in GitHub Actions."
echo "Next: run bash scripts/check-release-readiness.sh"
