//
//  GameScene.swift
//  WasteSort
//
//  Created by Tucker  Cullen  on 8/13/19.
//  Copyright © 2019 Tucker  Cullen . All rights reserved.
//

import SpriteKit

struct PhysicsCategory {
    static let none   : UInt32 = 0
    static let all    : UInt32 = UInt32.max
    static let item   : UInt32 = 0b1       // 1
    static let destroy: UInt32 = 0b10      // 2
}

//can this go within the class?? test later
var compostList: [Int] = [2, 3, 7, 13, 16, 28]
var trashList: [Int] = [15,18,20,21,22,24,25,26,27,29,31]
var recycleList: [Int] = [0,1,5,6,8,9,10,14,17,23,28,32]
var electricList: [Int] = [4, 11, 12, 19, 30]


enum SequenceType: CaseIterable { // what does this do?? from bryan's code
    case one //, chain, fastChain
}


class GameScene: SKScene, SKPhysicsContactDelegate {
    
    weak var viewController: GameViewController!
    
    // Setup nodes for waste bins
    let trashBottom = SKSpriteNode(imageNamed: "trashBottom")
    let electricBottom = SKSpriteNode(imageNamed: "electricBottom")
    let compostBottom = SKSpriteNode(imageNamed: "compostBottom")
    let recyclingBottom = SKSpriteNode(imageNamed: "recyclingBottom")
    
    //top covers for waste bins
    let recyclingTop = SKSpriteNode(imageNamed: "recyclingTop")
    let electricTop = SKSpriteNode(imageNamed: "electricTop")
    let compostTop = SKSpriteNode(imageNamed: "compostTop")
    let trashTop = SKSpriteNode(imageNamed: "trashTop")
    
    let maxItemNumber = 27 // largest waste item number, assests are numbered 1 - 27

    //Physics constants
    let gravity: CGFloat = -4.8
    let physicsSpeed: CGFloat = 0.90
    
    /// List of all the items currently in the scene
    var activeItems = [SKSpriteNode]()
    
    // varibles to setup touching interactions
    var touchpoint: CGPoint = CGPoint()
    var touching: Bool = false
    var movingItem = SKSpriteNode()
    
    /// is false when game is going on, turns to true once you run out of lives
    var gameEnded = false
    
    // Setting up the sequence of item tosses
    var popupTime = 3.0
    var chainDelay = 4.0
    var sequencePosition = 0
    var nextSequenceQueued = true
    var sequence: [SequenceType]!
    
    //Nodes at the base of each bin that destroy objects
    let compostDestroy = SKSpriteNode(color: .red, size: CGSize(width: 300, height: 15))
    let recycleDestroy = SKSpriteNode(color: .red, size: CGSize(width: 300, height: 15))
    let trashDestroy = SKSpriteNode(color: .red, size: CGSize(width: 300, height: 15))
    let electricDestroy = SKSpriteNode(color: .red, size: CGSize(width: 300, height: 15))
    
    //Guide lines inside each bin that guide item down to destroy lines
    let recycleGuideUp = SKSpriteNode(color: .blue, size: CGSize(width: 15, height: 300))
    let recycleGuideDown = SKSpriteNode(color: .blue, size: CGSize(width: 15, height: 300))
    let compostGuideUp = SKSpriteNode(color: .blue, size: CGSize(width: 15, height: 300))
    let compostGuideDown = SKSpriteNode(color: .blue, size: CGSize(width: 15, height: 300))
    let electricGuideUp = SKSpriteNode(color: .blue, size: CGSize(width: 15, height: 300))
    let electricGuideDown = SKSpriteNode(color: .blue, size: CGSize(width: 15, height: 300))
    let trashGuideUp = SKSpriteNode(color: .blue, size: CGSize(width: 15, height: 300))
    let trashGuideDown = SKSpriteNode(color: .blue, size: CGSize(width: 15, height: 300))

    //Setup the score
    var scoreLabel: SKLabelNode!
    var score = 0 {
        didSet {
            viewController.scoreLabel.text = "Score: \(score)"
        }
    }
    
    //Setup lives
    var livesImages = [SKSpriteNode]()
    var lives = 3
    let outerBoundary: CGFloat = 400.0 // a live is lost if an item falls past this point
    
    //Setup menu
    var menuLabel: SKLabelNode!
    var menuUp: Bool = false {
        didSet {
            if menuUp {
                menuLabel.text = "Done"
            } else {
                menuLabel.text = "Menu"
            }
        }
    }
    

