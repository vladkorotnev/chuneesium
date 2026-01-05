//
//  LEDEffect.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/05.
//

import Foundation

protocol LEDEffect {
    var isFinished: Bool { get }
    func draw(on display: LEDDisplay)
}

final class LEDEffectPlayer {
    private let display: LEDDisplay
    var interval: TimeInterval = 0.033 {
        didSet {
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: { [weak self] _ in
                self?.tick()
            })
        }
    }
    var currentEffect: LEDEffect?
    private var timer: Timer? = nil
    
    init(display: LEDDisplay) {
        self.display = display
        self.timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: { [weak self] _ in
            self?.tick()
        })
    }
    
    private func tick() {
        guard let currentEffect else { return }
        currentEffect.draw(on: display)
        display.push()
    }
}
