//
//  AVAssetExtensions.swift
//  koala-tea-video-editor
//
//  Created by Craig Holliday on 2/7/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import AVFoundation
import UIKit

extension AVAsset {
    public func getFirstVideoTrack() -> AVAssetTrack? {
        guard let track = self.tracks(withMediaType: AVMediaType.video).first else {
            assertionFailure("AVAsset: " + "Failure getting first video track")
            return nil
        }
        let videoTrack: AVAssetTrack = track as AVAssetTrack
        return videoTrack
    }
    
    public func getFirstAudioTrack() -> AVAssetTrack? {
        guard let track = self.tracks(withMediaType: AVMediaType.audio).first else {
            assertionFailure("AVAsset: " + "Failure getting first audio track")
            return nil
        }
        let videoTrack: AVAssetTrack = track as AVAssetTrack
        return videoTrack
    }
}

// MARK: Frame getters
extension AVAsset {
    // @TODO: Call initialDurationRequest something else
    public func getAllFramesIncrementally(initialFramesDurationInSeconds: Double, completion: @escaping ([UIImage]?) -> ()) -> [UIImage]? {
        // Start getting all frames with completion which will be done in background
        self.getAllFramesAsUIImages(completion: completion)
        
        // In the mean time, return frames
        return self.getFrames(atTimeRange: CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(initialFramesDurationInSeconds, 1000)))
    }
    
    public func getAllFramesAsUIImages(completion: @escaping ([UIImage]?) -> ()) {
        var images: [UIImage] = []

        DispatchQueue.global(qos: .background).async {
            // Frame Reader
            let reader = try! AVAssetReader(asset: self)
            
            guard let firstTrack = self.getFirstVideoTrack() else {
                completion(nil)
                return
            }

            // read video frames as BGRA
            let trackReaderOutput = AVAssetReaderTrackOutput(track: firstTrack,
                                                             outputSettings:[String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA)])
            reader.add(trackReaderOutput)
            reader.startReading()

            while let sampleBuffer = trackReaderOutput.copyNextSampleBuffer() {
                let image = CMBufferHelper.imageFromSampleBuffer(sampleBuffer: sampleBuffer)
                images.append(image)
            }

            DispatchQueue.main.async {
                completion(images)
            }
        }
    }
    
    private func getFrames(atTimeRange timeRange: CMTimeRange) -> [UIImage]? {
        var images: [UIImage] = []
        
        // Frame Reader
        let reader = try! AVAssetReader(asset: self)
        
        guard let firstTrack = self.getFirstVideoTrack() else {
            return nil
        }
        
        // read video frames as BGRA
        let trackReaderOutput = AVAssetReaderTrackOutput(track: firstTrack,
                                                         outputSettings:[String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA)])
        reader.add(trackReaderOutput)
        reader.timeRange = timeRange
        reader.startReading()
        
        while let sampleBuffer = trackReaderOutput.copyNextSampleBuffer() {
            let image = CMBufferHelper.imageFromSampleBuffer(sampleBuffer: sampleBuffer)
            images.append(image)
        }
        
        return images
    }
}
