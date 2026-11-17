import AppKit
import CryptoKit
import Foundation

// Only official, explicitly listed Fun City games may be installed from the network.
// Every ZIP must be attached to a GitHub Release in its own canonical repository.
struct GameDistribution: Sendable {
    let repo: String
    let appName: String
    let bundleID: String

    static func forGame(_ id: String) -> GameDistribution? {
        switch id {
        case "drift":
            return .init(repo: "vector-drift", appName: "VectorDrift", bundleID: "io.vectordrift.prototype")
        case "siege":
            return .init(repo: "vector-siege", appName: "VectorSiege", bundleID: "io.vectorsiege.game")
        case "soar":
            return .init(repo: "vector-soar", appName: "VectorSoar", bundleID: "io.vectorsoar.game")
        case "barrage":
            return .init(repo: "vector-barrage", appName: "VectorBarrage", bundleID: "io.vectorbarrage.game")
        case "aces":
            return .init(repo: "vector-aces", appName: "VectorAces", bundleID: "io.vectoraces.game")
        case "swarm":
            return .init(repo: "vector-swarm", appName: "VectorSwarm", bundleID: "io.vectorswarm.game")
        case "vortex":
            return .init(repo: "vector-vortex", appName: "VectorVortex", bundleID: "io.vectorvortex.game")
        default:
            return nil
        }
    }

    static func installedURL(forBundleID id: String) -> URL? {
        guard let spec = ["drift", "siege", "swarm", "vortex", "barrage", "soar", "aces"]
            .compactMap({ forGame($0) }).first(where: { $0.bundleID == id }) else { return nil }
        let location = gamesDirectory.appendingPathComponent(spec.appName + ".app", isDirectory: true)
        guard FileManager.default.fileExists(atPath: location.path),
              Bundle(url: location)?.bundleIdentifier == id else { return nil }
        return location
    }

    static var gamesDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications", isDirectory: true)
            .appendingPathComponent("Fun City Games", isDirectory: true)
    }
}

private struct GitHubRelease: Decodable {
    let tag_name: String
    let assets: [ReleaseAsset]
    let prerelease: Bool?
    let draft: Bool?
}

private struct ReleaseAsset: Decodable {
    let name: String
    let digest: String?
    let browser_download_url: URL
    let size: Int
}

enum GameDownloadError: LocalizedError {
    case missingRelease(String)
    case unexpectedResponse
    case missingPackage
    case invalidAssetURL
    case missingChecksum
    case checksumMismatch
    case invalidBundle
    case gameRunning
    case extractionFailed
    case untrustedSigner
    case obsoleteVersion

    var errorDescription: String? {
        switch self {
        case .missingRelease(let repo):
            return "No downloadable release is published for \(repo) yet. The game developer must publish a release before it can be installed."
        case .unexpectedResponse: return "GitHub did not return a successful download response."
        case .missingPackage: return "The release has no matching macOS game ZIP."
        case .invalidAssetURL: return "The download address did not match the official game repository."
        case .missingChecksum: return "The release has no SHA-256 digest. For safety, it was not installed."
        case .checksumMismatch: return "The downloaded game's SHA-256 checksum did not match. It was discarded."
        case .invalidBundle: return "The downloaded archive did not contain the expected macOS game application."
        case .gameRunning: return "Quit the game before reinstalling or updating it."
        case .extractionFailed: return "The game archive could not be extracted."
        case .untrustedSigner: return "The game failed Apple Developer ID or Gatekeeper verification. Nothing was installed."
        case .obsoleteVersion: return "A newer game version is installed. Downgrades are blocked."
        }
    }
}

struct GameQuitPrompt {
    let id: String
    let appName: String
    let beta: Bool
}

@MainActor
final class GameReleaseInstaller: ObservableObject {
    @Published private(set) var status: [String: String] = [:]
    @Published var notice: String?
    @Published var quitPrompt: GameQuitPrompt?
    @Published private(set) var updateAvailable: [String: String] = [:]
    @Published private(set) var downloadAvailable: [String: String] = [:]
    @Published private(set) var checkingUpdates = false

