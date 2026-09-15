//
//  Encoder+Output.swift
//  WAPBinaryXML
//
//  Created by Helge Hess on 15.09.26.
//  Copyright © 2026 ZeeZide GmbH. All rights reserved.
//

extension WBXMLEncoder {

  /**
   * An appendable byte buffer used by `encode(_:to:)`.
   *
   * Appending must preserve existing bytes and increase `count` by the number
   * of bytes appended. Truncation must preserve the retained prefix. The
   * encoder uses truncation to roll back a failed write, so irreversible
   * destinations such as network streams cannot implement this contract.
   */
  public protocol Output {

    /// The nonnegative number of bytes currently in the buffer.
    var count: Int { get }

    /// Append one byte.
    mutating func append(_ byte: UInt8)

    /// Append every byte in the span, in order.
    mutating func append(contentsOf bytes: Span<UInt8>)

    /// Retain `count` bytes, where `count` is within `0...self.count`.
    mutating func truncate(to count: Int)
  }
}

extension WBXMLEncoder.Output {

  @inlinable
  public mutating func append(_ byte: UInt8) {
    withUnsafePointer(to: byte) {
      append(contentsOf: UnsafeBufferPointer(start: $0, count: 1).span)
    }
  }
}

extension WBXMLEncoder.Output
  where Self: RangeReplaceableCollection, Element == UInt8
{

  @inlinable
  public mutating func append(contentsOf bytes: Span<UInt8>) {
    bytes.withUnsafeBufferPointer { append(contentsOf: $0) }
  }

  @inlinable
  public mutating func truncate(to count: Int) {
    precondition(count >= 0 && count <= self.count)
    let end = index(startIndex, offsetBy: count)
    removeSubrange(end..<endIndex)
  }
}

extension Array           : WBXMLEncoder.Output where Element == UInt8 {}
extension ContiguousArray : WBXMLEncoder.Output where Element == UInt8 {}
