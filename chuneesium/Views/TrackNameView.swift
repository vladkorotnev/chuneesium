//
//  TrackNameView.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/01.
//

import SwiftUI

struct TrackNameView: View {
    // Single variable to control the entire theme
    var themeColor: Color = Color(red: 0.5, green: 0.2, blue: 0.8) // Purple
    
    @State var leftSettingText: String = "SPEED: 9.25"
    @State var rightSettingText: String = "MIRROR: OFF"
    @State var trackNumber: Int = 1
    @State var difficultyText: String = "MASTER"
    @State var songName: String = "Song Name"
    @State var artistName: String = "Artist Name"
    
    var body: some View {
        VStack(spacing: 8) {
            // MARK: - Top Settings Bar
            HStack {
                Text(leftSettingText)
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
            
            // MARK: - Main Card
            ZStack {
                VStack(spacing: 0) {
                    // Top Section (Master/Level)
                    HStack {
                        // Song Artwork Placeholder
                        VStack(alignment: .leading, spacing: -2) {
                            Text("TRACK \(trackNumber)")
                                .font(.system(size: 14, weight: .bold))
                            Text(difficultyText)
                                .font(.system(size: 44, weight: .black))
                                .italic()
                                .kerning(3)
                        }
                        
                        Spacer()
                        
                        // Level Box
                        VStack(spacing: 0) {
                            Text("BPM")
                                .font(.system(size: 12, weight: .bold))
                                .padding(.vertical, 2)
                                .foregroundStyle(Color(red: 0, green: 0, blue: 0.6))
                            Text("175")
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
                    .background(themeColor)
                    .foregroundColor(.white)
                    
                    // Bottom Section (Song Info)
                    HStack {
                        // Song Artwork Placeholder
                        Spacer(minLength: 120.0)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(songName)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black.opacity(0.8))
                            
                            // Thin accent line
                            Rectangle()
                                .fill(themeColor.opacity(0.6))
                                .frame(height: 2)
                            
                            Text(artistName)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 15)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .background(Color.white)
                }
                
                HStack {
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .padding(20)
                        .aspectRatio(1, contentMode: .fit)
                        .foregroundColor(.gray)
                        .background(.white)
                        .border(.gray.opacity(0.3))
                        .frame(maxWidth: 150.0, maxHeight: 150.0, alignment: .leading)
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
        TrackNameView()
    }
}
