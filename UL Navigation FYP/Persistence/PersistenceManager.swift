//
//  PersistenceManager.swift
//  UL Navigation FYP
//
//  Created by Robert Mccahill on 28/03/2018.
//

import Foundation
import SceneKit

class PersistenceManager: NSObject {
    static let sharedInstance = PersistenceManager()
    static let test = ""
    
    override init() {
        super.init()
    }
    
    func getSceneForURL(_ address: String) -> (SCNNode, String?) {
        
        if let requestUrl = URL(string:address) {
            let request = URLRequest(url:requestUrl)
            URLSession.shared.dataTask(with: request) {
                (data, response, error) in
                if error == nil, let usableData = data {
                    print(usableData)
                    
                } else {
                    print(error as Any)
                }
            }
        }
        
        return (SCNNode(), "")
    }
    
//    func checkForLocalCopy(_ address: String) -> NSDictionary {
//        let dict = UserDefaults.standard.dictionary(forKey: address) as?
//
//        return NSDictionary()
//    }
    
    func commitScenetoCache() {
        
    }
    
    func deserializePayload(_ data: Data) -> SCNNode {
        return SCNNode()
    }
    
    
    
}
