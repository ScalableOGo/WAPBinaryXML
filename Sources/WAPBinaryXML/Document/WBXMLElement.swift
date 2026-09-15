//
//  WBXMLElement.swift
//  WAPBinaryXML
//
//  Created by Helge Hess on 06.04.26.
//  Copyright © 2026 ZeeZide GmbH. All rights reserved.
//

/// An element in the WBXML tree.
public struct WBXMLElement: Sendable {

  /// Resolved or literal element name.
  public var tag        : String

  /// Explicit code page, or nil to resolve automatically.
  public var page       : UInt8?

  /// Whether to encode the name with a WBXML `LITERAL` token.
  public var literal    : Bool

  /// Attributes in source order.
  public var attributes : [ WBXMLAttribute ]

  /// Child nodes in source order.
  public var children   : [ WBXMLNode ]

  @inlinable
  public init(tag: String, page: UInt8? = nil, literal: Bool = false,
              attributes: [ WBXMLAttribute ] = [], children: [ WBXMLNode ] = [])
  {
    self.tag        = tag
    self.page       = page
    self.literal    = literal
    self.attributes = attributes
    self.children   = children
  }
}

extension WBXMLElement: Equatable {

  @inlinable
  public static func == (lhs: Self, rhs: Self) -> Bool {
       WBXMLExactStringKey.equals(lhs.tag, rhs.tag) && lhs.page == rhs.page
    && lhs.literal == rhs.literal && lhs.attributes == rhs.attributes
    && lhs.children == rhs.children
  }
}

public extension WBXMLElement {

  /// Complete direct text, or nil if any child is not a literal text form.
  @inlinable
  var plainTextValue: String? {
    var result = ""

    for child in children {
      switch child {
        case .text(let value), .stringTable(let value):
          result += value

        case .entity(let value):
          guard XMLValidation.isValidScalar(value),
                let scalar = Unicode.Scalar(value) else { return nil }
          result.unicodeScalars.append(scalar)
        default:
          return nil
      }
    }
    return result
  }

  /// Concatenated inline, string-table, and entity text content.
  @inlinable
  var textContent: String {
    var result = ""

    for child in children {
      if let fragment = child.textFragment { result += fragment }
    }
    return result
  }

  /// Concatenated textual content, or nil if no textual children exist.
  @inlinable
  var textValue: String? {
    var result  = ""
    var hasText = false

    for child in children {
      if let fragment = child.textFragment {
        result += fragment
        hasText = true
      }
    }
    return hasText ? result : nil
  }

  /// First child element with the given tag name.
  @inlinable
  subscript(tag name: String) -> WBXMLElement? {
    for child in children {
      if case .element(let element) = child,
         WBXMLExactStringKey.equals(element.tag, name)
      {
        return element
      }
    }
    return nil
  }

  /// All child elements with the given tag name.
  @inlinable
  func elements(named name: String) -> [ WBXMLElement ] {
    children.compactMap {
      if case .element(let element) = $0,
         WBXMLExactStringKey.equals(element.tag, name)
      {
        return element
      }
      return nil
    }
  }

  /// First child with the exact tag name and resolved or explicit code page.
  @inlinable
  subscript(tag name: String, page page: UInt8) -> WBXMLElement? {
    for child in children {
      if case .element(let element) = child, element.page == page,
         WBXMLExactStringKey.equals(element.tag, name)
      {
        return element
      }
    }
    return nil
  }

  /// Children with the exact tag name and resolved or explicit code page.
  @inlinable
  func elements(named name: String, page: UInt8) -> [ WBXMLElement ] {
    children.compactMap {
      if case .element(let element) = $0, element.page == page,
         WBXMLExactStringKey.equals(element.tag, name)
      {
        return element
      }
      return nil
    }
  }

  /// All direct child elements, regardless of tag.
  @inlinable
  var elements: [ WBXMLElement ] {
    children.compactMap {
      if case .element(let element) = $0 { return element }
      return nil
    }
  }

  /// First opaque child's bytes, or nil.
  @inlinable
  var opaqueValue: [ UInt8 ]? {
    for child in children {
      if case .opaque(let data) = child { return data }
    }
    return nil
  }
}
