//
//  PdfOptionsView.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 1/3/25.
//

import SwiftUI

enum PDFQuality: String, CaseIterable {
  case best
  case high
  case balance
  case low

  var displayText: String {
    switch self {
    case .best:
      return "Best"
    case .high:
      return "High"
    case .balance:
      return "Balance"
    case .low:
      return "Low"
    }
  }

  var paramValue: String {
    switch self {
    case .best:
      return "prepress"
    case .high:
      return "printer"
    case .balance:
      return "ebook"
    case .low:
      return "screen"
    }
  }
}

struct PdfOptionsView: View {

  @AppStorage("pdfQuality") var pdfQuality: PDFQuality = .balance

  @ObservedObject var jobManager = JobManager.shared

  var body: some View {
    Section {
      Picker(selection: $pdfQuality) {
        ForEach(PDFQuality.allCases, id: \.self) { quality in
          Text(quality.displayText).tag(quality.rawValue)
        }
      } label: {
        Text("PDF quality")
      }
      .pickerStyle(.menu)
    }
    .disabled(jobManager.isRunning)
  }
}
