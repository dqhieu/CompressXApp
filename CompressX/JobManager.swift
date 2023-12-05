//
//  JobManager.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 23/11/2023.
//

import Foundation
import SwiftUI
import AVFoundation
import TelemetryClient
import DockProgress
import SwiftDate

/*
video:
  - transparency:
    - webm: ffmpeg
    - non-webm: apple
  - no transparency: ffmpeg
image:
  - png: pngquant
  - jpg: ffmpeg
gif:
  - gifski
*/

struct CompressionHistory: Codable, Identifiable, Hashable {
  var id = UUID().uuidString
  var fileName: String
  var originalSize: String
  var compressedSize: String
  var reducedSize: String
  var timeTaken: String
  var reducePercentage: Double
}

class Job: Identifiable {

  var id = UUID()
  
  var outputType: OutputType
  var inputFileURL: URL
  let inputFileSize: Int64?
  var outputFileURL: URL
  let removeInputFile: Bool
  let inputFileCreationDate: Date?

  var error: String?
  var totalTime: TimeInterval = 0

  var outputFileSize: Int64? {
    return outputFileURL.fileSize
  }

  var status: String = ""

  var targetOutputURL: URL
  var originalOutputURL: URL

  var tmpInputFileURL: URL?

  init(
    inputFileURL: URL,
    outputType: OutputType,
    outputFolder: OutputFolder,
    customOutputFolder: String,
    outputFileNameFormat: String,
    removeInputFile: Bool
  ) {
    self.inputFileURL = inputFileURL
    self.inputFileSize = inputFileURL.fileSize
    self.outputType = outputType
    self.removeInputFile = removeInputFile
    self.inputFileCreationDate = try? getFileCreationDate(from: inputFileURL)
    let outputFolderURL: URL = {
      if outputFolder == .custom, !customOutputFolder.isEmpty {
        return URL(string: "file://" + customOutputFolder)!
      } else {
        return inputFileURL.deletingLastPathComponent()
      }
    }()
    let intputFileNameWithoutExtension = inputFileURL.deletingPathExtension().lastPathComponent
    let format = outputFileNameFormat
      .replacingOccurrences(of: "{timestamp}", with: "\(Int(Date.now.timeIntervalSince1970))")
      .replacingOccurrences(of: "{datetime}", with: Date().toISO8601DateTime)
      .replacingOccurrences(of: "{date}", with: Date().toISO8601Date)
      .replacingOccurrences(of: "{time}", with: Date().toISO8601Time)

    switch outputType {
    case .video(_, _, let videoFormat, _, _, _, _, _):
      if videoFormat != .same {
        outputFileURL = outputFolderURL.appendingPathComponent(intputFileNameWithoutExtension + format + "." + videoFormat.rawValue)
      } else {
        outputFileURL = outputFolderURL.appendingPathComponent(intputFileNameWithoutExtension + format + "." + inputFileURL.pathExtension)
      }
    case .image(_, let imageFormat, _):
      if isRawImage(url: inputFileURL), let url = preProcessRawImage(inputFileURL: inputFileURL) {
        self.tmpInputFileURL = inputFileURL
        self.inputFileURL = url
      }
      switch imageFormat {
      case .same:
        if isPNGFile(url: self.inputFileURL) {
          outputFileURL = outputFolderURL.appendingPathComponent(intputFileNameWithoutExtension + format + ".png")
        } else if isSVGFile(url: self.inputFileURL) {
          outputFileURL = outputFolderURL.appendingPathComponent(intputFileNameWithoutExtension + format + ".svg")
        } else if isTiffFile(url: self.inputFileURL) {
          outputFileURL = outputFolderURL.appendingPathComponent(intputFileNameWithoutExtension + format + ".tif")
        } else {
          outputFileURL = outputFolderURL.appendingPathComponent(intputFileNameWithoutExtension + format + ".jpg")
        }
      case .webp:
        outputFileURL = outputFolderURL.appendingPathComponent(intputFileNameWithoutExtension + format + ".webp")
      case .jpg:
        outputFileURL = outputFolderURL.appendingPathComponent(intputFileNameWithoutExtension + format + ".jpg")
      case .png:
        outputFileURL = outputFolderURL.appendingPathComponent(intputFileNameWithoutExtension + format + ".png")
      }
    case .gif, .gifCompress:
      outputFileURL = outputFolderURL.appendingPathComponent(intputFileNameWithoutExtension + format + ".gif")
    }

    targetOutputURL = outputFileURL
    var count = 1
    while FileManager.default.fileExists(atPath: outputFileURL.path(percentEncoded: false)) {
      let fileExtension = outputFileURL.pathExtension
      outputFileURL = outputFolderURL.appendingPathComponent(intputFileNameWithoutExtension + " \(count)." + fileExtension)
      count += 1
    }
    originalOutputURL = outputFileURL
    if !FileManager.default.fileExists(atPath: outputFolderURL.absoluteString, isDirectory: nil) {
      try? FileManager.default.createDirectory(at: outputFolderURL, withIntermediateDirectories: true)
    }
  }

