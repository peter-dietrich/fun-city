# Fun City — development and operations

**Repository:** https://github.com/peter-dietrich/fun-city  
**Role:** Arcade launcher / game release installer  
**Minimum runtime:** macOS 13+  
**Technologies:** SwiftUI and AppKit  
**Bundle ID:** io.funcity.arcade

## Release model

**Two different outcomes:**

1. **Developer build:** Build locally in Xcode or via the macOS CI workflow. `CODE_SIGNING_ALLOWED=NO` creates an unsigned development product, not a notarized distributable.
2. **Public signed release:** The repository's `.github/workflows/release.yml` builds in Release, expects an Apple **Developer ID Application** signing identity, imports a signing certificate, signs with hardened runtime, submits to Apple notarization, staples, packages, computes SHA-256 and publishes a GitHub Release on a `v*` tag. An untagged PR check is **not** a signed public release.

## Required release prerequisites

- Active Apple Developer Program membership and valid Developer ID Application certificate for outside-the-App-Store distribution.
- Repository Actions secrets: `APPLE_DEVELOPER_ID_CERT_BASE64`, `APPLE_DEVELOPER_ID_CERT_PASSWORD`, `APPLE_SIGNING_IDENTITY`, `APPLE_ID`, `APPLE_TEAM_ID`, `APPLE_APP_SPECIFIC_PASSWORD` (app-specific password); check workflow for the current exact names. Never add certificate/private key/password bytes to Git.
- A version/tag plan: release tags must identify audited, tested commits. Review the release job output before sharing links.
- Rights review for artwork, sounds, names and any third-party material; see [Licensing](LICENSING.md).

## Suggested process

1. Finish code and docs on `main`, inspect CI and manually test on a real Mac.
2. Confirm certificate, secrets, signing identity and notarization access. **Do not create a `v*` release tag before these are ready**; the signed release path will fail without them.
3. Check `git status`, fetch latest and tag the approved commit: `git tag vX.Y.Z && git push origin vX.Y.Z`.
4. Inspect GitHub Actions release run, notarization result and GitHub Release assets.
5. Download the official published artifact, verify SHA-256, verify app signature/assessment on a clean Mac, and test launch and update/install.
6. Record the exact commit, checksums, signing/notarization outcome and outstanding licensing items in the release notes.

## Distribution and Fun City

Fun City publishes a signed/notarized **DMG** and checksum. The launcher downloads *individual game releases* from their canonical GitHub repositories; installing the launcher does **not** ship all games inside its DMG. The installer checks official repository download URL and package checksum; checksum integrity is not a substitute for verifying an appropriate code signature.

## Developer-account constraint

Without paid Apple Developer Program membership and configured credentials, signed/notarized automatic release is **not ready**. Continue using local Xcode builds and CI checks; do not characterize unsigned previews as ready for a general public download.
