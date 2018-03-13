//
//  Double+RadConversion.swift
//  UL Navigation FYP
//
//  Created by Robert Mccahill on 21/02/2018.
//

import Foundation

extension Double {
    
    func toRadians() -> Double {
        return self * .pi / 180.0
    }
    
    func toDegrees() -> Double {
        return self * 180.0 / .pi
    }
}
