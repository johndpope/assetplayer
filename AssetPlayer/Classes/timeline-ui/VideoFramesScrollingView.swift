//
//  VideoFramesScrollingView.swift
//  koala-tea-video-editor
//
//  Created by Craig Holliday on 3/6/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import UIKit

protocol VideoFramesScrollingViewDelegate: class {
    func isScrolling(to time: Double)
    func endScrolling(to time: Double)
}

public extension VideoFramesScrollingView {
    private struct Constants {
        static let PercentageOfTotalFrames: Double = 10
    }
}

public class VideoFramesScrollingView: UIView {
    weak var delegate: VideoFramesScrollingViewDelegate?

//    private var scrollingProgrammatically: Bool = false

    // @TODO: make only needed assets public
    public let scrollView = UIScrollView()

    private let framerate: Double
    private let videoDuration: Double

    private var videoFrameWidth: CGFloat {
        return self.height * (9/16)
    }
    
    public var pointsPerSecond: Double {
        return Double(self.scrollView.contentSize.width) / self.videoDuration
    }

    private var widthFromVideoDuration: CGFloat {
        let totalVideoFrames = videoDuration * framerate
        let frameCountForView = totalVideoFrames * Constants.PercentageOfTotalFrames
        // Frame count for view * width wanted for each frame
        let totalWidth = CGFloat(frameCountForView) * videoFrameWidth
        return totalWidth
    }

//    public var currentTimeForLinePosition: Double {
//        let xOffset = self.scrollView.contentOffset.x
//        let leftInset = self.scrollView.contentInset.left
//        let center = xOffset + leftInset
//
//        let timePerPoint: Double = self.videoDuration / Double(self.scrollView.contentSize.width)
//        let videoTime = Double(center) * timePerPoint
//
//        guard videoTime >= 0 else {
//            return 0.0
//        }
//
//        return videoTime
//    }
    
    private var videoFramesView: VideoFramesView?

    required public init(frame: CGRect,
                         videoAsset: AVURLAsset,
                         framerate: Double,
                         videoDuration: Double,
                         leftRightScrollViewInset: CGFloat) {
        self.framerate = framerate
        self.videoDuration = videoDuration

        super.init(frame: frame)
        
        self.setupScrollView(leftRightInset: leftRightScrollViewInset)

        // Video frame view
        let newVideoFramesView = VideoFramesView(videoAsset: videoAsset,
                                              framerate: framerate,
                                              videoDuration: videoDuration,
                                              videoFrameWidth: self.videoFrameWidth,
                                              videoFrameHeight: self.height,
                                              percentageOfTotalFrames: Constants.PercentageOfTotalFrames,
                                              imagesLoaded:
            { [weak self] in
                guard let videoFramesView = self?.videoFramesView else {
                    return
                }
                self?.scrollView.contentSize = videoFramesView.size
        })
        self.scrollView.addSubview(newVideoFramesView)
        self.videoFramesView = newVideoFramesView
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

//    public func handleTracking(for time: Double) {
//        guard !self.scrollView.isTracking else {
//            return
//        }
//
//        // Calculate size per second
//        let pointsPerSecond: Double =  Double(self.scrollView.contentSize.width) / self.videoDuration
//        // Calculate x scroll value
//        let x = time * (pointsPerSecond)
//        let y = self.scrollView.contentOffset.y
//
//        // Scroll to time
//        let frame = CGRect(x: x, y: Double(y), width: 0.001, height: 0.001)
//
//        self.scrollingProgrammatically = true
//        self.scrollView.scrollRectToVisible(frame, animated: false)
//        self.scrollingProgrammatically = false
//    }

    private func setupScrollView(leftRightInset: CGFloat) {
        self.scrollView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        self.scrollView.delegate = self

        self.scrollView.contentSize = CGSize(width: self.scrollView.width, height: self.scrollView.height)
        self.scrollView.contentInset = UIEdgeInsets(top: 0, left: leftRightInset, bottom: 0, right: leftRightInset)

        self.addSubview(scrollView)

        self.scrollView.contentOffset = CGPoint(x: -(scrollView.width/2) , y: 0)

        self.scrollView.showsHorizontalScrollIndicator = false
        self.scrollView.showsVerticalScrollIndicator = false
    }
}

extension VideoFramesScrollingView: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {

//        self.handleDefaultScroll(from: scrollView)
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//        self.handleEndScroll(from: scrollView)
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !decelerate else { return }

//        self.handleEndScroll(from: scrollView)
    }

//    func handleEndScroll(from scrollView: UIScrollView) {
//        guard !self.scrollingProgrammatically else {
//            return
//        }
//
//        let videoTime = self.currentTimeForLinePosition
//
//        guard videoTime <= videoDuration else {
//            delegate?.endScrolling(to: videoDuration)
//            return
//        }
//        delegate?.endScrolling(to: videoTime)
//    }
//
//    func handleDefaultScroll(from scrollView: UIScrollView) {
//        guard !self.scrollingProgrammatically else {
//            return
//        }
//
//        let xOffset = scrollView.contentOffset.x
//        let leftInset = scrollView.contentInset.left
//        let center = xOffset + leftInset
//
//        let timePerPoint: Double = self.videoDuration / Double(self.scrollView.contentSize.width)
//        let videoTime = Double(center) * timePerPoint
//
//        guard videoTime >= 0 else {
//            delegate?.isScrolling(to: 0.0)
//            return
//        }
//        guard videoTime <= videoDuration else {
//            delegate?.isScrolling(to: videoDuration)
//            return
//        }
//        delegate?.isScrolling(to: videoTime)
//    }
}

