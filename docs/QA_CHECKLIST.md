# Fun City — development and operations

**Repository:** https://github.com/peter-dietrich/fun-city  
**Role:** Arcade launcher / game release installer  
**Minimum runtime:** macOS 13+  
**Technologies:** SwiftUI and AppKit  
**Bundle ID:** io.funcity.arcade

## Automated verification

A successful GitHub Actions **macOS build** checks that the Xcode project compiles in CI. This is not a complete runtime, visual, licensing, signing or notarization audit. On a Mac, run:

```sh
xcodebuild -project FunCity.xcodeproj -scheme FunCity -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build
```

Check the **Actions** page for current build runs. Where the repository provides test scripts, run them as well. No workflow should be reported as having passed until the exact commit run says success.

## Manual release-candidate checklist

- [ ] Xcode clean build succeeds with the intended Xcode/macOS versions.
- [ ] Start/title, active game, pause/resume, game-over, restart and window resize work.
- [ ] Test **Classic and Modern** (and other available presentation modes) without rendering regressions.
- [ ] Check keyboard focus, key-repeat, smooth updates, sound on/off and multiple screen sizes.
- [ ] Test local presets, saved games, load/migration, stale save handling and score persistence where supported.
- [ ] Inspect logs for warnings, crashes, sandbox issues, excessive CPU/memory and missing files.
- [ ] Verify `LICENSE`, `THIRD_PARTY_NOTICES.md`, all graphics/audio and external dependencies are reviewed.
- [ ] Validate Developer ID signing, notarization, Gatekeeper launch and downloadable artifacts if distributing externally.
- [ ] For Fun City integration, confirm exact bundle IDs and release asset names.

## Game-specific smoke tests

Launch the lobby, inspect all five built-in cabinets, locate local .app bundles, verify external launch; check download refusal for no release/checksum mismatch/unexpected bundle and rerun on fresh accounts.

## Evidence

Record the tested commit SHA, workflow URL, macOS version, Xcode version, test result, known defects and human approver in the release notes. CI passing by itself does **not** establish legal clearance or a notarized public release.
