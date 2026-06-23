//
//  PhotoCaptureField.swift
//  CremaDialed
//
//  Reusable photo input that lets the user either take a new photo with the
//  camera or choose existing photos from the library. Falls back gracefully to
//  library-only when no camera is available (e.g. the simulator).
//

import SwiftUI
import PhotosUI
import UIKit

/// A UIImagePickerController wrapper for capturing a single photo from the camera.
struct CameraPicker: UIViewControllerRepresentable {
    var onCapture: (Data) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage,
               let data = ImageDownscaler.downscaledJPEG(from: image) {
                parent.onCapture(data)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

/// A multi-photo field with camera + library sources and a horizontal thumbnail strip.
struct PhotoCaptureField: View {
    @Binding var photos: [Data]
    var maxPhotos: Int = 6
    var prompt: String = "Capture the cup, the latte art, the room."

    @State private var showSourceDialog = false
    @State private var showCamera = false
    @State private var showLibrary = false
    @State private var showCameraDeniedAlert = false
    @State private var showLoadErrorAlert = false
    @State private var libraryItems: [PhotosPickerItem] = []

    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("PHOTOS")
                    .font(.crema(11, .semibold))
                    .foregroundStyle(CremaColor.textTertiary)
                Spacer()
                Button {
                    HapticEngine.tap()
                    showSourceDialog = true
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.crema(14, .semibold))
                        .foregroundStyle(CremaColor.espresso)
                }
                .disabled(photos.count >= maxPhotos)
            }

            if photos.isEmpty {
                Text(prompt)
                    .font(.crema(13, .medium))
                    .foregroundStyle(CremaColor.textSecondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(photos.enumerated()), id: \.offset) { index, data in
                            if let image = UIImage(data: data) {
                                Color(.secondarySystemBackground)
                                    .frame(width: 92, height: 92)
                                    .overlay {
                                        Image(uiImage: image).resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .allowsHitTesting(false)
                                    }
                                    .clipShape(.rect(cornerRadius: 12))
                                    .overlay(alignment: .topTrailing) {
                                        Button {
                                            HapticEngine.light()
                                            photos.remove(at: index)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.crema(18))
                                                .foregroundStyle(.white, .black.opacity(0.5))
                                                .padding(4)
                                        }
                                    }
                            }
                        }
                    }
                }
            }
        }
        .confirmationDialog("Add Photo", isPresented: $showSourceDialog, titleVisibility: .visible) {
            if cameraAvailable {
                Button("Take Photo") {
                    Task {
                        if await MediaPermissions.ensureCameraAccess() {
                            showCamera = true
                        } else {
                            showCameraDeniedAlert = true
                        }
                    }
                }
            }
            Button("Choose from Library") { showLibrary = true }
            Button("Cancel", role: .cancel) {}
        } message: {
            if !cameraAvailable {
                Text("Install the app on your device via the Rork App to take photos with the camera.")
            }
        }
        .photosPicker(isPresented: $showLibrary,
                      selection: $libraryItems,
                      maxSelectionCount: max(1, maxPhotos - photos.count),
                      matching: .images)
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { data in
                if photos.count < maxPhotos { photos.append(data) }
            }
            .ignoresSafeArea()
        }
        .cameraAccessAlert(isPresented: $showCameraDeniedAlert)
        .photoLoadErrorAlert(isPresented: $showLoadErrorAlert)
        .onChange(of: libraryItems) { _, items in
            guard !items.isEmpty else { return }
            Task {
                var loaded: [Data] = []
                var failed = false
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        loaded.append(ImageDownscaler.downscaledJPEG(from: data))
                    } else {
                        failed = true
                    }
                }
                await MainActor.run {
                    for data in loaded where photos.count < maxPhotos {
                        photos.append(data)
                    }
                    libraryItems = []
                    if failed && loaded.isEmpty { showLoadErrorAlert = true }
                }
            }
        }
    }
}

/// A single-photo capture field used for bean bags and equipment photos.
struct SinglePhotoCaptureField: View {
    @Binding var photo: Data?
    var height: CGFloat = 160
    var emptyTitle: String = "Add photo"

    @State private var showSourceDialog = false
    @State private var showCamera = false
    @State private var showLibrary = false
    @State private var showCameraDeniedAlert = false
    @State private var showLoadErrorAlert = false
    @State private var libraryItem: PhotosPickerItem?

    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        Button {
            HapticEngine.tap()
            showSourceDialog = true
        } label: {
            ZStack {
                if let photo, let image = UIImage(data: photo) {
                    Color(.secondarySystemBackground)
                        .frame(height: height)
                        .overlay {
                            Image(uiImage: image).resizable()
                                .aspectRatio(contentMode: .fill)
                                .allowsHitTesting(false)
                        }
                        .clipShape(.rect(cornerRadius: CremaRadius.card))
                } else {
                    RoundedRectangle(cornerRadius: CremaRadius.card)
                        .fill(CremaColor.surface)
                        .frame(height: height)
                        .overlay {
                            VStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .font(.crema(26))
                                Text(emptyTitle)
                                    .font(.crema(14, .medium))
                            }
                            .foregroundStyle(CremaColor.crema)
                        }
                }
            }
        }
        .buttonStyle(PressableStyle())
        .confirmationDialog("Add Photo", isPresented: $showSourceDialog, titleVisibility: .visible) {
            if cameraAvailable {
                Button("Take Photo") {
                    Task {
                        if await MediaPermissions.ensureCameraAccess() {
                            showCamera = true
                        } else {
                            showCameraDeniedAlert = true
                        }
                    }
                }
            }
            Button("Choose from Library") { showLibrary = true }
            if photo != nil {
                Button("Remove Photo", role: .destructive) { photo = nil }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if !cameraAvailable {
                Text("Install the app on your device via the Rork App to take photos with the camera.")
            }
        }
        .photosPicker(isPresented: $showLibrary, selection: $libraryItem, matching: .images)
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { data in photo = data }
                .ignoresSafeArea()
        }
        .cameraAccessAlert(isPresented: $showCameraDeniedAlert)
        .photoLoadErrorAlert(isPresented: $showLoadErrorAlert)
        .onChange(of: libraryItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    let scaled = ImageDownscaler.downscaledJPEG(from: data)
                    await MainActor.run { photo = scaled }
                } else {
                    await MainActor.run { showLoadErrorAlert = true }
                }
            }
        }
    }
}

// MARK: - Shared permission/error alerts

extension View {
    /// Alert shown when camera access is denied, with a shortcut to Settings.
    func cameraAccessAlert(isPresented: Binding<Bool>) -> some View {
        alert("Camera Access Needed", isPresented: isPresented) {
            Button("Open Settings") { MediaPermissions.openSettings() }
            Button("Not Now", role: .cancel) {}
        } message: {
            Text("Camera access is needed to take photos for your coffee journal. You can enable access in Settings.")
        }
    }

    /// Alert shown when a selected photo could not be loaded from the library.
    func photoLoadErrorAlert(isPresented: Binding<Bool>) -> some View {
        alert("Couldn't Load Photo", isPresented: isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("We couldn't open your photo library. Please try again.")
        }
    }
}
