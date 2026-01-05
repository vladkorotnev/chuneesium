//
//  chuneesiumApp.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/01.
//

import SwiftUI

@main
struct chuneesiumApp: App {
    @NSApplicationDelegateAdaptor(ChuneesiumAppDelegate.self) var appDelegate
    @StateObject private var vm: AppViewModel = AppViewModel()
    
    var body: some Scene {
        Settings {
            VStack {
                HStack {
                    Picker("COM Port:", selection: $vm.serialPortName) {
                        ForEach(vm.allSerialPorts, id: \.self) {
                            Text($0)
                        }
                    }
                    .disabled(vm.isConnected)
                    Button {
                        vm.reconnect()
                    } label: {
                        Image(systemName: vm.isConnected ? "cable.connector.slash" : "cable.connector")
                    }
                }
            }
            .padding()
        }
        .defaultLaunchBehavior(.presented)
    }
}
