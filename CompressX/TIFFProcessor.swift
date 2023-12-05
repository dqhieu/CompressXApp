//
//  TIFFProcessor.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 6/7/24.
//

import Foundation
import AppKit

class TIFFProcessor {
  static func compress(job: Job, imageQuality: ImageQuality, imageFormat: ImageFormat, imageDimension: ImageDimension) -> String? {
    let newSize: NSSize? = {
      if let imageRep = NSImageRep(contentsOf: job.inputFileURL), imageRep.pixelsWide > 0, imageRep.pixelsHigh > 0 {
        return NSSize(
          width: Double(imageRep.pixelsWide) * imageDimension.fraction,
          height: Double(imageRep.pixelsHigh) * imageDimension.fraction
        )
      }
      return nil
    }()
    let nsImage = NSImage(contentsOf: job.inputFileURL)?.resized(to: newSize)
    if let data = nsImage?.tiffRepresentation(using: NSBitmapImageRep.TIFFCompression.ccittfax4, factor: Float(imageQuality.svgImageQualityLevel)) {
      do {
        try data.write(to: job.outputFileURL)
      } catch {
        return String(describing: error)
      }
    }
    return "Failed to initialize TIFF"
  }
}
