//
//  MeasurementTests.swift
//  AssetPlayer_Tests
//
//  Created by Craig Holliday on 8/29/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
import AssetPlayer

class MeasurementTests: XCTestCase {
    let thirtySecondVideoURL = Bundle.main.url(forResource: "SampleVideo_1280x720_5mb", withExtension: "mp4")!
    var thirtySecondAsset: VideoAsset {
        return VideoAsset(url: thirtySecondVideoURL)
    }
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testGetOneFramePerSecond() {
        self.measure {
            let _ = thirtySecondAsset.urlAsset.getOneFramePerSecond()
        }
    }
    
    func testGetAllFrames() {
        self.measure {
            let expectation = XCTestExpectation(description: "should get all frames")
            
            thirtySecondAsset.urlAsset.getAllFramesAsUIImages(completion: { (images) in
                expectation.fulfill()
            })
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
}
