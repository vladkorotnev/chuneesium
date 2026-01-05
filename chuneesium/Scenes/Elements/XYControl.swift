//
//  XYControl.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/04.
//

import SwiftUI

final class XYControl {
    private let surface: SliderXY
    private let xAction: ActionBinding?
    private let yAction: ActionBinding?
    private let untouchAction: ActionBinding?
    var controller: SceneController?
    
    init(
        label: String,
        background: Color,
        position: Int,
        width: Int,
        xAction: ActionBinding? = nil,
        yAction: ActionBinding? = nil,
        onUntouch: ActionBinding? = nil
    ) {
        surface = SliderXY(
            label: label,
            location: .init(left: position, width: width),
            background: background
        )
        
        self.xAction = xAction
        self.yAction = yAction
        self.untouchAction = onUntouch
        
        surface.onChange = { [weak self] newValue in
            guard let controller = self?.controller else { return }
            controller.executeAction(self?.xAction, state: .value(Int(newValue.x * 127.0)))
            controller.executeAction(self?.yAction, state: .value(Int(newValue.y * 127.0)))
        }
        
        surface.onTouchStateChange = { [weak self] newState in
            guard !newState else { return }
            guard let controller = self?.controller else { return }
            controller.executeAction(self?.xAction, state: .value(0))
            controller.executeAction(self?.yAction, state: .value(0))
            controller.executeAction(self?.untouchAction, state: .value(0))
        }
    }
}

extension XYControl: ControlScenePlaceable {
    var sliderItem: any SliderPlaceableRaw {
        surface
    }
    
    func onEvent(_ event: ControlEvent) -> Bool {
        return false
    }
}
