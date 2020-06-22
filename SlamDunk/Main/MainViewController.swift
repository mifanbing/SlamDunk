import UIKit
import SceneKit
import ARKit

class MainViewController: UIViewController {
    
    @IBOutlet var sceneView: ARSCNView!
    var start: CGPoint?
    var end: CGPoint?
    var motherBallNode: BallNode!
    var targetBallNode: BallNode!
    let ballRadius: Float = 0.02
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(panGesture:)))
        sceneView.addGestureRecognizer(panGesture)
        
        sceneView.scene.physicsWorld.contactDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    @objc func handlePan(panGesture: UIPanGestureRecognizer) {
        let view = panGesture.view
        
        if panGesture.state == .began {
            start = panGesture.translation(in: view)
        }
        
        if panGesture.state == .ended {
            end = panGesture.translation(in: view)
            
            guard let startPoint = start, let endPoint = end else { return }
            
            guard let start3D = sceneView.hitTest(startPoint, types: .existingPlane).first,
                let end3D = sceneView.hitTest(endPoint, types: .existingPlane).first else { return }
            
            let end3DTranslation = end3D.worldTransform.columns.3
            let start3DTranslation = start3D.worldTransform.columns.3
            let startToEnd = SCNVector3(end3DTranslation.x - start3DTranslation.x,
                                        0,
                                        end3DTranslation.z - start3DTranslation.z)
            let ballDirection = startToEnd.normalized
            let speed = startToEnd.length
            motherBallNode.runAction(SCNAction.moveBy(x: CGFloat(ballDirection.x * speed * 3),
                                                      y: 0,
                                                      z: CGFloat(ballDirection.z * speed * 3),
                                                      duration: 3), forKey: ObjectCategory.motherBall.nodeName)
            motherBallNode.moved(ballSpeed: speed, ballDirection: ballDirection)
        }
    }
}

extension MainViewController: ARSCNViewDelegate {
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        setupPlane(planeAnchor: planeAnchor, node: node)
        setupMotherBall(planeAnchor: planeAnchor, node: node)
        setupTargetBall(planeAnchor: planeAnchor, node: node)
        
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }
}

extension MainViewController {
    private func setupPlane(planeAnchor: ARPlaneAnchor, node: SCNNode) {
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        let planeMaterial = SCNMaterial()
        planeMaterial.diffuse.contents = UIColor.green
        plane.materials = [planeMaterial]
        
        let planeNode = SCNNode()
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
        planeNode.position = SCNVector3(planeAnchor.center.x,
                                        0,
                                        planeAnchor.center.z)
        planeNode.geometry = plane
        
        node.addChildNode(planeNode)
        
        let wallNegtiveZ = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(ballRadius * 2))
        let wallNegativeZMaterial = SCNMaterial()
        wallNegativeZMaterial.diffuse.contents = UIColor.blue
        wallNegtiveZ.materials = [wallNegativeZMaterial]
        
