//
//  VideoAssetSpec.swift
//  AssetPlayer
//
//  Created by Craig Holliday on 8/27/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Nimble
import Quick
import AssetPlayer
import SwifterSwift

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
