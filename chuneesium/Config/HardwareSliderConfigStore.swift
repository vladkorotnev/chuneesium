//
//  HardwareSliderConfigStore.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/04.
//

import Foundation

protocol HardwareSliderConfigStoreProtocol: SerialPortEnumerator {
    var portPath: String? { get set }
    var onUpdate: ((String?) -> Void)? { get set }
}

final class HardwareSliderConfigStore: HardwareSliderConfigStoreProtocol {
    var onUpdate: ((String?) -> Void)? = nil
    
    var portPath: String? {
        get {
            UserDefaults.standard.string(forKey: "sliderPortPath")
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: "sliderPortPath")
            onUpdate?(newValue)
        }
    }
    
    init(onUpdate: ((String?) -> Void)? = nil) {
        self.onUpdate = onUpdate
        onUpdate?(portPath)
    }
}
