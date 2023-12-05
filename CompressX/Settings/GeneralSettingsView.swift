//
//  GeneralSettingsView.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 23/7/24.
//

import SwiftUI
import LaunchAtLogin
import UserNotifications

struct GeneralSettingsView: View {

  @AppStorage("removeFileAfterCompress") var removeFileAfterCompress = false
  @AppStorage("shouldShowRemoveFileWarning") var shouldShowRemoveFileWarning = true
  @AppStorage("notifyWhenFinish") var notifyWhenFinish = false
  @AppStorage("retainCreationDate") var retainCreationDate = false
  @AppStorage("outputFileNameFormat") var outputFileNameFormat = ""
  @AppStorage("copyOutputFilesToClipboard") var copyCompressedFilesToClipboard = false

  @State private var showOutputFileNameFormatPopover = false
  @State private var currentOutputFileNameFormat = ""

  var body: some View {
    Form {
      LaunchAtLogin.Toggle()
      VStack(alignment: .leading) {
        Toggle("Remove input files after compressing", isOn: $removeFileAfterCompress)
          .toggleStyle(.switch)
          .onChange(of: removeFileAfterCompress, perform: { newValue in
            if newValue == true, shouldShowRemoveFileWarning == true {
              shouldShowRemoveFileWarning = false
              showRemoveFileWarningAlert()
            }
          })
        Text("You can find the removed file in the Trash bin.")
          .foregroundStyle(.secondary)
      }
      Toggle("Notify when finish compressing", isOn: $notifyWhenFinish)
        .toggleStyle(.switch)
        .onChange(of: notifyWhenFinish, perform: { newValue in
          if newValue == true {
            UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .alert]) { _,_  in
            }
          }
        })
      Toggle("Copy output files to clipboard", isOn: $copyCompressedFilesToClipboard)
        .toggleStyle(.switch)
      VStack(alignment: .leading) {
        Toggle("Retain creation date", isOn: $retainCreationDate)
          .toggleStyle(.switch)
        Text("The compressed file will have the same creation date as the original file.")
          .foregroundStyle(.secondary)
      }
      VStack(alignment: .leading) {
        HStack {
          Text("Output file name format")
          Button(action: {
            showOutputFileNameFormatPopover.toggle()
          }, label: {
            Image(systemName: "exclamationmark.circle")
          })
          .buttonStyle(.bordered)
          .popover(isPresented: $showOutputFileNameFormatPopover) {
            VStack(alignment: .leading) {
              Text("Available variables:\n")
              Text("{timestamp} - Current unix timestamp")
              Text("{datetime} - Current date and time in \"yyyy-MM-dd'T'HHmmss\" format")
              Text("{date} - Current date in \"yyyy-MM-dd\" format")
              Text("{time} - Current time in \"HHmmss\" format")
            }
            .padding()
          }
        }
        HStack {
          TextField("Output file name format", text: $currentOutputFileNameFormat)
            .textFieldStyle(.squareBorder)
            .labelsHidden()
            .onSubmit {
              outputFileNameFormat = currentOutputFileNameFormat
            }
          Button(action: {
            outputFileNameFormat = currentOutputFileNameFormat
          }, label: {
            Text("Update")
          })
          .disabled(outputFileNameFormat == currentOutputFileNameFormat)
        }
        .onAppear {
          currentOutputFileNameFormat = outputFileNameFormat
        }
        VStack(alignment: .leading) {
          Text("Example: input1.mov → " + getSampleOutputFileName1())
          Text("Example: input2.mov → " + getSampleOutputFileName2())
        }
        .foregroundStyle(.secondary)
        .font(.caption)
      }
    }
    .formStyle(.grouped)
    .frame(width: 540, height: 370)
    .scrollDisabled(true)
  }

  func showRemoveFileWarningAlert() {
    let alert = NSAlert()
    alert.messageText = "Warning!"
    alert.informativeText = "Please note that the compressed video may not retain the same level of quality as the original. Therefore, it is advisable not to substitute the original video with its compressed version for storage purposes.\n\nYou can find the removed video in the Trash bin."
    alert.addButton(withTitle: "Understood")
    alert.runModal()
  }

  func getSampleOutputFileName1() -> String {
    let format = currentOutputFileNameFormat
      .replacingOccurrences(of: "{timestamp}", with: "\(Int(Date.now.timeIntervalSince1970))")
      .replacingOccurrences(of: "{datetime}", with: Date().toISO8601DateTime)
      .replacingOccurrences(of: "{date}", with: Date().toISO8601Date)
      .replacingOccurrences(of: "{time}", with: Date().toISO8601Time)
    let outputFileName = "input1" + format + ".mp4"
    return outputFileName
  }

  func getSampleOutputFileName2() -> String {
    let format = currentOutputFileNameFormat
      .replacingOccurrences(of: "{timestamp}", with: "\(Int(Date.now.timeIntervalSince1970))")
      .replacingOccurrences(of: "{datetime}", with: Date().toISO8601DateTime)
      .replacingOccurrences(of: "{date}", with: Date().toISO8601Date)
      .replacingOccurrences(of: "{time}", with: Date().toISO8601Time)
    if format.isEmpty {
      return "input2" + "_compressed.mov"
    } else {
      return "input2" + format + ".mov"
    }
  }
}
