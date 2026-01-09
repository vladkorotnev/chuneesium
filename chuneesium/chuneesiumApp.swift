//
//  chuneesiumApp.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/01.
//

import SwiftUI
import AppKit
internal import UniformTypeIdentifiers

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
                    AirTowerLEDColumn(surface: vm.leftSurface)
                    LEDPreviewer(left: vm.leftSurface, right: vm.rightSurface)
                    AirTowerLEDColumn(surface: vm.rightSurface)
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
                
                HStack {
                    Picker("JVS IO:", selection: $vm.jvsPortName) {
                        ForEach(vm.allSerialPorts, id: \.self) {
                            Text($0)
                        }
                    }
                    .disabled(vm.isJVSConnected)
                    Button {
                        vm.reconnectJVS()
                    } label: {
                        Image(systemName: vm.isJVSConnected ? "cable.connector.slash" : "cable.connector")
                    }
                }
                
                if vm.isJVSConnected {
                    HStack {
                        Text("Air Sensor State")
                        AirStateView(status: vm.airState)
                    }
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                // Window Visibility Settings
                VStack(alignment: .leading, spacing: 8) {
                    Text("Window Visibility")
                        .font(.headline)
                    
                    Toggle("Show Bottom Slider Window", isOn: $vm.showBottomSlider)
                    Toggle("Show Track Name Window", isOn: $vm.showTrackName)
                    Toggle("Show DJ Name Window", isOn: $vm.showDJName)
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                Button("Reset Track Number") {
                    vm.resetTrackNumber()
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                // DJ Name Settings Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("DJ Name Settings")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Rank Text:")
                            .font(.subheadline)
                        TextField("Rank Text", text: Binding(
                            get: { vm.djNameRankText },
                            set: { vm.djNameRankText = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name Text:")
                            .font(.subheadline)
                        TextField("Name Text", text: Binding(
                            get: { vm.djNameNameText },
                            set: { vm.djNameNameText = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DJ Image:")
                            .font(.subheadline)
                        HStack {
                            Button("Select Image...") {
                                let panel = NSOpenPanel()
                                panel.allowedContentTypes = [.image]
                                panel.allowsMultipleSelection = false
                                panel.canChooseDirectories = false
                                panel.canChooseFiles = true
                                
                                if panel.runModal() == .OK {
                                    if let url = panel.url {
                                        if let image = NSImage(contentsOf: url) {
                                            vm.setDJNameImage(image, path: url.path)
                                        }
                                    }
                                }
                            }
                            
                            Button("Clear Image") {
                                vm.setDJNameImage(nil, path: nil)
                            }
                        }
                    }
                }
                
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
