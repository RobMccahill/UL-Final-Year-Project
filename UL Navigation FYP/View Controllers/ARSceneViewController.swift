//
//  ViewController.swift
//  UL Navigation FYP
//
//  Created by Robert Mccahill on 31/01/2018.
//

import UIKit
import SceneKit
import ARKit
import MapKit
import QuartzCore

class ARSceneViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, CLLocationManagerDelegate {
    // MARK: - IBOutlets
    
    @IBOutlet weak var sessionInfoView: UIVisualEffectView!
    @IBOutlet weak var sessionInfoLabel: UILabel!
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var startRouteButton: UIButton!
    @IBOutlet var mapView: MKMapView!
    
    var locationManager = CLLocationManager()
    let height = Float(-1.5)
    
    var directions : MKDirections?
    var destinationCoord : CLLocationCoordinate2D?
    var mapZoomed = false
    
    
    // MARK: - View Life Cycle
    
    /// - Tag: StartARSession
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        startRouteButton.isHidden = true
        
        //rounding
        mapView.clipsToBounds = true
        mapView.layer.cornerRadius = mapView.frame.size.width / 2
        
        // border
        mapView.layer.borderColor = UIColor.gray.cgColor
        mapView.layer.borderWidth = 1.5
        
        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("""
                ARKit is not available on this device. For apps that require ARKit
                for core functionality, use the `arkit` key in the key in the
                `UIRequiredDeviceCapabilities` section of the Info.plist to prevent
                the app from installing. (If the app can't be installed, this error
                can't be triggered in a production scenario.)
                In apps where AR is an additive feature, use `isSupported` to
                determine whether to show UI for launching AR experiences.
            """) // For details, see https://developer.apple.com/documentation/arkit
        }
        
        /*
         Start the view's AR session with a configuration that uses the rear camera,
         device position and orientation tracking, and plane detection.
         */
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true;
        configuration.worldAlignment = .gravityAndHeading
        //        sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints
        sceneView.session.run(configuration)
        
        // Set a delegate to track the number of plane anchors for providing UI feedback.
        sceneView.session.delegate = self
        
        /*
         Prevent the screen from being dimmed after a while as users will likely
         have long periods of interaction without touching the screen or buttons.
         */
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Show debug UI to view performance metrics (e.g. frames per second).
        sceneView.showsStatistics = true
        
        locationManager.delegate = self
        
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's AR session.
        sceneView.session.pause()
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
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
            startRouteButton.isHidden = false
            
        case .notAvailable:
            message = "Tracking unavailable."
            
        case .limited(.excessiveMotion):
            message = "Too much movement!"
            
        case .limited(.insufficientFeatures):
            message = "Low light"
            
        case .limited(.initializing):
            message = "Initializing AR session."
            
        }
        
        sessionInfoLabel.text = message
        sessionInfoView.isHidden = message.isEmpty
    }
    
    private func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    @IBAction func createPath(_ sender: Any) {
        
        let userGeometry = SCNCylinder(radius: 0.1, height: 0.1)
        userGeometry.firstMaterial?.diffuse.contents = UIColor.red.withAlphaComponent(0.8)
        
        let userNode = SCNNode(geometry:userGeometry)
        userNode.position = SCNVector3Make(0, height, 0)
        self.sceneView.scene.rootNode.addChildNode(userNode)
        
        let firstGeometry = SCNBox(width: 0.1, height: 0.1, length: 3.4, chamferRadius: 0.0)
        firstGeometry.firstMaterial?.diffuse.contents = UIColor.blue.withAlphaComponent(0.8)
        
        let firstPathNode = SCNNode(geometry: firstGeometry)
        firstPathNode.position = SCNVector3Make(0, 0, Float(-firstGeometry.length) / 2)
        userNode.addChildNode(firstPathNode)
        
        let secondGeometry = SCNBox(width: 0.1, height: 0.1, length: 3.4, chamferRadius: 0.0)
        secondGeometry.firstMaterial?.diffuse.contents = UIColor.blue.withAlphaComponent(0.8)
        
        let secondPathNode = SCNNode(geometry: secondGeometry)
        secondPathNode.position = SCNVector3Make(Float(-firstGeometry.length) / 2, 0, Float(-firstGeometry.length))
        
        secondPathNode.eulerAngles.y = .pi / 2
        
        userNode.addChildNode(secondPathNode)
        
        let thirdGeometry = SCNBox(width: 0.1, height: 0.1, length: 1, chamferRadius: 0.0)
        thirdGeometry.firstMaterial?.diffuse.contents = UIColor.blue.withAlphaComponent(0.8)
        
        let thirdPathNode = SCNNode(geometry: thirdGeometry)
        thirdPathNode.position = SCNVector3Make(Float(secondPathNode.worldPosition.x) - Float(secondGeometry.length) / 2, 0, Float(-secondGeometry.length) - Float(thirdGeometry.length) / 2)
        
        userNode.addChildNode(thirdPathNode)
        
        let destinationGeometry = SCNCylinder(radius: 0.1, height: 0.1)
        destinationGeometry.firstMaterial?.diffuse.contents = UIColor.red.withAlphaComponent(0.8)
        
        let destinationNode = SCNNode(geometry: destinationGeometry)
        destinationNode.position = SCNVector3Make(thirdPathNode.position.x, 0, thirdPathNode.position.z - Float(thirdGeometry.length) + 0.4)
        
        userNode.addChildNode(destinationNode)
        
        userNode.rotation = SCNVector4Make(0, 1, 0, Float(toRadians(degrees: 150)))
        
        startRouteButton.isHidden = true
    }
    
    
    
    func addGeometryToPath(geometry : SCNBox, prevNode : SCNNode) {
        let newPathNode = SCNNode(geometry: geometry)
        newPathNode.position = SCNVector3Make(Float(prevNode.worldPosition.x) - Float(prevNode.scale.x) / 2, height, Float(-prevNode.scale.x) - Float(geometry.length) / 2)
        
        self.sceneView.scene.rootNode.addChildNode(newPathNode)
    }
    
    func toRadians(degrees : Double) -> Double {
        return degrees * .pi / 180
    }
    
    func toDegrees(radians : Double) -> Double {
        return radians * 180 / .pi
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            // If status has not yet been determied, ask for authorization
            manager.requestWhenInUseAuthorization()
            break
        case .authorizedWhenInUse:
            // If authorized when in use
            manager.startUpdatingLocation()
            break
        case .restricted:
            // If restricted by e.g. parental controls. User can't enable Location Services
            break
        case .denied:
            // If user denied your app access to Location Services, but can grant access from Settings.app
            break
        default:
            break
        }
    }
    
    //MARK CLLocationManagerDelegate methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    }
}

