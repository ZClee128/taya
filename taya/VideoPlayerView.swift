//
//  VideoPlayerView.swift
//  taya
//
//  Created by Developer on 2025/10/30.
//

import SwiftUI
import AVKit

struct VideoPlayerView: UIViewRepresentable {
    let videoName: String
    @Binding var isPlaying: Bool
    
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
            if context.coordinator.player?.rate == 0 && context.coordinator.player?.error == nil {
                context.coordinator.player?.play()
            }
        }
    }
    
    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.cleanup()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        var player: AVPlayer?
        weak var playerLayer: AVPlayerLayer?
        
        func cleanup() {
            NotificationCenter.default.removeObserver(self)
            player?.pause()
            player?.replaceCurrentItem(with: nil)
            playerLayer?.player = nil
            player = nil
        }
        
        func setup(in view: UIView, videoName: String) {
            guard let layer = view.layer as? AVPlayerLayer else { return }
            self.playerLayer = layer
            
            var videoURL: URL?
            if let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") {
                videoURL = url
            } else if let path = Bundle.main.path(forResource: videoName, ofType: "mp4") {
                videoURL = URL(fileURLWithPath: path)
            }
            
            if let url = videoURL {
                let player = AVPlayer(url: url)
                player.actionAtItemEnd = .none
                self.player = player
                
                layer.player = player
                layer.videoGravity = .resizeAspect
                
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(playerItemDidReachEnd(notification:)),
                    name: .AVPlayerItemDidPlayToEndTime,
                    object: player.currentItem
                )
                
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
            playerLayer?.player = nil
        }
        
        @objc func appWillEnterForeground() {
            playerLayer?.player = player
            player?.play()
        }
        
        deinit {
            cleanup()
        }
    }
    
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
