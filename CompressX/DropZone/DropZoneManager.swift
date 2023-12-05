//
//  DropZoneManager.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 4/9/24.
//

import AppKit
import SwiftUI
import Combine

class DropZoneManager: ObservableObject {

  @AppStorage("outputFileNameFormat") var outputFileNameFormat = ""
  @AppStorage("notchStyle") var notchStyle: NotchStyle = .expanded
  @AppStorage("dropZoneEnabled") var dropZoneEnabled = true

  @AppStorage("dropZoneCompressionSettingsType") var dropZoneCompressionSettingsType = DropZoneCompressSettingsType.same

  @AppStorage("dropZoneImageQuality") var dropZoneImageQuality: ImageQuality = .good
  @AppStorage("dropZoneImageFormat") var dropZoneImageFormat: ImageFormat = .same
  @AppStorage("dropZoneImageDimension") var dropZoneImageDimension: ImageDimension = .same
  @AppStorage("dropZoneVideoQuality") var dropZoneVideoQuality: VideoQuality = .good
  @AppStorage("dropZoneVideoFormat") var dropZoneVideoFormat: VideoFormat = .same
  @AppStorage("dropZoneVideoDimension") var dropZoneVideoDimension: VideoDimension = .same
  @AppStorage("dropZoneRemoveAudio") var dropZoneRemoveAudio: Bool = true
  @AppStorage("dropZonePreserveTransparency") var dropZonePreserveTransparency: Bool = false
  @AppStorage("dropZoneGifQuality") var dropZoneGifQuality: VideoQuality = .good
  @AppStorage("dropZoneGifDimension") var dropZoneGifDimension: GifDimension = .same
  @AppStorage("dropZoneOutputFolder") var dropZoneOutputFolder: OutputFolder = .same
  @AppStorage("dropZoneCustomOutputFolder") var dropZoneCustomOutputFolder: String = ""
  @AppStorage("dropZoneRemoveFileAfterCompression") var dropZoneRemoveFileAfterCompression: Bool = false

  @AppStorage("imageQuality") var defaultImageQuality: ImageQuality = .highest
  @AppStorage("outputImageFormat") var defaultImageFormat: ImageFormat = .same
  @AppStorage("imageDimension") var defaultImageDimension: ImageDimension = .same

  @AppStorage("videoQuality") var defaultVideoQuality: VideoQuality = .high
  @AppStorage("outputFormat") var defaultVideoFormat: VideoFormat = .same
  @AppStorage("videoDimension") var defaultVideoDimension: VideoDimension = .same
  @AppStorage("removeAudio") var defaultRemoveAudio = false
  @AppStorage("gifQuality") var defaultGifQuality: VideoQuality = .high
  @AppStorage("gifDimension") var defaultGifDimension: GifDimension = .same
  @AppStorage("outputFolder") var defaultOutputFolder: OutputFolder = .same
  @AppStorage("customOutputFolder") var defaultCustomOutputFolder = ""
  @AppStorage("removeFileAfterCompress") var defaultRemoveFileAfterCompress = false

  var imageQuality: ImageQuality {
    switch dropZoneCompressionSettingsType {
    case .same:
      return defaultImageQuality
    case .custom:
      return dropZoneImageQuality
    }
  }

  var imageFormat: ImageFormat {
    switch dropZoneCompressionSettingsType {
    case .same:
      return defaultImageFormat
    case .custom:
      return dropZoneImageFormat
    }
  }

  var imageDimension: ImageDimension {
    switch dropZoneCompressionSettingsType {
    case .same:
      return defaultImageDimension
    case .custom:
      return dropZoneImageDimension
    }
  }

  var gifQuality: VideoQuality {
    switch dropZoneCompressionSettingsType {
    case .same:
      return defaultGifQuality
    case .custom:
      return dropZoneGifQuality
    }
  }

  var gifDimension: GifDimension {
    switch dropZoneCompressionSettingsType {
    case .same:
      return defaultGifDimension
    case .custom:
      return dropZoneGifDimension
    }
  }

  var videoQuality: VideoQuality {
    switch dropZoneCompressionSettingsType {
    case .same:
      return defaultVideoQuality
    case .custom:
      return dropZoneVideoQuality
    }
  }

  var videoFormat: VideoFormat {
    switch dropZoneCompressionSettingsType {
    case .same:
      return defaultVideoFormat
    case .custom:
      return dropZoneVideoFormat
    }
  }

  var videoDimension: VideoDimension {
    switch dropZoneCompressionSettingsType {
    case .same:
      return defaultVideoDimension
    case .custom:
      return dropZoneVideoDimension
    }
  }

  var removeAudio: Bool {
    switch dropZoneCompressionSettingsType {
    case .same:
      return defaultRemoveAudio
    case .custom:
      return dropZoneRemoveAudio
    }
  }

  var outputFolder: OutputFolder {
    switch dropZoneCompressionSettingsType {
    case .same:
      return defaultOutputFolder
    case .custom:
      return dropZoneOutputFolder
    }
  }

  var customOutputFolder: String {
    switch dropZoneCompressionSettingsType {
    case .same:
      return defaultCustomOutputFolder
    case .custom:
      return dropZoneCustomOutputFolder
    }
  }

  var removeFileAfterCompression: Bool {
    switch dropZoneCompressionSettingsType {
    case .same:
      return defaultRemoveFileAfterCompress
    case .custom:
      return dropZoneRemoveFileAfterCompression
    }
  }

  var leftMouseDragMonitor: Any?
  var lastPasteboardChangeCount: Int = NSPasteboard(name: .drag).changeCount

  static let shared = DropZoneManager()

  static let WIDTH: CGFloat = 260

