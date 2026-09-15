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

  static func validateName(_ string: String) throws {
    guard isName(string) else { throw WBXMLError.invalidXMLName }
  }

  static func validatePITarget(_ string: String) throws {
    try validateName(string)
    guard !isReservedPITarget(string) else {
      throw WBXMLError.invalidProcessingInstructionTarget(string)
    }
  }

  static func validatePublicIdentifier(_ string: String) throws {
    for scalar in string.unicodeScalars {
      guard isPublicIdentifierCharacter(scalar.value) else {
        throw WBXMLError.invalidPublicIdentifier
      }
    }
  }

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
       value == UInt8(ascii: "\t") || value == UInt8(ascii: "\n")
    || value == UInt8(ascii: "\r")
    || (value >=    0x20 && value <=   0xD7FF)
    || (value >=  0xE000 && value <=   0xFFFD)
    || (value >= 0x10000 && value <= 0x10FFFF)
  }

  private static func isNameStart(_ value: UInt32) -> Bool {
        value == UInt8(ascii: ":") || value == UInt8(ascii: "_")
    || (value >= UInt8(ascii: "A") && value <= UInt8(ascii: "Z"))
    || (value >= UInt8(ascii: "a") && value <= UInt8(ascii: "z"))
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
       isNameStart(value) || value == UInt8(ascii: "-")
    || value == UInt8(ascii: ".") || value == 0xB7
    || (value >= UInt8(ascii: "0") && value <= UInt8(ascii: "9"))
    || (value >=  0x300 && value <=  0x36F)
    || (value >= 0x203F && value <= 0x2040)
  }

  private static func isReservedPITarget(_ string: String) -> Bool {
    var string = string
    return string.withUTF8 { bytes in
         bytes.count == 3 && bytes[0] | 0x20 == UInt8(ascii: "x")
      && bytes[1] | 0x20 == UInt8(ascii: "m")
      && bytes[2] | 0x20 == UInt8(ascii: "l")
    }
  }

  private static func isPublicIdentifierCharacter(_ value: UInt32) -> Bool {
    guard let ascii = UInt8(exactly: value) else { return false }
    
    if ascii == UInt8(ascii: " ") || ascii == UInt8(ascii: "\r")
       || ascii == UInt8(ascii: "\n")
    {
      return true
    }
    if ascii >= UInt8(ascii: "A") && ascii <= UInt8(ascii: "Z") { return true }
    if ascii >= UInt8(ascii: "a") && ascii <= UInt8(ascii: "z") { return true }
    if ascii >= UInt8(ascii: "0") && ascii <= UInt8(ascii: "9") { return true }

    return switch ascii {
      case UInt8(ascii: "-"), UInt8(ascii: "'"), UInt8(ascii: "("),
           UInt8(ascii: ")"), UInt8(ascii: "+"), UInt8(ascii: ","),
           UInt8(ascii: "."), UInt8(ascii: "/"), UInt8(ascii: ":"),
           UInt8(ascii: "="), UInt8(ascii: "?"), UInt8(ascii: ";"),
           UInt8(ascii: "!"), UInt8(ascii: "*"), UInt8(ascii: "#"),
           UInt8(ascii: "@"), UInt8(ascii: "$"), UInt8(ascii: "_"),
           UInt8(ascii: "%"): true
      default: false
    }
  }
}
