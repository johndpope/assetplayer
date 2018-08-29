//
//  VideoFramesScrollingView.swift
//  koala-tea-video-editor
//
//  Created by Craig Holliday on 3/6/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import UIKit

protocol VideoFramesScrollingViewDelegate: class {
    func isScrolling()
    func endScrolling()
}

public extension VideoFramesScrollingView {
    private struct Constants {
        static let DesiredFramesPerSecond: Double = 1
    }
}

public class VideoFramesScrollingView: UIView {
    weak var delegate: VideoFramesScrollingViewDelegate?
    
    private let scrollView = UIScrollView()
    public var isTracking: Bool {
        return self.scrollView.isTracking
    }
    public var contentOffset: CGPoint {
        return self.scrollView.contentOffset
    }

    private let framerate: Double
    private let videoDuration: Double
    
    public var pointsPerSecond: Double {
        return Double(self.scrollView.contentSize.width) / self.videoDuration
    }
    
    private var videoFramesView: VideoFramesView?

    required public init(frame: CGRect,
                         videoAsset: AVURLAsset,
                         framerate: Double,
                         videoDuration: Double,
                         videoFrameWidth: CGFloat,
                         leftRightScrollViewInset: CGFloat) {
        self.framerate = framerate
        self.videoDuration = videoDuration

        super.init(frame: frame)
        
        self.setupScrollView(leftRightInset: leftRightScrollViewInset)

        // Video frame view
        let newVideoFramesView = VideoFramesView(videoAsset: videoAsset,
                                              framerate: framerate,
                                              videoDuration: videoDuration,
                                              videoFrameSize: CGSize(width: videoFrameWidth, height: self.height),
                                              desiredFramesPerSecond: Constants.DesiredFramesPerSecond,
                                              imagesLoaded:
            { [weak self] in
                guard let videoFramesView = self?.videoFramesView else {
                    return
                }
                self?.scrollView.contentSize = videoFramesView.size
        })
        self.scrollView.contentSize = newVideoFramesView.size
        self.scrollView.addSubview(newVideoFramesView)
        self.videoFramesView = newVideoFramesView
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
        self.delegate?.isScrolling()
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.delegate?.endScrolling()
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !decelerate else { return }
        
        self.delegate?.endScrolling()
    }
}

import AVFoundation

public class VideoFramesView: UIView {
    required public init(videoAsset: AVURLAsset,
                         framerate: Double,
                         videoDuration: Double,
                         videoFrameSize: CGSize,
                         desiredFramesPerSecond: Double,
                         imagesLoaded: @escaping () -> ()) {
        super.init(frame: .zero)
        self.clipsToBounds = true
        
        let frameCountForView = videoDuration * desiredFramesPerSecond
        // Frame count for view * width wanted for each frame
        let totalWidth = CGFloat(frameCountForView) * videoFrameSize.width
        let totalFrameCount = videoDuration * framerate
        let divisor = (totalFrameCount / frameCountForView).rounded()
        
        let initialImages = videoAsset.getAllFramesIncrementally(initialFramesDurationInSeconds: Constants.DurationInSecondsForInitialLoadedFrames) { [weak self] (allImages) in
            guard let strongSelf = self else { return }
            
            strongSelf.removeSubviews()
            guard let images = allImages else {
                assertionFailure("Issue with getting initial frames as images for Video Asset")
                return
            }
            let spreadofImagesViews = strongSelf.createSpreadOfImageViews(images: images, divisor: divisor, size: videoFrameSize)
            strongSelf.addSubviews(spreadofImagesViews)
            
            imagesLoaded()
        }
        guard let images = initialImages else {
            assertionFailure("Issue with getting initial frames as images for Video Asset")
            return
        }
        
        self.width = totalWidth
        self.height = videoFrameSize.height
        let spreadofImagesViews = self.createSpreadOfImageViews(images: images, divisor: divisor, size: videoFrameSize)
        self.addSubviews(spreadofImagesViews)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createSpreadOfImageViews(images: [UIImage],
                                          divisor: Double,
                                          size: CGSize) -> [UIImageView] {
        var imageViews = [UIImageView]()
        // Get an even spread of images per the frame count
        var counter: CGFloat = 0
        for image in images {
            guard counter.truncatingRemainder(dividingBy: CGFloat(divisor)) == 0 else {
                counter += 1
                continue
            }
            
            let x: CGFloat = CGFloat(imageViews.count) * size.width
            
            let imageView = UIImageView(frame: CGRect(x: x, y: 0, width: size.width, height: size.height))
            imageView.contentMode = .scaleAspectFill
            imageView.image = image
            imageView.clipsToBounds = true
            
            imageViews.append(imageView)
            counter += 1
        }
        
        return imageViews
    }
    
    private struct Constants {
        static let DurationInSecondsForInitialLoadedFrames: Double = 10
    }
}
