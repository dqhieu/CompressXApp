//
//  StartView.swift
//  Onboarding
//
//  Created by Dinh Quang Hieu on 3/8/24.
//

import SwiftUI

struct StartView: View {

  @Binding var currentStep: OnboardingStep

  @State private var opacity = 0.0

  var body: some View {
    VStack {
      Spacer()
      VStack {
        if let iconImage = NSImage(named: "AppIcon") {
          Image(nsImage: iconImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 96, height: 96, alignment: .center)
        }

        Text("Welcome to")
        Text("CompressX")
          .font(.largeTitle)
          .fontWeight(.bold)
          .foregroundStyle(
            LinearGradient(
              colors: [Color.primary.opacity(0.7), Color.primary],
              startPoint: .top,
              endPoint: .bottom
            )
          )
        Text("The ultimate offline media compression tool")
          .padding(.top, 2)
        Button {
          withAnimation(.spring(duration: 1)) {
            currentStep = .installation
          }
        } label: {
          Text("Get Started")
        }
        .buttonStyle(NiceButtonStyle())
        .padding()
      }
      .opacity(opacity)
      .transition(.move(edge: .top).combined(with: .opacity))
      Spacer()
    }
    .task {
      withAnimation(.spring(duration: 3)) {
        opacity = 1
      }
    }
  }
}
