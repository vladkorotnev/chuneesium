//
//  AppViewModel.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/04.
//

import Combine
import SwiftUI
import AppKit

final class AppViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private var sliderCfgStore: HardwareSliderConfigStoreProtocol
    private var ledCfgStore: LedBoardConfigStoreProtocol
    private var djNameCfgStore: DJNameConfigStoreProtocol
    
    private var sceneController: SceneController
    private var sliderCoordinator: SliderCoordinator
    private var sliderWindow: BottomSliderViewWindowManager
    private var trackNameViewModel: TrackNameViewModel
    private var trackNameWindow: TrackNameViewWindowManager
    private var djNameViewModel: DJNameViewModel
    private var djNameWindow: DJNameViewWindowManager
    private var hardwareSlider: HardwareSlider?
    private var midi: MIDIIO
    
    private var leftLedbd: LEDBD?
    private var rightLedbd: LEDBD?
    private(set) var leftSurface: LEDSurface
    private(set) var rightSurface: LEDSurface
    private var ledDisplay: LEDDisplay
    private var effector: LEDEffectPlayer
    private var previousTrack: TraktorSongOnAir? = nil
    
    
    private static let nilPortName = "(None)"
    @Published var sliderPortName: String = nilPortName
    {
        didSet {
            guard sliderPortName != Self.nilPortName else {
                sliderCfgStore.portPath = nil
                return
            }
            
            if sliderPortName == leftLedPortName {
                leftLedPortName = Self.nilPortName
            }
            
            if sliderPortName == rightLedPortName {
                rightLedPortName = Self.nilPortName
            }
            
            sliderCfgStore.portPath = sliderPortName
        }
    }
    
    @Published var leftLedPortName: String = nilPortName
    {
        didSet {
            guard leftLedPortName != Self.nilPortName else {
                ledCfgStore.leftBoard = nil
                return
            }
            
            if sliderPortName == leftLedPortName {
                sliderPortName = Self.nilPortName
            }
            
            if leftLedPortName == rightLedPortName {
                rightLedPortName = Self.nilPortName
            }
            
            ledCfgStore.leftBoard = leftLedPortName
        }
    }
    
    @Published var rightLedPortName: String = nilPortName
    {
        didSet {
            guard rightLedPortName != Self.nilPortName else {
                ledCfgStore.rightBoard = nil
                return
            }
            
            if sliderPortName == rightLedPortName {
                sliderPortName = Self.nilPortName
            }
            
            if leftLedPortName == rightLedPortName {
                leftLedPortName = Self.nilPortName
            }
            
            
            ledCfgStore.rightBoard = rightLedPortName
        }
    }
    
    @Published var ledBrightness: Double = 1.0 {
        didSet {
            ledCfgStore.brightness = ledBrightness
            leftSurface.brightness = ledBrightness
            rightSurface.brightness = ledBrightness
        }
    }
    
    @Published private(set) var isSliderConnected = false
    @Published private(set) var isLedConnected = false
    
    var allSerialPorts: [String] {
        [Self.nilPortName] + sliderCfgStore.allPorts
    }
    private let tobs = TraktorOBSRelayClient()
    
    init() {
        sliderCfgStore = HardwareSliderConfigStore()
        sliderPortName = sliderCfgStore.portPath ?? Self.nilPortName
        ledCfgStore = LedBoardConfigStore()
        leftLedPortName = ledCfgStore.leftBoard ?? Self.nilPortName
        rightLedPortName = ledCfgStore.rightBoard ?? Self.nilPortName
        ledBrightness = ledCfgStore.brightness
        
        djNameCfgStore = DJNameConfigStore()
        
        midi = MIDIIO()
        
        sliderCoordinator = SliderCoordinator(items: [])
        sliderWindow = BottomSliderViewWindowManager(coordinator: sliderCoordinator)
        
        trackNameViewModel = TrackNameViewModel()
        trackNameWindow = TrackNameViewWindowManager(viewModel: trackNameViewModel)
        
        djNameViewModel = DJNameViewModel(configStore: djNameCfgStore)
        djNameWindow = DJNameViewWindowManager(viewModel: djNameViewModel)
        
        leftSurface = LEDSurface(port: nil, stripCount: 5, stripInversePhase: false, brightness: ledCfgStore.brightness)
        rightSurface = LEDSurface(port: nil, stripCount: 6, stripInversePhase: true, brightness: ledCfgStore.brightness)
        
        leftSurface.airTowerSeparateColors = [.init(color: .red), .init(color: .pink), .init(color: .indigo)]
        rightSurface.airTowerColor = .init(color: .green)
        
        ledDisplay = LEDDisplay(leftHalf: leftSurface, rightHalf: rightSurface)
        effector = LEDEffectPlayer(display: ledDisplay)
        effector.currentEffect = LEDEffectSequencer(effects: [
            LEDEffectTime(timeInterval: 12.0, effect: LEDMatrixRain()),
            LEDScrollString(text: "DJ AKASAKA", color: .cyan),
            LEDEffectTime(timeInterval: 3.0, effect: LEDSwoopbars(evenColor: .init(color: .pink), oddColor: .init(color: .indigo))),
            LEDScrollString(text: "INTHEMIX", color: .orange),
            LEDEffectTime(timeInterval: 5.0, effect: LEDSoundwaveMiddle(color: .init(color: .indigo), source: .controlChange(channel: 0, control: 127))),
            LEDRainbow(endless: false, loopCount: 2),
            LEDEffectTime(timeInterval: 5.0, effect: LEDSoundwaveFull(color: .init(color: .orange), source: .controlChange(channel: 0, control: 127))),
            LEDEffectTime(timeInterval: 10.0, effect: LEDSnake()),
            LEDEffectTime(timeInterval: 3.0, effect: LEDSwoopbars(evenColor: .init(color: .cyan), oddColor: .init(color: .green))),
            LEDEffectTime(timeInterval: 5.0, effect: LEDVolumeBar(color: .init(color: .orange), source: .controlChange(channel: 0, control: 127))),
        ])
        

        sceneController = SceneController(
            slider: sliderCoordinator,
            midi: midi,
            scenes: MY_SCENE
        )
        
        midi.events
            .sink { [weak self] event in
                self?.effector.receive(event: event)
            }
            .store(in: &cancellables)
        
        sceneController.onChange = { [weak self] newScene in
            guard let newScene else {
                self?.sliderCoordinator.items = []
                return
            }
            
            self?.sliderCoordinator.items = newScene.items.map { $0.sliderItem }
        }
        
        sliderCfgStore.onUpdate = { [weak self] newPortName in
            print("Port changed to \(String(describing: newPortName))")
            if self?.isSliderConnected == true {
                self?.reinitSlider(portPath: newPortName)
            }
        }
        
        sceneController.refresh()
        
        sceneController.onDirty = { @MainActor [weak self] in
            self?.sliderCoordinator.updateViewState()
        }
        
        // Wire up TraktorOBSRelayClient to TrackNameViewModel
        tobs.currentTrack
            .sink { [weak self] song in
                guard let self = self else { return }
                
                // Only update if the track actually changed (not just a duplicate)
                if song?.id != self.previousTrack?.id {
                    self.trackNameViewModel.updateTrack(song)
                    
                    // Update album art URL
                    if let song = song {
                        let artworkURL = self.tobs.artworkURL(for: song)
                        self.trackNameViewModel.updateAlbumArtURL(artworkURL)
                    } else {
                        self.trackNameViewModel.updateAlbumArtURL(nil)
                    }
                    
                    self.previousTrack = song
                }
            }
            .store(in: &cancellables)
        
        // Subscribe to nowPlaying to detect when all tracks stop
        // This handles the case where processUpdates returns early and currentTrack doesn't get set to nil
        tobs.nowPlaying
            .sink { [weak self] info in
                guard let self = self else { return }
                // If songsOnAir is empty or nil, clear the track
                guard let songs = info.songsOnAir, !songs.isEmpty else {
                    // All tracks stopped - clear the display
                    if self.previousTrack != nil {
                        self.trackNameViewModel.updateTrack(nil)
                        self.trackNameViewModel.updateAlbumArtURL(nil)
                        self.previousTrack = nil
                    }
                    return
                }
                
                // Check if any tracks are actually playing
                let hasPlayingTracks = songs.contains { $0.isPlaying == true }
                if !hasPlayingTracks && self.previousTrack != nil {
                    // All tracks stopped playing - clear the display
                    self.trackNameViewModel.updateTrack(nil)
                    self.trackNameViewModel.updateAlbumArtURL(nil)
                    self.previousTrack = nil
                }
            }
            .store(in: &cancellables)
        
        // Only increment track number when a track actually starts (not on currentTrack changes)
        tobs.trackStarted
            .sink { [weak self] _ in
                self?.trackNameViewModel.incrementTrackNumber()
                // Start the DJ name timer on first track
                self?.djNameViewModel.startTimer()
            }
            .store(in: &cancellables)
        
        tobs.bpmChanged
            .sink { [weak self] bpm in
                self?.trackNameViewModel.updateBPM(bpm)
            }
            .store(in: &cancellables)
    }
    
    private func reinitSlider(portPath: String?) {
        if let hardwareSlider {
            hardwareSlider.close()
        }
        
        isSliderConnected = false
        
        guard let portPath else {
            hardwareSlider = nil
            return
        }
        
        hardwareSlider = HardwareSlider(portPath: portPath, viewModel: sliderCoordinator)
        do {
            try hardwareSlider?.open()
            isSliderConnected = true
        }
        catch {
            print("ERROR: \(error)")
            hardwareSlider = nil
        }
    }
    
    private func reinitLeds(left: String?, right: String?) {
        if let leftLedbd {
            leftSurface.port = nil
            leftLedbd.close()
            self.leftLedbd = nil
        }
        
        if let rightLedbd {
            rightSurface.port = nil
            rightLedbd.close()
            self.rightLedbd = nil
        }
        
        isLedConnected = false
        
        if let left {
            let bd = LEDBD(portPath: left, ledCount: 53)
            do { try bd.open() } catch { return }
            leftLedbd = bd
            leftSurface.port = bd
            isLedConnected = true
        }
        
        if let right {
            let bd = LEDBD(portPath: right, ledCount: 63)
            do { try bd.open() } catch { return }
            rightLedbd = bd
            rightSurface.port = bd
            isLedConnected = true
        }
    }
    
    public func reconnectSlider() {
        if isSliderConnected {
            reinitSlider(portPath: nil)
        } else {
            reinitSlider(portPath: sliderCfgStore.portPath)
        }
    }
    
    public func reconnectLed() {
        if isLedConnected {
            reinitLeds(left: nil, right: nil)
        } else {
            reinitLeds(left: ledCfgStore.leftBoard, right: ledCfgStore.rightBoard)
        }
    }
    
    public func resetTrackNumber() {
        trackNameViewModel.resetTrackNumber()
        djNameViewModel.resetTimer()
    }
    
    var djNameRankText: String {
        get { djNameViewModel.rankText }
        set { 
            djNameViewModel.rankText = newValue
            djNameViewModel.saveToStore()
        }
    }
    
    var djNameNameText: String {
        get { djNameViewModel.nameText }
        set { 
            djNameViewModel.nameText = newValue
            djNameViewModel.saveToStore()
        }
    }
    
    func setDJNameImage(_ image: NSImage?, path: String?) {
        djNameViewModel.setImage(image, path: path)
    }
}
