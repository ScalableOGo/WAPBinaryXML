//
//  WBXMLNode.swift
//  WAPBinaryXML
//
//  Created by Helge Hess on 06.04.26.
//  Copyright © 2026 ZeeZide GmbH. All rights reserved.
//

/// A node in the WBXML tree.
public enum WBXMLNode: Sendable {

  /// A child element.
  case element(WBXMLElement)

  /// Inline string (`STR_I`).
  case text(String)

  /// String-table string (`STR_T`).
  case stringTable(String)

  /// Numeric character entity (`ENTITY`).
  case entity(UInt32)

  /// Inline extension token, its page hint may select an undeclared page.
  case extensionInline(index: UInt8, value: String, page: UInt8? = nil)

  /// Integer extension token, its page hint may select an undeclared page.
  case extensionInteger(index: UInt8, value: UInt32, page: UInt8? = nil)

  /// Payload-free extension, its page hint may select an undeclared page.
  case `extension`(index: UInt8, page: UInt8? = nil)

  /// A processing instruction (`PI`).
  case processingInstruction(WBXMLProcessingInstruction)

  /// Raw opaque bytes (`OPAQUE`).
  case opaque(ContiguousArray<UInt8>)
}

extension WBXMLNode: Equatable {

  @inlinable
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch ( lhs, rhs ) {
      case ( .element(let lhs), .element(let rhs) ):
        lhs == rhs

      case ( .text       (let lhs), .text       (let rhs) ),
           ( .stringTable(let lhs), .stringTable(let rhs) ):
        WBXMLExactStringKey.equals(lhs, rhs)

      case ( .entity(let lhs), .entity(let rhs) ):
        lhs == rhs

      case ( .extensionInline(let li, let lv, let lp),
             .extensionInline(let ri, let rv, let rp) ):
        li == ri && WBXMLExactStringKey.equals(lv, rv) && lp == rp

      case ( .extensionInteger(let li, let lv, let lp),
             .extensionInteger(let ri, let rv, let rp) ):
        li == ri && lv == rv && lp == rp

      case ( .extension(let li, let lp), .extension(let ri, let rp) ):
        li == ri && lp == rp

      case ( .processingInstruction(let lhs),
             .processingInstruction(let rhs) ):
        lhs == rhs

      case ( .opaque(let lhs), .opaque(let rhs) ):
        lhs == rhs

      default: false
    }
  }
}

extension WBXMLNode {

  @inlinable
  var textFragment: String? {
    switch self {
      case .text(let value), .stringTable(let value): return value
      case .entity(let value):
        guard let scalar = Unicode.Scalar(value) else { return "" }
        return String(scalar)
      default: return nil
    }
  }
}
