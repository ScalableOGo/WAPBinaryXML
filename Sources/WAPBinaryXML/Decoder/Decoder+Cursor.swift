//
//  Cursor.swift
//  WAPBinaryXML
//
//  Created by Helge Hess on 06.04.26.
//  Copyright © 2026 ZeeZide GmbH. All rights reserved.
//

extension WBXMLDecoder {

  struct Cursor {

    var offset = 0

    func peek(_ bytes: Span<UInt8>) -> UInt8? {
      guard offset >= 0, offset < bytes.count else { return nil }
      return bytes[offset]
    }

    mutating func advance() { offset += 1 }

    mutating func readByte(_ bytes: Span<UInt8>) throws -> UInt8 {
      guard offset >= 0, offset < bytes.count else {
        throw WBXMLError.unexpectedEnd
      }
      let byte = bytes[offset]
      offset += 1
      return byte
    }

    mutating func readBytes(_ count: Int, _ bytes: Span<UInt8>)
      throws -> [ UInt8 ]
    {
      guard count >= 0, offset >= 0, offset <= bytes.count,
            count <= bytes.count - offset else
      {
        throw WBXMLError.unexpectedEnd
      }
      let end = offset + count
      let slice = bytes.extracting(offset ..< end)
      let result = slice.withUnsafeBufferPointer { Array($0) }
      offset = end
      return result
    }

    mutating func skipBytes(_ count: Int, _ bytes: Span<UInt8>)
      throws -> Range<Int>
    {
      guard count >= 0, offset >= 0, offset <= bytes.count,
            count <= bytes.count - offset else
      {
        throw WBXMLError.unexpectedEnd
      }
      let start = offset
      offset += count
      return start ..< offset
    }

    mutating func readMBUInt32(_ bytes: Span<UInt8>) throws -> UInt32 {
      let ( value, count ) = try MBUInt32.decode(bytes.extracting(offset...))
      offset += count
      return value
    }

    mutating func readTerminatedRange(_ bytes: Span<UInt8>) throws -> Range<Int>
    {
      let start = offset
      while offset < bytes.count && bytes[offset] != 0 { offset += 1 }
      guard offset < bytes.count else { throw WBXMLError.unterminatedString }
      let range = start ..< offset
      offset += 1
      return range
    }
  }
}
