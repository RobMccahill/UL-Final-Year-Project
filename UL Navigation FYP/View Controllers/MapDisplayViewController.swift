//
//  MapDisplayViewController.swift
//  UL Navigation FYP
//
//  Created by Robert Mccahill on 31/01/2018.
//

import UIKit
import MapKit

protocol HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark)
}

class MapDisplayViewController: UIViewController {
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet weak var userLocationButton: UIButton!
    let locationManager = CLLocationManager()
    var mapZoomed = false
    var matchingItems:[MKMapItem] = []
    var selectedPin:MKPlacemark? = nil
    var handleMapSearchDelegate:HandleMapSearch? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        handleMapSearchDelegate = self
        
        userLocationButton.layer.borderWidth = 0.5
        let customBlue = UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
        userLocationButton.layer.borderColor = customBlue.cgColor
        
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    @IBAction func userLocationButtonTapped(_ sender: UIButton) {
        let mapRegion = MKCoordinateRegion(center: mapView.userLocation.coordinate, span: mapView.region.span)
        mapView.setRegion(mapRegion, animated: true)
    }
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
}

extension MapDisplayViewController : UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = searchBar.text
        request.region = mapView.region
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            guard let response = response else {
                return
            }
            self.matchingItems = response.mapItems
            self.tableView.reloadData()
        }
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
    }
}

extension MapDisplayViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItem = matchingItems[indexPath.row].placemark
        handleMapSearchDelegate?.dropPinZoomIn(placemark: selectedItem)
    }
}

extension MapDisplayViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "subtitleCell")!
        let selectedItem = matchingItems[indexPath.row]
        cell.textLabel?.text = selectedItem.name
        cell.detailTextLabel?.text = selectedItem.placemark.title
        return cell
    }
}

extension MapDisplayViewController : MKMapViewDelegate {
    func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
        if(!mapZoomed) {
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
        pinView?.canShowCallout = true
        let smallSquare = CGSize(width: 30, height: 30)
        let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
        button.setBackgroundImage(UIImage(named: "directions"), for: .normal)
        button.addTarget(self, action: #selector(getDirections), for: .touchUpInside)
//        button.setTitle("Get Directions", for: .normal)
//        button.setTitleColor(.blue, for: .normal)
        pinView?.leftCalloutAccessoryView = button
        return pinView
    }
    
    @objc func getDirections(){
        if let selectedPin = selectedPin {
            
            let request = MKDirectionsRequest()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: self.mapView.userLocation.coordinate, addressDictionary: nil))
            
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: selectedPin.coordinate, addressDictionary: nil))
            request.requestsAlternateRoutes = true
            request.transportType = .walking
            
            let directions = MKDirections(request: request)
            
            directions.calculate { response, error in
                if let error = error {
                    NSLog(error.localizedDescription)
                }
                guard let unwrappedResponse = response else { return }
                
                let arSceneVC = self.storyboard?.instantiateViewController(withIdentifier: "ARSceneVC") as! ARMapNavigationViewController
                arSceneVC.directions = unwrappedResponse
                arSceneVC.destinationCoord = selectedPin.coordinate
                self.navigationController?.pushViewController(arSceneVC, animated: true)
            }
            
            
        }
    }
    
    
    
}

extension MapDisplayViewController : CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error:: \(error.localizedDescription)")
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
}

extension MapDisplayViewController: HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark){
        // cache the pin
        selectedPin = placemark
        // clear existing pins
        mapView.removeAnnotations(mapView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        var subtitle = ""
        
        if let city = placemark.locality,
            let state = placemark.administrativeArea {
            subtitle += city + ", " + state
        } else if let state = placemark.administrativeArea,
                  let country = placemark.country {
            subtitle += state + ", " + country
        }
        
        annotation.subtitle = subtitle
        
        mapView.addAnnotation(annotation)
        mapView.setCenter(annotation.coordinate, animated: true)
        mapView.selectAnnotation(annotation, animated: true)
    }
}
