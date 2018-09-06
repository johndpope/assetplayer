//
//  VideoEditorController.swift
//  AssetPlayer
//
//  Created by Craig Holliday on 8/29/18.
//

import Foundation

public class VideoEditorLogicController {
    public typealias StateHandler = (VideoEditorVCState) -> Void
    public typealias SetupHandler = (_ player: AssetPlayer) -> Void
    public typealias TrackingHandler = (_ startTime: Double, _ currentTime: Double) -> Void
    
    private let assetplayer: AssetPlayer
    private var previousStartTime: Double = 0.0
    
    public var setupHandler: SetupHandler = { _ in }
    // Handler for tracking AssetPlayer playback
    public var trackingHandler: TrackingHandler = { _,_ in }
    public var stateHandler: StateHandler = { _ in }
    
    public init(assetPlayer: AssetPlayer = AssetPlayer.defaultLocalPlayer,
                setupHandler: SetupHandler?,
                trackingHandler: TrackingHandler?) {
        assetplayer = assetPlayer
        assetplayer.delegate = self
        
        if let handler = setupHandler {
            self.setupHandler = handler
        }
        
        if let handler = trackingHandler {
            self.trackingHandler = handler
        }
    }
    
    public func handle(intent: VideoEditorVCIntentions, stateHandler: @escaping StateHandler) {
        self.stateHandler = stateHandler
        
        switch intent {
        case .setup(let video):
            self.stateHandler(.loading)
            assetplayer.handle(action: .setup(with: video))
        case .didTapPauseButton:
            self.assetplayer.handle(action: .pause)
            self.stateHandler(.paused)
        case .didTapPlayButton:
            self.assetplayer.handle(action: .play)
            self.stateHandler(.playing)
        case .didTapMuteButton:
            self.assetplayer.handle(action: .changeIsMuted(to: true))
            self.stateHandler(.muted)
        case .didTapUnmuteButton:
            self.assetplayer.handle(action: .changeIsMuted(to: false))
            self.stateHandler(.unmuted)
        case .didStartScrolling:
            self.assetplayer.handle(action: .pause)
            self.stateHandler(.paused)
        case .didScroll(let time):
            self.assetplayer.handle(action: .pause)
            let newCurrentTime = self.getNewTimeFromOffset(currentTime: assetplayer.currentTime,
                                                           newStartTime: time.startTime,
                                                           previousStartTime: previousStartTime)
            assetplayer.handle(action: .seekToTimeInSeconds(time: newCurrentTime))
            assetplayer.handle(action: .changeStartTimeForLoop(to: time.startTime))
            assetplayer.handle(action: .changeEndTimeForLoop(to: time.endTime))
            
            previousStartTime = time.startTime
            self.stateHandler(.paused)
        case .didTapContinueButton(let videoAsset, let cropViewFrame):
            // @TODO: handle continueing with flow controller
            self.stateHandler(.loading)
        }
    }
    
    private func getNewTimeFromOffset(currentTime: Double, newStartTime: Double, previousStartTime: Double) -> Double {
        let offset = newStartTime - previousStartTime
        return currentTime + offset
    }
}

extension VideoEditorLogicController: AssetPlayerDelegate {
    public func currentAssetDidChange(_ player: AssetPlayer) {}
    
    public func playerIsSetup(_ player: AssetPlayer) {
        assetplayer.handle(action: .changeStartTimeForLoop(to: 0.0))
        assetplayer.handle(action: .changeEndTimeForLoop(to: 5.0))
        
        setupHandler(player)
        stateHandler(.paused)
    }
    
    public func playerPlaybackStateDidChange(_ player: AssetPlayer) {}
    
    public func playerCurrentTimeDidChange(_ player: AssetPlayer) {}
    
    public func playerCurrentTimeDidChangeInMilliseconds(_ player: AssetPlayer) {
        self.trackingHandler(player.startTimeForLoop, player.currentTime)
    }
    
    public func playerPlaybackDidEnd(_ player: AssetPlayer) {}
    
    public func playerIsLikelyToKeepUp(_ player: AssetPlayer) {}
    
    public func playerBufferTimeDidChange(_ player: AssetPlayer) {}
}
