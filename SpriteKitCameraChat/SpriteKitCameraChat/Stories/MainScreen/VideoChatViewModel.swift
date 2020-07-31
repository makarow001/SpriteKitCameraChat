//
//  VideoChatViewModel.swift
//  SpriteKitCameraChat
//
//  Created by Nikita Dyachkov on 7/26/20.
//  Copyright © 2020 ND. All rights reserved.
//

import Foundation
import SpriteKit
import AVFoundation

protocol VideoChatViewModelDelegate: NSObjectProtocol {
    func updatedCameraTexture(_ texture: SKTexture)
}

protocol VideoChatViewModelProtocol {
    var delegate: VideoChatViewModelDelegate? { get set }
}

class VideoChatViewModel: NSObject {
    
    private var cameraModel: CameraModel
    weak var delegate: VideoChatViewModelDelegate?
    
    override init() {
        cameraModel = CameraModel()
        super.init()
        cameraModel.delegate = self
    }
}

extension VideoChatViewModel: CameraModelDelegate {
    
    func didUpdated(videoBuffer: CMSampleBuffer) {
        guard let texture = SKTexture.texture(with: videoBuffer) else { return }
        delegate?.updatedCameraTexture(texture)
    }
    
    func permissions(granted: Bool) {
        
    }
}
