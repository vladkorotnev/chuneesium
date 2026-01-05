//
//  MIDIIO.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/04.
//

import Foundation
import MIDIKitCore
import MIDIKitIO

final class MIDIIO {
    private let outputTag = "midi_cncs_o"
    private let inputTag = "midi_cncs_i"
    
    private let manager = MIDIManager(
        clientName: "ChuneesiumMIDIManager",
        model: "Chuneesium",
        manufacturer: "DJ AKASAKA"
    )
    
    var onEvent: ((MIDIEvent) -> Void)?
    
    init() {
        do {
            try manager.start()
            try manager.addInput(
                name: "Control Surface I",
                tag: inputTag,
                uniqueID: .userDefaultsManaged(key: "midi_cncs1", suite: UserDefaults.standard),
                receiver: .events(options: [], { [weak self] events, _, _ in
                    Task { @MainActor [weak self] in
                        events.forEach { self?.onEvent?($0) }
                    }
                })
            )
            try manager.addOutput(
                name: "Control Surface O",
                tag: outputTag,
                uniqueID: .userDefaultsManaged(key: "midi_cncs2", suite: UserDefaults.standard)
            )
        } catch {
            print("Error while starting MIDI manager: \(error)")
        }
    }
    
    public func executeAction(_ action: ActionBinding?, state: ActionEventState) {
        guard let action, let port = manager.managedOutputs[outputTag] else { return }
        do {
            switch action {
            case .note(let channel, let value):
                let event = {
                    switch state {
                    case .press:
                        return MIDIEvent.noteOn(UInt7(value), velocity: .midi1(127), channel: UInt4(channel))
                    case .release:
                        return MIDIEvent.noteOff(UInt7(value), velocity: .midi1(127), channel: UInt4(channel))
                    case .value(let int):
                        return MIDIEvent.noteOn(UInt7(value), velocity: .midi1(UInt7(int)), channel: UInt4(channel))
                    }
                }()
                try port.send(event: event)
            case .controlChange(let channel, let control):
                let value = UInt7({
                    switch state {
                    case .press:
                        return 127
                    case .release:
                        return 0
                    case .value(let int):
                        return int
                    }
                }())
                try port.send(event: .cc(.init(number: UInt7(control)), value: .midi1(value), channel: UInt4(channel)))
                
            case .switchScene(_): fatalError("How did this get here?")
            }
        }
        catch {
            print("Action \(action) failed: \(error)")
        }
    }
}

