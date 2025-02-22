//
//  Utils.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 09/01/2024.
//

import Foundation
import UniformTypeIdentifiers
import AVFoundation
import AppKit
import UserNotifications

let videoSupportedTypes = [UTType.mpeg4Movie, .movie, .quickTimeMovie, .avi, .mpeg, .mpeg2Video, .video, UTType("org.matroska.mkv")].compactMap { $0 }
let imageSupportedTypes = [UTType.image, .bmp, .jpeg]
let pdfSupportedTypes = [UTType.pdf, .epub]
let extraVideoSupportedTypes = ["mkv"]
let notSupportedTypes: [String] = []

func checkFileType(url: URL) -> FileType {
  if isPDFFile(url: url) {
    return .pdf
  }
  if isGifFile(url: url) {
    return .gif
  }
  if isImageFile(url: url) {
    if isPNGFile(url: url) {
      return .image(.png)
    }
    return .image(.jpg)
  }
  for type in notSupportedTypes {
    if type.lowercased() == url.pathExtension.lowercased() {
      return .notSupported
    }
  }
  for type in videoSupportedTypes {
    if url.contains(type) {
      return .video
    }
  }
  for type in extraVideoSupportedTypes {
    if url.pathExtension.lowercased() == type {
      return .video
    }
  }
  return .notSupported
}

fileprivate func isImageFile(url: URL) -> Bool {
  for imageSupportedType in imageSupportedTypes {
    if url.contains(imageSupportedType) {
      return true
    }
  }
  return false
}

func isPDFFile(url: URL) -> Bool {
  return url.pathExtension.lowercased() == "pdf" || url.pathExtension.lowercased() == "epub"
}

func isGifFile(url: URL) -> Bool {
  return url.pathExtension.lowercased() == "gif"
}

func isPNGFile(url: URL) -> Bool {
  return url.pathExtension.lowercased() == "png"
}

func isPdfFile(url: URL) -> Bool {
  return url.pathExtension.lowercased() == "pdf"
}

func isRawImage(url: URL) -> Bool {
  return url.pathExtension.lowercased() == "dng" || url.pathExtension.lowercased() == "heic"
}

func isSVGFile(url: URL) -> Bool {
  return url.pathExtension.lowercased() == "svg"
}

func isTiffFile(url: URL) -> Bool {
  return url.pathExtension.lowercased() == "tif"
}

func preProcessRawImage(inputFileURL: URL) -> URL? {
  let outputFile = FileManager.default.temporaryDirectory.appending(path: inputFileURL.lastPathComponent)
  if convertDNGToJPEG(inputURL: inputFileURL, outputURL: outputFile) {
    return outputFile
  }
  return nil
}

func isFileSupported(url: URL) -> Bool {
  let filetype = checkFileType(url: url)
  return filetype != .notSupported
}

func isValidFFmpegPath(_ path: String) -> Bool {
  return path.lowercased().hasSuffix("ffmpeg")
}

func isValidPngquantPath(_ path: String) -> Bool {
  return path.lowercased().hasSuffix("pngquant")
}

func isValidGifskiPath(_ path: String) -> Bool {
  return path.lowercased().hasSuffix("gifski")
}

func getFPS(from videoUrl: URL) async throws -> Float? {
  let asset = AVURLAsset(url: videoUrl)
  let track = try await asset.loadTracks(withMediaType: AVMediaType.video).first
  return try await track?.load(.nominalFrameRate)
}

func getVideoSize(from videoUrl: URL) async throws -> CGSize? {
  let asset = AVURLAsset(url: videoUrl)
  let track = try await asset.loadTracks(withMediaType: AVMediaType.video).first
  return try await track?.load(.naturalSize)
}

func getVideoDuration(from videoURL: URL) async throws -> TimeInterval {
  let asset = AVURLAsset(url: videoURL)
  let duration = try await asset.load(.duration)
  return CMTimeGetSeconds(duration)
}

func fileSizeString(from bytes: Int64?) -> String {
  guard let bytes = bytes else { return "" }
  return fileByteCountFormatter.string(fromByteCount: bytes)
}

