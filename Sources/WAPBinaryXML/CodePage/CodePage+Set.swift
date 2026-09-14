//
//  CodePageSet.swift
//  WAPBinaryXML
//
//  Created by Helge Hess on 11.09.26.
//  Copyright © 2026 ZeeZide GmbH. All rights reserved.
//

extension WBXMLCodePage {

  /// A set of code pages for a WBXML language, such as ActiveSync or SyncML.
  public struct Set: Sendable {

    /// Pages keyed by page number.
    public let pages        : [ UInt8 : WBXMLCodePage ]

    @usableFromInline
    let nameIndex           : [ WBXMLExactStringKey : TokenReference ]

    @usableFromInline
    let attributeStartIndex : [ AttributeStartKey   : TokenReference ]

    @usableFromInline
    let attributeValueIndex : [ WBXMLExactStringKey : TokenReference ]

    @usableFromInline
    let validationErrors    : [ ParseError ]

    /**
     * Build a new code page set.
     */
    public init(_ pages: [ WBXMLCodePage ]) {
      var pageMap          = [ UInt8 : WBXMLCodePage ]()
      var nameIndex        = [ WBXMLExactStringKey : TokenReference ]()
      var startIndex       = [ AttributeStartKey   : TokenReference ]()
      var valueIndex       = [ WBXMLExactStringKey : TokenReference ]()
      var validationErrors = [ ParseError ]()

      for codePage in pages {
        validationErrors.append(contentsOf: codePage.validationErrors)
        if pageMap[codePage.page] != nil {
          validationErrors.append(.duplicatePage(codePage.page))
          continue
        }
        pageMap[codePage.page] = codePage

        for ( name, token ) in codePage.tagNameIndex
          where nameIndex[name] == nil
        {
          nameIndex[name] = TokenReference(page: codePage.page, token: token)
        }
        for definition in codePage.attributeStarts.values {
          let key = AttributeStartKey(name: definition.name,
                                      valuePrefix: definition.valuePrefix)
          if startIndex[key] == nil {
            startIndex[key] = TokenReference(page: codePage.page,
                                             token: definition.token)
          }
        }
        for definition in codePage.attributeValues.values {
          let key = WBXMLExactStringKey(definition.value)
          if valueIndex[key] == nil {
            valueIndex[key] = TokenReference(page: codePage.page,
                                             token: definition.token)
          }
        }
      }

      self.pages               = pageMap
      self.nameIndex           = nameIndex
      self.attributeStartIndex = startIndex
      self.attributeValueIndex = valueIndex
      self.validationErrors    = validationErrors
    }

    /// Throw the first invalid or duplicate definition, if any.
    @inlinable
    public func validate() throws(ParseError) {
      if let error = validationErrors.first { throw error }
    }

    /// Look up a tag name by page and token.
    @inlinable
    public func name(page: UInt8, token: UInt8) -> String? {
      pages[page]?.tokenToName[token]
    }

    /// Look up a tag token on any page.
    @inlinable
    public func token(for name: String) -> TokenReference? {
      nameIndex[WBXMLExactStringKey(name)]
    }

    /// Look up an attribute-start definition by page and token.
    @inlinable
    public func attributeStart(page: UInt8, token: UInt8)
                -> AttributeStartDefinition?
    {
      pages[page]?.attributeStarts[token]
    }

    /// Look up an attribute-start token on any page.
    @inlinable
    public func attributeStartToken(for name: String,
                                    valuePrefix: String? = nil)
                -> TokenReference?
    {
      attributeStartIndex[AttributeStartKey(name: name,
                                            valuePrefix: valuePrefix)]
    }

    /// Look up an attribute-value definition by page and token.
    @inlinable
    public func attributeValue(page: UInt8, token: UInt8)
      -> AttributeValueDefinition?
    {
      pages[page]?.attributeValues[token]
    }

    /// Look up an attribute-value token on any page.
    @inlinable
    public func attributeValueToken(for value: String) -> TokenReference? {
      attributeValueIndex[WBXMLExactStringKey(value)]
    }
  }
}
