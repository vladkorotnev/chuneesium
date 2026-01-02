//
//  SliderButton.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/01.
//

import SwiftUI

class SliderButton {
    var tint: Color
    var label: String
    var location: SliderCoordinates
    var onTap: (() -> Void)?
    var onPress: (() -> Void)?
    var onRelease: (() -> Void)?
    
    private var pressCoordinates: Set<SliderTouchCoordinates> = Set()
    
    init(
        tint: Color,
        label: String,
        location: SliderCoordinates,
        onTap: (() -> Void)? = nil,
        onRelease: (() -> Void)? = nil,
        onPress: (() -> Void)? = nil,
    ) {
        self.tint = tint
        self.label = label
        self.location = location
        self.onTap = onTap
        self.onPress = onPress
        self.onRelease = onRelease
    }
}

extension SliderButton: SliderPlaceable {
    var color: Color {
        if pressCoordinates.isEmpty {
            tint
        } else {
            tint.opacity(0.6)
        }
    }
    
    func hitTest(point: SliderTouchCoordinates, newState: Bool, overallState: Bool) {
        if location.contains(point) {
            if pressCoordinates.contains(point) && !newState {
                pressCoordinates.remove(point)
                
                if pressCoordinates.isEmpty {
                    onRelease?()
                    
                    if !overallState {
                        onTap?()
                    }
                }
            } else if !pressCoordinates.contains(point) {
                if pressCoordinates.isEmpty {
                    onPress?()
                }
                pressCoordinates.insert(point)
            }
        }
    }
}
