//
//  Soundwave.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/06.
//

import Foundation

final class LEDSoundwaveMiddle: LEDEffect {
    private var samples: [Double] = [
        0.3, 0.6, 1.0, 0.5, 0.1, 0.1, 0.2, 0.3, 0.6, 0.5, 0.2
    ]
    var color: SliderColor
    private let binding: LightBinding
    private var offset = 11
    
    init(
        color: SliderColor,
        source: LightBinding
    ) {
        self.color = color
        self.binding = source
    }
    
    var isFinished: Bool {
        false
    }
    
    private func columnForSample(_ sample: Double) -> [SliderColor] {
        // 1. Prevent log2(0) which is -Infinity
            let safeSample = max(sample, 0.001) // 0.001 is -60dB (the "floor")
            
            // 2. Convert to a 0.0...1.0 scale where 1.0 is loud
            // We use -60dB as the floor. log2(0.001) is approx -9.96.
            // A simpler way is to map the log range:
            let minDb: Double = -3.0
            let db = 20 * log10(safeSample)
            
            // Normalize dB to a 0...1 range
            // (db - minDb) / (maxDb - minDb) -> (db - (-60)) / (0 - (-60))
            let normalized = max(0, (db - minDb) / abs(minDb))
            
            // 3. Map to your 0...5 range
            let targetHeight = normalized * 5.0
        
        var halfColumn = Array(repeating: SliderColor(), count: 5)
        
        for i in 0..<5 {
            let pixelIndex = Double(i)
            
            if targetHeight >= pixelIndex + 1.0 {
                // Pixel is fully "inside" the waveform height
                halfColumn[i] = color
            } else if targetHeight > pixelIndex {
                // This is the "Edge" pixel - calculate fractional brightness
                let fractionalBrightness = targetHeight - pixelIndex
                halfColumn[i] = color.multiply(brightness: fractionalBrightness)
            } else {
                // Pixel is outside the waveform
                halfColumn[i] = .init()
            }
        }
        
        return halfColumn.reversed() + halfColumn
    }
    
    func draw(on display: LEDDisplay) {
        for i in offset..<display.columnCount {
            display.setColumn(x: i, column: columnForSample(samples[i - offset]).map { $0.multiply(brightness: Double(i) / Double(display.columnCount-1)) })
        }
        
        if offset > 0 {
            offset -= 1
        }
    }
    
    func pushSample(value: Double) {
        samples.append(value)
        samples.removeFirst()
    }
    
    func reset() {
        offset = 11
    }
    
    func react(to event: ControlEvent) {
        guard let value = binding.extractRawValue(event) else { return }
        pushSample(value: value)
    }
}


final class LEDSoundwaveFull: LEDEffect {
    private var samples: [Double] = [
        0.3, 0.6, 1.0, 0.5, 0.1, 0.1, 0.2, 0.3, 0.6, 0.5, 0.2
    ]
    var color: SliderColor
    private let binding: LightBinding
    private var offset = 11
    
    init(
        color: SliderColor,
        source: LightBinding
    ) {
        self.color = color
        self.binding = source
    }
    
    var isFinished: Bool {
        false
    }
    
    private func columnForSample(_ sample: Double) -> [SliderColor] {
        // 1. Prevent log2(0) which is -Infinity
            let safeSample = max(sample, 0.001) // 0.001 is -60dB (the "floor")
            
            // 2. Convert to a 0.0...1.0 scale where 1.0 is loud
            // We use -60dB as the floor. log2(0.001) is approx -9.96.
            // A simpler way is to map the log range:
            let minDb: Double = -4.0
            let db = 20 * log10(safeSample)
            
            // Normalize dB to a 0...1 range
            // (db - minDb) / (maxDb - minDb) -> (db - (-60)) / (0 - (-60))
            let normalized = max(0, (db - minDb) / abs(minDb))
            
            // 3. Map to your 0...5 range
            let targetHeight = normalized * 10.0
        
        var halfColumn = Array(repeating: SliderColor(), count: 10)
        
        for i in 0..<10 {
            let pixelIndex = Double(i)
            
            if targetHeight >= pixelIndex + 1.0 {
                // Pixel is fully "inside" the waveform height
                halfColumn[i] = color
            } else if targetHeight > pixelIndex {
                // This is the "Edge" pixel - calculate fractional brightness
                let fractionalBrightness = targetHeight - pixelIndex
                halfColumn[i] = color.multiply(brightness: fractionalBrightness)
            } else {
                // Pixel is outside the waveform
                halfColumn[i] = .init()
            }
        }
        
        return halfColumn.reversed()
    }
    
    func draw(on display: LEDDisplay) {
        for i in offset..<display.columnCount {
            display.setColumn(x: i, column: columnForSample(samples[i - offset]).map { $0.multiply(brightness: Double(i) / Double(display.columnCount-1)) })
        }
        
        if offset > 0 {
            offset -= 1
        }
    }
    
    func pushSample(value: Double) {
        samples.append(value)
        samples.removeFirst()
    }
    
    func reset() {
        offset = 11
    }
    
    func react(to event: ControlEvent) {
        guard let value = binding.extractRawValue(event) else { return }
        pushSample(value: value)
    }
}

final class LEDVolumeBar: LEDEffect {
    private var sample = 0.0
    private var peak = 0.0
    var color: SliderColor
    private let binding: LightBinding
    
    init(
        color: SliderColor,
        source: LightBinding
    ) {
        self.color = color
        self.binding = source
    }
    
    var isFinished: Bool {
        false
    }
    
    private func columnForSample(_ sample: Double) -> [SliderColor] {
        let safeSample = max(sample, 0.001) // 0.001 is -60dB (the "floor")
        
        // 2. Convert to a 0.0...1.0 scale where 1.0 is loud
        // We use -60dB as the floor. log2(0.001) is approx -9.96.
        // A simpler way is to map the log range:
        let minDb: Double = -3.0
        let db = 20 * log10(safeSample)
        
        // Normalize dB to a 0...1 range
        // (db - minDb) / (maxDb - minDb) -> (db - (-60)) / (0 - (-60))
        let normalized = max(0, (db - minDb) / abs(minDb))
        
        // 3. Map to your 0...5 range
        let targetHeight = normalized * 10.0
        if targetHeight > peak {
            peak = targetHeight
        } else {
            peak *= 0.95
        }
    
        var halfColumn = Array(repeating: SliderColor(), count: 10)
        
        for i in 0..<10 {
            let pixelIndex = Double(i)
            
            if targetHeight >= pixelIndex + 1.0 {
                // Pixel is fully "inside" the waveform height
                halfColumn[i] = color
            } else if targetHeight > pixelIndex {
                // This is the "Edge" pixel - calculate fractional brightness
                let fractionalBrightness = targetHeight - pixelIndex
                halfColumn[i] = color.multiply(brightness: fractionalBrightness)
            } else {
                // Pixel is outside the waveform
                halfColumn[i] = .init()
            }
            
            if peak >= pixelIndex, peak < pixelIndex + 1.0 {
                halfColumn[i] = .init(r: 128)
            }
        }
        
        return halfColumn.reversed()
    }
    
    func draw(on display: LEDDisplay) {
        let rslt = columnForSample(sample)
        for i in 0..<display.columnCount {
            display.setColumn(x: i, column: (i % 2 == 0) ? rslt : rslt.reversed())
        }
    }
    
    func react(to event: ControlEvent) {
        guard let value = binding.extractRawValue(event) else { return }
        sample = value
    }
}
