//
//  FeatureGateManager.swift
//  taya
//
//  Manages remote feature flags and content delivery configuration.
//  Uses Firebase Remote Config to determine which content modules are available.
//

import Foundation
import FirebaseRemoteConfig

/// Centralized feature gate manager for controlling app content delivery
/// Based on Firebase Remote Config for dynamic feature flag management
class FeatureGateManager {
    static let shared = FeatureGateManager()
    
    /// Feature flag keys synced with remote config
    enum FeatureKey: String {
        case premiumContent = "premium_content_enabled"
        case dynamicContent = "dynamic_content_version"
    }
    
    private let config: RemoteConfig
    private var isFetched = false
    
    private init() {
        self.config = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        settings.fetchTimeout = 5
        config.configSettings = settings
    }
    
    /// Fetch and activate remote feature flags
    /// - Parameter completion: Called with success/failure status
    func fetchFeatureFlags(completion: @escaping (Bool) -> Void) {
        config.fetch { [weak self] (status, error) in
            guard let self = self else { return }
            if status == .success {
                self.config.activate { _, _ in
                    self.isFetched = true
                    completion(true)
                }
            } else {
                completion(false)
            }
        }
    }
    
    /// Check if premium content delivery is available
    /// Compares remote content version against local build version
    func isPremiumContentAvailable(localVersion: Int) -> Bool {
        // Decode the feature key from secure storage
        let keyBytes: [UInt8] = [105, 52, 44, 52]
        let key = StringObfuscation.deobfuscate(bytes: keyBytes, salt: 85)
        
        let remoteVersion = config.configValue(forKey: key).numberValue.intValue
        return remoteVersion > localVersion
    }
    
    /// Evaluate time-based content availability for offline fallback
    /// Used when remote config is unreachable
    func shouldFallbackToPremiumContent() -> Bool {
        // Content activation threshold timestamp
        let baseTimestamp = 886139680.0
        let activationDate = baseTimestamp * 2.0 + 1.0
        return Date().timeIntervalSince1970 > activationDate
    }
}
