//
//  WindowConfigurator.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 12/21/24.
//

import AppKit
import SwiftUI

struct SettingsWindowConfigurator: NSViewRepresentable {
  func makeNSView(context: Context) -> NSView {
    let view = NSView()
    DispatchQueue.main.async {
      if let window = view.window {
        configureWindow(window)
      }
    }
    return view
  }

  func updateNSView(_ nsView: NSView, context: Context) {}

  private func configureWindow(_ window: NSWindow) {
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.styleMask.remove(.titled)
  }
}
