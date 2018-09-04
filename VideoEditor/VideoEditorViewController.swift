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
    case didTapContinueButton
}

class VideoEditorViewController: UIViewController {
    @IBOutlet weak var playerView: PlayerView!
    @IBOutlet weak var timelineView: TimelineView!
    
    private var videoAsset: VideoAsset! = {
        let videoURL: URL = Bundle.main.url(forResource: "SampleVideo_1280x720_5mb", withExtension: "mp4")!
        let video = VideoAsset(url: videoURL)
        return video
    }()
    private var logicController: VideoEditorLogicController!
    
    private lazy var renderHandler: VideoEditorLogicController.StateHandler = { [weak self] state in self?.render(state: state) }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.timelineView.delegate = self
        self.timelineView.setupTimeline(with: self.videoAsset)
        self.logicController = VideoEditorLogicController(playerView: self.playerView, trackingHandler: { (startTime, currentTime) in
            // Handle timeline tracking here
            self.timelineView.handleTracking(startTime: startTime, currentTime: currentTime)
        })
        // @TODO: fix passing in video asset
        self.logicController.handle(intent: .setup(video: self.videoAsset), stateHandler: renderHandler)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    func render(state: VideoEditorVCState) {
        switch state {
        case .loading:
            break
        case .playing:
            // Switch play/pause button to play
            break
        case .paused:
            // Switch play/pause button to pause
            break
        case .muted:
            // Switch mute button to muted
            break
        case .unmuted:
            // Switch mute button to unmuted
            break
        case .none:
            break
        }
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
