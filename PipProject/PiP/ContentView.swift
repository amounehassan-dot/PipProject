//
//  ContentView.swift
//  PiP
//
//  Created by Amoune Hassan on 07/11/25.
//
import SwiftUI
import AVKit

// -----------------------------------------------------
// MARK: - UIView that hosts the AVPlayerLayer
// -----------------------------------------------------
final class PlayerUIView: UIView {
    let playerLayer: AVPlayerLayer
    
    init(player: AVPlayer) {
        self.playerLayer = AVPlayerLayer(player: player)
        super.init(frame: .zero)
        layer.addSublayer(playerLayer)
        playerLayer.videoGravity = .resizeAspect
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

struct PlayerContainer: UIViewRepresentable {
    let player: AVPlayer
    @Binding var pipController: AVPictureInPictureController?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView(player: player)

        // Create PiP controller
        if AVPictureInPictureController.isPictureInPictureSupported() {
            let controller = AVPictureInPictureController(playerLayer: view.playerLayer)
            controller?.delegate = context.coordinator

            DispatchQueue.main.async {
                self.pipController = controller
            }
        }

        return view
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {}

    // PiP delegate
    class Coordinator: NSObject, AVPictureInPictureControllerDelegate {
        var parent: PlayerContainer

        init(_ parent: PlayerContainer) { self.parent = parent }
    }
}

// -----------------------------------------------------
// MARK: - Main SwiftUI Video Player View
// -----------------------------------------------------
struct LocalVideoPlayerView: View {
    @State private var player: AVPlayer?
    @State private var pipController: AVPictureInPictureController?

    init() {
        configureAudioSession()

        if let path = Bundle.main.path(forResource: "PiratesVideo", ofType: "mp4") {
            let url = URL(fileURLWithPath: path)
            _player = State(initialValue: AVPlayer(url: url))
        } else {
            print("⚠️ PiratesVideo.mp4 not found in bundle")
        }
    }

    var body: some View {
        VStack {
            if let player {
                PlayerContainer(player: player, pipController: $pipController)
                    .frame(height: 280)
                    .cornerRadius(10)
                    .padding()
                    .onAppear { player.play() }
                    .onDisappear { player.pause() }

                // -----------------------------------------------------
                // PLAYBACK BUTTONS (Play / Pause / Stop)
                // -----------------------------------------------------
                HStack(spacing: 20) {
                    Button(action: { player.play() }) {
                        Label("Play", systemImage: "play.fill")
                            .padding(10)
                            .background(Color.green.opacity(0.85))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }

                    Button(action: { player.pause() }) {
                        Label("Pause", systemImage: "pause.fill")
                            .padding(10)
                            .background(Color.orange.opacity(0.85))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }

                    Button(action: {
                        player.seek(to: .zero)
                        player.pause()
                    }) {
                        Label("Stop", systemImage: "stop.fill")
                            .padding(10)
                            .background(Color.red.opacity(0.85))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding(.bottom, 10)
                // -----------------------------------------------------

                // PiP button
                Button(action: togglePiP) {
                    Label("PiP", systemImage: "pip")
                        .padding()
                        .background(Color.black.opacity(0.75))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()

            } else {
                Text("Video not found")
                    .foregroundColor(.gray)
            }
        }

        // Auto enter PiP when app goes background
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            startPiP()
        }

        // Stop PiP when app enters foreground
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            stopPiP()
        }
    }

    // MARK: - PiP functions
    private func togglePiP() {
        guard let pipController else { return }
        pipController.isPictureInPictureActive
            ? pipController.stopPictureInPicture()
            : pipController.startPictureInPicture()
    }

    private func startPiP() {
        guard let pipController, !pipController.isPictureInPictureActive else { return }
        pipController.startPictureInPicture()
    }

    private func stopPiP() {
        guard let pipController, pipController.isPictureInPictureActive else { return }
        pipController.stopPictureInPicture()
    }

    // MARK: - Audio Session
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error:", error)
        }
    }
}

// -----------------------------------------------------
// MARK: - App Entry Point
// -----------------------------------------------------
@main
struct LocalVideoApp: App {
    var body: some Scene {
        WindowGroup {
            LocalVideoPlayerView()
        }
    }
}
