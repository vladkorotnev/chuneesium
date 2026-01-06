//
//  LEDSurface.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/05.
//

import Foundation
import Combine

final class LEDSurface: ObservableObject {
    var port: LEDPort? {
        didSet {
            guard let port else { return }
            assert(stripCount * pixelsPerStrip + 3 == port.ledCount, "LED Board does not match LED count for surface")
        }
    }
    
    private let inversePhase: Bool
    private let pixelsPerStrip = 10
    private var pushing = false
    var brightness = 0.6
    let stripCount: Int
    
    var airTowerColor: SliderColor {
        get {
            airTowerSeparateColors.first!
        }
        set {
            airTowerSeparateColors = Array(repeating: newValue, count: 3)
        }
    }
    
    @Published var airTowerSeparateColors: [SliderColor] = [
        .init(),
        .init(),
        .init()
    ]
    @Published var pixelGrid: [[SliderColor]]
    
    init(
        port: LEDBD?,
        stripCount: Int,
        stripInversePhase: Bool,
        brightness: Double = 0.6
    ) {
        self.port = port
        self.inversePhase = stripInversePhase
        self.stripCount = stripCount
        self.brightness = brightness
        self.pixelGrid = Array(repeating: Array(repeating: .init(), count: pixelsPerStrip), count: stripCount)
        
    }
    

    func push() {
        guard let port, !pushing else { return }
        pushing = true
        
        let dispData = pixelGrid.enumerated()
            .reduce(into: [], { partialResult, strip in
                if (strip.offset % 2 == 0 && inversePhase) || (strip.offset % 2 != 0 && !inversePhase) {
                    return partialResult.append(contentsOf: strip.element.reversed())
                } else {
                    return partialResult.append(contentsOf: strip.element)
                }
            })
            .map { ($0 as! SliderColor).multiply(brightness: brightness) }
        let linearData = dispData + airTowerSeparateColors
        
        port.writePixels(data: linearData)
        
        pushing = false
    }
}
