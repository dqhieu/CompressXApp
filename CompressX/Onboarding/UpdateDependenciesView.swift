//
//  UpdateDependenciesView.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 22/8/24.
//

import SwiftUI

struct UpdateDependenciesView: View {

  @EnvironmentObject var installationManager: InstallationManager

  var body: some View {
    VStack {
      Spacer()
      HStack {
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
              installationManager.downloadMissingDependencies()
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
          }
        }
        Spacer()
      }
      Spacer()
    }
    .background(VisualEffectView().ignoresSafeArea())
    .frame(width: 600, height: 340, alignment: .center)
    .fontDesign(.rounded)
    .task {
      if installationManager.state.isIdle || installationManager.state.isDone {
        installationManager.downloadMissingDependencies()
      }
    }
  }
}