extension ARSceneViewController : MKMapViewDelegate {
    func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
        if(!mapZoomed) {
            let annotation = MKPointAnnotation()
            if let coord = self.destinationCoord {
                annotation.coordinate = coord
                mapView.addAnnotation(annotation)
            }
            
            if let directions = self.directions {
                directions.calculate { [unowned self] response, error in
                    guard let unwrappedResponse = response else { return }
                    
                    if(unwrappedResponse.routes.count > 0) {
                        let route = unwrappedResponse.routes[0]
                        
                        self.mapView.add(route.polyline)
                        self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                    }
                }
            }
            
            mapView.showAnnotations(mapView.annotations, animated: true)
            mapZoomed = true
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?{
        if annotation is MKUserLocation {
            //return nil so map view draws "blue dot" for standard user location
            return nil
        }
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        pinView?.pinTintColor = UIColor.red
//        pinView?.canShowCallout = true
//        let smallSquare = CGSize(width: 30, height: 30)
//        let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
//        button.setBackgroundImage(UIImage(named: "directions"), for: .normal)
//        button.addTarget(self, action: #selector(getDirections), for: .touchUpInside)
//        //        button.setTitle("Get Directions", for: .normal)
//        //        button.setTitleColor(.blue, for: .normal)
//        pinView?.leftCalloutAccessoryView = button
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        renderer.strokeColor = UIColor.blue
        return renderer
    }
}
