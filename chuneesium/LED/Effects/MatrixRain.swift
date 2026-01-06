//
//  MatrixRain.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/06.
//

import Foundation

/// A "Matrix"-style green digital rain effect.
/// - Renders vertical columns of falling green pixels with fading trails.
/// - Uses a soft brightness field so trails decay smoothly over time.
final class LEDMatrixRain: LEDEffect {
    // The physical height of the LED strips.
    private let height = 10
    
    // Per-column drop head positions (in continuous Y space).
    private var headPositions: [Double] = []
    // Per-column fall speeds (pixels per frame).
    private var speeds: [Double] = []
    // Per-pixel brightness buffer (0.0 ... 1.0).
    private var brightness: [[Double]] = []
    
    // Configurable behavior.
    private let minSpeed: Double = 0.15
    private let maxSpeed: Double = 0.45
    private let trailLength: Double = 6.0
    private let decayFactor: Double = 0.75
    
    private var isInitialized = false
    private var lastWidth: Int = 0
    
    // This effect is intended to run indefinitely.
    var isFinished: Bool { false }
    
    func reset() {
        isInitialized = false
        headPositions = []
        speeds = []
        brightness = []
        lastWidth = 0
    }
    
    func draw(on display: LEDDisplay) {
        let width = display.columnCount
        guard width > 0 else { return }
        
        if !isInitialized || width != lastWidth {
            initializeState(width: width)
        }
        
        // 1. Fade existing trails.
        for x in 0..<width {
            for y in 0..<height {
                brightness[x][y] *= decayFactor
            }
        }
        
        // 2. Advance drop heads and inject new brightness along each column.
        for x in 0..<width {
            headPositions[x] += speeds[x]
            
            let limit = Double(height) + trailLength
            if headPositions[x] > limit {
                // Restart slightly above the visible area for a staggered look.
                headPositions[x] = Double.random(in: -trailLength...0.0)
                speeds[x] = Double.random(in: minSpeed...maxSpeed)
            }
            
            let head = headPositions[x]
            // Illuminate pixels within trailLength behind the head.
            for y in 0..<height {
                let distance = head - Double(y)
                if distance >= 0.0 && distance <= trailLength {
                    let value = max(0.0, 1.0 - distance / trailLength)
                    if value > brightness[x][y] {
                        brightness[x][y] = value
                    }
                }
            }
        }
        
        // 3. Render brightness buffer as green pixels.
        for x in 0..<width {
            for y in 0..<height {
                let b = max(0.0, min(1.0, brightness[x][y]))
                
                // Base Matrix green with subtle gradient in intensity.
                let green = UInt8(10 + Int(215.0 * b))
                let color = SliderColor(r: 0, g: green, b: 0)
                
                display.setPixel(x: x, y: y, color: color)
            }
        }
    }
    
    // MARK: - Private
    
    private func initializeState(width: Int) {
        lastWidth = width
        isInitialized = true
        
        headPositions = (0..<width).map { _ in
            // Start each column at a random position above the visible area.
            Double.random(in: -trailLength...Double(height))
        }
        
        speeds = (0..<width).map { _ in
            Double.random(in: minSpeed...maxSpeed)
        }
        
        brightness = Array(
            repeating: Array(repeating: 0.0, count: height),
            count: width
        )
    }
}

