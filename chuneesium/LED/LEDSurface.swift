//
//  LEDSurface.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/05.
//

import Foundation

final class LEDSurface {
    private let port: LEDPort
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
    
    var airTowerSeparateColors: [SliderColor] = [
        .init(),
        .init(),
        .init()
    ]
    var pixelGrid: [[SliderColor]]
    
    init(
        port: LEDBD,
        stripCount: Int,
        stripInversePhase: Bool
    ) {
        self.port = port
        self.inversePhase = stripInversePhase
        self.stripCount = stripCount
        self.pixelGrid = Array(repeating: Array(repeating: .init(), count: pixelsPerStrip), count: stripCount)
        assert(stripCount * pixelsPerStrip + 3 == port.ledCount, "LED Board does not match LED count for surface")
    }
    

    func push() {
        guard !pushing else { return }
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
