//
//  InputFileRow.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 1/8/24.
//

import SwiftUI

struct InputFileRow: View {

  @State private var isHovering = false

  var url: URL
  var fileSize: Int64?
  var onRemove: () -> Void

  var body: some View {
    HStack(alignment: .center) {
      Text(url.lastPathComponent)
      Spacer()
      Text(fileSizeString(from: fileSize))
        .foregroundStyle(.secondary)
      if isHovering {
        Image(systemName: "xmark")
          .onTapGesture(perform: onRemove)
      }
    }
    .onHover(perform: { hovering in
      isHovering = hovering
    })
  }
}
