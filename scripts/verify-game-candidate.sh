#!/usr/bin/env bash
# Validate a signed candidate without installing or launching it.
set -euo pipefail
set +x
[[ "$(uname -s)" == Darwin ]] || { echo "macOS required" >&2; exit 1; }
[[ "$#" == 2 ]] || { echo "Usage: bash scripts/verify-game-candidate.sh GAME RUN_ID" >&2; exit 2; }
game="$1"; run="$2"
case "$game" in
 siege) repo=vector-siege; app=VectorSiege; bundle=io.vectorsiege.game ;;
 swarm) repo=vector-swarm; app=VectorSwarm; bundle=io.vectorswarm.game ;;
 vortex) repo=vector-vortex; app=VectorVortex; bundle=io.vectorvortex.game ;;
 barrage) repo=vector-barrage; app=VectorBarrage; bundle=io.vectorbarrage.game ;;
 soar) repo=vector-soar; app=VectorSoar; bundle=io.vectorsoar.game ;;
 aces) repo=vector-aces; app=VectorAces; bundle=io.vectoraces.game ;;
 *) echo "Unknown game: $game" >&2; exit 2 ;;
esac
[[ "$run" =~ ^[0-9]+$ ]] || { echo "Run ID must be numeric" >&2; exit 2; }
command -v gh >/dev/null || { echo "Install GitHub CLI first" >&2; exit 1; }
root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT
gh run view "$run" -R "peter-dietrich/$repo" --exit-status >/dev/null
gh run download "$run" -R "peter-dietrich/$repo" --name "$app-signed-candidate" --dir "$root"
(cd "$root" && shasum -a 256 -c "$app-macOS.zip.sha256" && ditto -x -k "$app-macOS.zip" .)
target="$root/$app.app"
test -d "$target"
actual="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$target/Contents/Info.plist")"
[[ "$actual" == "$bundle" ]] || { echo "Unexpected bundle ID: $actual" >&2; exit 1; }
codesign --verify --deep --strict --verbose=2 "$target"
details="$(codesign --display --verbose=4 "$target" 2>&1)"
grep -Fq 'TeamIdentifier=6C9RJ9VDE2' <<< "$details"
grep -Fq 'Authority=Developer ID Application: Peter Dietrich (6C9RJ9VDE2)' <<< "$details"
spctl --assess --type execute --verbose=4 "$target"
xcrun stapler validate "$target"
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$target/Contents/Info.plist")"
build="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$target/Contents/Info.plist")"
echo "PASS: $app version $version ($build); signed, notarized, checksummed."
echo "No app installed or launched. Existing game files and saves untouched."
