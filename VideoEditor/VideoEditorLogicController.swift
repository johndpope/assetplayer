//
//  VideoEditorController.swift
//  AssetPlayer
//
//  Created by Craig Holliday on 8/29/18.
//

import Foundation

public class VideoEditorLogicController {
    typealias StateHandler = (VideoEditorVCState) -> Void
    typealias TrackingHandler = (_ startTime: Double, _ currentTime: Double) -> Void
    
    // @TODO: Do we need video editor vc here?
//    let viewController: VideoEditorViewController
    
    private let assetplayer: AssetPlayer
    private var previousStartTime: Double = 0.0
    
    // Necessary evil right now because we are unable to have a callback for setting up AssetPlayer
    private let playerView: PlayerView
//    private let timelineView: TimelineView
    
    // Handler for tracking AssetPlayer playback
    private var trackingHandler: TrackingHandler = { _,_ in }
    
    init(
        //        videoEditorViewcontroller: VideoEditorViewController,
        //         video: VideoAsset,
        playerView: PlayerView,
//        timelineView: TimelineView,
        trackingHandler: TrackingHandler?) {
        //        self.viewController = videoEditorViewcontroller
        self.playerView = playerView
        //        self.timelineView = timelineView
        
        assetplayer = AssetPlayer(isPlayingLocalAsset: true, shouldLoop: true)
        assetplayer.delegate = self
        
        if let handler = trackingHandler {
            self.trackingHandler = handler
        }
    }
    
//    public func play() {
//        self.assetplayer.execute(action: .play)
//    }
//
//    public func pause() {
//        self.assetplayer.execute(action: .pause)
//    }
//
//    public func reset() {
//        self.assetplayer.execute(action: .seekToTimeInSeconds(time: self.previousStartTime))
//    }
    
//    func setup(video: VideoAsset, stateHandler: @escaping StateHandler) {
//        assetplayer.execute(action: .setup(with: video))
//        stateHandler(.loading)
//    }
    
    func handle(intent: VideoEditorVCIntentions, stateHandler: @escaping StateHandler) {
        switch intent {
        case .setup(let video):
            assetplayer.handle(action: .setup(with: video))
            stateHandler(.loading)
        case .didTapPauseButton:
            self.assetplayer.handle(action: .pause)
            stateHandler(.paused)
        case .didTapPlayButton:
            self.assetplayer.handle(action: .play)
            stateHandler(.playing)
        case .didTapMuteButton:
            self.assetplayer.handle(action: .changeIsMuted(to: true))
            stateHandler(.muted)
        case .didTapUnmuteButton:
            self.assetplayer.handle(action: .changeIsMuted(to: false))
            stateHandler(.unmuted)
        case .didStartScrolling:
            self.assetplayer.handle(action: .pause)
            stateHandler(.paused)
        case .didScroll(let time):
            // @TODO: check if hitting handle many times causes issues
            self.assetplayer.handle(action: .pause)
            let newCurrentTime = self.getNewTimeFromOffset(currentTime: assetplayer.currentTime,
                                                           newStartTime: time.startTime,
                                                           previousStartTime: previousStartTime)
            assetplayer.handle(action: .seekToTimeInSeconds(time: newCurrentTime))
            assetplayer.handle(action: .changeStartTimeForLoop(to: time.startTime))
            assetplayer.handle(action: .changeEndTimeForLoop(to: time.endTime))
            
            previousStartTime = time.startTime
            stateHandler(.paused)
        case .didTapContinueButton:
            // @TODO: handle continueing with flow controller
            break
        }
    }
    
    private func getNewTimeFromOffset(currentTime: Double, newStartTime: Double, previousStartTime: Double) -> Double {
        let offset = newStartTime - previousStartTime
        return currentTime + offset
    }
}

extension VideoEditorLogicController: AssetPlayerDelegate {
    public func currentAssetDidChange(_ player: AssetPlayer) {
        
    }
    
    public func playerIsSetup(_ player: AssetPlayer) {
        self.playerView.player = player.player
        assetplayer.handle(action: .changeStartTimeForLoop(to: 0.0))
        assetplayer.handle(action: .changeEndTimeForLoop(to: 5.0))
    }
    
    public func playerPlaybackStateDidChange(_ player: AssetPlayer) {
        
    }
    
    public func playerCurrentTimeDidChange(_ player: AssetPlayer) {
        
    }
    
    public func playerCurrentTimeDidChangeInMilliseconds(_ player: AssetPlayer) {
        self.trackingHandler(player.startTimeForLoop, player.currentTime)
    }
    
    public func playerPlaybackDidEnd(_ player: AssetPlayer) {
        
    }
    
    public func playerIsLikelyToKeepUp(_ player: AssetPlayer) {
        
    }
    
    public func playerBufferTimeDidChange(_ player: AssetPlayer) {
        
    }
}
