//
//  CheckForUpdatesView.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 22/11/2023.
//

import Foundation
import SwiftUI
import Sparkle

// This view model class publishes when new updates can be checked by the user
final class CheckForUpdatesViewModel: ObservableObject {
  @Published var canCheckForUpdates = false
  
  init(updater: SPUUpdater) {
    updater.publisher(for: \.canCheckForUpdates)
      .assign(to: &$canCheckForUpdates)
  }
}

// This is the view for the Check for Updates menu item
// Note this intermediate view is necessary for the disabled state on the menu item to work properly before Monterey.
// See https://stackoverflow.com/questions/68553092/menu-not-updating-swiftui-bug for more info
struct CheckForUpdatesView: View {
  @ObservedObject private var checkForUpdatesViewModel: CheckForUpdatesViewModel
  private let updater: SPUUpdater
  
  init(updater: SPUUpdater) {
    self.updater = updater
    
    // Create our view model for our CheckForUpdatesView
    self.checkForUpdatesViewModel = CheckForUpdatesViewModel(updater: updater)
  }
  
  var body: some View {
    Button(action: {
      if LicenseManager.shared.isValid {
        updater.checkForUpdates()
      } else {
        let alert = NSAlert.init()
        alert.addButton(withTitle: "OK")
        alert.messageText = "Please activate your license to check for updates"
        let response = alert.runModal()
      }
    }, label: {
      Text("Check for Updates…")
    })
    .disabled(!checkForUpdatesViewModel.canCheckForUpdates)
  }
}
