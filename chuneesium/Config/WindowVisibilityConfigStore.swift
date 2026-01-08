//
//  WindowVisibilityConfigStore.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/08.
//

import Foundation

protocol WindowVisibilityConfigStoreProtocol {
    var showBottomSlider: Bool { get set }
    var showTrackName: Bool { get set }
    var showDJName: Bool { get set }
}

final class WindowVisibilityConfigStore: WindowVisibilityConfigStoreProtocol {
    var showBottomSlider: Bool {
        get { UserDefaults.standard.object(forKey: "windowShowBottomSlider") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "windowShowBottomSlider") }
    }
    
    var showTrackName: Bool {
        get { UserDefaults.standard.object(forKey: "windowShowTrackName") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "windowShowTrackName") }
    }
    
    var showDJName: Bool {
        get { UserDefaults.standard.object(forKey: "windowShowDJName") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "windowShowDJName") }
    }
}
