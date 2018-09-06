//
//  VideoHelpers.swift
//  koala-tea-video-editor
//
//  Created by Craig Holliday on 1/7/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import AVFoundation
import UIKit

/// Exporter for VideoAssets
public class VideoExporter {
    private enum VideoManagerError: Error {
        case FailedError(reason: String)
        case CancelledError
        case UnknownError
        case NoFirstVideoTrack
        case NoFirstAudioTrack
    }

    /**
     Supported Final Video Sizes

     - _1080x1080: 1080 width by 1080 height
     - _1280x720: 1280 width by 720 height
     - _720x1280: 720 width by 1280 height
     - _1920x1080: 1920 width by 1080 height
     - _1080x1920: 1080 width by 1920 height
     */
    public enum VideoExportSizes {
        case _1080x1080
        case _1024x1024
        case _1280x720
        case _720x1280
        case _1920x1080
        case _1080x1920
        case _1280x1024_twitter

        typealias RawValue = CGSize

        var rawValue: RawValue {
            switch self {
            case ._1080x1080:
                return CGSize(width: 1080, height: 1080)
            case ._1024x1024:
                return CGSize(width: 1024, height: 1024)
            case ._1280x720:
                return CGSize(width: 1280, height: 720)
            case ._720x1280:
                return CGSize(width: 720, height: 1280)
            case ._1920x1080:
                return CGSize(width: 1920, height: 1080)
            case ._1080x1920:
                return CGSize(width: 1080, height: 1920)
            case ._1280x1024_twitter:
                return CGSize(width: 1280, height: 1024)
            }
        }
    }
}

extension VideoExporter {
    /**
     Exports a video to the disk from AVMutableComposition and AVMutableVideoComposition.

     - Parameters:
         - avMutableComposition: Layer composition of everything except video
         - avMutatableVideoComposition: Video composition

         - progress: Returns progress every second.
         - success: Completion for when the video is saved successfully.
         - failure: Completion for when the video failed to save.
     */
    private static func exportVideoToDiskFrom(avMutableComposition: AVMutableComposition,
                                             avMutatableVideoComposition: AVMutableVideoComposition,
                                             progress: @escaping (Float) -> (),
                                             success: @escaping (_ fileUrl: URL) -> (),
                                             failure: @escaping (Error) -> ()) {
        // Get file path
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            failure(VideoManagerError.FailedError(reason: "Get File Path Error"))
            return
        }
        
        var dateString = ""
        let utcTimeZone = TimeZone(abbreviation: "UTC")
        if #available(iOS 10.0, *) {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.timeZone = utcTimeZone
            dateString = dateFormatter.string(from: Date())
        } else {
            // Fallback on earlier versions
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = utcTimeZone
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            dateString = dateFormatter.string(from: Date())
        }
        
        let fileURL = documentDirectory.appendingPathComponent("curago_video-\(dateString).mp4")
        
        // Remove any file at URL because if file exists assetExport will fail
        FileHelpers.removeFileAtURL(fileURL: fileURL)

        // Create AVAssetExportSession
        guard let assetExportSession = AVAssetExportSession(asset: avMutableComposition, presetName: AVAssetExportPresetHighestQuality) else {
            failure(VideoManagerError.FailedError(reason: "Can't create asset exporter"))
            return
        }
        assetExportSession.videoComposition = avMutatableVideoComposition
        assetExportSession.outputFileType = AVFileType.mp4
        assetExportSession.shouldOptimizeForNetworkUse = true
        assetExportSession.outputURL = fileURL

        // Schedule timer for sending progress
        var timer: Timer? = nil

        if #available(iOS 10.0, *) {
            timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { (timer) in
                progress(assetExportSession.progress)
            })
        } else {
            // Progress not available for <10
        }
        
        assetExportSession.exportAsynchronously(completionHandler: {
            timer?.invalidate()
            switch assetExportSession.status {
            case .completed:
                success(fileURL)
            case .cancelled:
                failure(assetExportSession.error ?? VideoManagerError.CancelledError)
            case .failed:
                failure(assetExportSession.error ?? VideoManagerError.FailedError(reason: "Asset Exporter Failed"))
            case .unknown, .exporting, .waiting:
                // Should never arrive here
                failure(assetExportSession.error ?? VideoManagerError.UnknownError)
            }
        })
    }

    private static func videoCompositionInstructionFor(compositionTrack: AVCompositionTrack,
                                                       assetTrack: AVAssetTrack,
                                                       assetframe: CGRect,
                                                       widthMultiplier: CGFloat,
                                                       heightMultiplier: CGFloat,
                                                       cropViewFrame: CGRect) -> AVMutableVideoCompositionLayerInstruction
    {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionTrack)
        let assetTransform = assetTrack.preferredTransform
        let assetInfo = VideoExporterOrientationHelper.orientationFromTransform(transform: assetTransform)

        let scaledX: CGFloat = (assetframe.minX - cropViewFrame.minX) * widthMultiplier
        let scaledY: CGFloat = (assetframe.minY - cropViewFrame.minY) * heightMultiplier
        let scaledWidth = assetframe.width * widthMultiplier
        let scaledHeight = assetframe.height * heightMultiplier
        
        var scaledRect = CGRect(x: scaledX, y: scaledY, width: scaledWidth, height: scaledHeight)
        var xFix: CGFloat = 0
        if assetInfo.isPortrait {
            // Flip height and width scale if is portrait because we use the asset's transform rotation
            scaledRect = CGRect(x: scaledX, y: scaledY, width: scaledHeight, height: scaledWidth)
            xFix = scaledWidth
        }
        
        let scaledTransform = CGAffineTransform(from: CGRect(x: 0, y: 0, width: assetTrack.naturalSize.width, height: assetTrack.naturalSize.height),
                                                toRect: scaledRect)
        let finalTransform = scaledTransform.translatedBy(x: xFix, y: 0).rotated(by: VideoExporterOrientationHelper.rotation(from: assetTransform))
        
        instruction.setTransform(finalTransform, at: kCMTimeZero)
        return instruction
    }
}

