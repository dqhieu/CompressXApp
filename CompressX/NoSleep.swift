//
//  NoSleep.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 10/8/24.
//

import Foundation
import IOKit.pwr_mgt

struct NoSleep {
  private static var assertionID: IOPMAssertionID = 0
  private static var success: IOReturn?

  @discardableResult
  static func disableSleep() -> Bool? {
    guard success == nil else { return nil }
    success = IOPMAssertionCreateWithName( kIOPMAssertionTypeNoDisplaySleep as CFString,
                                           IOPMAssertionLevel(kIOPMAssertionLevelOn),
                                           "Preventing sleep while compressing" as CFString,
                                           &assertionID )
    return success == kIOReturnSuccess
  }
  
  @discardableResult
  static func enableSleep() -> Bool {
    if success != nil {
      success = IOPMAssertionRelease(assertionID)
      success = nil
      return true
    }
    return false
  }
}
