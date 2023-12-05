//
//  GIFImage.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 3/4/24.
//

import SwiftUI
import WebKit
import AppKit

struct GIFImage: NSViewRepresentable {
  private let url: URL

  init(url: URL) {
    self.url = url
  }

  func makeNSView(context: Context) -> WKWebView {
    let webView = WKWebView()
    webView.window?.backgroundColor = NSColor.clear
    webView.loadFileURL(url, allowingReadAccessTo: url)
    webView.allowsMagnification = false
    if let image = NSImage(contentsOf: url) {
      webView.heightAnchor.constraint(equalTo: webView.widthAnchor, multiplier: image.size.height / image.size.width).isActive = true
    }
    return webView
  }

  func updateNSView(_ nsView: WKWebView, context: Context) {
  }
}
