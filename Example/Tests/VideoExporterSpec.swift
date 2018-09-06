//
//  VideoExporterSpec.swift
//  AssetPlayer
//
//  Created by Craig Holliday on 8/27/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Nimble
import Quick
import AssetPlayer
import SwifterSwift
import CoreMedia

class VideoExporterSpec: QuickSpec {
    override func spec() {
        var thirtySecondAsset: VideoAsset {
            return VideoAsset(url: Bundle.main.url(forResource: "SampleVideo_1280x720_5mb", withExtension: "mp4")!)
        }
        
        var verticalVideo: VideoAsset {
            return VideoAsset(url: Bundle.main.url(forResource: "vertical_video", withExtension: "mov")!)
        }
        
        var verticalVideoWithPortraitOrientation: VideoAsset {
            return VideoAsset(url: Bundle.main.url(forResource: "vertical_video", withExtension: "MOV")!)
        }
        
        xdescribe("video exporter") {
            var fileUrl: URL?
            var progressToCheck: Float = 0
            
            afterEach {
                if let url = fileUrl {
                    // Remove this line to manually review exported videos
                    FileHelpers.removeFileAtURL(fileURL: url)
                }
                
                fileUrl = nil
                progressToCheck = 0
            }
            
            // canvas view
            let canvasViewFrame = CGRect(x: 0, y: 0, width: 500, height: 500)
            
            // cropped view
            let croppedViewSize = CGSize(width: 720, height: 1280).aspectFit(to: canvasViewFrame.size)
            let origin = CGPoint(x: canvasViewFrame.midX - (croppedViewSize.width/2), y: 0)
            let cropViewFrame = CGRect(origin: origin, size: croppedViewSize)
            
            describe("export video with theme preset") {
                // draggable video view
                let draggableViewSize = CGSize(width: 1280/(720/500), height: 500)
                let draggableViewFrame = CGRect(origin: CGPoint(x: canvasViewFrame.midX - (draggableViewSize.width/2), y: 0),
                                                size: draggableViewSize)
                let finalAsset = thirtySecondAsset.withChangingFrame(to: draggableViewFrame).changeStartTime(to: 10.0).changeEndTime(to: 12.5)
                
                it("should complete export with progress") {
                    VideoExporter.exportThemeVideo(with: finalAsset,
                                                   cropViewFrame: cropViewFrame,
                                                   progress:
                        { (progress) in
                            print("export video with theme preset: \(progress)")
                            progressToCheck = progress
                    }, success: { returnedFileUrl in
                        fileUrl = returnedFileUrl
                    }, failure: { (error) in
                        expect(error).to(beNil())
                        fail()
                    })
                    
                    expect(progressToCheck).toEventually(beGreaterThan(0.5), timeout: 30)
                    expect(fileUrl).toEventuallyNot(beNil(), timeout: 30)
                    
                    // Check just saved local video
                    let savedVideo = VideoAsset(url: fileUrl!)
                    let firstVideoTrack = savedVideo.urlAsset.getFirstVideoTrack()
                    expect(firstVideoTrack?.naturalSize.width).to(equal(1080))
                    expect(firstVideoTrack?.naturalSize.height).to(equal(1920))
                    expect(firstVideoTrack?.asset?.duration.seconds).to(equal(5))
                }
            }
            
            describe("export vertical video with theme preset") {
                // draggable video view
                let draggableViewSize = CGSize(width: 281.25, height: 500)
                let draggableViewFrame = CGRect(origin: CGPoint(x: canvasViewFrame.midX - (draggableViewSize.width/2), y: 0),
                                                size: draggableViewSize)
                let finalVerticalAsset = verticalVideoWithPortraitOrientation.withChangingFrame(to: draggableViewFrame).changeStartTime(to: 5.0).changeEndTime(to: 10.0)
                
                it("should complete export with progress") {
                    VideoExporter.exportThemeVideo(with: finalVerticalAsset,
                                                   cropViewFrame: cropViewFrame,
                                                   progress:
                        { (progress) in
                            print("export vertical video with theme preset: \(progress)")
                            progressToCheck = progress
                    }, success: { returnedFileUrl in
                        fileUrl = returnedFileUrl
                    }, failure: { (error) in
                        expect(error).to(beNil())
                        fail()
                    })
                    
                    expect(progressToCheck).toEventually(beGreaterThan(0.5), timeout: 30)
                    expect(fileUrl).toEventuallyNot(beNil(), timeout: 30)
                    
                    // Check just saved local video
                    let savedVideo = VideoAsset(url: fileUrl!)
                    let firstVideoTrack = savedVideo.urlAsset.getFirstVideoTrack()
                    expect(firstVideoTrack?.naturalSize.width).to(equal(1080))
                    expect(firstVideoTrack?.naturalSize.height).to(equal(1920))
                    expect(firstVideoTrack?.asset?.duration.seconds).to(equal(5))
                }
            }
        }
    }
}
