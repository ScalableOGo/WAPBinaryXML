//
//  StringTableBuilder.swift
//  WAPBinaryXML
//
//  Created by Helge Hess on 06.04.26.
//  Copyright © 2026 ZeeZide GmbH. All rights reserved.
//

extension WBXMLEncoder {

  struct StringTableBuilder {

    let charset      : WBXMLCharset
    let maximumBytes : Int
    var bytes        = ContiguousArray<UInt8>()

    private var offsets = [ WBXMLExactStringKey : UInt32 ]()

    init(charset: WBXMLCharset, maximumBytes: Int,
         retaining table: WBXMLStringTable?) throws
    {
      self.charset      = charset
      self.maximumBytes = maximumBytes

      guard maximumBytes >= 0, (table?.bytes.count ?? 0) <= maximumBytes else {
        throw WBXMLError.resourceLimitExceeded(.stringTableBytes)
      }
      guard let table else { return }

      guard table.charset == charset else {
        throw WBXMLError
          .stringTableCharsetMismatch(table: table.charset, document: charset)
      }
      try WBXMLEncoder.validateLength(table.bytes.count)

      bytes   = table.bytes
      offsets = table.offsets
    }

    mutating func add(_ value: String) throws {
      let count = try charset.encodedByteCount(of: value)
      guard maximumBytes >= 0, count < maximumBytes else {
        throw WBXMLError.resourceLimitExceeded(.stringTableBytes)
      }

      let maximumLength = UInt64(UInt32.max)
      guard UInt64(count) < maximumLength else {
        throw WBXMLError.lengthOverflow
      }

      let key = WBXMLExactStringKey(value)
      if offsets[key] != nil { return }

      guard bytes.count <= maximumBytes,
            count < maximumBytes - bytes.count else
      {
        throw WBXMLError.resourceLimitExceeded(.stringTableBytes)
      }
      guard UInt64(bytes.count) <= maximumLength,
            UInt64(count) < maximumLength - UInt64(bytes.count) else
      {
        throw WBXMLError.lengthOverflow
      }
      
      offsets[key] = UInt32(bytes.count)
      charset.appendValidated(value, byteCount: count, into: &bytes)
      bytes.append(0)
    }

    func offset(for value: String) throws -> UInt32 {
      guard let offset = offsets[WBXMLExactStringKey(value)] else {
        throw WBXMLError.missingStringTableEntry(value)
      }
      return offset
    }

    func length() throws -> UInt32 {
      try WBXMLEncoder.uint32Length(bytes.count)
    }
  }
}
