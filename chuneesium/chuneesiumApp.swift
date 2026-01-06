//
//  chuneesiumApp.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/01.
//

import SwiftUI

@main
struct chuneesiumApp: App {
    @Environment(\.openWindow) private var openWindow
    @NSApplicationDelegateAdaptor(ChuneesiumAppDelegate.self) var appDelegate
    @StateObject private var vm: AppViewModel = AppViewModel()
    @State private var ledSimEnabled = false
    
    var body: some Scene {
        Window("LED", id: "ledSim") {
            HStack(spacing: 20) {
                if ledSimEnabled {
                    LEDColumn(stripData: vm.leftSurface.airTowerSeparateColors)
                    LEDPreviewer(left: vm.leftSurface, right: vm.rightSurface)
                    LEDColumn(stripData: vm.rightSurface.airTowerSeparateColors)
                }
            }
            .onDisappear {
                ledSimEnabled = false
            }
            .padding()
            .background(.black)
        }
        .windowResizability(.contentSize)
        
        Settings {
            VStack {
                HStack {
                    Picker("Slider:", selection: $vm.sliderPortName) {
                        ForEach(vm.allSerialPorts, id: \.self) {
                            Text($0)
                        }
                    }
                    .disabled(vm.isSliderConnected)
                    Button {
                        vm.reconnectSlider()
                    } label: {
                        Image(systemName: vm.isSliderConnected ? "cable.connector.slash" : "cable.connector")
                    }
                }
                
                HStack {
                    VStack {
                        Picker("Left LED:", selection: $vm.leftLedPortName) {
                            ForEach(vm.allSerialPorts, id: \.self) {
                                Text($0)
                            }
                        }
                        Picker("Right LED:", selection: $vm.rightLedPortName) {
                            ForEach(vm.allSerialPorts, id: \.self) {
                                Text($0)
                            }
                        }
                    }
                    .disabled(vm.isLedConnected)
                    Button {
                        vm.reconnectLed()
                    } label: {
                        Image(systemName: vm.isLedConnected ? "cable.connector.slash" : "cable.connector")
                    }
                }
                Slider(value: $vm.ledBrightness, in: 0.3...1.0, minimumValueLabel: Image(systemName: "sun.min"), maximumValueLabel: Image(systemName: "sun.max"), label: { Text("Brightness") } )
                
            }
            .frame(width: 500.0)
            .padding()
        }
        .commands {
            CommandMenu("LED") {
                Button("Show simulator") {
                    openWindow(id: "ledSim")
                    ledSimEnabled = true
                }
                .keyboardShortcut("l", modifiers: .command)
            }
        }
    }
}
