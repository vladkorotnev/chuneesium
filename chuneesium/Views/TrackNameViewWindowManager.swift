//
//  TrackNameViewWindowManager.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/04.
//

import AppKit
import SwiftUI

final class TrackNameViewWindowManager {
    let window: NSWindow
    let viewModel: TrackNameViewModel
    
    init(viewModel: TrackNameViewModel) {
        self.viewModel = viewModel
        
        guard let screen = NSScreen.main else { fatalError("What NSScreen?") }
        let screenFrame = screen.visibleFrame
        
        // Position at top right corner
        // TrackNameView has maxWidth: 500, so we'll use that width
        // Height is approximately 130 based on the view
        let windowWidth: CGFloat = 500
        let windowHeight: CGFloat = 130
        let rightMargin: CGFloat = 10
        
        window = NSWindow(
            contentRect: NSRect(
                x: screenFrame.maxX - windowWidth - rightMargin,
                y: screenFrame.maxY - windowHeight,
                width: windowWidth,
                height: windowHeight
            ),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        let contentView = TrackNameView(viewModel: viewModel)
        
        window.contentView = NSHostingView(rootView: contentView)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .statusBar
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        window.collectionBehavior = [.canJoinAllSpaces, .canJoinAllApplications]
    }
}
