//
//  ButtonControl.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/04.
//

import SwiftUI

final class ButtonControl {
    private let tint: SceneControlColor
    private let button: SliderButton
    let action: ActionBinding
    let holdAction: ActionBinding?
    weak var controller: SceneController?
    
    init(
        tint: SceneControlColor,
        label: String,
        position: Int,
        width: Int,
        action: ActionBinding,
        isDirect: Bool = false,
        holdAction: ActionBinding? = nil
    ) {
        self.tint = tint
        self.holdAction = holdAction
        button = SliderButton(tint: tint.baseColor, label: label, location: .init(left: position, width: width))
        self.action = action
        if !isDirect {
            button.onTap = { [weak self] in
                guard let self else { return }
                self.controller?.executeAction(self.action, state: .value(0))
            }
        } else {
            button.onPress = { [weak self] in
                guard let self else { return }
                self.controller?.executeAction(self.action, state: .press)
            }
            button.onRelease = { [weak self] in
                guard let self else { return }
                self.controller?.executeAction(self.action, state: .release)
            }
        }
        if holdAction != nil {
            button.onHold = { [weak self] in
                guard let self else { return }
                self.controller?.executeAction(self.holdAction, state: .value(0))
            }
        }
    }
}

extension ButtonControl: ControlScenePlaceable {
    var sliderItem: any SliderPlaceableRaw {
        button
    }
    
    func onEvent(_ event: ControlEvent) -> Bool {
        if let newTint = self.tint.resolveAgainst(event: event) {
            button.tint = newTint
            return true
        }
        return false
    }
}
