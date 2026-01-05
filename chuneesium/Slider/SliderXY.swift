//
//  SliderXY.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/04.
//

import SwiftUI

typealias SliderXYOutput = (x: Double, y: Double)

final class SliderXY {
    private var background: Color
    var location: SliderCoordinates
    let label: String
    var onChange: ((SliderXYOutput) -> Void)?
    private var currentLocation: SliderXYOutput = (x: 0, y: 0) {
        didSet { onChange?(currentLocation) }
    }
    private var rowValues = [0, 0]
    private var untouchTimer: Timer?
    private var oldTouchState = false
    var onTouchStateChange: ((Bool) -> Void)?
    var colors: [Color]

    init(
        label: String,
        location: SliderCoordinates,
        background: Color
    ) {
        self.label = label
        self.location = location
        self.background = background
        self.colors = Array(repeating: background, count: location.width*2)
    }
    
    private var estimatedY: Double {
        let top = Double(rowValues[0])/255.0
        let bottom = Double(rowValues[1])/255.0
        
        if top == 0 && bottom > 0 {
            return bottom/2.0
        } else if top > 0 && bottom > 0 {
            return 0.5 + top / 2.0
        } else if top > 0 && bottom == 0 {
            return 0.5 + top
        } else {
            return 0
        }
    }
}

extension SliderXY: SliderPlaceableRaw {
    var labelTint: Color {
        background
    }
    
    func hitTestRaw(point: SliderTouchCoordinates, newState: Bool, overallState: Bool, value: Int) {
        guard location.contains(point) else { return }
        
        rowValues[point.row] = value
        
        if !overallState {
            currentLocation = (x: 0, y: 0)
            untouchTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false, block: { [weak self] _ in
                self?.onTouchStateChange?(false)
                self?.oldTouchState = false
            })
            self.colors = Array(repeating: background, count: location.width*2)
        } else {
            if newState {
                self.colors = Array(repeating: background.opacity(0.5), count: location.width*2)
                self.colors[(point.column - location.left)*2] = background
                let localX = Double(point.column - location.left) / Double(location.width)
                let localY = min(estimatedY, 1.0)

                currentLocation = (x: localX, y: localY)
            }
            
            self.oldTouchState = true
            untouchTimer?.invalidate()
        }
    }
}

