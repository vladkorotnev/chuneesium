//
//  LedBoardConfigStore.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/06.
//

import Foundation
import Combine

protocol LedBoardConfigStoreProtocol: SerialPortEnumerator {
    var leftBoard: String? { get set }
    var rightBoard: String? { get set }
    var brightness: Double { get set }
}

final class LedBoardConfigStore: LedBoardConfigStoreProtocol {
    var leftBoard: String? {
        get { UserDefaults.standard.string(forKey: "leftLedbd") }
        set { UserDefaults.standard.set(newValue, forKey: "leftLedbd") }
    }
    
    var rightBoard: String? {
        get { UserDefaults.standard.string(forKey: "rightLedbd") }
        set { UserDefaults.standard.set(newValue, forKey: "rightLedbd") }
    }
    
    var brightness: Double {
        get { UserDefaults.standard.double(forKey: "ledbdBright") }
        set { UserDefaults.standard.set(newValue, forKey: "ledbdBright") }
    }
}
