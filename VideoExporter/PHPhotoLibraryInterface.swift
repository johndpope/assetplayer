//
//  PHPhotoLibraryInterface.swift
//  AssetPlayer
//
//  Created by Craig Holliday on 8/27/18.
//

import Photos

public enum PhotoLibraryAuthorization {
    case authorized
    case notDetermined
    case denied
}

public class PHPhotoLibraryInterface {
    public static func authorizationStatus() -> PhotoLibraryAuthorization {
        switch PHPhotoLibrary.authorizationStatus() {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .authorized, .restricted:
            return .authorized
        }
    }

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
    
    public static func requestPhotosAccess(completion: @escaping (_ status: PhotoLibraryAuthorization) -> ()) {
        PHPhotoLibrary.requestAuthorization { (status) in
            switch status {
            case .notDetermined:
                completion(.notDetermined)
            case .denied:
                completion(.denied)
            case .authorized, .restricted:
                completion(.authorized)
            }
        }
    }
}
