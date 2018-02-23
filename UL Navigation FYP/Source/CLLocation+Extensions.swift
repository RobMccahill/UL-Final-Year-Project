//
//  CLLocation+Extensions.swift
//  ARKit+CoreLocation
//
//  Created by Andrew Hart on 02/07/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//
import Foundation
import CoreLocation

///Translation in meters between 2 locations
public struct LocationTranslation {
    public var latitudeTranslation: Double
    public var longitudeTranslation: Double
    public var altitudeTranslation: Double
    
    public init(latitudeTranslation: Double, longitudeTranslation: Double, altitudeTranslation: Double) {
        self.latitudeTranslation = latitudeTranslation
        self.longitudeTranslation = longitudeTranslation
        self.altitudeTranslation = altitudeTranslation
    }
}

public extension CLLocation {
    public convenience init(coordinate: CLLocationCoordinate2D, altitude: CLLocationDistance) {
        self.init(coordinate: coordinate, altitude: altitude, horizontalAccuracy: 0, verticalAccuracy: 0, timestamp: Date())
    }
    
    ///Translates distance in meters between two locations.
    ///Returns the result as the distance in latitude and distance in longitude.
    public func translation(toLocation location: CLLocation) -> LocationTranslation {
        let inbetweenLocation = CLLocation(latitude: self.coordinate.latitude, longitude: location.coordinate.longitude)
        
        let distanceLatitude = location.distance(from: inbetweenLocation)
        
        let latitudeTranslation: Double
        
        if location.coordinate.latitude > inbetweenLocation.coordinate.latitude {
            latitudeTranslation = distanceLatitude
        } else {
            latitudeTranslation = 0 - distanceLatitude
        }
        
        let distanceLongitude = self.distance(from: inbetweenLocation)
        
        let longitudeTranslation: Double
        
        if self.coordinate.longitude > inbetweenLocation.coordinate.longitude {
            longitudeTranslation = 0 - distanceLongitude
        } else {
            longitudeTranslation = distanceLongitude
        }
        
        let altitudeTranslation = location.altitude - self.altitude
        
        return LocationTranslation(
            latitudeTranslation: latitudeTranslation,
            longitudeTranslation: longitudeTranslation,
            altitudeTranslation: altitudeTranslation)
    }
    
    public func translatedLocation(with translation: LocationTranslation) -> CLLocation {
        let latitudeCoordinate = self.coordinate.coordinateWithBearing(bearing: 0, distanceMeters: translation.latitudeTranslation)
        
        let longitudeCoordinate = self.coordinate.coordinateWithBearing(bearing: 90, distanceMeters: translation.longitudeTranslation)
        
        let coordinate = CLLocationCoordinate2D(
            latitude: latitudeCoordinate.latitude,
            longitude: longitudeCoordinate.longitude)
        
        let altitude = self.altitude + translation.altitudeTranslation
        
        return CLLocation(coordinate: coordinate, altitude: altitude, horizontalAccuracy: self.horizontalAccuracy, verticalAccuracy: self.verticalAccuracy, timestamp: self.timestamp)
    }
}

extension Double {
    func metersToLatitude() -> Double {
        return self / (6360500.0)
    }
    
    func metersToLongitude() -> Double {
        return self / (5602900.0)
    }
}

public extension CLLocationCoordinate2D {
    public func coordinateWithBearing(bearing:Double, distanceMeters:Double) -> CLLocationCoordinate2D {
        //The numbers for earth radius may be _off_ here
        //but this gives a reasonably accurate result..
        //Any correction here is welcome.
        let distRadiansLat = distanceMeters.metersToLatitude() // earth radius in meters latitude
        let distRadiansLong = distanceMeters.metersToLongitude() // earth radius in meters longitude
        
        let lat1 = self.latitude * .pi / 180
        let lon1 = self.longitude * .pi / 180
        
        let lat2 = asin(sin(lat1) * cos(distRadiansLat) + cos(lat1) * sin(distRadiansLat) * cos(bearing))
        let lon2 = lon1 + atan2(sin(bearing) * sin(distRadiansLong) * cos(lat1), cos(distRadiansLong) - sin(lat1) * sin(lat2))
        
        return CLLocationCoordinate2D(latitude: lat2 * 180 / Double.pi, longitude: lon2 * 180 / Double.pi)
    }
    
//    public func coordToMetres(toPoint point2: CLLocationCoordinate2D) -> (latitude: Double, longitude: Double) {
//
//        let lat1 = degreesToRadians(self.latitude);
//        let lon1 = degreesToRadians(self.longitude);
//
//        let lat2 = degreesToRadians(point2.latitude);
//        let lon2 = degreesToRadians(point2.longitude);
//
//        let dLon = lon2 - lon1;
//
//        let y = sin(dLon) * cos(lat2);
//        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
//        var latDistance = atan2(y, x);
//
//        if(latDistance < 0.0) {
//            latDistance += 2 * .pi;
//        }
//
//        return (latDistance, latDistance)
//    }
    
    public func bearingToCoord(coord : CLLocationCoordinate2D) -> Double {
        
        let lat1 = degreesToRadians(self.latitude)
        let lon1 = degreesToRadians(self.longitude)
        
        let lat2 = degreesToRadians(coord.latitude)
        let lon2 = degreesToRadians(coord.longitude)
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        var radiansBearing = atan2(y, x)
        
        radiansBearing = radiansToDegrees(radiansBearing)
        
        if(radiansBearing < 0.0) {
            radiansBearing += 2 * .pi;
        }
        
        return radiansBearing
    }
    
    func degreesToRadians(_ degrees: Double) -> Double { return degrees * .pi / 180.0 }
    func radiansToDegrees(_ radians: Double) -> Double { return radians * 180.0 / .pi }
}
