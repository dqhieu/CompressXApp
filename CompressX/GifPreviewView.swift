//
//  GifPreviewView.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 10/23/24.
//

import SwiftUI

struct GifView: View {

  @Environment(\.dismiss) var dismiss
  @Environment(\.colorScheme) var colorScheme

  let file: InputFile
  var onRemove: () -> Void

  var size: CGSize {
    let fallbackWidth: CGFloat = NSApp.keyWindow?.contentView?.bounds.width ?? 500
    let fallbackHeight: CGFloat = NSApp.keyWindow?.contentView?.bounds.height ?? 500
    if let image = NSImage(contentsOf: file.url) {
      if image.size.height < fallbackHeight {
        return image.size
      }
      return CGSize(width: fallbackHeight * image.size.width / image.size.height, height: fallbackHeight)
    }
    return CGSize(width: fallbackWidth, height: fallbackHeight)
  }

  var body: some View {
    ZStack {
      GIFImage(url: file.url)
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

struct GifPreviewView: View {
  let file: InputFile
  let size: CGFloat
  var onRemove: () -> Void

  @State private var show = false
  @State private var thumbnail: NSImage?

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
      Image(systemName: "play.circle.fill")
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(width: 48, height: 48)
        .padding(2)
        .background(.regularMaterial)
        .clipShape(Circle())
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
      GifView(file: file, onRemove: onRemove)
    }
    .task {
      Task(priority: .utility) {
        if let nsImage = NSImage(contentsOf: file.url) {
          if let fileSize = file.url.fileSize, fileSize >= 25_000_000 {
            let size = nsImage.size
            let resizedImage = nsImage.resized(to: NSSize(width: 1024, height: 1024 * size.height / size.width))
            await MainActor.run {
              thumbnail = resizedImage.squareCrop()
            }
          } else {
            await MainActor.run {
              thumbnail = nsImage.squareCrop()
            }
          }
        }
      }
    }
  }
}

