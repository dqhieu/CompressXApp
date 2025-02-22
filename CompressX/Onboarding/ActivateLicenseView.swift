//
//  ActivateLicenseView.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 03/02/2024.
//

import SwiftUI
import UniformTypeIdentifiers

struct ActivateLicenseView: View {

  @Binding var currentStep: OnboardingStep

  @Environment(\.colorScheme) var colorScheme
  @ObservedObject var licenseManager = LicenseManager.shared
  @State var licenseKey = ""

  var body: some View {
    VStack {
      Spacer()
      if licenseManager.isValid {
        Text("You have activated your license 🥳")
          .padding()
        Button {
          withAnimation(.spring(duration: 1)) {
            currentStep = .done
          }
        } label: {
          Text("Next")
        }
        .buttonStyle(NiceButtonStyle())
      } else {
        Text("Enter your license key to continue")
        TextField("", text: $licenseKey, prompt: Text("XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"))
          .textFieldStyle(.roundedBorder)
          .multilineTextAlignment(.center)
          .labelsHidden()
          .disabled(licenseManager.isActivating)
          .onAppear(perform: {
            licenseKey = licenseManager.licenseKey
          })
          .frame(width: 400)
          .onChange(of: licenseKey, perform: { newValue in
            licenseKey = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
          })
        if licenseManager.isActivating {
          ProgressView()
            .controlSize(.small)
        } else {
          Button {
            Task {
              _ = await licenseManager.activate(key: licenseKey)
            }
          } label: {
            Text("Activate")
          }
          .buttonStyle(NiceButtonStyle())
          .disabled(licenseManager.isActivating || licenseKey.isEmpty)
        }
        if !licenseManager.activateError.isEmpty {
          Text(licenseManager.activateError)
            .foregroundStyle(redColor)
        }
        if licenseManager.activateError.contains("activation limit") {
          Link(destination: URL(string: "https://docs.compresto.app/guides/how-to-reset-your-license")!, label: {
            Text("Reset your license limit")
          })
          .buttonStyle(NiceButtonStyle())
        }
        Spacer()
        Link(destination: URL(string: "https://compresto.app/pricing")!, label: {
          Text("Purchase a license")
        })
        .buttonStyle(NiceButtonStyle())
        Link(destination: URL(string: "https://docs.compresto.app/guides/how-to-find-your-license-key")!, label: {
          Text("How to find your license \(Image(systemName: "arrow.up.forward"))")
        })
      }
      Spacer()
    }
  }

  var redColor: Color {
    switch colorScheme {
    case .dark:
      return .red
    case .light:
      return Color(hex: "#b00000")
    @unknown default:
      return .red
    }
  }
}

#Preview {
  ActivateLicenseView(currentStep: .constant(.license))
}
