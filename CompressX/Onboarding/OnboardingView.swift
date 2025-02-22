//
//  OnboardingView.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 6/8/24.
//

import SwiftUI

struct OnboardingView: View {

  @AppStorage("shouldShowOnboardingV2") var shouldShowOnboardingV2 = true

  @State private var currentStep: OnboardingStep = .start
  @State private var allSteps: [OnboardingStep] = [
    .start,
    .installation,
    .license,
    .done
  ]

  @State private var stepOpacity = 0.0

  var body: some View {
    VStack(spacing: 0) {
      switch currentStep {
      case .start:
        StartView(currentStep: $currentStep)
          .transition(
            .asymmetric(
              insertion: .move(edge: .trailing).combined(with: .opacity),
              removal: .move(edge: .leading).combined(with: .opacity)
            )
          )
      case .installation:
        InstallationView(currentStep: $currentStep)
          .transition(
            .asymmetric(
              insertion: .move(edge: .trailing).combined(with: .opacity),
              removal: .move(edge: .leading).combined(with: .opacity)
            )
          )
      case .license:
        ActivateLicenseView(currentStep: $currentStep)
          .transition(
            .asymmetric(
              insertion: .move(edge: .trailing).combined(with: .opacity),
              removal: .move(edge: .leading).combined(with: .opacity)
            )
          )
      case .done:
        VStack {
          Spacer()
          if let iconImage = NSImage(named: "AppIcon") {
            Image(nsImage: iconImage)
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 80, height: 80, alignment: .center)
          }
          Text("Well done! You have finished the onboarding 🚀")
          Text("Learn more about Compresto features in our comprehensive [documentation](https://docs.compresto.app)")
          Button {
            shouldShowOnboardingV2 = false
          } label: {
            Text("Continue")
          }
          .buttonStyle(NiceButtonStyle())
          .padding()
          Spacer()
        }
          .transition(
            .asymmetric(
              insertion: .move(edge: .trailing).combined(with: .opacity),
              removal: .move(edge: .leading).combined(with: .opacity)
            )
          )
      }
      Spacer(minLength: 0)
      Divider()
        .opacity(stepOpacity)
      VStack(spacing: 0) {
        Spacer()
        HStack(spacing: 8) {
          Spacer()
          ForEach(0..<allSteps.count, id: \.self) { index in
            OnboardingStepView(allSteps: allSteps, index: index, currentStep: $currentStep)
            if index < allSteps.count - 1 {
              Text("→")
            }
          }
          Spacer()
        }
        Spacer()
      }
      .background(.thickMaterial)
      .frame(height: 59)
      .opacity(stepOpacity)
    }
    .background(VisualEffectView().ignoresSafeArea())
    .frame(width: 600, height: 400, alignment: .center)
    .fontDesign(.rounded)
    .task {
      try? await Task.sleep(nanoseconds: 1_000_000_000)
      withAnimation(.spring(duration: 2)) {
        stepOpacity = 1.0
      }
    }
  }

}
