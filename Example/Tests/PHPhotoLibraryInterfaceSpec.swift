//
//  PHPhotoLibraryInterfaceSpec.swift
//  AssetPlayer
//
//  Created by Craig Holliday on 8/27/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Nimble
import Quick
import AssetPlayer

class PHPhotoLibraryInterfaceSpec: QuickSpec {
    override func spec() {
        let videoUrlToSave = Bundle.main.url(forResource: "SampleVideo_1280x720_1mb", withExtension: "mp4")!
        
        fdescribe("save local video file url to photos") {
            it("should succeed") {
                var success = false
                
                PHPhotoLibraryInterface.saveFileUrlToPhotos(fileUrl: videoUrlToSave,
                                                            success: {
                                                                success = true
                }, failure: { (error) in
                    fail()
                })
                
                expect(success).toEventually(equal(true), timeout: 5)
            }
        }
    }
}

