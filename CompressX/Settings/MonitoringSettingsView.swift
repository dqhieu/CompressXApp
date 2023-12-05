//
//  MonitoringSettingsView.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 12/21/24.
//

import SwiftUI

class WatchSetting: Identifiable, Codable {

  enum FileType: String, Codable, CaseIterable {
    case image
    case video
    case all

    var displayText: String {
      switch self {
      case .image:
        return "Image"
      case .video:
        return "Video"
      case .all:
        return "Video and image"
      }
    }
  }

  var id = UUID().uuidString
  var folder: String = ""
  var fileType: FileType = .all
  var imageQuality: ImageQuality = .high
  var imageFormat: ImageFormat? = .same
  var videoQuality: VideoQuality = .high
  var videoFormat: VideoFormat = .same
  var removeAudio: Bool = false
  var preserveTransparency: Bool = false
  var outputFolder: OutputFolder = .same
  var customOutputFolder: String = ""
  var removeFileAfterCompression: Bool? = false
  var videoDimension: VideoDimension? = .same
  var imageDimension: ImageDimension? = .same
  var outputFileNameFormat: String? = ""
}

struct WatchSettingView: View {

  @AppStorage("watchSettings") var watchSettings: [WatchSetting] = []
  var setting: WatchSetting

  @State private var fileType: WatchSetting.FileType = .all
  @State private var videoQuality: VideoQuality = .high
  @State private var videoFormat: VideoFormat = .same
  @State private var removeAudio = false
  @State private var imageQuality: ImageQuality = .high
  @State private var imageFormat: ImageFormat = .same
  @State private var outputFolder: OutputFolder = .same
  @State private var customOutputFolder: String = ""
  @State private var removeFileAfterCompression = false
  @State private var videoDimension: VideoDimension = .same
  @State private var imageDimension: ImageDimension = .same
  @State private var outputFileNameFormat: String = ""
  @State private var showOutputFileNameFormatPopover = false

