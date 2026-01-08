//
//  DJNameViewWindowManager.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/06.
//

import AppKit
import SwiftUI

final class DJNameViewWindowManager {
    let window: NSWindow
    let viewModel: DJNameViewModel
    
    init(viewModel: DJNameViewModel) {
        self.viewModel = viewModel
        
        guard let screen = NSScreen.main else { fatalError("What NSScreen?") }
        let screenFrame = screen.visibleFrame
        
        // Position at top left corner
        // DJNameView has maxWidth: 480, so we'll use that width
        // Height is approximately 150 based on the view
        let windowWidth: CGFloat = 480
        let windowHeight: CGFloat = 150
        let leftMargin: CGFloat = 10
        
        window = NSWindow(
            contentRect: NSRect(
                x: screenFrame.minX + leftMargin,
                y: screenFrame.maxY - windowHeight,
                width: windowWidth,
                height: windowHeight
            ),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        let contentView = DJNameView(viewModel: viewModel)
        
        window.contentView = NSHostingView(rootView: contentView)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .statusBar
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        window.collectionBehavior = [.canJoinAllSpaces, .canJoinAllApplications]
    }
}
