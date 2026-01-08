//
//  ChuneesiumAppDelegate.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/02.
//

import AppKit
import SwiftUI

class ChuneesiumAppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
      let jvs = JVSIO(portPath: "/dev/cu.usbmodem1101")
      try! jvs.open()
  }
}
