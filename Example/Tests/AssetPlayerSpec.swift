//
//  AssetPlayerSpec.swift
//  AssetPlayer
//
//  Created by Craig Holliday on 8/27/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Nimble
import Quick
import AssetPlayer

class AssetPlayerSpec: QuickSpec {
    override func spec() {
        describe("asset player local asset tests") {
            var thirtySecondAsset: VideoAsset {
                return VideoAsset(url: Bundle.main.url(forResource: "SampleVideo_1280x720_5mb", withExtension: "mp4")!)
            }
            
            var fiveSecondAsset: VideoAsset {
                return VideoAsset(url: Bundle.main.url(forResource: "SampleVideo_1280x720_1mb", withExtension: "mp4")!)
            }
            
            var assetPlayer: AssetPlayer!
            
            beforeEach {
                assetPlayer = AssetPlayer(isPlayingLocalAsset: true, shouldLoop: false)
            }
            
            afterEach {
                assetPlayer = nil
                expect(assetPlayer).to(beNil())
            }
            
            describe("actionable state changes") {
                beforeEach {
                    assetPlayer.execute(action: .setup(with: thirtySecondAsset))
                }
                
                it("should have SETUP state") {
                    expect(assetPlayer.state).to(equal(AssetPlayerPlaybackState.setup(asset: thirtySecondAsset)))
                }
                
                it("should have PLAYED state") {
                    assetPlayer.execute(action: .play)
                    
                    expect(assetPlayer.state).to(equal(AssetPlayerPlaybackState.playing))
                    sleep(2)
                    expect(assetPlayer.state).toEventuallyNot(equal(AssetPlayerPlaybackState.failed(error: nil)))
                }
                
                it("should have PAUSED state") {
                    assetPlayer.execute(action: .pause)
                    
                    expect(assetPlayer.state).to(equal(AssetPlayerPlaybackState.paused))
                }
            }
            
            describe("finished state test") {
                beforeEach {
                    assetPlayer.execute(action: .setup(with: fiveSecondAsset))
                }
                
                it("should have FINISHED state") {
                    expect(assetPlayer.state).to(equal(AssetPlayerPlaybackState.setup(asset: fiveSecondAsset)))
                    assetPlayer.execute(action: .play)
                    expect(assetPlayer.state).toEventually(equal(AssetPlayerPlaybackState.finished), timeout: 8)
                }
                
                it("should continue looping after finishing") {
                    assetPlayer.execute(action: AssetPlayerActions.changeShouldLoop(to: true))
                    expect(assetPlayer.state).to(equal(AssetPlayerPlaybackState.setup(asset: fiveSecondAsset)))
                    assetPlayer.execute(action: .play)
                    expect(assetPlayer.state).toEventually(equal(AssetPlayerPlaybackState.playing), timeout: 8)
                }
            }
            
            // @TODO: Test failure states with assets with protected content or non playable assets
            describe("failed state test") {
                beforeEach {
                    assetPlayer.execute(action: .setup(with: fiveSecondAsset))
                }
                
                it("should have FAILED state") {
                    let error = NSError(domain: "TEST", code: -1, userInfo: nil)
                    assetPlayer.state = .failed(error: error as Error)
                    expect(assetPlayer.state).to(equal(AssetPlayerPlaybackState.failed(error: error)))
                }
            }
            
            describe("delegate methods") {
                var mockAssetPlayerDelegate: MockAssetPlayerDelegate!
                
                beforeEach {
                    assetPlayer.execute(action: .setup(with: fiveSecondAsset))
                    mockAssetPlayerDelegate = MockAssetPlayerDelegate(assetPlayer: assetPlayer)
                }
                
                it("should fire setup delegate") {
                    expect(mockAssetPlayerDelegate.currentAsset?.urlAsset.url).toEventually(equal(fiveSecondAsset.urlAsset.url))
                }
                
                it("should fire delegate to set current time in seconds") {
                    assetPlayer.execute(action: .play)
                    expect(mockAssetPlayerDelegate.currentTimeInSeconds).toEventually(equal(1), timeout: 2)
                }
                
                it("should fire delegate to set current time in milliseconds") {
                    assetPlayer.execute(action: .play)
                    expect(mockAssetPlayerDelegate.currentTimeInMilliSeconds).toEventually(equal(0.50), timeout: 1, pollInterval: 0.01)
                }
                
                it("should fire playback ended delegate") {
                    assetPlayer.execute(action: .play)
                    expect(mockAssetPlayerDelegate.playbackEnded).toEventually(equal(true), timeout: 7)
                }
            }
        }
        
        describe("asset player remote asset tests") {
            // Minimum time it should take to setup remote video
            let minimumSetupTime: Double = 8
            
            var thirtySecondAsset: VideoAsset {
                return VideoAsset(url: URL(string: "https://s3-us-west-2.amazonaws.com/curago-binaries/test_assets/videos/SampleVideo_1280x720_5mb.mp4")!)
            }
            
            var fiveSecondAsset: VideoAsset {
                return VideoAsset(url: URL(string: "https://s3-us-west-2.amazonaws.com/curago-binaries/test_assets/videos/SampleVideo_1280x720_1mb.mp4")!)
            }
            
            var assetPlayer: AssetPlayer!
            
            beforeEach {
                assetPlayer = AssetPlayer(isPlayingLocalAsset: false, shouldLoop: false)
            }
            
            afterEach {
                assetPlayer = nil
                expect(assetPlayer).to(beNil())
            }
            
            describe("actionable state changes") {
                beforeEach {
                    assetPlayer.execute(action: .setup(with: thirtySecondAsset))
                }
                
                it("should have SETUP state") {
                    expect(assetPlayer.state).to(equal(AssetPlayerPlaybackState.setup(asset: thirtySecondAsset)))
                }
                
                it("should have PLAYED state") {
                    assetPlayer.execute(action: .play)
                    
                    
                    expect(assetPlayer.state).to(equal(AssetPlayerPlaybackState.playing))
                    sleep(2)
                    expect(assetPlayer.state).toEventuallyNot(equal(AssetPlayerPlaybackState.failed(error: nil)))
                }
                
                it("should have PAUSED state") {
                    assetPlayer.execute(action: .pause)
                    
                    expect(assetPlayer.state).to(equal(AssetPlayerPlaybackState.paused))
                }
                
                it("should mute player & un-mute") {
                    assetPlayer.execute(action: .changeIsMuted(to: true))
                    expect(assetPlayer.isMuted).to(equal(true))
                    
                    assetPlayer.execute(action: .changeIsMuted(to: false))
                    expect(assetPlayer.isMuted).to(equal(false))
                }
            }
            
            describe("finished state test") {
                beforeEach {
                    assetPlayer.execute(action: .setup(with: fiveSecondAsset))
                }
                
                it("should have FINISHED state") {
                    expect(assetPlayer.state).to(equal(AssetPlayerPlaybackState.setup(asset: fiveSecondAsset)))
                    assetPlayer.execute(action: .play)
                    expect(assetPlayer.state).toEventually(equal(AssetPlayerPlaybackState.finished), timeout: minimumSetupTime + 20)
                }
                
                it("should continue looping after finishing") {
                    assetPlayer.execute(action: AssetPlayerActions.changeShouldLoop(to: true))
                    expect(assetPlayer.state).to(equal(AssetPlayerPlaybackState.setup(asset: fiveSecondAsset)))
                    assetPlayer.execute(action: .play)
                    expect(assetPlayer.state).toEventually(equal(AssetPlayerPlaybackState.playing), timeout: minimumSetupTime + 8)
                }
            }
            
            // @TODO: Test failure states with assets with protected content or non playable assets
            describe("failed state test") {
                beforeEach {
                    assetPlayer.execute(action: .setup(with: fiveSecondAsset))
                }
                
                it("should have FAILED state") {
                    let error = NSError(domain: "TEST", code: -1, userInfo: nil)
                    assetPlayer.state = .failed(error: error as Error)
                    expect(assetPlayer.state).to(equal(AssetPlayerPlaybackState.failed(error: error)))
                }
            }
            
            describe("delegate methods") {
                var mockAssetPlayerDelegate: MockAssetPlayerDelegate!
                
                beforeEach {
                    assetPlayer.execute(action: .setup(with: fiveSecondAsset))
                    mockAssetPlayerDelegate = MockAssetPlayerDelegate(assetPlayer: assetPlayer)
                }
                
                it("should fire setup delegate") {
                    expect(mockAssetPlayerDelegate.currentAsset?.urlAsset.url).toEventually(equal(fiveSecondAsset.urlAsset.url))
                }
                
                it("should fire delegate to set current time in seconds") {
                    assetPlayer.execute(action: .play)
                    expect(mockAssetPlayerDelegate.currentTimeInSeconds).toEventually(equal(1), timeout: minimumSetupTime + 2)
                }
                
                it("should fire delegate to set current time in milliseconds") {
                    assetPlayer.execute(action: .play)
                    expect(mockAssetPlayerDelegate.currentTimeInMilliSeconds).toEventually(equal(0.50), timeout: minimumSetupTime + 2, pollInterval: 0.01)
                }
                
                it("should fire playback ended delegate") {
                    assetPlayer.execute(action: .play)
                    expect(mockAssetPlayerDelegate.playbackEnded).toEventually(equal(true), timeout: minimumSetupTime + 20)
                }
   
                it("should fire playerIsLikelyToKeepUp delegate") {
                    assetPlayer.execute(action: .play)
                    expect(mockAssetPlayerDelegate.playerIsLikelyToKeepUp).toEventually(equal(true), timeout: minimumSetupTime)
                }
                
                it("should fire playerBufferTimeDidChange delegate") {
                    assetPlayer.execute(action: .play)
                    expect(mockAssetPlayerDelegate.bufferTime).toEventually(beGreaterThanOrEqualTo(5.0), timeout: minimumSetupTime + 5)
                }
            }
        }
    }
}

