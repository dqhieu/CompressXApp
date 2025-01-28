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
        Link(destination: URL(string: "https://compressx.app")!) {
          HStack {
            Text("compressx.app")
            Image(systemName: "arrow.up.right.square")
          }
        }
      }
      HStack {
        Text("Changelog")
        Spacer()
        Link(destination: URL(string: "https://compressx.app/changelog")!) {
          HStack {
            Text("compressx.app/changelog")
            Image(systemName: "arrow.up.right.square")
          }
        }
      }
      HStack {
        Text("Documentation")
        Spacer()
        Link(destination: URL(string: "https://docs.compressx.app")!) {
          HStack {
            Text("docs.compressx.app")
            Image(systemName: "arrow.up.right.square")
          }
        }
      }
      HStack {
        Text("Support email")
        Spacer()
        Link(destination: URL(string: "mailto:hieu@compressx.app")!) {
          HStack {
            Text("hieu@compressx.app")
            Image(systemName: "arrow.up.right.square")
          }
        }
      }
      HStack {
        Text("𝕏")
        Spacer()
        Link(destination: URL(string: "https://x.com/CompressXApp")!) {
          HStack {
            Text("x.com/CompressXApp")
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
        Link(destination: URL(string: "https://github.com/dqhieu/CompressXApp")!) {
          HStack {
            Text("github.com/dqhieu/CompressXApp")
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
