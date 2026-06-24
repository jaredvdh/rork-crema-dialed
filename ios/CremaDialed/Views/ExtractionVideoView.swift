//
//  ExtractionVideoView.swift
//  CremaDialed
//
//  A seamless, muted, looping cinematic espresso video used as the backdrop for
//  the extraction ritual. Falls back to the procedural ExtractionBackground if
//  the bundled clip is missing, so the screen always looks alive.
//

import AVFoundation
import SwiftUI

struct ExtractionVideoView: View {
    /// Whether espresso is actively flowing (plays) or paused (frozen frame).
    var isFlowing: Bool

    var body: some View {
        if let url = Self.videoURL {
            LoopingVideoPlayer(url: url, isPlaying: isFlowing)
                .ignoresSafeArea()
                .background(Color(red: 0.06, green: 0.04, blue: 0.03).ignoresSafeArea())
                .overlay { ExtractionVideoOverlay() }
        } else {
            ExtractionBackground(isFlowing: isFlowing)
        }
    }

    private static let videoURL: URL? = Bundle.main.url(forResource: "extraction", withExtension: "mp4")
}

/// A soft warm-glow + vignette layered on top of the video to keep it on-brand
/// and ensure the overlay text stays readable.
private struct ExtractionVideoOverlay: View {
    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color(red: 0.80, green: 0.55, blue: 0.27).opacity(0.10), .clear],
                center: .init(x: 0.5, y: 0.34),
                startRadius: 0,
                endRadius: 520
            )
            RadialGradient(
                colors: [.clear, .black.opacity(0.55)],
                center: .center,
                startRadius: 120,
                endRadius: 460
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

/// UIKit-backed seamless looping player. AVPlayerLooper gives a gapless loop and
/// `.resizeAspectFill` makes the clip fill the screen edge to edge.
private struct LoopingVideoPlayer: UIViewRepresentable {
    let url: URL
    let isPlaying: Bool

    func makeUIView(context: Context) -> PlayerUIView {
        PlayerUIView(url: url)
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.setPlaying(isPlaying)
    }

    static func dismantleUIView(_ uiView: PlayerUIView, coordinator: Coordinator) {
        uiView.teardown()
    }
}

final class PlayerUIView: UIView {
    private let playerLayer = AVPlayerLayer()
    private var looper: AVPlayerLooper?
    private let queuePlayer = AVQueuePlayer()
    private var shouldPlay = false
    private var isReady = false

    init(url: URL) {
        super.init(frame: .zero)
        queuePlayer.isMuted = true
        queuePlayer.actionAtItemEnd = .none
        playerLayer.player = queuePlayer
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)

        // Load the asset off the main thread so creating the player never
        // blocks the UI. The looping item is attached once the asset is ready.
        let asset = AVURLAsset(url: url)
        Task.detached(priority: .userInitiated) { [weak self] in
            // Defensively confirm the clip is actually playable before wiring up
            // the looping player. A corrupt/missing track must not crash the
            // extraction screen — the dark backdrop simply remains.
            let isPlayable = (try? await asset.load(.isPlayable)) ?? false
            guard isPlayable else { return }
            await MainActor.run {
                guard let self else { return }
                let item = AVPlayerItem(asset: asset)
                self.looper = AVPlayerLooper(player: self.queuePlayer, templateItem: item)
                self.isReady = true
                if self.shouldPlay { self.queuePlayer.play() }
            }
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }

    func setPlaying(_ playing: Bool) {
        shouldPlay = playing
        guard isReady else { return }
        if playing {
            queuePlayer.play()
        } else {
            queuePlayer.pause()
        }
    }

    func teardown() {
        shouldPlay = false
        queuePlayer.pause()
        looper = nil
        playerLayer.player = nil
    }
}
