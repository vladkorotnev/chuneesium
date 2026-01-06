//
//  Rainbow.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/05.
//

final class LEDRainbow: LEDEffect {
    private var currentColor = SliderColor(r: 255, g: 0, b: 0)
    private var phase = 0
    private let step = 10
    var endless: Bool
    var loopCount: Int {
        didSet { loopTime = 0 }
    }
    var loopTime: Int = 0
    var outro = 0
    
    init(
        endless: Bool,
        loopCount: Int = 1
    ) {
        self.endless = endless
        self.loopCount = 2
    }
    
    var isFinished: Bool {
        phase == 6
    }
    
    func reset() {
        phase = 0
        loopTime = 0
        currentColor = .init(r: 255, g: 0, b: 0)
    }
    
    func draw(on display: LEDDisplay) {
        if phase == 0 {
            if currentColor.r == 255 {
                phase = 1
            } else {
                currentColor.b = UInt8(max(Int(currentColor.b) - step, 0))
                currentColor.r = UInt8(min(255, Int(currentColor.r) + step))
            }
        } else if phase == 1 {
            if currentColor.g == 255 {
                phase = 2
            } else {
                currentColor.r = UInt8(max(Int(currentColor.r) - step, 0))
                currentColor.g = UInt8(min(255, Int(currentColor.g) + step))
            }
        } else if phase == 2 {
            if currentColor.b == 255 {
                if endless || loopTime < loopCount - 1 {
                    phase = 0
                    if !endless { loopTime += 1 }
                } else {
                    phase = 4
                }
            } else {
                currentColor.g = UInt8(max(Int(currentColor.g) - step, 0))
                currentColor.b = UInt8(min(255, Int(currentColor.b) + step))
            }
        } else if phase == 4 {
            if currentColor.b == 0 {
                phase = 5
            } else {
                currentColor.b = UInt8(max(Int(currentColor.g) - step, 0))
            }
        } else if phase == 5 {
            if outro == 11 {
                phase = 6
            } else {
                outro += 1
            }
        }
        
        display.hShift(count: 1, inserting: .init(repeating: currentColor, count: 10))
    }
}
