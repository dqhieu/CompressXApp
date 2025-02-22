//
//  FileManagementSettingsView.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 12/21/24.
//

import SwiftUI

enum OnDropBehavior: String, CaseIterable {
  case replace
  case append

  var displayText: String {
    switch self {
    case .replace:
      return "Replace current files"
    case .append:
      return "Append new files"
    }
  }
}

enum SubfolderProcessing: String, CaseIterable {
  case none
  case custom
  case all

  var displayText: String {
    switch self {
    case .none:
      return "None"
    case .custom:
      return "Custom"
    case .all:
      return "All"
    }
  }
}

struct FileManagementSettingsView: View {

  @AppStorage("removeFileAfterCompress") var removeFileAfterCompress = false
  @AppStorage("shouldShowRemoveFileWarning") var shouldShowRemoveFileWarning = true
  @AppStorage("copyOutputFilesToClipboard") var copyCompressedFilesToClipboard = false
  @AppStorage("outputFileNameFormat") var outputFileNameFormat = ""
  @AppStorage("onDropBehavior") var onDropBehavior: OnDropBehavior = .replace
  @AppStorage("thumbnailPreviewLimit") var thumbnailPreviewLimit = 20
  @AppStorage("subfolderProcessing") var subfolderProcessing: SubfolderProcessing = .none
  @AppStorage("subfolderProcessingLimit") var subfolderProcessingLimit = 1

  @State private var showOutputFileNameFormatPopover = false
  @State private var currentOutputFileNameFormat = ""
  @State private var thumbnailPreviewLimitText = "20"
  @State private var subfolderProcessingLimitText = "1"

  var body: some View {
    Form {
      VStack(alignment: .leading) {
        Toggle("Remove input files after compressing", isOn: $removeFileAfterCompress)
          .toggleStyle(.switch)
          .onChange(of: removeFileAfterCompress, perform: { newValue in
            if newValue == true, shouldShowRemoveFileWarning == true {
              shouldShowRemoveFileWarning = false
              showRemoveFileWarningAlert()
            }
          })
        Text("You can find the removed file in the Trash bin.")
          .foregroundStyle(.secondary)
          .font(.caption)
      }
      Toggle("Copy output files to clipboard", isOn: $copyCompressedFilesToClipboard)
        .toggleStyle(.switch)
      HStack {
        Text("Thumbnail preview limit")
        Spacer()
        TextField("", text: $thumbnailPreviewLimitText)
          .frame(width: 50)
          .textFieldStyle(.squareBorder)
          .labelsHidden()
          .multilineTextAlignment(.trailing)
          .onSubmit(onThumbnailPreviewLimitSubmittion)
        Text(" files")
        Button {
          onThumbnailPreviewLimitSubmittion()
        } label: {
          Text("Update")
        }
        .disabled(Int(thumbnailPreviewLimitText) == thumbnailPreviewLimit)
      }
      .task {
        thumbnailPreviewLimitText = String(thumbnailPreviewLimit)
      }
      VStack(alignment: .leading, spacing: 4) {
        Picker(selection: $onDropBehavior) {
          ForEach(OnDropBehavior.allCases, id: \.self) { behavior in
            Text(behavior.displayText).tag(behavior.rawValue)
          }
        } label: {
          Text("On drop files and folders into main window")
        }
        Text("Hold Option key to always append files.")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      VStack(alignment: .leading, spacing: 4) {
        Picker(selection: $subfolderProcessing) {
          ForEach(SubfolderProcessing.allCases, id: \.self) { behavior in
            Text(behavior.displayText).tag(behavior.rawValue)
          }
        } label: {
          Text("Include files in subfolders recursively")
        }
        if subfolderProcessing == .custom {
          HStack {
            Text("Max depth")
              .font(.caption)
              .foregroundStyle(.secondary)
            Spacer()
            TextField("", text: $subfolderProcessingLimitText)
              .frame(width: 50)
              .textFieldStyle(.squareBorder)
              .labelsHidden()
              .multilineTextAlignment(.trailing)
              .onSubmit(onMaxDepthSubmittion)
            Button {
              onMaxDepthSubmittion()
            } label: {
              Text("Update")
            }
            .disabled(Int(subfolderProcessingLimitText) == subfolderProcessingLimit)
          }
          .task {
            subfolderProcessingLimitText = String(subfolderProcessingLimit)
          }
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
        HStack {
          TextField("Output file name format", text: $currentOutputFileNameFormat)
            .textFieldStyle(.squareBorder)
            .labelsHidden()
            .onSubmit {
              outputFileNameFormat = currentOutputFileNameFormat
            }
          Button(action: {
            outputFileNameFormat = currentOutputFileNameFormat
          }, label: {
            Text("Update")
          })
          .disabled(outputFileNameFormat == currentOutputFileNameFormat)
        }
        .onAppear {
          currentOutputFileNameFormat = outputFileNameFormat
        }
        VStack(alignment: .leading) {
          Text("Example: input1.mov → " + getSampleOutputFileName1())
          Text("Example: input2.mov → " + getSampleOutputFileName2())
        }
        .foregroundStyle(.secondary)
        .font(.caption)
      }
    }
    .formStyle(.grouped)
    .scrollDisabled(true)
  }

  func onThumbnailPreviewLimitSubmittion() {
    if let limit = Int(thumbnailPreviewLimitText), limit > 0 {
      thumbnailPreviewLimit = abs(limit)
    } else {
      let alert = NSAlert()
      alert.messageText = "Invalid value"
      alert.informativeText = "Value must be an positive integer"
      alert.addButton(withTitle: "OK")
      let _ = alert.runModal()
    }
  }

  func onMaxDepthSubmittion() {
    if let limit = Int(subfolderProcessingLimitText), limit > 0 {
      subfolderProcessingLimit = abs(limit)
    } else {
      let alert = NSAlert()
      alert.messageText = "Invalid value"
      alert.informativeText = "Value must be an positive integer"
      alert.addButton(withTitle: "OK")
      let _ = alert.runModal()
    }
  }

  func showRemoveFileWarningAlert() {
    let alert = NSAlert()
    alert.messageText = "Warning!"
    alert.informativeText = "Please note that the compressed video may not retain the same level of quality as the original. Therefore, it is advisable not to substitute the original video with its compressed version for storage purposes.\n\nYou can find the removed video in the Trash bin."
    alert.addButton(withTitle: "Understood")
    alert.runModal()
  }

  func getSampleOutputFileName1() -> String {
    let format = currentOutputFileNameFormat
      .replacingOccurrences(of: "{timestamp}", with: "\(Int(Date.now.timeIntervalSince1970))")
      .replacingOccurrences(of: "{datetime}", with: Date().toISO8601DateTime)
      .replacingOccurrences(of: "{date}", with: Date().toISO8601Date)
      .replacingOccurrences(of: "{time}", with: Date().toISO8601Time)
    let outputFileName = "input1" + format + ".mp4"
    return outputFileName
  }

  func getSampleOutputFileName2() -> String {
    let format = currentOutputFileNameFormat
      .replacingOccurrences(of: "{timestamp}", with: "\(Int(Date.now.timeIntervalSince1970))")
      .replacingOccurrences(of: "{datetime}", with: Date().toISO8601DateTime)
      .replacingOccurrences(of: "{date}", with: Date().toISO8601Date)
      .replacingOccurrences(of: "{time}", with: Date().toISO8601Time)
    if format.isEmpty {
      return "input2" + "_compressed.mov"
    } else {
      return "input2" + format + ".mov"
    }
  }
}
