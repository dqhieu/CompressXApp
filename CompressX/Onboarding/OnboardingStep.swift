//
//  OnboardingStep.swift
//  Onboarding
//
//  Created by Dinh Quang Hieu on 3/8/24.
//


enum OnboardingStep: Int, Identifiable, Comparable {
  static func < (lhs: OnboardingStep, rhs: OnboardingStep) -> Bool {
    return lhs.rawValue < rhs.rawValue
  }
  
  case start = 0
  case installation = 1
  case license = 2
  case done = 3

  var id: String {
    return self.displayText
  }

  var displayText: String {
    switch self {
    case .start:
      return "Start"
    case .installation:
      return "Install"
    case .license:
      return "License"
    case .done:
      return "Done"
    }
  }
}
