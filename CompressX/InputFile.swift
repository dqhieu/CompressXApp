//
//  InputFile.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 10/26/24.
//

import SwiftUI
import CoreMedia
import AVKit

struct InputFile: Identifiable, Hashable {

  var fileType: FileType
  var url: URL

  var fileName: String {
    return String(url.lastPathComponent.split(separator: ".").first ?? "")
  }

  var fileExtension: String {
    return url.lastPathComponent.split(separator: ".").last?.uppercased() ?? ""
  }

  var fileSize: String {
    return fileSizeString(from: url.fileSize)
  }

  var id: String { url.absoluteString }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  static func ==(lhs: InputFile, rhs: InputFile) -> Bool {
    return lhs.id == rhs.id
  }
}
