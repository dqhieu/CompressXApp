//
//  ImageFormat.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 1/8/24.
//


enum ImageFormat: String, CaseIterable, Codable {
  case same
  case jpg
  case png
  case webp

  var displayText: String {
    switch self {
    case .same:
      return "Same as input"
    case .jpg:
      return "JPG"
    case .png:
      return "PNG"
    case .webp:
      return "WebP"
    }
  }

}