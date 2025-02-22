//
//  CompressView.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 21/11/2023.
//

import SwiftUI
import AVFoundation
import AVKit
import TelemetryClient
import UniformTypeIdentifiers
import SwiftDate
import UserNotifications

struct CompressView: View {

  @AppStorage("pinMainWindowOnTop") var pinMainWindowOnTop = false
  @AppStorage("customOutputFolder") var customOutputFolder = ""
  @AppStorage("notifyWhenFinish") var notifyWhenFinish = false
  @AppStorage("removeFileAfterCompress") var removeFileAfterCompress = false
  @AppStorage("shouldRemindAutoCompress") var shouldRemindAutoCompress = true
  @AppStorage("outputFolderType") var outputFolderType = 1
  @AppStorage("videoQuality") var videoQuality: VideoQuality = .high
  @AppStorage("imageQuality") var imageQuality: ImageQuality = .highest
  @AppStorage("gifQuality") var gifQuality: VideoQuality = .high
  @AppStorage("outputFormat") var outputFormat: VideoFormat = .same
  @AppStorage("outputFolder") var outputFolder: OutputFolder = .same
  @AppStorage("outputImageFormat") var outputImageFormat: ImageFormat = .same
  @AppStorage("gifDimension") var gifDimension: GifDimension = .same
  @AppStorage("videoGifDimension") var videoGifDimension: GifDimension = .same
  @AppStorage("videoGifQuality") var videoGifQuality: VideoQuality = .high
  @AppStorage("didOpenProductHuntLink") var didOpenProductHuntLink = false
  @AppStorage("onDropBehavior") var onDropBehavior: OnDropBehavior = .replace
  @AppStorage("imageSize") var imageSize: ImageSize = .same
  @AppStorage("videoDimension") var videoDimension: VideoDimension = .same
  @AppStorage("removeAudio") var removeAudio = false
  @AppStorage("pdfQuality") var pdfQuality: PDFQuality = .balance
  @AppStorage("subfolderProcessing") var subfolderProcessing: SubfolderProcessing = .none
  @AppStorage("subfolderProcessingLimit") var subfolderProcessingLimit = 1

  @ObservedObject var jobManager = JobManager.shared

  @State private var lastWindowRect: NSRect?

  @State private var errorMessage: String?
  @State private var timeTaken: String?
  @State private var hasAudio: Bool = false

  @State private var reducedSizeString: String?
  @State private var showGetNotificationReminder = false
  @State private var showGetNotificationReminderWorkItem = DispatchWorkItem {}
  @State private var notificationErrorMessage: String?
  @State private var startDate = Date()
  @State private var removeFileError: String?
  @State private var isInputWebM = false
  @State private var showPreserveTransparency = false
  @State private var shouldPreserveTransparency = false
  @State private var hasImageInput = false
  @State private var hasVideoInput = false
  @State private var hasGifInput = false
  @State private var hasPDFInput = false
  @State private var fpsValue: Double = 30
  @State private var shouldShowProductHuntLink = false
  @State private var isHovering = false
  @State private var inputFiles: [InputFile] = []
  @State private var startTimes: [URL: CMTime] = [:]
  @State private var endTimes: [URL: CMTime] = [:]
  @State private var subfolderProcessingLimitText = "1"

  @State private var inputPaths: [URL] = []

  var videoQualities: [VideoQuality] {
    if showPreserveTransparency && shouldPreserveTransparency && outputFormat != .webm {
      return [.highest, .ultraHD, .fullHD]
    }
    return [.highest, .high, .good, .medium, .acceptable]
  }

  var gifQualities: [VideoQuality] = [.highest, .high, .good, .medium, .acceptable]

