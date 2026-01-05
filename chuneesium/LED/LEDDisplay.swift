//
//  LEDDisplay.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/05.
//

final class LEDDisplay {
    private let leftHalf: LEDSurface
    private let rightHalf: LEDSurface
    
    init(leftHalf: LEDSurface, rightHalf: LEDSurface) {
        self.leftHalf = leftHalf
        self.rightHalf = rightHalf
    }
    
    private func xToSurface(x: Int) -> (LEDSurface, Int)? {
        guard x >= 0, x < (leftHalf.stripCount + rightHalf.stripCount) else { return nil }
        
        let surface = {
            if x < leftHalf.stripCount {
                leftHalf
            } else {
                rightHalf
            }
        }()
        
        let localX = {
            if x < leftHalf.stripCount {
                x
            } else {
                leftHalf.stripCount - x
            }
        }()
        
        return (surface, localX)
    }
    
    func setColumn(x: Int, column: [SliderColor]) {
        guard let (surface, localX) = xToSurface(x: x) else { return }
        surface.pixelGrid[localX] = column
    }
    
    func setPixel(x: Int, y: Int, color: SliderColor) {
        guard let (surface, localX) = xToSurface(x: x) else { return }
        surface.pixelGrid[localX][y] = color
    }
    
    func hShift(count: Int, inserting column: [SliderColor] = .init(repeating: .init(), count: 10)) {
        if count > 0 {
            let carry = leftHalf.pixelGrid.removeLast()
            leftHalf.pixelGrid.insert(column, at: 0)
            rightHalf.pixelGrid.insert(carry, at: 0)
            let _ = rightHalf.pixelGrid.removeLast()
        } else if count < 0 {
            let carry = rightHalf.pixelGrid.removeFirst()
            leftHalf.pixelGrid.append(carry)
            rightHalf.pixelGrid.append(column)
            let _ = leftHalf.pixelGrid.removeFirst()
        }
    }
    
    func push() {
        leftHalf.push()
        rightHalf.push()
    }
}
