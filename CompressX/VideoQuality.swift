//
//  VideoQuality.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 1/8/24.
//

import AVFoundation
import AVKit

enum VideoQuality: Codable, Equatable, RawRepresentable, Hashable {

  typealias RawValue = String

  init?(rawValue: String) {
    switch rawValue.lowercased() {
    case "highest":
      self = .highest
    case "high":
      self = .high
    case "good":
      self = .good
    case "medium":
      self = .medium
    case "acceptable":
      self = .acceptable
    case "ultraHD":
      self = .ultraHD
    case "fullHD":
      self = .fullHD
    default:
      return nil
    }
  }

  var rawValue: String {
    return displayText
  }

  case highest
  case high
  case good
  case medium
  case acceptable
  case ultraHD
  case fullHD
  case custom(Int)

  static func ==(lhs: VideoQuality, rhs: VideoQuality) -> Bool {
    return lhs.rawValue == rhs.rawValue
  }

  var displayText: String {
    switch self {
    case .highest:
      return "Highest"
    case .high:
      return "High"
    case .good:
      return "Good"
    case .medium:
      return "Medium"
    case .acceptable:
      return "Acceptable"
    case .ultraHD:
      return "Ultra HD"
    case .fullHD:
      return "Full HD"
    case .custom(let value):
      return "Custom (\(value))"
    }
  }
  
  var crf: String {
    switch self {
    case .highest:
      return "10"
    case .high:
      return "17"
    case .good:
      return "23"
    case .medium:
      return "27"
    case .acceptable:
      return "30"
    case .custom(let value):
      return "\(value)"
    default:
      return "17"
    }
  }

  var next: VideoQuality? {
    switch self {
    case .highest:
      return .good
    case .high:
      return .medium
    case .good:
      return .acceptable
    case .medium:
      return .acceptable
    case .acceptable:
      return .custom(35)
    case .custom(let value):
      if value > 40 {
        return nil
      }
      return .custom(min(value + 5, 40))
    default:
      return .acceptable
    }
  }

  var gifQualityLevel: String {
    switch self {
    case .highest:
      return "90"
    case .high:
      return "80"
    case .good:
      return "70"
    case .medium:
      return "60"
    case .acceptable:
      return "50"
    default:
      return "90"
    }
  }

  var avAssetExportPresetName: String {
    switch self {
    case .highest:
      return AVAssetExportPresetHEVCHighestQualityWithAlpha
    case .ultraHD:
      return AVAssetExportPresetHEVC3840x2160WithAlpha
    case .fullHD:
      return AVAssetExportPresetHEVC1920x1080WithAlpha
    default:
      return AVAssetExportPresetHEVCHighestQualityWithAlpha
    }
  }
}
