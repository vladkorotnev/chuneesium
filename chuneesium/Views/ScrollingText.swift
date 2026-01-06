//
//  ScrollingText.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/04.
//

import SwiftUI

struct ScrollingText: View {
    let text: String
    let font: Font
    let color: Color
    let gradientWidth: CGFloat = 20
    
    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var animationTask: Task<Void, Never>?
    
    var body: some View {
        GeometryReader { geometry in
            let needsScrolling = textWidth > geometry.size.width
            
            ZStack(alignment: .leading) {
                // Scrolling text
                Text(text)
                    .font(font)
                    .foregroundColor(color)
                    .fixedSize(horizontal: true, vertical: false)
                    .offset(x: needsScrolling ? scrollOffset : 0)
                    .background(
                        GeometryReader { textGeometry in
                            Color.clear
                                .preference(key: TextWidthPreferenceKey.self, value: textGeometry.size.width)
                        }
                    )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .mask(
                Group {
                    if needsScrolling {
                        // Gradient mask for fade effect on edges (only when scrolling)
                        HStack(spacing: 0) {
                            // Left fade
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0),
                                    .init(color: .black, location: 1)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: gradientWidth)
                            
                            // Middle (full opacity)
                            Rectangle()
                                .fill(Color.black)
                            
                            // Right fade
                            LinearGradient(
                                stops: [
                                    .init(color: .black, location: 0),
                                    .init(color: .clear, location: 1)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: gradientWidth)
                        }
                        .offset(x: -gradientWidth/2)
                    } else {
                        // No gradient when text fits - show full opacity
                        Rectangle()
                            .fill(Color.black)
                    }
                }
            )
            .clipped()
            .onAppear {
                containerWidth = geometry.size.width
            }
            .onDisappear {
                animationTask?.cancel()
            }
            .onChange(of: geometry.size.width) { newWidth in
                containerWidth = newWidth
                updateScrolling()
            }
            .onPreferenceChange(TextWidthPreferenceKey.self) { width in
                textWidth = width
                updateScrolling()
            }
            .onChange(of: text) { _ in
                scrollOffset = 0
                updateScrolling()
            }
        }
    }
    
    private func updateScrolling() {
        animationTask?.cancel()
        
        guard textWidth > containerWidth, containerWidth > 0 else {
            scrollOffset = 0
            return
        }
        
        let scrollDistance = textWidth - containerWidth + gradientWidth * 2
        let pauseDuration: TimeInterval = 2.0
        let scrollDuration: TimeInterval = Double(scrollDistance) / 30.0 // 30 points per second
        
        animationTask = Task {
            // Initial pause
            try? await Task.sleep(nanoseconds: UInt64(pauseDuration * 1_000_000_000))
            
            guard !Task.isCancelled else { return }
            
            // Scroll to the end
            withAnimation(.linear(duration: scrollDuration)) {
                scrollOffset = -scrollDistance
            }
            
            try? await Task.sleep(nanoseconds: UInt64(scrollDuration * 1_000_000_000))
            
            guard !Task.isCancelled else { return }
            
            // Pause at the end
            try? await Task.sleep(nanoseconds: UInt64(pauseDuration * 1_000_000_000))
            
            guard !Task.isCancelled else { return }
            
            // Scroll back to the start
            withAnimation(.linear(duration: scrollDuration)) {
                scrollOffset = 0
            }
            
            try? await Task.sleep(nanoseconds: UInt64(scrollDuration * 1_000_000_000))
            
            guard !Task.isCancelled else { return }
            
            // Repeat
            updateScrolling()
        }
    }
}

private struct TextWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
