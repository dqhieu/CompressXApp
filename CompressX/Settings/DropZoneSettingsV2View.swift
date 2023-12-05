//
//  DropZoneSettingsV2View.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 12/21/24.
//

import SwiftUI

enum DropZoneCompressSettingsType: String, CaseIterable, Codable {
  case same
  case custom

  var displayText: String {
    switch self {
    case .same:
      return "Last used settings"
    case .custom:
      return "Custom"
    }
  }
}

enum DropZoneCompressionFileType: String, CaseIterable {
  case video
  case image
  case gif

  var displayText: String {
    switch self {
    case .video:
      return "Video"
    case .image:
      return "Image"
    case .gif:
      return "GIF"
    }
  }
}


struct DropZoneSettingsV2View: View {

  @AppStorage("dropZoneEnabled") var dropZoneEnabled = true
  @AppStorage("dropZoneCompressionSettingsType") var dropZoneCompressionSettingsType = DropZoneCompressSettingsType.same

  @State var fileType: DropZoneCompressionFileType = .video

  @AppStorage("dropZoneImageQuality") var imageQuality: ImageQuality = .good
  @AppStorage("dropZoneImageFormat") var imageFormat: ImageFormat = .same
  @AppStorage("dropZoneImageDimension") var imageDimension: ImageDimension = .same

  @AppStorage("dropZoneVideoQuality") var videoQuality: VideoQuality = .good
  @AppStorage("dropZoneVideoFormat") var videoFormat: VideoFormat = .same
  @AppStorage("dropZoneVideoDimension") var videoDimension: VideoDimension = .same
  @AppStorage("dropZoneRemoveAudio") var removeAudio: Bool = true
  @AppStorage("dropZonePreserveTransparency") var preserveTransparency: Bool = false

  @AppStorage("dropZoneGifQuality") var gifQuality: VideoQuality = .good
  @AppStorage("dropZoneGifDimension") var gifDimension: GifDimension = .same

  @AppStorage("dropZoneOutputFolder") var outputFolder: OutputFolder = .same
  @AppStorage("dropZoneCustomOutputFolder") var customOutputFolder: String = ""
  @AppStorage("dropZoneRemoveFileAfterCompression") var removeFileAfterCompression: Bool = false

  var body: some View {
    Form {
      Section {
        Toggle("Enable Drop Zone", isOn: $dropZoneEnabled)
          .toggleStyle(.switch)
          .onChange(of: dropZoneEnabled, perform: { newValue in
            if newValue == true {
              DropZoneManager.shared.enableDropZone()
            } else {
              DropZoneManager.shared.disableDropZone()
            }
          })
        if dropZoneEnabled {
          Picker(selection: $dropZoneCompressionSettingsType) {
            ForEach(DropZoneCompressSettingsType.allCases, id: \.self) { setting in
              Text(setting.displayText).tag(setting.rawValue)
            }
          } label: {
            HStack {
              Text("Compression settings")
            }
          }
        }
      }

      if dropZoneEnabled {
        if dropZoneCompressionSettingsType == .custom {
          Section {
            Toggle("Remove input file", isOn: $removeFileAfterCompression)
              .toggleStyle(.switch)
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
          }
          Section {
            Picker(selection: $fileType) {
              ForEach(DropZoneCompressionFileType.allCases, id: \.self) { type in
                Text(type.displayText).tag(type.rawValue)
              }
            } label: {
              HStack {
                Text(fileType.displayText)
              }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(maxWidth: .infinity, alignment: .center)
            if fileType == .video {
              Picker("Video quality", selection: $videoQuality) {
                ForEach([VideoQuality.highest, .high, .good, .medium, .acceptable], id: \.self) { quality in
                  Text(quality.displayText).tag(quality.rawValue)
                }
              }
              .pickerStyle(.menu)
              Picker("Video resolution", selection: $videoDimension) {
                ForEach(VideoDimension.allCases, id: \.self) { dimension in
                  Text(dimension.displayText).tag(dimension.rawValue)
                }
              }
              .pickerStyle(.menu)
              Picker("Video format", selection: $videoFormat) {
                ForEach(VideoFormat.allVideoCases, id: \.self) { format in
                  Text(format.displayText).tag(format.rawValue)
                }
              }
              .pickerStyle(.menu)
              Toggle("Remove audio", isOn: $removeAudio)
                .toggleStyle(.switch)
            }
            if fileType == .image {
              Picker("Image quality", selection: $imageQuality) {
                ForEach(ImageQuality.allCases, id: \.self) { quality in
                  Text(quality.displayText).tag(quality.rawValue)
                }
              }
              .pickerStyle(.menu)
              Picker("Image format", selection: $imageFormat) {
                ForEach(ImageFormat.allCases, id: \.self) { format in
                  Text(format.displayText).tag(format.rawValue)
                }
              }
              .pickerStyle(.menu)
              Picker("Image size", selection: $imageDimension) {
                ForEach(ImageDimension.allCases, id: \.self) { dimension in
                  Text(dimension.displayText).tag(dimension.rawValue)
                }
              }
              .pickerStyle(.menu)
            }
            if fileType == .gif {
              Picker(selection: $gifQuality) {
                ForEach([VideoQuality.highest, .high, .good, .medium, .acceptable], id: \.self) { quality in
                  Text(quality.displayText).tag(quality.rawValue)
                }
              } label: {
                Text("Gif quality")
              }
              .pickerStyle(.menu)
              Picker(selection: $gifDimension) {
                ForEach(GifDimension.allCases, id: \.self) { dimension in
                  Text(dimension.displayText).tag(dimension.rawValue)
                }
              } label: {
                Text("Gif dimension")
              }
              .pickerStyle(.menu)
            }
          }
        }
      }
    }
    .formStyle(.grouped)
    .scrollDisabled(true)
  }

  func openFolderSelectionPanel() {
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    let response = panel.runModal()
    if response == .OK, let url = panel.url {
      customOutputFolder = url.path(percentEncoded: false)
      outputFolder = outputFolder
      customOutputFolder = customOutputFolder
    } else if customOutputFolder.isEmpty {
      outputFolder = .same
    }
  }
}
