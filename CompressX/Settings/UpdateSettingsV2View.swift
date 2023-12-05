//
//  UpdateSettingsV2View.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 12/21/24.
//

import SwiftUI
import Sparkle

struct UpdateSettingsV2View: View {

  @EnvironmentObject var installationManager: InstallationManager
  private let updater: SPUUpdater
  @AppStorage("automaticallyChecksForUpdates") var automaticallyChecksForUpdates = true
  @AppStorage("shouldShowOnboardingV2") var shouldShowOnboardingV2 = true

  @State private var isCheckingForUpdates = false

  init(updater: SPUUpdater) {
    self.updater = updater
  }

  var body: some View {
    Form {
      Toggle("Automatically check for updates", isOn: $automaticallyChecksForUpdates)
        .onChange(of: automaticallyChecksForUpdates) { newValue in
          Updater.shared.automaticallyChecksForUpdates = newValue
        }
      HStack {
        Text("Current version: \(appVersion)")
        Spacer()
        if isCheckingForUpdates {
          ProgressView()
            .progressViewStyle(.linear)
            .frame(width: 100)
        } else {
          Button {
            if LicenseManager.shared.isValid {
              checkForUpdates()
            } else {
              let alert = NSAlert.init()
              alert.addButton(withTitle: "OK")
              alert.messageText = "Please activate your license to check for updates"
              let _ = alert.runModal()
            }
          } label: {
            Text("Check for Updates")
          }
          .buttonStyle(.borderedProminent)
        }

      }
      HStack {
        Spacer()
        Button {
          installationManager.removeDependencies()
          installationManager.state = .idle
          shouldShowOnboardingV2 = true
        } label: {
          Text("Clear cache and reset onboarding")
        }
        .buttonStyle(.bordered)
        Spacer()
      }
    }
    .formStyle(.grouped)
    .scrollDisabled(true)
  }

  func checkForUpdates() {
    isCheckingForUpdates = true
    Task {
      let model = await LicenseManager.shared.checkForUpdates()
      isCheckingForUpdates = false
      if let model = model {
        if model.isEligibleForUpdate {
          updater.checkForUpdates()
        } else if let latestEligibleVersion = model.latestEligibleVersion {
          switch compareVersions(normalizeVersion(appVersionOnly), normalizeVersion(latestEligibleVersion)) {
          case 1:
            let alert = NSAlert.init()
            alert.addButton(withTitle: "OK")
            alert.messageText = model.message ?? "No updates available"
            let _ = alert.runModal()
          case 0:
            let alert = NSAlert.init()
            alert.addButton(withTitle: "Purchase license")
            alert.addButton(withTitle: "Renew license")
            alert.addButton(withTitle: "Close")
            alert.messageText = "You're using the latest available version for your license. To continue getting updates, please purchase a new license or renew your current license"
            let response = alert.runModal()
            if response == NSApplication.ModalResponse.alertFirstButtonReturn {
              NSWorkspace.shared.open(URL(string: "https://compressx.app/pricing")!)
            }
            if response == NSApplication.ModalResponse.alertSecondButtonReturn {
              let licenseKey = LicenseManager.shared.licenseKey
              let productID = LicenseManager.shared.productID
              let url = "https://compressx.app/license-renew?license-key=\(licenseKey)&product-id=\(productID)"
              NSWorkspace.shared.open(URL(string: url)!)
            }
          case -1:
            let alert = NSAlert.init()
            alert.addButton(withTitle: "Download")
            alert.addButton(withTitle: "Close")
            alert.messageText = "You're not eligble for the latest update. The latest version you can use is \(latestEligibleVersion). Tap download to get it."
            let response = alert.runModal()
            if response == NSApplication.ModalResponse.alertFirstButtonReturn {
              if let url = model.downloadURL {
                NSWorkspace.shared.open(URL(string: url)!)
              } else {
                NSWorkspace.shared.open(URL(string: "https://compressx.app/download")!)
              }
            }
          default: break
          }
        } else {
          let alert = NSAlert.init()
          alert.addButton(withTitle: "OK")
          alert.messageText = model.message ?? "Failed to check for updates"
          let _ = alert.runModal()
        }
      }
    }
  }
}
