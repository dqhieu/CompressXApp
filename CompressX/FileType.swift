//
//  FileType.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 1/8/24.
//

import Foundation

enum FileType: Equatable {
  case image(ImageType)
  case gif
  case video
  case pdf
  case notSupported

  var isImage: Bool {
    switch self {
    case .image:
      return true
    default:
      return false
    }
  }
}
