//
//  ChuneesiumAppDelegate.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/02.
//

import AppKit
import SwiftUI

class ChuneesiumAppDelegate: NSObject, NSApplicationDelegate {
    var effector: LEDEffectPlayer!
    
  func applicationDidFinishLaunching(_ notification: Notification) {
      // right half: 6 strips middle to right (bottom to top then zig zag); then right air
      let ledbd = LEDBD(portPath: "/dev/cu.usbserial-FTC0YLP90", ledCount: 63)
      try! ledbd.open()
      
      // left half: 5 strips leftmost column to around middle (top to bottom then zig zag); then left air
      let ledbd2 = LEDBD(portPath: "/dev/cu.usbserial-FTC0YLP91", ledCount: 53)
      try! ledbd2.open()
      
      let surfaceL = LEDSurface(port: ledbd2, stripCount: 5, stripInversePhase: false)
      let surfaceR = LEDSurface(port: ledbd, stripCount: 6, stripInversePhase: true)
      let disp = LEDDisplay(leftHalf: surfaceL, rightHalf: surfaceR)
      effector = LEDEffectPlayer(display: disp)
      effector.currentEffect = LEDEffectSequencer(effects: [
        LEDScrollString(text: "SEGS  SEGS", color: .blue),
        LEDEffectDelay(timeInterval: 2.0),
        LEDScrollString(text: "HEY", color: .pink),
        LEDScrollString(text: "GUYS", color: .yellow),
        LEDScrollString(text: "CHECKTHISOUT", color: .green),
        LEDRainbow(endless: false, loopCount: 3),
        LEDEffectDelay(timeInterval: 2.0),
        LEDScrollString(text: "IMPRESSIVE", color: .purple),
        LEDScrollString(text: "HUH?", color: .pink),
        LEDEffectDelay(timeInterval: 2.0),
      ])
  }
}
