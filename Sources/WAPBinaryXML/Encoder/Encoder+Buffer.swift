//
//  EncodingBuffer.swift
//  WAPBinaryXML
//
//  Created by Helge Hess on 06.04.26.
//  Copyright © 2026 ZeeZide GmbH. All rights reserved.
//

extension WBXMLEncoder {

  /**
   * Just an array that raises ``WBXMLError/resourceLimitExceeded`` when adding
   * more data would overflow the limit.
   *
   * Well, and methods limited to just what the encoder needs.
   */
  struct EncodingBuffer {

    let maximumBytes : Int
    var bytes        = ContiguousArray<UInt8>()

    mutating func append(_ byte: UInt8) throws {
      guard bytes.count < maximumBytes else {
        throw WBXMLError.resourceLimitExceeded(.documentBytes)
      }
      bytes.append(byte)
    }

    mutating func append(contentsOf data: ContiguousArray<UInt8>) throws {
      guard bytes.count <= maximumBytes,
            data.count <= maximumBytes - bytes.count else
      {
        throw WBXMLError.resourceLimitExceeded(.documentBytes)
      }
      
      bytes.append(contentsOf: data)
    }

    mutating func appendMBUInt32(_ value: UInt32) throws {
      let count = MBUInt32.encodedByteCount(value)
      guard bytes.count <= maximumBytes,
            count <= maximumBytes - bytes.count else
      {
        throw WBXMLError.resourceLimitExceeded(.documentBytes)
      }
      
      MBUInt32.encode(value, into: &bytes)
    }

    mutating func appendTerminated(_ value: String, charset: WBXMLCharset)
      throws
    {
      let count = try charset.encodedByteCount(of: value)
      guard bytes.count <= maximumBytes,
            count < maximumBytes - bytes.count else
      {
        throw WBXMLError.resourceLimitExceeded(.documentBytes)
      }
      
      charset.appendValidated(value, byteCount: count, into: &bytes)
      bytes.append(0)
    }
  }
}