class MockAssetPlayerDelegate: AssetPlayerDelegate {
    var currentAsset: VideoAsset?
    var currentTimeInSeconds: Double = 0
    var currentTimeInMilliSeconds: Double = 0
    var timeElapsedText: String = ""
    var durationText: String = ""
    var playbackEnded = false
    var playerIsLikelyToKeepUp = false
    var bufferTime: Double = 0
    
    init(assetPlayer: AssetPlayer) {
        assetPlayer.delegate = self
    }
    
    func currentAssetDidChange(_ player: AssetPlayer) {
        self.currentAsset = player.asset as? VideoAsset
    }
    
    func playerIsSetup(_ player: AssetPlayer) {
        self.currentAsset = player.asset as? VideoAsset
    }
    
    func playerPlaybackStateDidChange(_ player: AssetPlayer) {}
    
    func playerCurrentTimeDidChange(_ player: AssetPlayer) {
        self.currentTimeInSeconds = player.currentTime.rounded()
        self.timeElapsedText = player.timeElapsedText
        self.durationText = player.durationText
    }
    
    func playerCurrentTimeDidChangeInMilliseconds(_ player: AssetPlayer) {
        self.currentTimeInMilliSeconds = round(100.0 * player.currentTime) / 100.0
        self.timeElapsedText = player.timeElapsedText
        self.durationText = player.durationText
    }
    
    func playerPlaybackDidEnd(_ player: AssetPlayer) {
        self.playbackEnded = true
    }
    
    func playerIsLikelyToKeepUp(_ player: AssetPlayer) {
        playerIsLikelyToKeepUp = true
    }
    
    func playerBufferTimeDidChange(_ player: AssetPlayer) {
        self.bufferTime = Double(player.bufferedTime)
    }
}
