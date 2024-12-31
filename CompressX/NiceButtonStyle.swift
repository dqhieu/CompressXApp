//
//  NiceButtonStyle.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 12/6/24.
//

import SwiftUI

struct NiceButtonStyle: ButtonStyle {

  @Environment(\.colorScheme) var colorScheme

  @State var isHovering = false

  var backgroundColor: Color {
    switch colorScheme {
    case .light:
      return .offWhite
    case .dark:
      return Color(hex: "E1E0DD")
    @unknown default:
      return .white
    }
  }

  var outterShadowColor: Color {
    switch colorScheme {
    case .light:
      return .primary.opacity(0.1)
    case .dark:
      return .clear
    @unknown default:
      return .white
    }
  }

  var borderColor: Color {
    switch colorScheme {
    case .light:
      return .white.opacity(0.7)
    case .dark:
      return .white.opacity(0.1)
    @unknown default:
      return .white
    }
  }

  var textHoverColor: Color {
    switch colorScheme {
    case .dark: .black
    case .light: .primary
    @unknown default: .primary
    }
  }

  var textNonHoverColor: Color {
    switch colorScheme {
    case .dark: .blue
    case .light: .blue
    @unknown default: .blue
    }
  }

  func makeBody(configuration: Configuration) -> some View {
    ZStack {
      configuration
        .label
        .foregroundColor(isHovering ? textHoverColor : textNonHoverColor)
        .fontWeight(.bold)
        .fontDesign(.rounded)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .background(
      RoundedRectangle(
        cornerRadius: 12,
        style: .continuous
      )
      .fill(backgroundColor)
      .clipShape(RoundedRectangle(
        cornerRadius: 12,
        style: .continuous
      ))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(borderColor, lineWidth: 1)
    )
    .shadow(color: outterShadowColor, radius: 4, x: 0, y: 2)
    .scaleEffect(configuration.isPressed ? 0.95 : isHovering ? 1.02 : 1.0)
    .animation(.spring(), value: configuration.isPressed)
    .onHover(perform: { hovering in
      withAnimation {
        isHovering = hovering
      }
    })
  }
}

extension Color {
  init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int = UInt64()
    Scanner(string: hex).scanHexInt64(&int)
    let a, r, g, b: UInt64
    switch hex.count {
    case 3: // RGB (12-bit)
      (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6: // RGB (24-bit)
      (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8: // ARGB (32-bit)
      (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
      (a, r, g, b) = (255, 0, 0, 0)
    }
    self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue:  Double(b) / 255, opacity: Double(a) / 255)
  }

  static let offWhite = Color(hex: "#FAF9F6")
  static let offBlack = Color(hex: "#303030")
}
