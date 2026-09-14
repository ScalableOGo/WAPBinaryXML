//
//  WBXMLPublicIdentifier.swift
//  WAPBinaryXML
//
//  Created by Helge Hess on 06.04.26.
//  Copyright © 2026 ZeeZide GmbH. All rights reserved.
//

/// A WBXML public identifier.
public enum WBXMLPublicIdentifier: Sendable {

  /// A numeric public identifier.
  case numeric(UInt32)

  /// An XML `PubidLiteral`, including an empty one, stored in the string table.
  case literal(String)
}

extension WBXMLPublicIdentifier: Equatable {

  @inlinable
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch ( lhs, rhs ) {
      case ( .numeric(let lhs), .numeric(let rhs) ): lhs == rhs
      case ( .literal(let lhs), .literal(let rhs) ):
        WBXMLExactStringKey.equals(lhs, rhs)
      default: false
    }
  }
}
