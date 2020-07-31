//
//  DeviceUtility.swift
//  SpriteKitCameraChat
//
//  Created by Nikita Dyachkov on 7/26/20.
//  Copyright © 2020 ND. All rights reserved.
//

import Foundation
import AVFoundation

public final class DeviceUtility {
    
    private init() { }
    
    static public func videoDevice(withPosition: AVCaptureDevice.Position) -> AVCaptureDevice? {
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: withPosition)
    }
    
    static public func audioDevice(withPosition: AVCaptureDevice.Position) -> AVCaptureDevice? {
        return AVCaptureDevice.default(.builtInMicrophone, for: AVMediaType.audio, position: withPosition)
    }
}