        let wallNegativeZNode = SCNNode()
        wallNegativeZNode.position = SCNVector3(planeAnchor.center.x,
                                                ballRadius,
                                                planeAnchor.center.z - planeAnchor.extent.z / 2)
        wallNegativeZNode.geometry = wallNegtiveZ
        wallNegativeZNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: wallNegtiveZ, options: nil))
        wallNegativeZNode.physicsBody?.categoryBitMask = ObjectCategory.wall.categoryBit
        wallNegativeZNode.physicsBody?.contactTestBitMask = ObjectCategory.motherBall.categoryBit | ObjectCategory.targetBall.categoryBit
        wallNegativeZNode.name = ObjectCategory.wall.nodeName
        
        node.addChildNode(wallNegativeZNode)
        
        let wallPositiveZ = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(ballRadius * 2))
        let wallPositiveZMaterial = SCNMaterial()
        wallPositiveZMaterial.diffuse.contents = UIColor.blue
        wallPositiveZ.materials = [wallNegativeZMaterial]
        
        let wallPositiveZNode = SCNNode()
        wallPositiveZNode.position = SCNVector3(planeAnchor.center.x,
                                                ballRadius,
                                                planeAnchor.center.z + planeAnchor.extent.z / 2)
        wallPositiveZNode.geometry = wallPositiveZ
        wallPositiveZNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: wallPositiveZ, options: nil))
        wallPositiveZNode.physicsBody?.categoryBitMask = ObjectCategory.wall.categoryBit
        wallPositiveZNode.physicsBody?.contactTestBitMask = ObjectCategory.motherBall.categoryBit | ObjectCategory.targetBall.categoryBit
        wallPositiveZNode.name = ObjectCategory.wall.nodeName
        
        node.addChildNode(wallPositiveZNode)
        
        let wallNegtiveX = SCNPlane(width: CGFloat(planeAnchor.extent.z), height: CGFloat(ballRadius * 2))
        let wallNegativeXMaterial = SCNMaterial()
        wallNegativeXMaterial.diffuse.contents = UIColor.blue
        wallNegtiveX.materials = [wallNegativeXMaterial]
        
        let wallNegativeXNode = SCNNode()
        wallNegativeXNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 0, 1, 0)
        wallNegativeXNode.position = SCNVector3(planeAnchor.center.x - planeAnchor.extent.x / 2,
                                                ballRadius,
                                                planeAnchor.center.z)
        
        wallNegativeXNode.geometry = wallNegtiveX
        wallNegativeXNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: wallNegtiveX, options: nil))
        wallNegativeXNode.physicsBody?.categoryBitMask = ObjectCategory.wall.categoryBit
        wallNegativeXNode.physicsBody?.contactTestBitMask = ObjectCategory.motherBall.categoryBit | ObjectCategory.targetBall.categoryBit
        wallNegativeXNode.name = ObjectCategory.wall.nodeName
        
        node.addChildNode(wallNegativeXNode)
        
        let wallPositiveX = SCNPlane(width: CGFloat(planeAnchor.extent.z), height: CGFloat(ballRadius * 2))
        let wallPositiveXMaterial = SCNMaterial()
        wallPositiveXMaterial.diffuse.contents = UIColor.blue
        wallPositiveX.materials = [wallPositiveXMaterial]
        
        let wallPositiveXNode = SCNNode()
        wallPositiveXNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 0, 1, 0)
        wallPositiveXNode.position = SCNVector3(planeAnchor.center.x + planeAnchor.extent.x / 2,
                                                ballRadius,
                                                planeAnchor.center.z)
        wallPositiveXNode.geometry = wallPositiveX
        wallPositiveXNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: wallPositiveX, options: nil))
        wallPositiveXNode.physicsBody?.categoryBitMask = ObjectCategory.wall.categoryBit
        wallPositiveXNode.physicsBody?.contactTestBitMask = ObjectCategory.motherBall.categoryBit | ObjectCategory.targetBall.categoryBit
        wallPositiveXNode.name = ObjectCategory.wall.nodeName
        
        node.addChildNode(wallPositiveXNode)
    }
    
    private func setupMotherBall(planeAnchor: ARPlaneAnchor, node: SCNNode) {
        let motherBall = SCNSphere(radius: CGFloat(ballRadius))
        let ballMaterial = SCNMaterial()
        ballMaterial.diffuse.contents = UIColor.red
        motherBall.materials = [ballMaterial]
        
        motherBallNode = BallNode()
        motherBallNode.position = SCNVector3(planeAnchor.center.x, ballRadius, planeAnchor.center.z)
        motherBallNode.geometry = motherBall
        motherBallNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: motherBall, options: nil))
        motherBallNode.physicsBody?.categoryBitMask = ObjectCategory.motherBall.categoryBit
        motherBallNode.physicsBody?.contactTestBitMask = ObjectCategory.wall.categoryBit | ObjectCategory.targetBall.categoryBit
        motherBallNode.name = ObjectCategory.motherBall.nodeName
        
        node.addChildNode(motherBallNode)
    }
    
    private func setupTargetBall(planeAnchor: ARPlaneAnchor, node: SCNNode) {
        let targetBall = SCNSphere(radius: CGFloat(ballRadius))
        let targetBallMaterial = SCNMaterial()
        targetBallMaterial.diffuse.contents = UIColor.yellow
        targetBall.materials = [targetBallMaterial]
        
        targetBallNode = BallNode()
        targetBallNode.position = SCNVector3(planeAnchor.center.x + 0.1, ballRadius, planeAnchor.center.z)
        targetBallNode.geometry = targetBall
        targetBallNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: targetBall, options: nil))
        targetBallNode.physicsBody?.categoryBitMask = ObjectCategory.targetBall.categoryBit
        targetBallNode.physicsBody?.contactTestBitMask = ObjectCategory.wall.categoryBit | ObjectCategory.motherBall.categoryBit
        targetBallNode.name = ObjectCategory.targetBall.nodeName
        
        node.addChildNode(targetBallNode)
    }
}

extension MainViewController: SCNPhysicsContactDelegate {
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        //Ball hits the wall
        if contact.nodeA.name == ObjectCategory.wall.nodeName || contact.nodeA.name == ObjectCategory.wall.nodeName {
            ballHitsWall(contact: contact)
            return
        }
        
