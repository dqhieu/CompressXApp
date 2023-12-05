//
//  InstallationView.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 6/8/24.
//

import SwiftUI

struct InstallationView: View {

  @EnvironmentObject var installationManager: InstallationManager
  @Binding var currentStep: OnboardingStep

  var body: some View {
    VStack {
      Spacer()
      switch installationManager.state {
      case .installing, .validating, .idle:
        VStack {
          Text("We’re getting things ready for you.")
          Text("This usually takes a few minutes.")
          if case .validating = installationManager.state {
            ProgressView()
          } else {
            HStack {
              Spacer()
              ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                  .foregroundStyle(Color(nsColor: NSColor.lightGray))
                  .zIndex(0)
                RoundedRectangle(cornerRadius: 3)
                  .foregroundStyle(.blue)
                  .frame(width: max(installationManager.overallProgress * 200, 0), alignment: .leading)
                  .zIndex(1)
              }
              .frame(width: 200, height: 6)
              Text("\(Int(installationManager.overallProgress*100))%")
                .frame(width: 40)
              Spacer()
            }
          }
        }
      case .error(let error):
        VStack {
          Text("Sorry, something went wrong")
          Text(error.localizedDescription)
          Button {
            installationManager.reset()
          } label: {
            Text("Try Again")
          }
        }
      case .done:
        VStack {
          HStack {
            Spacer()
            Text("Install Complete 🎉")
            Spacer()
          }
          .padding()
          Button {
            withAnimation(.spring(duration: 1)) {
              currentStep = .license
            }
          } label: {
            Text("Next")
          }
          .buttonStyle(NiceButtonStyle())
        }
      }
      Spacer()
    }
    .task {
      if installationManager.state.isIdle {
        installationManager.downloadDependencies()
      }
    }
  }

}
