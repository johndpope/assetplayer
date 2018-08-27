//
//  PHPhotoLibraryInterface.swift
//  AssetPlayer
//
//  Created by Craig Holliday on 8/27/18.
//

import Photos

public class PHPhotoLibraryInterface {
    public static func saveFileUrlToPhotos(fileUrl: URL,
                                           success: @escaping () -> (),
                                           failure: @escaping (Error?) -> ()) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileUrl)
        }) { saved, error in
            guard saved == true else {
                failure(error)
                return
            }
            success()
        }
    }
}
