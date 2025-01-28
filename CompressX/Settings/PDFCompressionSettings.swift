//
//  PDFCompressionSettings.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 1/4/25.
//

import SwiftUI

struct PDFCompressionSettingsView: View {

  @AppStorage("ghostscriptPath") var ghostscriptPath = ""

  @EnvironmentObject var installationManager: InstallationManager

  @FocusState private var isPathTextFieldFocused: Bool

  @State private var id = UUID()

  @State private var path = ""

  var body: some View {
    Form {
      Section {
        VStack {
          Text("Ghostscript path")
            .frame(maxWidth: .infinity, alignment: .leading)
          HStack {
            TextField("", text: $path)
              .textFieldStyle(.squareBorder)
              .labelsHidden()
              .focused($isPathTextFieldFocused)
              .id(id)
              .onAppear(perform: {
                path = ghostscriptPath
              })
            Spacer()
            Button {
              if !path.isEmpty {
                ghostscriptPath = path
              }
            } label: {
              Text("Update")
            }
            .disabled(path.isEmpty || path == ghostscriptPath)
          }
          if !ghostscriptPath.isEmpty && (ghostscriptPath.hasSuffix("bin/brew/gs") || ghostscriptPath.hasSuffix("bin/gs")) {
            Text("Ghostscript is installed")
              .frame(maxWidth: .infinity, alignment: .leading)
              .font(.caption)
          }
        }
      }
      if ghostscriptPath.isEmpty {
        Section {
          Text("Ghostscript path is not set. Please install Ghostscript and set the path in order to compress PDF files.")
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
      Section {
        HStack {
          Spacer()
          VStack {
            Button {
              path = "123"
              NSWorkspace.shared.open(URL(string: "https://docs.compressx.app/guides/how-to-setup-pdf-compression")!)
            } label: {
              Text("Read the docs")
            }
            if brewPath != nil {
              if installationManager.isInstallingGhostscript {
                HStack {
                  ProgressView()
                    .controlSize(.small)
                  Text("Ghostscript is being installed")
                    .foregroundStyle(.secondary)
                }
              } else {
                Button {
                  installationManager.installGhostscript()
                } label: {
                  Text("Install Ghostscript via Homebrew")
                }
              }
            }
          }
          Spacer()
        }
      }
      Section {
        Text("**Disclaimer**: CompressX does not own or distribute Ghostscript (https://www.ghostscript.com/). Ghostscript is installed separately on your device. CompressX only uses Ghostscript to compress PDF files.")
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .formStyle(.grouped)
    .scrollDisabled(true)
    .onChange(of: ghostscriptPath) { newValue in
      isPathTextFieldFocused = false
      path = newValue
    }
  }
  
}

#Preview {
  PDFCompressionSettingsView()
}