func getFileCreationDate(from url: URL) throws -> Date? {
  let attributes = try FileManager.default.attributesOfItem(atPath: url.path(percentEncoded: false))
  return attributes[.creationDate] as? Date
}

func changeAppIcon(image: NSImage) {
  NSApp.applicationIconImage = image
  NSWorkspace.shared.setIcon(image, forFile: Bundle.main.bundlePath)
  let task = Process()
  task.launchPath = "/usr/bin/env"
  task.arguments = ["touch", Bundle.main.bundlePath]
  try? task.run()
}

let fileByteCountFormatter: ByteCountFormatter = {
  let bcf = ByteCountFormatter()
  bcf.allowedUnits = [.useAll]
  bcf.countStyle = .file
  return bcf
}()

var brewPath: String? {
  if FileManager.default.fileExists(atPath: "/opt/homebrew/bin/brew") {
    return "/opt/homebrew/bin/brew"
  }
  if FileManager.default.fileExists(atPath: "/usr/local/bin/brew") {
    return "/usr/local/bin/brew"
  }
  return nil
}

extension String {
  func toTimeInterval() -> TimeInterval? {
    let components = self.components(separatedBy: "=")
    guard components.count == 2, components[0] == "time", let timeString = components.last else {
      return nil
    }

    let timeComponents = timeString.components(separatedBy: ":")
    guard timeComponents.count == 3,
            let hours = Double(timeComponents[0]),
            let minutes = Double(timeComponents[1]),
            let seconds = Double(timeComponents[2]) else {
      return nil
    }

    return hours * 3600 + minutes * 60 + seconds
  }
}

func convertISO8601ToReadableDate(isoDate: String) -> String {
  let isoFormatter = ISO8601DateFormatter()
  isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds] // Include fractional seconds
  guard let date = isoFormatter.date(from: isoDate) else {
    return isoDate
  }

  let readableFormatter = DateFormatter()
  readableFormatter.dateStyle = .long
  readableFormatter.timeStyle = .none

  return readableFormatter.string(from: date)
}

/* Example usage
let doubleValue = 3661.0 // For 1 hour, 1 minute, and 1 second
let formattedString = formatTimeInterval(doubleValue)
print(formattedString) // Outputs: "01:01:01"
 */
func formatTimeInterval(_ interval: Double) -> String {
  let formatter = DateComponentsFormatter()
  formatter.allowedUnits = [.hour, .minute, .second]
  formatter.unitsStyle = .positional
  formatter.zeroFormattingBehavior = .pad

  return formatter.string(from: TimeInterval(interval)) ?? ""
}


func getFFmpegParam(videoSize: CGSize, expectedDimension: VideoDimension) -> [String]? {
  switch expectedDimension {
  case .same:
    return nil
  case .ultraHD:
    if videoSize.isFullHD || videoSize.isHD || videoSize.is4K {
      return nil
    }
    return ["-filter:v", "scale='trunc(oh*a/2)*2:2160'"]
  case .fullHD:
    if videoSize.isFullHD || videoSize.isHD {
      return nil
    }
    return ["-filter:v", "scale='trunc(oh*a/2)*2:1080'"]
  case .HD:
    if videoSize.isHD {
      return nil
    }
    return ["-filter:v", "scale='trunc(oh*a/2)*2:720'"]
  }
}

func getFFmpegParam(size: NSSize, imageSize: ImageSize, imageSizeValue: Int) -> [String]? {
  let newSize = getSize(
    inputWidth: size.width,
    inputHeight: size.height,
    imageSize: imageSize,
    imageSizeValue: imageSizeValue
  )
  return ["-vf", "scale=\(newSize.width):\(newSize.height)"]
}

