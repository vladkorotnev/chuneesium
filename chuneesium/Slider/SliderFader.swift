//
//  SliderFader.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/04.
//

import SwiftUI

final class SliderFader {
    var value = 0.0
    private var handleLocation: Int {
        if value <= 0.0 {
            location.left
        } else if value >= 1.0 {
            location.left + location.width - 1
        } else {
            Int(round(Double(location.width) * value))
        }
    }
    
    let location: SliderCoordinates
    let label: String
    let allowsJump: Bool
    
    var backdrop: Color
    var ticks: Color
    var handle: Color
    var onChange: ((Double) -> Void)?
    var onTouchStateChange: ((Bool) -> Void)?
    
    private var touches: Set<Int> = []
    private var untouchTimer: Timer?
    private var oldTouchState = false
    
    init(
        label: String,
        location: SliderCoordinates,
        allowsJump: Bool = false,
        value: Double = 0.0,
        backdrop: Color = .yellow.opacity(0.7),
        ticks: Color = .purple,
        handle: Color = .white
    ) {
        self.label = label
        self.value = value
        self.location = location
        self.backdrop = backdrop
        self.ticks = ticks
        self.handle = handle
        self.allowsJump = allowsJump
    }
    
    private func updateToTouchedValueIfNeeded() {
        if !allowsJump {
            guard touches.count <= 2,
                  touches.count > 0,
                  (oldTouchState || touches.allSatisfy({ abs(handleLocation - $0) <= 1 }))
            else {
                return
            }
        }
        
        let touch = touches.reduce(into: 0.0) { partialResult, value in
            partialResult += Double(value)
        } / Double(touches.count)
        
        let newHandleLocation = touch - Double(location.left)
        guard !newHandleLocation.isNaN, newHandleLocation.isFinite else { return }
        
        if newHandleLocation == 0 {
            value = 0.0
        } else if Int(newHandleLocation) == location.width - 1 {
            value = 1.0
        } else {
            value = Double(newHandleLocation) / Double(location.width)
        }
        
        onChange?(value)
    }
}

extension SliderFader: SliderPlaceable {
    var colors: [Color] {
        var rslt: [Color] = []
        for _ in 0..<location.width {
            rslt.append(backdrop)
            rslt.append(ticks)
        }
        rslt[(handleLocation - location.left)*2] = handle
        return rslt
    }
    
    var labelTint: Color {
        backdrop
    }
    
    func hitTest(point: SliderTouchCoordinates, newState: Bool, overallState: Bool) {
        guard location.contains(point) else { return }
        if newState {
            touches.insert(point.column)
        } else {
            touches.remove(point.column)
        }
        
        updateToTouchedValueIfNeeded()
        
        untouchTimer?.invalidate()
        if touches.isEmpty {
            untouchTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false, block: { [weak self] _ in
                self?.onTouchStateChange?(false)
                self?.oldTouchState = false
            })
        } else {
            untouchTimer = nil
            if !oldTouchState {
                oldTouchState = touches.allSatisfy({ abs(handleLocation - $0) <= 1 }) || allowsJump
                if oldTouchState {
                    onTouchStateChange?(true)
                }
            }
        }
    }
}
