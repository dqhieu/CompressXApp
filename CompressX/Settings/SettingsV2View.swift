//
//  SettingsV2View.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 12/21/24.
//

import SwiftUI
import Sparkle

enum Setting: String, CaseIterable{
  case general
  case advanced
  case fileManagement
  case appearance
  case monitoring
  case dropZone
  case pdfCompression
  case license
  case credits
  case softwareUpdate
  case about

  var displayText: String {
    switch self {
    case .general:
      return "General"
    case .advanced:
      return "Advanced"
    case .fileManagement:
      return "File Management"
    case .appearance:
      return "Appearance"
    case .softwareUpdate:
      return "Software Update"
    case .monitoring:
      return "Monitoring"
    case .dropZone:
      return "Drop Zone"
    case .pdfCompression:
      return "PDF Compression"
    case .license:
      return "License"
    case .credits:
      return "Credits"
    case .about:
      return "About"
    }
  }

  var symbolName: String {
    switch self {
    case .general:
      return "gearshape"
    case .advanced:
      return "slider.horizontal.3"
    case .fileManagement:
      return "doc.badge.gearshape"
    case .appearance:
      return "wand.and.stars"
    case .softwareUpdate:
      return "arrow.triangle.2.circlepath.circle"
    case .monitoring:
      return "eyes"
    case .dropZone:
      return "doc.viewfinder"
    case .pdfCompression:
      return "doc.append"
    case .license:
      return "key"
    case .credits:
      return "c.circle"
    case .about:
      return "info.circle"
    }
  }
}

struct SettingsV2View: View {

  @EnvironmentObject var installationManager: InstallationManager
  @State private var currentSetting: Setting = .general
  @State private var hoveringSetting: Setting?

  private let updater: SPUUpdater

  init(updater: SPUUpdater) {
    self.updater = updater
  }

  var body: some View {
    HStack(alignment: .top, spacing: 0) {
      VStack {
        ForEach(Setting.allCases, id: \.self) { setting in
          Button {
            if #available(macOS 14.0, *) {
              withAnimation {
                currentSetting = setting
              }
            } else {
              currentSetting = setting
            }
          } label: {
            HStack {
              if #available(macOS 15.0, *) {
                Image(systemName: setting.symbolName)
                  .symbolEffect(.bounce.byLayer, options: .nonRepeating, isActive: currentSetting == setting)
                  .frame(width: 16, height: 16, alignment: .center)
              } else {
                Image(systemName: setting.symbolName)
                  .frame(width: 16, height: 16, alignment: .center)
              }
              Text(setting.displayText)
              Spacer()
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.001))
          }
          .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
              .foregroundStyle(hoveringSetting == setting ? Color.secondary.opacity(0.15) : currentSetting == setting ? Color.secondary.opacity(0.2) : .clear)
          )
          .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
              .stroke(currentSetting == setting ? Color.secondary.opacity(0.5) : .clear, lineWidth: 1)
          )
          .buttonStyle(.plain)
          .onHover { isHovering in
            if #available(macOS 14.0, *) {
              withAnimation {
                if isHovering {
                  hoveringSetting = setting
                } else {
                  hoveringSetting = nil
                }
              }
            }
          }
          if setting == .credits {
            Spacer()
          }
        }
      }
      .frame(width: 160)
      .padding()
      VStack {
        Group {
          switch currentSetting {
          case .general:
            GeneralSettingsV2View()
          case .advanced:
            AdvancedSettingsV2View()
          case .fileManagement:
            FileManagementSettingsView()
          case .appearance:
            AppearanceSettingsV2View()
          case .monitoring:
            MonitoringSettingsView()
          case .dropZone:
            DropZoneSettingsV2View()
          case .pdfCompression:
            PDFCompressionSettingsView()
              .environmentObject(installationManager)
          case .license:
            LicenseSettingsV2View()
          case .credits:
            CreditsSettingsView()
          case .softwareUpdate:
            UpdateSettingsV2View(updater: updater)
          case .about:
            AboutSettingsView()
          }
        }
        Spacer()
      }
      .background(.regularMaterial)
      .animation(nil, value: currentSetting)
    }
    .background(VisualEffectView().ignoresSafeArea())
    .frame(width: 640, height: 500)
    .fontDesign(.rounded)
  }
}

struct SettingsViewModifier: ViewModifier {
  func body(content: Content) -> some View {
    if #available(macOS 14, *) {
      content
        .background(SettingsWindowConfigurator())
    } else {
      content
    }
  }
}
