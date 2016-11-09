//
//  GameScene.swift
//  iTrials
//
//  Created by student on 11/6/16.
//  Copyright © 2016 student. All rights reserved.
//

import SpriteKit
import GameplayKit

struct PhysicsCategory {
    static let None: UInt32 = 0
    static let Cat: UInt32 = 0b1 // 1
    static let Block: UInt32 = 0b10 // 2
    static let Bed: UInt32 = 0b100 // 4
    static let Edge: UInt32 = 0b1000 // 8
    static let Label: UInt32 = 0b10000 // 16
}

struct GameLayer {
    static let background: CGFloat = 0
    static let hud       : CGFloat = 1
    static let sprite    : CGFloat = 2
    static let message   : CGFloat = 3
}

class GameScene: SKScene,UIGestureRecognizerDelegate {
    
    var levelNum:Int = 1
    var sceneManager:SceneManager = GameViewController()
    var spritesMoving:Bool = false
    var gameLoopPaused:Bool = true{
        didSet{
            print("gameLoopPaused=\(gameLoopPaused)")
            gameLoopPaused ? runPauseAction() : runUnpauseAction()
        }
    }
    var lastUpdateTime:TimeInterval = 0
    var dt:TimeInterval = 0
    
    var gasDown:Bool = false
    var brakeDown:Bool = false
    
    var carNode:CarNode!
    
    var playableRect:CGRect!
    
    // MARK: - Initialization -
    class func loadLevel(_ levelNum: Int, size: CGSize, scaleMode:SKSceneScaleMode, totalScore: Int, sceneManager:SceneManager) -> GameScene?{
        
        let scene = GameScene(fileNamed: "Level\(levelNum)")!
        scene.levelNum = levelNum
        scene.size = size
        scene.scaleMode = scaleMode
        scene.sceneManager = sceneManager
        return scene
    }
    
    override func didMove(to view: SKView) {
        // Calculate playable margin
        let maxAspectRatio: CGFloat = 16.0/9.0
        let maxAspectRatioHeight = size.width / maxAspectRatio
        let playableMargin: CGFloat = (size.height
            - maxAspectRatioHeight)/2
        playableRect = CGRect(x: 0, y: playableMargin,
                                  width: size.width, height: size.height-playableMargin*2)
        
        carNode = childNode(withName: "//carBody") as! CarNode
        carNode.didMoveToScene()
        setupUI()
        setupSpritesAndPhysics()
    }
    
    func touchDown(atPoint pos : CGPoint) {
    }
    
    func touchMoved(toPoint pos : CGPoint) {
    }
    
    func touchUp(atPoint pos : CGPoint) {
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        calculateDeltaTime(currentTime: currentTime)
        
        guard spritesMoving else{
            return
        }
    }
    
    // MARK: - Pause/Unpause -
    private func runPauseAction(){
        physicsWorld.speed = 0.0
        spritesMoving = false
        
        let fadeAction = SKAction.customAction(withDuration: 0.25,
            actionBlock:{
                node, elapsedTime in
                let totalAnimationTime:CGFloat = 0.5
                let percentDone = elapsedTime/totalAnimationTime
                let amountToFade:CGFloat = 0.5
                node.alpha = 1.0 - (percentDone * amountToFade)
            })
        
        let pauseAction = SKAction.run({
            self.view?.isPaused = true
        })
        
        let pauseViewAfterFadeAction = SKAction.sequence([
            fadeAction,
            pauseAction])
        
        run(pauseViewAfterFadeAction)
    }
    
    private func runUnpauseAction(){
        print(#function)
        view?.isPaused = false // resumes actions and update()
        lastUpdateTime = 0
        dt = 0
        spritesMoving = false // needed if called by Notification
        
        let unPauseAction = SKAction.sequence([
            SKAction.fadeIn(withDuration: 1.0),
            SKAction.run({
                self.physicsWorld.speed = 1.0 // resumes physics
                self.spritesMoving = true
            })
            ])
        unPauseAction.timingMode = .easeIn
        run(unPauseAction)
    }
    
    //MARK: - Helpers -
    private func calculateDeltaTime(currentTime: TimeInterval){
        
        if lastUpdateTime > 0{
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime
    }
    
    private func setupUI(){
        let gasSprite = SKSpriteNode(imageNamed: "GasPedal")
        gasSprite.xScale = 1.5
        gasSprite.yScale = 1.5
        let brakeSprite = SKSpriteNode(imageNamed: "BrakePedal")
        brakeSprite.xScale = 1.5
        brakeSprite.yScale = 1.5
        
        let gasButton = Button(gasSprite)
        let brakeButton = Button(brakeSprite)
        
        //this will need to change to adapt to the origin of the scene later
        gasButton.position = CGPoint(x: size.width/2-gasSprite.size.width, y: (-size.height/2) + (gasSprite.size.height/2))
        brakeButton.position = CGPoint(x: (-size.width/2)+brakeSprite.size.width, y: (-size.height/2) + (brakeSprite.size.height/2))
        
        gasButton.pressAnimation = SKAction.setTexture(SKTexture(imageNamed: "GasPedalPressed"))
        brakeButton.pressAnimation = SKAction.setTexture(SKTexture(imageNamed: "BrakePedalPressed"))
        
        gasButton.releaseAnimation = SKAction.setTexture(SKTexture(imageNamed: "GasPedal"))
        brakeButton.releaseAnimation = SKAction.setTexture(SKTexture(imageNamed: "BrakePedal"))
        
        gasButton.subscribeToPress(funcName: "onGasPressed", callback: onGasPressed)
        brakeButton.subscribeToPress(funcName: "onBrakePressed", callback: onBrakePressed)
        
        gasButton.subscribeToRelease(funcName: "onGasReleased", callback: onGasReleased)
        brakeButton.subscribeToRelease(funcName: "onBrakeReleased", callback: onBrakeReleased)
        
        addChild(gasButton)
        addChild(brakeButton)
    }
    
    private func onGasPressed() {
        gasDown = true
        print("GO!")
    }
    
    private func onGasReleased() {
        gasDown = false
        print("Gas Released")
    }
    
    private func onBrakePressed() {
        brakeDown = true
        print("STOP!")
    }
    
    private func onBrakeReleased() {
        brakeDown = false
        print("Brake Released")
    }
    
    private func setupSpritesAndPhysics(){
        
    }
}