func getSize(inputWidth: CGFloat, inputHeight: CGFloat, imageSize: ImageSize, imageSizeValue: Int) -> CGSize {
  switch imageSize {
  case .same:
    return CGSize(width: inputWidth, height: inputHeight)
  case .percentage:
    return CGSize(
      width: inputWidth * CGFloat(imageSizeValue) / 100,
      height: inputHeight * CGFloat(imageSizeValue) / 100
    )
  case .maxHeight:
    if inputHeight <= CGFloat(imageSizeValue) {
      return CGSize(width: inputWidth, height: inputHeight)
    } else {
      return CGSize(
        width: inputWidth * CGFloat(imageSizeValue) / inputHeight,
        height: CGFloat(imageSizeValue)
      )
    }
  case .maxWidth:
    if inputWidth <= CGFloat(imageSizeValue) {
      return CGSize(width: inputWidth, height: inputHeight)
    } else {
      return CGSize(
        width: CGFloat(imageSizeValue),
        height: inputHeight * CGFloat(imageSizeValue) / inputWidth
      )
    }
  case .maxLongEdge:
    if inputWidth < inputHeight {
      return getSize(
        inputWidth: inputWidth,
        inputHeight: inputHeight,
        imageSize: .maxHeight,
        imageSizeValue: imageSizeValue
      )
    } else {
      return getSize(
        inputWidth: inputWidth,
        inputHeight: inputHeight,
        imageSize: .maxWidth,
        imageSizeValue: imageSizeValue
      )
    }
  case .maxShortEdge:
    if inputWidth < inputHeight {
      return getSize(
        inputWidth: inputWidth,
        inputHeight: inputHeight,
        imageSize: .maxWidth,
        imageSizeValue: imageSizeValue
      )
    } else {
      return getSize(
        inputWidth: inputWidth,
        inputHeight: inputHeight,
        imageSize: .maxHeight,
        imageSizeValue: imageSizeValue
      )
    }
  }
}

extension CGSize {

  var is8K: Bool {
    return width > 3840 && height > 2160
  }

  var is4K: Bool {
    return width > 1920 && height > 1080
  }

  var isFullHD: Bool {
    return width <= 1920 && height <= 1080
  }

  var isHD: Bool {
    return width <= 1280 && height <= 720
  }
}

func saveImageAsPNG(image: NSImage, toPath path: String) -> Bool {
  guard let tiffData = image.tiffRepresentation,
        let bitmapImageRep = NSBitmapImageRep(data: tiffData) else {
    return false
  }

  guard let pngData = bitmapImageRep.representation(using: .png, properties: [:]) else {
    return false
  }

  do {
    try pngData.write(to: URL(fileURLWithPath: path))
    return true
  } catch {
    print("Failed to save image: \(error)")
    return false
  }
}

func saveImageAsJPEG(image: NSImage, toPath path: String, compressionFactor: Float = 0.9) -> Bool {
  guard let tiffData = image.tiffRepresentation,
        let bitmapImageRep = NSBitmapImageRep(data: tiffData) else {
    return false
  }

  let properties: [NSBitmapImageRep.PropertyKey: Any] = [.compressionFactor: compressionFactor]

  guard let jpegData = bitmapImageRep.representation(using: .jpeg, properties: properties) else {
    return false
  }

  do {
    try jpegData.write(to: URL(fileURLWithPath: path))
    return true
  } catch {
    print("Failed to save image: \(error)")
    return false
  }
}

extension URL {
  var fileSize: Int64? {
    if let values = try? resourceValues(forKeys: [URLResourceKey.fileSizeKey]), let fileBytes = values.fileSize {
      return Int64(fileBytes)
    }
    return nil
  }