import AVFoundation

public class VideoFramesView: UIView {
    required public init(videoAsset: AVURLAsset,
                         framerate: Double,
                         videoDuration: Double,
                         videoFrameWidth: CGFloat,
                         videoFrameHeight: CGFloat,
                         percentageOfTotalFrames: Double,
                         imagesLoaded: @escaping () -> ()) {
        super.init(frame: .zero)
        self.clipsToBounds = true
        
        videoAsset.getAllFramesAsUIImages { [weak self] (images) in
            guard let strongSelf = self else { return }
            
            guard let images = images else {
                assertionFailure("Issue with getting frames as images for Video Asset")
                return
            }
            
            let totalVideoFrames = videoDuration * framerate
            let frameCountForView = totalVideoFrames * (percentageOfTotalFrames / 100)
            // Frame count for view * width wanted for each frame
            let totalWidth = CGFloat(frameCountForView) * videoFrameWidth
            let divisor = (Double(images.count) / frameCountForView).rounded()
            
            let imageViews = strongSelf.createSpreadOfImageViews(images: images,
                                                           divisor: divisor,
                                                           videoFrameWidth: videoFrameWidth,
                                                           videoFrameHeight: videoFrameHeight)
            
            strongSelf.width = totalWidth
            strongSelf.height = videoFrameHeight
            strongSelf.addSubviews(imageViews)
            
            imagesLoaded()
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createSpreadOfImageViews(images: [UIImage],
                                          divisor: Double,
                                          videoFrameWidth: CGFloat,
                                          videoFrameHeight: CGFloat) -> [UIImageView] {
        var imageViews = [UIImageView]()
        // Get an even spread of images per the frame count
        var counter: CGFloat = 0
        for image in images {
            guard counter.truncatingRemainder(dividingBy: CGFloat(divisor)) == 0 else {
                counter += 1
                continue
            }
            
            let x: CGFloat = CGFloat(imageViews.count) * videoFrameWidth
            
            let imageView = UIImageView(frame: CGRect(x: x, y: 0, width: videoFrameWidth, height: videoFrameHeight))
            imageView.contentMode = .scaleAspectFill
            imageView.image = image
            imageView.clipsToBounds = true
            
            imageViews.append(imageView)
            counter += 1
        }
        
        return imageViews
    }
}
