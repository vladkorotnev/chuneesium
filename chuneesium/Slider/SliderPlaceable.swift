//
//  SliderPlaceable.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/01.
//

import SwiftUI

struct SliderCoordinates {
    var left: Int
    var width: Int
}

struct SliderTouchCoordinates: Hashable {
    var row: Int
    var column: Int
}

extension SliderCoordinates {
    func contains(_ point: SliderTouchCoordinates) -> Bool {
        self.left <= point.column && (self.left + self.width) > point.column
    }
}

protocol SliderPlaceable {
    var location: SliderCoordinates { get }
    var color: Color { get }
    var label: String { get }
    
    func hitTest(point: SliderTouchCoordinates, newState: Bool, overallState: Bool)
}
