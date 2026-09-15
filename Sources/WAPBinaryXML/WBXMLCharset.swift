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

  /// ISO-8859-1 (Latin-1).
  case isoLatin1   = 4

  /// UTF-8, IANA MIBenum 106.
  case utf8        = 106
}

extension WBXMLCharset {

  func encodedByteCount(of string: String) throws -> Int {
    try Self.validate(string)

    switch self {
      case .unspecified, .utf8:
        return string.utf8.count

      case .isoLatin1:
        var count = 0
        for scalar in string.unicodeScalars {
          guard scalar.value <= UInt8.max else {
            throw WBXMLError
              .unrepresentableCharacter(charset: self, scalar: scalar.value)
          }
          count += 1
        }
        return count
    }
  }

  /// Append text using the byte count validated for this string and charset.
  func appendValidated(_ string: String, byteCount: Int,
                       into bytes: inout ContiguousArray<UInt8>)
  {
    switch self {
      case .unspecified, .utf8:
        bytes.append(contentsOf: string.utf8)
      case .isoLatin1:
        if byteCount == string.utf8.count {
          bytes.append(contentsOf: string.utf8)
          return
        }
        #if compiler(>=6.3)
        bytes.append(addingCapacity: byteCount) { output in
          for scalar in string.unicodeScalars {
            output.append(UInt8(scalar.value))
          }
        }
        #else
        for scalar in string.unicodeScalars {
          bytes.append(UInt8(scalar.value))
        }
        #endif
    }
  }

  func decode<C: Collection>(_ bytes: C) throws -> String
    where C.Element == UInt8
  {
    let string: String
    switch self {
      case .unspecified, .utf8:
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
      case .isoLatin1:
        var scalars = String.UnicodeScalarView()
        for byte in bytes {
          guard let scalar = Unicode.Scalar(UInt32(byte)) else {
            throw WBXMLError.invalidXMLScalar(UInt32(byte))
          }
          scalars.append(scalar)
        }
        string = String(scalars)
    }

    try Self.validate(string)
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
