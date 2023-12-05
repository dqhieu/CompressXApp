//
//  PDFCompressor.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 10/16/24.
//

import Foundation
import Quartz

// https://github.com/maxim-puchkov/compress-pdf
class PDFCompressor {

  private let quartz_filter: QuartzFilter

  var filter: String {
    return quartz_filter.localizedName()
  }

  init() {
    let properties: [AnyHashable : Any] = [
      "Domains": [
        "Applications": true
      ],
      "FilterData": [
        "ColorSettings": [
          "ImageSettings": [
            "Compression Quality": -10,
            "ImageCompression": "ImageJPEGCompress",
            "ImageScaleSettings": [
              "ImageScaleFactor": 0.9
            ]
          ]
        ],
      ],
      "FilterType": 1,
      "Name": "PDFCompressSettings"
    ]
    quartz_filter = QuartzFilter(properties: properties)
  }

  func compress(_ inPath: String, out outPath: String) -> String? {
    let inURL = URL(fileURLWithPath: inPath)
    let outURL = URL(fileURLWithPath: outPath)
    return compress(inURL, out: outURL)
  }

  func compress(_ inURL: URL, out outURL: URL) -> String? {
    // Make sure input PDF file at 'inURL' is valid
    guard let inFile = PDFDocument(url: inURL) else {
      return "Input file is not a PDF document"
    }

    // Get original input PDF document at 'inURL'
    let inPDF: CGPDFDocument = inFile.documentRef!
    // Create an empty PDF document at 'outURL'
    let outPDF: CGContext = CGContext(outURL as CFURL, mediaBox: nil, nil)!

    // All PDF pages drawn after the filter is applied will be compressed
    self.quartz_filter.apply(to: outPDF)

    // Copy every page to new output document
    for index in 1...inPDF.numberOfPages {
      // Get current page and its size (bounds) from input document
      let page: CGPDFPage = inPDF.page(at: index)!
      var pageMediaBox: CGRect = page.getBoxRect(.mediaBox)

      // Redraw current page in output document
      outPDF.beginPage(mediaBox: &pageMediaBox)
      outPDF.drawPDFPage(page)
      outPDF.endPage()
    }

    // Close output document and return its location
    outPDF.closePDF()
    return nil
  }
}
