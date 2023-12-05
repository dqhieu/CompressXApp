//
//  CreditsSettingsView.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 12/21/24.
//

import SwiftUI

struct OpenSourceLibrary: Identifiable {
  var id = UUID().uuidString
  var name: String
  var url: String
}

struct CreditsSettingsView: View {

  var libs: [OpenSourceLibrary] = [
    OpenSourceLibrary(name: "FFmpeg", url: "ffmpeg.org"),
    OpenSourceLibrary(name: "pngquant", url: "pngquant.org"),
    OpenSourceLibrary(name: "Gifski", url: "gif.ski"),
    OpenSourceLibrary(name: "Sparkle", url: "github.com/sparkle-project/Sparkle"),
    OpenSourceLibrary(name: "TelemetryClient", url: "github.com/TelemetryDeck/SwiftClient"),
    OpenSourceLibrary(name: "SettingsAccess", url: "github.com/orchetect/SettingsAccess"),
    OpenSourceLibrary(name: "SwiftDate", url: "github.com/malcommac/SwiftDate"),
    OpenSourceLibrary(name: "DockProgress", url: "github.com/sindresorhus/DockProgress"),
    OpenSourceLibrary(name: "LaunchAtLogin", url: "github.com/sindresorhus/LaunchAtLogin-Modern"),
    OpenSourceLibrary(name: "SDWebImageWebPCoder", url: "github.com/SDWebImage/SDWebImageWebPCoder"),
    OpenSourceLibrary(name: "KeyboardShortcuts", url: "github.com/sindresorhus/KeyboardShortcuts"),
    OpenSourceLibrary(name: "SwiftDraw", url: "github.com/swhitty/SwiftDraw"),
  ]

  var body: some View {
    Form {
      Section {
        ForEach(libs) { lib in
          HStack {
            Text(lib.name)
            Spacer()
            Link(destination: URL(string: "https://" + lib.url)!) {
              HStack {
                Text(lib.url)
                Image(systemName: "arrow.up.right.square")
              }
            }
          }
        }
      } header: {
        Text("CompressX is powered by awesome open source projects. Special thanks to:")
      }

    }
    .formStyle(.grouped)
//    .scrollDisabled(true)
  }
}
