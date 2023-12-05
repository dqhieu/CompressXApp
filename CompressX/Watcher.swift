//
//  Watcher.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 06/02/2024.
//

import Foundation
import AppKit
import SwiftUI
import Combine

class Watcher {

  @AppStorage("outputFileNameFormat") var outputFileNameFormat = ""
  @AppStorage("watchSettings") var watchSettings: [WatchSetting] = []
  @AppStorage("notchStyle") var notchStyle: NotchStyle = .expanded

  var folderWatchers: [FolderMonitor] = []

  var jobQueue: [Job] = []
  let jobQueuePublisher = PassthroughSubject<[Job], Never>()
  var cancellables = Set<AnyCancellable>()

  static let shared = Watcher()

  func setup() {
    start(settings: watchSettings)
  }

  func start(settings: [WatchSetting]) {
    stop()

    for setting in settings {
      let watcher = FolderMonitor(folderURL: URL(fileURLWithPath: setting.folder, isDirectory: true))
      watcher.startMonitoring { [weak self] path in
        guard let this = self else { return }
        let currentOutputFiles: [String] =
        JobManager.shared.jobs.map({ $0.outputFileURL.path(percentEncoded: false)})
        + JobManager.shared.jobs.map({ $0.originalOutputURL.path(percentEncoded: false)})
        + JobManager.shared.jobs.map({ $0.targetOutputURL.path(percentEncoded: false)})
        + HUDJobManager.shared.jobs.map({ $0.outputFileURL.path(percentEncoded: false)})
        + HUDJobManager.shared.jobs.map({ $0.originalOutputURL.path(percentEncoded: false)})
        + HUDJobManager.shared.jobs.map({ $0.targetOutputURL.path(percentEncoded: false)})
        if !currentOutputFiles.contains(where: { $0 == path }),
           let updatedSetting = this.watchSettings.first(where: { $0.id == setting.id }) {
          let inputFileURL = URL(fileURLWithPath: path)
          let fileType = checkFileType(url: inputFileURL)
          switch updatedSetting.fileType {
          case .image:
            if !fileType.isImage { return }
          case .video:
            if fileType != .video { return }
          case .all:
            if !fileType.isImage && fileType != .video { return }
          }
          let outputType: OutputType? = {
            switch fileType {
            case .image:
              return .image(
                imageQuality: updatedSetting.imageQuality,
                imageFormat: updatedSetting.imageFormat ?? .same,
                imageDimension: updatedSetting.imageDimension ?? .same
              )
            case .video:
              return .video(
                videoQuality: updatedSetting.videoQuality,
                videoDimension: updatedSetting.videoDimension ?? .same,
                videoFormat: updatedSetting.videoFormat,
                hasAudio: true,
                removeAudio: updatedSetting.removeAudio,
                preserveTransparency: false,
                startTime: nil,
                endTime: nil
              )
            default:
              return nil
            }
          }()
          guard let outputType = outputType else { return }
          let outputFormat: String = {
            if let format = updatedSetting.outputFileNameFormat, !format.isEmpty {
              return format
            }
            return this.outputFileNameFormat
          }()

          let job = Job(
            inputFileURL: inputFileURL,
            outputType: outputType,
            outputFolder: updatedSetting.outputFolder,
            customOutputFolder: updatedSetting.customOutputFolder,
            outputFileNameFormat: outputFormat,
            removeInputFile: updatedSetting.removeFileAfterCompression ?? false
          )

          this.addJobs([job])
        }
      }
      folderWatchers.append(watcher)
    }

    let debouncedStream = jobQueuePublisher
      .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
      .eraseToAnyPublisher()

    debouncedStream
      .sink { jobs in
        guard jobs.count > 0 else { return }
        DispatchQueue.main.async { [weak self] in
          self?.jobQueue.removeAll()
          if HUDJobManager.shared.isRunning {
            HUDJobManager.shared.queue(newJobs: jobs)
          } else {
            HUDJobManager.shared.jobs = jobs
            Task {
              await HUDJobManager.shared.compress()
            }
            let outputFolder = jobs.first?.outputFileURL.deletingLastPathComponent().path(percentEncoded: false) ?? ""
            if let style = self?.notchStyle, style != NotchStyle.none {
              NotchKit.shared.show(folderPath: outputFolder, notchStyle: style)
            }
          }
        }
      }
      .store(in: &cancellables)
  }

  func addJobs(_ jobs: [Job]) {
    jobQueue.append(contentsOf: jobs)
    jobQueuePublisher.send(jobQueue)
  }

  func stop() {
    for watcher in folderWatchers {
      watcher.stopMonitoring()
    }
    folderWatchers.removeAll()
    cancellables.removeAll()
  }
}

class FolderMonitor {
  private var monitoredFolderURL: URL
  private var folderMonitorQueue: DispatchQueue
  private var folderMonitorSource: DispatchSourceFileSystemObject?
  private var lastFileList: [String] = []

  init(folderURL: URL) {
    self.monitoredFolderURL = folderURL
    self.folderMonitorQueue = DispatchQueue(label: "FolderMonitorQueue", attributes: .concurrent)
    updateLastFileList()
  }

  private func updateLastFileList() {
    do {
      let fileList = try FileManager.default.contentsOfDirectory(atPath: monitoredFolderURL.path)
      self.lastFileList = fileList
    } catch {
      print("Failed to fetch file list: \(error)")
    }
  }

  func startMonitoring(completion: @escaping (String) -> Void) {
    let fileDescriptor = open(monitoredFolderURL.path, O_EVTONLY)
    guard fileDescriptor != -1 else {
      print("Unable to open file descriptor.")
      return
    }

    folderMonitorSource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDescriptor, eventMask: .write, queue: folderMonitorQueue)

    folderMonitorSource?.setEventHandler { [weak self] in
      guard let this = self else { return }
      do {
        let currentFileList = try FileManager.default.contentsOfDirectory(atPath: this.monitoredFolderURL.path)
        if !this.shouldNotifyNewFiles(currentFiles: currentFileList, oldFiles: this.lastFileList) {
          this.lastFileList = currentFileList // Update the last known file list
          return
        }
        let newFiles = currentFileList.filter { !this.lastFileList.contains($0) }

        this.lastFileList = currentFileList // Update the last known file list

        // Notify for each new file found
        newFiles.forEach { newFile in
          let fullPath = this.monitoredFolderURL.appendingPathComponent(newFile).path
          completion(fullPath)
        }
      } catch {
        print("Error listing directory contents: \(error)")
      }
    }

    folderMonitorSource?.setCancelHandler {
      close(fileDescriptor)
    }

    folderMonitorSource?.resume()
  }

  func shouldNotifyNewFiles(currentFiles: [String], oldFiles: [String]) -> Bool {
    let newFiles = currentFiles.filter { !oldFiles.contains($0) }
    let removedFiles = oldFiles.filter { !currentFiles.contains($0) }
    for file in removedFiles {
      if newFiles.contains(where: { $0 + ".crdownload" == file }) {
        return true
      }
    }
    return currentFiles.count != oldFiles.count
  }

  func stopMonitoring() {
    folderMonitorSource?.cancel()
    folderMonitorSource = nil
  }
}
