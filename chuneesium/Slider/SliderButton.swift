//
//  SliderButton.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/01.
//

import SwiftUI

class SliderButton {
    var tint: Color
    var barColor: Color?
    var label: String
    var location: SliderCoordinates
    var onTap: (() -> Void)?
    var onPress: (() -> Void)?
    var onRelease: (() -> Void)?
    var onHold: (() -> Void)?
    
    private var pressCoordinates: Set<SliderTouchCoordinates> = Set()
    private var holdTimer: Timer?
    
    init(
        tint: Color,
        label: String,
        location: SliderCoordinates,
        barColor: Color? = nil,
        onTap: (() -> Void)? = nil,
        onRelease: (() -> Void)? = nil,
        onPress: (() -> Void)? = nil,
        onHold: (() -> Void)? = nil
    ) {
        self.tint = tint
        self.label = label
        self.location = location
        self.onTap = onTap
        self.onPress = onPress
        self.onRelease = onRelease
        self.onHold = onHold
    }
    
    private var activeBarColor: Color {
        guard let barColor else { return labelTint }
        
        if pressCoordinates.isEmpty {
            return barColor
        } else {
            return barColor.opacity(0.6)
        }
    }
}

extension SliderButton: SliderPlaceable {
    var labelTint: Color {
        if pressCoordinates.isEmpty {
            tint
        } else {
            tint.opacity(0.6)
        }
    }
    
    var colors: [Color] {
        [labelTint, activeBarColor]
    }
    
    func hitTest(point: SliderTouchCoordinates, newState: Bool, overallState: Bool) {
        if location.contains(point) {
            if pressCoordinates.contains(point) && !newState {
                pressCoordinates.remove(point)
                
                if pressCoordinates.isEmpty {
                    onRelease?()
                    holdTimer?.invalidate()
                    
                    if !overallState {
                        onTap?()
                    }
                }
            } else if !pressCoordinates.contains(point) {
                if pressCoordinates.isEmpty {
                    onPress?()
                    
                    holdTimer?.invalidate()
                    holdTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false, block: { [weak self] _ in
                        if let onHold = self?.onHold {
                            onHold()
                            self?.pressCoordinates.removeAll()
                        }
                    })
                }
                pressCoordinates.insert(point)
            }
        }
    }
}
