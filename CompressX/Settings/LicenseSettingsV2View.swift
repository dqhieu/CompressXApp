//
//  LicenseSettingsV2View.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 12/21/24.
//

import SwiftUI

struct LicenseSettingsV2View: View {

  @ObservedObject var licenseManager = LicenseManager.shared
  @State var licenseKey = ""

  var body: some View {
    Form {
      if !licenseManager.licenseKey.isEmpty {
        if let status = licenseManager.licenseStatus {
          VStack(alignment: .leading) {
            HStack(spacing: 0) {
              Text("License status")
              Spacer()
              if licenseManager.isSubscription {
                if licenseManager.licenseStatus == "active" {
                  Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                  Text(" Active")
                } else if licenseManager.licenseStatus == "expired" {
                  Image(systemName: "calendar.badge.exclamationmark").foregroundStyle(.red)
                  Text(" Expired")
                } else {
                  Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                  Text(" \(licenseManager.licenseStatus ?? "Unknown")")
                }
              } else {
                Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                Text(" Valid")
              }
              if licenseManager.isValidating {
                ProgressView()
                  .controlSize(.small)
                  .padding(.leading, 4)
              } else {
                Button {
                  Task {
                    await licenseManager.validate()
                  }
                } label: {
                  Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .padding(.leading, 4)
                .foregroundStyle(.secondary)
                .help("Refresh license status")
              }
            }
          }
          if !licenseManager.isSubscription {
            HStack {
              switch status {
              case "active":
                Text("Updates available until")
                Spacer()
                Text(convertISO8601ToReadableDate(isoDate: licenseManager.expiryDate))
              case "expired":
                Text("You're no longer able to receive new updates")
                Spacer()
                Button {
                  let licenseKey = licenseManager.licenseKey
                  let productID = licenseManager.productID
                  let url = "https://compressx.app/license-renew?license-key=\(licenseKey)&product-id=\(productID)"
                  NSWorkspace.shared.open(URL(string: url)!)
                } label: {
                  Text("Renew license")
                }
              default:
                EmptyView()
              }
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
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(licenseManager.licenseKey, forType: .string)
          } label: {
            Image(systemName: "doc.on.doc")
          }
          .buttonStyle(.plain)
          .padding(.leading, 4)
          .foregroundStyle(.secondary)
        }
        if !licenseManager.customerEmail.isEmpty {
          HStack(spacing: 0) {
            Text("Email")
            Spacer(minLength: 0)
            Text(licenseManager.customerEmail)
              .textSelection(.enabled)
            Button {
              NSPasteboard.general.clearContents()
              NSPasteboard.general.setString(licenseManager.customerEmail, forType: .string)
            } label: {
              Image(systemName: "doc.on.doc")
            }
            .buttonStyle(.plain)
            .padding(.leading, 4)
            .foregroundStyle(.secondary)
          }
        }
        HStack {
          Spacer()
          if licenseManager.isSubscription {
            Button {
              NSWorkspace.shared.open(URL(string: "https://compressx.lemonsqueezy.com/billing")!)
            } label: {
              Text("Manage billing")
            }
          }
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
              .buttonStyle(.borderedProminent)
              .disabled(shouldDisableActivateButton)
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
    .scrollDisabled(true)
  }

  var shouldDisableActivateButton: Bool {
    return licenseManager.isActivating || licenseKey.isEmpty || licenseKey == licenseManager.licenseKey
  }
}
