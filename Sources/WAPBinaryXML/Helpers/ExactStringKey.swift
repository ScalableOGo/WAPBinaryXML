//
//  WBXMLExactStringKey.swift
//  WAPBinaryXML
//
//  Created by Helge Hess on 30.08.26.
//  Copyright © 2026 ZeeZide GmbH. All rights reserved.
//

/// A string key whose identity is its exact UTF-8 sequence.
@usableFromInline
struct WBXMLExactStringKey: Sendable {

  @usableFromInline
  let value : String

  @inlinable
  init(_ value: String) {
    var value = value
    value.makeContiguousUTF8()
    self.value = value
  }
}

extension WBXMLExactStringKey: Hashable {

  @inlinable
  static func == (lhs: Self, rhs: Self) -> Bool {
    equals(lhs.value, rhs.value)
  }

  @inlinable
  func hash(into hasher: inout Hasher) {
    var value = value
    value.withUTF8 { hasher.combine(bytes: UnsafeRawBufferPointer($0)) }
  }

  @inlinable
  static func equals(_ lhs: String, _ rhs: String) -> Bool {
    var lhs = lhs
    var rhs = rhs
    return lhs.withUTF8 { lhsBytes in
      rhs.withUTF8 { rhsBytes in
        lhsBytes.count == rhsBytes.count && lhsBytes.elementsEqual(rhsBytes)
      }
    }
  }

  @inlinable
  static func equals(_ lhs: String?, _ rhs: String?) -> Bool {
    switch ( lhs, rhs ) {
      case ( .none,          .none          ) : true
      case ( .some(let lhs), .some(let rhs) ) : equals(lhs, rhs)
      default                                 : false
    }
  }
}
