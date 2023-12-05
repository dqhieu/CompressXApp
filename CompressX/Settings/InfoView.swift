//
//  InfoView.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 10/15/24.
//

import SwiftUI

struct InfoView: View {

  @AppStorage("selectedAppIconName") var selectedAppIconName = "AppIcon"

  var body: some View {
    Form {
      HStack {
        Spacer()
        VStack(alignment: .center, spacing: 8) {
          Image(nsImage: (NSImage(named: selectedAppIconName))!)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 80, height: 80, alignment: .center)
          Link(destination: URL(string: "https://compressx.app/")!) {
            Text("CompressX")
              .font(.title3)
              .fontWeight(.bold)
              .foregroundStyle(
                LinearGradient(
                  colors: [Color.primary.opacity(0.7), Color.primary],
                  startPoint: .top,
                  endPoint: .bottom
                )
              )
            Image(systemName: "arrow.up.forward")
          }
          Text("Offline media compression")
          Text(appVersion)
          Link(destination: URL(string: "https://x.com/hieudinh_")!) {
            Text("© 2024 Dinh Quang Hieu")
              .foregroundStyle(
                LinearGradient(
                  colors: [Color.primary.opacity(0.7), Color.primary],
                  startPoint: .top,
                  endPoint: .bottom
                )
              )
            Image(systemName: "arrow.up.forward")
          }
          HStack {
            Link(destination: URL(string: "https://x.com/CompressXApp")!) {
              Text("Follow us on 𝕏 🤝")
            }
            Link(destination: URL(string: "https://www.producthunt.com/products/compressx/reviews/new")!) {
              Text("Leave a review on Product Hunt ⭐")
            }
          }
          HStack {
            Link(destination: URL(string: "mailto:hieu@compressx.app")!) {
              Text("Submit an issue or feature request 💌")
            }
            Link(destination: URL(string: "https://compressx.app/changelog")!) {
              Text("Changelog 📝")
            }
          }
          Link(destination: URL(string: "https://t.me/+ldb3DRPCi6Y1NWNl")!) {
            Text("Join Telegram community 💬")
          }
        }
        Spacer()
      }
    }
    .formStyle(.grouped)
    .frame(width: 540, height: 310)
    .scrollDisabled(true)
  }
}
