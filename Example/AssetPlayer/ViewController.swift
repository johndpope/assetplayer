//
//  ViewController.swift
//  AssetPlayer
//
//  Created by themisterholliday on 08/11/2018.
//  Copyright (c) 2018 themisterholliday. All rights reserved.
//

import UIKit
import AssetPlayer
import Photos

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var assetplayer: AssetPlayer!
    
    lazy var playButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 200, width: 100, height: 100))
        button.setTitle("Play", for: .normal)
        button.backgroundColor = .red
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(self.play), for: .touchUpInside)
        return button
    }()
    
    lazy var pauseButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 300, width: 100, height: 100))
        button.setTitle("Pause", for: .normal)
        button.backgroundColor = .blue
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(self.pause), for: .touchUpInside)
        return button
    }()
    
    lazy var resetButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 400, width: 100, height: 100))
        button.setTitle("Reset", for: .normal)
        button.backgroundColor = .purple
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(self.reset), for: .touchUpInside)
        return button
    }()
    
    var timeLineView: TimelineView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let videoURL: URL = Bundle.main.url(forResource: "SampleVideo_1280x720_5mb", withExtension: "mp4")!
        let video = VideoAsset(url: videoURL)
        
        assetplayer = AssetPlayer(isPlayingLocalAsset: true, shouldLoop: false)
        assetplayer.perform(action: .setup(with: video))
        assetplayer.delegate = self
        
        let frame = CGRect(x: 0, y: 100, width: self.view.width, height: 72)
        let timeLineView = TimelineView.init(frame: frame)
        timeLineView.setupTimeline(with: video)
        self.timeLineView = timeLineView
        self.view.addSubview(timeLineView)
        
        self.view.addSubview(playButton)
        self.view.addSubview(pauseButton)
        self.view.addSubview(resetButton)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func play() {
        self.assetplayer.perform(action: .play)
    }
    
    @objc func pause() {
        self.assetplayer.perform(action: .pause)
    }
    
    @objc func reset() {
        self.assetplayer.perform(action: .seekToTimeInSeconds(time: 0.0))
    }
}

extension ViewController: AssetPlayerDelegate {
    public func currentAssetDidChange(_ player: AssetPlayer) {
        
    }
    
    public func playerIsSetup(_ player: AssetPlayer) {
        
    }
    
    public func playerPlaybackStateDidChange(_ player: AssetPlayer) {
        
    }
    
    public func playerCurrentTimeDidChange(_ player: AssetPlayer) {
        
    }
    
    public func playerCurrentTimeDidChangeInMilliseconds(_ player: AssetPlayer) {
        self.timeLineView?.handleTracking(forTime: player.currentTime)
    }
    
    public func playerPlaybackDidEnd(_ player: AssetPlayer) {
        
    }
    
    public func playerIsLikelyToKeepUp(_ player: AssetPlayer) {
        
    }
    
    public func playerBufferTimeDidChange(_ player: AssetPlayer) {
        
    }
}
