//
//  CameraPreviewNode.swift
//  SpriteKitCameraChat
//
//  Created by Nikita Dyachkov on 7/25/20.
//  Copyright © 2020 ND. All rights reserved.
//

import Foundation
import SpriteKit
import AVFoundation

class CameraPreviewNode: SKCropNode {
    
    var sprite: SKSpriteNode? = nil
    
    convenience init(radius: CGFloat) {
        self.init()
        let mask = SKShapeNode.init(circleOfRadius: radius)
        mask.fillColor = SKColor.white
        self.maskNode = mask
        createSprite()
        sutupPhysicsBody(with: radius)
    }
    
    private func createSprite() {
        let sprite = SKSpriteNode(texture: nil)
        sprite.color = .white
        self.sprite = sprite
        if let size = maskNode?.frame.size {
            sprite.size = size
        }
        insertChild(sprite, at: 0)
    }
    
    private func sutupPhysicsBody(with radius: CGFloat) {
        physicsBody = SKPhysicsBody(circleOfRadius: radius)
        physicsBody?.affectedByGravity = false
    }
}
