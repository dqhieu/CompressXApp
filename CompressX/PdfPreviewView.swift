//
//  PdfPreviewView.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 1/4/25.
//

import SwiftUI
import PDFKit

struct PdfView: View {

  let file: InputFile
  var onRemove: () -> Void

  var size: CGSize {
    if let contentView = NSApp.keyWindow?.contentView {
      return CGSize(width: contentView.bounds.width * 3 / 4, height: contentView.bounds.height)
    }
    return CGSize(width: 600, height: 800)
  }

  var body: some View {
    ZStack {
      PDFKitView(url: file.url)
//        .frame(minWidth: 600, minHeight: 800)
//      FileInfoOverlay(
//        file: file,
//        size: size.width,
//        isPreview: false,
//        onRemove: onRemove,
//        allowTrimming: false,
//        isTrimming: .constant(false),
//        wrapper: nil
//      )
    }
    .frame(minWidth: 600, minHeight: 800)
  }
}

struct PdfPreviewView: View {

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
      Image(systemName: "arrow.up.backward.and.arrow.down.forward.circle.fill")
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
      PdfView(file: file, onRemove: onRemove)
    }
    .task {
      loadThumbnail()
    }
  }

  func loadThumbnail() {
    Task(priority: .utility) {
      guard let pdfDocument = PDFDocument(url: file.url) else { return }
      guard let pdfPage = pdfDocument.page(at: 0) else { return }

      let pageRect = pdfPage.bounds(for: .mediaBox)
      let thumbnailSize = NSApp.keyWindow?.contentView?.bounds.size ?? NSSize(width: size, height: size)

      // Create a new image context
      let imageRepresentation = NSImage(size: thumbnailSize)
      imageRepresentation.lockFocus()

      // Fill background with white
      NSColor.white.setFill()
      NSRect(origin: .zero, size: thumbnailSize).fill()

      // Scale and center the PDF page
      let scale = min(thumbnailSize.width / pageRect.width,
                      thumbnailSize.height / pageRect.height)

      let transform = NSAffineTransform()
      transform.translateX(by: (thumbnailSize.width - pageRect.width * scale) / 2,
                           yBy: (thumbnailSize.height - pageRect.height * scale) / 2)
      transform.scale(by: scale)
      transform.concat()

      // Draw the PDF page
      pdfPage.draw(with: .mediaBox, to: NSGraphicsContext.current!.cgContext)

      imageRepresentation.unlockFocus()

      await MainActor.run {
        self.thumbnail = imageRepresentation
      }
    }
  }
}

struct PDFKitView: NSViewRepresentable {
  let url: URL

  func makeNSView(context: Context) -> PDFView {
    let pdfView = PDFView()
    pdfView.document = PDFDocument(url: url)
    pdfView.autoScales = true
    return pdfView
  }

  func updateNSView(_ nsView: PDFView, context: Context) {
    nsView.document = PDFDocument(url: url)
  }
}