  var mimeType: String {
    return UTType(filenameExtension: self.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
  }

  func contains(_ uttype: UTType) -> Bool {
    return UTType(mimeType: self.mimeType)?.conforms(to: uttype) ?? false
  }

  var hasAudio: Bool  {
    get async throws {
      let asset = AVAsset(url: self)

      // Check if there are any audio tracks in the asset
      let audioTracks = try await asset.loadTracks(withMediaType: .audio)

      return !audioTracks.isEmpty
    }
  }

  var checkVideoTransparency: Bool {
    get async throws {
      let asset = AVAsset(url: self)
      let videoTracks = try await asset.loadTracks(withMediaType: .video)

      guard let track = videoTracks.first else { return false }

      let formatDescriptions = try await track.load(.formatDescriptions)
      for formatDescription in formatDescriptions {
        if let containsAlphaChannel = formatDescription.extensions[CMFormatDescription.Extensions.Key.containsAlphaChannel],
           containsAlphaChannel.propertyListRepresentation as? Bool == true {
          return true
        }
        if formatDescription.extensions[CMFormatDescription.Extensions.Key.alphaChannelMode] != nil {
          return true
        }
      }
      return false
    }
  }
}

func convertDNGToJPEG(inputURL: URL, outputURL: URL) -> Bool {
  let context = CIContext()
  guard let rawImage = CIImage(contentsOf: inputURL) else {
    return false
  }

  guard let jpegData = context.jpegRepresentation(of: rawImage, colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!, options: [:]) else {
    return false
  }

  do {
    try jpegData.write(to: outputURL)
  } catch {
    return false
  }

  return true
}

extension NSImage {
  func resized(to newSize: NSSize?) -> NSImage {
    guard let newSize = newSize else { return self }
    if let bitmapRep = NSBitmapImageRep(
      bitmapDataPlanes: nil, pixelsWide: Int(newSize.width), pixelsHigh: Int(newSize.height),
      bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
      colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0
    ) {
      bitmapRep.size = newSize
      NSGraphicsContext.saveGraphicsState()
      NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
      draw(in: NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height), from: .zero, operation: .copy, fraction: 1.0)
      NSGraphicsContext.restoreGraphicsState()

      let resizedImage = NSImage(size: newSize)
      resizedImage.addRepresentation(bitmapRep)
      return resizedImage
    }

    return self
  }
}

var hasNotch: Bool {
  return notchSize != nil
}

var notchSize: NSSize? {
  if let screen = getScreenWithMouse(),
     screen.safeAreaInsets.top != 0,
     let auxiliaryTopLeftArea = screen.auxiliaryTopLeftArea,
     let auxiliaryTopRightArea = screen.auxiliaryTopLeftArea {
    return NSSize(
      width: screen.visibleFrame.width -  auxiliaryTopLeftArea.width - auxiliaryTopRightArea.width,
      height: screen.safeAreaInsets.top
    )
  }
  return nil
}

func getScreenWithMouse() -> NSScreen? {
  let mouseLocation = NSEvent.mouseLocation
  let screens = NSScreen.screens
  let screenWithMouse = (screens.first { NSMouseInRect(mouseLocation, $0.frame, false) })

  return screenWithMouse
}

var appVersion: String {
  var result = ""
  if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
    result = appVersion
  }
  if let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
    result += " (\(buildNumber))"
  }

  return result
}

var appVersionOnly: String {
  return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
}

extension NSImage {
  func squareCrop() -> NSImage {
    let imageSize = self.size
    var rect: CGRect = .zero
    if imageSize.width < imageSize.height {
      rect = CGRect(
        x: 0,
        y: (imageSize.height - imageSize.width) / 2,
        width: imageSize.width,
        height: imageSize.width
      )
    } else if imageSize.width > imageSize.height {
      rect = CGRect(
        x: (imageSize.width - imageSize.height) / 2,
        y: 0,
        width: imageSize.height,
        height: imageSize.height
      )
    } else {
      return self
    }
    let result = NSImage(size: rect.size)
    result.lockFocus()

    self.draw(in: NSRect(origin: .zero, size: result.size),
              from: rect,
              operation: .copy,
              fraction: 1.0)

    result.unlockFocus()

    return result
  }
}

func getVideoThumbnail(url: URL, cmTime: CMTime?) -> NSImage? {
  let asset = AVURLAsset(url: url)
  let imageGenerator = AVAssetImageGenerator(asset: asset)
  imageGenerator.appliesPreferredTrackTransform = true
  if let cgImage = try? imageGenerator.copyCGImage(at: cmTime ?? CMTime(seconds: 0, preferredTimescale: 1), actualTime: nil) {
    return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
  }
  return nil
}

func getSubfolders(in folderURL: URL) -> [URL] {
  let fileManager = FileManager.default

  let allItems = try? fileManager.contentsOfDirectory(
    at: folderURL,
    includingPropertiesForKeys: nil,
    options: [.skipsHiddenFiles]
  )

  let subfolders = allItems?.filter { $0.hasDirectoryPath }

  return subfolders ?? []
}

