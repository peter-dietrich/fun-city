# Fun City arcade — repository, release and licensing matrix

_Audit date: November 9, 2026 (America/Denver). Covers **the Fun City arcade family only**, not unrelated repositories such as Naveryn or Homebridge._

| Project | Repository | Runtime | Bundle identifier | Role | License |
|---|---|---|---|---|---|
| Fun City | [fun-city](https://github.com/peter-dietrich/fun-city) | macOS 13+ | `io.funcity.arcade` | Launcher / downloader | MIT |
| Vector Drift | [vector-drift](https://github.com/peter-dietrich/vector-drift) | macOS 13+ | `io.vectordrift.prototype` | Space shooter | MIT |
| Vector Siege | [vector-siege](https://github.com/peter-dietrich/vector-siege) | macOS 13+ | `io.vectorsiege.game` | First-person tank shooter | MIT |
| Vector Swarm | [vector-swarm](https://github.com/peter-dietrich/vector-swarm) | macOS 13+ | `io.vectorswarm.game` | Formation shooter | MIT (added in this audit) |
| Vector Vortex | [vector-vortex](https://github.com/peter-dietrich/vector-vortex) | macOS 14+ | `io.vectorvortex.game` | Tube shooter | MIT |

## Confirmed source-tree documentation

The five active repositories each contain `LICENSE`, `README.md`, `THIRD_PARTY_NOTICES.md`, and four maintainer documents: `docs/DEVELOPMENT.md`, `docs/QA_CHECKLIST.md`, `docs/RELEASE.md`, and `docs/LICENSING.md`. The CI build status of a commit needs to be checked separately from documentation completeness.

## Distribution contracts

- **Fun City:** standalone, signed/notarized `FunCity-macOS.dmg` plus `.sha256` on its own GitHub Release. It does **not** bundle games. It uses the official game repositories to find signed release ZIPs and installs compatible app bundles under the user's application folder.
- **Each game:** `<AppName>-macOS.zip` plus `.sha256` attached to that game's **own** tagged GitHub Release. See each game's `docs/RELEASE.md` for exact app name and signing requirements.
- **Version tags:** the workflows reserve `v*` tags for the signed release path. Avoid creating tags until Developer ID certificate, paid Developer Program membership, notarization credentials and manual tests are ready.
- **Trust:** checksum verification protects download integrity; it does not independently prove publisher identity. Independently test the release app's code signature and notarization status. A CI build is not a notarized distributable.

## License and intellectual-property review

- **Repository license text:** MIT is present in the active repositories, including newly added Vector Swarm. The text alone does not certify that every resource or line of code is owned by the licensor.
- **Dependencies:** no third-party Swift package manifests or vendored third-party libraries were found in the inspected source trees. Apple frameworks and system resources are subject to Apple terms.
- **Resources requiring provenance records:** Vector Siege's six WAV sound effects; any outside or AI-generated artwork subsequently used in marketing or release bundles. For each, retain the creator, source, license/permission evidence and redistribution scope.
- **Historical arcade inspiration:** these are original genre-inspired games; inspect game marks, art style, audio, recognizable likenesses and packaging for potential trademark and copyrighted-expression conflicts before commercial distribution. Use no unlicensed third-party original game art, logos or recorded music.
- **Legal outcome:** **technical license-file consistency verified**, but creator ownership, media provenance, trademark non-infringement and commercial release clearance **not legally certified**.

## Release gates

- [ ] All five active repository commits pass their macOS build checks.
- [ ] Each game is interactively tested on a supported Mac; save/resume, controls, audio and game-specific mechanics checked.
- [ ] Fun City's downloader is exercised against official releases, invalid packages, mismatched checksums and missing releases.
- [ ] Asset provenance and software copyright ownership are confirmed and recorded.
- [ ] Valid Apple Developer ID signing and notarization credentials are configured.
- [ ] A clean Mac verifies final downloaded archives, checksums, signatures, notarization and first launch.
- [ ] Only then publish `v*` tags and advertise public download support.

This matrix is an audit record, not a substitute for legal review or completed end-to-end testing.

## Removed from active distribution (November 12, 2026)

Prism Hopper (formerly `peter-dietrich/prism-hopper`, bundle ID `io.prismhopper.game`) is **retired** and excluded from Fun City's application catalog, update/download registry, release plan and built-in artwork because of intellectual-property concerns. Its separate public source repository has not been deleted, but it is not part of the active arcade lineup; no GitHub Releases were found in that repository at the time of removal.
