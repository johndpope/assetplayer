/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	`Asset` is a wrapper struct around an `AVURLAsset` and its asset name.
 */

import Foundation
import AVFoundation

protocol AssetProtocol {
    /// The name of the asset to present in the application.
    var assetName: String { get }
    // Custom artwork that shows in remote view
    var artworkURL: URL? { get }
    /// The `AVURLAsset` corresponding to an asset in either the application bundle or on the Internet.
    var urlAsset: AVURLAsset { get }
}

public struct Asset: AssetProtocol {
    public var assetName: String
    public var artworkURL: URL?
    public var urlAsset: AVURLAsset
    
    public init(assetName: String = "", url: URL, artworkURL: URL? = nil) {
        self.assetName = assetName
        self.urlAsset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        self.artworkURL = artworkURL
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

public struct VideoAsset: AssetProtocol {
    var assetName: String
    var artworkURL: URL?
    var urlAsset: AVURLAsset
    
    public var timePoints: TimePoints = TimePoints(startTime: kCMTimeZero, endTime: kCMTimeZero)

    public var timeRange: CMTimeRange {
        let duration = timePoints.endTime - timePoints.startTime
        return CMTimeRangeMake(timePoints.startTime, duration)
    }

    public var frame: CGRect = .zero

    public var framerate: Double? {
        guard let track = self.urlAsset.getFirstVideoTrack() else {
            print("No first video track")
            return nil
        }

        return Double(track.nominalFrameRate)
    }

    public init(assetName: String = "", url: URL) {
        self.assetName = assetName
        self.urlAsset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])

        let timePoints = TimePoints(startTime: kCMTimeZero, endTime: self.urlAsset.duration)
        self.timePoints = timePoints
    }

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