  var body: some View {
    Form {
      Section {
        Picker("File type", selection: $fileType) {
          ForEach(WatchSetting.FileType.allCases, id: \.self) { type in
            Text(type.displayText).tag(type.rawValue)
          }
        }
        .pickerStyle(.menu)
        .onChange(of: fileType, perform: { newValue in
          setting.fileType = newValue
          updateSetting()
        })
      }
      if fileType == .video || fileType == .all {
        Section {
          Picker("Video quality", selection: $videoQuality) {
            ForEach([VideoQuality.highest, .high, .good, .medium, .acceptable], id: \.self) { quality in
              Text(quality.displayText).tag(quality.rawValue)
            }
          }
          .pickerStyle(.menu)
          .onChange(of: videoQuality, perform: { newValue in
            setting.videoQuality = newValue
            updateSetting()
          })
          Picker("Video resolution", selection: $videoDimension) {
            ForEach(VideoDimension.allCases, id: \.self) { dimension in
              Text(dimension.displayText).tag(dimension.rawValue)
            }
          }
          .pickerStyle(.menu)
          .onChange(of: videoDimension, perform: { newValue in
            setting.videoDimension = newValue
            updateSetting()
          })
          Picker("Video format", selection: $videoFormat) {
            ForEach(VideoFormat.allVideoCases, id: \.self) { format in
              Text(format.displayText).tag(format.rawValue)
            }
          }
          .pickerStyle(.menu)
          .onChange(of: videoFormat, perform: { newValue in
            setting.videoFormat = newValue
            updateSetting()
          })
          Toggle("Remove audio", isOn: $removeAudio)
            .toggleStyle(.switch)
            .onChange(of: removeAudio, perform: { newValue in
              setting.removeAudio = newValue
              updateSetting()
            })
        }
      }
      if fileType == .image || fileType == .all {
        Section {
          Picker("Image quality", selection: $imageQuality) {
            ForEach(ImageQuality.allCases, id: \.self) { quality in
              Text(quality.displayText).tag(quality.rawValue)
            }
          }
          .pickerStyle(.menu)
          .onChange(of: imageQuality, perform: { newValue in
            setting.imageQuality = newValue
            updateSetting()
          })
          Picker("Image format", selection: $imageFormat) {
            ForEach(ImageFormat.allCases, id: \.self) { format in
              Text(format.displayText).tag(format.rawValue)
            }
          }
          .pickerStyle(.menu)
          .onChange(of: imageFormat, perform: { newValue in
            setting.imageFormat = newValue
            updateSetting()
          })
          Picker("Image size", selection: $imageDimension) {
            ForEach(ImageDimension.allCases, id: \.self) { dimension in
              Text(dimension.displayText).tag(dimension.rawValue)
            }
          }
          .pickerStyle(.menu)
          .onChange(of: imageDimension, perform: { newValue in
            setting.imageDimension = newValue
            updateSetting()
          })
        }
      }
      Section {
        Toggle("Remove input file", isOn: $removeFileAfterCompression)
          .toggleStyle(.switch)
          .onChange(of: removeFileAfterCompression, perform: { newValue in
            setting.removeFileAfterCompression = newValue
            updateSetting()
          })
        VStack(spacing: 8) {
          Picker("Output folder", selection: $outputFolder) {
            ForEach(OutputFolder.allCases, id: \.self) { folder in
              Text(folder.displayText).tag(folder.rawValue)
            }
          }
          .pickerStyle(.menu)
          .onChange(of: outputFolder, perform: { newValue in
            if newValue == .custom, customOutputFolder.isEmpty {
              openFolderSelectionPanel()
            }
            setting.outputFolder = newValue
            updateSetting()
          })
          if outputFolder == .custom, !customOutputFolder.isEmpty {
            HStack {
              Text(customOutputFolder.replacingOccurrences(of: FileManager.default.homeDirectoryForCurrentUser.path(percentEncoded: false), with: "~/"))
                .textSelection(.enabled)
              Spacer()
              Button {
                openFolderSelectionPanel()
              } label: {
                Text("Change")
              }
            }
            .foregroundStyle(.secondary)
          }
        }
        VStack(alignment: .leading) {
          HStack {
            Text("Output file name format")
            Button(action: {
              showOutputFileNameFormatPopover.toggle()
            }, label: {
              Image(systemName: "exclamationmark.circle")
            })
            .buttonStyle(.bordered)
            .popover(isPresented: $showOutputFileNameFormatPopover) {
              VStack(alignment: .leading) {
                Text("Available variables:\n")
                Text("{timestamp} - Current unix timestamp")
                Text("{datetime} - Current date and time in \"yyyy-MM-dd'T'HHmmss\" format")
                Text("{date} - Current date in \"yyyy-MM-dd\" format")
                Text("{time} - Current time in \"HHmmss\" format")
              }
              .padding()
            }
          }
          TextField("Output file name format", text: $outputFileNameFormat)
            .textFieldStyle(.squareBorder)
            .labelsHidden()
            .onChange(of: outputFileNameFormat, perform: { newValue in
              setting.outputFileNameFormat = newValue
              updateSetting()
            })
        }
      }
    }
    .formStyle(.grouped)
    .frame(width: 300, height: formHeight)
    .scrollDisabled(true)
    .task {
      fileType = setting.fileType
      videoQuality = setting.videoQuality
      videoFormat = setting.videoFormat
      removeAudio = setting.removeAudio
      imageQuality = setting.imageQuality
      outputFolder = setting.outputFolder
      customOutputFolder = setting.customOutputFolder
      removeFileAfterCompression = setting.removeFileAfterCompression ?? false
      videoDimension = setting.videoDimension ?? .same
      imageDimension = setting.imageDimension ?? .same
      outputFileNameFormat = setting.outputFileNameFormat ?? ""
    }
  }

  var formHeight: CGFloat {
    switch fileType {
    case .image:
      return 350
    case .video:
      return 390
    case .all:
      return 510
    }
  }

  var extraHeight: CGFloat {
    return outputFolder == .same ? 0 : 20
  }

  func openFolderSelectionPanel() {
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    let response = panel.runModal()
    if response == .OK, let url = panel.url {
      customOutputFolder = url.path(percentEncoded: false)
      setting.outputFolder = outputFolder
      setting.customOutputFolder = customOutputFolder
      updateSetting()
    } else if customOutputFolder.isEmpty {
      outputFolder = .same
    }
  }

  func updateSetting() {
    guard let index = watchSettings.firstIndex(where: { $0.id == setting.id }) else { return }
    watchSettings[index] = setting
  }
}


struct WatchSettingCell: View {

  @AppStorage("watchSettings") var watchSettings: [WatchSetting] = []
  @State private var showSetting = false

  var setting: WatchSetting

  var body: some View {
    HStack {
      Text(setting.folder.replacingOccurrences(of: FileManager.default.homeDirectoryForCurrentUser.path(percentEncoded: false), with: "~/"))
        .truncationMode(.middle)
        .lineLimit(1)
      Spacer()

      Button(action: {
        showSetting.toggle()
      }, label: {
        Text("Settings")
      })
      .popover(isPresented: $showSetting) {
        WatchSettingView(setting: setting)
      }
      Button(action: {
        watchSettings.removeAll(where: { $0.id == setting.id })
      }, label: {
        Text("Remove")
      })
    }
  }
}

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
