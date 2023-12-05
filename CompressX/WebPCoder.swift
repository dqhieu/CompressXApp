//
//  WebPCoder.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 15/4/24.
//

import Foundation
import SDWebImage
import SDWebImageWebPCoder

class WebPCoder {

  static let shared = WebPCoder()

  func convert(inputURL: URL, outputURL: URL, imageQuality: ImageQuality, imageDimension: ImageDimension) -> String? {
    guard var image = NSImage(contentsOf: inputURL) else {
      return "Failed to load image"
    }
    let newSize: CGSize = {
      if let imageRep = NSImageRep(contentsOf: inputURL), imageRep.pixelsWide > 0, imageRep.pixelsHigh > 0 {
        return CGSize(
          width: Double(imageRep.pixelsWide) * imageDimension.fraction,
          height: Double(imageRep.pixelsHigh) * imageDimension.fraction
        )
      }
      return CGSize(
        width: image.size.width * image.scale * imageDimension.fraction,
        height: image.size.height * image.scale * imageDimension.fraction
      )
    }()
    image = image.resized(to: newSize)
    let options = [SDImageCoderOption.encodeCompressionQuality: imageQuality.webPImageQualityLevel]
    let webPCoder = SDImageWebPCoder.shared

    if let webpData = webPCoder.encodedData(with: image, format: .webP, options: options) {
      do {
        try webpData.write(to: outputURL)
        return nil
      } catch {
        return "Failed to write WebP image: \(error)"
      }
    } else {
      return "Failed to encode WebP image"
    }
  }

  func testWebP() {
    let inputURL = URL(fileURLWithPath: "/Users/hieudinh/Desktop/codec.png")
    let outputURL = URL(fileURLWithPath: "/Users/hieudinh/Desktop/codec.webp")
    guard let image = NSImage(contentsOf: inputURL) else {
      print("Failed to load image from path")
      return
    }
    let options = [SDImageCoderOption.encodeCompressionQuality: 0.8]
    let webPCoder = SDImageWebPCoder.shared

    if let webpData = webPCoder.encodedData(with: image, format: .webP, options: options) {
      do {
        try webpData.write(to: outputURL)
        print("Successfully saved WebP to \(outputURL.path(percentEncoded: false))")
      } catch {
        print("Failed to write WebP image: \(error)")
      }
    } else {
      print("Failed to encode WebP image")
    }
  }
}