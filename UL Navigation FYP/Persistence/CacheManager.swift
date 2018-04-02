//
//  CacheManager.swift
//  UL Navigation FYP
//
//  Created by Robert Mccahill on 28/03/2018.
//

import Foundation

class CacheManager: NSObject {
    static let sharedInstance = CacheManager()
    static let test = ""
    
    override init() {
        super.init()
        
        
    }
    
    public func isURLPresent(url: String) -> Bool {
        
        return false;
    }
    
    
}
