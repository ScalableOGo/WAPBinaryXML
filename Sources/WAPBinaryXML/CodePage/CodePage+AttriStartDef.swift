//
//  CodePageAttributeStartDefinition.swift
//  WAPBinaryXML
//
//  Created by Helge Hess on 11.09.26.
//  Copyright © 2026 ZeeZide GmbH. All rights reserved.
//

extension WBXMLCodePage {

  /// An attribute-start token definition.
  public struct AttributeStartDefinition: Sendable {

    /// Token byte in the attribute code page.
    public let token       : UInt8

    /// Attribute name introduced by the token.
    public let name        : String

    /// Optional value prefix introduced by the token.
    public let valuePrefix : String?

    /// Build an attribute-start definition.
    @inlinable
    public init(token: UInt8, name: String, valuePrefix: String? = nil) {
      self.token       = token
      self.name        = name
      self.valuePrefix = valuePrefix
    }
  }
}

extension WBXMLCodePage.AttributeStartDefinition: Equatable {

  @inlinable
  public static func == (lhs: Self, rhs: Self) -> Bool {
       lhs.token == rhs.token
    && WBXMLExactStringKey.equals(lhs.name, rhs.name)
    && WBXMLExactStringKey.equals(lhs.valuePrefix, rhs.valuePrefix)
  }
}
