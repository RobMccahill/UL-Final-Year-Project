//
//  ARLocalizedNavigationViewController.swift
//  UL Navigation FYP
//
//  Created by Robert Mccahill on 26/02/2018.
//

import Foundation
import ARKit
import Vision

class ARQRViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, AVCaptureMetadataOutputObjectsDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var sessionInfoLabel: UILabel!
    @IBOutlet var sessionInfoView: UIVisualEffectView!
    
    
    var processing = false
    var qrCodeFound = false
    let height = Float(-1.5)
    var detectedDataAnchor: ARAnchor?
    var currentFrame : ARFrame?
    var qrFoundCount = 0
    
    override func viewDidAppear(_ animated: Bool) {
        
        let configuration = ARWorldTrackingConfiguration()
        if #available(iOS 11.3, *) {
            configuration.planeDetection = [.horizontal, .vertical]
        } else {
            configuration.planeDetection = .horizontal
        }
        
        configuration.isLightEstimationEnabled = true;
        configuration.worldAlignment = .gravity
        
        sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints
        sceneView.session.run(configuration)
        
        // Set a delegate to track the number of plane anchors for providing UI feedback.
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        /*
         Prevent the screen from being dimmed after a while as users will likely
         have long periods of interaction without touching the screen or buttons.
         */
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Show debug UI to view performance metrics (e.g. frames per second).
        sceneView.showsStatistics = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's AR session.
        sceneView.session.pause()
    }
    
