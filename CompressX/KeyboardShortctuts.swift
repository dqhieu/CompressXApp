//
//  KeyboardShortctuts.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 9/29/24.
//

import SwiftUI
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
  static let showMainWindow = Self("showMainWindow")
  static let togglePinMainWindowOnTop = Self("togglePinMainWindowOnTop")
}

@MainActor
final class KeyboardShortcutsManager: ObservableObject {

  @Published var mainWindowTrigger = 0
  @Published var togglePinMainWindowOnTopTrigger = 0

  init() {
    KeyboardShortcuts.onKeyDown(for: .showMainWindow) { [weak self] in
      DispatchQueue.main.async { [weak self] in
        self?.mainWindowTrigger += 1
      }
    }
    KeyboardShortcuts.onKeyDown(for: .togglePinMainWindowOnTop) { [weak self] in
      DispatchQueue.main.async { [weak self] in
        self?.togglePinMainWindowOnTopTrigger += 1
      }
    }
  }
}