  var body: some View {
    ZStack {
      VStack {
        VStack {
          HStack {
            Spacer()
            Text("Compresto")
              .fontWeight(.bold)
              .foregroundStyle(
                LinearGradient(
                  colors: [Color.primary.opacity(0.7), Color.primary],
                  startPoint: .top,
                  endPoint: .bottom
                )
              )
              .offset(y: 2)
            Spacer()
          }
          Divider()
        }
        .background(.ultraThinMaterial)
        .offset(y: -2)
        Spacer()
      }
      .offset(y: -22)
      .zIndex(100)
      .onTapGesture(count: 2) {
        if let keyWindow = NSApplication.shared.keyWindow, let screen = getScreenWithMouse() {
          if keyWindow.frame.size == screen.visibleFrame.size, let rect = lastWindowRect {
            keyWindow.setFrame(rect, display: true, animate: true)
          } else  {
            lastWindowRect = keyWindow.frame
            keyWindow.setFrame(screen.visibleFrame, display: true, animate: true)
          }
        }
      }
      VStack {
        VStack {
          HStack {
            Spacer()
            Button {
              pinMainWindowOnTop.toggle()
            } label: {
              if #available(macOS 15.0, *) {
                Image(systemName: pinMainWindowOnTop ? "pin.square.fill" : "pin.square")
                  .resizable()
                  .aspectRatio(contentMode: .fit)
                  .frame(width: 16, height: 16)
                  .symbolRenderingMode(.hierarchical)
                  .contentTransition(.symbolEffect(.replace))
                  .symbolEffect(.wiggle, value: pinMainWindowOnTop)
                  .foregroundStyle(.secondary)
                  .padding(.trailing, 8)
                  .help("Pin window on top: \(pinMainWindowOnTop ? "On" : "Off")")
              } else
              if #available(macOS 14.0, *) {
                Image(systemName: pinMainWindowOnTop ? "pin.square.fill" : "pin.square")
                  .resizable()
                  .aspectRatio(contentMode: .fit)
                  .frame(width: 16, height: 16)
                  .symbolRenderingMode(.hierarchical)
                  .contentTransition(.symbolEffect(.replace))
                  .foregroundStyle(.secondary)
                  .padding(.trailing, 8)
                  .help("Pin window on top: \(pinMainWindowOnTop ? "On" : "Off")")
              } else {
                Image(systemName: pinMainWindowOnTop ? "pin.square.fill" : "pin.square")
                  .resizable()
                  .aspectRatio(contentMode: .fit)
                  .frame(width: 16, height: 16)
                  .foregroundStyle(.secondary)
                  .padding(.trailing, 8)
                  .help("Pin window on top: \(pinMainWindowOnTop ? "On" : "Off")")
              }
            }
            .buttonStyle(.plain)
          }
        }
        Spacer()
      }
      .offset(y: -22)
      .zIndex(100)
      HStack(spacing: 0) {
        VStack {
          GroupBox {
            if !inputFiles.isEmpty {
              FileGridView(
                inputFiles: inputFiles,
                startTimes: $startTimes,
                endTimes: $endTimes,
                onRemoveFile: { file in
                  var inputFileURLs = jobManager.inputFileURLs
                  inputFileURLs.removeAll(where: { $0 == file.url })
                  setSourceFile(urls: inputFileURLs)
                }
              )
            } else {
              HStack {
                Spacer()
                VStack {
                  Spacer()
                  HStack(spacing: 32) {
                    Image(systemName: "video")
                      .resizable()
                      .aspectRatio(contentMode: .fit)
                      .frame(width: 70, height: 70, alignment: .center)
                      .rotationEffect(Angle(degrees: isHovering ? -10 : -7))
                      .scaleEffect(isHovering ? 1.05 : 1)
                      .offset(x: 20)
                    Image(systemName: "doc")
                      .resizable()
                      .aspectRatio(contentMode: .fit)
                      .frame(width: 60, height: 60, alignment: .center)
                      .scaleEffect(isHovering ? 1.05 : 1)
                      .offset(y: -20)
                    Image(systemName: "photo")
                      .resizable()
                      .aspectRatio(contentMode: .fit)
                      .frame(width: 60, height: 60, alignment: .center)
                      .rotationEffect(Angle(degrees: isHovering ? 10 : 7))
                      .scaleEffect(isHovering ? 1.05 : 1)
                      .offset(x: -20)
                  }
                  Text("Tap to select videos / images / gifs / pdfs")
                  Text("or")
                  Text("drop them here")
                  Spacer()
                }
                Spacer()
              }
              .scaleEffect(isHovering ? 1.05 : 1)
              .background(Color.secondary.opacity(isHovering ? 0.1 : 0.001))
              .onHover(perform: { hovering in
                withAnimation {
                  isHovering = hovering
                }
              })
              .onTapGesture {
                openFileSelectionPanel()
              }
            }
          }
          .dropDestination(for: URL.self) { items, location in
            handleOnDropFiles(urls: items)
            return true
          }
        }
        .padding([.top, .leading, .bottom], 20)
        .frame(minWidth: 400, minHeight: 350)
        VStack {
          Form {
            if !jobManager.inputFileURLs.isEmpty {
              Section {
                HStack {
                  if jobManager.inputFileURLs.count == 1 {
                    Text("Input file (1)")
                  } else {
                    Text("Input files (\(jobManager.inputFileURLs.count))")
                  }
                  Spacer()
                  Button {
                    jobManager.inputFileURLs.removeAll()
                    inputFiles.removeAll()
                    jobManager.jobs.removeAll()
                    _ = validateInputFile(urls: [])
                    inputPaths = []
                  } label: {
                    Text("Clear")
                  }
                  .disabled(jobManager.isRunning)
                  Button {
                    openFileSelectionPanel()
                  } label: {
                    Text("Change")
                  }
                  .disabled(jobManager.isRunning)
                }
                if hasSubfolders(urls: inputPaths) {
                  VStack {
                    Picker(selection: $subfolderProcessing) {
                      ForEach(SubfolderProcessing.allCases, id: \.self) { behavior in
                        Text(behavior.displayText).tag(behavior.rawValue)
                      }
                    } label: {
                      Text("Include subfolders")
                    }
                    .onChange(of: subfolderProcessing, perform: { newValue in
                      let maxDepth: Int = {
                        switch newValue {
                        case .all:
                          return 1_000_000
                        case .none:
                          return 1
                        case .custom:
                          return subfolderProcessingLimit
                        }
                      }()
                      updateInputFiles(maxDepth: maxDepth)
                    })
                    .onChange(of: subfolderProcessingLimit, perform: { newValue in
                      subfolderProcessingLimitText = String(newValue)
                      updateInputFiles(maxDepth: newValue)
                    })
                    if subfolderProcessing == .custom {
                      HStack {
                        Text("Max depth")
                          .font(.caption)
                          .foregroundStyle(.secondary)
                        Spacer()
                        TextField("", text: $subfolderProcessingLimitText)
                          .frame(width: 50)
                          .textFieldStyle(.squareBorder)
                          .labelsHidden()
                          .multilineTextAlignment(.trailing)
                          .onSubmit(onMaxDepthSubmittion)
                        Button {
                          onMaxDepthSubmittion()
                        } label: {
                          Text("Update")
                        }
                        .disabled(Int(subfolderProcessingLimitText) == subfolderProcessingLimit)
                      }
                      .task {
                        subfolderProcessingLimitText = String(subfolderProcessingLimit)
                      }
                    }
                  }
                }
              }
            }
            Section {
              VStack(spacing: 8) {
                Picker("Output folder", selection: $outputFolder) {
                  ForEach(OutputFolder.allCases, id: \.self) { folder in
                    Text(folder.displayText).tag(folder.rawValue)
                  }
                }
                .pickerStyle(.menu)
                .onChange(of: outputFolder, perform: { newValue in
                  if newValue == .custom, customOutputFolder.isEmpty {
                    openFolderSelectionPanel()
                  }
                })
                if outputFolder == .custom, !customOutputFolder.isEmpty {
                  HStack {
                    Text(customOutputFolder.replacingOccurrences(of: FileManager.default.homeDirectoryForCurrentUser.path(percentEncoded: false), with: "~/"))
                      .textSelection(.enabled)
                    Spacer()
                    Button {
                      openFolderSelectionPanel()
                    } label: {
                      Text("Change")
                    }
                  }
                  .foregroundStyle(.secondary)
                }
              }
              Toggle(jobManager.inputFileURLs.count > 1 ? "Remove input files" : "Remove input file", isOn: $removeFileAfterCompress)
                .toggleStyle(.switch)
            }
            .disabled(jobManager.isRunning)
            if hasVideoInput {
              VideoOptionsView(
                showPreserveTransparency: $showPreserveTransparency,
                shouldPreserveTransparency: $shouldPreserveTransparency,
                isInputWebM: $isInputWebM,
                fpsValue: $fpsValue,
                hasAudio: $hasAudio
              )
            }
            if hasImageInput {
              ImageOptionsView()
            }
            if hasGifInput {
              GifOptionsView()
            }
            if hasPDFInput {
              PdfOptionsView()
            }
            Section {
              if jobManager.isRunning, let job = jobManager.currentJob {
                VStack(alignment: .leading, spacing: 4) {
                  HStack {
                    switch job.outputType {
                    case .video:
                      if jobManager.currentJob?.isMKV ?? false {
                        ProgressView {
                          HStack {
                            Text(jobManager.currentJob?.status ?? "Compressing")
                            if jobManager.jobs.count > 1, let index = jobManager.currentIndex {
                              Text("\(index)/\(jobManager.jobs.count) files")
                            }
                            Spacer()
                            Text(startDate, style: .relative)
                          }
                        }
                        .progressViewStyle(.linear)
                      } else {
                        ProgressView(value: jobManager.currentProgress, total: 1) {
                          HStack {
                            Text(jobManager.currentJob?.status ?? "Compressing")
                            if jobManager.jobs.count > 1, let index = jobManager.currentIndex {
                              Text("\(index)/\(jobManager.jobs.count) files")
                            }
                            Spacer()
                            Text(String(Int(jobManager.currentProgress * 100)) + "%")
                          }
                        }
                        .progressViewStyle(.linear)
                      }

                    case .image, .pdfCompress:
                      if jobManager.jobs.count > 1 {
                        ProgressView(value: Double(jobManager.currentIndex ?? 0) - 1, total: max(Double(jobManager.currentIndex ?? 0), Double(jobManager.jobs.count))) {
                          HStack {
                            Text("Compressing")
                            if jobManager.jobs.count > 1, let index = jobManager.currentIndex {
                              Text("\(index)/\(jobManager.jobs.count) files")
                            }
                            Spacer()
                            Text("\(jobManager.currentIndexProgress ?? 0)%")
                            //                          Text(String(Int(jobManager.currentProgress * 100)) + "%")
                          }
                        }
                        .progressViewStyle(.linear)
                      } else {
                        ProgressView {
                          HStack {
                            Text("Compressing")
                            Spacer()
                            Text(startDate, style: .relative)
                          }
                        }
                        .progressViewStyle(.linear)
                      }
                    case .gif:
                      ProgressView(value: jobManager.currentProgress, total: 1) {
                        HStack {
                          Text("Converting")
                          if jobManager.jobs.count > 1, let index = jobManager.currentIndex {
                            Text("\(index)/\(jobManager.jobs.count) files")
                          }
                          Spacer()
                          Text(String(Int(jobManager.currentProgress * 100)) + "%")
                        }
                      }
                      .progressViewStyle(.linear)
                    case .gifCompress:
                      ProgressView(value: jobManager.currentProgress, total: 1) {
                        HStack {
                          Text("Compressing")
                          if jobManager.jobs.count > 1, let index = jobManager.currentIndex {
                            Text("\(index)/\(jobManager.jobs.count) files")
                          }
                          Spacer()
                          Text(String(Int(jobManager.currentProgress * 100)) + "%")
                        }
                      }
                      .progressViewStyle(.linear)
                    }
                    Spacer()
                    Button {
                      jobManager.terminate()
                    } label: {
                      Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.borderless)
                  }
                  if jobManager.jobs.count > 1 {
                    Text(jobManager.currentJob?.inputFileURL.lastPathComponent ?? "")
                      .frame(maxWidth: .infinity, alignment: .leading)
                      .foregroundStyle(.secondary)
                      .font(.caption)
                  }
                }
              } else {
                Button(action: {
                  compress()
                }, label: {
                  HStack {
                    Spacer()
                    Text(hasVideoInput && !hasImageInput && outputFormat == .gif ? "Convert" : "Compress")
                      .foregroundStyle(.primary)
                    Spacer()
                  }
                  .frame(height: 24)
                })
                .buttonStyle(NiceButtonStyle())
                .disabled(jobManager.isRunning || jobManager.inputFileURLs.isEmpty)
                .keyboardShortcut(.defaultAction)
              }
            }
            if jobManager.jobs.contains(where: { FileManager.default.fileExists(atPath: $0.outputFileURL.path(percentEncoded: false)) }) {
              if jobManager.jobs.count == 1, !jobManager.isRunning {
                OutputView(
                  reducedSizeString: reducedSizeString,
                  timeTaken: timeTaken
                )
              } else if (jobManager.isRunning && (jobManager.currentIndex ?? 0) > 1) || !jobManager.isRunning {
                OutputView(
                  reducedSizeString: reducedSizeString,
                  timeTaken: timeTaken
                )
              }
            }
            if let message = errorMessage {
              Section {
                Text("\(Image(systemName: "xmark.diamond.fill")) \(message)")
                  .foregroundStyle(.red)
                if message.lowercased().contains("bad cpu type in executable") {
                  Button {
                    NSWorkspace.shared.open(URL(string: "https://docs.compresto.app/guides/how-to-resolve-error-bad-cpu-type-in-executable-on-macos")!)
                  } label: {
                    Text("Open documentation")
                  }
                }
                if message.lowercased().contains("ghostscript is not installed") {
                  Button {
                    NSWorkspace.shared.open(URL(string: "https://docs.compresto.app/guides/how-to-setup-pdf-compression")!)
                  } label: {
                    Text("Setup PDF compression")
                  }
                }
              }
            }
            if shouldShowProductHuntLink,
               let url = jobManager.jobs.first?.outputFileURL, FileManager.default.fileExists(atPath: url.path(percentEncoded: false)),
               let outputFileSize = url.fileSize,
               let inputFileSize = jobManager.jobs.first?.inputFileSize,
               outputFileSize < inputFileSize {
              Button {
                NSWorkspace.shared.open(URL(string: "https://www.producthunt.com/products/compressx/reviews/new")!)
                didOpenProductHuntLink = true
              } label: {
                Text("💛 Enjoy the app? Please review us on Product Hunt \(Image(systemName: "arrow.up.forward"))")
                  .multilineTextAlignment(.leading)
              }
              .buttonStyle(.link)
            }
            if showGetNotificationReminder {
              VStack {
                HStack {
                  Text("💡 Taking too long? Get notified when it finishes")
                  Spacer()
                  Button {
                    UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .alert]) { granted, error in
                      if granted {
                        showGetNotificationReminder = false
                        notifyWhenFinish = true
                      } else if let error = error {
                        notificationErrorMessage = error.localizedDescription + ". Please check your notification settings"
                      }
                    }
                  } label: {
                    Text("Notify me")
                  }
                }
                if let message = notificationErrorMessage {
                  Text("\(Image(systemName: "xmark.diamond.fill")) \(message)")
                    .foregroundStyle(.red)
                  Button {
                    if let bundleIdentifier = Bundle.main.bundleIdentifier,
                       let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications?\(bundleIdentifier)") {
                      NSWorkspace.shared.open(url)
                    }
                  } label: {
                    Text("Take me there")
                  }
                }
              }
            }
          }
          .frame(width: 300)
          .formStyle(.grouped)
          .task {
            OpenWithHandler.shared.onOpenFile { jobs in
              if jobManager.isRunning {
                jobManager.queue(newJobs: jobs)
                setInputFiles(urls: jobManager.inputFileURLs)
              } else {
                jobManager.jobs.removeAll(where: { FileManager.default.fileExists(atPath: $0.outputFileURL.path(percentEncoded: false)) })
                jobManager.queue(newJobs: jobs)
                setInputFiles(urls: jobManager.inputFileURLs)
                compress(jobs: jobs)
              }
            }
            OpenWithHandler.shared.onPasteFiles { urls in
              handleOnDropFiles(urls: urls)
            }
          }
        }
      }
    }
  }

  func handleOnDropFiles(urls: [URL]) {
    inputPaths = urls
    let maxDepth: Int = {
      switch subfolderProcessing {
      case .all:
        return 1_000_000
      case .none:
        return 1
      case .custom:
        return subfolderProcessingLimit
      }
    }()
    let files = flatten(urls: urls, maxDepth: maxDepth)
    onDropFiles(items: files)
  }

  func openFileSelectionPanel() {
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = true
    panel.canChooseDirectories = true
    panel.canChooseFiles = true
    panel.showsHiddenFiles = true
    panel.allowedContentTypes = videoSupportedTypes + imageSupportedTypes + pdfSupportedTypes
    let response = panel.runModal()
    if response == .OK {
      let urls = panel.urls
      let maxDepth: Int = {
        switch subfolderProcessing {
        case .all:
          return 1_000_000
        case .none:
          return 1
        case .custom:
          return subfolderProcessingLimit
        }
      }()
      let files = flatten(urls: urls, maxDepth: maxDepth)
      inputPaths = urls
      setSourceFile(urls: files)
    }
  }

  func openFolderSelectionPanel() {
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    let response = panel.runModal()
    if response == .OK, let url = panel.url {
      customOutputFolder = url.path(percentEncoded: false)
    } else if customOutputFolder.isEmpty {
      outputFolder = .same
    }
  }

  private func validateInputFile(urls: [URL]) -> [URL] {
    let supportedURLs = urls.filter { isFileSupported(url: $0) }

    hasImageInput = false
    hasVideoInput = false
    hasGifInput = false
    hasPDFInput = false

    for url in supportedURLs {
      let fileType = checkFileType(url: url)
      switch fileType {
      case .image:
        hasImageInput = true
      case .gif:
        hasGifInput = true
      case .video:
        hasVideoInput = true
      case .pdf:
        hasPDFInput = true
      case .notSupported:
        break
      }
    }

    return supportedURLs
  }

  private func checkWebMFormat(urls: [URL]) {
    var hasAtleast1WebM = false
    for url in urls {
      if url.pathExtension.uppercased() == VideoFormat.webm.rawValue.uppercased() {
        hasAtleast1WebM = true
      }
    }
    isInputWebM = hasAtleast1WebM
    if isInputWebM {
      outputFormat = .same
    }
  }

  private func checkAudio(urls: [URL]) {
    Task {
      var hasAtleast1Audio = false
      for url in urls {
        do {
          let inputHasAudio = try await url.hasAudio
          if inputHasAudio { hasAtleast1Audio = true }
        }
      }
      await MainActor.run {
        hasAudio = hasAtleast1Audio
      }
    }
  }

  private func checkTransparency(urls: [URL]) {
    showPreserveTransparency = false
    Task {
      var hasNoTransparency = true
      for url in urls {
        do {
          let hasTransparency = try await url.checkVideoTransparency
          if hasTransparency { hasNoTransparency = false }
        }
      }
      await MainActor.run {
        showPreserveTransparency = !hasNoTransparency
        if showPreserveTransparency {
          if outputFormat == .webm {
            shouldPreserveTransparency = true
          }
          if shouldPreserveTransparency {
            resetOptionForTransparencyIfNeeded()
          }
        } else {
          shouldPreserveTransparency = false
        }
      }
    }
  }

  func setSourceFile(urls: [URL]) {
    let filteredURLs = validateInputFile(urls: urls)
    jobManager.inputFileURLs = filteredURLs
    setInputFiles(urls: filteredURLs)
    jobManager.jobs.removeAll()
    startTimes.removeAll()
    endTimes.removeAll()
    errorMessage = nil
    timeTaken = nil
    hasAudio = false
    reducedSizeString = nil
    notificationErrorMessage = nil
    removeFileError = nil
    showPreserveTransparency = false
    shouldPreserveTransparency = false
    shouldShowProductHuntLink = false
    checkWebMFormat(urls: filteredURLs)
    checkAudio(urls: filteredURLs)
    checkTransparency(urls: filteredURLs)
  }

  private func setInputFiles(urls: [URL]) {
    inputFiles = urls.map { url -> InputFile in
      let fileType = checkFileType(url: url)
      return InputFile(
        fileType: fileType,
        url: url
      )
    }
    .filter { $0.fileType != .notSupported }
  }

  private func resetOptionForTransparencyIfNeeded() {
    if !videoQualities.contains(videoQuality) {
      videoQuality = .highest
    }
    removeAudio = false
  }

  func compress(jobs: [Job]) {
    guard LicenseManager.shared.isValid else {
      return showActivateLicenseAlert()
    }
    errorMessage = nil
    for job in jobs {
      switch job.outputType {
      case .video(let videoQuality, let videoDimension, let videoFormat, _, let removeAudio, let preserveTransparency, _, _):
        self.videoQuality = videoQuality
        self.outputFormat = videoFormat
        self.removeAudio = removeAudio
        self.shouldPreserveTransparency = preserveTransparency
        self.videoDimension = videoDimension
      case .image(let imageQuality, let imageFormat, let imageSize, _):
        self.imageQuality = imageQuality
        self.outputImageFormat = imageFormat
        self.imageSize = imageSize
      case .gifCompress(let gifQuality, let dimension):
        self.gifQuality = gifQuality
        self.gifDimension = dimension
      case .gif(let gifQuality, let fpsValue, let dimension):
        self.videoGifQuality = gifQuality
        self.videoGifDimension = dimension
        self.fpsValue = Double(fpsValue)
      case .pdfCompress(let pdfQuality):
        self.pdfQuality = pdfQuality
      }
    }
    if !notifyWhenFinish {
      showGetNotificationReminderWorkItem = DispatchWorkItem(block: {
        if !notifyWhenFinish, jobManager.isRunning == true {
          showGetNotificationReminder = true
        }
      })
      DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: showGetNotificationReminderWorkItem)
    }
    startDate = Date()
    commonCompress()
  }

  func compress() {
    guard LicenseManager.shared.isValid else {
      return showActivateLicenseAlert()
    }
    errorMessage = nil
    let jobs = jobManager.createJobs(
      inputFileURLs: jobManager.inputFileURLs,
      removeInputFile: removeFileAfterCompress,
      imageQuality: imageQuality,
      imageFormat: outputImageFormat,
      imageSize: imageSize,
      videoQuality: videoQuality,
      videoDimension: videoDimension,
      videoGifQuality: videoGifQuality,
      videoGifDimension: videoGifDimension,
      gifQuality: gifQuality,
      gifDimension: gifDimension,
      videoFormat: outputFormat,
      pdfQuality: pdfQuality,
      hasAudio: hasAudio,
      removeAudio: removeAudio,
      fpsValue: Int(fpsValue),
      preserveTransparency: shouldPreserveTransparency && showPreserveTransparency,
      startTimes: startTimes,
      endTimes: endTimes
    )
    jobManager.jobs = jobs
    if !notifyWhenFinish {
      showGetNotificationReminderWorkItem = DispatchWorkItem(block: {
        if !notifyWhenFinish, jobManager.isRunning == true {
          showGetNotificationReminder = true
        }
      })
      DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: showGetNotificationReminderWorkItem)
    }
    startDate = Date()
    commonCompress()
  }

  private func commonCompress() {
    Task {
      let jobs = await jobManager.compress()
      await MainActor.run {
        showGetNotificationReminderWorkItem.cancel()
        showGetNotificationReminder = false
        let totalTime = jobs.map { $0.totalTime }.reduce(0,+)
        timeTaken = totalTime.toString {
          $0.unitsStyle = .full
          $0.collapsesLargestUnit = false
          $0.allowsFractionalUnits = true
        }
        if !didOpenProductHuntLink, Int.random(in: 0...9) == 4 {
          shouldShowProductHuntLink = true
        } else {
          shouldShowProductHuntLink = false
        }
        if jobs.count > 1 {
          if outputFormat != .gif {
            let totalInputFileSize = jobs.map { $0.inputFileSize ?? 0 }.reduce(0,+)
            let totalOutputFileSize = jobs.map { $0.outputFileSize ?? 0 }.reduce(0,+)
            reducedSizeString = fileSizeString(from: totalInputFileSize - totalOutputFileSize)
          }
        } else if jobs.count == 1, let job = jobs.first {
          if let error = job.error {
          } else {
            if (job.inputFileSize ?? 0) - (job.outputFileSize ?? 0) <= 0 && outputFormat == .gif {
              reducedSizeString = nil
            } else {
              reducedSizeString = fileSizeString(from: (job.inputFileSize ?? 0) - (job.outputFileSize ?? 0))
            }
          }
        }
      }
    }
  }

  func onDropFiles(items: [URL]) {
    if jobManager.isRunning {
      let newJobs = jobManager.createJobs(
        inputFileURLs: items,
        removeInputFile: removeFileAfterCompress,
        imageQuality: imageQuality,
        imageFormat: outputImageFormat,
        imageSize: imageSize,
        videoQuality: videoQuality,
        videoDimension: videoDimension,
        videoGifQuality: videoGifQuality,
        videoGifDimension: videoGifDimension,
        gifQuality: gifQuality,
        gifDimension: gifDimension,
        videoFormat: outputFormat,
        pdfQuality: pdfQuality,
        hasAudio: hasAudio,
        removeAudio: removeAudio,
        fpsValue: Int(fpsValue),
        preserveTransparency: shouldPreserveTransparency && showPreserveTransparency,
        startTimes: startTimes,
        endTimes: endTimes
      )
      jobManager.queue(newJobs: newJobs)
      setInputFiles(urls: jobManager.inputFileURLs)
    } else {
      let optionKeyPressed = NSEvent.modifierFlags.contains(.option)
      if optionKeyPressed {
        // Append files if Option key is pressed
        let currentFiles = jobManager.inputFileURLs
        let newFiles = items.filter { !currentFiles.contains($0) }
        setSourceFile(urls: currentFiles + newFiles)
      } else {
        switch onDropBehavior {
        case .replace:
          setSourceFile(urls: items)
        case .append:
          let currentFiles = jobManager.inputFileURLs
          let newFiles = items.filter { !currentFiles.contains($0) }
          setSourceFile(urls: currentFiles + newFiles)
        }
      }
    }
  }

  func showFileNotSupportedAlert(type: String) {
    let alert = NSAlert.init()
    alert.messageText = "The \(type) type is not supported!"
    alert.addButton(withTitle: "OK")
    let _ = alert.runModal()
  }

  func showActivateLicenseAlert() {
    let alert = NSAlert.init()
    alert.messageText = "Please activate your license"
    alert.alertStyle = .critical
    alert.addButton(withTitle: "OK")
    let _ = alert.runModal()
  }

  func onMaxDepthSubmittion() {
    if let limit = Int(subfolderProcessingLimitText), limit > 0 {
      subfolderProcessingLimit = abs(limit)
    } else {
      let alert = NSAlert()
      alert.messageText = "Invalid value"
      alert.informativeText = "Value must be an positive integer"
      alert.addButton(withTitle: "OK")
      let _ = alert.runModal()
    }
  }

  func updateInputFiles(maxDepth: Int) {
    let files = flatten(urls: inputPaths, maxDepth: maxDepth)
    setSourceFile(urls: files)
  }
}
