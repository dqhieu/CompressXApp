//
//  ImageOptionsView.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 1/3/25.
//

import SwiftUI

struct ImageOptionsView: View {

  @AppStorage("imageQuality") var imageQuality: ImageQuality = .highest
  @AppStorage("outputImageFormat") var outputImageFormat: ImageFormat = .same
  @AppStorage("imageDimension") var imageDimension: ImageDimension = .same

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
      Picker(selection: $imageDimension) {
        ForEach(ImageDimension.allCases, id: \.self) { dimension in
          Text(dimension.displayText).tag(dimension.rawValue)
        }
      } label: {
        Text("Image size")
      }
      .pickerStyle(.menu)
    }
    .disabled(jobManager.isRunning)
  }
}
