//
//  OpenWithHandler.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 06/12/2023.
//

import Foundation
import SwiftUI

class OpenWithHandler {

  @AppStorage("outputFileNameFormat") var outputFileNameFormat = ""

  static let shared = OpenWithHandler()

  var jobHandler: (([Job]) -> Void)?
  var pasteHandler: (([URL]) -> Void)?

  func onOpenFile(jobHandler: @escaping ([Job]) -> Void) {
    self.jobHandler = jobHandler
  }

  func openFile(jobs: [Job]) {
    DispatchQueue.main.async { [weak self] in
      self?.jobHandler?(jobs)
    }
  }

  func onPasteFiles(pasteHandler: @escaping (([URL]) -> Void)) {
    self.pasteHandler = pasteHandler
  }

  func pasteFiles(urls: [URL]) {
    self.pasteHandler?(urls)
  }

}
