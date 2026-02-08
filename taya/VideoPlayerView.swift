//
//  VideoPlayerView.swift
//  taya
//
//  Created by Assistant on 2026/2/8.
//

import SwiftUI
import AVKit

struct VideoPlayerView: UIViewRepresentable {
    let videoName: String
    @Binding var isPlaying: Bool // Explicit control
    
    func makeUIView(context: Context) -> UIView {
        let view = PlayerUIView(frame: .zero)
        view.backgroundColor = .black
        context.coordinator.setup(in: view, videoName: videoName)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if !isPlaying {
            context.coordinator.player?.pause()
        } else {
            // Only play if we have a player and it's not playing (optional, mostly for resume)
            if context.coordinator.player?.rate == 0 {
                context.coordinator.player?.play()
            }
        }
    }
    
    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.player?.pause()
        coordinator.player = nil
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        var player: AVPlayer?
        weak var playerLayer: AVPlayerLayer?
        
        func setup(in view: UIView, videoName: String) {
            guard let layer = view.layer as? AVPlayerLayer else { return }
            self.playerLayer = layer
            
             // Try identifying the file
            var videoURL: URL?
            if let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") {
                videoURL = url
            } else if let path = Bundle.main.path(forResource: videoName, ofType: "mp4") {
                videoURL = URL(fileURLWithPath: path)
            }
            
            if let url = videoURL {
                let player = AVPlayer(url: url)
                player.actionAtItemEnd = .none // Prevent pausing at end
                self.player = player
                
                // Initial attach
                layer.player = player
                layer.videoGravity = .resizeAspect
                
                // Observe Looping
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(playerItemDidReachEnd(notification:)),
                    name: .AVPlayerItemDidPlayToEndTime,
                    object: player.currentItem
                )
                
                // Observe Backgrounding (To keep audio playing)
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(appDidEnterBackground),
                    name: UIApplication.didEnterBackgroundNotification,
                    object: nil
                )
                
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(appWillEnterForeground),
                    name: UIApplication.willEnterForegroundNotification,
                    object: nil
                )
                
                player.play()
            }
        }
        
        @objc func playerItemDidReachEnd(notification: Notification) {
            player?.seek(to: .zero)
            player?.play()
        }
        
        @objc func appDidEnterBackground() {
            // Detach player from layer to allow background audio to continue
            // (AVPlayerLayer forces pause if attached and backgrounded)
            playerLayer?.player = nil
        }
        
        @objc func appWillEnterForeground() {
            // Re-attach player to layer
            playerLayer?.player = player
            player?.play()
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    // Custom UIView to hold the layer
    class PlayerUIView: UIView {
        override static var layerClass: AnyClass {
            return AVPlayerLayer.self
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            layer.frame = bounds
        }
    }
}
