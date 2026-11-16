# Fun City: Local Developer ID signing setup

Run the companion helper only on a trusted Mac, after confirming you have an active paid
Apple Developer membership, a valid Developer ID Application signing identity and the
password-protected .p12 containing its PRIVATE KEY.

Check your identity:

    security find-identity -v -p codesigning

Ensure Apple's notarization credential profile has been validated locally:

    xcrun notarytool store-credentials FunCity-Notary --apple-id YOUR_EMAIL --team-id YOUR_TEAM_ID

That Keychain profile is only local. GitHub Actions runners need the app-specific
password and Developer ID export uploaded as encrypted repository secrets.

Run from the updated Fun City repository:

    cd ~/Documents/GitHub/fun-city
    git switch main
    git pull --ff-only origin main
    bash scripts/setup-signing-secrets.sh

The helper prompts for the .p12 absolute path, exact signing identity, Team ID, email,
.p12 password, and app-specific notarization password. It uploads values via gh secret
set standard input to each of these repositories: fun-city, vector-drift,
vector-siege, vector-swarm, vector-vortex, vector-barrage, vector-soar, vector-aces.
It does not print, save or commit secret values. The setup overwrites any previous
secrets with matching names in each repository.

To list the six configured SECRET NAMES in each repo (not their values):

    bash scripts/setup-signing-secrets.sh --check

Expected names: APPLE_DEVELOPER_ID_CERT_BASE64, APPLE_DEVELOPER_ID_CERT_PASSWORD,
APPLE_SIGNING_IDENTITY, APPLE_ID, APPLE_TEAM_ID, APPLE_APP_SPECIFIC_PASSWORD.

IMPORTANT: No public releases are created by this script. Do not create version tags
before a signed/notarized pilot tests the whole GitHub release, checksum, macOS
installer, launch, installed-version detection, update and rollback lifecycle.
Vector Barrage, Vector Soar and Vector Aces still need signed release workflows.
Never send certificate files, private keys or passwords through ChatGPT or GitHub issues.
