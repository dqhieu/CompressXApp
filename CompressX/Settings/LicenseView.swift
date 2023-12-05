//
//  LicenseView.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 06/01/2024.
//

import SwiftUI

struct LicenseView: View {
  
  @ObservedObject var licenseManager = LicenseManager.shared
  @State var licenseKey = ""
  
  var body: some View {
    Form {
      if licenseManager.isValid {
        if let status = licenseManager.licenseStatus {
          VStack(alignment: .leading) {
            HStack(spacing: 0) {
              Text("License status")
              Spacer()
              Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
              Text(" Valid")
            }
          }
          HStack {
            switch status {
            case "active":
              Text("Updates available until")
              Spacer()
              Text(convertISO8601ToReadableDate(isoDate: licenseManager.expiryDate))
            case "expired":
              Text("You're no longer able to receive new updates")
              Spacer()
            default:
              EmptyView()
            }
          }
        }
        HStack(spacing: 0) {
          Text("License usage")
          Spacer()
          Text("\(licenseManager.activation_usage)/\(licenseManager.activation_limit) used")
        }
        HStack(spacing: 0) {
          Text("License key")
          Spacer(minLength: 0)
          Text(licenseManager.licenseKey)
            .textSelection(.enabled)
          Button {
            NSPasteboard.general.setString(licenseManager.licenseKey, forType: .string)
          } label: {
            Image(systemName: "doc.on.doc")
          }
          .buttonStyle(.plain)
          .padding(.leading, 4)
          .foregroundStyle(.secondary)
        }
        HStack {
          Spacer()
          Button {
            NSWorkspace.shared.open(URL(string: "https://app.lemonsqueezy.com/my-orders")!)
          } label: {
            Text("Manage license")
          }
          Button(action: {
            Task {
              await licenseManager.deactivate()
            }
          }, label: {
            Text("Unlink device") // when license expires, show something else
              .foregroundStyle(.red)
          })
          Spacer()
        }
      } else {
        VStack(alignment: .leading) {
          HStack {
            Text("Enter your license key")
            Spacer()
            Link(destination: URL(string: "https://docs.compressx.app/guides/how-to-find-your-license-key")!, label: {
              Text("How to find license key \(Image(systemName: "questionmark.circle"))")
            })
          }
          HStack {
            TextField("", text: $licenseKey, prompt: Text("XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"))
              .textFieldStyle(.squareBorder)
              .labelsHidden()
              .disabled(licenseManager.isActivating)
              .onAppear(perform: {
                licenseKey = licenseManager.licenseKey
              })
              .onChange(of: licenseKey, perform: { newValue in
                licenseKey = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
              })
            Spacer()
            if licenseManager.isActivating {
              ProgressView()
                .controlSize(.small)
            } else {
              Button {
                Task {
                  await licenseManager.activate(key: licenseKey)
                }
              } label: {
                Text("Activate")
              }
              .disabled(licenseManager.isActivating || licenseKey.isEmpty || licenseKey == licenseManager.licenseKey)
            }
          }
          if !licenseManager.activateError.isEmpty {
            Text(licenseManager.activateError)
              .foregroundStyle(.red)
          }
        }
      }
    }

    .formStyle(.grouped)
    .frame(width: 540, height: licenseManager.isValid ? 230 : !licenseManager.activateError.isEmpty ? 130 : 110)
    .scrollDisabled(true)
  }
}

#Preview {
  LicenseView()
    .formStyle(.grouped)
    .frame(width: 540, height: 260, alignment: .center)
}

