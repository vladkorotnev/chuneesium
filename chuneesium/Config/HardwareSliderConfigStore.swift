//
//  HardwareSliderConfigStore.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/04.
//

import Foundation
import IOKit
import IOKit.serial

protocol HardwareSliderConfigStoreProtocol {
    var portPath: String? { get set }
    var allPorts: [String] { get }
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
    
    var allPorts: [String] {
        get {
            guard let serialBSDService = IOServiceMatching(kIOSerialBSDServiceValue) else { return [] }
            guard var dict = serialBSDService as NSDictionary as? [String: AnyObject] else { return [] }

            dict[kIOSerialBSDTypeKey] = kIOSerialBSDAllTypes as AnyObject
            var serialPortIterator = io_iterator_t()
            guard IOServiceGetMatchingServices(kIOMainPortDefault, serialBSDService, &serialPortIterator) == kIOReturnSuccess else { return [] }

            var rslt: [String] = []
            while case let modemService = IOIteratorNext(serialPortIterator), modemService != 0 {
                let prop = IORegistryEntryCreateCFProperty(modemService, kIOCalloutDeviceKey as CFString, kCFAllocatorDefault, IOOptionBits(0))
                if let value = prop?.takeUnretainedValue(), let bsdPath = value as? String {
                    rslt.append(bsdPath)
                }
            }

            IOObjectRelease(serialPortIterator)
            return rslt
        }
    }
    
    init(onUpdate: ((String?) -> Void)? = nil) {
        self.onUpdate = onUpdate
        onUpdate?(portPath)
    }
}
