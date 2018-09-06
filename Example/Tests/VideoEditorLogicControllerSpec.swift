//
//  VideoEditorLogicControllerSpec.swift
//  AssetPlayer_Tests
//
//  Created by Craig Holliday on 9/5/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Nimble
import Quick
import AssetPlayer

class VideoEditorLogicControllerSpec: QuickSpec {
    override func spec() {
        describe("logic controller tests") {
            describe("logic controller with mock asset player") {
                var mockAssetPlayer: MockAssetPlayer!
                var logicController: VideoEditorLogicController!
                var isSetup: Bool!
                
                var fiveSecondAsset: VideoAsset {
                    return VideoAsset(url: Bundle.main.url(forResource: "SampleVideo_1280x720_1mb", withExtension: "mp4")!)
                }
                
                var currentVCState: VideoEditorVCState!
                let stateHandler: VideoEditorLogicController.StateHandler = { state in currentVCState = state }
                
                beforeEach {
                    mockAssetPlayer = MockAssetPlayer(isPlayingLocalAsset: true, shouldLoop: true)
                    isSetup = false
                    currentVCState = .none
                    
                    waitUntil(timeout: 3.0, action: { (done) in
                        logicController = VideoEditorLogicController(assetPlayer: mockAssetPlayer, setupHandler: { (assetPlayer) in
                            isSetup = true
                            done()
                        }) { (startTime, currentTime) in
                            // Handle timeline tracking here
                        }
                        // Setup logic controller with asset
                        logicController.handle(intent: .setup(video: fiveSecondAsset), stateHandler: stateHandler)
                        expect(currentVCState).to(equal(VideoEditorVCState.paused))
                    })
                }
                
                describe("handling states for intents") {
                    it("should setup without error") {
                        expect(isSetup).to(beTrue())
                        expect(mockAssetPlayer.state).to(equal(AssetPlayerPlaybackState.none))
                    }
                    
                    it("should pause") {
                        logicController.handle(intent: .didTapPauseButton, stateHandler: stateHandler)
                        expect(currentVCState).to(equal(VideoEditorVCState.paused))
                        
                        expect(mockAssetPlayer.state).to(equal(AssetPlayerPlaybackState.paused))
                    }
                    
                    it("should play") {
                        logicController.handle(intent: .didTapPlayButton, stateHandler: stateHandler)
                        expect(currentVCState).to(equal(VideoEditorVCState.playing))
                        
                        expect(mockAssetPlayer.state).to(equal(AssetPlayerPlaybackState.playing))
                    }
                    
                    it("should play then pause") {
                        expect(currentVCState).to(equal(VideoEditorVCState.paused))
                        expect(mockAssetPlayer.state).to(equal(AssetPlayerPlaybackState.none))
                        
                        logicController.handle(intent: .didTapPlayButton, stateHandler: stateHandler)
                        expect(currentVCState).to(equal(VideoEditorVCState.playing))
                        expect(mockAssetPlayer.state).to(equal(AssetPlayerPlaybackState.playing))
                        
                        logicController.handle(intent: .didTapPauseButton, stateHandler: stateHandler)
                        expect(currentVCState).to(equal(VideoEditorVCState.paused))
                        
                        expect(mockAssetPlayer.state).to(equal(AssetPlayerPlaybackState.paused))
                    }
                    
                    it("should mute") {
                        logicController.handle(intent: .didTapMuteButton, stateHandler: stateHandler)
                        expect(currentVCState).to(equal(VideoEditorVCState.muted))
                        
                        expect(mockAssetPlayer.isMuted).to(beTrue())
                    }
                    
                    it("should unmute") {
                        logicController.handle(intent: .didTapUnmuteButton, stateHandler: stateHandler)
                        expect(currentVCState).to(equal(VideoEditorVCState.unmuted))
                        
                        expect(mockAssetPlayer.isMuted).to(beFalse())
                    }
                    
                    it("should mute then unmute") {
                        logicController.handle(intent: .didTapMuteButton, stateHandler: stateHandler)
                        expect(currentVCState).to(equal(VideoEditorVCState.muted))
                        
                        expect(mockAssetPlayer.isMuted).to(beTrue())
                        
                        logicController.handle(intent: .didTapUnmuteButton, stateHandler: stateHandler)
                        expect(currentVCState).to(equal(VideoEditorVCState.unmuted))
                        
                        expect(mockAssetPlayer.isMuted).to(beFalse())
                    }
                    
                    it("should pause when starting scroll") {
                        logicController.handle(intent: .didStartScrolling, stateHandler: stateHandler)
                        expect(currentVCState).to(equal(VideoEditorVCState.paused))
                        
                        expect(mockAssetPlayer.state).to(equal(AssetPlayerPlaybackState.paused))
                    }
                    
                    it("should pause when scrolling") {
                        let startTime = 5.0
                        let endTime = 10.0
                        logicController.handle(intent: .didScroll(to: (startTime: startTime, endTime: endTime)), stateHandler: stateHandler)
                        expect(currentVCState).to(equal(VideoEditorVCState.paused))
                        
                        expect(mockAssetPlayer.state).to(equal(AssetPlayerPlaybackState.paused))
                        expect(mockAssetPlayer.mockCurrentTime).to(equal(startTime))
                        expect(mockAssetPlayer.mockStartTimeForLoop).to(equal(startTime))
                        expect(mockAssetPlayer.mockEndTimeForLoop).to(equal(endTime))
                    }
                    
                    it("should show loading when continue pressed") {
                        logicController.handle(intent: .didTapContinueButton(videoAsset: fiveSecondAsset, cropViewFrame: .zero), stateHandler: stateHandler)
                        expect(currentVCState).to(equal(VideoEditorVCState.loading))
                        
                        expect(mockAssetPlayer.state).to(equal(AssetPlayerPlaybackState.none))
                    }
                }
            }
            
            describe("logic controller - integrated test for asset player") {
                var assetPlayer: AssetPlayer!
                var logicController: VideoEditorLogicController!
                var isSetup: Bool!
                
                var fiveSecondAsset: VideoAsset {
                    return VideoAsset(url: Bundle.main.url(forResource: "SampleVideo_1280x720_1mb", withExtension: "mp4")!)
                }
                
                var currentVCState: VideoEditorVCState!
                let stateHandler: VideoEditorLogicController.StateHandler = { state in currentVCState = state }
                
                beforeEach {
                    isSetup = false
                    currentVCState = .none
                    
                    waitUntil(timeout: 3.0, action: { (done) in
                        logicController = VideoEditorLogicController(setupHandler: { (player) in
                            assetPlayer = player
                            isSetup = true
                            done()
                        }) { (startTime, currentTime) in
                            // Handle timeline tracking here
                        }
                        // Setup logic controller with asset
                        logicController.handle(intent: .setup(video: fiveSecondAsset), stateHandler: stateHandler)
                        expect(currentVCState).to(equal(VideoEditorVCState.loading))
                    })
                }
                
                describe("handling states for intents") {
                    it("should setup without error") {
                        expect(isSetup).to(beTrue())
                        expect(assetPlayer.state).to(equal(AssetPlayerPlaybackState.none))
                    }
                    
                    it("should pause") {
                        logicController.handle(intent: .didTapPauseButton, stateHandler: stateHandler)
                        expect(currentVCState).to(equal(VideoEditorVCState.paused))
                        
                        expect(assetPlayer.state).to(equal(AssetPlayerPlaybackState.paused))
                    }
                    
                    it("should play") {
                        logicController.handle(intent: .didTapPlayButton, stateHandler: stateHandler)
                        expect(currentVCState).to(equal(VideoEditorVCState.playing))
                        
                        expect(assetPlayer.state).to(equal(AssetPlayerPlaybackState.playing))
                    }
                    
                    it("should play then pause") {
                        expect(currentVCState).to(equal(VideoEditorVCState.paused))
                        expect(assetPlayer.state).to(equal(AssetPlayerPlaybackState.none))
                        
                        logicController.handle(intent: .didTapPlayButton, stateHandler: stateHandler)
                        expect(currentVCState).to(equal(VideoEditorVCState.playing))
                        expect(assetPlayer.state).to(equal(AssetPlayerPlaybackState.playing))
                        
                        logicController.handle(intent: .didTapPauseButton, stateHandler: stateHandler)
                        expect(currentVCState).to(equal(VideoEditorVCState.paused))
                        
                        expect(assetPlayer.state).to(equal(AssetPlayerPlaybackState.paused))
                    }
                    
                    it("should mute") {
                        logicController.handle(intent: .didTapMuteButton, stateHandler: stateHandler)
                        expect(currentVCState).to(equal(VideoEditorVCState.muted))
                        
                        expect(assetPlayer.isMuted).to(beTrue())
                    }
                    
                    it("should unmute") {
                        logicController.handle(intent: .didTapUnmuteButton, stateHandler: stateHandler)
                        expect(currentVCState).to(equal(VideoEditorVCState.unmuted))
                        
                        expect(assetPlayer.isMuted).to(beFalse())
                    }
                    
                    it("should mute then unmute") {
                        logicController.handle(intent: .didTapMuteButton, stateHandler: stateHandler)
                        expect(currentVCState).to(equal(VideoEditorVCState.muted))
                        
                        expect(assetPlayer.isMuted).to(beTrue())
                        
                        logicController.handle(intent: .didTapUnmuteButton, stateHandler: stateHandler)
                        expect(currentVCState).to(equal(VideoEditorVCState.unmuted))
                        
                        expect(assetPlayer.isMuted).to(beFalse())
                    }
                    
                    it("should pause when starting scroll") {
                        logicController.handle(intent: .didStartScrolling, stateHandler: stateHandler)
                        expect(currentVCState).to(equal(VideoEditorVCState.paused))
                        
                        expect(assetPlayer.state).to(equal(AssetPlayerPlaybackState.paused))
                    }
                    
                    it("should pause when scrolling") {
                        let startTime = 2.0
                        let endTime = 6.0
                        logicController.handle(intent: .didScroll(to: (startTime: startTime, endTime: endTime)), stateHandler: stateHandler)
                        expect(currentVCState).to(equal(VideoEditorVCState.paused))
                        
                        expect(assetPlayer.state).to(equal(AssetPlayerPlaybackState.paused))
                        expect(assetPlayer.currentTime).to(equal(0))
                        expect(assetPlayer.startTimeForLoop).to(equal(startTime))
                        expect(assetPlayer.endTimeForLoop).to(equal(5.312))
                    }
                    
                    it("should show loading when continue pressed") {
                        logicController.handle(intent: .didTapContinueButton(videoAsset: fiveSecondAsset, cropViewFrame: .zero), stateHandler: stateHandler)
                        expect(currentVCState).to(equal(VideoEditorVCState.loading))
                        
                        expect(assetPlayer.state).to(equal(AssetPlayerPlaybackState.none))
                    }
                }
            }
        }
    }
}

class MockAssetPlayer: AssetPlayer {
    var mockCurrentTime: Double = 0.0
    var mockStartTimeForLoop: Double = 0.0
    var mockEndTimeForLoop: Double = 0.0
    
    override func handle(action: AssetPlayerActions) {
        switch action {
        case .setup:
            self.state = .none
            self.delegate?.playerIsSetup(self)
        case .play:
            self.state = .playing
        case .pause:
            self.state = .paused
        case .seekToTimeInSeconds(let time):
            self.mockCurrentTime = time
        case .changeStartTimeForLoop(let time):
            self.mockStartTimeForLoop = time
        case .changeEndTimeForLoop(let time):
            self.mockEndTimeForLoop = time
        case .changeIsMuted(let isMuted):
            self.player.isMuted = isMuted
        default:
            break
        }
    }
    
    deinit {}
}
