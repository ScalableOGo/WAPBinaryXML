//
//  XMLValidation.swift
//  WAPBinaryXML
//
//  Created by Helge Hess on 14.09.26.
//  Copyright © 2026 ZeeZide GmbH. All rights reserved.
//

/// XML 1.0 name and character checks.
@usableFromInline
enum XMLValidation {

  static func isName(_ string: String) -> Bool {
    var scalars = string.unicodeScalars.makeIterator()
    guard let first = scalars.next(), isNameStart(first.value) else {
      return false
    }
    while let scalar = scalars.next() {
      if !isNameCharacter(scalar.value) { return false }
    }
    return true
  }

  static func isValidString(_ string: String) -> Bool {
    string.unicodeScalars.allSatisfy { isValidScalar($0.value) }
  }

  @inlinable
  static func isValidScalar(_ value: UInt32) -> Bool {
    value == 0x09 || value == 0x0A || value == 0x0D
      || (value >= 0x20 && value <= 0xD7FF)
      || (value >= 0xE000 && value <= 0xFFFD)
      || (value >= 0x10000 && value <= 0x10FFFF)
  }

  private static func isNameStart(_ value: UInt32) -> Bool {
    value == 0x3A || value == 0x5F
      || (value >=    0x41 && value <=    0x5A)
      || (value >=    0x61 && value <=    0x7A)
      || (value >=    0xC0 && value <=    0xD6)
      || (value >=    0xD8 && value <=    0xF6)
      || (value >=    0xF8 && value <=   0x2FF)
      || (value >=   0x370 && value <=   0x37D)
      || (value >=   0x37F && value <=  0x1FFF)
      || (value >=  0x200C && value <=  0x200D)
      || (value >=  0x2070 && value <=  0x218F)
      || (value >=  0x2C00 && value <=  0x2FEF)
      || (value >=  0x3001 && value <=  0xD7FF)
      || (value >=  0xF900 && value <=  0xFDCF)
      || (value >=  0xFDF0 && value <=  0xFFFD)
      || (value >= 0x10000 && value <= 0xEFFFF)
  }

  private static func isNameCharacter(_ value: UInt32) -> Bool {
    isNameStart(value) || value == 0x2D || value == 0x2E || value == 0xB7
      || (value >=   0x30 && value <=   0x39)
      || (value >=  0x300 && value <=  0x36F)
      || (value >= 0x203F && value <= 0x2040)
  }
}
