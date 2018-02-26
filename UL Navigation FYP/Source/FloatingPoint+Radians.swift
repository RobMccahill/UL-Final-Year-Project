//
//  Double+RadConversion.swift
//  UL Navigation FYP
//
//  Created by Robert Mccahill on 21/02/2018.
//

import Foundation

extension FloatingPoint {
    
    public var radiansToDegrees: Self { return self * 180 / .pi}
    public var degreesToRadians: Self { return self * .pi / 180 }
}
