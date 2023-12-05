//
//  ImagePreviewView.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 10/23/24.
//

import SwiftUI

struct ImageView: View {

  @Environment(\.dismiss) var dismiss
  @Environment(\.colorScheme) var colorScheme

  let file: InputFile
  let image: NSImage?
  var onRemove: () -> Void

  var size: CGSize {
    let fallbackWidth: CGFloat = NSApp.keyWindow?.contentView?.bounds.width ?? 500
    let fallbackHeight: CGFloat = NSApp.keyWindow?.contentView?.bounds.height ?? 500
    if let image = image {
      if image.size.height < fallbackHeight {
        return image.size
      }
      return CGSize(width: fallbackHeight * image.size.width / image.size.height, height: fallbackHeight)
    }
    return CGSize(width: fallbackWidth, height: fallbackHeight)
  }

  var body: some View {
    ZStack {
      if let image = image {
        Image(nsImage: image)
          .resizable()
          .aspectRatio(contentMode: .fit)
      } else {
        ProgressView()
      }
      FileInfoOverlay(
        file: file,
        size: size.width,
        isPreview: false,
        onRemove: onRemove,
        onTrimPress: nil,
        allowTrimming: false,
        isTrimming: .constant(false),
        wrapper: nil
      )
    }
    .frame(width: size.width, height: size.height)
  }
}

struct ImagePreviewView: View {

  let file: InputFile
  let size: CGFloat
  var onRemove: () -> Void

  @State private var thumbnail: NSImage?
  @State private var image: NSImage?

  @State private var show = false

  var body: some View {
    ZStack {
      if let image = thumbnail {
        Image(nsImage: image)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(width: size, height: size)
          .clipped()
      } else {
        ProgressView()
      }
      FileInfoOverlay(
        file: file,
        size: size,
        isPreview: true,
        onRemove: onRemove,
        onTrimPress: nil,
        allowTrimming: false,
        isTrimming: .constant(false),
        wrapper: nil
      )
      .frame(width: size, height: size)
    }
    .frame(width: size, height: size)
    .onTapGesture {
      show.toggle()
    }
    .sheet(isPresented: $show) {
      ImageView(file: file, image: image, onRemove: onRemove)
    }
    .task {
      Task(priority: .utility) {
        if let nsImage = NSImage(contentsOf: file.url) {
          if let fileSize = file.url.fileSize, fileSize >= 25_000_000 {
            let size = nsImage.size
            let resizedImage = nsImage.resized(to: NSSize(width: 1024, height: 1024 * size.height / size.width))
            await MainActor.run {
              thumbnail = resizedImage.squareCrop()
              image = nsImage
            }
          } else {
            await MainActor.run {
              thumbnail = nsImage.squareCrop()
              image = nsImage
            }
          }
        }
      }
    }
  }
}