func getFiles(in folderURL: URL) -> [URL] {
  let fileManager = FileManager.default

  let allItems = try? fileManager.contentsOfDirectory(
    at: folderURL,
    includingPropertiesForKeys: nil,
    options: [.skipsHiddenFiles]
  )

  let files = allItems?.filter { !$0.hasDirectoryPath }

  return files ?? []
}

func flatten(urls: [URL], maxDepth: Int) -> [URL] {
  guard !urls.isEmpty, maxDepth > 0 else { return [] }
  let files = urls.filter { !$0.hasDirectoryPath }
  let folders = urls.filter { $0.hasDirectoryPath }
  let flattenFiles = folders.flatMap { getFiles(in: $0) }
  let subfolders = folders.flatMap { getSubfolders(in: $0) }
  return files + flattenFiles + flatten(urls: subfolders, maxDepth: maxDepth - 1)
}

extension Date {
  var toISO8601DateTime: String {
    let formatter = DateFormatter()
    formatter.timeZone = .current
    formatter.dateFormat = "yyyy-MM-dd'T'HHmmss"
    let result = formatter.string(from: self)
    return result.replacingOccurrences(of: ":", with: ".")
  }

  var toISO8601Date: String {
    let formatter = DateFormatter()
    formatter.timeZone = .current
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: self)
  }

  var toISO8601Time: String {
    let formatter = DateFormatter()
    formatter.timeZone = .current
    formatter.dateFormat = "HHmmss"
    let result = formatter.string(from: self)
    return result
  }
}

func normalizeVersion(_ version: String) -> String {
  // Split the version string by "."
  var parts = version.split(separator: ".").map(String.init)

  // Ensure that we always have at least 3 parts
  while parts.count < 3 {
    parts.append("0")
  }

  // Join them back into a normalized version string
  return parts.joined(separator: ".")
}

func compareVersions(_ version1: String, _ version2: String) -> Int {
  // Normalize and split both versions, converting each part to Int
  let v1Parts = normalizeVersion(version1).split(separator: ".").compactMap { Int($0) }
  let v2Parts = normalizeVersion(version2).split(separator: ".").compactMap { Int($0) }

  // Compare each segment
  for i in 0..<3 {
    if v1Parts[i] > v2Parts[i] {
      return 1
    } else if v1Parts[i] < v2Parts[i] {
      return -1
    }
  }

  // If all segments are equal, return 0
  return 0
}

extension Array: @retroactive RawRepresentable where Element: Codable {
  public init?(rawValue: String) {
    guard let data = rawValue.data(using: .utf8),
          let result = try? JSONDecoder().decode([Element].self, from: data)
    else {
      return nil
    }
    self = result
  }

  public var rawValue: String {
    guard let data = try? JSONEncoder().encode(self),
          let result = String(data: data, encoding: .utf8)
    else {
      return "[]"
    }
    return result
  }
}

func numberOfAudioTracks(url: URL) async throws -> Int {
  let asset = AVAsset(url: url)

  // Get all audio tracks
  let audioTracks = try await asset.loadTracks(withMediaType: .audio)

  return audioTracks.count
}

func sendSuccessPushNotification(path: String, count: Int, urls: [String]) {
  let content = UNMutableNotificationContent()
  content.title = "Compression finished 🎉"
  if urls.count > 1 {
    content.body = "\(count) files saved to \(path). Tap to open them in Finder"
  } else {
    content.body = "\(count) file saved to \(path). Tap to open them in Finder"
  }
  content.userInfo = ["fileURLs": urls]
  content.sound = .default
  let request = UNNotificationRequest(identifier: "compress.finish." + UUID().uuidString, content: content, trigger: nil)
  Task {
    try? await UNUserNotificationCenter.current().add(request)
  }
}

func sendErrorPushNotification(error: String) {
  let content = UNMutableNotificationContent()
  content.title = "Compression failed ❌"
  content.body = error
  content.sound = .default
  let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
  Task {
    try? await UNUserNotificationCenter.current().add(request)
  }
}

func hasSubfolders(urls: [URL]) -> Bool {
  let folders = urls.filter { $0.hasDirectoryPath }
  for folder in folders {
    // check if folder has subfolders
    let subfolders = getSubfolders(in: folder)
    if !subfolders.isEmpty {
      return true
    }
  }
  return false
}
