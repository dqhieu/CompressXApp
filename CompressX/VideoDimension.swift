//
//  VideoDimension.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 1/8/24.
//


enum VideoDimension: String, CaseIterable, Codable {
  case same
  case ultraHD
  case fullHD
  case HD

  var displayText: String {
    switch self {
    case .same:
      return "Same as input"
    case .ultraHD:
      return "4K (2160p)"
    case .fullHD:
      return "Full HD (1080p)"
    case .HD:
      return "HD (720p)"
    }
  }
}
