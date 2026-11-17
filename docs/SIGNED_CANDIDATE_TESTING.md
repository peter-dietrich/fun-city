# Signed game candidate validation — Fun City Arcade

These six Actions runs produce signed test packages only. They DO NOT publish releases.
Each candidate is downloaded into a temporary directory, verified, and then removed.

Run only when each GitHub Actions run reports success:

    bash scripts/verify-game-candidate.sh siege 43992253941
    bash scripts/verify-game-candidate.sh swarm 43992261373
    bash scripts/verify-game-candidate.sh vortex 43992270572
    bash scripts/verify-game-candidate.sh barrage 43992277380
    bash scripts/verify-game-candidate.sh soar 43992284266
    bash scripts/verify-game-candidate.sh aces 43992291410

The script checks the ZIP SHA-256, bundle identity, code signature, Apple team,
Gatekeeper approval and notarization ticket. Artifacts expire after seven days.

Complete manual gameplay testing on a clean macOS account before public publishing.
Test startup, controls, graphics, sound, pause/restart/quit, high scores and save
preservation where applicable. Do not publish a release merely because signing passes.

Only after approval, manually run signed-release.yml from main with
publish_release=true. This publishes a PUBLIC stable GitHub Release.
Default publish_release=false uploads a signed Actions artifact only.
