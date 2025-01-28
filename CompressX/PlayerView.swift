//
//  PlayerView.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 1/17/25.
//


import SwiftUI
import AVKit

struct SingleVideoPlayerView: View {

  @Environment(\.colorScheme) var colorScheme

  @StateObject var wrapper = AVPlayerViewWrapper()
  @State var player: AVPlayer?
  @State var isHovering = false

  let file: InputFile
  @Binding var startTimes: [URL: CMTime]
  @Binding var endTimes: [URL: CMTime]

  var body: some View {
    ZStack {
      AVPlayerControllerRepresented(player: wrapper.playerView)
      if !wrapper.isTrimming {
        VStack {
          HStack {
            Button {
              Task {
                await wrapper.beginTrim()
              }
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
            .padding(8)
            Spacer()
          }
          Spacer()
        }
      }
    }
    .onHover(perform: { hover in
      isHovering = hover
    })
    .task {
      reloadPlayer(file: file)
    }
    .onChange(of: file, perform: { newValue in
      reloadPlayer(file: newValue)
    })
  }

  func reloadPlayer(file: InputFile) {
    player = AVPlayer(url: file.url)
    if let player = player {
      wrapper.reload(player: player, startTime: startTimes[file.url], endTime: endTimes[file.url])
//      player.play()
    }
    wrapper.onTrimConfirmed = { (start, end) -> Void in
      startTimes[file.url] = start
      endTimes[file.url] = end
    }
  }
}

struct PlayerView: View {

  @StateObject var wrapper = AVPlayerViewWrapper()

  @Binding var avPlayer: AVPlayer?
  @Binding var startTime: CMTime?
  @Binding var endTime: CMTime?
  @Binding var outputFormat: VideoFormat
  var shouldShowTrim: Bool
  var onTrimConfirmed: () -> Void

  init(
    player: Binding<AVPlayer?>,
    startTime: Binding<CMTime?>,
    endTime: Binding<CMTime?>,
    outputFormat: Binding<VideoFormat>,
    shouldShowTrim: Bool,
    onTrimConfirmed: @escaping () -> Void
  ) {
    self._avPlayer = player
    self._startTime = startTime
    self._endTime = endTime
    self._outputFormat = outputFormat
    self.shouldShowTrim = shouldShowTrim
    self.onTrimConfirmed = onTrimConfirmed
  }

  var body: some View {
    ZStack {
      AVPlayerControllerRepresented(player: wrapper.playerView)
    }
    .overlay(alignment: .topLeading) {
      if !wrapper.isTrimming && outputFormat != .gif && shouldShowTrim {
        Button(action: {
          Task {
            await wrapper.beginTrim()
          }
        }, label: {
          Text("\(Image(systemName: "timeline.selection")) Trim video")
        })
        .padding()
      }
    }
    .task {
      if let player = avPlayer {
        wrapper.reload(player: player, startTime: startTime, endTime: endTime)
      }
      wrapper.onTrimConfirmed = { (start, end) in
        startTime = start
        endTime = end
        onTrimConfirmed()
      }
    }
    .onChange(of: avPlayer, perform: { newValue in
      if let player = avPlayer {
        wrapper.reload(player: player, startTime: startTime, endTime: endTime)
      }
    })
  }
}
