//
//  TrackNameViewModel.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/04.
//

import Combine
import SwiftUI

final class TrackNameViewModel: ObservableObject {
    @Published var leftSettingText: String = "SPEED: 0.0"
    @Published var rightSettingText: String = "MIRROR: OFF"
    @Published var trackNumber: Int = 0
    @Published var difficultyText: String = "MASTER"
    @Published var songName: String = "Song Name"
    @Published var artistName: String = "Artist Name"
    @Published var bpm: Double = 0.0
    @Published var albumArtURL: URL?
    @Published var albumArtImage: NSImage?
    @Published var themeColor: Color = Color(red: 0.5, green: 0.2, blue: 0.8)
    private var globalBpm: Double = 0
    
    private var trackSequenceCounter: Int = 0
    
    init() {}
    
    func updateBPM(_ bpm: Double) {
        leftSettingText = String(format: "SPEED: %.2f", bpm)
        globalBpm = bpm
    }
    
    func updateTrack(_ track: TraktorSongOnAir?) {
        if let track = track {
            songName = track.title ?? "Unknown Title"
            artistName = track.artist ?? "Unknown Artist"
            bpm = track.bpm ?? globalBpm
        } else {
            songName = "Song Name"
            artistName = "Artist Name"
        }
    }
    
    func incrementTrackNumber() {
        trackSequenceCounter += 1
        trackNumber = trackSequenceCounter
        let diff = [
            (Color(red: 0.35, green: 0.75, blue: 0.38), "EASY"),
            (.red, "EXPERT"),
            (.orange, "ADVANCED"),
            (Color(red: 0.5, green: 0.2, blue: 0.8), "MASTER"),
        ].randomElement()!
        difficultyText = diff.1
        themeColor = diff.0
    }
    
    func resetTrackNumber() {
        trackSequenceCounter = 0
        trackNumber = 0
    }
    
    func updateAlbumArtURL(_ url: URL?) {
        albumArtURL = url
        loadAlbumArt(from: url)
    }
    
    private func loadAlbumArt(from url: URL?) {
        guard let url = url else {
            albumArtImage = nil
            return
        }
        
        // Load image asynchronously
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self?.albumArtImage = nil
                }
                return
            }
            
            if let image = NSImage(data: data) {
                DispatchQueue.main.async {
                    self?.albumArtImage = image
                }
            } else {
                DispatchQueue.main.async {
                    self?.albumArtImage = nil
                }
            }
        }.resume()
    }
}
