//
//  Updater.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 12/21/24.
//

import SwiftUI
import Sparkle

class Updater: NSObject, SPUUpdaterDelegate {

  static let shared = Updater()

  var updater: SPUUpdater?
  var automaticallyChecksForUpdates: Bool = false

  var dispatchWorkItem: DispatchWorkItem?

  func checkForUpdates() {
    dispatchWorkItem?.cancel()
    dispatchWorkItem = DispatchWorkItem(block: { [weak self] in
      self?.checkForUpdates()
    })
    Task {
      if let model = await LicenseManager.shared.checkForUpdates() {
        if model.isEligibleForUpdate {
          DispatchQueue.main.asyncAfter(deadline: .now() + 60 * 60 * 24, execute: dispatchWorkItem!)
          await MainActor.run {
            updater?.checkForUpdateInformation()
          }
        }
      }
    }
  }

  func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
    DispatchQueue.main.async { [weak self] in
      self?.updater?.checkForUpdates()
    }
  }

}
