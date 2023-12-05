//
//  CompressHistoryView.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 28/3/24.
//

import SwiftUI

struct HistoryCell: View {
  var compressionHistory: CompressionHistory

  var body: some View {
    VStack(spacing: 0) {
      Button(action: {
        if FileManager.default.fileExists(atPath: compressionHistory.fileName) {
          NSWorkspace.shared.activateFileViewerSelecting([URL(filePath: compressionHistory.fileName)])
        }
      }, label: {
        HStack {
          if let url = URL(string: compressionHistory.fileName) {
            Text(url.lastPathComponent)
          } else {
            Text(compressionHistory.fileName)
          }
          Text("•")
          Text("\(compressionHistory.reducedSize) reduced (\(Int(compressionHistory.reducePercentage * 100))%)")
            .foregroundStyle(.secondary)
          Spacer()
          Text("\(compressionHistory.originalSize) → \(compressionHistory.compressedSize)")
            .foregroundStyle(.secondary)
        }
      })
      .buttonStyle(.plain)
    }
  }
}

struct CompressHistoryView: View {

  @AppStorage("compressionHistories") var compressionHistories: [CompressionHistory] = []
  @AppStorage("shouldSaveCompressionHistory") var shouldSaveCompressionHistory = true
  @AppStorage("videoCompressed") var videoCompressed: Int = 0
  @AppStorage("imageCompressed") var imageCompressed: Int = 0
  @AppStorage("gifCompressed") var gifCompressed: Int = 0
  @AppStorage("gifConverted") var gifConverted: Int = 0
  @AppStorage("sizeReduced") var sizeReduced = 0

  var body: some View {
    Group {
      if compressionHistories.isEmpty {
        if #available(macOS 14, *) {
          ContentUnavailableView {
            Label("No files has been compressed", systemImage: "doc")
          } description: {
            Text("Your compression history will appear here.")
            Toggle("Keep compression history", isOn: $shouldSaveCompressionHistory)
          }
        } else {
          VStack {
            Image(systemName: "doc")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 100, height: 100, alignment: .center)
            Text("Your compression history will show here")
            Toggle("Keep compression history", isOn: $shouldSaveCompressionHistory)
          }
        }
      } else {
        VStack(alignment: .leading) {
          HStack(alignment: .top) {
            VStack(alignment: .leading) {
              Text("Total compressed files: \(videoCompressed + imageCompressed + gifCompressed)")
              Text("Total reduced size: \(fileSizeString(from: Int64(sizeReduced)))")
            }
            Spacer()
            VStack(alignment: .trailing) {
              Toggle("Keep compression history", isOn: $shouldSaveCompressionHistory)
                .onChange(of: shouldSaveCompressionHistory, perform: { newValue in
                  if newValue {

                  } else {
                    compressionHistories.removeAll()
                  }
                })
              Text("Disable this will also clear the compression history")
                .foregroundStyle(.secondary)
            }
          }
          .padding([.horizontal, .top])
          HStack {
            Text("Latest compression:")
            Spacer()
            Text("Data is stored locally on your device.")
              .italic()
          }
          .foregroundStyle(.secondary)
          .padding([.horizontal, .top])
          Form {
            List {
              ForEach(compressionHistories.reversed(), id: \.self) { history in
                HistoryCell(compressionHistory: history)
                  .padding(.vertical, 4)
              }
            }
          }
        }
      }
    }
    .frame(minWidth: 400, minHeight: 200)
  }
}

#Preview {
  CompressHistoryView()
    .frame(width: 600, height: 400, alignment: .center)
}
