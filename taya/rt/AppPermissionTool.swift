import Foundation
import Photos
import UIKit
import UserNotifications
import AVFoundation

/// Handles runtime permission requests for camera, microphone, photo library,
/// and push notifications. Returns both the authorization state and whether
/// this is the first time the user has been prompted.
final class PermissionService {

    static let shared = PermissionService()
    private init() {}

    // MARK: - Microphone

    func checkMicrophone(completion: @escaping (_ granted: Bool, _ isInitialPrompt: Bool) -> Void) {
        let status = AVAudioSession.sharedInstance().recordPermission
        switch status {
        case .granted:
            completion(true, false)
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                completion(allowed, true)
            }
        case .denied:
            completion(false, false)
        @unknown default:
            completion(false, false)
        }
    }

    // MARK: - Photo Library

    func checkPhotoLibrary(completion: @escaping (_ granted: Bool, _ isInitialPrompt: Bool) -> Void) {
        if #available(iOS 14, *) {
            let current = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            switch current {
            case .authorized, .limited:
                completion(true, false)
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { result in
                    completion(result == .authorized || result == .limited, true)
                }
            case .restricted, .denied:
                completion(false, false)
            @unknown default:
                completion(false, false)
            }
        } else {
            let current = PHPhotoLibrary.authorizationStatus()
            switch current {
            case .authorized:
                completion(true, false)
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization { result in
                    completion(result == .authorized, true)
                }
            case .restricted, .denied, .limited:
                completion(false, false)
            @unknown default:
                completion(false, false)
            }
        }
    }

    // MARK: - Camera

    func checkCamera(completion: @escaping (_ granted: Bool, _ isInitialPrompt: Bool) -> Void) {
        let current = AVCaptureDevice.authorizationStatus(for: .video)
        switch current {
        case .authorized:
            completion(true, false)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { allowed in
                completion(allowed, true)
            }
        case .restricted, .denied:
            completion(false, false)
        @unknown default:
            completion(false, false)
        }
    }

    // MARK: - Notifications

    func checkNotifications(completion: @escaping (_ granted: Bool, _ isInitialPrompt: Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized:
                completion(true, false)
            case .notDetermined:
                completion(false, true)
            case .denied, .provisional, .ephemeral:
                completion(false, false)
            @unknown default:
                completion(false, false)
            }
        }
    }
}

// MARK: - Legacy Compatibility

/// Preserves existing call sites that reference `AppPermissionTool`.
final class AppPermissionTool {
    static let shared = AppPermissionTool()
    private let service = PermissionService.shared

    func requestMicPermission(authBlock: @escaping (_ auth: Bool, _ isFirst: Bool) -> Void) {
        service.checkMicrophone(completion: authBlock)
    }

    func requestPhotoPermission(authBlock: @escaping (_ auth: Bool, _ isFirst: Bool) -> Void) {
        service.checkPhotoLibrary(completion: authBlock)
    }

    func requestCameraPermission(authBlock: @escaping (_ auth: Bool, _ isFirst: Bool) -> Void) {
        service.checkCamera(completion: authBlock)
    }

    func requestNotificationPermission(authBlock: @escaping (_ auth: Bool, _ isFirst: Bool) -> Void) {
        service.checkNotifications(completion: authBlock)
    }
}
