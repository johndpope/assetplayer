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

    var videoPlayerView: VideoPlayerView!
    
    let imagePickerController = UIImagePickerController()

    override func viewDidLoad() {
        super.viewDidLoad()
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.delegate = self
        imagePickerController.mediaTypes = ["public.image", "public.movie"]
        
//        present(imagePickerController, animated: true, completion: nil)
//        // Do any additional setup after loading the view, typically from a nib.
//        let videoPlayerView = VideoPlayerView(frame: CGRect(x: 0, y: 0, width: 200, height: 400))
//        videoPlayerView.backgroundColor = .blue
//        let videoURL: URL = Bundle.main.url(forResource: "SampleVideo_1280x720_1mb", withExtension: "mp4")!
//        let testVideo = VideoAsset(url: videoURL)
//        videoPlayerView.setupPlayer(with: testVideo)
////        videoPlayerView.assetPlayer?.play()
//        self.videoPlayerView = videoPlayerView
//        self.view.addSubview(videoPlayerView)
//
//        let playbutton = UIButton(frame: CGRect(x:240, y:40, width: 100, height: 50))
//        playbutton.setTitle("Play", for: .normal)
//        playbutton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
//        self.view.addSubview(playbutton)
//        playbutton.backgroundColor = .green
//
//        let pausebutton = UIButton(frame: CGRect(x:240, y: 100, width: 100, height: 50))
//        pausebutton.setTitle("Pause", for: .normal)
//        pausebutton.addTarget(self, action: #selector(pauseTapped), for: .touchUpInside)
//        pausebutton.backgroundColor = .red
//
//        self.view.addSubview(pausebutton)
        
        let videoURL: URL = Bundle.main.url(forResource: "SampleVideo_1280x720_5mb", withExtension: "mp4")!
        let video = VideoAsset(url: videoURL)
//        let frameView = FrameLayerView.init(video: video, videoFrameWidth: 50, videoFrameHeight: 50)
//        frameView.frame.origin = CGPoint(x: 0, y: 50)
//        self.view.addSubview(frameView)
        let frame = CGRect(x: 0, y: 100, width: self.view.width, height: 100)
        let layerScroller = LayerScrollerView.init(frame: frame, video: video)
        layerScroller.backgroundColor = .red
        self.view.addSubview(layerScroller)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

