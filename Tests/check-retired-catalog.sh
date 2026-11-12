#!/usr/bin/env bash
set -euo pipefail
# Guard against accidentally reintroducing a retired cabinet or download.
! grep -Fq 'ArcadeGame(id: "prism"' Sources/FunCityApp.swift
! grep -Fq 'case "prism":' Sources/GameReleaseInstaller.swift
! grep -Fq 'repo: "prism-hopper"' Sources/GameReleaseInstaller.swift
! grep -Fq 'if kind == "prism"' Sources/FunCityApp.swift
grep -Fq 'stored.filter { $0.id != "prism" && $0.bundleID != "io.prismhopper.game" }' Sources/FunCityApp.swift
grep -Fq 'bundle?.bundleIdentifier == "io.prismhopper.game"' Sources/FunCityApp.swift
echo "Active arcade catalog excludes retired game and includes legacy-library migration."
