# Signed Vector Drift beta: Fun City install/update pilot

The prior signed Actions artifact was checked manually (SHA-256, Developer ID, Gatekeeper and stapling). **It is not a GitHub Release and Fun City's release downloader cannot fetch Actions artifacts.** This separate test channel uses an explicitly published **public prerelease** and is not a friends-and-family launch.

## Review and run controlled beta test

1. Review and merge the Vector Drift beta-release workflow PR and this Fun City beta-install PR after macOS CI passes.
2. On the current `main` branch, run the workflow WITHOUT publishing to verify signing, version metadata, notarization and packaging:

   ```bash
   gh workflow run beta-release.yml -R peter-dietrich/vector-drift --ref main \
     -f beta_version=v0.14.2-beta.1 -f publish_prerelease=false
   ```

3. When you're ready to make the test package visible to **anyone on GitHub**, explicitly approve public prerelease publication:

   ```bash
   gh workflow run beta-release.yml -R peter-dietrich/vector-drift --ref main \
     -f beta_version=v0.14.2-beta.1 -f publish_prerelease=true
   ```

   Inspect [Vector Drift Releases](https://github.com/peter-dietrich/vector-drift/releases); expect `VectorDrift-macOS.zip` and `VectorDrift-macOS.zip.sha256`.

4. On your own Mac, update Fun City and open its Xcode project. Select Vector Drift, enable **VECTOR DRIFT BETA TEST (PUBLIC PRERELEASE)** and click **BETA: CHECK / INSTALL**. The app will retrieve the latest `v0.14.2-beta.N` prerelease from the official public GitHub repository, check the digest and bundle identifier, validate the notarized Apple Developer ID and Team ID, then install to `~/Applications/Fun City Games`.

5. Click **PLAY NOW** to launch the managed copy. The launcher deliberately prefers the managed app over a linked Xcode build.
6. Repeat the same workflow with `-f beta_version=v0.14.2-beta.2 -f publish_prerelease=true` and click the beta install button again. Verify the signed newer version replaces the prior one. Saved game data and settings must be checked manually.
7. Click again with no newer release and confirm it reports already installed.

## What is and isn't verified

- All non-Drift cabinets continue to use the normal `/releases/latest` path; no automatic beta selection elsewhere.
- This beta path is explicitly opt-in, scoped to Vector Drift, and uses only tags matching `v0.14.2-beta.N`.
- The installed receipt in UserDefaults records the specific GitHub release tag; the main executable also carries `CFBundleShortVersionString=0.14.2` and `CFBundleVersion=N`.
- Higher installed semantic versions are protected from downgrades. A lower or equal beta within the same semantic version can still be manually selected if its receipt differs; do not assume automatic background updates or version ordering across beta channels.
- The install operation backs up the old app during replacement and attempts to restore it after replacement failure. It does not preserve a full rollback history.
- No silent installation and no public game release happen just by merging the code.

For public release, also implement stronger ZIP entry validation, updater regression tests, reliable ordered semantic-version comparisons, automatic update discovery, and clean-user installation tests. All beta releases in a public repository are publicly visible despite their beta label.
