import SwiftUI
import AVKit

/// A custom AVPlayerViewController that prevents the system from pausing the video
/// when the app enters the background by detaching the player from the view.
class BackgroundPlayerViewController: AVPlayerViewController {
    var storedPlayer: AVPlayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.showsPlaybackControls = false
        self.videoGravity = .resizeAspectFill
        
        // Listen for backgrounding to detach player
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        // Listen for foregrounding to reattach player
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func appDidEnterBackground() {
        storedPlayer = self.player
        self.player = nil // Detach so system doesn't pause it
    }
    
    @objc private func appWillEnterForeground() {
        if let p = storedPlayer {
            self.player = p
            p.play()
        }
    }
}

/// A view that plays a video in a continuous loop using AVQueuePlayer and AVPlayerLooper.
/// It also handles app lifecycle events to ensure playback continues or resumes correctly.
struct VideoPlayerView: UIViewControllerRepresentable {
    let videoName: String

    func makeUIViewController(context: Context) -> BackgroundPlayerViewController {
        let controller = BackgroundPlayerViewController()
        controller.videoGravity = .resizeAspectFill

        let url = getVideoURL(for: videoName)
        let playerItem = AVPlayerItem(url: url)
        
        // Use AVQueuePlayer and AVPlayerLooper for seamless looping
        let queuePlayer = AVQueuePlayer(playerItem: playerItem)
        let looper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        
        // Store the looper and player in the context coordinator to keep them alive
        context.coordinator.looper = looper
        context.coordinator.player = queuePlayer
        
        controller.player = queuePlayer
        queuePlayer.play()

        // Configure audio session for background playback
        // MUST NOT use .mixWithOthers if we want to hold background playback authority
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)

        return controller
    }

    func updateUIViewController(_ uiViewController: BackgroundPlayerViewController, context: Context) {
        // Ensure it stays playing
        if uiViewController.player?.timeControlStatus != .playing {
            uiViewController.player?.play()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        var looper: AVPlayerLooper?
        var player: AVQueuePlayer?
    }

    private func getVideoURL(for name: String) -> URL {
        if let path = Bundle.main.path(forResource: name, ofType: "mp4") {
            return URL(fileURLWithPath: path)
        }
        
        // Sample videos fallback
        let sampleURLs: [String: String] = [
            "sky": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
            "star": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4"
        ]
        let urlStr = sampleURLs[name] ?? "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4"
        return URL(string: urlStr)!
    }
}
