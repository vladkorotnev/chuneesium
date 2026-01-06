//
//  SerialPortEnumerator.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/06.
//

import Foundation
import IOKit
import IOKit.serial

protocol SerialPortEnumerator {
    var allPorts: [String] { get }
}

extension SerialPortEnumerator {
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
}
