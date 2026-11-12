# Fun City — a personal arcade for macOS

## Maintainer documentation (2026 audit)

- [Architecture and development](docs/DEVELOPMENT.md) — code structure, local workflow, data and gameplay scope.
- [Build, tests and quality checks](docs/QA_CHECKLIST.md) — repeatable Mac checks and what CI does **not** prove.
- [Release and signing](docs/RELEASE.md) — release tags, notarization, archive output and Fun City integration.
- [Licensing and provenance](docs/LICENSING.md) — MIT terms, inspiration/trademarks, asset-origin review and redistribution boundaries.
- [Third-party notices](THIRD_PARTY_NOTICES.md) — observed libraries/resources and verification status.


**Fun City** is the home for our growing collection of native Mac arcade games, named after the arcade that started it all.

The arcade includes [Vector Drift](https://github.com/peter-dietrich/vector-drift), [Vector Siege](https://github.com/peter-dietrich/vector-siege), [Vector Vortex](https://github.com/peter-dietrich/vector-vortex), [Vector Swarm](https://github.com/peter-dietrich/vector-swarm). Each game remains in its own repository and runs as a separate macOS application. Fun City is a launcher and doesn't copy or embed the games.

## Start in Xcode

1. Clone this repository to `~/Documents/GitHub/fun-city`.
2. Open `FunCity.xcodeproj` in Xcode (16 or newer).
3. Select scheme **FunCity**, destination **My Mac**, and press **Command-R**.
4. Select **Vector Drift**, **Vector Siege**, **Vector Vortex**, **Vector Swarm**. If the cabinet reads "LINK GAME TO PLAY", click **LOCATE GAME** and select the game's built `.app` in its Xcode build products directory (normally `~/Library/Developer/Xcode/DerivedData/<game>-.../Build/Products/Debug`).

Command-line build (on macOS):

```sh
xcodebuild -project FunCity.xcodeproj -scheme FunCity -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build
```

## v0.1

- Native SwiftUI arcade lobby, neon marquee, free-play sign, vector cabinet illustrations.
- Built-in cabinets include **Vector Drift**, **Vector Siege**, **Vector Vortex**, **Vector Swarm**.
- Automatic app lookup via each game's bundle identifier when macOS knows where it is installed.
- **LOCATE GAME** for Xcode-built apps not yet registered with macOS.
- **PLAY NOW** opens the selected game in its own window while Fun City stays open.
- **ADD GAME** for any other macOS `.app`; locally saved library via UserDefaults.
- Remove imported cabinets without deleting the games themselves.
- Original graphics; no third-party game artwork, external libraries, account, or telemetry uploads.

## Arcade repository audit

See the [repository, release and licensing matrix](docs/REPOSITORY_MATRIX.md) for the five active arcade repositories, license status, asset provenance review and release-readiness gates.

## Architecture

Fun City is an independent launcher. It looks for:

| Cabinet | Repository | macOS bundle identifier |
|---|---|---|
| Vector Drift | [peter-dietrich/vector-drift](https://github.com/peter-dietrich/vector-drift) | `io.vectordrift.prototype` |
| Vector Siege | [peter-dietrich/vector-siege](https://github.com/peter-dietrich/vector-siege) | `io.vectorsiege.game` |
| Vector Vortex | [peter-dietrich/vector-vortex](https://github.com/peter-dietrich/vector-vortex) | `io.vectorvortex.game` |
| Vector Swarm | [peter-dietrich/vector-swarm](https://github.com/peter-dietrich/vector-swarm) | `io.vectorswarm.game` |

Future games can be added using **ADD GAME**, or included as built-in cabinets by extending `ArcadeGame.featured`.

The repository's main Xcode project is `FunCity.xcodeproj`; source code is in `Sources/FunCityApp.swift`. The launcher does not build or install the games. The macOS app must be built locally to verify platform compilation and runtime behavior.

## Requirements

macOS 13+, Xcode 16+; SwiftUI and AppKit. This is intended for personal, local use. Signing is disabled for command-line and CI debug builds.

## Animated neon identity

The launcher now displays the Fun City marquee logo and game-specific artwork for Vector Drift and Vector Siege in the featured cabinet and selection grid. All three reduced-size prototype JPEGs are bundled as offline app resources. Glow gently pulses, and selecting or launching a cabinet triggers a short original synthesized two-note arcade chime. Original full-resolution artwork can replace the bundled previews later. The individual games still launch independently via their existing app lookups.

## Downloadable distribution (release pipeline)

**Fun City installs from one downloadable macOS DMG**, while each game publishes its own signed, notarized `.app` inside a versioned ZIP file on its separate GitHub Releases page.

The distribution implementation provides:
- A `DOWNLOAD GAME` / `INSTALL / UPDATE` action for all four preconfigured cabinets.
- Automatic lookup of the latest published release from each official game repository.
- SHA-256 integrity verification using GitHub's release asset digest, or the accompanying `.sha256` file.
- Expected filename and bundle-identifier checks, and a user-writable `~/Applications/Fun City Games` installation destination (no administrator privilege needed).
- Launching installed games directly, while keeping the existing **LOCATE GAME** workflow for local Xcode builds.
- A GitHub Actions release workflow to build, Developer-ID-sign, notarize, staple and publish `FunCity-macOS.dmg`.

Publishing a successful signed public release requires appropriate Apple Developer ID credentials. These are deliberately not included in the repository, and the workflows refuse to publish release builds without them.

### GitHub Actions secrets (set separately on all five active repositories)

| Secret | Value |
| --- | --- |
| `APPLE_DEVELOPER_ID_CERT_BASE64` | Base64-encoded Developer ID Application `.p12` export |
| `APPLE_DEVELOPER_ID_CERT_PASSWORD` | Password of that `.p12` export |
| `APPLE_SIGNING_IDENTITY` | Exact Developer ID Application signing identity (name or SHA-1) |
| `APPLE_ID` | Apple Developer account email for notarization |
| `APPLE_TEAM_ID` | Apple Developer Team ID |
| `APPLE_APP_SPECIFIC_PASSWORD` | Apple app-specific password authorized for notarization |

Never commit private signing certificates, account passwords or personal access tokens. If using App Store Connect API-key notarization instead of Apple ID, the workflows will need to be adapted.

### Release convention

After merging and validating a project's release workflow, create a version tag such as `v0.2.0` on that project's `main` branch and push it. The release workflow creates exactly one stable download name:

- **Fun City:** `FunCity-macOS.dmg` with `FunCity-macOS.dmg.sha256`
- **Vector Drift:** `VectorDrift-macOS.zip` and sibling `.sha256`
- **Vector Siege:** `VectorSiege-macOS.zip` and sibling `.sha256`
- **Vector Swarm:** `VectorSwarm-macOS.zip` and sibling `.sha256`
- **Vector Vortex:** `VectorVortex-macOS.zip` and sibling `.sha256`

Every new release is separate and must be tested first. Release tags must point to reviewed commits on `main`; never tag unreviewed feature-branch code. Fun City expects each official download asset to follow this exact naming convention.

**Important:** SHA-256 verifies download integrity, not publisher identity by itself. Developer ID signing, notarization, and an unmodified release publishing pipeline provide additional provenance checks. A final security review should include validating the expected signing team and robust archive safety before public rollout.


## Retired arcade title

Prism Hopper was removed from the Fun City catalog and release/download integration on November 12, 2026, at the project owner's request due to intellectual-property concerns. Older local Fun City libraries are migrated to remove its entry. Fun City does not delete any previously installed app or its saved data. The separate source repository remains outside the active Fun City release program.
