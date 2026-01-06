//
//  SceneActivationBinding.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/04.
//

import MIDIKitCore
import SwiftUI

enum SceneActivationBinding: Hashable {
    case `default`
    case controlChange(channel: Int, control: Int, value: Int)
}

enum ActionBinding {
    case note(channel: Int, value: Int)
    case controlChange(channel: Int, control: Int)
    case switchScene(id: String?)
    case setScene(content: ControlScene)
}

enum LightBinding {
    case note(channel: Int, value: Int)
    case controlChange(channel: Int, control: Int)
    case either(of: [LightBinding])
}

extension LightBinding {
    func extractRawValue(_ event: ControlEvent?) -> Double? {
        guard let event else { return nil }
        
        switch self {
        case let .either(of: bindings):
            let results = bindings.map { $0.extractValue(event) }.compactMap { $0 }
            if results.isEmpty {
                return nil
            } else {
                return results.min()
            }
        case let .note(channel, value):
            if case let .noteOn(payload) = event,
               payload.channel.intValue == channel,
               payload.note.number.intValue == value {
                return Double(payload.velocity.midi1Value) / Double(127.0)
            }
            else if case let .noteOff(payload) = event,
                payload.channel.intValue == channel,
                payload.note.number.intValue == value {
                return 0
             }
        case let .controlChange(channel, control):
            if case let .cc(payload) = event,
               payload.channel.intValue == channel,
               payload.controller.number.intValue == control {
                return Double(payload.value.midi1Value) / Double(127.0)
            }
        }
        
        return nil
    }
    
    func extractValue(_ event: ControlEvent?) -> Double? {
        guard let extraction = extractRawValue(event) else { return nil }
        
        return min(1.0, 0.5 + extraction)
    }
}

enum SceneControlColor {
    case constant(Color)
    case dynamic(color: Color, binding: LightBinding)
}

extension SceneControlColor {
    var baseColor: Color {
        switch self {
        case let .constant(color): return color
        case let .dynamic(color, _): return color
        }
    }
    
    func resolveAgainst(event: ControlEvent?) -> Color? {
        guard let event else {
            return nil
        }
        
        switch self {
        case let .constant(color): return color
        case let .dynamic(color, binding):
            guard let multiplier = binding.extractValue(event) else { return nil }
            return color.opacity(multiplier)
        }
    }
}


enum ActionEventState {
    case press
    case release
    case value(Int)
}
