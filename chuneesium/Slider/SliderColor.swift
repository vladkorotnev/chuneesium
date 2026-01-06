//
//  SliderColor.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/06.
//


import SwiftUI

/// Represents an RGB color for an individual slider segment.
public struct SliderColor {
    public var r: UInt8
    public var g: UInt8
    public var b: UInt8
    
    public init(r: UInt8 = 0, g: UInt8 = 0, b: UInt8 = 0) {
        self.r = r
        self.g = g
        self.b = b
    }
    
    init(color: Color) {
        let resolved = color.resolve(in: .init())
        self.r = UInt8(min(255, resolved.linearRed * 255 * resolved.opacity))
        self.g = UInt8(min(255, resolved.linearGreen * 255 * resolved.opacity))
        self.b = UInt8(min(255, resolved.linearBlue * 255 * resolved.opacity))
    }
    
    func multiply(brightness: Double) -> SliderColor {
        return SliderColor(
            r: UInt8(min(255, max(0, brightness * Double(r)))),
            g: UInt8(min(255, max(0, brightness * Double(g)))),
            b: UInt8(min(255, max(0, brightness * Double(b)))),
        )
    }
    
    var toSwiftUi: Color {
        Color(
            .sRGBLinear,
            red: Double(r)/255.0,
            green: Double(g)/255.0,
            blue: Double(b)/255.0
        )
    }
}
