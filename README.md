# Fun City — a personal arcade for macOS

**Fun City** is the home for our growing collection of native Mac arcade games, named after the arcade that started it all.

The first two cabinets are [Vector Drift](https://github.com/peter-dietrich/vector-drift) and [Vector Siege](https://github.com/peter-dietrich/vector-siege). Each game remains in its own repository and runs as a separate macOS application. Fun City is a launcher and doesn't copy or embed the games.

## Start in Xcode

1. Clone this repository to `~/Documents/GitHub/fun-city`.
2. Open `FunCity.xcodeproj` in Xcode (16 or newer).
3. Select scheme **FunCity**, destination **My Mac**, and press **Command-R**.
4. Select **Vector Drift** or **Vector Siege**. If the cabinet reads "LINK GAME TO PLAY", click **LOCATE GAME** and select the game's built `.app` in its Xcode build products directory (normally `~/Library/Developer/Xcode/DerivedData/<game>-.../Build/Products/Debug`).

Command-line build (on macOS):

```sh
xcodebuild -project FunCity.xcodeproj -scheme FunCity -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build
```

## v0.1

- Native SwiftUI arcade lobby, neon marquee, free-play sign, vector cabinet illustrations.
- Library begins with **Vector Drift** and **Vector Siege**.
- Automatic app lookup via each game's bundle identifier when macOS knows where it is installed.
- **LOCATE GAME** for Xcode-built apps not yet registered with macOS.
- **PLAY NOW** opens the selected game in its own window while Fun City stays open.
- **ADD GAME** for any other macOS `.app`; locally saved library via UserDefaults.
- Remove imported cabinets without deleting the games themselves.
- Original graphics; no third-party game artwork, external libraries, account, or telemetry uploads.

## Architecture

Fun City is an independent launcher. It looks for:

| Cabinet | Repository | macOS bundle identifier |
|---|---|---|
| Vector Drift | [peter-dietrich/vector-drift](https://github.com/peter-dietrich/vector-drift) | `io.vectordrift.prototype` |
| Vector Siege | [peter-dietrich/vector-siege](https://github.com/peter-dietrich/vector-siege) | `io.vectorsiege.game` |

Future games can be added using **ADD GAME**, or included as built-in cabinets by extending `ArcadeGame.featured`.

The repository's main Xcode project is `FunCity.xcodeproj`; source code is in `Sources/FunCityApp.swift`. The launcher does not build or install the games. The macOS app must be built locally to verify platform compilation and runtime behavior.

## Requirements

macOS 13+, Xcode 16+; SwiftUI and AppKit. This is intended for personal, local use. Signing is disabled for command-line and CI debug builds.
