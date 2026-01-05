//
//  BottomSliderViewWindowManager.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/04.
//

import AppKit
import SwiftUI

final class BottomSliderViewWindowManager {
    let window: NSWindow
    let coordinator: SliderCoordinator
    
    init(coordinator: SliderCoordinator) {
        self.coordinator = coordinator
        
        guard let screen = NSScreen.main else { fatalError("What NSScreen?") }
        let screenFrame = screen.visibleFrame
        
        window = NSWindow(
            contentRect: NSRect(
                x: screenFrame.minX,
                y: screenFrame.minY,
                width: screenFrame.width,
                height: 75
            ),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        let contentView = ZStack {
            SliderView(viewModel: coordinator)
        }.frame(maxWidth: .infinity)
        
        window.contentView = NSHostingView(rootView: contentView)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .statusBar
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        window.collectionBehavior = [.canJoinAllSpaces, .canJoinAllApplications]
    }
    
}