    override func didMove(to view: SKView) {
        
        setUpPhysics()
        setBackground()
        placeBins()
        setupLines()
        createMenuButton()
        
        //Background music
        let backgroundSound = SKAudioNode(fileNamed: "mainmusic.mp3") 
        self.addChild(backgroundSound)
        
        sequence = [.one, .one, .one]
        for _ in 0 ... 1000 {
            let nextSequence = SequenceType.allCases.randomElement()!
            sequence.append(nextSequence)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [unowned self] in
            self.tossItems()
        }
    }
    
    
    /// Sets up the wood background image
    func setBackground (){
        
        let background = SKSpriteNode(imageNamed: "woodBackground")
        background.size = self.frame.size
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.blendMode = .replace //told to include this in hacking with swift tutorial, more effecient?
        background.zPosition = -1
        addChild(background)
    }
    
    /// Places the various bins in the scene
    func placeBins() {
        
        recyclingBottom.position = CGPoint(x: size.width - 100, y: size.height * 0.50)
        recyclingBottom.zRotation = 0.925 //53 degrees in radians
        recyclingBottom.zPosition = 0
        addChild(recyclingBottom)
        topPlacement(topBin: recyclingTop, bottomBin: recyclingBottom, xAdjust: 29.99, yAdjust: -27.4) //positions the top cover for the recycle bin
        
        electricBottom.position = CGPoint(x: size.width - 110, y: size.height * 0.1)
        electricBottom.zRotation = 0.925 //53 degrees in radians
        electricBottom.zPosition = 0
        electricBottom.xScale = 0.5
        electricBottom.yScale = 0.5
        addChild(electricBottom)
        electricTop.xScale = 0.5
        electricTop.yScale = 0.5
        topPlacement(topBin: electricTop, bottomBin: electricBottom, xAdjust: 0, yAdjust: 0)
        
        compostBottom.position = CGPoint(x: size.width - size.width + 110, y: size.height * 0.1)
        compostBottom.zRotation = 5.35 // 307 degrees in radians (aka -53 degrees in radians)
        compostBottom.zPosition = 0
        addChild(compostBottom)
        topPlacement(topBin: compostTop, bottomBin: compostBottom, xAdjust: -25.133, yAdjust: -24.261)
        
        trashBottom.position = CGPoint(x: size.width - size.width + 80, y: size.height * 0.5)
        trashBottom.zRotation = 5.35 // 307 degrees in radians (aka -53 degrees in radians)
        trashBottom.zPosition = 0
        addChild(trashBottom)
        topPlacement(topBin: trashTop, bottomBin: trashBottom, xAdjust: -8.215, yAdjust: -2.104)
        
    }
    
    /// sets up the top covering for a bin
    func topPlacement(topBin: SKSpriteNode, bottomBin: SKSpriteNode, xAdjust: CGFloat, yAdjust: CGFloat){
        
        topBin.position = CGPoint(x: bottomBin.position.x + xAdjust, y: bottomBin.position.y + yAdjust)
        topBin.zRotation = bottomBin.zRotation
        topBin.zPosition = 2
        addChild(topBin)
    }
    
    
    func setupLines() {
        
        
        //Recycling bin lines
        drawDestructionLines(line: recycleDestroy, bottomBin: recyclingBottom, xAdjust: 110, yAdjust: 60, name: "recycleDestroy")
        drawGuideLines(line: recycleGuideUp, bottomBin: recyclingBottom, xAdjust: -95, yAdjust: -120)
        drawGuideLines(line: recycleGuideDown, bottomBin: recyclingBottom, xAdjust: 95, yAdjust: 120)
        
        //electric bin lines
        drawDestructionLines(line: electricDestroy, bottomBin: electricBottom, xAdjust: 110, yAdjust: 60, name: "electricDestroy")
        drawGuideLines(line: electricGuideUp, bottomBin: electricBottom, xAdjust: -95, yAdjust: -120)
        drawGuideLines(line: electricGuideDown, bottomBin: electricBottom, xAdjust: 95, yAdjust: 120)
        
        //compost bin lines
        drawDestructionLines(line: compostDestroy, bottomBin: compostBottom, xAdjust: -110, yAdjust: 60, name: "compostDestroy")
        drawGuideLines(line: compostGuideUp, bottomBin: compostBottom, xAdjust: 95, yAdjust: -120)
        drawGuideLines(line: compostGuideDown, bottomBin: compostBottom, xAdjust: -95, yAdjust: 120)
        
        //trash bin lines
        drawDestructionLines(line: trashDestroy, bottomBin: trashBottom, xAdjust: -110, yAdjust: 60, name: "trashDestroy")
        drawGuideLines(line: trashGuideUp, bottomBin: trashBottom, xAdjust: 95, yAdjust: -120)
        drawGuideLines(line: trashGuideDown, bottomBin: trashBottom, xAdjust: -95, yAdjust: 120)
        
       
    }
    
