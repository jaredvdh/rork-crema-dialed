//
//  MediaPermissions.swift
//  CremaDialed
//
//  Centralised camera permission handling for the photo capture flows.
//  The photo library is accessed through SwiftUI's PhotosPicker, which runs
//  out-of-process and needs no library permission, so this helper focuses on
//  the camera (which does require an explicit authorization grant).
//

import AVFoundation
import UIKit

enum MediaPermissions {
    /// Requests camera access if needed and returns whether it is authorized.
    /// Safe to call from the main actor; resolves on the main actor.
    @MainActor
    static func ensureCameraAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    /// Opens the system Settings app for this app, where permissions can be changed.
    @MainActor
    static func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
