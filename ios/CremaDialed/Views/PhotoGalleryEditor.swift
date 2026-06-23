//
//  PhotoGalleryEditor.swift
//  CremaDialed
//
//  A premium multi-photo editor for café memories: capture from camera or
//  library, set a cover image, add captions, reorder and delete — styled like
//  a lightweight Apple Photos picker rather than a file attachment field.
//

import SwiftUI
import PhotosUI
import UIKit

/// A single captured photo with an optional caption.
struct GalleryPhoto: Identifiable, Equatable {
    let id = UUID()
    var data: Data
    var caption: String = ""

    static func == (lhs: GalleryPhoto, rhs: GalleryPhoto) -> Bool { lhs.id == rhs.id }
}

struct PhotoGalleryEditor: View {
    @Binding var photos: [GalleryPhoto]
    var maxPhotos: Int = 10

    @State private var showSourceDialog = false
    @State private var showCamera = false
    @State private var showLibrary = false
    @State private var showCameraDeniedAlert = false
    @State private var showLoadErrorAlert = false
    @State private var libraryItems: [PhotosPickerItem] = []
    @State private var editingCaptionFor: GalleryPhoto?

    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        VStack(spacing: 16) {
            if photos.isEmpty {
                emptyHero
            } else {
                gallery
                addMoreButton
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
        .cameraAccessAlert(isPresented: $showCameraDeniedAlert)
        .photoLoadErrorAlert(isPresented: $showLoadErrorAlert)
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { data in
                if photos.count < maxPhotos { photos.append(GalleryPhoto(data: data)) }
            }
            .ignoresSafeArea()
        }
        .sheet(item: $editingCaptionFor) { photo in
            CaptionEditor(caption: caption(for: photo)) { newCaption in
                if let idx = photos.firstIndex(of: photo) {
                    photos[idx].caption = newCaption
                }
            }
            .presentationDetents([.height(260)])
        }
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
                        photos.append(GalleryPhoto(data: data))
                    }
                    libraryItems = []
                    if failed && loaded.isEmpty { showLoadErrorAlert = true }
                }
            }
        }
    }

    private func caption(for photo: GalleryPhoto) -> String {
        photos.first(where: { $0.id == photo.id })?.caption ?? ""
    }

    // MARK: Empty hero

    private var emptyHero: some View {
        Button {
            HapticEngine.tap()
            showSourceDialog = true
        } label: {
            VStack(spacing: 12) {
                Image(systemName: "camera.aperture")
                    .font(.system(size: 40, weight: .regular))
                    .foregroundStyle(CremaColor.crema)
                Text("Capture Your Coffee")
                    .font(.crema(19, .bold))
                    .foregroundStyle(CremaColor.textPrimary)
                Text("Latte art, the cup, the room — make this a memory.")
                    .font(.crema(13, .medium))
                    .foregroundStyle(CremaColor.textSecondary)
                    .multilineTextAlignment(.center)
                HStack(spacing: 10) {
                    pill("Take Photo", "camera.fill")
                    pill("Library", "photo.on.rectangle")
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 36)
            .padding(.horizontal, 20)
            .background(
                LinearGradient(colors: [CremaColor.card, CremaColor.surface],
                               startPoint: .top, endPoint: .bottom)
            )
            .clipShape(.rect(cornerRadius: CremaRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: CremaRadius.card)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [7, 5]))
                    .foregroundStyle(CremaColor.separator)
            )
        }
        .buttonStyle(PressableStyle())
    }

    private func pill(_ title: String, _ symbol: String) -> some View {
        Label(title, systemImage: symbol)
            .font(.crema(13, .semibold))
            .foregroundStyle(CremaColor.background)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(CremaColor.espresso)
            .clipShape(Capsule())
    }

    // MARK: Gallery

    private var gallery: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                    photoTile(photo, index: index)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func photoTile(_ photo: GalleryPhoto, index: Int) -> some View {
        let isCover = index == 0
        return Color(.secondarySystemBackground)
            .frame(width: 180, height: 220)
            .overlay {
                if let image = UIImage(data: photo.data) {
                    Image(uiImage: image).resizable().aspectRatio(contentMode: .fill).allowsHitTesting(false)
                }
            }
            .overlay {
                LinearGradient(colors: [.clear, .black.opacity(0.55)], startPoint: .center, endPoint: .bottom)
                    .allowsHitTesting(false)
            }
            .clipShape(.rect(cornerRadius: 16))
            .overlay(alignment: .topLeading) {
                if isCover {
                    Label("Cover", systemImage: "star.fill")
                        .font(.crema(11, .bold))
                        .foregroundStyle(CremaColor.background)
                        .padding(.horizontal, 9).padding(.vertical, 5)
                        .background(CremaColor.crema)
                        .clipShape(Capsule())
                        .padding(8)
                }
            }
            .overlay(alignment: .topTrailing) {
                Button {
                    HapticEngine.light()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        photos.removeAll { $0.id == photo.id }
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.crema(22))
                        .foregroundStyle(.white, .black.opacity(0.45))
                        .padding(6)
                }
            }
            .overlay(alignment: .bottom) {
                HStack(spacing: 8) {
                    if !isCover {
                        tileAction("Make Cover", "star") {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                if let from = photos.firstIndex(of: photo) {
                                    photos.move(fromOffsets: IndexSet(integer: from), toOffset: 0)
                                }
                            }
                        }
                    }
                    tileAction(photo.caption.isEmpty ? "Caption" : "Edit", "text.bubble") {
                        editingCaptionFor = photo
                    }
                }
                .padding(8)
            }
            .overlay(alignment: .bottomLeading) {
                if !photo.caption.isEmpty {
                    Text(photo.caption)
                        .font(.crema(11, .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .padding(.top, 40)
                        .padding(.leading, 8)
                }
            }
    }

    private func tileAction(_ title: String, _ symbol: String, _ action: @escaping () -> Void) -> some View {
        Button {
            HapticEngine.selection()
            action()
        } label: {
            Label(title, systemImage: symbol)
                .font(.crema(11, .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 9).padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
        }
        .buttonStyle(PressableStyle())
    }

    private var addMoreButton: some View {
        Button {
            HapticEngine.tap()
            showSourceDialog = true
        } label: {
            Label("Add Photo", systemImage: "plus")
                .font(.crema(15, .semibold))
                .foregroundStyle(CremaColor.espresso)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(CremaColor.surface)
                .clipShape(.rect(cornerRadius: CremaRadius.field))
        }
        .buttonStyle(PressableStyle())
        .disabled(photos.count >= maxPhotos)
        .opacity(photos.count >= maxPhotos ? 0.5 : 1)
    }
}

/// A small sheet for editing a single photo caption.
private struct CaptionEditor: View {
    @State var caption: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("Best flat white I've had…", text: $caption, axis: .vertical)
                    .font(.crema(16, .medium))
                    .foregroundStyle(CremaColor.textPrimary)
                    .tint(CremaColor.crema)
                    .focused($focused)
                    .lineLimit(3, reservesSpace: true)
                    .padding(14)
                    .background(CremaColor.surface)
                    .clipShape(.rect(cornerRadius: CremaRadius.field))
                Spacer()
            }
            .padding(16)
            .background(CremaColor.background)
            .navigationTitle("Photo Caption")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { onSave(caption); dismiss() }.fontWeight(.semibold)
                }
            }
            .onAppear { focused = true }
        }
    }
}
