# Fun City self-updates

Fun City launcher updates are **distinct from individual game updates**. The app uses Sparkle 2.10.1 (Swift Package Manager), with a signed and notarized DMG published as a GitHub Release and an Ed25519-signed update archive referenced by `appcast.xml`. The seven game repositories keep their independent update paths.

## Development builds

An Xcode **Debug** launcher does not self-update. This is intentional: Sparkle must never overwrite a local source-built copy. The app-menu **Check for Fun City Updates…** command is disabled in Debug, and unsigned Release previews lacking a public update-verification key also disable updater startup.

## One-time signing key preparation

**Run this only on your own Mac** from the Fun City source checkout. Private signing material must not be pasted into chat, issues, or command-line arguments. First ensure `gh` is available and connected:

```bash
cd ~/Documents/GitHub/fun-city
git switch main
git pull --ff-only origin main
brew install gh  # skip if already installed
gh auth login     # skip if already authenticated
bash scripts/setup-sparkle-signing.sh
bash scripts/check-release-readiness.sh
```

The setup script pins the official Sparkle 2.10.1 tarball by SHA-256, reuses an existing Fun City key from the login Keychain or generates a new one, verifies test signing, and sends the public/private values to the matching GitHub Actions secrets via authenticated `gh`. It uses a restrictive temporary directory and deletes the private export on exit. Back up your key separately on encrypted offline media; preserving that key is essential for continuity of deployed updates.

The readiness script checks **presence only** of the eight required GitHub Actions secrets; it neither reads nor prints their values and cannot establish that they are valid. A missing Apple Developer ID secret must be configured by the repository owner with the appropriate Apple signing credentials before a release tag can be published.



The project owner must initialize and safeguard a Sparkle Ed25519 signing key pair **before publishing the first DMG**. The signing key is independent from the Apple Developer ID certificate.

1. Use the `generate_keys` tool from the pinned Sparkle distribution, available in Xcode's downloaded package artifacts or in the official Sparkle 2.10.1 release. The tool prints a **public key** and stores the private signing key in the local Keychain.
2. Export the private key securely using Sparkle's documented `generate_keys -x <private-key-file>` command and keep an offline backup. Do not commit, print to logs, send in chat, or store in project files.
3. In the Fun City GitHub repository, configure these **Actions secrets**:
   - `SPARKLE_PUBLIC_ED_KEY`: the public base64 key printed by Sparkle.
   - `SPARKLE_EDDSA_PRIVATE_KEY`: the private key export content from Sparkle, consumed via standard input by the release workflow.
4. The pre-existing Apple Developer ID and notarization secrets remain necessary: `APPLE_DEVELOPER_ID_CERT_BASE64`, `APPLE_DEVELOPER_ID_CERT_PASSWORD`, `APPLE_SIGNING_IDENTITY`, `APPLE_ID`, `APPLE_TEAM_ID`, and `APPLE_APP_SPECIFIC_PASSWORD`.

Keep the public key constant across ordinary releases. Never publish a DMG with an empty or incorrect embedded `SUPublicEDKey`. Publishing a release without a valid matching signing key would strand users on a non-updating copy.

## Releasing

1. Validate the latest `main` commit with **both Debug and Release** macOS builds in GitHub Actions and test it on a Mac. Do not tag untested source.
2. Increase `CURRENT_PROJECT_VERSION` (the numeric CFBundleVersion) in the Xcode project for **every** new published launcher update. Adjust `MARKETING_VERSION` as appropriate. Sparkle compares the numeric build, not only the visible marketing version.
3. Create an approved stable tag (e.g. `v0.4.1`) at that reviewed commit and push it. Tags matching `v*` trigger `.github/workflows/release.yml`.
4. The workflow checks for the public key, builds Release with that key embedded, signs with Developer ID, notarizes and staples the app and DMG, then signs the DMG with Sparkle's EdDSA private key. It publishes the DMG, its SHA-256 sidecar, and a generated `appcast.xml` to the *same* stable GitHub Release.
5. The embedded feed is `https://github.com/peter-dietrich/fun-city/releases/latest/download/appcast.xml`. This points to the latest **non-prerelease** GitHub release; do not mix development prereleases with public launcher updates.
6. On a **different Mac**, or from an already installed prior signed release, copy FunCity.app from the DMG into /Applications and test **Fun City Arcade → Check for Fun City Updates…**; verify downloading, signature verification, replacement, restart, and preservation of game settings/saves.

### Safeguards

- No automatic update signing key is checked into Git.
- The Sparkle archive is EdDSA signed and downloaded over HTTPS.
- An unconfigured Release build will not start the updater; its manual command is disabled.
- Preview/PR builds remain unsigned and unpublishable, and the signed GitHub Release job fails if update-signing secrets are missing.
- No game, save, settings, or high-score paths are intentionally modified by a launcher update.
- Updates to each game continue through its own GitHub repository.
- The release pipeline generates an *archive-signed* appcast; signed feeds/delta downloads are potential future hardening, not claimed as currently implemented.

### Verification gate

The presence of the integration in a Debug Xcode build **does not** demonstrate a completed self-update. The feature is not considered shipping-ready until a real signed/notarized earlier launcher version successfully updates to a newer signed/notarized stable version on a clean Mac. GitHub's current build workflow checks compilation only.