    /// Queries release metadata only: never downloads binaries, quits games,
    /// or installs anything without an explicit player action.
    func refreshAvailability(betaForDrift: Bool, betaForSwarm: Bool = false) async {
        guard !checkingUpdates else { return }
        checkingUpdates = true
        defer { checkingUpdates = false }
        updateAvailable = [:]
        downloadAvailable = [:]

        for id in ["drift", "siege", "swarm", "vortex", "barrage", "soar", "aces"] {
            guard let spec = GameDistribution.forGame(id) else { continue }
            let beta = (betaForDrift && id == "drift") || (betaForSwarm && id == "swarm")
            do {
                let release = try await Self.fetchRelease(spec: spec, beta: beta)
                let filename = spec.appName + "-macOS.zip"
                guard release.assets.contains(where: { $0.name == filename }) else { continue }

                guard let local = GameDistribution.installedURL(forBundleID: spec.bundleID) else {
                    downloadAvailable[id] = release.tag_name
                    continue
                }
                let receipt = UserDefaults.standard.string(forKey: "FunCity.InstalledRelease." + id)
                if receipt == release.tag_name { continue }

                let remote = String(release.tag_name
                    .dropFirst(release.tag_name.hasPrefix("v") ? 1 : 0)
                    .split(separator: "-").first ?? "")
                let bundle = Bundle(url: local)
                let installedVersion = bundle?
                    .object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
                if let installedVersion {
                    let order = installedVersion.compare(remote, options: .numeric)
                    if order == .orderedDescending { continue }
                    if order == .orderedAscending {
                        updateAvailable[id] = release.tag_name
                        continue
                    }
                }
                if beta,
                   release.tag_name.hasPrefix(id == "drift" ? "v0.14.2-beta." : "v0.1.0-beta."),
                   let betaBuild = Int(release.tag_name.split(separator: ".").last ?? ""),
                   let installedBuild = Int(bundle?.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""),
                   betaBuild > installedBuild {
                    updateAvailable[id] = release.tag_name
                } else if receipt != nil, receipt != release.tag_name {
                    // Same marketing version can still be a new signed build.
                    updateAvailable[id] = release.tag_name
                }
            } catch {
                // No release, offline, and API rate-limit states are not proof
                // that a game is outdated. Preserve local playability.
                continue
            }
        }
    }

    func actionLabel(for id: String, hasApp: Bool, beta: Bool) -> String {
        if let state = status[id], state != "READY" { return state }
        if let tag = updateAvailable[id] { return "UPDATE TO " + tag }
        if downloadAvailable[id] != nil { return beta ? "BETA: DOWNLOAD GAME" : "DOWNLOAD GAME" }
        return hasApp ? "CHECK / UPDATE" : (beta ? "BETA: CHECK / INSTALL" : "DOWNLOAD GAME")
    }

