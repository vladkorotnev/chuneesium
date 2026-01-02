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
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
