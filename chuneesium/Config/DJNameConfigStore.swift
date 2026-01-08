//
//  DJNameConfigStore.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/06.
//

import Foundation
import AppKit

protocol DJNameConfigStoreProtocol {
    var rankText: String { get set }
    var nameText: String { get set }
    var imagePath: String? { get set }
}

extension DJNameConfigStoreProtocol {
    func loadImage() -> NSImage? {
        guard let imagePath = imagePath else { return nil }
        return NSImage(contentsOfFile: imagePath)
    }
}

final class DJNameConfigStore: DJNameConfigStoreProtocol {
    var rankText: String {
        get { UserDefaults.standard.string(forKey: "djNameRankText") ?? "NEW FACE" }
        set { UserDefaults.standard.set(newValue, forKey: "djNameRankText") }
    }
    
    var nameText: String {
        get { UserDefaults.standard.string(forKey: "djNameNameText") ?? "AKASAKA" }
        set { UserDefaults.standard.set(newValue, forKey: "djNameNameText") }
    }
    
    var imagePath: String? {
        get { UserDefaults.standard.string(forKey: "djNameImagePath") }
        set { UserDefaults.standard.set(newValue, forKey: "djNameImagePath") }
    }
}