  var isVideo: Bool {
    switch outputType {
    case .video:
      return true
    default:
      return false
    }
  }

  var isGif: Bool {
    switch outputType {
    case .gif, .gifCompress:
      return true
    default:
      return false
    }
  }

  var isImage: Bool {
    switch outputType {
    case .image:
      return true
    default:
      return false
    }
  }

  var isMKV: Bool {
    return inputFileURL.pathExtension.lowercased() == "mkv" 
  }

  var isWebP: Bool {
    return inputFileURL.pathExtension.lowercased() == "webp"
  }
}

enum OutputType {
  case video(
    videoQuality: VideoQuality,
    videoDimension: VideoDimension,
    videoFormat: VideoFormat,
    hasAudio: Bool,
    removeAudio: Bool,
    preserveTransparency: Bool,
    startTime: CMTime?,
    endTime: CMTime?
  )
  case image(imageQuality: ImageQuality, imageFormat: ImageFormat, imageDimension: ImageDimension)
  case gif(gifQuality: VideoQuality, fpsValue: Int, dimension: GifDimension)
  case gifCompress(gifQuality: VideoQuality, dimension: GifDimension)

  var startTime: Double? {
    switch self {
    case .video(_, _, _, _, _, _, let startTime, _):
      return startTime?.seconds
    default: return nil
    }
  }

  var endTime: Double? {
    switch self {
    case .video(_, _, _, _, _, _, _, let endTime):
      return endTime?.seconds
    default: return nil
    }
  }
}

class JobManager: ObservableObject {
  
  @AppStorage("ffmpegPath") var ffmpegPath = ""
  @AppStorage("pngquantPath") var pngquantPath = "/opt/homebrew/bin/pngquan"
  @AppStorage("gifskiPath") var gifskiPath = "/opt/homebrew/bin/gifsk"
  @AppStorage("customOutputFolder") var customOutputFolder = ""
  @AppStorage("outputFolder") var outputFolder: OutputFolder = .same
  @AppStorage("videoCompressed") var videoCompressed: Int = 0
  @AppStorage("imageCompressed") var imageCompressed: Int = 0
  @AppStorage("gifConverted") var gifConverted: Int = 0
  @AppStorage("gifCompressed") var gifCompressed: Int = 0
  @AppStorage("sizeReduced") var sizeReduced = 0
  @AppStorage("outputFileNameFormat") var outputFileNameFormat = ""
  @AppStorage("hardwareAccelerationEnabled") var hardwareAccelerationEnabled = false
  @AppStorage("compressionHistories") var compressionHistories: [CompressionHistory] = []
  @AppStorage("shouldSaveCompressionHistory") var shouldSaveCompressionHistory = true
  @AppStorage("retainCreationDate") var retainCreationDate = false
  @AppStorage("encodingCodec") var encodingCodec: Codec = .libx264
  @AppStorage("targetVideoFPS") var targetVideoFPS = TargetVideoFPS.same
  @AppStorage("retainImageMetadata") var retainImageMetadata = false
  @AppStorage("copyOutputFilesToClipboard") var copyCompressedFilesToClipboard = false
  @AppStorage("confettiEnabled") var confettiEnabled = false

