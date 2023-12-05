//
//  MonitoringSettingsView.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 12/21/24.
//

import SwiftUI

struct MonitoringSettingsView: View {

  @AppStorage("watchSettings") var watchSettings: [WatchSetting] = []

  var folders: [String] {
    return watchSettings.map { $0.folder }
  }

  var body: some View {
    Form {
      HStack {
        Text("Add a folder to start monitoring")
        Spacer()
        Button {
          openFolderSelectionPanel(currentFolder: nil)
        } label: {
          Text("Add folder")
        }
      }
      ForEach(watchSettings) { setting in
        WatchSettingCell(setting: setting)
      }
    }
    .formStyle(.grouped)
    .scrollDisabled(true)
  }

  func openFolderSelectionPanel(currentFolder: String?) {
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    if let currentFolder = currentFolder {
      panel.directoryURL = URL(string: currentFolder)
    }
    let response = panel.runModal()
    if response == .OK, let url = panel.url {
      if !folders.contains(url.path(percentEncoded: false)) {
        let setting = WatchSetting()
        setting.folder = url.path(percentEncoded: false)
        watchSettings.append(setting)
        Watcher.shared.start(settings: watchSettings)
      }
    }
  }
}
