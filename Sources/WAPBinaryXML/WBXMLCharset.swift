//
//  WBXMLCharset.swift
//  WAPBinaryXML
//
//  Created by Helge Hess on 30.08.26.
//  Copyright © 2026 ZeeZide GmbH. All rights reserved.
//

/// Character sets supported by the WBXML codecs.
public enum WBXMLCharset: UInt32, Sendable, Equatable {

  /// Unspecified charset, treated as UTF-8.
  case unspecified = 0

  /// ISO-8859-1 (Latin-1), IANA MIBenum 4.
  case isoLatin1   = 4

  /// UTF-8, IANA MIBenum 106.
  case utf8        = 106
}

extension WBXMLCharset {

  static func decode<C: Collection>(_ bytes: C, charset: UInt32)
    throws -> String where C.Element == UInt8
  {
    let string: String
    switch charset {
      case WBXMLCharset.unspecified.rawValue, WBXMLCharset.utf8.rawValue:
        if #available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *) {
          guard let validated = String(validating: bytes, as: UTF8.self) else {
            throw WBXMLError.invalidUTF8
          }
          string = validated
        }
        else {
          string = String(decoding: bytes, as: UTF8.self)
          guard string.utf8.elementsEqual(bytes) else {
            throw WBXMLError.invalidUTF8
          }
        }
      case WBXMLCharset.isoLatin1.rawValue:
        var scalars = String.UnicodeScalarView()
        for byte in bytes {
          guard let scalar = Unicode.Scalar(UInt32(byte)) else {
            throw WBXMLError.invalidXMLScalar(UInt32(byte))
          }
          scalars.append(scalar)
        }
        string = String(scalars)
      default:
        throw WBXMLError.unsupportedCharset(charset)
    }
    try validate(string)
    return string
  }

  static func validate(_ string: String) throws {
    for scalar in string.unicodeScalars {
      if scalar.value == 0 { throw WBXMLError.embeddedNull }
      guard XMLValidation.isValidScalar(scalar.value) else {
        throw WBXMLError.invalidXMLScalar(scalar.value)
      }
    }
  }
}
