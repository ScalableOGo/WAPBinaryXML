//
//  EncodingBuffer.swift
//  WAPBinaryXML
//
//  Created by Helge Hess on 06.04.26.
//  Copyright © 2026 ZeeZide GmbH. All rights reserved.
//

extension WBXMLEncoder {

  /**
   * An output that can directly take UInt8 collections like ``Data``.
   */
  struct CollectionOutput<Bytes: RangeReplaceableCollection>: Output
    where Bytes.Element == UInt8
  {

    var bytes : Bytes
    var count : Int { bytes.count }

    mutating func append(_ byte: UInt8) { bytes.append(byte) }

    mutating func append(contentsOf data: Span<UInt8>) {
      data.withUnsafeBufferPointer { bytes.append(contentsOf: $0) }
    }

    mutating func truncate(to count: Int) {
      let end = bytes.index(bytes.startIndex, offsetBy: count)
      bytes.removeSubrange(end..<bytes.endIndex)
    }
  }

  /**
   * Just an array that raises ``WBXMLError/resourceLimitExceeded`` when adding
   * more data would overflow the limit.
   *
   * Well, and methods limited to just what the encoder needs.
   */
  struct EncodingBuffer<Destination: Output> {

    let maximumBytes : Int
    var destination  : Destination

    private(set) var count = 0

    mutating func append(_ byte: UInt8) throws {
      guard count < maximumBytes else {
        throw WBXMLError.resourceLimitExceeded(.documentBytes)
      }
      destination.append(byte)
      count += 1
    }

    mutating func append(contentsOf data: ContiguousArray<UInt8>) throws {
      guard count <= maximumBytes, data.count <= maximumBytes - count else {
        throw WBXMLError.resourceLimitExceeded(.documentBytes)
      }

      destination.append(contentsOf: data.span)
      count += data.count
    }

    mutating func appendMBUInt32(_ value: UInt32) throws {
      let length = MBUInt32.encodedByteCount(value)
      guard count <= maximumBytes, length <= maximumBytes - count else {
        throw WBXMLError.resourceLimitExceeded(.documentBytes)
      }

      var groups = length
      var shift  = (groups - 1) * 7
      while groups > 0 {
        let byte = UInt8((value >> shift) & 0x7F)
        groups -= 1
        destination.append(groups == 0 ? byte : byte | 0x80)
        shift -= 7
      }
      count += length
    }

    mutating func appendTerminated(_ value: String, charset: WBXMLCharset)
      throws
    {
      let length = try charset.encodedByteCount(of: value)
      guard count <= maximumBytes, length < maximumBytes - count else {
        throw WBXMLError.resourceLimitExceeded(.documentBytes)
      }

      if charset != .isoLatin1 || length == value.utf8.count {
        var string = value
        string.withUTF8 { destination.append(contentsOf: $0.span) }
      }
      else {
        appendLatin1(value)
      }
      destination.append(0)
      count += length + 1
    }

    private mutating func appendLatin1(_ value: String) {
      withUnsafeTemporaryAllocation(of: UInt8.self, capacity: 256) { bytes in
        bytes.initialize(repeating: 0)
        var count = 0
        for scalar in value.unicodeScalars {
          bytes[count] = UInt8(scalar.value)
          count += 1
          if count == bytes.count {
            destination.append(contentsOf: bytes.span)
            count = 0
          }
        }
        if count > 0 {
          destination.append(contentsOf: bytes.span.extracting(..<count))
        }
      }
    }
  }
}
