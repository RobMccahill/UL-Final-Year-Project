//
//  CLLocation+Extensions.swift
//  UL Navigation FYP
//
//  Created by Robert Mccahill on 21/02/2018.
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
}
