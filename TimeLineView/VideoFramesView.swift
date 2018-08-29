//
//  VideoFramesView.swift
//  AssetPlayer
//
//  Created by Craig Holliday on 8/29/18.
//

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
