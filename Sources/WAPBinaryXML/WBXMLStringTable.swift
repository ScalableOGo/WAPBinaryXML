//
//  WBXMLStringTable.swift
//  WAPBinaryXML
//
//  Created by Helge Hess on 09.09.26.
//  Copyright © 2026 ZeeZide GmbH. All rights reserved.
//

/**
 * An immutable string table retaining its original byte offsets and charset.
 */
public struct WBXMLStringTable: Sendable {

  /// Original, null-terminated string bytes.
  public let bytes   : ContiguousArray<UInt8>

  /// The character encoding used by the table's bytes.
  public let charset : WBXMLCharset

  var offsets = [ WBXMLExactStringKey : UInt32 ]()

  public init(bytes: ContiguousArray<UInt8>, charset: WBXMLCharset = .utf8)
    throws
  {
    self.bytes   = bytes
    self.charset = charset
    guard UInt64(bytes.count) <= UInt64(UInt32.max) else {
      throw WBXMLError.lengthOverflow
    }

    var offset = 0
    while offset < bytes.count {
      let end = try terminatedEnd(at: offset)
      let string = try WBXMLCharset.decode(bytes[offset ..< end],
                                           charset: charset.rawValue)
      let key = WBXMLExactStringKey(string)
      if offsets[key] == nil { offsets[key] = UInt32(offset) }

      let empty = WBXMLExactStringKey("")
      if offsets[empty] == nil { offsets[empty] = UInt32(end) }

      offset = end + 1
    }
  }

  /// Byte, not char, offset
  public subscript(offset: Int) -> String {
    get throws {
      guard offset >= 0 && offset < bytes.count else {
        throw WBXMLError.invalidStringTableOffset(offset)
      }
      let end = try terminatedEnd(at: offset)
      return try WBXMLCharset
                   .decode(bytes[offset..<end], charset: charset.rawValue)
    }
  }

  private func terminatedEnd(at start: Int) throws -> Int {
    var end = start
    while end < bytes.count && bytes[end] != 0 { end += 1 }
    guard end < bytes.count else { throw WBXMLError.unterminatedString }
    return end
  }
}

extension WBXMLStringTable: Equatable {

  @inlinable
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.bytes == rhs.bytes && lhs.charset == rhs.charset
  }
}
