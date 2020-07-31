//
//  VideoChatController.swift
//  SpriteKitCameraChat
//
//  Created by Nikita Dyachkov on 7/25/20.
//  Copyright © 2020 ND. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class VideoChatController: UIViewController {

    var viewModel: VideoChatViewModel!
    var videoChatScene: VideoChatScene?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //viewModel shoud be injected before loading
        assert(viewModel != nil)
        guard let view = self.view as! SKView? else { return }
        configure(mainScene: view)
        viewModel.delegate = self
    }

    private func configure(mainScene: SKView) {
        // Load the SKScene from 'VideoChatScene.sks'
        let scene = VideoChatScene()
        scene.size = view.frame.size
        scene.scaleMode = .aspectFill
        videoChatScene = scene
        
        // Present the scene
        mainScene.presentScene(scene)
        mainScene.ignoresSiblingOrder = true
        mainScene.showsFPS = true
        mainScene.showsNodeCount = true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

extension VideoChatController: VideoChatViewModelDelegate {
    
    func updatedCameraTexture(_ texture: SKTexture) {
        //texture should be updated on main thread
        DispatchQueue.main.async { [weak self] in
            self?.videoChatScene?.updateCamera(texture: texture)
        }
    }
}