    private static func fetchRelease(spec: GameDistribution, beta: Bool) async throws -> GitHubRelease {
        if beta {
            guard ["vector-drift", "vector-swarm"].contains(spec.repo) else {
                throw GameDownloadError.missingRelease(spec.repo + " beta")
            }
            let url = URL(string: "https://api.github.com/repos/peter-dietrich/\(spec.repo)/releases?per_page=30")!
            var request = URLRequest(url: url)
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.setValue("FunCityArcade/0.3", forHTTPHeaderField: "User-Agent")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw GameDownloadError.unexpectedResponse
            }
            let releases = try JSONDecoder().decode([GitHubRelease].self, from: data)
            guard let selected = releases.first(where: {
                $0.prerelease == true && $0.draft != true
                && $0.tag_name.hasPrefix(spec.repo == "vector-drift" ? "v0.14.2-beta." : "v0.1.0-beta.")
            }) else { throw GameDownloadError.missingRelease(spec.repo + " beta") }
            return selected
        }
        let url = URL(string: "https://api.github.com/repos/peter-dietrich/\(spec.repo)/releases/latest")!
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("FunCityArcade/0.3", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw GameDownloadError.unexpectedResponse
        }
        if http.statusCode == 404 { throw GameDownloadError.missingRelease(spec.repo) }
        guard http.statusCode == 200 else { throw GameDownloadError.unexpectedResponse }
        return try JSONDecoder().decode(GitHubRelease.self, from: data)
    }

    func quitGameAndRetryInstall() {
        guard let prompt = quitPrompt,
              let spec = GameDistribution.forGame(prompt.id) else { return }
        quitPrompt = nil
        status[prompt.id] = "QUITTING GAME"
        Task {
            // Never force-kill an app. Let macOS request a normal quit so the
            // game can flush preferences and saves. Stop if it refuses.
            let running = NSRunningApplication.runningApplications(withBundleIdentifier: spec.bundleID)
            for application in running { _ = application.terminate() }
            var closed = false
            for _ in 0..<40 {
                if NSRunningApplication.runningApplications(withBundleIdentifier: spec.bundleID).isEmpty {
                    closed = true
                    break
                }
                try? await Task.sleep(nanoseconds: 250_000_000)
            }
            status[prompt.id] = "READY"
            guard closed else {
                notice = "\(spec.appName) did not quit. Save your game, quit it using its app menu (Command-Q), then retry. Fun City will not force quit or overwrite a running game."
                return
            }
            install(prompt.id, beta: prompt.beta)
        }
    }

    func isBusy(_ id: String) -> Bool {
        guard let s = status[id] else { return false }
        return s != "READY"
    }

    /// Displays the managed installation rather than another Xcode-built copy.
    func installedReleaseLabel(_ id: String) -> String? {
        guard let spec = GameDistribution.forGame(id),
              let managed = GameDistribution.installedURL(forBundleID: spec.bundleID) else {
            return nil
        }
        if let receipt = UserDefaults.standard.string(forKey: "FunCity.InstalledRelease." + id) {
            return "FUN CITY INSTALLED: " + receipt
        }
        if let version = Bundle(url: managed)?.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            return "FUN CITY INSTALLED: v" + version
        }
        return "FUN CITY INSTALLED"
    }

    /// The beta channel is intentionally limited to our signed Vector Drift pilot.
    /// GitHub prereleases are PUBLIC; never use this for confidential binaries.
    func install(_ id: String, beta: Bool = false) {
        guard let spec = GameDistribution.forGame(id), !isBusy(id) else { return }
        let useBeta = beta && (id == "drift" || id == "swarm")
        // Query release metadata first. Do not interrupt a running game when
        // it is already the latest installed release.
        Task {
            do {
                status[id] = "CHECKING RELEASE"
                let release = try await Self.fetchRelease(spec: spec, beta: useBeta)
                let receiptKey = "FunCity.InstalledRelease." + id
                let managedApp = GameDistribution.installedURL(forBundleID: spec.bundleID)
                if let managedApp {
                    if UserDefaults.standard.string(forKey: receiptKey) == release.tag_name {
                        status[id] = "READY"
                        notice = "\(spec.appName) \(release.tag_name) is already installed."
                        return
                    }
                    if useBeta,
                       let oldTag = UserDefaults.standard.string(forKey: receiptKey),
                       oldTag.hasPrefix(id == "drift" ? "v0.14.2-beta." : "v0.1.0-beta."),
                       release.tag_name.hasPrefix(id == "drift" ? "v0.14.2-beta." : "v0.1.0-beta."),
                       let oldBuild = Int(oldTag.split(separator: ".").last ?? ""),
                       let newBuild = Int(release.tag_name.split(separator: ".").last ?? ""),
                       oldBuild > newBuild {
                        throw GameDownloadError.obsoleteVersion
                    }
                    if let localVersion = Bundle(url: managedApp)?
                        .object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
                        let remoteVersion = String(release.tag_name
                            .dropFirst(release.tag_name.hasPrefix("v") ? 1 : 0)
                            .split(separator: "-").first ?? "")
                        if localVersion.compare(remoteVersion, options: .numeric) == .orderedDescending {
                            throw GameDownloadError.obsoleteVersion
                        }
                    }
                }
                let filename = spec.appName + "-macOS.zip"
                guard let asset = release.assets.first(where: { $0.name == filename }) else {
                    throw GameDownloadError.missingPackage
                }
                guard asset.size > 0, asset.size < 600_000_000,
                      asset.browser_download_url.scheme == "https",
                      asset.browser_download_url.host == "github.com",
                      asset.browser_download_url.path.hasPrefix("/peter-dietrich/\(spec.repo)/releases/download/"),
                      asset.browser_download_url.lastPathComponent == filename else {
                    throw GameDownloadError.invalidAssetURL
                }

                // Prefer GitHub's server-calculated asset digest. Older releases can
                // provide the workflow's sibling .sha256 asset as a fallback.
                let expectedDigest: String
                if let digest = asset.digest?.lowercased(), digest.hasPrefix("sha256:"),
                   digest.dropFirst(7).count == 64 {
                    expectedDigest = String(digest.dropFirst(7))
                } else if let sidecar = release.assets.first(where: { $0.name == filename + ".sha256" }) {
                    guard sidecar.browser_download_url.scheme == "https",
                          sidecar.browser_download_url.host == "github.com",
                          sidecar.browser_download_url.path.hasPrefix("/peter-dietrich/\(spec.repo)/releases/download/"),
                          sidecar.browser_download_url.lastPathComponent == filename + ".sha256" else {
                        throw GameDownloadError.invalidAssetURL
                    }
                    let (checkData, checkResponse) = try await URLSession.shared.data(from: sidecar.browser_download_url)
                    guard (checkResponse as? HTTPURLResponse)?.statusCode == 200,
                          let text = String(data: checkData, encoding: .utf8),
                          let token = text.split(whereSeparator: \.isWhitespace).first,
                          token.count == 64,
                          token.allSatisfy({ $0.isHexDigit }) else {
                        throw GameDownloadError.missingChecksum
                    }
                    expectedDigest = String(token).lowercased()
                } else {
                    throw GameDownloadError.missingChecksum
                }

                status[id] = "DOWNLOADING"
                let (download, downloadResponse) = try await URLSession.shared.download(from: asset.browser_download_url)
                guard (downloadResponse as? HTTPURLResponse)?.statusCode == 200 else {
                    throw GameDownloadError.unexpectedResponse
                }
                // URLSession's download URL is temporary: move the file immediately
                // before any asynchronous digest or extraction work can begin.
                let archived = FileManager.default.temporaryDirectory
                    .appendingPathComponent("fun-city-download-\(UUID().uuidString).zip")
                try FileManager.default.moveItem(at: download, to: archived)
                defer { try? FileManager.default.removeItem(at: archived) }
                let size = try FileManager.default.attributesOfItem(atPath: archived.path)[.size] as? NSNumber
                guard let size, size.int64Value == Int64(asset.size) else {
                    throw GameDownloadError.checksumMismatch
                }

                status[id] = "VERIFYING"
                let actualDigest = try await Task.detached(priority: .userInitiated) {
                    let data = try Data(contentsOf: archived, options: [.mappedIfSafe])
                    return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
                }.value
                guard actualDigest == expectedDigest else { throw GameDownloadError.checksumMismatch }
                if !NSRunningApplication.runningApplications(withBundleIdentifier: spec.bundleID).isEmpty {
                    status[id] = "READY"
                    quitPrompt = GameQuitPrompt(id: id, appName: spec.appName, beta: useBeta)
                    return
                }

                status[id] = "INSTALLING"
                let installedURL = try await Self.installArchive(archived, spec: spec)
                guard Bundle(url: installedURL)?.bundleIdentifier == spec.bundleID else {
                    throw GameDownloadError.invalidBundle
                }
                UserDefaults.standard.set(release.tag_name, forKey: receiptKey)
                updateAvailable.removeValue(forKey: id)
                downloadAvailable.removeValue(forKey: id)
                status[id] = "READY"
                notice = "\(spec.appName) \(release.tag_name) is installed in ~/Applications/Fun City Games. Select PLAY NOW to launch it."
            } catch {
                status[id] = "READY"
                notice = error.localizedDescription
            }
        }
    }

    nonisolated private static func installArchive(_ zipURL: URL, spec: GameDistribution) async throws -> URL {
        try await Task.detached(priority: .userInitiated) {
            let fm = FileManager.default
            let temp = fm.temporaryDirectory.appendingPathComponent("fun-city-\(UUID().uuidString)", isDirectory: true)
            try fm.createDirectory(at: temp, withIntermediateDirectories: true)
            defer { try? fm.removeItem(at: temp) }

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
            process.arguments = ["-x", "-k", zipURL.path, temp.path]
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { throw GameDownloadError.extractionFailed }

            let apps = try fm.contentsOfDirectory(at: temp, includingPropertiesForKeys: [.isSymbolicLinkKey])
                .filter { $0.pathExtension.lowercased() == "app" }
            guard apps.count == 1,
                  apps[0].lastPathComponent == spec.appName + ".app",
                  (try apps[0].resourceValues(forKeys: [.isSymbolicLinkKey])).isSymbolicLink != true,
                  Bundle(url: apps[0])?.bundleIdentifier == spec.bundleID else {
                throw GameDownloadError.invalidBundle
            }
            // Validate official Apple Developer ID identity, intact signature,
            // and Gatekeeper acceptance BEFORE copying over an existing game.
            try Self.verifySignedApp(apps[0], expectedID: spec.bundleID)
            try fm.createDirectory(at: GameDistribution.gamesDirectory, withIntermediateDirectories: true)
            let destination = GameDistribution.gamesDirectory
                .appendingPathComponent(spec.appName + ".app", isDirectory: true)
            let staging = GameDistribution.gamesDirectory
                .appendingPathComponent(".install-\(UUID().uuidString).app", isDirectory: true)
            let backup = GameDistribution.gamesDirectory
                .appendingPathComponent(".backup-\(UUID().uuidString).app", isDirectory: true)

            try fm.copyItem(at: apps[0], to: staging)
            guard Bundle(url: staging)?.bundleIdentifier == spec.bundleID else {
                try? fm.removeItem(at: staging)
                throw GameDownloadError.invalidBundle
            }
            let replacing = fm.fileExists(atPath: destination.path)
            if replacing {
                try fm.moveItem(at: destination, to: backup)
            }
            do {
                try fm.moveItem(at: staging, to: destination)
                if replacing { try? fm.removeItem(at: backup) }
            } catch {
                if replacing, !fm.fileExists(atPath: destination.path) {
                    try? fm.moveItem(at: backup, to: destination)
                }
                try? fm.removeItem(at: staging)
                throw error
            }
            return destination
        }.value
    }
    nonisolated private static func verifySignedApp(_ url: URL, expectedID: String) throws {
        func execute(_ tool: String, _ arguments: [String]) throws -> String {
            let command = Process()
            let output = Pipe()
            command.executableURL = URL(fileURLWithPath: tool)
            command.arguments = arguments
            command.standardOutput = output
            command.standardError = output
            try command.run()
            let data = output.fileHandleForReading.readDataToEndOfFile()
            command.waitUntilExit()
            guard command.terminationStatus == 0 else {
                throw GameDownloadError.untrustedSigner
            }
            return String(decoding: data, as: UTF8.self)
        }

        _ = try execute("/usr/bin/codesign", ["--verify", "--deep", "--strict", url.path])
        let details = try execute("/usr/bin/codesign", ["--display", "--verbose=4", url.path])
        guard details.contains("TeamIdentifier=6C9RJ9VDE2"),
              details.contains("Authority=Developer ID Application: Peter Dietrich (6C9RJ9VDE2)"),
              details.contains("Identifier=" + expectedID) else {
            throw GameDownloadError.untrustedSigner
        }
        let assessment = try execute("/usr/sbin/spctl", ["--assess", "--type", "execute", "--verbose=4", url.path])
        guard assessment.contains("source=Notarized Developer ID") else {
            throw GameDownloadError.untrustedSigner
        }
    }

}
