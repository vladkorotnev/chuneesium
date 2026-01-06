//
//  Sequencer.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/05.
//

import Foundation

final class LEDEffectSequencer: LEDEffect {
    var looping = true
    private var effects: [LEDEffect]
    private var position: Int = 0
    private var curEffect: LEDEffect? {
        effects[position]
    }
    
    init(effects: [LEDEffect]) {
        self.effects = effects
    }
    
    var isFinished: Bool {
        !looping && position == effects.count - 1 && curEffect?.isFinished != false
    }
    
    func draw(on display: LEDDisplay) {
        guard !effects.isEmpty, let curEffect else { return }
        
        curEffect.draw(on: display)
        
        if curEffect.isFinished {
            curEffect.reset()
            if position == effects.count-1 {
                position = 0
            } else {
                position += 1
            }
        }
    }
    
    func reset() {
        effects.forEach { $0.reset() }
    }
    
    func react(to event: ControlEvent) {
        curEffect?.react(to: event)
    }
}

final class LEDEffectTime: LEDEffect {
    var timeInterval: TimeInterval
    var start: Date?
    var effect: LEDEffect?
    
    init(
        timeInterval: TimeInterval,
        effect: LEDEffect? = nil
    ) {
        self.timeInterval = timeInterval
        self.effect = effect
    }
    
    var isFinished: Bool {
        guard let start else { return false }
        return start.timeIntervalSinceNow <= -timeInterval
    }
    
    func draw(on display: LEDDisplay) {
        if start == nil {
            start = Date()
        }
        
        effect?.draw(on: display)
    }
    
    func reset() {
        start = nil
        effect?.reset()
    }
    
    func react(to event: ControlEvent) {
        effect?.react(to: event)
    }
}