        //ball hits ball
        if contact.nodeA.name == ObjectCategory.motherBall.nodeName || contact.nodeA.name == ObjectCategory.motherBall.nodeName {
            ballHitsBall(contact: contact)
            return
        }
    }
    
    private func ballHitsWall(contact: SCNPhysicsContact) {
        var ballNode: BallNode!
        
        if contact.nodeA.name == ObjectCategory.motherBall.nodeName || contact.nodeA.name == ObjectCategory.targetBall.nodeName {
            ballNode = (contact.nodeA as! BallNode)
        }
        
        if contact.nodeB.name == ObjectCategory.motherBall.nodeName || contact.nodeB.name == ObjectCategory.targetBall.nodeName {
            ballNode = (contact.nodeB as! BallNode)
        }
        
        ballNode.removeAction(forKey: ballNode.name!)
        guard ballNode.ballSpeed > 0.01 else { return }
        ballNode.ballSpeed = ballNode.ballSpeed / 2
        
        let normal = contact.contactNormal.xzPlane
        
        let normalComponent = ballNode.ballDirection.normalComponent(wrt: normal)
        let tangentCompoent = ballNode.ballDirection.tangentComponent(wrt: normal)
        let reflectedBallDirection = SCNVector3(tangentCompoent.x - normalComponent.x,
                                                0,
                                                tangentCompoent.z - normalComponent.z)
        
        ballNode.runAction(SCNAction.moveBy(x: CGFloat(reflectedBallDirection.x * ballNode.ballSpeed * 3),
                                            y: 0,
                                            z: CGFloat(reflectedBallDirection.z * ballNode.ballSpeed * 3),
                                            duration: 3), forKey: ballNode.name!)
}
    
    private func ballHitsBall(contact: SCNPhysicsContact) {
        let ballNodeA = (contact.nodeA as! BallNode)
        let ballNodeB = (contact.nodeB as! BallNode)
        
        if ballNodeA.actionKeys.contains(ballNodeA.name!) {
            ballNodeA.removeAction(forKey: ballNodeA.name!)
        }
        if ballNodeB.actionKeys.contains(ballNodeB.name!) {
            ballNodeB.removeAction(forKey: ballNodeB.name!)
        }
        
        let normal = contact.contactNormal.xzPlane

        if ballNodeA.ballSpeed == 0 {
            ballNodeA.ballDirection = normal.dot(vector: ballNodeB.ballDirection) > 0 ? normal : normal.negative
        }
        if ballNodeB.ballSpeed == 0 {
            ballNodeB.ballDirection = normal.dot(vector: ballNodeA.ballDirection) > 0 ? normal : normal.negative
        }
        
        let normalComponentA = ballNodeA.ballDirection.normalComponent(wrt: normal)
        let tangentCompoentA = ballNodeA.ballDirection.tangentComponent(wrt: normal)
        let normalComponentB = ballNodeB.ballDirection.normalComponent(wrt: normal)
        let tangentCompoentB = ballNodeB.ballDirection.tangentComponent(wrt: normal)
        
        let normalComponentAfter = SCNVector3((normalComponentA.x * ballNodeA.ballSpeed + normalComponentB.x * ballNodeB.ballSpeed) / 2,
                                              0,
                                              (normalComponentA.z * ballNodeA.ballSpeed + normalComponentB.z * ballNodeB.ballSpeed) / 2)
        
        let reflectedBallAVelocity = SCNVector3(tangentCompoentA.x * ballNodeA.ballSpeed + normalComponentAfter.x,
                                                0,
                                                tangentCompoentA.z * ballNodeA.ballSpeed + normalComponentAfter.z)
        if reflectedBallAVelocity.length > 0.01 {
            ballNodeA.ballSpeed = reflectedBallAVelocity.length
            ballNodeA.runAction(SCNAction.moveBy(x: CGFloat(reflectedBallAVelocity.x * 3),
                                                 y: 0,
                                                 z: CGFloat(reflectedBallAVelocity.z * 3),
                                                 duration: 3), forKey: ballNodeA.name!)
        }
              
        let reflectedBallBVelocity = SCNVector3(tangentCompoentB.x * ballNodeB.ballSpeed + normalComponentAfter.x,
                                                0,
                                                tangentCompoentB.z * ballNodeB.ballSpeed + normalComponentAfter.z)
        if reflectedBallBVelocity.length > 0.01 {
            ballNodeB.ballSpeed = reflectedBallBVelocity.length
            ballNodeB.runAction(SCNAction.moveBy(x: CGFloat(reflectedBallBVelocity.x * 3),
                                                 y: 0,
                                                 z: CGFloat(reflectedBallBVelocity.z * 3),
                                                 duration: 3), forKey: ballNodeB.name!)
        }
    }

}