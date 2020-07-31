//
//  SKTexture+CMSampleBuffer.swift
//  SpriteKitCameraChat
//
//  Created by Nikita Dyachkov on 7/26/20.
//  Copyright © 2020 ND. All rights reserved.
//

import Foundation
import SpriteKit
import AVFoundation
import Accelerate

extension SKTexture {
    
    class func texture(with buffer: CMSampleBuffer) -> SKTexture? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(buffer) else { return nil}
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let sourceBuffr = CVPixelBufferGetBaseAddress(imageBuffer)
        let data = NSData(bytes: sourceBuffr, length: bytesPerRow * height)
        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let dimension = min(width, height)
        return SKTexture(data: data as Data, size: CGSize(width: dimension, height: dimension), flipped: true)
    }
}
