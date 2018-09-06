//
//  VideoEditorViewController.swift
//  AssetPlayer
//
//  Created by Craig Holliday on 8/29/18.
//

import UIKit

struct VideoEditorViewModel {
    
}

public enum VideoEditorVCState {
    case loading
    case playing
    case paused
    case muted
    case unmuted
    case none
}

public enum VideoEditorVCIntentions {
    case setup(video: VideoAsset)
    case didTapPauseButton
    case didTapPlayButton
    case didTapMuteButton
    case didTapUnmuteButton
    case didStartScrolling
    case didScroll(to: (startTime: Double, endTime: Double))
    case didTapContinueButton(videoAsset: VideoAsset, cropViewFrame: CGRect)
}

class VideoEditorViewController: UIViewController {
    @IBOutlet weak var playerView: DraggablePlayerView!
    @IBOutlet weak var timelineView: TimelineView!
    @IBOutlet weak var canvasView: UIView!
    @IBOutlet weak var cropView: UIView!
    @IBOutlet weak var sendWithAudioLabel: UILabel!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var muteUnmuteButton: UIButton!
    @IBOutlet weak var playButtonImageView: UIImageView!
    @IBOutlet weak var muteButtonImageView: UIImageView!
    
    @IBOutlet weak var secondsTickView: SecondsTickView!
    @IBOutlet weak var secondsTickViewWidthConstraint: NSLayoutConstraint!
    
    // @TODO: fix passing in video asset
    private var videoAsset: VideoAsset! = {
        let videoURL: URL = Bundle.main.url(forResource: "SampleVideo_1280x720_5mb", withExtension: "mp4")!
//        let videoURL: URL = Bundle.main.url(forResource: "SampleVideo_2.5", withExtension: "mp4")!
        let video = VideoAsset(url: videoURL)
        return video
    }()
    private var logicController: VideoEditorLogicController!
    
    private lazy var renderHandler: VideoEditorLogicController.StateHandler = { [weak self] state in self?.render(state: state) }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.sendWithAudioLabel.text = Constants.SendWithAudioOnText
        
        self.timelineView.delegate = self
        
        self.logicController = VideoEditorLogicController(setupHandler: { (assetPlayer) in
            self.playerView.player = assetPlayer.player
            
            // Set player view frame to aspect fill canvas view
            guard let size = assetPlayer.asset?.naturalAssetSize else {
                return
            }
                        
            let scaledSize = CGSize.aspectFill(aspectRatio: size, minimumSize: self.canvasView.frame.size)
            self.playerView.frame = CGRect(origin: .zero, size: scaledSize)
            self.playerView.center = self.canvasView.center
        }, trackingHandler: { (startTime, currentTime) in
            // Handle timeline tracking here
            self.timelineView.handleTracking(startTime: startTime, currentTime: currentTime)
        })
        
        // @TODO: fix passing in video asset
        self.logicController.handle(intent: .setup(video: self.videoAsset), stateHandler: renderHandler)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.timelineView.setupTimeline(with: self.videoAsset)
        
        guard let cropViewFrame = self.timelineView.cropViewFrame else {
            return
        }
        let duration = self.videoAsset.cropDurationInSeconds
        self.secondsTickView.setupWithSeconds(seconds: duration, cropViewFrame: cropViewFrame)
        // Update width constraint because we calculate secondsTickView width in `setupWithSeconds`
        secondsTickViewWidthConstraint.constant = self.secondsTickView.frame.width
    }
    
    func render(state: VideoEditorVCState) {
        switch state {
        case .loading:
            // @TODO: Show loading hud here
            // @TODO: Hide loading hud everywhere else
            break
        case .playing:
            // Switch play/pause button to play
            self.playPauseButton.isSelected = true
            self.playButtonImageView.isHighlighted = true
        case .paused:
            // Switch play/pause button to pause
            self.playPauseButton.isSelected = false
            self.playButtonImageView.isHighlighted = false
        case .muted:
            // Switch mute button to muted
            self.muteUnmuteButton.isSelected = true
            self.muteButtonImageView.isHighlighted = true
            
            // Update send audio label
            self.sendWithAudioLabel.text = Constants.SendWithAudioOffText
        case .unmuted:
            // Switch mute button to unmuted
            self.muteUnmuteButton.isSelected = false
            self.muteButtonImageView.isHighlighted = false
            
            // Update send audio label
            self.sendWithAudioLabel.text = Constants.SendWithAudioOnText
        case .none:
            break
        }
    }
    
    @IBAction func playPauseButtonPressed(_ sender: UIButton) {
        let intent: VideoEditorVCIntentions = sender.isSelected ? .didTapPauseButton : .didTapPlayButton
        self.logicController.handle(intent: intent, stateHandler: renderHandler)
    }
    
    @IBAction func muteUnmuteButtonPressed(_ sender: UIButton) {
        let intent: VideoEditorVCIntentions = sender.isSelected ? .didTapUnmuteButton : .didTapMuteButton
        self.logicController.handle(intent: intent, stateHandler: renderHandler)
    }
    
    @IBAction func continueButtonPressed(_ sender: UIButton) {
        let assetWithUpdatedFrame = self.videoAsset.withChangingFrame(to: self.playerView.frame)
        let intent = VideoEditorVCIntentions.didTapContinueButton(videoAsset: assetWithUpdatedFrame, cropViewFrame: self.cropView.frame)
        self.logicController.handle(intent: intent, stateHandler: renderHandler)
    }
}

extension VideoEditorViewController: TimelineViewDelegate {
    public func isScrolling() {
        self.logicController.handle(intent: .didStartScrolling, stateHandler: renderHandler)
    }

    public func endScrolling() {}

    public func didChangeStartAndEndTime(to time: (startTime: Double, endTime: Double)) {
        self.logicController.handle(intent: .didScroll(to: time), stateHandler: renderHandler)
    }
}

extension VideoEditorViewController {
    private struct Constants {
        static let SendWithAudioOnText = "Send with audio on"
        static let SendWithAudioOffText = "Send with audio off"
    }
}
