//
//  GameViewController.swift
//  WasteSort
//
//  Created by Tucker  Cullen  on 8/13/19.
//  Copyright © 2019 Tucker  Cullen . All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {
    
    var currentGame: GameScene!
    
    @IBOutlet weak var rightX: UIImageView!
    @IBOutlet weak var centerX: UIImageView!
    @IBOutlet weak var leftX: UIImageView!
    @IBOutlet weak var scoreLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scene = GameScene(size: CGSize(width: 1080, height: 1920)) //creates a GameScene.swift, the actually sorting game
        let skView = self.view as! SKView
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.ignoresSiblingOrder = true
        scene.scaleMode = .aspectFill
        skView.presentScene(scene) // displays (and starts)
        
        currentGame = scene as GameScene
        currentGame.viewController = self
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
}
