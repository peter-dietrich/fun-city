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
        case "swarm":
            return .init(repo: "vector-swarm", appName: "VectorSwarm", bundleID: "io.vectorswarm.game")
        case "vortex":
            return .init(repo: "vector-vortex", appName: "VectorVortex", bundleID: "io.vectorvortex.game")
        default:
            return nil
        }
    }

    static func installedURL(forBundleID id: String) -> URL? {
        guard let spec = ["drift", "siege", "swarm", "vortex"]
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
        }
    }
}

@MainActor
final class GameReleaseInstaller: ObservableObject {
    @Published private(set) var status: [String: String] = [:]
    @Published var notice: String?

    func isBusy(_ id: String) -> Bool {
        guard let s = status[id] else { return false }
        return s != "READY"
    }

    func install(_ id: String) {
        guard let spec = GameDistribution.forGame(id), !isBusy(id) else { return }
        Task {
            do {
                status[id] = "CHECKING RELEASE"
                let releaseURL = URL(string: "https://api.github.com/repos/peter-dietrich/\(spec.repo)/releases/latest")!
                var request = URLRequest(url: releaseURL)
                request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
                request.setValue("FunCity/0.2", forHTTPHeaderField: "User-Agent")
                let (releaseData, releaseResponse) = try await URLSession.shared.data(for: request)
                guard let http = releaseResponse as? HTTPURLResponse else {
                    throw GameDownloadError.unexpectedResponse
                }
                if http.statusCode == 404 { throw GameDownloadError.missingRelease(spec.repo) }
                guard http.statusCode == 200 else { throw GameDownloadError.unexpectedResponse }
                let release = try JSONDecoder().decode(GitHubRelease.self, from: releaseData)
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
                    throw GameDownloadError.gameRunning
                }

                status[id] = "INSTALLING"
                let installedURL = try await Self.installArchive(archived, spec: spec)
                guard Bundle(url: installedURL)?.bundleIdentifier == spec.bundleID else {
                    throw GameDownloadError.invalidBundle
                }
                status[id] = "READY"
                notice = "\(spec.appName) is installed in ~/Applications/Fun City Games. Select PLAY NOW to launch it. macOS may request approval the first time you open a downloaded game."
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
}