  static var HEIGHT: CGFloat {
    if hasNotch {
      return 70
    }
    return 50
  }

  var notchWindow: NSWindow?
  var dropZoneView: DropZoneView?

  init() {
    if dropZoneEnabled {
      enableDropZone()
    }
  }

  func getScreenWithMouse() -> NSScreen? {
    let mouseLocation = NSEvent.mouseLocation
    let screens = NSScreen.screens
    let screenWithMouse = (screens.first { NSMouseInRect(mouseLocation, $0.frame, false) })

    return screenWithMouse
  }

  private var notchTopCenterPoint: CGPoint {
    return CGPoint(
      x: (NSScreen.main?.frame.width ?? 0) / 2 + (NSScreen.main?.frame.origin.x ?? 0),
      y: (NSScreen.main?.frame.height ?? 0) + (NSScreen.main?.frame.origin.y ?? 0)
    )
  }

  private var notchFrame: NSRect {
    return NSRect(
      x: notchTopCenterPoint.x - DropZoneManager.WIDTH/2,
      y: notchTopCenterPoint.y - DropZoneManager.HEIGHT,
      width: DropZoneManager.WIDTH,
      height: DropZoneManager.HEIGHT
    )
  }

  func show() {
    if self.notchWindow != nil {
      notchWindow?.setFrameOrigin(notchFrame.origin)
      return
    }
    let window = NSWindow()
    let onClose: () -> Void = { [weak self] in
      self?.close()
    }
    let notchView = DropZoneView(
      hasNotch: hasNotch,
      onClose: onClose
    )
    dropZoneView = notchView
    let view = NSHostingView(rootView: notchView)
    window.contentView = view
    window.level = .popUpMenu
    window.backgroundColor = NSColor.clear
    window.styleMask = [.borderless]
    window.backingType = .buffered
    window.setFrame(notchFrame, display: true)
    window.orderFront(nil)
    window.isReleasedWhenClosed = false
    self.notchWindow = window
  }

  func close() {
    notchWindow?.contentView = nil
    notchWindow?.close()
    notchWindow = nil
    dropZoneView = nil
  }

  var jobQueue: [Job] = []
  let jobQueuePublisher = PassthroughSubject<[Job], Never>()
  var cancellables = Set<AnyCancellable>()

  func queueJob(inputFileURLs: [URL]) {

    for inputFileURL in inputFileURLs {
      let fileType = checkFileType(url: inputFileURL)
      let outputType: OutputType? = {
        switch fileType {
        case .image:
          return .image(
            imageQuality: imageQuality,
            imageFormat: imageFormat,
            imageDimension: imageDimension
          )
        case .gif:
          return .gifCompress(
            gifQuality: gifQuality,
            dimension: gifDimension
          )
        case .video:
          return .video(
            videoQuality: videoQuality,
            videoDimension: videoDimension,
            videoFormat: videoFormat,
            hasAudio: true,
            removeAudio: removeAudio,
            preserveTransparency: false,
            startTime: nil,
            endTime: nil
          )
        default:
          return nil
        }
      }()
      guard let outputType = outputType else { return }
      let job = Job(
        inputFileURL: inputFileURL,
        outputType: outputType,
        outputFolder: outputFolder,
        customOutputFolder: customOutputFolder,
        outputFileNameFormat: outputFileNameFormat,
        removeInputFile: removeFileAfterCompression
      )

      jobQueue.append(job)
    }
    jobQueuePublisher.send(jobQueue)
  }

  func enableDropZone() {
    disableDropZone()

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

    if let monitor = leftMouseDragMonitor {
      NSEvent.removeMonitor(monitor)
    }
    leftMouseDragMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged) { [weak self] _ in
      self?.checkForDraggedItems()
      withAnimation {
        self?.calculateOffset()
      }
    }
  }

  let offsetXMax: CGFloat = 20
  let offsetYMax: CGFloat = 10
  @Published var offsetX: CGFloat = 0
  @Published var offsetY: CGFloat = 0

  private func calculateOffset() {
    let mouseLocation = NSEvent.mouseLocation
    let centerPoint = notchTopCenterPoint
    let midY = (NSScreen.main?.frame.height ?? 0) / 2 + (NSScreen.main?.frame.origin.y ?? 0)
    offsetX = offsetXMax * ((mouseLocation.x - centerPoint.x) / centerPoint.x)
    offsetY = offsetYMax * ((mouseLocation.y - midY) / midY)
//    print("💛", mouseLocation, offsetX)
  }

  private func checkForDraggedItems() {
    let dragPasteboard = NSPasteboard(name: .drag)
    let currentChangeCount = dragPasteboard.changeCount
    guard lastPasteboardChangeCount != currentChangeCount else {
      return
    }
    lastPasteboardChangeCount = currentChangeCount
    let dragTypes = [NSPasteboard.PasteboardType.URL]
    if dragPasteboard.availableType(from: dragTypes) != nil {
      var isFileTypeSupported = false
      if let urls = dragPasteboard.readObjects(forClasses: [NSURL.self]) as? [URL] {
        urls.forEach { url in
          let fileType = checkFileType(url: url)
          switch fileType {
          case .image:
            isFileTypeSupported = true
          case .gif:
            isFileTypeSupported = true
          case .video:
            isFileTypeSupported = true
          case .notSupported:
            break
          }
        }
      }
      if isFileTypeSupported {
        DropZoneManager.shared.show()
      }
    }
  }

  func disableDropZone() {
    if let monitor = leftMouseDragMonitor {
      NSEvent.removeMonitor(monitor)
      leftMouseDragMonitor = nil
    }
    cancellables.forEach { $0.cancel() }
    cancellables.removeAll()
  }
}
