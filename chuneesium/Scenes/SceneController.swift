//
//  SceneController.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/04.
//

import MIDIKitCore

final class SceneController {
    var scenes: [ControlScene] = []
    var onChange: ((ControlScene?) -> Void)?
    var onDirty: (() -> Void)?
    
    private(set) var activeScene: ControlScene?
    {
        didSet {
            refresh()
        }
    }
    
    private let slider: SliderCoordinator
    private let midi: MIDIIO
    
    init(
        slider: SliderCoordinator,
        midi: MIDIIO,
        scenes: [ControlScene] = []
    ) {
        self.scenes = scenes
        self.slider = slider
        self.midi = midi
        
        midi.onEvent = { [weak self] event in
            guard let self else { return }
            var isDirty = false
            self.activeScene?.items.forEach { item in
                if item.onEvent(event) {
                    isDirty = true
                }
            }
            
            if isDirty {
                onDirty?()
                isDirty = false
            }
            
            switch event {
            case let MIDIEvent.cc(payload):
                if let nextScene = self.find(for: .controlChange(channel: payload.channel.intValue, control: payload.controller.number.intValue, value: payload.value.midi1Value.intValue)) {
                    self.activeScene = nextScene
                } else if case let .controlChange(channel, control, value) = self.activeScene?.binding,
                          channel == payload.channel.intValue,
                          control == payload.controller.number.intValue,
                          value != payload.channel.intValue {
                    // same channel but other control value - fallback to default
                    activate(with: .default)
                }
            default: break
            }
        }
        
        activate(with: .default)
    }
    
    func activate(with binding: SceneActivationBinding) {
        activeScene = find(for: binding)
    }
    
    func activate(by id: String) {
        guard let scene = scenes.first(where: { $0.id == id }) else { return }
        activeScene = scene
    }
    
    private func find(for binding: SceneActivationBinding) -> ControlScene? {
        return scenes.first(where: { $0.binding == binding })
    }
    
    func refresh() {
        if let activeScene {
            for i in activeScene.items.indices {
                activeScene.items[i].controller = self
            }
        }
        onChange?(activeScene)
    }
    
    func executeAction(_ action: ActionBinding?, state: ActionEventState) {
        guard case let .switchScene(id) = action else {
            midi.executeAction(action, state: state)
            return
        }
        
        guard let id else {
            activate(with: .default)
            return
        }
        
        activate(by: id)
    }
}

