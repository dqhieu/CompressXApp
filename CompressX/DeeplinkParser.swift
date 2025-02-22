//
//  DeeplinkParser.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 29/02/2024.
//

import Foundation
import SwiftUI

// compressx://open?path=file:///Users/hieudinh/Downloads/IMG_2588.MOV&quality=acceptable&videoFormat=mp4&imageFormat=webp
class DeeplinkParser {

  @AppStorage("outputFileNameFormat") var outputFileNameFormat = ""
  @AppStorage("removeFileAfterCompress") var removeFileAfterCompress = false
  @AppStorage("subfolderProcessing") var subfolderProcessing: SubfolderProcessing = .none
  @AppStorage("subfolderProcessingLimit") var subfolderProcessingLimit = 1

  static let shared = DeeplinkParser()

  func parse(url: URL) -> [Job] {
    if url.absoluteString.isEmpty { return [] }
    if let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
      switch components.scheme?.lowercased() {
      case "file": // open with
        let outputType: OutputType? = {
          let fileType = checkFileType(url: url)
          switch fileType {
          case .image(let imageType):
            switch imageType {
            case .jpg:
              return .image(imageQuality: .high, imageFormat: .same, imageSize: .same, imageSizeValue: 100)
            case .png:
              return .image(imageQuality: .high, imageFormat: .same, imageSize: .same, imageSizeValue: 100)
            }
          case .gif:
            return .gifCompress(gifQuality: .high, dimension: .same)
          case .pdf:
            return .pdfCompress(pdfQuality: .balance)
          case .video:
            return .video(
              videoQuality: .high,
              videoDimension: .same,
              videoFormat: .same,
              hasAudio: true,
              removeAudio: false,
              preserveTransparency: false,
              startTime: nil,
              endTime: nil
            )
          case .notSupported:
            return nil
          }
        }()
        if let outputType = outputType {
          return [Job(
            inputFileURL: url,
            outputType: outputType,
            outputFolder: .same,
            customOutputFolder: "",
            outputFileNameFormat: outputFileNameFormat,
            removeInputFile: removeFileAfterCompress
          )]
        } else {
          return []
        }
      case "compressx", "compresto": // deeplink
        // example deeplink: compressx://open?path=file:///Users/hieudinh/Desktop/acquired.mp4
        switch components.host {
        case "open":
          if let pathValue = components.queryItems?.first(where: { $0.name == "path"} )?.value {
            let paths = pathValue.split(separator: "|")
            var jobs: [Job] = []
            for path in paths {
              var isDirectory: ObjCBool = false
              if FileManager.default.fileExists(atPath: String(path), isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                  var newPath = String(path)
                  if !path.hasPrefix("file://") {
                    newPath = "file://" + path
                  }
                  if path.suffix(1) != "/" {
                    newPath += "/"
                  }
                  let maxDepth: Int = {
                    if let subfolderProcessingValue = components.queryItems?.first(where: { $0.name == "subfolderProcessing"} )?.value {
                      switch subfolderProcessingValue.lowercased() {
                      case "none":
                        return 1
                      case "all":
                        return 1_000_000
                      default:
                        return Int(subfolderProcessingValue.lowercased()) ?? 1
                      }
                    }
                    return 1
                  }()
                  let fileURLs = flatten(urls: [URL(string: String(newPath))!], maxDepth: maxDepth)
                  for fileURL in fileURLs {
                    if let job = createJob(fileURL: fileURL, components: components) {
                      jobs.append(job)
                    }
                  }
                } else {
                  var newPath = String(path)
                  if !path.hasPrefix("file://") {
                    newPath = "file://" + path
                  }
                  if let fileURL = URL(string: newPath) {
                    if let job = createJob(fileURL: fileURL, components: components) {
                      jobs.append(job)
                    }
                  }
                }
              }
            }
            return jobs
          }
        case "import": // compressx://import?path=/Users/hieudinh/Downloads/CompressX_ShipATon
          if let path = components.queryItems?.first(where: { $0.name == "path"} )?.value {
            var urls: [URL] = []
            let filePaths = path.split(separator: "|")
            for filePath in filePaths {
              var newPath = String(filePath)
              if !filePath.hasPrefix("file://") {
                newPath = "file://" + filePath
              }
              var isDirectory: ObjCBool = false
              if FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                  if path.suffix(1) != "/" {
                    newPath += "/"
                  }
                }
              }
              if let url = URL(string: newPath) {
                urls.append(url)
              }
            }
            OpenWithHandler.shared.pasteFiles(urls: urls)
          }
        default:
          break
        }
      default:
        return []
      }
    }
    return []
  }

  private func createJob(fileURL: URL, components: URLComponents) -> Job? {
    let videoQuality: VideoQuality = {
      if let qualityValue = components.queryItems?.first(where: { $0.name == "quality"} )?.value {
        return VideoQuality(rawValue: qualityValue.lowercased()) ?? .high
      }
      return .high
    }()
    let videoFormat: VideoFormat = {
      if let formatValue = components.queryItems?.first(where: { $0.name == "videoFormat"} )?.value {
        return VideoFormat(rawValue: formatValue.lowercased()) ?? .same
      }
      if let formatValue = components.queryItems?.first(where: { $0.name == "format"} )?.value {
        return VideoFormat(rawValue: formatValue.lowercased()) ?? .same
      }
      return .same
    }()
    let imageQuality: ImageQuality = {
      if let qualityValue = components.queryItems?.first(where: { $0.name == "quality"} )?.value {
        return ImageQuality(rawValue: qualityValue.lowercased()) ?? .high
      }
      return .high
    }()
    let imageFormat: ImageFormat = {
      if let formatValue = components.queryItems?.first(where: { $0.name == "imageFormat"} )?.value {
        return ImageFormat(rawValue: formatValue.lowercased()) ?? .same
      }
      if let formatValue = components.queryItems?.first(where: { $0.name == "format"} )?.value {
        return ImageFormat(rawValue: formatValue.lowercased()) ?? .same
      }
      return .same
    }()
    let removeAudio: Bool = {
      if let removeAudioValue = components.queryItems?.first(where: { $0.name == "removeAudio"} )?.value {
        return removeAudioValue.lowercased() == "true"
      }
      return false
    }()
    let gifQuality: VideoQuality = {
      if let qualityValue = components.queryItems?.first(where: { $0.name == "quality"} )?.value {
        return VideoQuality(rawValue: qualityValue.lowercased()) ?? .high
      }
      return .high
    }()
    let pdfQuality: PDFQuality = {
      if let qualityValue = components.queryItems?.first(where: { $0.name == "pdfQuality"} )?.value ?? components.queryItems?.first(where: { $0.name == "quality"} )?.value {
        return PDFQuality(rawValue: qualityValue.lowercased()) ?? .balance
      }
      return .high
    }()
    let outputDirectory: String? = {
      if let value = components.queryItems?.first(where: { $0.name == "outputFolder"} )?.value {
        return value
      }
      if let value = components.queryItems?.first(where: { $0.name == "outputPath"} )?.value {
        return value
      }
      if let value = components.queryItems?.first(where: { $0.name == "outputDirectory"} )?.value {
        return value
      }
      return nil

    }()
    let removeInputFile: Bool = {
      if let value = components.queryItems?.first(where: { $0.name == "removeInputFile"} )?.value {
        if value.lowercased() == "true" {
          return true
        } else if value.lowercased() == "false" {
          return false
        }
      }
      return removeFileAfterCompress
    }()
    let fileNameFormat: String = {
      if let value = components.queryItems?.first(where: { $0.name == "fileNameFormat"} )?.value {
        return value
      }
      return outputFileNameFormat
    }()
    let outputType: OutputType? = {
      let fileType = checkFileType(url: fileURL)
      switch fileType {
      case .image(let imageType):
        switch imageType {
        case .jpg:
          return .image(imageQuality: imageQuality, imageFormat: imageFormat, imageSize: .same, imageSizeValue: 100)
        case .png:
          return .image(imageQuality: imageQuality, imageFormat: imageFormat, imageSize: .same, imageSizeValue: 100)
        }
      case .gif:
        return .gifCompress(gifQuality: gifQuality, dimension: .same)
      case .pdf:
        return .pdfCompress(pdfQuality: pdfQuality)
      case .video:
        return .video(
          videoQuality: videoQuality,
          videoDimension: .same,
          videoFormat: videoFormat,
          hasAudio: true,
          removeAudio: removeAudio,
          preserveTransparency: false,
          startTime: nil,
          endTime: nil
        )
      case .notSupported:
        return nil
      }
    }()
    if let outputType = outputType {
      if var outputDirectory = outputDirectory, !outputDirectory.isEmpty {
        if !outputDirectory.hasPrefix("/") {
          outputDirectory = "/" + outputDirectory
        }
        if !outputDirectory.hasPrefix(FileManager.default.homeDirectoryForCurrentUser.path) {
          outputDirectory = FileManager.default.homeDirectoryForCurrentUser.path + outputDirectory
        }
        let job = Job(
          inputFileURL: fileURL,
          outputType: outputType,
          outputFolder: .custom,
          customOutputFolder: outputDirectory,
          outputFileNameFormat: fileNameFormat,
          removeInputFile: removeInputFile
        )
        return job
      } else {
        let job = Job(
          inputFileURL: fileURL,
          outputType: outputType,
          outputFolder: .same,
          customOutputFolder: "",
          outputFileNameFormat: fileNameFormat,
          removeInputFile: removeInputFile
        )
        return job
      }
    } else {
      return nil
    }
  }
}
