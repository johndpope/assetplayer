//
//  CanvasView.swift
//  koala-tea-video-editor
//
//  Created by Craig Holliday on 2/7/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import UIKit

enum CanvasFrameSizes {
    case _1x1(forSize: CGSize)
    case _16x9(forSize: CGSize)
    case _9x16(forSize: CGSize)
    case _3x4(forSize: CGSize)
    case _4x3(forSize: CGSize)
    case _2x1(forSize: CGSize)
    case _1x2(forSize: CGSize)
    case twitter(forSize: CGSize)
}

extension CanvasFrameSizes {
    typealias RawValue = CGSize

    var rawValue: RawValue {
        switch self {
        case ._1x1(let frameSize):
            return CGSize.aspectFit(aspectRatio: CGSize(width: 1, height: 1), boundingSize: frameSize)
        case ._16x9(let frameSize):
            return CGSize.aspectFit(aspectRatio: CGSize(width: 16, height: 9), boundingSize: frameSize)
        case ._9x16(let frameSize):
            return CGSize.aspectFit(aspectRatio: CGSize(width: 9, height: 16), boundingSize: frameSize)
        case ._3x4(let frameSize):
            return CGSize.aspectFit(aspectRatio: CGSize(width: 3, height: 4), boundingSize: frameSize)
        case ._4x3(let frameSize):
            return CGSize.aspectFit(aspectRatio: CGSize(width: 4, height: 3), boundingSize: frameSize)
        case ._1x2(let frameSize):
            return CGSize.aspectFit(aspectRatio: CGSize(width: 1, height: 2), boundingSize: frameSize)
        case ._2x1(let frameSize):
            return CGSize.aspectFit(aspectRatio: CGSize(width: 2, height: 1), boundingSize: frameSize)
        case .twitter(let frameSize):
            return CGSize.aspectFit(aspectRatio: CGSize(width: 1280, height: 1024), boundingSize: frameSize)
        }
    }
}
