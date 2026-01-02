//
//  DJNameView.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/01.
//

import SwiftUI

struct DJNameView: View {
    @State
    var rankText: String = "NEW FACE"
    
    @State 
    var nameText: String = "AKASAKA"
    
    @State
    var ratingText: String = "12:34"
    
    var body: some View {
            VStack(spacing: 4) {
                // MARK: - New Comer Header
                Text(rankText)
                    .font(.system(size: 22, weight: .medium, design: .default))
                    .foregroundStyle(.black)
                    .italic()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [Color.white, Color(white: 0.85)]),
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
                
                // MARK: - Main Profile Card
                HStack(spacing: 0) {
                    // Left Info Section
                    VStack(alignment: .leading, spacing: 0) {
                        // Top Row: Level and Name
                        HStack(alignment: .bottom, spacing: 10) {
                            HStack(alignment: .bottom, spacing: 4) {
                                Text("DJ")
                                    .font(.system(size: 18, weight: .bold))
                            }
                            
                            Text(nameText)
                                .font(.system(size: 30, weight: .medium))
                                .tracking(4) // Adds spacing between letters
                        }
                        .padding(.horizontal, 10)
                        .padding(.top, 15)
                        .padding(.bottom, 5)
                        
                        // Divider Line
                        Rectangle()
                            .fill(Color.gray.opacity(0.6))
                            .frame(height: 1)
                            .padding(.horizontal, 5)
                        
                        // Bottom Row: Rating
                        HStack(alignment: .bottom, spacing: 30) {
                            Text("RATING")
                                .font(.system(size: 14, weight: .black))
                                .foregroundColor(.green)
                                .italic()
                            
                            Text(ratingText)
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundColor(.green)
                                
                        }
                        .stroke(color: .black, width: 0.5)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Right Side: Character Placeholder
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 50.0)
                            .padding(20)
                            .foregroundColor(.gray)
                            .border(.gray.opacity(0.3))
                }
                .background(Color.white)
                .border(Color.gray.opacity(0.5), width: 1)
            }
            .padding()
            .background(
                Gradient(stops: [
                    .init(color: .init(white: 0.9), location: 0),
                    .init(color: .init(white: 1), location: 0.5),
                    .init(color: .init(white: 0.85), location: 0.51),
                    .init(color: .init(white: 0.95), location: 1),
                ])
            )
            .frame(maxWidth: 480.0)
            .border(width: 1, edges: [.leading, .bottom, .trailing], color: .white)
        }
}

#Preview {
    DJNameView()
}
