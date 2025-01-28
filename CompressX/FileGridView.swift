//
//  FileGridView.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 10/16/24.
//

import SwiftUI
import CoreMedia
import AVKit

struct FileInfoOverlay: View {

  @Environment(\.colorScheme) var colorScheme
  @Environment(\.dismiss) var dismiss

  @ObservedObject var jobManager = JobManager.shared

  let file: InputFile
  let size: CGFloat
  let isPreview: Bool
  var onRemove: () -> Void
  var onTrimPress: (() -> Void)?
  let allowTrimming: Bool
  @Binding var isTrimming: Bool
  let wrapper: AVPlayerViewWrapper?

  @State private var isHovering = false

  var body: some View {
    ZStack {
      VStack {
        HStack {
          if isPreview || isHovering {
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
            if allowTrimming && !jobManager.isRunning && !isTrimming {
              Button {
                onTrimPress?()
              } label: {
                Text("Trim video")
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
              }
              .buttonStyle(.borderless)
            }
          }
          Spacer()
          if isHovering {
            if isPreview {
              Button {
                onRemove()
              } label: {
                Image(systemName: "trash")
                  .resizable()
                  .aspectRatio(contentMode: .fit)
                  .frame(width: 16, height: 16)
                  .padding(6)
                  .background(.regularMaterial)
                  .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                  .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                      .strokeBorder(
                        colorScheme == .dark ? .white.opacity(0.3) : .black.opacity(0.1),
                        lineWidth: 1
                      )
                  )
              }
              .buttonStyle(.borderless)
              .disabled(jobManager.isRunning)
            } else {
              Button {
                wrapper?.playerView.player?.pause()
                dismiss()
                onRemove()
              } label: {
                Text("Remove")
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
              }
              .buttonStyle(.borderless)
              .disabled(jobManager.isRunning)
              Button {
                wrapper?.playerView.player?.pause()
                dismiss()
              } label: {
                Image(systemName: "xmark")
                  .padding(6)
                  .background(isHovering ? .regularMaterial : .thinMaterial)
                  .clipShape(Circle())
                  .overlay(
                    Circle()
                      .strokeBorder(
                        colorScheme == .dark ? .white.opacity(0.3) : .black.opacity(0.1),
                        lineWidth: 1
                      )
                  )
              }
              .buttonStyle(.borderless)
            }

          }
        }
        .padding(8)
        Spacer()
      }
      if isHovering {
        VStack {
          Spacer()
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
            .padding(8)
            .frame(maxWidth: size, alignment: .leading)
        }
      }
    }
    .opacity(isTrimming ? 0 : 1)
    .onHover { isHover in
      isHovering = isHover
    }
    .onDisappear {
      wrapper?.playerView.player?.pause()
    }
  }
}

struct FileGridCellView: View {

  @Environment(\.colorScheme) var colorScheme

  let file: InputFile
  let size: CGFloat
  @Binding var startTimes: [URL: CMTime]
  @Binding var endTimes: [URL: CMTime]
  var onRemove: () -> Void

  @State private var showSheet = false

  @State private var player: AVPlayer?

  var body: some View {
      ZStack {
        switch file.fileType {
        case .image:
          ImagePreviewView(file: file, size: size, onRemove: onRemove)
        case .gif:
          GifPreviewView(file: file, size: size, onRemove: onRemove)
        case .video:
          VideoPreviewView(
            file: file,
            size: size,
            startTimes: $startTimes,
            endTimes: $endTimes,
            onRemove: onRemove
          )
        case .pdf:
          PdfPreviewView(file: file, size: size, onRemove: onRemove)
        case .notSupported:
          Text("Unable to load file")
        }
      }
      .clipShape(
        RoundedRectangle(cornerRadius: 16, style: .continuous)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .strokeBorder(
            colorScheme == .dark ? .white.opacity(0.3) : .black.opacity(0.1),
            lineWidth: 1
          )
      )
    }
}

struct FileGridView: View {

  @AppStorage("thumbnailPreviewLimit") var thumbnailPreviewLimit = 50

  let inputFiles: [InputFile]
  @Binding var startTimes: [URL: CMTime]
  @Binding var endTimes: [URL: CMTime]
  var onRemoveFile: (InputFile) -> Void

  @State private var columns: [GridItem] = [
    GridItem(.flexible()),
    GridItem(.flexible()),
    GridItem(.flexible())
  ]

  var body: some View {
    if inputFiles.count > thumbnailPreviewLimit {
      VStack {
        Text("Thumbnails are not shown for more than \(thumbnailPreviewLimit) files")
        Text("You can change this settings anytime in Settings → File Management")
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    } else if inputFiles.count == 1, let file = inputFiles.last, file.fileType == .video {
      SingleVideoPlayerView(file: file, startTimes: $startTimes, endTimes: $endTimes)
    } else {
      GeometryReader { proxy in
        ScrollView(showsIndicators: false) {
          LazyVGrid(
            columns: columns,
            alignment: .center,
            spacing: 8
          ) {
            ForEach(inputFiles, id: \.self) { file in
              FileGridCellView(
                file: file,
                size: getAvailableSize(size: proxy.size),
                startTimes: $startTimes,
                endTimes: $endTimes,
                onRemove: {
                  onRemoveFile(file)
                }
              )
            }
          }
          .padding(8)
          .scrollIndicators(.hidden, axes: .vertical)
        }
        .onChange(of: proxy.size, perform: {  newValue in
          adjustColumns(to: newValue)
        })
      }
    }
  }

  func adjustColumns(to size: CGSize)  {
    if inputFiles.count == 1 {
      columns = [
        GridItem(.flexible()),
      ]
    } else if inputFiles.count == 2 {
      columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
      ]
    } else if size.width <= 600 {
      columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
      ]
    } else if size.width <= 1000 {
      columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
      ]
    } else if size.width <= 1400 {
      columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
      ]
    }
  }

  func getAvailableSize(size: CGSize) -> CGFloat {
    return (size.width - 16 - CGFloat(columns.count - 1) * 8) / CGFloat(columns.count)
  }

}