  @Published var isRunning = false
  @Published var inputFileURLs: [URL] = []
  @Published var jobs: [Job] = []
  @Published var currentIndex: Int?
  @Published var currentJob: Job?

  var currentIndexProgress: Int? {
    guard let index = currentIndex else { return nil }
    return Int(100 * Double(index - 1) / Double(jobs.count))
  }

  static let shared = JobManager()
  
  private var currentExportSession: AVAssetExportSession?
  private var currentProcess: Process?
  private var isTerminated = false
  @Published var currentProgress: Double = 0

  func createTask(job: Job) async -> (Process, String?) {
    let task = Process()
    var arguments: [String] = []
    var error: String?
    switch job.outputType {
    case .video(let videoQuality, let videoDimension, let videoFormat, let hasAudio, let removeAudio, _, let startTime, let endTime):
      if hardwareAccelerationEnabled {
        arguments.append(contentsOf: [
          "-hwaccel",
          "auto"
        ])
      }
      arguments.append(contentsOf: [
        "-y",
        "-i",
        job.inputFileURL.path(percentEncoded: false)
      ])
      let videoSize = try? await getVideoSize(from: job.inputFileURL)
      if let videoSize, let additionalParams = getFFmpegParam(videoSize: videoSize, expectedDimension: videoDimension) {
        arguments.append(contentsOf: additionalParams)
      }
      if let start = startTime, let end = endTime {
        if removeAudio || !hasAudio {
          arguments.append(contentsOf: [
            "-vf",
            "trim=start=\(start.seconds):end=\(end.seconds),setpts=PTS-STARTPTS"
          ])
        } else {
          let numberOfAudioTrack = (try? await numberOfAudioTracks(url: job.inputFileURL)) ?? 1
          if numberOfAudioTrack > 1 {
            var filterValue = "[0:v]trim=start=\(start.seconds):end=\(end.seconds),setpts=PTS-STARTPTS[v]"
            for i in 0..<numberOfAudioTrack {
              filterValue += ";[0:a\(i)]atrim=start=\(start.seconds):end=\(end.seconds),asetpts=PTS-STARTPTS[a\(i)]"
            }
            arguments.append(contentsOf: [
              "-filter_complex",
              filterValue,
              "-map",
              "[v]",
            ])
            for i in 0..<numberOfAudioTrack {
              arguments.append(contentsOf: [
                "-map",
                "[a\(i)]",
              ])
            }
//            arguments.append(contentsOf: [
//              "-filter_complex",
//              "[0:v]trim=start=\(start.seconds):end=\(end.seconds),setpts=PTS-STARTPTS[v];[0:a]atrim=start=\(start.seconds):end=\(end.seconds),asetpts=PTS-STARTPTS[a]",
//              "-map",
//              "[v]",
//              "-map",
//              "[a]",
//            ])
          } else {
            arguments.append(contentsOf: [
              "-filter_complex",
              "[0:v]trim=start=\(start.seconds):end=\(end.seconds),setpts=PTS-STARTPTS[v];[0:a]atrim=start=\(start.seconds):end=\(end.seconds),asetpts=PTS-STARTPTS[a]",
              "-map",
              "[v]",
              "-map",
              "[a]",
            ])
          }
        }
      }
      let shouldUseWebMFormat: Bool = job.inputFileURL.pathExtension.uppercased() == VideoFormat.webm.rawValue.uppercased() || videoFormat == .webm
      if shouldUseWebMFormat {
        arguments.append(contentsOf: [
          "-c:v",
          "libvpx-vp9",
          "-b:v",
          "0",
          "-crf",
          videoQuality.crf,
          "-c:a",
          "copy"
        ])
      } else {
        if targetVideoFPS != .same, let inputFPS = try? await getFPS(from: job.inputFileURL), targetVideoFPS.value < inputFPS {
          arguments.append(contentsOf: [
            "-r",
            targetVideoFPS.displayText
          ])
        }
        arguments.append(contentsOf: [
          "-c:v",
          encodingCodec.rawValue,
          "-crf",
          videoQuality.crf
        ])
        if removeAudio {
          arguments.append("-an")
        } else if startTime != nil && endTime != nil {

        } else {
          arguments.append(contentsOf: [
            "-c:a",
            "copy",
            "-map",
            "0"
          ])
        }
        switch encodingCodec {
        case .libx264:
          arguments.append(contentsOf: [
            "-pix_fmt",
            "yuv420p"
          ])
        case .libx265:
          arguments.append(contentsOf: [
            "-tag:v",
            "hvc1"
          ])
        }
      }
      arguments.append(job.outputFileURL.path(percentEncoded: false))
      print("😂", arguments.joined(separator: " "))
      task.launchPath = ffmpegPath
      if !isValidFFmpegPath(ffmpegPath) {
        error = "FFmpeg setting is not correct"
      }
    case .image(let imageQuality, let imageFormat, let imageDimension):
      let isPngInput = isPNGFile(url: job.inputFileURL)
      let isPngOutput = imageFormat == .same || imageFormat == .png
      if isPngInput && isPngOutput {
        arguments.append(contentsOf: [
          job.inputFileURL.path(percentEncoded: false),
          "--quality",
          imageQuality.pngImageQualityLevel,
          "--force",
          "-o",
          job.outputFileURL.path(percentEncoded: false)
        ])
        task.launchPath = pngquantPath
        if !isValidPngquantPath(pngquantPath) {
          error = "pngquant setting is incorrect"
        }
        // pngquant /Users/hieudinh/Desktop/ap.png --quality 40-60 -o /Users/hieudinh/Desktop/test.png
        // ffmpeg -i /Users/hieudinh/Desktop/iPhone_original.jpg -q:v 12 /Users/hieudinh/Desktop/iPhone_original 1.jpg
      } 
      else if imageFormat == .png {
        arguments.append(contentsOf: [
          "-y",
          "-i",
          job.inputFileURL.path(percentEncoded: false)
        ])
        if let imageRep = NSImageRep(contentsOf: job.inputFileURL), let additionalParams = getFFmpegParam(imageSize: CGSize(width: imageRep.pixelsWide, height: imageRep.pixelsHigh), dimension: imageDimension) {
          arguments.append(contentsOf: additionalParams)
        }
        arguments.append(contentsOf: [
          "-compression_level",
          imageQuality.pngFFmpegQualityLevel,
          job.outputFileURL.path(percentEncoded: false)
        ])
        task.launchPath = ffmpegPath
        if !isValidFFmpegPath(ffmpegPath) {
          error = "FFmpeg setting is incorrect"
        }
      } 
      else {
        arguments.append(contentsOf: [
          "-y",
          "-i",
          job.inputFileURL.path(percentEncoded: false)
        ])
        if let imageRep = NSImageRep(contentsOf: job.inputFileURL), let additionalParams = getFFmpegParam(imageSize: CGSize(width: imageRep.pixelsWide, height: imageRep.pixelsHigh), dimension: imageDimension) {
          arguments.append(contentsOf: additionalParams)
        }
        arguments.append(contentsOf: [
          "-q:v",
          imageQuality.jpgImageQualityLevel,
          job.outputFileURL.path(percentEncoded: false)
        ])
        task.launchPath = ffmpegPath
        if !isValidFFmpegPath(ffmpegPath) {
          error = "FFmpeg setting is incorrect"
        }
      }
    case .gif(let gifQuality, let fpsValue, let dimension):
      if let videoSize = try? await getVideoSize(from: job.inputFileURL) {
        let width = String(Int(videoSize.width * dimension.fraction))
        arguments.append(contentsOf: [
          "--width",
          width
        ])
      }
      var targetFps: Int = fpsValue
      let videoFps = try? await getFPS(from: job.inputFileURL)
      if let fps = videoFps, targetFps > Int(fps) {
        targetFps = Int(fps)
      }
      arguments.append(contentsOf: [
        "--fps",
        "\(targetFps)",
        "--quality",
        gifQuality.gifQualityLevel,
        "-o",
        job.outputFileURL.path(percentEncoded: false),
        job.inputFileURL.path(percentEncoded: false)
      ])
      task.launchPath = gifskiPath
      if !isValidGifskiPath(gifskiPath) {
        error = "gifski setting is incorrect"
      }
    case .gifCompress(let gifQuality, let dimension):
      if let imageRep = NSImageRep(contentsOf: job.inputFileURL) {
        let width = String(Int(Double(imageRep.pixelsWide) * dimension.fraction))
        arguments.append(contentsOf: [
          "--width",
          width
        ])
      }
      let videoFps = (try? await getFPS(from: job.inputFileURL)) ?? 20
      let targetFps = Int(videoFps)
      arguments.append(contentsOf: [
        "--fps",
        "\(targetFps)",
        "--quality",
        gifQuality.gifQualityLevel,
        "-o",
        job.outputFileURL.path(percentEncoded: false),
        job.inputFileURL.path(percentEncoded: false)
      ])
      task.launchPath = gifskiPath
      if !isValidGifskiPath(gifskiPath) {
        error = "gifski setting is incorrect"
      }
    }
    task.arguments = arguments
    return (task, error)
  }
  