    /// setups the phyics lines at the bottom of each bin that destroy the items when a collision occurs
    func drawDestructionLines(line: SKSpriteNode, bottomBin: SKSpriteNode, xAdjust: CGFloat, yAdjust: CGFloat, name: String){
        
        line.position = CGPoint(x: bottomBin.position.x+xAdjust, y: bottomBin.position.y-yAdjust )
        line.zRotation = bottomBin.zRotation
        line.zPosition = 1
        line.physicsBody = SKPhysicsBody(rectangleOf: line.size)
        line.physicsBody?.isDynamic = false
        line.physicsBody!.contactTestBitMask = PhysicsCategory.destroy
        line.physicsBody!.collisionBitMask = PhysicsCategory.item
        line.name = name
        addChild(line)
        
    }
    
    /// Sets up phyisics lines that guide the items into the bins
    func drawGuideLines(line: SKSpriteNode, bottomBin: SKSpriteNode, xAdjust: CGFloat, yAdjust: CGFloat) {
        
        line.position = CGPoint(x: bottomBin.position.x+xAdjust, y: bottomBin.position.y+yAdjust )
        line.zRotation = bottomBin.zRotation
        line.zPosition = 1
        line.physicsBody = SKPhysicsBody(rectangleOf: line.size)
        line.physicsBody?.isDynamic = false
        line.name = "guidingLine"
        addChild(line)

    }
    
    /// Sets up general physics properties for the scene
    func setUpPhysics() {
        
        physicsWorld.gravity = CGVector(dx: 0, dy: gravity)
        physicsWorld.speed = physicsSpeed
        physicsWorld.contactDelegate = self
    }
    
