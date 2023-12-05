//
//  UpdateSettingsView.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 31/7/24.
//

import SwiftUI
import Sparkle

struct UpdateSettingsView: View {

  @EnvironmentObject var installationManager: InstallationManager
  @AppStorage("shouldShowOnboardingV2") var shouldShowOnboardingV2 = true

  private let updater: SPUUpdater
  @State private var automaticallyChecksForUpdates: Bool
  @State private var automaticallyDownloadsUpdates: Bool

  init(updater: SPUUpdater) {
    self.updater = updater
    self.automaticallyChecksForUpdates = updater.automaticallyChecksForUpdates
    self.automaticallyDownloadsUpdates = updater.automaticallyDownloadsUpdates
  }

  var body: some View {
    Form {
      Toggle("Automatically check for updates", isOn: $automaticallyChecksForUpdates)
        .onChange(of: automaticallyChecksForUpdates) { newValue in
          updater.automaticallyChecksForUpdates = newValue
        }
        .toggleStyle(.switch)
      Toggle("Automatically download updates", isOn: $automaticallyDownloadsUpdates)
        .disabled(!automaticallyChecksForUpdates)
        .onChange(of: automaticallyDownloadsUpdates) { newValue in
          updater.automaticallyDownloadsUpdates = newValue
        }
        .toggleStyle(.switch)
      HStack {
        Text("Current version: \(appVersion)")
        Spacer()
        Button {
          if LicenseManager.shared.isValid {
            updater.checkForUpdates()
          } else {
            let alert = NSAlert.init()
            alert.addButton(withTitle: "OK")
            alert.messageText = "Please activate your license to check for updates"
            let _ = alert.runModal()
          }
        } label: {
          Text("Check for Updates")
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
        Spacer()
      }
    }
    .formStyle(.grouped)
    .frame(width: 540, height: 200)
    .scrollDisabled(true)
  }

}
