/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	`Asset` is a wrapper struct around an `AVURLAsset` and its asset name.
 */

import Foundation
import AVFoundation

public class Asset {
    // MARK: Types
    static let nameKey = "AssetName"
    
    // MARK: Properties
    
    /// The name of the asset to present in the application.
    public var assetName: String = ""
    
    // Custom artwork
    public var artworkURL: URL? = nil
    
    /// The `AVURLAsset` corresponding to an asset in either the application bundle or on the Internet.
    public var urlAsset: AVURLAsset
    
    public var savedTime: Float = 0 // This is in seconds
    
    // @TODO: Idk if CMTime is the right thing to use
    public var savedCMTime: CMTime {
        get {
            return CMTimeMake(Int64(savedTime), 1)
        }
    }
    
    public init(assetName: String, url: URL, artworkURL: URL? = nil, savedTime: Float = 0) {
        self.assetName = assetName
        let avURLAsset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        self.urlAsset = avURLAsset
        self.artworkURL = artworkURL
        self.savedTime = savedTime
    }
}

extension Asset: Equatable {
    public static func == (lhs: Asset, rhs: Asset) -> Bool {
        return lhs.assetName == rhs.assetName && lhs.urlAsset == lhs.urlAsset
    }
}

public class TimePoints {
    public var startTime: CMTime
    public var endTime: CMTime

    init(startTime: CMTime, endTime: CMTime) {
        self.startTime = startTime
        self.endTime = endTime
    }
}

extension TimePoints: Equatable {
    public static func ==(lhs: TimePoints, rhs: TimePoints) -> Bool {
        return lhs.startTime == rhs.startTime &&
            lhs.endTime == rhs.endTime
    }
}

public class VideoAsset: Asset {
    public var timePoints: TimePoints = TimePoints(startTime: kCMTimeZero, endTime: kCMTimeZero)

    public var timeRange: CMTimeRange {
        let duration = timePoints.endTime - timePoints.startTime
        return CMTimeRangeMake(timePoints.startTime, duration)
    }

    public var frame: CGRect = .zero

    public var framerate: Double? {
        guard let track = self.urlAsset.getFirstVideoTrack() else {
            assertionFailure("No first video track")
            return nil
        }

        return Double(track.nominalFrameRate)
    }

    public init(assetName: String, url: URL) {
        super.init(assetName: assetName, url: url)

        let timePoints = TimePoints(startTime: kCMTimeZero, endTime: self.urlAsset.duration)
        self.timePoints = timePoints
    }

    // @TODO: What is a good timescale to use? Does the timescale need to depend on framerate?
    public func setStartime(to time: Double) {
        let cmTime = CMTimeMakeWithSeconds(time, 600)
        self.timePoints.startTime = cmTime
    }

    public func setEndTime(to time: Double) {
        let cmTime = CMTimeMakeWithSeconds(time, 600)

        if cmTime > self.urlAsset.duration {
            self.timePoints.endTime = self.urlAsset.duration
            return
        }

        self.timePoints.endTime = cmTime
    }
}

extension AssetPlayer {
    convenience init(videoAsset: VideoAsset) {
        let asset = Asset(assetName: videoAsset.assetName, url: videoAsset.urlAsset.url)
        self.init(asset: asset)
    }
}