    /// creates an item randomly and sets up all node and physics properties, also labels the item
    func setupItem() {
        
        let itemType = Int.random(in: 0..<maxItemNumber) //randomly chooses the item to create
        let imageName = "item\(itemType)"
        let item: SKSpriteNode = SKSpriteNode(imageNamed: imageName)
        item.zPosition = 1
        
        //Scale the sprite to the correct size
        item.scale(to: CGSize(width: 200, height: 200*item.size.height/item.size.width))
        if(item.size.height > 280) {
            item.scale(to: CGSize(width: 125, height: 125*item.size.height/item.size.width))
        }
        if(item.size.height < 180 && item.size.width < 180) {
            item.scale(to: CGSize(width: item.size.width*1.5, height: item.size.width*1.5))
        }
        
        /// determine where to create the item
        let randomPosition = CGPoint(x: CGFloat.random(in: size.width/10...9*size.width/10), y: size.height+70)
        item.position = randomPosition
        
        /// Generate Velocities for the item
        
        //Angular velocity
        let randomAngularVelocity = CGFloat.random(in: -6...6) / 2.0 //angualr velocity
        
        // X velocity
        var randomXVelocity = 0 //initialize variable
        if randomPosition.x < size.width/4 {   // not sure why this is necessary, copied from bryan's code
            randomXVelocity = Int.random(in: 8...15)
        } else if randomPosition.x < 2*size.width/4 {
            randomXVelocity = Int.random(in: 3...5)
        } else if randomPosition.x < 3*size.width/4 {
            randomXVelocity = -Int.random(in: 3...5)
        } else {
            randomXVelocity = -Int.random(in: 8...15)
        }
        
        // Y Velocity
        let randomYVelocity = 0
        
        // set up physics body for item
        item.physicsBody = SKPhysicsBody(rectangleOf: item.size) // sets shape of physics body
        item.physicsBody?.velocity = CGVector(dx: randomXVelocity * 40, dy: randomYVelocity * 40)
        item.physicsBody?.angularVelocity = randomAngularVelocity
                    //item.physicsBody?.collisionBitMask = 0x01
        item.physicsBody!.contactTestBitMask = PhysicsCategory.item
        item.physicsBody!.collisionBitMask = PhysicsCategory.destroy
        item.physicsBody?.restitution = 0.4
        
        // TODO: change to dictionary will allow item.name = trashMap[itemType]
        // label the item that has been created
        if(compostList.contains(itemType)) {
            item.name = "compost"
        } else if(trashList.contains(itemType)) {
            item.name = "trash"
        } else if(recycleList.contains(itemType)) {
            item.name = "recycle"
        } else if(electricList.contains(itemType)) {
            item.name = "electric"
        }
        
        //add the item to the scene
        addChild(item)
        activeItems.append(item) // add the item to the list of active items
    }
    
    
    ///  what happens when an item needs to be destroyed
    func destroy(item: SKNode, successfully: Bool) {
        if let fireParticles = SKEmitterNode(fileNamed: "FireParticles") {
            fireParticles.position = item.position
            addChild(fireParticles)
            fireParticles.run(
                SKAction.sequence([
                    SKAction.wait(forDuration: 2.0),
                    SKAction.removeFromParent()
                    ])
                )
        }
        item.removeFromParent()
    }
    
    
    /// should be called when an item is touched
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if let touch = touches.first {
            let location = touch.location(in: self)
            for item in activeItems {
                if item.frame.contains(location) {
                    touching = true
                    touchpoint = location
                    movingItem = item
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        touchpoint = location
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touching = false
    }
    

    
    /// Releases an item onto the screen
    func tossItems() {
        
        if gameEnded {
            return
        }
        popupTime *= 0.991
        chainDelay *= 0.999
        physicsWorld.speed *= 1.001
        
        let sequenceType = sequence![sequencePosition]
        
     switch sequenceType {
        case .one:
            setupItem()
        }
        
        sequencePosition += 1
        nextSequenceQueued = false
        
    }

    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else {return}
        guard let nodeB = contact.bodyB.node else {return}
        
        if let name = contact.bodyA.node?.name {
            if name.count < 10 {
                collisionBetween(item: nodeA, object: nodeB)
                return
            } else {
            }
        }
        if let name = contact.bodyB.node?.name {
            if name.count < 10 {
                collisionBetween(item: nodeB, object: nodeA)
            } else {
                return
            }
        }
    }

    
    /// Determines if there was a collision between
    func collisionBetween( item: SKNode, object: SKNode ){
        
        var match = false
        switch object.name { //test to see if item was placed in correct bin
        case "trashDestroy":
            if item.name == "trash" {
                match = true
                destroy(item: item, successfully: match)
                score += 1
                //scoreLabel.text = "Score: \(score)"
            }
            else {
                subtractLife()
            }
        case "compostDestroy":
            if item.name == "compost" {
                match = true
                destroy(item: item, successfully: match)
                score += 1

            }
            else {
                subtractLife()
            }
        case "recycleDestroy":
            if item.name == "recycle" {
                match = true
                destroy(item: item, successfully: match)
                score += 1
                
            }
            else {
                subtractLife()
            }
        case "electricDestroy":
            if item.name == "electric" {
                match = true
                destroy(item: item, successfully: match)
                score += 1
            }
            else {
                subtractLife()
            }
        default:
            return
        }
        
        destroy(item: item, successfully: match)
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        // Allows user to "grab" an item with a touch
        if touching {
            let dt:CGFloat = 1.0/60.0
            let distance = CGVector(dx: touchpoint.x-movingItem.position.x, dy: touchpoint.y-movingItem.position.y)
            let velocity = CGVector(dx: distance.dx/dt*3/4, dy: distance.dy/dt*3/4)
            movingItem.physicsBody!.velocity=velocity
        }
        
        for node in activeItems {
            if node.position.y < -outerBoundary || node.position.x < -outerBoundary || node.position.x > size.width + outerBoundary {
                
                node.removeAllActions()
                node.name = ""
                subtractLife()
                
                node.removeFromParent()
                
                if let index = activeItems.firstIndex(of: node) {
                    activeItems.remove(at: index)
                }
            }
        }
        
        // keeps the items continually tossed
        if !nextSequenceQueued {
            DispatchQueue.main.asyncAfter(deadline: .now() + popupTime) { [unowned self] in
                self.tossItems()
            }
            nextSequenceQueued = true
        }
        
    }
    
    func subtractLife() {
        lives -= 1
        
        
        var life: UIImageView
        
        if lives == 2 {
            life = viewController.rightX
        } else if lives == 1 {
            life = viewController.centerX
        } else {
            life = viewController.leftX
            endGame()
        }
        life.image = UIImage(named: "sliceLifeGone")
    }
    
    
    func createMenuButton() {
        menuLabel = SKLabelNode(fontNamed: "Chalkduster")
        menuLabel.text = "Menu"
        menuLabel.position = CGPoint(x: 100, y: size.height-200)
        menuLabel.horizontalAlignmentMode = .left
        menuLabel.fontSize = 50
        addChild(menuLabel)
    }
    
    func endGame() {
        
        if gameEnded {
            return
        }
        
        gameEnded = true
        physicsWorld.speed = 0
        isUserInteractionEnabled = false
        
    }
  
}


