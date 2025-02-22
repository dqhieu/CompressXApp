//
//  SinglePDFPreviewView.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 2/17/25.
//

import SwiftUI

struct SinglePDFPreviewView: View {
  @Environment(\.colorScheme) var colorScheme

  let file: InputFile

  @State var isHovering = false
  @State var id = UUID()

  var body: some View {
    ZStack {
      PDFKitView(url: file.url)
        .id(id)
      VStack {
        HStack {
          Text("\(file.fileExtension) | \(file.fileSize)")
            .padding(6)
            .background(isHovering ? .regularMaterial : .thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
              RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(
                  colorScheme == .dark ? .white.opacity(0.3) : .black.opacity(0.1),
                  lineWidth: 1
                )
            )
          Spacer()
        }
        Spacer()
        HStack {
          Text("\(file.fileName)")
            .lineLimit(1)
            .padding(6)
            .background(isHovering ? .regularMaterial : .thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
              RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(
                  colorScheme == .dark ? .white.opacity(0.3) : .black.opacity(0.1),
                  lineWidth: 1
                )
            )
          Spacer()
        }
      }
      .padding(8)
    }
    .onHover(perform: { hover in
      isHovering = hover
    })
    .onChange(of: file) { newValue in
      id = UUID()
    }
  }
}