//    /// - Tag: PlaceARContent
//    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
//        // Place content only for anchors found by plane detection.
//        if let planeAnchor = anchor as? ARPlaneAnchor {
//            // Create a SceneKit plane to visualize the plane anchor using its position and extent.
//            let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
//            let planeNode = SCNNode(geometry: plane)
//            planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
//
//            // `SCNPlane` is vertically oriented in its local coordinate space, so
//            // rotate the plane to match the horizontal orientation of `ARPlaneAnchor`.
//            planeNode.eulerAngles.x = -.pi / 2
//
//            // Make the plane visualization semitransparent to clearly show real-world placement.
//            planeNode.opacity = 0.25
//
//            // Add the plane visualization to the ARKit-managed node so that it tracks
//            // changes in the plane anchor as plane estimation continues.
//            node.addChildNode(planeNode)
//        }
//        else if self.detectedDataAnchor?.identifier == anchor.identifier {
//            let qrGeometry = SCNBox(width: 05, height: 0.05, length: 0.01, chamferRadius: 0)
//            qrGeometry.firstMaterial?.diffuse.contents = UIColor.red.withAlphaComponent(0.5)
//            let qrNode = SCNNode(geometry: qrGeometry)
//
//            // Set its position based off the anchor
//            qrNode.transform = SCNMatrix4(anchor.transform)
//
//            node.addChildNode(qrNode)
//        }
//
//
//    }
//
//    /// - Tag: UpdateARContent
//    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
//        // Update content only for plane anchors and nodes matching the setup created in `renderer(_:didAdd:for:)`.
//        if let planeAnchor = anchor as? ARPlaneAnchor,
//            let planeNode = node.childNodes.first,
//            let plane = planeNode.geometry as? SCNPlane {
//
//            // Plane estimation may shift the center of a plane relative to its anchor's transform.
//            planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
//
//            // Plane estimation may also extend planes, or remove one plane to merge its extent into another.
//            plane.width = CGFloat(planeAnchor.extent.x)
//            plane.height = CGFloat(planeAnchor.extent.z)
//        }
//    }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {

        // If this is our anchor, create a node
        if self.detectedDataAnchor?.identifier == anchor.identifier {

            let qrGeometry = SCNBox(width: 0.05, height: 0.05, length: 0.01, chamferRadius: 0)
            qrGeometry.firstMaterial?.diffuse.contents = UIColor.red.withAlphaComponent(0.5)
            let qrNode = SCNNode(geometry: qrGeometry)

            // Set its position based off the anchor
            qrNode.transform = SCNMatrix4(anchor.transform)

            return qrNode
        } else {
          return nil
        }
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        // Only run one Vision request at a time
        if self.processing {
            return
        }
        
        self.processing = true
        
        self.currentFrame = frame
        
        // Create a Barcode Detection Request
        let request = VNDetectBarcodesRequest(completionHandler: processQRCodeRequest)
        
        // Process the request in the background
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Set it to recognize QR code only
                request.symbologies = [.QR]
                
                // Create a request handler using the captured image from the ARFrame
                let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: frame.capturedImage,
                                                                options: [:])
                
                // Process the request
                try imageRequestHandler.perform([request])
            } catch {
                NSLog("Failed barcode request")
            }
        }
    }
    
    func processQRCodeRequest(request: VNRequest, error: Error?) {
        // Get the first result out of the results, if there are any
        if let results = request.results, let result = results.first as? VNBarcodeObservation {
            
            // Get the bounding box for the bar code and find the center
            var rect = result.boundingBox
            
            // Flip coordinates
            rect = rect.applying(CGAffineTransform(scaleX: 1, y: -1))
            rect = rect.applying(CGAffineTransform(translationX: 0, y: 1))
            
            // Get center
            let center = CGPoint(x: rect.midX, y: rect.midY)
            
            // Go back to the main thread
            DispatchQueue.main.async {
                
                // Perform a hit test on the ARFrame to find a surface
                if let frame = self.currentFrame {
                    let hitTestResults = frame.hitTest(center, types: [.featurePoint/*, .estimatedHorizontalPlane, .existingPlane, .existingPlaneUsingExtent*/] )
                    
                    // If we have a result, process it
                    if let hitTestResult = hitTestResults.first {
                        
                        // If we already have an anchor, update the position of the attached node
                        if(self.qrFoundCount < 32) {
                            
                        }
                        if let detectedDataAnchor = self.detectedDataAnchor,
                            let node = self.sceneView.node(for: detectedDataAnchor) {
                            
                            node.transform = SCNMatrix4(hitTestResult.worldTransform)
                            
                        } else {
                            // Create an anchor. The node will be created in delegate methods
                            self.detectedDataAnchor = ARAnchor(transform: hitTestResult.worldTransform)
                            self.sceneView.session.add(anchor: self.detectedDataAnchor!)
                        }
                        if let payloadString = result.payloadStringValue {
                            if(!self.qrCodeFound) {
                                NSLog(payloadString)
                                self.processQRPayload(payloadString)
                            }
                        }
                        self.qrCodeFound = true
                    }
                }
                
                
                // Set processing flag off
                self.processing = false
            }
            
        } else {
            // Set processing flag off
            self.processing = false
        }
    }
    
    func processQRPayload(_ payloadString: String) {
        if(payloadString.starts(with: "http")) {
            //TODO: code for loading request here
        } else {
            let pointsArray = payloadString.split(separator: ";")
            
            guard pointsArray.count > 0 else {
                NSLog("Invalid payload format")
                return
            }
            var vectorArray = [SCNVector3]()
            for vector in pointsArray {
                
                let values = vector.split(separator: ",")
                if(values.count == 3) {
                    vectorArray.append(SCNVector3Make(Float(values[0]) ?? 0, Float(values[1]) ?? 0, Float(values[2]) ?? 0))
                }
            }
            
            createPath(coordinates: vectorArray)
        }
        
        
    }
    
    func createPath(coordinates: [SCNVector3]) {
        let startGeometry = SCNCylinder(radius: 0.1, height: 0.1)
        let startNode = SCNNode(geometry: startGeometry)
        startNode.position = coordinates[0]
        
        let destinationGeometry = SCNCylinder(radius: 0.1, height: 0.1)
        let destinationNode = SCNNode(geometry: destinationGeometry)
        destinationNode.position = coordinates[coordinates.count - 1]
        
        self.sceneView.scene.rootNode.addChildNode(startNode)
        self.sceneView.scene.rootNode.addChildNode(destinationNode)
        
        var index = 0
        for coordinate in coordinates {
            if(index != 0 || index != coordinates.count - 1) {
                let posGeometry = SCNCylinder(radius: 0.1, height: 0.1)
                let posNode = SCNNode(geometry: posGeometry)
                posNode.position = coordinate
                
                self.sceneView.scene.rootNode.addChildNode(posNode)
            }
            index += 1
        }
        
        
    }
    
    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        updateSessionInfoLabel(for: session.currentFrame!, trackingState: camera.trackingState)
    }
    
    // MARK: - ARSessionObserver
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay.
        sessionInfoLabel.text = "Session was interrupted"
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required.
        sessionInfoLabel.text = "Session interruption ended"
        resetTracking()
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user.
        sessionInfoLabel.text = "Session failed: \(error.localizedDescription)"
        resetTracking()
    }
    
    // MARK: - Private methods
    
    private func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String
        
        switch trackingState {
        case .normal:
            message = ""
            
        case .notAvailable:
            message = "Tracking unavailable."
            
        case .limited(.excessiveMotion):
            message = "Too much movement!"
            
        case .limited(.insufficientFeatures):
            message = "Low light"
            
        case .limited(.initializing):
            message = "Initializing AR Session"
            
        case .limited(.relocalizing):
            message = "Relocalizing..."
        }
        
        sessionInfoLabel.text = message
        sessionInfoView.isHidden = message.isEmpty
    }
    
    private func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        if #available(iOS 11.3, *) {
            configuration.planeDetection = [.horizontal, .vertical]
        } else {
           configuration.planeDetection = .horizontal
        }
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    private func resetTrackingWithWorldAlignment(alignment: ARConfiguration.WorldAlignment) {
        let configuration = ARWorldTrackingConfiguration()
        if #available(iOS 11.3, *) {
            configuration.planeDetection = [.horizontal, .vertical]
        } else {
            configuration.planeDetection = .horizontal
        }
        configuration.worldAlignment = alignment
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
}
