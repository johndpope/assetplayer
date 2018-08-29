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
    
    public func getOneFramePerSecond() -> [UIImage] {
        let duration: Float64 = CMTimeGetSeconds(self.duration)
        let generator = AVAssetImageGenerator(asset:self)
        generator.appliesPreferredTrackTransform = true
        
        var frames: [UIImage] = []
        for index:Int in 0 ..< Int(duration) {
            let image = self.getFrame(from: generator, with: Float64(index))
            image.flatMap({ frames.append($0) })
        }
        
        return frames
    }
    
    private func getFrame(from generator: AVAssetImageGenerator, with time: Float64) -> UIImage? {
        let time: CMTime = CMTimeMakeWithSeconds(time, 1000)
        let image: CGImage
        do {
            try image = generator.copyCGImage(at:time, actualTime:nil)
        } catch {
            return nil
        }
        return UIImage(cgImage: image)
    }
}
