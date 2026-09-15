//
//  WBXMLBuilder.swift
//  WAPBinaryXML
//
//  Created by Helge Hess on 06.04.26.
//  Copyright © 2026 ZeeZide GmbH. All rights reserved.
//

/**
 * Closure-based DSL for constructing WBXML element trees.
 *
 * Child elements inherit the enclosing page unless an explicit page is
 * supplied. A nil root page leaves page selection to the encoder.
 */
public enum WBXMLBuilder {

  /// Build a root element, ready to wrap in a ``WBXMLDocument``.
  @inlinable
  public static func element(_ tag: String, page: UInt8? = nil,
                             literal: Bool = false,
                             attributes: [ WBXMLAttribute ] = [],
                             build: (inout ElementBuilder) throws -> Void)
    rethrows -> WBXMLElement
  {
    var builder = ElementBuilder(inheritedPage: page)
    try build(&builder)
    return WBXMLElement(tag: tag, page: page, literal: literal,
                        attributes: attributes, children: builder.nodes)
  }

  /// Builder context for adding child nodes.
  public struct ElementBuilder {

    @usableFromInline
    var nodes         : [ WBXMLNode ]

    @usableFromInline
    let inheritedPage : UInt8?

    @inlinable
    init(inheritedPage: UInt8?) {
      self.nodes         = [ WBXMLNode ]()
      self.inheritedPage = inheritedPage
    }

    /// Add a child element with text content.
    @inlinable
    public mutating func element(_ tag: String, text: String,
                                 page: UInt8? = nil, literal: Bool = false,
                                 attributes: [ WBXMLAttribute ] = [])
    {
      let elementPage = page ?? inheritedPage
      nodes.append(
        .element(WBXMLElement(tag: tag, page: elementPage, literal: literal,
                              attributes: attributes,
                              children: [ .text(text) ])))
    }

    /// Add a child element with integer text.
    @inlinable
    public mutating func element(_ tag: String, int value: Int,
                                 page: UInt8? = nil, literal: Bool = false,
                                 attributes: [ WBXMLAttribute ] = [])
    {
      element(tag, text: String(value), page: page, literal: literal,
              attributes: attributes)
    }

    /// Add a child element with text only when the value is non-nil.
    @inlinable
    public mutating func element(_ tag: String, text value: String?,
                                 page: UInt8? = nil, literal: Bool = false,
                                 attributes: [ WBXMLAttribute ] = [])
    {
      guard let value else { return }
      element(tag, text: value, page: page, literal: literal,
              attributes: attributes)
    }

    /// Add a child element with nested children.
    @inlinable
    public mutating func element(_ tag: String, page: UInt8? = nil,
                                 literal: Bool = false,
                                 attributes: [ WBXMLAttribute ] = [],
                                 build: (inout ElementBuilder) throws -> Void)
      rethrows
    {
      let elementPage = page ?? inheritedPage
      var child       = ElementBuilder(inheritedPage: elementPage)
      try build(&child)
      nodes.append(
        .element(WBXMLElement(tag: tag, page: elementPage, literal: literal,
                              attributes: attributes, children: child.nodes)))
    }

    /// Add an empty child element.
    @inlinable
    public mutating func element(_ tag: String, page: UInt8? = nil,
                                 literal: Bool = false,
                                 attributes: [ WBXMLAttribute ] = [])
    {
      nodes.append(
        .element(WBXMLElement(tag: tag, page: page ?? inheritedPage,
                              literal: literal, attributes: attributes)))
    }

    /// Add an inline string node.
    @inlinable
    public mutating func text(_ value: String) { nodes.append(.text(value)) }

    /// Add a string-table string node.
    @inlinable
    public mutating func stringTable(_ value: String) {
      nodes.append(.stringTable(value))
    }

    /// Add a numeric character entity.
    @inlinable
    public mutating func entity(_ value: UInt32) {
      nodes.append(.entity(value))
    }

    /// Add an inline extension token.
    @inlinable
    public mutating func extensionInline(_ index: UInt8, value: String,
                                         page: UInt8? = nil)
    {
      nodes.append(.extensionInline(index: index, value: value, page: page))
    }

    /// Add an integer extension token.
    @inlinable
    public mutating func extensionInteger(_ index: UInt8, value: UInt32,
                                          page: UInt8? = nil)
    {
      nodes.append(.extensionInteger(index: index, value: value, page: page))
    }

    /// Add an extension token without a payload.
    @inlinable
    public mutating func `extension`(_ index: UInt8, page: UInt8? = nil) {
      nodes.append(.extension(index: index, page: page))
    }

    /// Add a processing instruction.
    @inlinable
    public mutating func processingInstruction(_ instruction:
                                               WBXMLProcessingInstruction)
    {
      nodes.append(.processingInstruction(instruction))
    }

    /// Add opaque binary data.
    @inlinable
    public mutating func opaque(_ data: [ UInt8 ]) {
      nodes.append(.opaque(data))
    }
  }
}
