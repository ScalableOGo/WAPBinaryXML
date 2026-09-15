//
//  WBXMLAttribute.swift
//  WAPBinaryXML
//
//  Created by Helge Hess on 06.04.26.
//  Copyright © 2026 ZeeZide GmbH. All rights reserved.
//

/// An attribute attached to an element or processing instruction.
public struct WBXMLAttribute: Sendable {

  /// Resolved or literal attribute name.
  public var name        : String

  /// Explicit attribute code page, or nil to resolve automatically.
  public var page        : UInt8?

  /// Whether to encode the name with a WBXML `LITERAL` token.
  public var literal     : Bool

  /// Value prefix carried by the selected attribute-start token.
  public var valuePrefix : String?

  /// Attribute value components in source order, an empty list is valid.
  public var values      : [ WBXMLAttributeValue ]

  /// Build an attribute.
  @inlinable
  public init(name: String, page: UInt8? = nil, literal: Bool = false,
              valuePrefix: String? = nil, values: [ WBXMLAttributeValue ] = [])
  {
    self.name        = name
    self.page        = page
    self.literal     = literal
    self.valuePrefix = valuePrefix
    self.values      = values
  }
}

public extension WBXMLAttribute {

  /// Build an attribute with one inline text value.
  @inlinable
  init(name: String, page: UInt8? = nil, literal: Bool = false,
       valuePrefix: String? = nil, text: String)
  {
    self.init(name: name, page: page, literal: literal,
              valuePrefix: valuePrefix, values: [ .text(text) ])
  }

  /// Lossy literal text, omitting unresolved extensions and opaque data.
  @inlinable
  var textContent: String {
    var result = valuePrefix ?? ""
    for value in values { result += value.textContent }
    return result
  }

  /// Complete literal text, or nil if any component needs interpretation.
  @inlinable
  var plainTextValue: String? {
    var result = valuePrefix ?? ""
    for value in values {
      guard let text = value.plainTextValue else { return nil }
      result += text
    }
    return result
  }
}

extension WBXMLAttribute: Equatable {

  @inlinable
  public static func == (lhs: Self, rhs: Self) -> Bool {
       WBXMLExactStringKey.equals(lhs.name, rhs.name) && lhs.page == rhs.page
    && lhs.literal == rhs.literal
    && WBXMLExactStringKey.equals(lhs.valuePrefix, rhs.valuePrefix)
    && lhs.values == rhs.values
  }
}
