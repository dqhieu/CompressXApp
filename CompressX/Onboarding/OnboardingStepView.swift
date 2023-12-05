//
//  OnboardingStepView.swift
//  Onboarding
//
//  Created by Dinh Quang Hieu on 3/8/24.
//

import SwiftUI

struct OnboardingStepView: View {

  var allSteps: [OnboardingStep]
  var index: Int
  @Binding var currentStep: OnboardingStep

  @State private var isHover = false

  var isCurrentStep: Bool {
    return allSteps.firstIndex(of: currentStep) == index
  }

  var isPastStep: Bool {
    return index < (allSteps.firstIndex(of: currentStep) ?? -1)
  }

  var isUpcomingStep: Bool {
    return index > (allSteps.firstIndex(of: currentStep) ?? -1)
  }

  var body: some View {
    HStack(spacing: 12) {
      if #available(macOS 14.0, *) {
        Image(systemName: isPastStep ? "checkmark.circle.fill" : "\(index+1).circle.fill")
          .resizable()
          .frame(width: 20, height: 20)
          .contentTransition(.symbolEffect(.replace))
          .symbolRenderingMode(isPastStep ? .multicolor : .hierarchical)
          .foregroundStyle(isUpcomingStep ? .secondary : .primary)
      } else {
        Image(systemName: isPastStep ? "checkmark.circle.fill" : "\(index+1).circle.fill")
          .resizable()
          .frame(width: 20, height: 20)
          .symbolRenderingMode(isPastStep ? .multicolor : .hierarchical)
          .foregroundStyle(isUpcomingStep ? .secondary : .primary)
      }
      Text(allSteps[index].displayText)
        .fontWeight(.semibold)
    }
    .opacity(isUpcomingStep ? 0.3 : 1)
    .padding(8)
    .background(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(isHover ? Color.secondary.opacity(0.1) : Color.clear)
    )
    .onHover(perform: { isHovering in
      withAnimation {
        isHover = isHovering
      }
    })
//    .onTapGesture {
//      if isPastStep {
//        withAnimation(.spring(duration: 1)) {
//          currentStep = allSteps[index]
//        }
//      }
//    }
  }

}
