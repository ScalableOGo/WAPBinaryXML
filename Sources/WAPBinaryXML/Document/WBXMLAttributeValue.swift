//
//  WBXMLAttributeValue.swift
//  WAPBinaryXML
//
//  Created by Helge Hess on 06.04.26.
//  Copyright © 2026 ZeeZide GmbH. All rights reserved.
//

/// A component of an attribute value.
public enum WBXMLAttributeValue: Sendable {

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

  /// Code-page attribute-value token.
  case token(String, page: UInt8? = nil)

  /// Raw opaque attribute data (`OPAQUE`).
  case opaque(ContiguousArray<UInt8>)
}

public extension WBXMLAttributeValue {

  /// Lossy literal text, empty for unresolved extensions and opaque data.
  @inlinable
  var textContent: String { plainTextValue ?? "" }

  /// Literal text, or nil for extensions, opaque data, or invalid entities.
  @inlinable
  var plainTextValue: String? {
    switch self {
      case .text(let value), .stringTable(let value): return value
      case .entity(let value):
        guard XMLValidation.isValidScalar(value),
              let scalar = Unicode.Scalar(value) else { return nil }
        return String(scalar)
      case .extensionInline, .extensionInteger, .extension, .opaque:
        return nil
      case .token(let value, _): return value
    }
  }
}

extension WBXMLAttributeValue: Equatable {

  @inlinable
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch ( lhs, rhs ) {
      case ( .text       (let lhs), .text       (let rhs) ),
           ( .stringTable(let lhs), .stringTable(let rhs) ):
        WBXMLExactStringKey.equals(lhs, rhs)

      case ( .entity(let lhs), .entity(let rhs) ): lhs == rhs

      case ( .extensionInline(let li, let lv, let lp),
             .extensionInline(let ri, let rv, let rp) ):
        li == ri && WBXMLExactStringKey.equals(lv, rv) && lp == rp

      case ( .extensionInteger(let li, let lv, let lp),
             .extensionInteger(let ri, let rv, let rp) ):
        li == ri && lv == rv && lp == rp

      case ( .extension(let li, let lp), .extension(let ri, let rp) ):
        li == ri && lp == rp

      case ( .token(let lv, let lp), .token(let rv, let rp) ):
        WBXMLExactStringKey.equals(lv, rv) && lp == rp

      case ( .opaque(let lhs), .opaque(let rhs) ):
        lhs == rhs

      default: false
    }
  }
}
