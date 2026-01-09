//
//  DeckPhaseLEDViewModel.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/08.
//

import Combine
import Foundation

/// Manages LED air tower colors based on deck phase and end-of-track states.
///
/// When `DECK_A_END_STATE` arrives with raw value 1:
/// - Switches the base color to the end color (e.g., red)
///
/// When `DECK_A_END_STATE` arrives with raw value 0:
/// - Switches the base color back to the phase color (e.g., green)
///
/// When `DECK_A_PHASE_STATE` arrives:
/// - Displays a moving bright spot across the 3 air tower LEDs based on the phase value
final class DeckPhaseLEDViewModel {
    private weak var surface: LEDSurface?
    private let phaseBinding: LightBinding
    private let endStateBinding: LightBinding
    
    private let phaseColor: SliderColor
    private let endColor: SliderColor
    private var baseColor: SliderColor
    
    private var isInEndState = false
    
    /// Creates a new DeckPhaseLEDViewModel.
    /// - Parameters:
    ///   - surface: The LED surface to control
    ///   - phaseBinding: The MIDI binding for phase state events (e.g., `DECK_A_PHASE_STATE`)
    ///   - endStateBinding: The MIDI binding for end-of-track events (e.g., `DECK_A_END_STATE`)
    ///   - phaseColor: The base color to use for normal phase display (defaults to green)
    ///   - endColor: The color to use when track is ending (defaults to red)
    init(
        surface: LEDSurface,
        phaseBinding: LightBinding,
        endStateBinding: LightBinding,
        phaseColor: SliderColor = SliderColor(r: 0, g: 255, b: 0),
        endColor: SliderColor = SliderColor(r: 255, g: 0, b: 0)
    ) {
        self.surface = surface
        self.phaseBinding = phaseBinding
        self.endStateBinding = endStateBinding
        self.phaseColor = phaseColor
        self.endColor = endColor
        self.baseColor = phaseColor
    }
    
    /// Process an incoming MIDI event.
    /// - Parameter event: The MIDI event to process
    func receive(event: ControlEvent) {
        // Check for end state changes first
        if let endRawValue = endStateBinding.extractRawValue(event) {
            if endRawValue >= 0.5 {
                baseColor = endColor
            } else {
                baseColor = phaseColor
            }
            return
        }
        
        
        // Check for phase state changes
        if let phaseRawValue = phaseBinding.extractRawValue(event) {
            setPhaseColors(phase: phaseRawValue)
        }
    }
    
    /// Sets the air tower colors as a moving bright spot based on the phase value.
    /// - Parameter phase: The phase value from 0.0 to 1.0
    private func setPhaseColors(phase: Double) {
        // Each LED has a position: 0.0, 0.5, 1.0
        // The brightness is based on how close the phase is to each LED's position
        let ledPositions: [Double] = [0.0, 0.5, 1.0]
        let spotWidth: Double = 0.4 // Controls how wide the bright spot is
        
        let colors = ledPositions.map { position -> SliderColor in
            let distance = abs(phase - position)
            // Use a smooth falloff: 1.0 at center, fading to ~0.1 at edges
            let brightness = max(0.1, 1.0 - (distance / spotWidth))
            return baseColor.multiply(brightness: brightness)
        }
        
        surface?.airTowerSeparateColors = colors
    }
}
