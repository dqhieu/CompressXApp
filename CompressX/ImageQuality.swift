//
//  ImageQuality.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 1/8/24.
//


enum ImageQuality: String, CaseIterable, Codable {
  case highest
  case high
  case good
  case medium

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
    }
  }

  var jpgImageQualityLevel: String {
    switch self {
    case .highest:
      return "2"
    case .high:
      return "3"
    case .good:
      return "8"
    case .medium:
      return "12"
    }
  }

  var pngFFmpegQualityLevel: String {
    switch self {
    case .highest:
      return "30"
    case .high:
      return "50"
    case .good:
      return "70"
    case .medium:
      return "80"
    }
  }

  var pngImageQualityLevel: String {
    switch self {
    case .highest:
      return "40-90"
    case .high:
      return "30-75"
    case .good:
      return "20-60"
    case .medium:
      return "10-45"
    }
  }

  var webPImageQualityLevel: Double {
    switch self {
    case .highest:
      return 0.9
    case .high:
      return 0.8
    case .good:
      return 0.7
    case .medium:
      return 0.6
    }
  }

  var svgImageQualityLevel: Double {
    switch self {
    case .highest:
      return 0.9
    case .high:
      return 0.8
    case .good:
      return 0.7
    case .medium:
      return 0.6
    }
  }
}
