//
//  FaderControl.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/04.
//

import SwiftUI
import MIDIKitCore

final class FaderControl {
    private let fader: SliderFader
    let action: ActionBinding
    weak var controller: SceneController?
    let afterUntouch: ActionBinding?
    
    init(
        label: String,
        position: Int,
        width: Int,
        action: ActionBinding,
        initialValue: Double = 0.0,
        background: Color = .orange,
        notches: Color = .purple,
        handle: Color = .white,
        afterUntouch: ActionBinding? = nil,
        allowJump: Bool = false,
    ) {
        self.fader = SliderFader(
            label: label,
            location: .init(left: position, width: width),
            allowsJump: allowJump,
            value: initialValue,
            backdrop: background,
            ticks: notches,
            handle: handle
        )
        self.action = action
        self.afterUntouch = afterUntouch
        self.fader.onChange = { [weak self] newValue in
            self?.controller?.executeAction(self?.action, state: .value(Int(127.0 * newValue)))
        }
        self.fader.onTouchStateChange = { [weak self] touch in
            guard !touch else { return }
            self?.controller?.executeAction(self?.afterUntouch, state: .release)
        }
    }
}

extension FaderControl: ControlScenePlaceable {
    var sliderItem: any SliderPlaceableRaw {
        fader
    }
    
    func onEvent(_ event: ControlEvent) -> Bool {
        switch self.action {
        case .controlChange(channel: let channel, control: let control):
            if case let MIDIEvent.cc(payload) = event,
               payload.channel == channel,
               payload.controller.number == control {
                self.fader.value = Double(payload.value.midi1Value) / Double(127.0)
                return true
            }
            
        default: break
        }
        
        return false
    }
}
