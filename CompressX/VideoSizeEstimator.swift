//
//  VideoSizeEstimator.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 12/02/2024.
//

import Foundation
import SwiftUI

//class VideoSizeEstimator: ObservableObject {
//
//  enum Status: Equatable {
//    case idle
//    case starting
//    case finished(String?)
//    case error(String)
//  }
//
//  @AppStorage("ffmpegPath") var ffmpegPath = ""
//  @AppStorage("hardwareAccelerationEnabled") var hardwareAccelerationEnabled = false
//  @AppStorage("shouldEstiamteCompressedVideoSize") var shouldEstiamteCompressedVideoSize = false
//  @AppStorage("encodingCodec") var encodingCodec: Codec = .libx264
//
//  @Published var status: Status = .idle
//
//  private var currentTask: Process?
//
//  static let shared = VideoSizeEstimator()
//
//  func estimate(
//    inputFileURL: URL,
//    videoQuality: VideoQuality,
//    duration: Double,
//    shouldUseWebMFormat: Bool
//  ) async {
//    cancel()
//    guard shouldEstiamteCompressedVideoSize, let inputFileSize = inputFileURL.fileSize else { return }
//    setStatus(status: .starting)
//    let tmpOutputFilePath = FileManager.default.temporaryDirectory.appendingPathComponent("tmp.mp4")
//    var arguments: [String] = []
//    if hardwareAccelerationEnabled {
//      arguments.append(contentsOf: [
//        "-hwaccel",
//        "auto"
//      ])
//    }
//    arguments.append(contentsOf: [
//      "-y",
//      "-i",
//      inputFileURL.path(percentEncoded: false),
//    ])
//    if shouldUseWebMFormat {
//      arguments.append(contentsOf: [
//        "-c:v",
//        "libvpx-vp9",
//        "-b:v",
//        "0",
//      ])
//    } else {
//      arguments.append(contentsOf: [
//        "-c:v",
//        encodingCodec.rawValue,
//      ])
//    }
//    var multiplyFactor: Double
//    if inputFileSize <= 100_000_000 {
//      arguments.append(contentsOf: [
//        "-crf",
//        videoQuality.crf,
//        tmpOutputFilePath.path(percentEncoded: false)
//      ])
//      multiplyFactor = 1
//    } else if inputFileSize <= 200_000_000 {
//      multiplyFactor = 2
//      arguments.append(contentsOf: [
//        "-ss",
//        "00:00:00",
//        "-to",
//        formatTimeInterval(duration / 2),
//        "-crf",
//        videoQuality.crf,
//        tmpOutputFilePath.path(percentEncoded: false)
//      ])
//    } else {
//      if duration < 10 {
//        multiplyFactor = 1
//      } else {
//        multiplyFactor = duration / 10
//      }
//      arguments.append(contentsOf: [
//        "-ss",
//        "00:00:00",
//        "-to",
//        formatTimeInterval(Double(min(Int(duration), 10))),
//        "-crf",
//        videoQuality.crf,
//        tmpOutputFilePath.path(percentEncoded: false)
//      ])
//    }
//    let task = Process()
//    task.launchPath = ffmpegPath
//    task.arguments = arguments
//    currentTask = task
//    let error = await CommandlineHelper.run(process: task)
//    if let error = error {
//      setStatus(status: .error(error))
//      return
//    }
//    if task.terminationStatus == 255 {
//      return
//    }
//    if FileManager.default.fileExists(atPath: tmpOutputFilePath.path(percentEncoded: false)),
//       let outputFileSize = tmpOutputFilePath.fileSize {
//      let adjustedOutputFileSize = Int64(Double(outputFileSize) * multiplyFactor)
//      if adjustedOutputFileSize > inputFileSize, let nextQuality = videoQuality.next {
//        await estimate(
//          inputFileURL: inputFileURL,
//          videoQuality: nextQuality,
//          duration: duration,
//          shouldUseWebMFormat: shouldUseWebMFormat
//        )
//      } else {
//        let estimatedSize = fileSizeString(from: adjustedOutputFileSize)
//        setStatus(status: .finished(estimatedSize))
//        try? FileManager.default.removeItem(at: tmpOutputFilePath)
//      }
//    } else {
//      setStatus(status: .finished(nil))
//    }
//  }
//
//  func setStatus(status: Status) {
//    DispatchQueue.main.async { [weak self] in
//      self?.status = status
//    }
//  }
//
//  func cancel() {
//    if let task = currentTask, task.isRunning {
//      task.terminate()
//      currentTask = nil
//    }
//    setStatus(status: .idle)
//  }
//}
