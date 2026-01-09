//
//  LEDPreviewer.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/06.
//

import SwiftUI

private let H_SPACING: CGFloat = 15

struct LEDColumn: View {
    var stripData: [SliderColor]
    
    var body: some View {
        VStack(spacing: 5) {
            ForEach(stripData.indices, id: \.self) { row in
                let ledColor = stripData[row].toSwiftUi
                
                Rectangle()
                    .fill(ledColor)
                    .frame(width: 15.0, height: 45.0)
            }
        }
    }
}

/// A wrapper view that observes LEDSurface and displays its air tower colors.
/// This ensures proper SwiftUI observation chain for nested ObservableObjects.
struct AirTowerLEDColumn: View {
    @ObservedObject var surface: LEDSurface
    
    var body: some View {
        LEDColumn(stripData: surface.airTowerSeparateColors)
    }
}

struct HalfLEDPreviewer: View {
    var pixelGrid: [[SliderColor]]
    
    var body: some View {
        HStack(spacing: H_SPACING) {
            ForEach(pixelGrid.indices, id: \.self) { col in
                let stripData = pixelGrid[col]
                LEDColumn(stripData: stripData)
            }
        }
    }
}

struct LEDPreviewer: View {
    @StateObject var left: LEDSurface
    @StateObject var right: LEDSurface
    
    var body: some View {
        HStack(spacing: H_SPACING) {
            HalfLEDPreviewer(pixelGrid: left.pixelGrid)
            HalfLEDPreviewer(pixelGrid: right.pixelGrid)
        }
        .blur(radius: 3.0)
    }
}


#Preview {
    HalfLEDPreviewer(pixelGrid: [
        Array(repeating: .init(color: .red), count: 10),
        Array(repeating: .init(color: .green), count: 10),
        Array(repeating: .init(color: .blue), count: 10),
        Array(repeating: .init(color: .red), count: 10),
        Array(repeating: .init(color: .green), count: 10),
        Array(repeating: .init(color: .blue), count: 10),
        Array(repeating: .init(color: .red), count: 10),
        Array(repeating: .init(color: .green), count: 10),
        Array(repeating: .init(color: .blue), count: 10),
        Array(repeating: .init(color: .red), count: 10),
        Array(repeating: .init(color: .green), count: 10),
    ])
}
