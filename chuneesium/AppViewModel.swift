//
//  AppViewModel.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/04.
//

import Combine
import SwiftUI

final class AppViewModel: ObservableObject {
    private static let nilPortName = "(None)"
    @Published var serialPortName: String = nilPortName
    {
        didSet {
            guard serialPortName != Self.nilPortName else {
                sliderCfgStore.portPath = nil
                return
            }
            
            sliderCfgStore.portPath = serialPortName
        }
    }
    @Published private(set) var isConnected = false
    
    var allSerialPorts: [String] {
        [Self.nilPortName] + sliderCfgStore.allPorts
    }
    
    private var sceneController: SceneController
    private var sliderCoordinator: SliderCoordinator
    private var sliderWindow: BottomSliderViewWindowManager
    private var sliderCfgStore: HardwareSliderConfigStoreProtocol
    private var hardwareSlider: HardwareSlider?
    private var midi: MIDIIO
    
    init() {
        sliderCfgStore = HardwareSliderConfigStore()
        serialPortName = sliderCfgStore.portPath ?? Self.nilPortName
        
        midi = MIDIIO()
        
        sliderCoordinator = SliderCoordinator(items: [])
        sliderWindow = BottomSliderViewWindowManager(coordinator: sliderCoordinator)
        sceneController = SceneController(
            slider: sliderCoordinator,
            midi: midi,
            scenes: MY_SCENE
        )
        
        sceneController.onChange = { [weak self] newScene in
            guard let newScene else {
                self?.sliderCoordinator.items = []
                return
            }
            
            self?.sliderCoordinator.items = newScene.items.map { $0.sliderItem }
        }
        
        sliderCfgStore.onUpdate = { [weak self] newPortName in
            print("Port changed to \(String(describing: newPortName))")
            if self?.isConnected == true {
                self?.reinitSlider(portPath: newPortName)
            }
        }
        
        sceneController.refresh()
        
        sceneController.onDirty = { @MainActor [weak self] in
            self?.sliderCoordinator.updateViewState()
        }
    }
    
    private func reinitSlider(portPath: String?) {
        if let hardwareSlider {
            hardwareSlider.close()
        }
        
        isConnected = false
        
        guard let portPath else {
            hardwareSlider = nil
            return
        }
        
        hardwareSlider = HardwareSlider(portPath: portPath, viewModel: sliderCoordinator)
        do {
            try hardwareSlider?.open()
            isConnected = true
        }
        catch {
            print("ERROR: \(error)")
            hardwareSlider = nil
        }
    }
    
    public func reconnect() {
        if isConnected {
            reinitSlider(portPath: nil)
        } else {
            reinitSlider(portPath: sliderCfgStore.portPath)
        }
    }
}
