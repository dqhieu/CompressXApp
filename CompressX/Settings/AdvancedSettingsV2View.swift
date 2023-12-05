//
//  AdvancedSettingsV2View.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 12/21/24.
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

struct AdvancedSettingsV2View: View {

  @AppStorage("hardwareAccelerationEnabled") var hardwareAccelerationEnabled = true
  @AppStorage("encodingCodec") var encodingCodec: Codec = .libx264
  @AppStorage("targetVideoFPS") var targetVideoFPS = TargetVideoFPS.same
  @AppStorage("retainImageMetadata") var retainImageMetadata = false
  @AppStorage("retainCreationDate") var retainCreationDate = false

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
        Text("If the video fps is smaller than target fps, the fps won't chage")
          .foregroundStyle(.secondary)
          .font(.caption)
      }
      VStack(alignment: .leading) {
        Toggle("Retain image metadata (EXIF, IPTC)", isOn: $retainImageMetadata)
        Text("Output image file size could be affected")
          .foregroundStyle(.secondary)
          .font(.caption)
      }
      VStack(alignment: .leading) {
        Toggle("Retain creation date", isOn: $retainCreationDate)
          .toggleStyle(.switch)
        Text("The compressed file will have the same creation date as the original file.")
          .foregroundStyle(.secondary)
          .font(.caption)
      }
    }
    .formStyle(.grouped)
    .scrollDisabled(true)
  }
}
