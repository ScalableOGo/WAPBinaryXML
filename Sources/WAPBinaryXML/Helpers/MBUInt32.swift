//
//  MBUInt32.swift
//  WAPBinaryXML
//
//  Created by Helge Hess on 06.04.26.
//  Copyright © 2026 ZeeZide GmbH. All rights reserved.
//

/**
 * Variable-length UInt32 encoding for WBXML header fields and opaque payload
 * lengths.
 *
 * Each byte carries 7 data bits, bit 7 is the continuation flag, set on all
 * bytes except the last. A 32-bit value fits in 1-5 bytes.
 */
public enum MBUInt32 {

  /**
   * Decode a multi-byte uint32 from the start of `buf`.
   *
   * - Returns: The decoded value and the number of bytes consumed.
   * - Throws:  `WBXMLError.invalidMBUInt32` if the value exceeds 32 bits or 5
   *            bytes, or `WBXMLError.unexpectedEnd` if data runs out.
   */
  @inlinable
  public static func decode(_ buf: Span<UInt8>)
    throws -> ( value: UInt32, count: Int )
  {
    var result   : UInt32 = 0
    var consumed = 0

    while true {
      guard consumed < buf.count else { throw WBXMLError.unexpectedEnd }
      
      let byte = buf[consumed]
      consumed += 1

      if consumed == 5 {
        guard result <= UInt32.max >> 7, byte & 0x80 == 0 else {
          throw WBXMLError.invalidMBUInt32
        }
      }
      result = (result << 7) | UInt32(byte & 0x7F)

      if byte & 0x80 == 0 { break }
    }
    return ( result, consumed )
  }

  /// Append the multi-byte encoding of `value` to `buf`.
  @inlinable
  public static func encode<C>(_ value: UInt32, into buf: inout C)
    where C: RangeReplaceableCollection, C.Element == UInt8
  {
    // Count required bytes up-front so we can emit most-significant 7-bit group
    // first without a reverse step.
    var bytes    = encodedByteCount(value)
    var bitsLeft = (bytes - 1) * 7
    while bytes > 0 {
      let group = UInt8((value >> bitsLeft) & 0x7F)
      bytes -= 1
      buf.append(bytes == 0 ? group : (group | 0x80))
      bitsLeft -= 7
    }
  }

  /// Encode a UInt32 as a byte array.
  @inlinable
  public static func encode(_ value: UInt32) -> [ UInt8 ] {
    var buf = [ UInt8 ](); buf.reserveCapacity(encodedByteCount(value))
    encode(value, into: &buf)
    return buf
  }

  @inlinable
  static func encodedByteCount(_ value: UInt32) -> Int {
    max(1, (32 - value.leadingZeroBitCount + 6) / 7)
  }
}