  private func transcodeVideo(sourceFileURL: URL, outputFileURL: URL, videoQuality: VideoQuality, startTime: CMTime?, endTime: CMTime?) async -> String? {
    let avAsset = AVURLAsset(url: sourceFileURL)
    guard let exportSession = AVAssetExportSession(asset: avAsset, presetName: videoQuality.avAssetExportPresetName) else {
      return "Unable to create AVAssetExportSession"
    }
    exportSession.outputURL = outputFileURL
    exportSession.outputFileType = .mp4
    exportSession.shouldOptimizeForNetworkUse = true

    await exportSession.export()
    return exportSession.error?.localizedDescription
  }

  func compress(job: Job, isRetrying: Bool = false) async -> String? {
    if case .video(let videoQuality, _, let videoFormat, _, _, let preserveTransparency, let startTime, let endTime) = job.outputType, preserveTransparency && videoFormat != .webm {
      return await transcodeVideo(sourceFileURL: job.inputFileURL, outputFileURL: job.outputFileURL, videoQuality: videoQuality, startTime: startTime, endTime: endTime)
    }
//    if isPdfFile(url: job.inputFileURL) {
//      return PDFCompressor().compress(job.inputFileURL, out: job.outputFileURL)
//    }
    guard isFileSupported(url: job.inputFileURL) else {
      return "File format is not supported"
    }
    guard FileManager.default.fileExists(atPath: job.inputFileURL.path(percentEncoded: false)) else {
      return "Input file does not exist"
    }
    if case .image(let imageQuality, let imageFormat, let imageDimension) = job.outputType, (imageFormat == .webp || imageFormat == .same && job.isWebP) {
      return WebPCoder.shared.convert(
        inputURL: job.inputFileURL,
        outputURL: job.outputFileURL,
        imageQuality: imageQuality,
        imageDimension: imageDimension
      )
    }
    if case .image(let imageQuality, let imageFormat, let imageDimension) = job.outputType, isSVGFile(url: job.inputFileURL) {
      return SVGProcessor.convert(job: job, imageQuality: imageQuality, imageFormat: imageFormat, imageDimension: imageDimension)
    }
    if case .image(let imageQuality, let imageFormat, let imageDimension) = job.outputType, isSVGFile(url: job.inputFileURL), isTiffFile(url: job.inputFileURL), imageFormat == .same {
      return TIFFProcessor.compress(job: job, imageQuality: imageQuality, imageFormat: imageFormat, imageDimension: imageDimension)
    }
    let (process, pathError) = await createTask(job: job)
    currentProcess = process
    if !job.isMKV {
      // TODO: if input file is MKV, then process doesn't emit any output 
      catchProgress(job: job, process: process)
    }
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
    if error == nil {
      switch job.outputType {
      case .video(let videoQuality, let videoDimension, let videoFormat, let hasAudio, let removeAudio, let preserveTransparency, let startTime, let endTime):
        if FileManager.default.fileExists(atPath: job.outputFileURL.path(percentEncoded: false)),
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
      case .gifCompress(let gifQuality, let dimension):
        if FileManager.default.fileExists(atPath: job.outputFileURL.path(percentEncoded: false)),
           (job.outputFileSize ?? 0) >= (job.inputFileSize ?? 0),
           let nextQuality = gifQuality.next {
          let newOutputType = OutputType.gifCompress(
            gifQuality: nextQuality,
            dimension: dimension
          )
          job.outputType = newOutputType
          job.outputFileURL.removeCachedResourceValue(forKey: URLResourceKey.fileSizeKey)
          try? FileManager.default.removeItem(at: job.outputFileURL)
          return await compress(job: job, isRetrying: true)
        }
      default:
        break
      }
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
            } else if progress >= 1 {
              job.status = "Finalizing"
            }
            DockProgress.progress = min(max(0, progress), 1)
          }
        }
      }
    }
  }

  func compress() async -> [Job] {
    NoSleep.disableSleep()
    await MainActor.run {
      isRunning = true
      isTerminated = false
      DockProgress.resetProgress()
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
        if jobs.count == 1 {
          DockProgress.style = .pie(color: .systemBlue)
        } else {
          DockProgress.style = .badge(color: .systemBlue, badgeValue: { [jobs] in
            jobs.count - index
          })
        }
        if !job.isVideo {
          DockProgress.progress = (Double(index) + 0.01) / Double(jobs.count)
        }
        currentIndex = index + 1
      }
      let error = await compress(job: job)
      job.error = error
      job.totalTime = abs(startDate.timeIntervalSinceNow)
      if job.isImage && retainImageMetadata {
        try? copyEXIFData(job: job)
        try? copyIPTCData(job: job)
      }
      copyFileTagIfNeeded(job: job)
      removeFileIfNeeded(job: job)
      trackFinishJob(job)
      setFileCreationIfNeeded(job: job)

      i += 1

      if index >= jobs.count { break }
    }
    await MainActor.run {
      currentJob = nil
      isRunning = false
      currentIndex = nil
      DockProgress.progressInstance = nil
      let outputFileURLs = jobs.map { $0.inputFileURL }
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
    } else if let session = currentExportSession, session.status == .exporting || session.status == .waiting {
      session.cancelExport()
      currentExportSession = nil
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

  func copyFileTagIfNeeded(job: Job) {
    if let tagNames = try? job.inputFileURL.resourceValues(forKeys: [.tagNamesKey]) {
      try? job.outputFileURL.setResourceValues(tagNames)
    }
  }

  func removeFileIfNeeded(job: Job) {
    if let tmpInputFileURL = job.tmpInputFileURL {
      try? FileManager.default.trashItem(at: job.inputFileURL, resultingItemURL: nil)
      job.inputFileURL = tmpInputFileURL
    }
    guard job.removeInputFile, let outputFileSize = job.outputFileSize, outputFileSize > 0, job.error == nil else {
      return
    }
    do {
      try FileManager.default.trashItem(at: job.inputFileURL, resultingItemURL: nil)
      if job.targetOutputURL.absoluteString != job.outputFileURL.absoluteString,
          !FileManager.default.fileExists(atPath: job.targetOutputURL.path(percentEncoded: false)) {
        try FileManager.default.moveItem(at: job.outputFileURL, to: job.targetOutputURL)
        job.outputFileURL = job.targetOutputURL
      }
    } catch {
    }
  }

  func setFileCreationIfNeeded(job: Job) {
    if retainCreationDate,
       let creationDate = job.inputFileCreationDate,
       var attributes = try? FileManager.default.attributesOfItem(atPath: job.outputFileURL.path(percentEncoded: false)) {
      attributes[.creationDate] = creationDate
      do {
        try FileManager.default.setAttributes(
          attributes,
          ofItemAtPath: job.outputFileURL.path(percentEncoded: false)
        )
      } catch {
      }
    }
  }

  func copyEXIFData(job: Job) throws {
    let sourceURL = job.inputFileURL
    let destinationURL = job.outputFileURL
    guard let sourceImage = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
          let destinationImage = CGImageSourceCreateWithURL(destinationURL as CFURL, nil) else {
      throw NSError(domain: "com.example.EXIFCopy", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to create image sources."])
    }

    let metadata = CGImageSourceCopyPropertiesAtIndex(sourceImage, 0, nil) as NSDictionary?

    guard let type = CGImageSourceGetType(destinationImage),
          let destinationImageDestination = CGImageDestinationCreateWithURL(destinationURL as CFURL, type, 1, nil) else {
      throw NSError(domain: "com.example.EXIFCopy", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to create image destination."])
    }

    CGImageDestinationAddImageFromSource(destinationImageDestination, sourceImage, 0, metadata)
    if !CGImageDestinationFinalize(destinationImageDestination) {
      throw NSError(domain: "com.example.EXIFCopy", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to finalize the image destination."])
    }
  }

  func copyIPTCData(job: Job) throws {
    let sourceURL = job.inputFileURL
    let destinationURL = job.outputFileURL
    guard let sourceImageSource = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
          let destinationImageSource = CGImageSourceCreateWithURL(destinationURL as CFURL, nil) else {
      throw NSError(domain: "com.example.IPTCCopy", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to create image sources"])
    }

    guard let sourceProperties = CGImageSourceCopyPropertiesAtIndex(sourceImageSource, 0, nil) as? [CFString: Any],
          var destinationProperties = CGImageSourceCopyPropertiesAtIndex(destinationImageSource, 0, nil) as? [CFString: Any] else {
      throw NSError(domain: "com.example.IPTCCopy", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to get image properties"])
    }

    if let sourceIPTCData = sourceProperties[kCGImagePropertyIPTCDictionary] as? [CFString: Any] {
      destinationProperties[kCGImagePropertyIPTCDictionary] = sourceIPTCData
    }

    guard let type = CGImageSourceGetType(destinationImageSource),
          let destinationImageDestination = CGImageDestinationCreateWithURL(destinationURL as CFURL, type, 1, nil) else {
      throw NSError(domain: "com.example.IPTCCopy", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unable to create image destination"])
    }

    CGImageDestinationAddImageFromSource(destinationImageDestination, destinationImageSource, 0, destinationProperties as CFDictionary)
    if !CGImageDestinationFinalize(destinationImageDestination) {
      throw NSError(domain: "com.example.IPTCCopy", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to finalize the image destination"])
    }
  }

  func queue(newJobs: [Job]) {
    for job in newJobs {
      if !jobs.contains(where: { $0.inputFileURL == job.inputFileURL }) {
        jobs.append(job)
      }
    }
    inputFileURLs = jobs.map { $0.inputFileURL }
  }

  func createJobs(
    inputFileURLs: [URL],
    removeInputFile: Bool,
    imageQuality: ImageQuality,
    imageFormat: ImageFormat,
    imageDimension: ImageDimension,
    videoQuality: VideoQuality,
    videoDimension: VideoDimension,
    videoGifQuality: VideoQuality,
    videoGifDimension: GifDimension,
    gifQuality: VideoQuality,
    gifDimension: GifDimension,
    videoFormat: VideoFormat,
    hasAudio: Bool,
    removeAudio: Bool,
    fpsValue: Int,
    preserveTransparency: Bool,
    startTimes: [URL: CMTime],
    endTimes: [URL: CMTime]
  ) -> [Job] {
    let newJobs = inputFileURLs.map { url in

      let outputType: OutputType = {
        let fileType = checkFileType(url: url)
        switch fileType {
        case .image(let imageType):
          switch imageType {
          case .jpg:
            return .image(imageQuality: imageQuality, imageFormat: imageFormat, imageDimension: imageDimension)
          case .png:
            return .image(imageQuality: imageQuality, imageFormat: imageFormat, imageDimension: imageDimension)
          }
        case .video:
          if videoFormat == .gif {
            return .gif(
              gifQuality: videoGifQuality,
              fpsValue: fpsValue,
              dimension: videoGifDimension
            )
          } else {
            return .video(
              videoQuality: videoQuality,
              videoDimension: videoDimension,
              videoFormat: videoFormat,
              hasAudio: hasAudio,
              removeAudio: removeAudio,
              preserveTransparency: preserveTransparency,
              startTime: startTimes[url],
              endTime: endTimes[url]
            )
          }
        case .gif:
          return .gifCompress(
            gifQuality: gifQuality,
            dimension: gifDimension
          )
        case .notSupported:
          fatalError()
        }
      }()
      return Job(
        inputFileURL: url,
        outputType: outputType,
        outputFolder: outputFolder,
        customOutputFolder: customOutputFolder,
        outputFileNameFormat: outputFileNameFormat,
        removeInputFile: removeInputFile
      )
    }
    return newJobs
  }

  func trackFinishJob(_ job: Job) {
    if let error = job.error {
      TelemetryDeck.signal("compress.error", parameters: [
        "error": String(describing: error),
        "inputFileSize": String(job.inputFileSize ?? 0),
        "inputFileSizeString": fileSizeString(from: job.inputFileSize),
        "inputFileFormat": job.inputFileURL.pathExtension,
      ])
    } else if let outputFileSize = job.outputFileSize, outputFileSize > 0 {
      let fileSizeReduced = (job.inputFileSize ?? 0) - outputFileSize
      let trackingData: [String: String] = [
        "inputFileSize": String(job.inputFileSize ?? 0),
        "inputFileSizeString": fileSizeString(from: job.inputFileSize),
        "inputFileFormat": job.inputFileURL.pathExtension,
        "outputFileSize": String(outputFileSize),
        "outputFileSizeString": fileSizeString(from: outputFileSize),
        "outputFileFormat": job.outputFileURL.pathExtension,
        "reducedSize": String((job.inputFileSize ?? 0) - outputFileSize),
        "reducedSizeString": fileSizeString(from: fileSizeReduced),
        "totalTime": String(job.totalTime),
        "hardwareAccelerationEnabled": String(hardwareAccelerationEnabled)
      ]
      let inputSize = Double(job.inputFileSize ?? 1)
      let history = CompressionHistory(
        fileName: job.outputFileURL.path(percentEncoded: false),
        originalSize: fileSizeString(from: job.inputFileSize),
        compressedSize: fileSizeString(from: outputFileSize),
        reducedSize: fileSizeString(from: fileSizeReduced),
        timeTaken: Int(ceil(job.totalTime)).seconds.timeInterval.toString {
          $0.unitsStyle = .full
          $0.collapsesLargestUnit = false
          $0.allowsFractionalUnits = true
        },
        reducePercentage: Double(fileSizeReduced) / inputSize
      )
      Task {
        await MainActor.run {
          if fileSizeReduced > 0 {
            sizeReduced += Int(fileSizeReduced)
          }
          switch job.outputType {
          case .video:
            videoCompressed += 1
            TelemetryDeck.signal("compress.finish", parameters: trackingData)
            if shouldSaveCompressionHistory {
              compressionHistories.append(history)
            }
          case .image:
            imageCompressed += 1
            TelemetryDeck.signal("compress.finish", parameters: trackingData)
            if shouldSaveCompressionHistory {
              compressionHistories.append(history)
            }
          case .gifCompress:
            gifCompressed += 1
            TelemetryDeck.signal("compress.finish", parameters: trackingData)
            if shouldSaveCompressionHistory {
              compressionHistories.append(history)
            }
          case .gif:
            gifConverted += 1
            TelemetryDeck.signal("convert.finish.gif", parameters: trackingData)
          }
        }
      }
    }
  }
}

class CommandlineHelper {
  static func run(process: Process) async -> String? {

    let commandLineTask = Task(priority: .utility) { () -> String? in
      do {
        try process.run()
        process.waitUntilExit()
        return nil
      } catch {
        return error.localizedDescription
      }
    }
    return await commandLineTask.value
  }

}

extension Collection {
  subscript (safe index: Index) -> Element? {
    return indices.contains(index) ? self[index] : nil
  }
}

