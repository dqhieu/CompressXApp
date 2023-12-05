//
//  SettingsView.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 24/11/2023.
//

import SwiftUI
import Sparkle
import UserNotifications
import AppKit
import TelemetryClient
import LaunchAtLogin

struct SettingsView: View {

  @EnvironmentObject var installationManager: InstallationManager

  @AppStorage("ffmpegPath") var ffmpegPath = ""
  @AppStorage("pngquantPath") var pngquantPath = ""
  @AppStorage("gifskiPath") var gifskiPath = ""
  @AppStorage("shouldShowOnboardingV2") var shouldShowOnboardingV2 = true
  @AppStorage("outputFolder") var outputFolder: OutputFolder = .same
  @AppStorage("customOutputFolder") var customOutputFolder = ""

  private let updater: SPUUpdater
  @State var localFFmpegPath = ""
  @State var showInstructions = false
  @ObservedObject var jobManager = JobManager.shared

  @FocusState private var isTextFieldFocused: Bool
  
  init(updater: SPUUpdater) {
    self.updater = updater
  }
  
  var body: some View {
    TabView {
      GeneralSettingsView()
        .tabItem {
          Label("General", systemImage: "slider.horizontal.3")
        }
      AdvanceSettingsView()
        .tabItem {
          Label("Advanced", systemImage: "gearshape.2")
        }
      UpdateSettingsView(updater: updater)
        .environmentObject(installationManager)
        .tabItem {
          Label("Updates", systemImage: "arrow.triangle.2.circlepath.circle")
        }
      AppearanceSettingsView()
        .tabItem {
          Label("Appearance", systemImage: "wand.and.stars")
        }
      WatcherSettingsView()
        .tabItem {
          Label("Monitoring", systemImage: "eyes")
        }
      DropZoneSettingsView()
        .tabItem {
          Label("Drop Zone", systemImage: "doc.viewfinder")
        }
      LicenseView()
        .tabItem {
          Label("License", systemImage: "key")
        }
      InfoView()
        .tabItem {
          Label("Info", systemImage: "info.circle")
        }
      
      #if DEBUG
//      Form {
//        Button {
//          ffmpegPath = ""
//        } label: {
//          Text("Clear ffmpeg")
//        }
//        Button {
//          pngquantPath = ""
//        } label: {
//          Text("Clear pngquant")
//        }
//        Button {
//          gifskiPath = ""
//        } label: {
//          Text("Clear gifski")
//        }
//        Button {
//          shouldShowOnboardingV2 = true
//        } label: {
//          Text("Reset onboarding")
//        }
//
//        Button {
//          LicenseManager.shared.reset()
//        } label: {
//          Text("Reset license")
//        }
//      }
//      .tabItem {
//        Label("Debug", systemImage: "hammer")
//      }
//      .formStyle(.grouped)
//      .frame(width: 540, height: 260)
//      .scrollDisabled(true)
      #endif
    }
  }
  
}

#Preview {
  SettingsView(updater: SPUStandardUpdaterController(startingUpdater: false, updaterDelegate: nil, userDriverDelegate: nil).updater)
}
