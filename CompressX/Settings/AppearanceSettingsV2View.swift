//
//  AppearanceSettingsV2View.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 12/21/24.
//

import SwiftUI
import TelemetryClient

enum NotchStyle: String, CaseIterable {
  case none
  case compact
  case expanded

  var displayText: String {
    switch self {
    case .none:
      return "None"
    case .compact:
      return "Compact"
    case .expanded:
      return "Expanded"
    }
  }
}

struct AppearanceSettingsV2View: View {

  @AppStorage("selectedAppIconName") var selectedAppIconName = "AppIcon"
  @AppStorage("notchStyle") var notchStyle: NotchStyle = .expanded
  @AppStorage("confettiEnabled") var confettiEnabled = false

  var body: some View {
    Form {
      Section {
        Picker(selection: $notchStyle) {
          ForEach(NotchStyle.allCases, id: \.self) { style in
            Text(style.displayText).tag(style.rawValue)
          }
        } label: {
          Text("Dynamic island style")
        }
        .onChange(of: notchStyle) { newValue in
          NotchKit.shared.close()
          if newValue == .expanded || newValue == .compact {
            NotchKit.shared.show(folderPath: "", notchStyle: newValue, dismissDelay: 3)
          }
        }
        Toggle(isOn: $confettiEnabled) {
          VStack(alignment: .leading) {
            Text("Show confetti when compression finishes")
            Text("Requires [Raycast](https://www.raycast.com/) to be installed.")
              .foregroundStyle(.secondary)
              .font(.caption)
          }
        }
        .onChange(of: confettiEnabled) { newValue in
          if newValue, let url = URL(string: "raycast://confetti"), let _ = NSWorkspace.shared.urlForApplication(toOpen: url) {
            NSWorkspace.shared.open(url)
          } else {
            confettiEnabled = false
          }
        }
      }
      Section {
        LazyVGrid(columns: [
          GridItem(.flexible()),
          GridItem(.flexible())
        ], alignment: .leading
        ) {
          if let iconImage = NSImage(named: "AppIcon") {
            HStack {
              Image(nsImage: iconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64, height: 64, alignment: .center)
                .onTapGesture {
                  changeIcon(iconImage: iconImage, iconName: "AppIcon")
                }
              Text("Original")
              Spacer()
            }
          }
          if let iconImage = NSImage(named: "CompressXBlue") {
            HStack {
              Image(nsImage: iconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64, height: 64, alignment: .center)
                .onTapGesture {
                  changeIcon(iconImage: iconImage, iconName: "CompressXBlue")
                }
              Text("Blue")
              Spacer()
            }
          }
          if let iconImage = NSImage(named: "CompressX-alohe-light") {
            HStack {
              Image(nsImage: iconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64, height: 64, alignment: .center)
                .onTapGesture {
                  changeIcon(iconImage: iconImage, iconName: "CompressX-alohe-light")
                }
              VStack(alignment: .leading) {
                Text("Alohe Light")
                Link(destination: URL(string: "https://twitter.com/alemalohe")!) {
                  Text("@alemalohe")
                }
              }
            }
          }
          if let iconImage = NSImage(named: "CompressX-alohe-dark") {
            HStack {
              Image(nsImage: iconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64, height: 64, alignment: .center)
                .onTapGesture {
                  changeIcon(iconImage: iconImage, iconName: "CompressX-alohe-dark")
                }
              VStack(alignment: .leading) {
                Text("Alohe Dark")
                Link(destination: URL(string: "https://twitter.com/alemalohe")!) {
                  Text("@alemalohe")
                }
              }
            }
          }
          if let iconImage = NSImage(named: "CompressX-Kacper") {
            HStack {
              Image(nsImage: iconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64, height: 64, alignment: .center)
                .onTapGesture {
                  changeIcon(iconImage: iconImage, iconName: "CompressX-Kacper")
                }
              VStack(alignment: .leading) {
                Text("Kacper")
                Link(destination: URL(string: "https://twitter.com/kacperfyi")!) {
                  Text("@kacperfyi")
                }
              }
            }
          }
        }
      } header: {
        Text("Dock Icon")
      }
    }
    .formStyle(.grouped)
    .scrollDisabled(true)
  }

  func changeIcon(iconImage: NSImage, iconName: String) {
    TelemetryDeck.signal("compress.dockIcon.change", parameters: [
      "iconName": iconName,
    ])
    selectedAppIconName = iconName
    changeAppIcon(image: iconImage)
  }
}
