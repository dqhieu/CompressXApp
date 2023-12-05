//
//  OutputFolder.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 1/8/24.
//


enum OutputFolder: String, CaseIterable, Codable {
  case same
  case custom
  
  var displayText: String {
    switch self {
    case .same:
      return "Same as input"
    case .custom:
      return "Custom"
    }
  }
}