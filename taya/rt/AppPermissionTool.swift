//
//  AppPermissionTool.swift
//  taya
//
//  Created by young on 2025/9/23.
//

import Foundation
import Photos
import UIKit

class AppPermissionTool {
    static let shared = AppPermissionTool()

    /// Request microphone permission
    func requestMicPermission(authBlock: @escaping (_ auth: Bool, _ isFirst: Bool) -> Void) {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            authBlock(true, false)
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { auth in
                authBlock(auth, true)
            }
        case .denied:
            authBlock(false, false)
        default:
            authBlock(false, false)
        }
    }

    /// Request photo library permission
    func requestPhotoPermission(authBlock: @escaping (_ auth: Bool, _ isFirst: Bool) -> Void) {
        if #available(iOS 14, *) {
            switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
            case .authorized:
                authBlock(true, false)
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                    if status == .authorized || status == .limited {
                        authBlock(true, true)
                    } else {
                        authBlock(false, true)
                    }
                }
            case .restricted:
                authBlock(false, false)
            case .denied:
                authBlock(false, false)
            case .limited:
                authBlock(true, false)
            default:
                authBlock(false, false)
            }
        } else {
            switch PHPhotoLibrary.authorizationStatus() {
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization { status in
                    if status == .authorized {
                        authBlock(true, false)
                    } else {
                        authBlock(false, false)
                    }
                }
            case .restricted:
                authBlock(false, false)
            case .denied:
                authBlock(false, false)
            case .authorized:
                authBlock(true, false)
            case .limited:
                authBlock(false, false)
            @unknown default:
                authBlock(false, false)
            }
        }
    }

    /// Request camera permission
    func requestCameraPermission(authBlock: @escaping (_ auth: Bool, _ isFirst: Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            authBlock(true, false)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { auth in
                authBlock(auth, true)
            }
        case .restricted:
            authBlock(false, false)
        case .denied:
            authBlock(false, false)
        default:
            authBlock(false, false)
        }
    }
    
    /// Request notification permission
    func requestNotificationPermission(authBlock: @escaping (_ auth: Bool, _ isFirst: Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { (setttings) in
            switch setttings.authorizationStatus {
            case .authorized:
                authBlock(true, false)
            case .denied:
                authBlock(false, false)
            case .notDetermined:
                authBlock(false, true)
            case .provisional:
                authBlock(false, false)
            case .ephemeral:
                authBlock(false, false)
            @unknown default:
                authBlock(false, false)
            }
        }
    }
}
