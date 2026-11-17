import Combine
import Foundation
import Sparkle
import SwiftUI

/// The launcher updater is independent from the seven game installers.
///
/// Development builds never attempt to replace an Xcode-built app. The
/// distributed application enables Sparkle only when the approved Ed25519
/// public key has been embedded into its Info.plist at release build time.
@MainActor
final class FunCityLauncherUpdater: ObservableObject {
    @Published private(set) var canCheckForUpdates = false

    private let controller: SPUStandardUpdaterController?
    private var availabilitySubscription: AnyCancellable?

    init() {
        #if DEBUG
        controller = nil
        #else
        let configuredKey = Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String ?? ""
        let feedURL = Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") as? String ?? ""
        guard !configuredKey.isEmpty,
              Data(base64Encoded: configuredKey)?.count == 32,
              feedURL.hasPrefix("https://github.com/peter-dietrich/fun-city/releases/latest/download/") else {
            // Unsigned preview builds have no signing key and cannot install updates.
            controller = nil
            return
        }

        let updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        controller = updaterController
        availabilitySubscription = updaterController.updater
            .publisher(for: \.canCheckForUpdates)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] canCheck in
                self?.canCheckForUpdates = canCheck
            }
        #endif
    }

    func checkForUpdates() {
        guard canCheckForUpdates else { return }
        controller?.checkForUpdates(nil)
    }
}
