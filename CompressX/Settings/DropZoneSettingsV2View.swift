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
  case pdf

  var displayText: String {
    switch self {
    case .video:
      return "Video"
    case .image:
      return "Image"
    case .gif:
      return "GIF"
    case .pdf:
      return "PDF"
    }
  }
}


struct DropZoneSettingsV2View: View {

  @AppStorage("dropZoneEnabled") var dropZoneEnabled = true
  @AppStorage("dropZoneCompressionSettingsType") var dropZoneCompressionSettingsType = DropZoneCompressSettingsType.same

  @State var fileType: DropZoneCompressionFileType = .video

  @AppStorage("dropZoneImageQuality") var imageQuality: ImageQuality = .good
  @AppStorage("dropZoneImageFormat") var imageFormat: ImageFormat = .same
  @AppStorage("dropZoneImageSize") var imageSize: ImageSize = .same
  @AppStorage("dropZoneImageSizeValue") var dropZoneImageSizeValue = 100

  @AppStorage("dropZoneVideoQuality") var videoQuality: VideoQuality = .good
  @AppStorage("dropZoneVideoFormat") var videoFormat: VideoFormat = .same
  @AppStorage("dropZoneVideoDimension") var videoDimension: VideoDimension = .same
  @AppStorage("dropZoneRemoveAudio") var removeAudio: Bool = true
  @AppStorage("dropZonePreserveTransparency") var preserveTransparency: Bool = false

  @AppStorage("dropZoneGifQuality") var gifQuality: VideoQuality = .good
  @AppStorage("dropZoneGifDimension") var gifDimension: GifDimension = .same

  @AppStorage("dropZonePdfQuality") var dropZonePdfQuality: PDFQuality = .balance

  @AppStorage("dropZoneOutputFolder") var outputFolder: OutputFolder = .same
  @AppStorage("dropZoneCustomOutputFolder") var customOutputFolder: String = ""
  @AppStorage("dropZoneRemoveFileAfterCompression") var removeFileAfterCompression: Bool = false

  @State private var dropZoneImageSizeValueText = "100"

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
              VStack {
                Picker("Image size", selection: $imageSize) {
                  ForEach(ImageSize.allCases, id: \.self) { size in
                    Text(size.displayText).tag(size.rawValue)
                  }
                }
                .pickerStyle(.menu)
                if imageSize != .same {
                  HStack {
                    TextField("Value", text: $dropZoneImageSizeValueText, onEditingChanged: { (editingChanged) in
                      if !editingChanged {
                        onSubmittion()
                      }
                    })
                    .frame(width: 100)
                    .textFieldStyle(.squareBorder)
                    .labelsHidden()
                    .multilineTextAlignment(.trailing)
                    .onSubmit(onSubmittion)
                    .task {
                      dropZoneImageSizeValueText = String(dropZoneImageSizeValue)
                    }
                    Text(imageSize == .percentage ? "%" : "px")
                      .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                      onSubmittion()
                    } label: {
                      Text("Update")
                    }
                    .disabled(dropZoneImageSizeValue == Int(dropZoneImageSizeValueText))
                  }
                }
              }
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
            if fileType == .pdf {
              Picker(selection: $dropZonePdfQuality) {
                ForEach(PDFQuality.allCases, id: \.self) { quality in
                  Text(quality.displayText).tag(quality.rawValue)
                }
              } label: {
                Text("PDF quality")
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

  func onSubmittion() {
    if let value = Int(dropZoneImageSizeValueText), value > 0 && value <= 65535 {
      dropZoneImageSizeValue = value
    } else {
      let alert = NSAlert()
      alert.messageText = "Invalid value"
      if (Int(dropZoneImageSizeValueText) ?? 0) <= 0 {
        alert.informativeText = "Value must be an positive integer"
      } else if (Int(dropZoneImageSizeValueText) ?? 0) > 65535 {
        alert.informativeText = "Value is too large"
      }
      alert.addButton(withTitle: "OK")
      let _ = alert.runModal()
    }
  }
}
