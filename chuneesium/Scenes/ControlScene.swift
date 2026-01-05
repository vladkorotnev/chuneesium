//
//  Scene.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/04.
//

import MIDIKitCore
import SwiftUI

typealias ControlEvent = MIDIEvent

protocol ControlScenePlaceable {
    var sliderItem: SliderPlaceableRaw { get }
    var controller: SceneController? { get set }
    
    func onEvent(_ event: ControlEvent) -> Bool
}

final class ControlScene {
    var id: String?
    var items: [ControlScenePlaceable]
    var binding: SceneActivationBinding?
    
    init(id: String? = nil, items: [ControlScenePlaceable], binding: SceneActivationBinding? = nil) {
        self.id = id
        self.items = items
        self.binding = binding
    }
}
