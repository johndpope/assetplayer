import XCTest
import AssetPlayer
import Nimble
import Quick

class ExampleSpec: QuickSpec {
    override func spec() {
        describe("basic test") {
            it("should eval true") {
                let myBool = true
                expect(myBool).to(beTrue())
            }
        }
    }
}

class AssetPlayerSpec: QuickSpec {
    override func spec() {
        describe("asset player tests") {
            
            var thirtySecondAsset: VideoAsset {
                return VideoAsset(url: Bundle.main.url(forResource: "SampleVideo_1280x720_5mb", withExtension: "mp4")!)
            }
            
            var fiveSecondAsset: VideoAsset {
                return VideoAsset(url: Bundle.main.url(forResource: "SampleVideo_1280x720_1mb", withExtension: "mp4")!)
            }
            
            var assetPlayer: AssetPlayer!
            
            describe("state changes") {
                beforeEach {
                    assetPlayer = AssetPlayer()
                    assetPlayer.perform(action: .setup(with: thirtySecondAsset))
                }
                
                afterEach {
                    assetPlayer = nil
                    expect(assetPlayer).to(beNil())
                }
                
                it("should have SETUP state") {
                    expect(assetPlayer.state).to(equal(AssetPlayerPlaybackState.setup(asset: thirtySecondAsset)))
                }
                
                it("should have PLAYED state") {
                    assetPlayer.perform(action: .play)
                    
                    expect(assetPlayer.state).to(equal(AssetPlayerPlaybackState.playing))
                }
                
                it("should have PAUSED state") {
                    assetPlayer.perform(action: .pause)
                    
                    expect(assetPlayer.state).to(equal(AssetPlayerPlaybackState.paused))
                }
            }
            
            describe("finished state test") {
                beforeEach {
                    assetPlayer = AssetPlayer()
                    assetPlayer.perform(action: .setup(with: fiveSecondAsset))
                }
                
                afterEach {
                    assetPlayer = nil
                    expect(assetPlayer).to(beNil())
                }
                
                it("should have FINISHED state") {
                    expect(assetPlayer.state).to(equal(AssetPlayerPlaybackState.setup(asset: fiveSecondAsset)))
                    assetPlayer.perform(action: .play)
                    expect(assetPlayer.state).toEventually(equal(AssetPlayerPlaybackState.finished), timeout: 8)
                }
                
                it("should continue looping after finishing") {
                    assetPlayer.shouldLoop = true
                    expect(assetPlayer.state).to(equal(AssetPlayerPlaybackState.setup(asset: fiveSecondAsset)))
                    assetPlayer.perform(action: .play)
                    expect(assetPlayer.state).toEventually(equal(AssetPlayerPlaybackState.playing), timeout: 8)
                }
            }
            
            // @TODO: Test failure states with assets with protected content or non playable assets
            describe("failed state test") {
                beforeEach {
                    assetPlayer = AssetPlayer()
                    assetPlayer.perform(action: .setup(with: fiveSecondAsset))
                }

                afterEach {
                    assetPlayer = nil
                    expect(assetPlayer).to(beNil())
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
                    assetPlayer = AssetPlayer()
                    assetPlayer.perform(action: .setup(with: fiveSecondAsset))
                    mockAssetPlayerDelegate = MockAssetPlayerDelegate(assetPlayer: assetPlayer)
                }
                
                afterEach {
                    assetPlayer = nil
                    expect(assetPlayer).to(beNil())
                }
                
                it("should fire setup delegate") {
                    expect(mockAssetPlayerDelegate.currentAsset?.urlAsset.url).toEventually(equal(fiveSecondAsset.urlAsset.url))
                }
                
                it("should fir delegate to set current time in seconds") {
                    assetPlayer.perform(action: .play)
                    expect(mockAssetPlayerDelegate.currentTimeInSeconds).toEventually(equal(1), timeout: 2)
                }
                
                it("should fire delegate to set current time in milliseconds") {
                    assetPlayer.perform(action: .play)
                    expect(mockAssetPlayerDelegate.currentTimeInMilliSeconds).toEventually(equal(0.50), timeout: 1, pollInterval: 0.01)
                }
                
                it("should fire playback ended delegate") {
                    assetPlayer.perform(action: .play)
                    expect(mockAssetPlayerDelegate.playbackEnded).toEventually(equal(true), timeout: 7)
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
    
    init(assetPlayer: AssetPlayer) {
        assetPlayer.delegate = self
    }
    
    func currentAssetDidChange(_ player: AssetPlayer) {
        self.currentAsset = player.asset as? VideoAsset
    }
    
    func playerIsSetup(_ player: AssetPlayer) {
        self.currentAsset = player.asset as? VideoAsset
    }
    
    func playerPlaybackStateDidChange(_ player: AssetPlayer) {
        
    }
    
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
    
    func playerIsLikelyToKeepUp(_ player: AssetPlayer) {}
    
    func playerBufferTimeDidChange(_ player: AssetPlayer) {}
}


class VideoAssetSpec: QuickSpec {
    override func spec() {
        describe("video asset tests") {
            let thirtySecondVideoURL = Bundle.main.url(forResource: "SampleVideo_1280x720_5mb", withExtension: "mp4")!
            var thirtySecondAsset: VideoAsset {
                return VideoAsset(url: thirtySecondVideoURL)
            }
            
            let fiveSecondVideoURL = Bundle.main.url(forResource: "SampleVideo_1280x720_1mb", withExtension: "mp4")!
            var fiveSecondAsset: VideoAsset {
                return VideoAsset(url: fiveSecondVideoURL)
            }
            
            describe("check thirtySecondAsset properties") {
                it("should match init properties") {
                    expect(thirtySecondAsset.urlAsset.url).to(equal(thirtySecondVideoURL))
                    expect(thirtySecondAsset.framerate).to(equal(25))
                    expect(thirtySecondAsset.timePoints.startTimeInSeconds).to(equal(0))
                    expect(thirtySecondAsset.timePoints.endTimeInSeconds).to(equal(29.568))
                    expect(thirtySecondAsset.duration).to(equal(29.568))
                }
            }
            
            describe("check fiveSecondAsset properties") {
                it("should match init properties") {
                    expect(fiveSecondAsset.urlAsset.url).to(equal(fiveSecondVideoURL))
                    expect(fiveSecondAsset.framerate).to(equal(25))
                    expect(fiveSecondAsset.timePoints.startTimeInSeconds).to(equal(0))
                    expect(fiveSecondAsset.timePoints.endTimeInSeconds).to(equal(5.312))
                    expect(fiveSecondAsset.duration).to(equal(5.312))
                }
            }
            
            describe("mutate video asset") {
                it("should change start time") {
                    let mutatedAsset = thirtySecondAsset.changeStartTime(to: 10)
                    expect(mutatedAsset.timePoints.startTimeInSeconds).to(equal(10))
                }
                
                it("should change end time") {
                    let mutatedAsset = thirtySecondAsset.changeEndTime(to: 20)
                    expect(mutatedAsset.timePoints.endTimeInSeconds).to(equal(20))
                }
                
                it("should change start time but not less than 0") {
                    let mutatedAsset = thirtySecondAsset.changeStartTime(to: -10)
                    expect(mutatedAsset.timePoints.startTimeInSeconds).to(equal(0))
                }
                
                it("should change start time but not greater than asset duration") {
                    let assetDuration = 29.568
                    let mutatedAsset = thirtySecondAsset.changeEndTime(to: 100)
                    expect(mutatedAsset.timePoints.endTimeInSeconds).to(equal(assetDuration))
                }
            }
            
            describe("video asset extension getters") {
                it("should get all frames for thirtySecondAsset") {
                    let images = thirtySecondAsset.getAllFramesAsUIImages()
                    expect(images?.count).to(equal(739))
                }
                
                it("should get all frames for fiveSecondAsset") {
                    let images = fiveSecondAsset.getAllFramesAsUIImages()
                    expect(images?.count).to(equal(132))
                }
            }
        }
    }
}
