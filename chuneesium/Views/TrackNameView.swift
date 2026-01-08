//
//  TrackNameView.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/01.
//

import SwiftUI

struct TrackNameView: View {
    // Single variable to control the entire theme
    @ObservedObject var viewModel: TrackNameViewModel
    
    @State var rightSettingText: String = "VIBES: GOOD"
    
    var body: some View {
        VStack(spacing: 8) {
            // MARK: - Top Settings Bar
            HStack {
                Text(viewModel.leftSettingText)
                    .frame(maxWidth: .infinity)
                Spacer()
                Divider()
                    .frame(height: 15)
                    .background(Color.white.opacity(0.5))
                Spacer()
                Text(rightSettingText)
                    .frame(maxWidth: .infinity)
            }
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 40)
            .padding([.top], 5)
            
            // MARK: - Main Card
            ZStack {
                VStack(spacing: 0) {
                    // Top Section (Level)
                    HStack {
                        VStack(alignment: .leading, spacing: -2) {
                            Text("TRACK \(viewModel.trackNumber)")
                                .font(.system(size: 14, weight: .bold))
                                .padding([.top], 15)
                            ScrollingText(
                                text: viewModel.difficultyText,
                                font: .system(size: 44, weight: .black).italic(),
                                color: .white
                            )
                            .padding([.top], -5)
                            .frame(height: 50)
                        }
                        
                        Spacer()
                        
                        // Level Box
                        VStack(spacing: 0) {
                            Text("BPM")
                                .font(.system(size: 12, weight: .bold))
                                .padding(.vertical, 2)
                                .foregroundStyle(Color(red: 0, green: 0, blue: 0.6))
                            Text(String(format: "%.0f", viewModel.bpm))
                                .font(.system(size: 28, weight: .black))
                                .frame(maxWidth: .infinity)
                                .background(Color(red: 0, green: 0, blue: 0.6))
                        }
                        .padding(.horizontal, 1)
                        .frame(maxWidth: 70)
                        .frame(height: 55)
                        .background(.white)
                        .shadow(radius: 2)
                    }
                    .padding(.trailing, 15)
                    .padding(.leading, 130)
                    .frame(height: 75)
                    .background(viewModel.themeColor)
                    .foregroundColor(.white)
                    
                    // Bottom Section (Song Info)
                    HStack {
                        // Song Artwork Placeholder
                        Spacer(minLength: 115.0)
                        VStack(alignment: .leading, spacing: 4) {
                            ScrollingText(
                                text: viewModel.songName,
                                font: .system(size: 20, weight: .bold),
                                color: .black.opacity(0.8)
                            )
                            .frame(height: 24)
                            .padding([.top], 5.0)
                            
                            // Thin accent line
                            Rectangle()
                                .fill(viewModel.themeColor.opacity(0.6))
                                .frame(height: 2)
                            
                            ScrollingText(
                                text: viewModel.artistName,
                                font: .system(size: 14, weight: .medium),
                                color: Color(white: 0.4)
                            )
                            .frame(height: 18)
                            .padding([.bottom], 5.0)
                        }
                    }
                    .padding(.horizontal, 15)
                    .padding([.bottom], 5.0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .background(Color.white)
                }
                
                HStack {
                    Group {
                        if let albumArt = viewModel.albumArtImage {
                            Image(nsImage: albumArt)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: "music.quarternote.3")
                                .resizable()
                                .scaledToFit()
                                .padding(20)
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(width: 110, height: 110)
                    .clipped()
                    .background(.white)
                    .border(.gray.opacity(0.3))
                    .shadow(radius: 1.0)
                    .padding(10)
                        
                    Spacer()
                }
            }
            .frame(height: 130)
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .shadow(radius: 10)
        }
        .background(Color.black)
        .border(width: 1, edges: [.leading, .bottom, .trailing], color: .white)
        .frame(maxWidth: 500.0)
    }
}

// MARK: - Preview
struct TrackNameView_Previews: PreviewProvider {
    static var previews: some View {
        TrackNameView(viewModel: TrackNameViewModel())
    }
}
