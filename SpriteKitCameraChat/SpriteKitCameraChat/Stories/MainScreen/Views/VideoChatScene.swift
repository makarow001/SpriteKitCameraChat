//
//  VideoChatScene.swift
//  SpriteKitCameraChat
//
//  Created by Nikita Dyachkov on 7/25/20.
//  Copyright © 2020 ND. All rights reserved.
//

import SpriteKit
import GameplayKit
import AVFoundation

protocol VideoChatSceneProtocol {
    func updateCamera(texture: SKTexture)
}

class VideoChatScene: SKScene, VideoChatSceneProtocol {
    
    private var cameraNode: CameraPreviewNode!
    private var redCircle: SKShapeNode?
    static var circleRadius: CGFloat = 70

    override func didMove(to view: SKView) {
        createSceneContents()
        addCamera()
        addRedCircle()
    }
    
    func updateCamera(texture: SKTexture) {
        cameraNode.sprite?.texture = texture
    }
    
    private func addRedCircle() {
        let circleNode = SKShapeNode(circleOfRadius: VideoChatScene.circleRadius)
        circleNode.fillColor = .red
        circleNode.physicsBody = circleGravityBody(with: VideoChatScene.circleRadius)
        addChild(circleNode)
        circleNode.position = CGPoint(x: frame.midX, y: frame.midY)
        redCircle = circleNode
    }

    private func addCamera() {
        cameraNode = CameraPreviewNode(radius: VideoChatScene.circleRadius)
        addChild(cameraNode)
    }

    private func circleGravityBody(with radius: CGFloat) -> SKPhysicsBody {
        let body = SKPhysicsBody(circleOfRadius: radius)
        body.affectedByGravity = false
        return body
    }

    func createSceneContents() {
        self.backgroundColor = .black
        self.scaleMode = .aspectFit
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
    }

    func touchDown(atPoint pos : CGPoint) {
        cameraNode.run(SKAction.move(to: pos, duration: 0.2))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }

    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
