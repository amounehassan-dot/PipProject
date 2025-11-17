Created by Amoune Hassan

Picture-in-Picture (PiP)


Picture-in-Picture, also known as PiP, is a feature that allows a video to continue playing in a small
floating window while the user uses other apps. PiP is a multitasking tool that helps people stay productive while still watching content.
This makes it possible to multitask, for example:
- Watch a video while texting
- Follow instructions while browsing the internet
- Keep a video call open while checking another app


What My Project Does

This project is an iOS app that demonstrates how PiP works on iPhone and iPad.
The app:
- Plays a video inside the app
- Allows the user to tap a button to enter Picture-in-Picture
- Lets the video continue playing even after leaving the app
- Supports play, pause, and stop controls
- Automatically enters PiP when the app goes to the background


Why PiP Is Useful

- Multitasking
- Keeps content running even when switching apps
- Great for tutorials and learning
- Works during video calls


How PiP Works 

1. The video starts inside the app.
2. When the user activates PiP, the system (iOS) turns the video into a small floating window.
3. The app is no longer responsible for the video — the system controls it.
4. The video stays on top of all apps until the user closes it or returns to the app.


What’s Inside the App

- A video player
- Play, pause, and stop buttons
- A PiP button
- An audio setup so the video continues in background
- A video file named PiratesVideo.mp4


How to Use the App

1. Open the app
2. The video will appear and begin playing
3. Tap PiP to enter Picture-in-Picture mode
4. Leave the app — the video keeps playing in a floating window
5. Tap the window to return to full screen
6. Use play/pause/stop controls anytime


import SwiftUI
import AVKit

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

    class Coordinator: NSObject, AVPictureInPictureControllerDelegate {
        var parent: PlayerContainer
        init(_ parent: PlayerContainer) { self.parent = parent }
    }
}


struct FullScreenPlayer: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.modalPresentationStyle = .fullScreen
        controller.entersFullScreenWhenPlaybackBegins = true
        controller.exitsFullScreenWhenPlaybackEnds = true
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}

struct LocalVideoPlayerView: View {
    @State private var player: AVPlayer?
    @State private var pipController: AVPictureInPictureController?
    @State private var showFullscreen = false   // <- NEW

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
                    .frame(height: 300)
                    .cornerRadius(12)
                    .padding()
                    .onAppear { player.play() }
                    .onDisappear { player.pause() }
                    
                HStack(spacing: 20) {

                    Button(action: { player.play() }) {
                        Label("Play", systemImage: "play.fill")
                            .padding(10)
                            .background(Color.green.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }

                    Button(action: { player.pause() }) {
                        Label("Pause", systemImage: "pause.fill")
                            .padding(10)
                            .background(Color.orange.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }

                    Button(action: {
                        player.seek(to: .zero)
                        player.pause()
                    }) {
                        Label("Stop", systemImage: "stop.fill")
                            .padding(10)
                            .background(Color.red.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding(.bottom, 10)

                
                Button(action: { showFullscreen = true }) {
                    Label("Full Screen", systemImage: "arrow.up.left.and.arrow.down.right")
                        .padding()
                        .background(Color.blue.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.bottom, 10)

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
        
        .fullScreenCover(isPresented: $showFullscreen) {
            if let player {
                FullScreenPlayer(player: player)
            }
        }

        // Auto PiP on background
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            startPiP()
        }

        // Stop PiP on foreground
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            stopPiP()
        }
    }

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

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error:", error)
        }
    }
}

@main
struct LocalVideoApp: App {
    var body: some Scene {
        WindowGroup {
            LocalVideoPlayerView()
        }
    }
}


![PiP PP 2-1](https://github.com/user-attachments/assets/109e72e9-d4fd-4c7d-a843-8d61f6074bd1)
![PiP PP 2-2](https://github.com/user-attachments/assets/65f12e83-cc04-4d6f-be49-57758a715adc)
![PiP PP 2-3](https://github.com/user-attachments/assets/1b14fa95-749b-4650-9167-00e5a4132074)
![PiP PP 2-4](https://github.com/user-attachments/assets/7b4813c2-ba60-4ebf-9b96-3315b57706df)
![PiP PP 2-5](https://github.com/user-attachments/assets/ba0e0df7-6153-47e9-b590-f531299784e8)
![PiP PP 2-6](https://github.com/user-attachments/assets/ffe14773-e4e6-439f-8323-1ecf51e1807e)






