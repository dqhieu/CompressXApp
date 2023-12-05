//
//  GeneralSettingsV2View.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 12/21/24.
//

import SwiftUI
import LaunchAtLogin
import UserNotifications
import KeyboardShortcuts

struct GeneralSettingsV2View: View {

  @AppStorage("showMenuBarIcon") var showMenuBarIcon = true
  @AppStorage("showDockIcon") var showDockIcon = true
  @AppStorage("notifyWhenFinish") var notifyWhenFinish = false
  @AppStorage("showMainWindowAtLaunch") var showMainWindowAtLaunch = true
  @AppStorage("pinMainWindowOnTop") var pinMainWindowOnTop = false
  @AppStorage("shareAnonymousAnalytics") var shareAnonymousAnalytics = true

  var body: some View {
    Form {
      LaunchAtLogin.Toggle()
      Toggle("Notify when finish compressing", isOn: $notifyWhenFinish)
        .toggleStyle(.switch)
        .onChange(of: notifyWhenFinish, perform: { newValue in
          if newValue == true {
            UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .alert]) { _,_  in
            }
          }
        })
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
      KeyboardShortcuts.Recorder("Show main window shortcut", name: .showMainWindow)
      VStack {
        Toggle(isOn: $pinMainWindowOnTop) {
          Text("Pin main window on top")
        }
        KeyboardShortcuts.Recorder("Toggle shortcut", name: .togglePinMainWindowOnTop)
      }
      Toggle("Share anonymous analytics", isOn: $shareAnonymousAnalytics)
        .toggleStyle(.switch)
        .onChange(of: shareAnonymousAnalytics, perform: { value in
          telemetryConfiguration.analyticsDisabled = !value
        })
    }
    .formStyle(.grouped)
    .scrollDisabled(true)
  }

}
