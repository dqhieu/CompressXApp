//
//  VisualEffectView.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 6/8/24.
//

import SwiftUI

struct VisualEffectView: NSViewRepresentable {

  var material: NSVisualEffectView.Material

  init(_ material: NSVisualEffectView.Material = .menu) {
    self.material = material
  }

  func makeNSView(context: Context) -> NSVisualEffectView {
    let view = NSVisualEffectView()

    view.blendingMode = .behindWindow
    view.state = .active
    view.material = material

    return view
  }

  func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
    //
  }
}
