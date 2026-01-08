//
//  DJNameViewModel.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/06.
//

import Combine
import SwiftUI
import AppKit

final class DJNameViewModel: ObservableObject {
    @Published var rankText: String = "NEW FACE"
    @Published var nameText: String = "AKASAKA"
    @Published var ratingText: String = "00:00"
    @Published var djImage: NSImage?
    
    private var configStore: DJNameConfigStoreProtocol
    private var timer: Timer?
    private var elapsedSeconds: Int = 0
    private var hasStarted: Bool = false
    
    init(configStore: DJNameConfigStoreProtocol) {
        self.configStore = configStore
        loadFromStore()
    }
    
    func loadFromStore() {
        rankText = configStore.rankText
        nameText = configStore.nameText
        djImage = configStore.loadImage()
    }
    
    func saveToStore() {
        configStore.rankText = rankText
        configStore.nameText = nameText
    }
    
    func setImage(_ image: NSImage?, path: String?) {
        djImage = image
        configStore.imagePath = path
    }
    
    func startTimer() {
        guard !hasStarted else { return }
        hasStarted = true
        elapsedSeconds = 0
        updateRatingText()
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    func resetTimer() {
        timer?.invalidate()
        timer = nil
        hasStarted = false
        elapsedSeconds = 0
        updateRatingText()
    }
    
    private func tick() {
        elapsedSeconds += 1
        updateRatingText()
    }
    
    private func updateRatingText() {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        ratingText = String(format: "%d.%02d", minutes, seconds)
    }
    
    deinit {
        timer?.invalidate()
    }
}
