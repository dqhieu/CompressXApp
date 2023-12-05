//
//  ImageDimension.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 1/8/24.
//


enum ImageDimension: String, CaseIterable, Codable {
  case same
  case threeQuarters
  case half
  case oneQuarter

  var displayText: String {
    switch self {
    case .same:
      return "Same as input"
    case .threeQuarters:
      return "75%"
    case .half:
      return "50%"
    case .oneQuarter:
      return "25%"
    }
  }

  var fraction: Double {
    switch self {
    case .same:
      return 1
    case .threeQuarters:
      return 0.75
    case .half:
      return 0.5
    case .oneQuarter:
      return 0.25
    }
  }
}
