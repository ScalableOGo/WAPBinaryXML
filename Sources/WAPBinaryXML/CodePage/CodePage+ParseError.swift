//
//  CodePageParseError.swift
//  WAPBinaryXML
//
//  Created by Helge Hess on 11.09.26.
//  Copyright © 2026 ZeeZide GmbH. All rights reserved.
//

extension WBXMLCodePage {

  /// Code-page validation errors.
  public enum ParseError: Error, Sendable, Equatable {

    /// A tag token was outside its application-token range.
    case invalidTagToken(TokenReference)

    /// A tag definition had an empty name.
    case emptyTagName(TokenReference)

    /// A tag definition did not use an XML 1.0 `Name`.
    case invalidTagName(TokenReference, name: String)

    /// A page defined the same tag token more than once.
    case duplicateTagToken(TokenReference)

    /// A page defined the same tag name more than once.
    case duplicateTagName(page: UInt8, name: String)

    /// An attribute-start token overlapped a reserved global token.
    case invalidAttributeStartToken(TokenReference)

    /// An attribute-start definition had an empty name.
    case emptyAttributeName(TokenReference)

    /// An attribute-start definition did not use an XML 1.0 `Name`.
    case invalidAttributeName(TokenReference, name: String)

    /// An attribute-start value prefix contained a forbidden XML character.
    case invalidAttributeValuePrefix(TokenReference)

    /// A page defined the same attribute-start token more than once.
    case duplicateAttributeStartToken(TokenReference)

    /// A page repeated an attribute name and value-prefix pair.
    case duplicateAttributeStart(page: UInt8, name: String,
                                 valuePrefix: String?)

    /// An attribute-value token overlapped a reserved global token.
    case invalidAttributeValueToken(TokenReference)

    /// A page defined the same attribute-value token more than once.
    case duplicateAttributeValueToken(TokenReference)

    /// A page defined the same attribute-value text more than once.
    case duplicateAttributeValue(page: UInt8, value: String)

    /// An attribute-value token contained a forbidden XML character.
    case invalidAttributeValueText(TokenReference)

    /// A code-page set contained the same page number more than once.
    case duplicatePage(UInt8)
  }
}
