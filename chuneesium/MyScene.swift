//
//  MyScene.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/04.
//

import SwiftUI

let MY_SCENE = [
    // MARK: - Root
    ControlScene(
        id: "root",
        items: [
            // Deck A transport
            ButtonControl(
                tint: .dynamic(color: .green, binding: .note(channel: 1, value: 2)),
                label: "Play",
                position: 0,
                width: 1,
                action: .note(channel: 1, value: 2),
                isDirect: true
            ),
            ButtonControl(
                tint: .dynamic(color: .cyan, binding: .note(channel: 1, value: 1)),
                label: "Cue",
                position: 1,
                width: 1,
                action: .note(channel: 1, value: 1),
                isDirect: true
            ),
            ButtonControl(
                tint: .constant(.orange),
                label: "Filter",
                position: 2,
                width: 1,
                action: .setScene(content: ControlScene(
                    id: "filterA",
                    items: [
                        FaderControl(
                            label: "Filter A",
                            position: 0,
                            width: 14,
                            action: .controlChange(channel: 1, control: 0),
                            initialValue: 0.5,
                            background: .orange,
                            notches: .purple,
                            handle: .white
                        ),
                        ButtonControl(
                            tint: .constant(.blue),
                            label: "Return",
                            position: 14,
                            width: 2,
                            action: .switchScene(id: nil)
                        ),
                    ]
                )),
                holdAction: .setScene(content: ControlScene(
                    id: "filterA_autoClose",
                    items: [
                        FaderControl(
                            label: "Filter A",
                            position: 0,
                            width: 16,
                            action: .controlChange(channel: 1, control: 0),
                            initialValue: 0.5,
                            background: .orange,
                            notches: .purple,
                            handle: .white,
                            afterUntouch: .switchScene(id: nil),
                        ),
                    ]
                ))
            ),
            ButtonControl(
                tint: .constant(.indigo),
                label: "FX 1",
                position: 3,
                width: 1,
                action: .setScene(content: ControlScene(
                    id: "fxA",
                    items: [
                        XYControl(
                            label: "FX A",
                            background: .indigo,
                            position: 0,
                            width: 14,
                            xAction: .controlChange(channel: 3, control: 0),
                            yAction: .controlChange(channel: 3, control: 1),
                            onUntouch: .switchScene(id: nil)
                        ),
                        ButtonControl(
                            tint: .constant(.blue),
                            label: "Return",
                            position: 14,
                            width: 2,
                            action: .switchScene(id: nil)
                        ),
                    ]
                )),
                holdAction: .setScene(content: ControlScene(
                    id: "fxA_autoClose",
                    items: [
                        XYControl(
                            label: "FX A",
                            background: .indigo,
                            position: 0,
                            width: 16,
                            xAction: .controlChange(channel: 3, control: 0),
                            yAction: .controlChange(channel: 3, control: 1),
                            onUntouch: .switchScene(id: nil)
                        ),
                    ]
                ))
            ),
            ButtonControl(
                tint: .dynamic(color: .gray, binding: .note(channel: 1, value: 3)),
                label: "Low",
                position: 4,
                width: 1,
                action: .note(channel: 1, value: 3),
                holdAction: .setScene(content: ControlScene(
                    id: "lowA_autoClose",
                    items: [
                        FaderControl(
                            label: "EQ Low A",
                            position: 0,
                            width: 16,
                            action: .controlChange(channel: 1, control: 3),
                            initialValue: 0.5,
                            background: .black,
                            notches: .green,
                            handle: .white,
                            afterUntouch: .switchScene(id: nil),
                        ),
                    ]
                ))
            ),
            ButtonControl(
                tint: .dynamic(color: .gray, binding: .note(channel: 1, value: 4)),
                label: "Mid",
                position: 5,
                width: 1,
                action: .note(channel: 1, value: 4),
                holdAction: .setScene(content: ControlScene(
                    id: "midA_autoClose",
                    items: [
                        FaderControl(
                            label: "EQ Mid A",
                            position: 0,
                            width: 16,
                            action: .controlChange(channel: 1, control: 4),
                            initialValue: 0.5,
                            background: .black,
                            notches: .yellow,
                            handle: .white,
                            afterUntouch: .switchScene(id: nil),
                        ),
                    ]
                ))
            ),
            ButtonControl(
                tint: .dynamic(color: .gray, binding: .note(channel: 1, value: 5)),
                label: "High",
                position: 6,
                width: 1,
                action: .note(channel: 1, value: 5),
                holdAction: .setScene(content: ControlScene(
                    id: "highA_autoClose",
                    items: [
                        FaderControl(
                            label: "EQ High A",
                            position: 0,
                            width: 16,
                            action: .controlChange(channel: 1, control: 5),
                            initialValue: 0.5,
                            background: .black,
                            notches: .red,
                            handle: .white,
                            afterUntouch: .switchScene(id: nil),
                        ),
                    ]
                ))
            ),
            
            // middle
            ButtonControl(
                tint: .dynamic(color: .red, binding: .either(of: [
                    .note(channel: 0, value: 126),
                    .note(channel: 0, value: 127)
                ])),
                label: "Song Select",
                position: 7,
                width: 1,
                action: .note(channel: 0, value: 0) //<- not using setScene here because this is a 2-way binding (can be activated via Traktor GUI)
            ),
            ButtonControl(
                tint: .constant(.purple),
                label: "X-Fader",
                position: 8,
                width: 1,
                action: .setScene(content: ControlScene(
                    id: "xfader",
                    items: [
                        FaderControl(
                            label: "X-Fader",
                            position: 0,
                            width: 14,
                            action: .controlChange(channel: 2, control: 0),
                            initialValue: 0.5,
                            background: .black,
                            notches: .white,
                            handle: .red,
                        ),
                        ButtonControl(
                            tint: .constant(.blue),
                            label: "Return",
                            position: 14,
                            width: 2,
                            action: .switchScene(id: nil)
                        ),
                    ]
                )),
                holdAction: .setScene(
                    content: ControlScene(
                        id: "xfader_autoClose",
                        items: [
                            FaderControl(
                                label: "X-Fader",
                                position: 0,
                                width: 16,
                                action: .controlChange(channel: 2, control: 0),
                                initialValue: 0.5,
                                background: .black,
                                notches: .white,
                                handle: .red,
                                afterUntouch: .switchScene(id: nil),
                            ),
                        ]
                    )
                )
            ),
        ],
        binding: .default
    ),
  
           
    // MARK: - Song Selection Controls
    ControlScene(
        id: "song_select",
        items: [
            ButtonControl(tint: .constant(.green), label: "Up", position: 0, width: 3, action: .note(channel: 0, value: 1)),
            ButtonControl(tint: .constant(.green), label: "Down", position: 3, width: 3, action: .note(channel: 0, value: 2)),
            ButtonControl(tint: .constant(.red), label: "Load A", position: 6, width: 3, action: .note(channel: 0, value: 3)),
            ButtonControl(tint: .constant(.red), label: "Load B", position: 9, width: 3, action: .note(channel: 0, value: 4)),
            ButtonControl(tint: .constant(.blue), label: "Return", position: 14, width: 2, action: .note(channel: 0, value: 0)),
        ],
        binding: .controlChange(channel: 0, control: 0, value: 1)
    )
]
