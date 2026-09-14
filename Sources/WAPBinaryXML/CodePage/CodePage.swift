//
//  CodePage.swift
//  WAPBinaryXML
//
//  Created by Helge Hess on 06.04.26.
//  Copyright © 2026 ZeeZide GmbH. All rights reserved.
//

/// A single tag and attribute code page.
public struct WBXMLCodePage: Sendable {

  /// Code page number.
  public let page            : UInt8

  /// Namespace URI, such as `AirSync:`.
  public let namespace       : String

  /// Tag token to name mapping.
  public let tokenToName     : [ UInt8 : String ]

  /// Attribute-start token definitions.
  public let attributeStarts : [ UInt8 : AttributeStartDefinition ]

  /// Attribute-value token definitions.
  public let attributeValues : [ UInt8 : AttributeValueDefinition ]

  @usableFromInline
  let tagNameIndex        : [ WBXMLExactStringKey : UInt8 ]

  @usableFromInline
  let attributeStartIndex : [ AttributeStartKey : UInt8 ]

  @usableFromInline
  let attributeValueIndex : [ WBXMLExactStringKey : UInt8 ]

  @usableFromInline
  let validationErrors    : [ ParseError ]

  /**
   * Create a code page from tag/tokens.
   *
   * Invalid definitions are retained as validation errors.
   */
  public init(page: UInt8, namespace: String, tokens: [ ( UInt8, String ) ],
              attributeStarts: [ AttributeStartDefinition ] = [],
              attributeValues: [ AttributeValueDefinition ] = [])
  {
    self.page      = page
    self.namespace = namespace

    var tokenToName  = [ UInt8               : String ]()
    var tagNameIndex = [ WBXMLExactStringKey : UInt8 ]()
    var starts       = [ UInt8               : AttributeStartDefinition ]()
    var startIndex   = [ AttributeStartKey   : UInt8 ]()
    var values       = [ UInt8               : AttributeValueDefinition ]()
    var valueIndex   = [ WBXMLExactStringKey : UInt8 ]()
    var errors       = [ ParseError                  ]()

    for ( token, name ) in tokens {
      let reference = TokenReference(page: page, token: token)
      let nameKey = WBXMLExactStringKey(name)
      if !Self.isValidTagToken(token) {
        errors.append(.invalidTagToken(reference))
      }
      if name.isEmpty { errors.append(.emptyTagName(reference)) }
      else if !XMLValidation.isName(name) {
        errors.append(.invalidTagName(reference, name: name))
      }
      if tokenToName[token] != nil {
        errors.append(.duplicateTagToken(reference))
      }
      if tagNameIndex[nameKey] != nil {
        errors.append(.duplicateTagName(page: page, name: name))
      }
      if tokenToName[token] == nil { tokenToName[token] = name }
      if tagNameIndex[nameKey] == nil { tagNameIndex[nameKey] = token }
    }

    for definition in attributeStarts {
      let reference = TokenReference(page: page, token: definition.token)
      let key = AttributeStartKey(name: definition.name,
                                  valuePrefix: definition.valuePrefix)
      if !Self.isValidAttributeStartToken(definition.token) {
        errors.append(.invalidAttributeStartToken(reference))
      }
      if definition.name.isEmpty {
        errors.append(.emptyAttributeName(reference))
      }
      else if !XMLValidation.isName(definition.name) {
        errors.append(.invalidAttributeName(reference, name: definition.name))
      }
      if let prefix = definition.valuePrefix,
         !XMLValidation.isValidString(prefix)
      {
        errors.append(.invalidAttributeValuePrefix(reference))
      }
      if starts[definition.token] != nil {
        errors.append(.duplicateAttributeStartToken(reference))
      }
      if startIndex[key] != nil {
        errors.append(
          .duplicateAttributeStart(page: page, name: definition.name,
                                   valuePrefix: definition.valuePrefix))
      }
      if starts[definition.token] == nil {
        starts[definition.token] = definition
      }
      if startIndex[key] == nil { startIndex[key] = definition.token }
    }

    for definition in attributeValues {
      let reference = TokenReference(page: page, token: definition.token)
      let valueKey = WBXMLExactStringKey(definition.value)
      if !Self.isValidAttributeValueToken(definition.token) {
        errors.append(.invalidAttributeValueToken(reference))
      }
      if values[definition.token] != nil {
        errors.append(.duplicateAttributeValueToken(reference))
      }
      if !XMLValidation.isValidString(definition.value) {
        errors.append(.invalidAttributeValueText(reference))
      }
      if valueIndex[valueKey] != nil {
        errors.append(
          .duplicateAttributeValue(page: page, value: definition.value))
      }
      if values[definition.token] == nil {
        values[definition.token] = definition
      }
      if valueIndex[valueKey] == nil { valueIndex[valueKey] = definition.token }
    }

    self.tokenToName         = tokenToName
    self.tagNameIndex        = tagNameIndex
    self.attributeStarts     = starts
    self.attributeValues     = values
    self.attributeStartIndex = startIndex
    self.attributeValueIndex = valueIndex
    self.validationErrors    = errors
  }

  /// Throw the first validation error, if any.
  @inlinable
  public func validate() throws(ParseError) {
    if let error = validationErrors.first { throw error }
  }

  /// Find an attribute-start token on this page.
  @inlinable
  public func attributeStartToken(for name: String,
                                  valuePrefix: String? = nil) -> UInt8?
  {
    attributeStartIndex[AttributeStartKey(name: name, valuePrefix: valuePrefix)]
  }

  /// Find a tag token using the name's exact UTF-8 identity.
  @inlinable
  public func tagToken(for name: String) -> UInt8? {
    tagNameIndex[WBXMLExactStringKey(name)]
  }

  /// Find an attribute-value token on this page.
  @inlinable
  public func attributeValueToken(for value: String) -> UInt8? {
    attributeValueIndex[WBXMLExactStringKey(value)]
  }
}

private extension WBXMLCodePage {

  static func isValidTagToken(_ token: UInt8) -> Bool {
    token >= 0x05 && token <= 0x3F
  }

  static func isValidAttributeStartToken(_ token: UInt8) -> Bool {
    (token >= 0x05 && token <= 0x3F) || (token >= 0x45 && token <= 0x7F)
  }

  static func isValidAttributeValueToken(_ token: UInt8) -> Bool {
    (token >= 0x85 && token <= 0xBF) || (token >= 0xC5 && token <= 0xFF)
  }
}
