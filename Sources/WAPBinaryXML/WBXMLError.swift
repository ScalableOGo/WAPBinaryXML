//
//  WBXMLError.swift
//  WAPBinaryXML
//
//  Created by Helge Hess on 06.04.26.
//  Copyright © 2026 ZeeZide GmbH. All rights reserved.
//

/// Errors thrown during WBXML encoding or decoding.
public enum WBXMLError: Error, Equatable, Sendable {

  /// A string payload was not valid UTF-8.
  case invalidUTF8

  /// The IANA charset MIBenum is not supported by this codec.
  case unsupportedCharset(UInt32)

  /// A null-terminated string contained U+0000.
  case embeddedNull

  /// A string or entity contained a scalar forbidden by XML 1.0.
  case invalidXMLScalar(UInt32)

  /// A string reached its containing buffer without a null terminator.
  case unterminatedString

  /// A string-table reference did not identify a table string.
  case invalidStringTableOffset(Int)

  /// A payload length or string-table offset exceeded `UInt32`.
  case lengthOverflow
}
