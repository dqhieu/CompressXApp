//
//  HUDJobManager.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 01/03/2024.
//

import Foundation
import SwiftUI
import TelemetryClient

class HUDJobManager: ObservableObject {
  @Published var isRunning = false
  @Published var jobs: [Job] = []
  @Published var currentIndex: Int?
  @Published var currentJob: Job?
  private var currentProcess: Process?
  private var isTerminated = false
  @Published var currentProgress: Double = 0
  @AppStorage("retainImageMetadata") var retainImageMetadata = false
  @AppStorage("copyOutputFilesToClipboard") var copyCompressedFilesToClipboard = false
  @AppStorage("confettiEnabled") var confettiEnabled = false

  static let shared = HUDJobManager()

  func compress(job: Job, isRetrying: Bool = false) async -> String? {
    guard isFileSupported(url: job.inputFileURL) else {
      return "File format is not supported"
    }
    guard FileManager.default.fileExists(atPath: job.inputFileURL.path(percentEncoded: false)) else {
      return "Input file does not exist"
    }
    if case .image(let imageQuality, let imageFormat, let imageDimension) = job.outputType, imageFormat == .webp {
      return WebPCoder.shared.convert(
        inputURL: job.inputFileURL,
        outputURL: job.outputFileURL,
        imageQuality: imageQuality,
        imageDimension: imageDimension
      )
    }
    let (process, pathError) = await JobManager.shared.createTask(job: job)
    currentProcess = process
    catchProgress(job: job, process: process)
    if isRetrying {
      job.status = "Retrying"
    } else {
      if job.isMKV {
        job.status = "Compressing"
      } else if job.isVideo {
        job.status = "Preparing"
      } else if job.isGif {
        job.status = "Converting"
      } else {
        job.status = "Compressing"
      }
    }
    let error = await CommandlineHelper.run(process: process)
    currentProcess = nil
    if error == nil,
       case .video(let videoQuality, let videoDimension, let videoFormat, let hasAudio, let removeAudio, let preserveTransparency, let startTime, let endTime) = job.outputType,
       FileManager.default.fileExists(atPath: job.outputFileURL.path(percentEncoded: false)),
       (job.outputFileSize ?? 0) >= (job.inputFileSize ?? 0),
       let nextQuality = videoQuality.next {
      let newOutputType = OutputType.video(
        videoQuality: nextQuality,
        videoDimension: videoDimension,
        videoFormat: videoFormat,
        hasAudio: hasAudio,
        removeAudio: removeAudio,
        preserveTransparency: preserveTransparency,
        startTime: startTime,
        endTime: endTime
      )
      job.outputType = newOutputType
      job.outputFileURL.removeCachedResourceValue(forKey: URLResourceKey.fileSizeKey)
      try? FileManager.default.removeItem(at: job.outputFileURL)
      return await compress(job: job, isRetrying: true)
    }
    return pathError ?? error
  }

  private func catchProgress(job: Job, process: Process) {
    DispatchQueue.main.async { [weak self] in
      if job.isVideo || job.isGif {
        self?.currentProgress = 0
      }
    }
    let pipe = Pipe()
    if job.isVideo {
      process.standardError = pipe
    } else if job.isGif {
      process.standardOutput = pipe
    }
    Task {
      let duration: TimeInterval = (try? await getVideoDuration(from: job.inputFileURL)) ?? 0
      guard duration > 0 else { return }
      pipe.fileHandleForReading.readabilityHandler = { [weak self] (fileHandle) -> Void in
        let availableData = fileHandle.availableData
        var newProgress: Double?
        if let newOutput = String.init(data: availableData, encoding: .utf8) {
          let split = newOutput.split(separator: " ")
          if job.isVideo, let timeInfo = split.first(where: { $0.hasPrefix("time=") }), let time = String(timeInfo).toTimeInterval() {
            let adjustedDuration: Double = {
              if let start = job.outputType.startTime, let end = job.outputType.endTime {
                return min(end - start, duration)
              }
              return duration
            }()
            newProgress = Double(time / adjustedDuration)
          } else if job.isGif {
            let dotCount = newOutput.filter { $0 == "." }.count
            let hashCount = newOutput.filter { $0 == "#" }.count
            newProgress = Double(hashCount) / Double(hashCount + dotCount)
          }
        }
        if let progress = newProgress {
          DispatchQueue.main.async { [weak self] in
            self?.currentProgress = min(max(0, progress), 1)
            if job.isVideo, progress > 0.01 {
              job.status = "Compressing"
            } else if job.isGif, progress > 0.01 {
              job.status = "Converting"
            }
          }
        }
      }
    }
  }

  @discardableResult
  func compress() async -> [Job] {
    NoSleep.disableSleep()
    await MainActor.run {
      isRunning = true
      isTerminated = false
      if copyCompressedFilesToClipboard {
        NSPasteboard.general.clearContents()
      }
    }

    var i: Int = 0
    while let job = jobs[safe: i] {
      if isTerminated { break }
      let index = i

      let startDate = Date()
      await MainActor.run {
        currentJob = job
        currentIndex = index + 1
        if !job.isVideo {
          currentProgress = (Double(currentIndex ?? jobs.count)) / Double(jobs.count)
        }
      }
      let error = await compress(job: job)
      job.error = error
      job.totalTime = abs(startDate.timeIntervalSinceNow)
      if job.isImage && retainImageMetadata {
        try? JobManager.shared.copyEXIFData(job: job)
        try? JobManager.shared.copyIPTCData(job: job)
      }
      JobManager.shared.copyFileTagIfNeeded(job: job)
      JobManager.shared.removeFileIfNeeded(job: job)
      JobManager.shared.trackFinishJob(job)
      JobManager.shared.setFileCreationIfNeeded(job: job)

      i += 1
      if index >= jobs.count { break }
    }
    await MainActor.run {
      currentJob = nil
      isRunning = false
      currentIndex = nil
      let outputFileURLs = jobs.map { $0.outputFileURL }
      if copyCompressedFilesToClipboard, !outputFileURLs.isEmpty {
        NSPasteboard.general.writeObjects(outputFileURLs as [NSPasteboardWriting])
      }
      let successCount = jobs.map { FileManager.default.fileExists(atPath: $0.outputFileURL.path(percentEncoded: false)) ? 1 : 0 }.reduce(0,+)
      if confettiEnabled, successCount > 0, let url = URL(string: "raycast://confetti") {
        NSWorkspace.shared.open(url)
      }
    }

    NoSleep.enableSleep()
    return self.jobs
  }

  func terminate() {
    guard isRunning else { return }
    isTerminated = true
    if let process = currentProcess, process.isRunning {
      process.terminate()
      currentProcess = nil
    }
    if let job = currentJob {
      try? FileManager.default.removeItem(at: job.outputFileURL)
    }
    Task {
      await MainActor.run {
        if let index = jobs.firstIndex(where: { $0.id.uuidString == currentJob?.id.uuidString }) {
          jobs = Array(jobs[..<index])
        } else {
          jobs.removeAll()
        }
      }
    }
  }

  func queue(newJobs: [Job]) {
    jobs.append(contentsOf: newJobs)
  }
}