// MARK: Generic Export Method
extension VideoExporter {
    /// Export video from VideoAsset with a cropping view to a final export size.
    ///
    /// - Parameters:
    ///   - videoAsset: VideoAsset to export
    ///   - cropViewFrame: frame of crop view that will determine crop of final exported video. Crop View frame is in relation to a CanvasViewFrame
    ///   - finalExportSize: final export size the video will be after completeing
    ///   - progress: progress of export
    ///   - success: successful completion of export
    ///   - failure: export failure
    public static func exportVideo(with videoAsset: VideoAsset,
                                   cropViewFrame: CGRect,
                                   finalExportSize: VideoExportSizes,
                                   progress: @escaping (Float) -> (),
                                   success: @escaping (_ fileUrl: URL) -> (),
                                   failure: @escaping (Error) -> ()) {
        let exportVideoSize = finalExportSize.rawValue
        
        // Canvas view has to be same aspect ratio as export video size
        guard cropViewFrame.size.getAspectRatio() == exportVideoSize.getAspectRatio() else {
            assertionFailure("Selected export size's aspect ratio: \(exportVideoSize.getAspectRatio()) does not equal Cropped View Frame's aspect ratio: \(cropViewFrame.size.getAspectRatio())")
            return
        }
        
        // 1 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
        let mixComposition = AVMutableComposition()
        
        // 2 - Create video tracks
        guard let firstTrack = mixComposition.addMutableTrack(withMediaType: .video,
                                                              preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else
        {
            failure(VideoManagerError.FailedError(reason: "Failed To Create Video Track"))
            return
        }
        guard let assetFirstVideoTrack = videoAsset.urlAsset.getFirstVideoTrack() else {
            failure(VideoManagerError.NoFirstVideoTrack)
            return
        }
        
        // Attach timerange for first video track
        do {
            try firstTrack.insertTimeRange(videoAsset.timeRange,
                                           of: assetFirstVideoTrack,
                                           at: kCMTimeZero)
        } catch {
            failure(VideoManagerError.FailedError(reason: "Failed To Insert Time Range For Video Track"))
            return
        }
        
        // 2.1
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRange(start: kCMTimeZero, duration: videoAsset.durationInCMTime)
        
        // Multipliers to scale height and width of video to final export size
        let heightMultiplier: CGFloat = exportVideoSize.height / cropViewFrame.height
        let widthMultiplier: CGFloat = exportVideoSize.width / cropViewFrame.width
        // 2.2
        let firstInstruction = self.videoCompositionInstructionFor(compositionTrack: firstTrack,
                                                                   assetTrack: assetFirstVideoTrack,
                                                                   assetframe: videoAsset.frame,
                                                                   widthMultiplier: widthMultiplier,
                                                                   heightMultiplier: heightMultiplier,
                                                                   cropViewFrame: cropViewFrame)
        
        // 2.3
        mainInstruction.layerInstructions = [firstInstruction]
        
        let avMutableVideoComposition = AVMutableVideoComposition()
        avMutableVideoComposition.instructions = [mainInstruction]
        guard let framerate = videoAsset.framerate else {
            failure(VideoManagerError.FailedError(reason: "No Framerate for Asset"))
            return
        }
        avMutableVideoComposition.frameDuration = CMTimeMake(1, Int32(framerate))
        avMutableVideoComposition.renderSize = exportVideoSize
        
        // 3 - Audio track
        guard let audioAsset = videoAsset.urlAsset.getFirstAudioTrack() else {
            failure(VideoManagerError.FailedError(reason: "No First Audio Track"))
            return
        }
        
        let audioTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: 0)
        do {
            try audioTrack?.insertTimeRange(videoAsset.timeRange,
                                            of: audioAsset,
                                            at: kCMTimeZero)
        } catch {
            failure(VideoManagerError.FailedError(reason: "Failed To Insert Time Range For Audio Track"))
        }
        
        // 4 Export Video
        self.exportVideoToDiskFrom(avMutableComposition: mixComposition, avMutatableVideoComposition: avMutableVideoComposition, progress: progress, success: success, failure: failure)
    }
}

// MARK: Convenience export method
extension VideoExporter {
    public static func exportThemeVideo(with videoAsset: VideoAsset,
                                        cropViewFrame: CGRect,
                                        progress: @escaping (Float) -> (),
                                        success: @escaping (_ fileUrl: URL) -> (),
                                        failure: @escaping (Error) -> ()) {
        self.exportVideo(with: videoAsset, cropViewFrame: cropViewFrame, finalExportSize: ._1080x1920, progress: progress, success: success, failure: failure)
    }
}
