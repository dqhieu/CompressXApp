//
//  AdvanceSettingsView.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 12/4/24.
//

import SwiftUI

enum Codec: String, CaseIterable {
  case libx264 = "libx264"
  case libx265 = "libx265"

  var displayText: String {
    switch self {
    case .libx264: "H.264 (Recommended)"
    case .libx265: "H.265/HEVC"
    }
  }
}

enum TargetVideoFPS: String, Codable, CaseIterable {
  case same
  case sixty
  case thirdty
  case twentyFour
  case fifteen

  var displayText: String {
    switch self {
    case .same:
      return "Same as input"
    case .sixty:
      return "60"
    case .thirdty:
      return "30"
    case .twentyFour:
      return "24"
    case .fifteen:
      return "15"
    }
  }

  var value: Float {
    switch self {
    case .same:
      return 30
    case .sixty:
      return 60
    case .thirdty:
      return 30
    case .twentyFour:
      return 24
    case .fifteen:
      return 15
    }
  }
}

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

struct AdvanceSettingsView: View {

  @AppStorage("hardwareAccelerationEnabled") var hardwareAccelerationEnabled = true
  @AppStorage("shouldEstiamteCompressedVideoSize") var shouldEstiamteCompressedVideoSize = false
  @AppStorage("encodingCodec") var encodingCodec: Codec = .libx264
  @AppStorage("shareAnonymousAnalytics") var shareAnonymousAnalytics = true
  @AppStorage("targetVideoFPS") var targetVideoFPS = TargetVideoFPS.same
  @AppStorage("retainImageMetadata") var retainImageMetadata = false
  @AppStorage("thumbnailPreviewLimit") var thumbnailPreviewLimit = 50
  @AppStorage("onDropBehavior") var onDropBehavior: OnDropBehavior = .replace

  @State private var thumbnailPreviewLimitText = "100"

  var body: some View {
    Form {
      Toggle("Automatic hardware acceleration", isOn: $hardwareAccelerationEnabled)
        .toggleStyle(.switch)
      Picker(selection: $encodingCodec) {
        ForEach(Codec.allCases, id: \.self) { codec in
          Text(codec.displayText).tag(codec.rawValue)
        }
      } label: {
        HStack {
          Text("Video encoding codec")
          if #available(macOS 14, *) {
            Button(action: {
              if let url = URL(string: "https://compressx.app/newsroom/h264-vs-h265") {
                NSWorkspace.shared.open(url)
              }
            }, label: {
              Image(systemName: "questionmark")
            })
            .buttonBorderShape(.circle)
          } else {
            Button(action: {
              if let url = URL(string: "https://compressx.app/newsroom/h264-vs-h265") {
                NSWorkspace.shared.open(url)
              }
            }, label: {
              Image(systemName: "questionmark.circle")
            })
            .clipShape(.circle)
          }
        }
      }
      .pickerStyle(.menu)
      VStack(alignment: .leading) {
        Picker(selection: $targetVideoFPS) {
          ForEach(TargetVideoFPS.allCases, id: \.self) { target in
            Text(target.displayText).tag(target.rawValue)
          }
        } label: {
          HStack {
            Text("Target video FPS")
          }
        }
        Text("Compressed video's FPS = min(input video's FPS, target FPS)")
          .foregroundStyle(.secondary)
      }
      VStack(alignment: .leading) {
        Toggle("Retain image metadata (EXIF, IPTC)", isOn: $retainImageMetadata)
        Text("Output image file size could be affected")
          .foregroundStyle(.secondary)
      }
      HStack {
        Text("Do not generate preview thumbnail for more than")
        Spacer()
        TextField("", text: $thumbnailPreviewLimitText)
          .frame(width: 50)
          .textFieldStyle(.squareBorder)
          .labelsHidden()
          .multilineTextAlignment(.trailing)
          .onSubmit(onSubmittion)
        Text(" files")
        Button {
          onSubmittion()
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
          Text("On drop files into main window")
        }
        Text("Hold Option key to always append files.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      Toggle("Share anonymous analytics", isOn: $shareAnonymousAnalytics)
        .toggleStyle(.switch)
        .onChange(of: shareAnonymousAnalytics, perform: { value in
          telemetryConfiguration.analyticsDisabled = !value
        })
    }
    .formStyle(.grouped)
    .frame(width: 540, height: 370) // Updated height
    .scrollDisabled(true)
  }

  func onSubmittion() {
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
}

#Preview {
  AdvanceSettingsView()
}
