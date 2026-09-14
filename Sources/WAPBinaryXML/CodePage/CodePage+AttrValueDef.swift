//
//  CodePageAttributeValueDefinition.swift
//  WAPBinaryXML
//
//  Created by Helge Hess on 11.09.26.
//  Copyright © 2026 ZeeZide GmbH. All rights reserved.
//

extension WBXMLCodePage {

  /// An attribute-value token definition.
  public struct AttributeValueDefinition: Sendable {

    /// Token byte in the attribute code page.
    public let token : UInt8

    /// Text contributed by the token.
    public let value : String

    /// Build an attribute-value definition.
    @inlinable
    public init(token: UInt8, value: String) {
      self.token = token
      self.value = value
    }
  }
}

extension WBXMLCodePage.AttributeValueDefinition: Equatable {

  @inlinable
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.token == rhs.token && WBXMLExactStringKey.equals(lhs.value, rhs.value)
  }
}
