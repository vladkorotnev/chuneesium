//
//  ChuneesiumAppDelegate.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/02.
//

import AppKit
import SwiftUI

class ChuneesiumAppDelegate: NSObject, NSApplicationDelegate {
  var window: NSWindow!
    var port: HardwareSlider!
    var viewModel: SliderViewModel!
      
  func applicationDidFinishLaunching(_ notification: Notification) {
      guard let screen = NSScreen.main else { fatalError("What NSScreen?") }
      let screenFrame = screen.visibleFrame
      
    // create window
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
    
      viewModel = SliderViewModel(
        items: [
            SliderButton(
                tint: .green,
                label: "BACK",
                location: .init(left: 0, width: 3),
                onTap: {
                    print("back tap")
                },
                onRelease: {
                    print("back up")
                },
                onPress: {
                    print("back down")
                }
            ),
            SliderButton(
                tint: .green,
                label: "NEXT",
                location: .init(left: 3, width: 3),
            ),
            SliderButton(
                tint: .red,
                label: "ENTER",
                location: .init(left: 6, width: 4),
            ),
//            SliderButton(
//                tint: .white,
//                label: "SORT",
//                location: .init(left: 10, width: 2),
//            ),
            SliderButton(
                tint: .white,
                label: "SORT",
                location: .init(left: 12, width: 2),
            ),
            SliderButton(
                tint: .blue,
                label: "MODE",
                location: .init(left: 14, width: 2),
            ),
        ]
    )
      
    // set content to custom View
      let contentView = ZStack {
          SliderView(viewModel: viewModel)
      }
          .frame(maxWidth: .infinity)
    window.contentView = NSHostingView(rootView: contentView)
      window.isOpaque = false
      window.backgroundColor = .clear
      window.level = .statusBar
      window.makeKeyAndOrderFront(nil)
      window.orderFrontRegardless()
      window.collectionBehavior = [.canJoinAllSpaces, .canJoinAllApplications]
      
      port = HardwareSlider(portPath: "/dev/cu.usbserial-0001", viewModel: viewModel)
      try! port.open()
      
  }
}
