//
//  AboutSettingsView.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 12/21/24.
//

import SwiftUI

struct AboutSettingsView: View {

  var body: some View {
    Form {
      HStack {
        Text("Website")
        Spacer()
        Link(destination: URL(string: "https://compresto.app")!) {
          HStack {
            Text("compresto.app")
            Image(systemName: "arrow.up.right.square")
          }
        }
      }
      HStack {
        Text("Changelog")
        Spacer()
        Link(destination: URL(string: "https://compresto.app/changelog")!) {
          HStack {
            Text("compresto.app/changelog")
            Image(systemName: "arrow.up.right.square")
          }
        }
      }
      HStack {
        Text("Documentation")
        Spacer()
        Link(destination: URL(string: "https://docs.compresto.app")!) {
          HStack {
            Text("docs.compresto.app")
            Image(systemName: "arrow.up.right.square")
          }
        }
      }
      HStack {
        Text("Support email")
        Spacer()
        Link(destination: URL(string: "mailto:hieu@compresto.app")!) {
          HStack {
            Text("hieu@compresto.app")
            Image(systemName: "arrow.up.right.square")
          }
        }
      }
      HStack {
        Text("𝕏")
        Spacer()
        Link(destination: URL(string: "https://x.com/ComprestoApp")!) {
          HStack {
            Text("x.com/ComprestoApp")
            Image(systemName: "arrow.up.right.square")
          }
        }
      }
      HStack {
        Text("Telegram")
        Spacer()
        Link(destination: URL(string: "https://t.me/+ldb3DRPCi6Y1NWNl")!) {
          HStack {
            Text("t.me/+ldb3DRPCi6Y1NWNl")
            Image(systemName: "arrow.up.right.square")
          }
        }
      }
      HStack {
        Text("Github")
        Spacer()
        Link(destination: URL(string: "https://github.com/dqhieu/ComprestoApp")!) {
          HStack {
            Text("github.com/dqhieu/ComprestoApp")
            Image(systemName: "arrow.up.right.square")
          }
        }
      }
      HStack {
        Text("Raycast extension")
        Spacer()
        Link(destination: URL(string: "https://www.raycast.com/hieudinh/compressx")!) {
          HStack {
            Text("raycast.com/hieudinh/compressx")
            Image(systemName: "arrow.up.right.square")
          }
        }
      }
      HStack {
        Text("App version")
        Spacer()
        Text(appVersion)
      }
    }
    .formStyle(.grouped)
  }
}
