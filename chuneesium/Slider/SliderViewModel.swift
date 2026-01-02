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
    let color: Color
    let label: String
}

enum SliderInputSource {
    case mouse
    case hardwareSlider
}

class SliderViewModel: ObservableObject {
    @Published var items: [SliderPlaceable]
    @Published var viewState: [SliderViewState]
    
    private var inputState: [SliderInputSource: Set<SliderTouchCoordinates>] = [:]
    let threshold = 40
    
    init(items: [SliderPlaceable]) {
        self.items = items
        self.viewState = []
        updateViewState()
    }
    
    private func updateViewState() {
        viewState = items
            .map { item in
                SliderViewState(location: item.location, color: item.color, label: item.label)
            }
        
    }

    func onInputUpdate(
        from source: SliderInputSource,
        state: [SliderTouchCoordinates: Int]
    ) {
        let state = Set(
            state
                .filter { $0.value >= threshold }
                .keys
        )
        
        let touches = inputState[source] ?? Set()
        
        let newTouches = state.subtracting(touches)
        let goneTouches = touches.subtracting(state)
        
        for item in items {
            for touch in newTouches {
                item.hitTest(point: touch, newState: true, overallState: !state.isEmpty)
            }
            
            for touch in goneTouches {
                item.hitTest(point: touch, newState: false, overallState: !state.isEmpty)
            }
        }
        
        inputState[source] = state
        
        updateViewState()
    }
}
