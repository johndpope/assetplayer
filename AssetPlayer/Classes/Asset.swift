/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	`Asset` is a wrapper struct around an `AVURLAsset` and its asset name.
 */

import Foundation
import AVFoundation

public protocol AssetProtocol {
    /// The `AVURLAsset` corresponding to an asset in either the application bundle or on the Internet.
    var urlAsset: AVURLAsset { get }
}

// MARK: Asset

public struct Asset: AssetProtocol {
    public var urlAsset: AVURLAsset
    
    public init(url: URL) {
        self.urlAsset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
    }
}

// MARK: Video Asset

public struct TimePoints {
    public let startTime: CMTime
    public let endTime: CMTime
    
    public var startTimeInSeconds: Double {
        return startTime.seconds
    }
    
    public var endTimeInSeconds: Double {
        return endTime.seconds
    }
    
    public func withChangingStartTime(to startTime: CMTime) -> TimePoints {
        return TimePoints(startTime: startTime, endTime: endTime)
    }
    
    public func withChangingEndTime(to endTime: CMTime) -> TimePoints {
        return TimePoints(startTime: startTime, endTime: endTime)
    }
}

extension TimePoints: Equatable {
    public static func ==(lhs: TimePoints, rhs: TimePoints) -> Bool {
        return lhs.startTime == rhs.startTime &&
            lhs.endTime == rhs.endTime
    }
}

public struct VideoAsset: AssetProtocol {
    public let urlAsset: AVURLAsset
    /// Start and End times for export
    public let timePoints: TimePoints
    /// frame of video in relation to CanvasView to be exported
    public let frame: CGRect
    
    /// Framerate of Video
    public var framerate: Double? {
        guard let track = self.urlAsset.getFirstVideoTrack() else {
            print("No first video track")
            return nil
        }
        
        return Double(track.nominalFrameRate)
    }
    
    public var timeRange: CMTimeRange {
        let duration = timePoints.endTime - timePoints.startTime
        return CMTimeRangeMake(timePoints.startTime, duration)
    }
    
    public var duration: Double {
        return (timePoints.endTime - timePoints.startTime).seconds
    }
    
    public var durationInCMTime: CMTime {
        return CMTimeMakeWithSeconds(self.duration, 600)
    }
    
    public init(urlAsset: AVURLAsset,
                timePoints: TimePoints,
                frame: CGRect = .zero) {
        self.urlAsset = urlAsset
        self.timePoints = timePoints
        self.frame = frame
    }
    
    public init(url: URL) {
        let urlAsset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        let timePoints = TimePoints(startTime: kCMTimeZero, endTime: urlAsset.duration)
        self.init(urlAsset: urlAsset, timePoints: timePoints)
    }

    public func changeStartTime(to time: Double) -> VideoAsset {
        let cmTime = CMTimeMakeWithSeconds(time, 1000)
        
        guard time > 0 else {
            return VideoAsset(urlAsset: self.urlAsset,
                              timePoints: self.timePoints.withChangingStartTime(to: kCMTimeZero),
                              frame: self.frame)
        }
        
        return VideoAsset(urlAsset: self.urlAsset,
                          timePoints: self.timePoints.withChangingStartTime(to: cmTime),
                          frame: self.frame)
    }

    public func changeEndTime(to time: Double) -> VideoAsset {
        let cmTime = CMTimeMakeWithSeconds(time, 1000)
        
        guard cmTime < self.urlAsset.duration else {
            return VideoAsset(urlAsset: self.urlAsset,
                              timePoints: self.timePoints.withChangingEndTime(to: self.urlAsset.duration),
                              frame: self.frame)
        }

        return VideoAsset(urlAsset: self.urlAsset,
                          timePoints: self.timePoints.withChangingEndTime(to: cmTime),
                          frame: self.frame)
    }
    
    public func withChangingFrame(to frame: CGRect) -> VideoAsset {
        return VideoAsset(urlAsset: self.urlAsset, timePoints: self.timePoints, frame: frame)
    }
}

// MARK: AV Extension Getters
extension VideoAsset {
    public func getAllFramesAsUIImages() -> [UIImage]? {
        return self.urlAsset.getAllFramesAsUIImages()
    }
}
