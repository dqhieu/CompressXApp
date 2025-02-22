//
//  OutputView.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 1/21/25.
//

import SwiftUI

struct OutputView: View {

  @AppStorage("outputFormat") var outputFormat: VideoFormat = .same

  @ObservedObject var jobManager = JobManager.shared

  let reducedSizeString: String?
  let timeTaken: String?

  var body: some View {
    Section {
      HStack {
        if jobManager.jobs.count > 1 {
          Image(systemName: "checkmark.seal.fill")
            .foregroundStyle(.green)
          Text("Output files (\(jobManager.isRunning ? (jobManager.currentIndex ?? 1) - 1 : jobManager.jobs.count))")
        } else {
          let reducedSize = (jobManager.jobs.first?.inputFileSize ?? 0) - (jobManager.jobs.first?.outputFileSize ?? 0)
          if reducedSize > 0 {
            Image(systemName: "checkmark.seal.fill")
              .foregroundStyle(.green)
          } else if outputFormat != .gif {
            Image(systemName: "exclamationmark.triangle.fill")
              .foregroundStyle(.orange)
          }
          Text("Output file")
        }
        Spacer()
        Button {
          NSWorkspace.shared.activateFileViewerSelecting(jobManager.jobs.map { $0.outputFileURL} )
        } label: {
          Text("Open in Finder")
        }
      }
      ScrollView {
        LazyVStack {
          ForEach(jobManager.jobs) { job in
            if FileManager.default.fileExists(atPath: job.outputFileURL.path(percentEncoded: false)), (jobManager.isRunning && (jobManager.currentIndex ?? 0) > (jobManager.getJobIndex(job) ?? 0) + 1) || (!jobManager.isRunning) {
              if job.id.uuidString != jobManager.jobs.first?.id.uuidString {
                Divider()
              }
              Button {
                NSWorkspace.shared.activateFileViewerSelecting([job.outputFileURL])
              } label: {
                VStack(alignment: .leading, spacing: 8) {
                  HStack(alignment: .top) {
                    Text(job.outputFileURL.lastPathComponent)
                    Spacer()
                    Text(fileSizeString(from: job.outputFileSize ?? 0))
                      .foregroundStyle(.secondary)
                  }
                  if jobManager.jobs.count > 1 {
                    HStack(alignment: .top) {
                      let reducedSize = (job.inputFileSize ?? 0) - (job.outputFileSize ?? 0)
                      if reducedSize > 0 {
                        Image(systemName: "arrow.down.circle.fill")
                          .foregroundStyle(.green)
                      } else if outputFormat != .gif {
                        Image(systemName: "exclamationmark.triangle.fill")
                          .foregroundStyle(.orange)
                      }
                      Text(fileSizeString(from: reducedSize))
                      if let reducedPercentage = job.reducedPercentage {
                        Text("(\(reducedPercentage))")
                      }
                      Spacer()
                      Image(systemName: "arrow.right")
                        .foregroundStyle(.secondary)
                    }
                  }
                }
                .background(Color.white.opacity(0.001))
              }
              .buttonStyle(.plain)
            }
          }
        }
      }
      .frame(maxHeight: 200)
      if let reducedSizeString = reducedSizeString {
        HStack {
          Text(jobManager.jobs.count == 1 ? "Size reduced" : "Total size reduced")
          Spacer()
          Text(reducedSizeString)
          if jobManager.jobs.count == 1, let job = jobManager.jobs.first, let reducedPercentage = job.reducedPercentage {
            Text("(\(reducedPercentage))")
          }
        }
      }
      if let timeTaken = timeTaken {
        HStack {
          Text("Time taken")
          Spacer()
          Text(timeTaken)
        }
      }
    }
  }
}
