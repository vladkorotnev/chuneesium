//
//  Randomizer.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/08.
//

import Foundation

final class LEDEffectRandomizer: LEDEffect {
    private let numberOfLoops: Int
    private var effects: [LEDEffect]
    private var currentIndex: Int?
    private var playCount = 0
    
    private var curEffect: LEDEffect? {
        guard let currentIndex, effects.indices.contains(currentIndex) else { return nil }
        return effects[currentIndex]
    }
    
    /// - Parameter numberOfLoops: Number of effects to play before finishing. Use 0 for infinite looping.
    init(effects: [LEDEffect], numberOfLoops: Int = 1) {
        self.effects = effects
        self.numberOfLoops = numberOfLoops
        pickRandomEffect()
    }
    
    var isFinished: Bool {
        numberOfLoops > 0 && playCount >= numberOfLoops && curEffect?.isFinished != false
    }
    
    func draw(on display: LEDDisplay) {
        guard !effects.isEmpty, let curEffect else { return }
        
        curEffect.draw(on: display)
        
        if curEffect.isFinished {
            playCount += 1
            
            if numberOfLoops == 0 || playCount < numberOfLoops {
                curEffect.reset()
                pickRandomEffect()
            }
        }
    }
    
    func reset() {
        effects.forEach { $0.reset() }
        playCount = 0
        pickRandomEffect()
    }
    
    func react(to event: ControlEvent) {
        curEffect?.react(to: event)
    }
    
    private func pickRandomEffect() {
        guard !effects.isEmpty else {
            currentIndex = nil
            return
        }
        
        if effects.count == 1 {
            currentIndex = 0
            return
        }
        
        // Avoid picking the same effect twice in a row
        var newIndex: Int
        repeat {
            newIndex = Int.random(in: 0..<effects.count)
        } while newIndex == currentIndex
        
        currentIndex = newIndex
    }
}
