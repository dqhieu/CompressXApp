//
//  GifDimension.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 1/8/24.
//


enum GifDimension: String, CaseIterable, Codable {
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
      return 1.0
    case .threeQuarters:
      return 3.0/4.0
    case .half:
      return 2.0/4.0
    case .oneQuarter:
      return 1.0/4.0
    }
  }
}
