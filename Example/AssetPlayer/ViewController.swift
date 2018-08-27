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
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        imagePickerController.dismiss(animated: true, completion: nil)
        let mediaType = info[UIImagePickerControllerMediaType]
        let videoURL = info[UIImagePickerControllerReferenceURL] as? URL
        print(videoURL)
        let vid = VideoAsset(url: videoURL!).changeEndTime(to: 5.0)
        
        VideoExporter.exportThemeVideo(with: vid,
                                            cropViewFrame: CGRect(x: 0, y: 0, width: 720, height: 1280),
                                            progress:
            { (progress) in
                print(progress)
//                progressToCheck = progress
        }, success: { returnedFileUrl in
//            fileUrl = returnedFileUrl
        }, failure: { (error) in
//            expect(error).to(beNil())
//            fail()
        })
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc func playTapped() {
//        videoPlayerView.assetPlayer?.play()
    }

    @objc func pauseTapped() {
//        videoPlayerView.assetPlayer?.pause()
    }
}

