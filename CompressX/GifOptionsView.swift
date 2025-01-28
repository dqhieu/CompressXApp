//
//  GifOptionsView.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 1/3/25.
//

import SwiftUI

struct GifOptionsView: View {

  @AppStorage("gifQuality") var gifQuality: VideoQuality = .high
  @AppStorage("gifDimension") var gifDimension: GifDimension = .same

  @ObservedObject var jobManager = JobManager.shared

  var gifQualities: [VideoQuality] = [.highest, .high, .good, .medium, .acceptable]

  var body: some View {
    Section {
      Picker(selection: $gifQuality) {
        ForEach(gifQualities, id: \.self) { quality in
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
    .disabled(jobManager.isRunning)
  }
}
