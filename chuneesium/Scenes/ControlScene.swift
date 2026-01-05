//
//  Scene.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/04.
//

protocol ScenePlaceable {
    var sliderItem: SliderPlaceable { get }
}

struct Scene {
    var items: [ScenePlaceable]
    var binding: SceneActivationBinding
}
