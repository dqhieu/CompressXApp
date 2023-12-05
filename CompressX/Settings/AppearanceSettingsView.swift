//
//  AppearanceSettingsView.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 9/8/24.
//

import SwiftUI
import TelemetryClient
import KeyboardShortcuts

struct AppearanceSettingsView: View {

  @AppStorage("selectedAppIconName") var selectedAppIconName = "AppIcon"
  @AppStorage("showMenuBarIcon") var showMenuBarIcon = true
  @AppStorage("showDockIcon") var showDockIcon = true
  @AppStorage("showMainWindowAtLaunch") var showMainWindowAtLaunch = true
  @AppStorage("pinMainWindowOnTop") var pinMainWindowOnTop = false

  var body: some View {
    Form {
      Section {
        Toggle(isOn: $showDockIcon) {
          Text("Show Dock icon")
        }
        .onChange(of: showDockIcon, perform: { newValue in
          if newValue {
            NSApp.setActivationPolicy(.regular)
          } else {
            NSApp.setActivationPolicy(.accessory)
          }
        })
        Toggle(isOn: $showMenuBarIcon) {
          Text("Show Menu Bar icon")
        }
        Toggle(isOn: $showMainWindowAtLaunch) {
          Text("Show main window at launch")
        }
        VStack {
          Toggle(isOn: $pinMainWindowOnTop) {
            Text("Pin main window on top")
          }
          KeyboardShortcuts.Recorder("Toggle shortcut", name: .togglePinMainWindowOnTop)
        }
        KeyboardShortcuts.Recorder("Show main window shortcut", name: .showMainWindow)
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
              VStack {
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
              VStack {
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
              VStack {
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
    .frame(width: 540, height: 540)
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
