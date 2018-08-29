//
//  TimelineView.swift
//  koala-tea-video-editor
//
//  Created by Craig Holliday on 3/11/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import UIKit

public protocol TimelineViewDelegate: class {
    func isScrolling()
    func endScrolling()
    func didChangeStartAndEndTime(to time: (startTime: Double, endTime: Double))
}

public class TimelineView: UIView {
    public weak var delegate: TimelineViewDelegate?

    // @TODO: Fix optionality
    private var videoFramesScrollingView: VideoFramesScrollingView!
    private var cropView: TimelineCropView?
    
    private var playbackLineIndicator: PlaybackLineIndicatorView?
    private var timeLineStartingPoint: CGFloat = 0
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = Constants.TimelineBackgroundColor
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setupTimeline(with video: VideoAsset) {
        let maxVideoDurationInSeconds = video.duration > Constants.CropViewDurationInSeconds ? Constants.CropViewDurationInSeconds : video.duration
        
        // @TODO: calculate with calculated width * max time in seconds
        let widthPerSecond = 44.4
        
        // Crop View
        let cropView = TimelineCropView(widthPerSecond: widthPerSecond,
                                maxVideoDurationInSeconds: maxVideoDurationInSeconds,
                                height: self.height,
                                center: CGPoint(x: self.bounds.midX, y: self.bounds.midY))
        cropView.changeBorderColor(to: UIColor(hexString: "#33E5E9") ?? .white)
        self.cropView = cropView
        
        let leftRightScrollViewInset = cropView.frame.minX + cropView.layer.borderWidth
        timeLineStartingPoint = leftRightScrollViewInset
        
        // Layer Scroller View
        let frame = CGRect(x: 0, y: 0, width: self.width, height: self.height)
        
        let framerate = video.framerate ?? 0
        let duration = video.duration
        videoFramesScrollingView = VideoFramesScrollingView(frame: frame,
                                                            videoAsset: video.urlAsset,
                                                            framerate: framerate,
                                                            videoDuration: duration,
                                                            videoFrameWidth: CGFloat(widthPerSecond),
                                                            leftRightScrollViewInset: leftRightScrollViewInset)
        videoFramesScrollingView.delegate = self
        
        // PlaybackLineIndicator
        let playbackLineIndicatorWidth: CGFloat = 24
        let playbackLineIndicatorFrame = CGRect(x: self.timeLineStartingPoint - (playbackLineIndicatorWidth / 2), y: 0, width: playbackLineIndicatorWidth, height: self.height)
        let playbackLineIndicator = PlaybackLineIndicatorView(frame: playbackLineIndicatorFrame)
        self.playbackLineIndicator = playbackLineIndicator
        
        self.addSubview(videoFramesScrollingView)
        self.addSubview(cropView)
        self.addSubview(playbackLineIndicator)
    }
    
    public func handleTracking(startTime: Double, currentTime: Double) {
        guard let cropView = self.cropView else {
            return
        }

        guard !videoFramesScrollingView.isTracking else {
            return
        }
        guard let playbackIndicator = self.playbackLineIndicator else {
            return
        }

        // Calculate size per second
        let pointsPerSecond = videoFramesScrollingView.pointsPerSecond
        let halfPlaybackIndicatorWidth = playbackIndicator.width / 2
        let normalizedTime = currentTime - startTime
        // Calculate x scroll value
        let x = CGFloat(normalizedTime * pointsPerSecond) + (cropView.frame.minX + cropView.borderWidth) - halfPlaybackIndicatorWidth
        
        // Scroll playbackLineIndicator
        playbackIndicator.frame.origin.x = x
        self.layoutIfNeeded()
    }
}

extension TimelineView: VideoFramesScrollingViewDelegate {
    internal func isScrolling() {
        delegate?.isScrolling()
    }

    internal func endScrolling() {
        delegate?.endScrolling()
        
        let x = self.videoFramesScrollingView.contentOffset.x + self.timeLineStartingPoint
        let startTime = Double(x) / videoFramesScrollingView.pointsPerSecond
        let endTime = startTime + Constants.CropViewDurationInSeconds
        delegate?.didChangeStartAndEndTime(to: (startTime: startTime, endTime: endTime))
    }
}

extension TimelineView {
    private struct Constants {
        static let TimelineBackgroundColor = UIColor(hexString: "#DFE3E3") ?? .white
        static let CropViewColor = UIColor(hexString: "#33E5E9") ?? .white
        static let CropViewDurationInSeconds = 5.0
    }
}
