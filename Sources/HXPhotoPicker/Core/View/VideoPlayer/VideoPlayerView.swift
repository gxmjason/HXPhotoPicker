//
//  VideoPlayerView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/1/9.
//

import UIKit
import AVFoundation

open 
class VideoPlayerView: UIView {
    
    open override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    var player: AVPlayer!
    
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    var avAsset: AVAsset?
    
    init() {
        player = AVPlayer()
        super.init(frame: .zero)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
