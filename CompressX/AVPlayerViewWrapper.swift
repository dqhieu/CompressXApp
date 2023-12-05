//
//  AVPlayerViewWrapper.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 07/02/2024.
//

import SwiftUI
import AVKit

@MainActor
class AVPlayerViewWrapper: ObservableObject {

  @Published var playerView: AVPlayerView
  @Published var isTrimming = false

  var onTrimConfirmed: ((CMTime, CMTime) -> Void)?

  init() {
    self.playerView = AVPlayerView()
    self.playerView.player = AVPlayer()
  }

  @MainActor
  func reload(player: AVPlayer, startTime: CMTime?, endTime: CMTime?) {
    self.playerView.player = player
    if let startTime = startTime {
      self.playerView.player?.currentItem?.reversePlaybackEndTime = startTime
      self.playerView.player?.seek(to: startTime)
    }
    if let endTime = endTime {
      self.playerView.player?.currentItem?.forwardPlaybackEndTime = endTime
    }
  }

  @MainActor
  func beginTrim() async {
    guard playerView.canBeginTrimming else { return }
    isTrimming = true
    let result = await playerView.beginTrimming()
    switch result {
    case .cancelButton:
      break
    case .okButton:
      let startTime = playerView.player?.currentItem?.reversePlaybackEndTime
      let endTime = playerView.player?.currentItem?.forwardPlaybackEndTime
      if let startTime = startTime, let endTime = endTime {
        onTrimConfirmed?(startTime, endTime)
      }
    @unknown default:
      break
    }
    isTrimming = false
  }
}

struct AVPlayerControllerRepresented : NSViewRepresentable {
  var player: AVPlayerView

  func makeNSView(context: Context) -> AVPlayerView {
    return player
  }

  func updateNSView(_ nsView: AVPlayerView, context: Context) {

  }
}
