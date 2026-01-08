//
//  JVSConfigStore.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/08.
//

import Foundation

protocol JVSConfigStoreProtocol: SerialPortEnumerator {
    var portPath: String? { get set }
    var onUpdate: ((String?) -> Void)? { get set }
}

final class JVSConfigStore: JVSConfigStoreProtocol {
    var onUpdate: ((String?) -> Void)? = nil
    
    var portPath: String? {
        get {
            UserDefaults.standard.string(forKey: "jvsPortPath")
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: "jvsPortPath")
            onUpdate?(newValue)
        }
    }
    
    init(onUpdate: ((String?) -> Void)? = nil) {
        self.onUpdate = onUpdate
        onUpdate?(portPath)
    }
}
