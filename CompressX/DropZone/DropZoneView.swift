//
//  DropZoneView.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 4/9/24.
//

import SwiftUI

struct DropZoneView: View {

  var hasNotch: Bool
  var onClose: () -> Void

  @ObservedObject var dropZoneManager = DropZoneManager.shared

  @State private var scale = 0.5
  @State private var offset = DropZoneManager.HEIGHT
  @State private var alpha = 0.0
  @State private var blur = 20.0

  @State var leftMouseReleaseMonitor: Any?

  var body: some View {
    VStack {
      HStack(spacing: 0) {
        Spacer(minLength: 0)
          .background(.clear)
        CornerShape()
          .fill(Color.black)
          .frame(width: 12, height: DropZoneManager.HEIGHT)
        VStack {
          Spacer(minLength: 0)
            .background(.black)
          HStack {
            Spacer(minLength: 0)
            Text("Drop files here to compress")
              .foregroundStyle(.white)
              .lineLimit(1)
              .offset(x: dropZoneManager.offsetX, y: -dropZoneManager.offsetY)
              .opacity(alpha)
              .blur(radius: blur)
            Spacer(minLength: 0)
          }
          .background(.black)
        }
        .padding(.top, 8)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .background(
          UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: 16,
            bottomTrailingRadius: 16,
            topTrailingRadius: 0,
            style: .continuous
          )
          .fill(Color.black)
        )
        .frame(width: DropZoneManager.WIDTH - 24)
        CornerShape()
          .fill(Color.black)
          .frame(width: 12, height: DropZoneManager.HEIGHT)
          .rotation3DEffect(
            .degrees(180),
            axis: (x: 0.0, y: 1.0, z: 0.0)
          )
        Spacer(minLength: 0)
          .background(.clear)
      }
      Spacer(minLength: 0)
        .background(.clear)
    }
    .scaleEffect(scale)
    .offset(x: 0, y: -offset)
    .dropDestination(for: URL.self) { items, location in
      return onDropFiles(items: items)
    }
    .task {
      appear()
    }
  }

  func onDropFiles(items: [URL]) -> Bool {
    DropZoneManager.shared.queueJob(inputFileURLs: items)
    return true
  }

  func appear() {
    withAnimation(.spring()) {
      scale = 1.0
      offset = 0
    }
    withAnimation(.spring().delay(0.1)) {
      alpha = 1.0
      blur = 0.0
    }

    leftMouseReleaseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { _ in
      dismiss()
    }
  }

  func dismiss() {
    if let monitor = leftMouseReleaseMonitor {
      NSEvent.removeMonitor(monitor)
      leftMouseReleaseMonitor = nil
    }
    withAnimation(.spring()) {
      if hasNotch {
        scale = 0.5
        offset = DropZoneManager.HEIGHT
      } else {
        scale = 0.01
        offset = DropZoneManager.HEIGHT
      }
      alpha = 0.0
      blur = 20
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      onClose()
    }
  }
}
