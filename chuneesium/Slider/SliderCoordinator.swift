//
//  SliderButtonBar.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/02.
//

import Combine
import SwiftUI

struct SliderViewState {
    let location: SliderCoordinates
    let labelTint: Color
    let label: String
    let colors: [Color]
}

enum SliderInputSource {
    case mouse
    case hardwareSlider
}

class SliderCoordinator: ObservableObject {
    @Published var items: [SliderPlaceableRaw] {
        didSet {
            updateViewState()
        }
    }
    
    @Published var viewState: [SliderViewState]
    @Published var columnTouchState: [Int] = []
    
    private var inputState: [SliderInputSource: Set<SliderTouchCoordinates>] = [:]
    let threshold = 40
    
    init(items: [SliderPlaceable]) {
        self.items = items
        self.viewState = []
        self.columnTouchState = []
        updateViewState()
    }
    
    func updateViewState() {
        viewState = items
            .map { item in
                SliderViewState(
                    location: item.location,
                    labelTint: item.labelTint,
                    label: item.label,
                    colors: item.colors.pattern(length: item.location.width * 2)
                )
            }
    }
    
    func onInputUpdate(
        from source: SliderInputSource,
        state rawState: [SliderTouchCoordinates: Int]
    ) {
        if source == .hardwareSlider {
            var columnState = Array(repeating: 0, count: 16)
            rawState.forEach { status in
                columnState[status.key.column] += status.value
            }
            for i in columnState.indices {
                columnState[i] /= 2
            }
            columnTouchState = columnState
        }
        
        let state = Set(
            rawState
                .filter { $0.value >= threshold }
                .keys
        )
        
        let touches = inputState[source] ?? Set()
        
        let newTouches = state.subtracting(touches)
        let goneTouches = touches.subtracting(state)
        let itemCopy = [] + items
        
        for item in itemCopy {
            for touch in newTouches {
                item.hitTestRaw(point: touch, newState: true, overallState: !state.isEmpty, value: rawState[touch] ?? 1)
            }
            
            for touch in goneTouches {
                item.hitTestRaw(point: touch, newState: false, overallState: !state.isEmpty, value: 0)
            }
        }
        
        inputState[source] = state
        
        updateViewState()
    }
}
