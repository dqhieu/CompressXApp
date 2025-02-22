//
//  ImageOptionsView.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 1/3/25.
//

import SwiftUI

enum ImageSize: String, CaseIterable, Codable {
  case same
  case percentage
  case maxWidth
  case maxHeight
  case maxLongEdge
  case maxShortEdge

  var displayText: String {
    switch self {
    case .same:
      return "Same as input"
    case .percentage:
      return "Percentage"
    case .maxWidth:
      return "Max width"
    case .maxHeight:
      return "Max height"
    case .maxLongEdge:
      return "Max long edge"
    case .maxShortEdge:
      return "Max short edge"
    }
  }
}

struct ImageOptionsView: View {

  @AppStorage("imageQuality") var imageQuality: ImageQuality = .highest
  @AppStorage("outputImageFormat") var outputImageFormat: ImageFormat = .same
  @AppStorage("imageSize") var imageSize: ImageSize = .same
  @AppStorage("imageSizeValue") var imageSizeValue: Int = 100
  @AppStorage("imageSizeValueText") var imageSizeValueText: String = "100"

  @State var selection = 0

  @ObservedObject var jobManager = JobManager.shared

  var body: some View {
    Section {
      Picker(selection: $imageQuality) {
        ForEach(ImageQuality.allCases, id: \.self) { quality in
          Text(quality.displayText).tag(quality.rawValue)
        }
      } label: {
        Text("Image quality")
      }
      .pickerStyle(.menu)
      Picker(selection: $outputImageFormat) {
        ForEach(ImageFormat.allCases, id: \.self) { format in
          Text(format.displayText).tag(format.rawValue)
        }
      } label: {
        Text("Image format")
      }
      .pickerStyle(.menu)
      VStack {
        Picker(selection: $imageSize) {
          ForEach(ImageSize.allCases, id: \.self) { size in
            Text(size.displayText).tag(size.rawValue)
          }
        } label: {
          Text("Image size")
        }
        .pickerStyle(.menu)
        if imageSize != .same {
          HStack {
            TextField("Value", text: $imageSizeValueText, onEditingChanged: { (editingChanged) in
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
              imageSizeValueText = String(imageSizeValue)
            }
            Text(imageSize == .percentage ? "%" : "px")
              .foregroundStyle(.secondary)
            Spacer()
            Button {
              onSubmittion()
            } label: {
              Text("Update")
            }
            .disabled(imageSizeValue == Int(imageSizeValueText))
          }
        }
      }
    }
    .disabled(jobManager.isRunning)
  }

  func onSubmittion() {
    if let value = Int(imageSizeValueText), value > 0 && value <= 65535 {
      imageSizeValue = value
    } else {
      let alert = NSAlert()
      alert.messageText = "Invalid value"
      if (Int(imageSizeValueText) ?? 0) <= 0 {
        alert.informativeText = "Value must be an positive integer"
      } else if (Int(imageSizeValueText) ?? 0) > 65535 {
        alert.informativeText = "Value is too large"
      }
      alert.addButton(withTitle: "OK")
      let _ = alert.runModal()
    }
  }
}
