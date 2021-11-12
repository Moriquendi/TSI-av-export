//
//  ViewController.swift
//  BrokenAnimation
//
//  Created by Michał Śmiałko on 20/10/2021.
//

import UIKit
import AVFoundation
import AVKit

class PlayerView: UIView {
    
    var playerLayer: AVSynchronizedLayer {
        self.layer as! AVSynchronizedLayer
    }
    
    override class var layerClass: AnyClass {
        AVSynchronizedLayer.self
    }
    
}

class CompositionLayer: CALayer {
    let videoLayer = CALayer()
    let animatedLayer = CustomLayer()
    
    override init() {
        super.init()
        addSublayer(videoLayer)
        addSublayer(animatedLayer)
        setNeedsLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSublayers() {
        videoLayer.frame = bounds
        animatedLayer.frame = bounds
    }
}

class ViewController: UIViewController {
    
    var _session: AVAssetExportSession?
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var playerView: PlayerView!
    var player: AVPlayer?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        statusLabel.text = ""
    }
    
    func prepare() -> (AVComposition, CompositionLayer) {
        let composition = AVMutableComposition()
        
        // Video track
        let videoTrack = composition.addMutableTrack(withMediaType: .video,
                                                     preferredTrackID: CMPersistentTrackID(1))!
        let _videoAssetURL = Bundle.main.url(forResource: "emptyVideo", withExtension: "mov")!
        let _emptyVideoAsset = AVURLAsset(url: _videoAssetURL)
        let _emptyVideoTrack = _emptyVideoAsset.tracks(withMediaType: .video)[0]
        try! videoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: _emptyVideoAsset.duration),
                                        of: _emptyVideoTrack, at: .zero)
        
        // Root Layer
        let size = playerView.bounds.size
        let rootLayer = CompositionLayer()
        rootLayer.frame = CGRect(origin: .zero, size: size)
        
        // Video layer
        rootLayer.videoLayer.frame = CGRect(origin: .zero, size: size)
        
        // Animated layer
        let animLayer = rootLayer.animatedLayer
        animLayer.progress = 0.0
        animLayer.frame = CGRect(origin: .zero, size: size)
        animLayer.borderColor = UIColor.green.cgColor
        animLayer.borderWidth = 0.0
        animLayer.setNeedsDisplay()
        
        // PROGRESS ANIMATION
        let progressAnim = CABasicAnimation(keyPath: "progress")
        progressAnim.fromValue = 0.0
        progressAnim.toValue = 1.0
        progressAnim.duration = 6.0
        progressAnim.beginTime = AVCoreAnimationBeginTimeAtZero
        progressAnim.isRemovedOnCompletion = false
        animLayer.add(progressAnim, forKey: nil)
        
        // BORDER ANIMATION
        let borderAnim = CABasicAnimation(keyPath: "borderWidth")
        borderAnim.fromValue = 0.0
        borderAnim.toValue = 50.0
        borderAnim.duration = 6.0
        borderAnim.beginTime = AVCoreAnimationBeginTimeAtZero
        borderAnim.isRemovedOnCompletion = false
        animLayer.add(borderAnim, forKey: nil)
        
        return (composition, rootLayer)
    }
    
    @IBAction func playCustom(_ sender: Any) {
        // Clearold
        playerView.playerLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        let (composition, compositionLayer) = prepare()
        let playerItem = AVPlayerItem(asset: composition)
        let player = AVPlayer(playerItem: playerItem)
        playerView.playerLayer.playerItem = playerItem
        playerView.playerLayer.addSublayer(compositionLayer)
        compositionLayer.frame = self.playerView.playerLayer.bounds
        
        self.player = player
        self.player?.play()
    }
    
    
    @IBAction func exportCustom(_ sender: Any) {
        print("Exporting...")
        statusLabel.text = "Exporting..."
        
        let (composition, compositionLayer) = prepare()
        compositionLayer.frame = CGRect(origin: .zero, size: composition.naturalSize)
        
        // Video Composition
        let videoComposition = AVMutableVideoComposition(propertiesOf: composition)
        videoComposition.renderSize = composition.naturalSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        
        // Animation tool
        let animTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: compositionLayer.videoLayer,
                                                           in: compositionLayer)
        
        videoComposition.animationTool  = animTool
        
        // Video instruction > Basic
        let videoInstruction = AVMutableVideoCompositionInstruction()
        videoInstruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)
        videoComposition.instructions = [videoInstruction]
        
        // Video-instruction > Layer instructions
        let videoTrack = composition.tracks(withMediaType: .video)[0]
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        videoInstruction.layerInstructions = [layerInstruction]
        
        // Session
        let exportSession = AVAssetExportSession(asset: composition,
                                                 presetName: AVAssetExportPresetHighestQuality)!
        exportSession.videoComposition = videoComposition
        exportSession.shouldOptimizeForNetworkUse = true
        var url = FileManager.default.temporaryDirectory.appendingPathComponent("\(arc4random()).mov")
        url = URL(fileURLWithPath: url.path)
        exportSession.outputURL = url
        exportSession.outputFileType = .mov
        _session = exportSession
        
        exportSession.exportAsynchronously {
            if let error = exportSession.error {
                print("Fail. \(error)")
            } else {
                print("Ok")
                print(url)
                DispatchQueue.main.async {
                    self.statusLabel.text = ""
                    
                    let vc = AVPlayerViewController()
                    vc.player = AVPlayer(url: url)
                    self.present(vc, animated: true) {
                        vc.player?.play()
                    }
                }
            }
        }
    }
    
}
