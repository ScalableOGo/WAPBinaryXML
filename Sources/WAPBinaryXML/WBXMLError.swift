//
//  WBXMLError.swift
//  WAPBinaryXML
//
//  Created by Helge Hess on 06.04.26.
//  Copyright © 2026 ZeeZide GmbH. All rights reserved.
//

/// Errors thrown during WBXML encoding or decoding.
public enum WBXMLError: Error, Equatable, Sendable {

  /// A string payload was not valid UTF-8.
  case invalidUTF8

  /// The IANA charset MIBenum is not supported by this codec.
  case unsupportedCharset(UInt32)

  /// A null-terminated string contained U+0000.
  case embeddedNull

  /// A string or entity contained a scalar forbidden by XML 1.0.
  case invalidXMLScalar(UInt32)

  /// A string reached its containing buffer without a null terminator.
  case unterminatedString

  /// A string-table reference did not identify a table string.
  case invalidStringTableOffset(Int)

  /// A payload length or string-table offset exceeded `UInt32`.
  case lengthOverflow

  /// The WBXML version is not supported by this codec.
  case unsupportedVersion(UInt8)

  /// A retained table's charset differs from the document's charset.
  case stringTableCharsetMismatch(table: WBXMLCharset, document: WBXMLCharset)

  /// An element, attribute, or processing-instruction name was not an XML Name.
  case invalidXMLName

  /// A processing-instruction target was the reserved name `xml`.
  case invalidProcessingInstructionTarget(String)

  /// Known processing-instruction text contained the XML delimiter `?>`.
  case invalidProcessingInstructionData

  /// An element contained the same XML attribute name more than once.
  case duplicateAttribute(String)

  /// A scalar cannot be represented by the document charset.
  case unrepresentableCharacter(charset: WBXMLCharset, scalar: UInt32)

  /// An application token required a page absent from the code-page set.
  case unknownCodePage(UInt8)

  /// A literal or numeric public identifier was malformed.
  case invalidPublicIdentifier

  /// An attribute or processing instruction was malformed.
  case invalidAttribute

  /// Encoder preflight omitted a required string-table entry.
  case missingStringTableEntry(String)

  /// No configured page defines the requested automatic element name.
  case unknownElement(String)

  /// The explicitly selected page does not define the element name.
  case unknownElementOnPage(String, UInt8)

  /// No configured page defines the requested automatic attribute name.
  case unknownAttribute(String)

  /// The explicitly selected page does not define the attribute name.
  case unknownAttributeOnPage(String, UInt8)

  /// No configured page defines the automatic attribute value token.
  case unknownAttributeValue(String)

  /// The selected page does not define the attribute value token.
  case unknownAttributeValueOnPage(String, UInt8)

  /// An extension index was outside the valid range zero through two.
  case invalidExtensionIndex(UInt8)

  /// A code-page definition failed validation.
  case invalidCodePage(WBXMLCodePage.ParseError)

  /// Encoding or decoding exceeded a configured resource limit.
  case resourceLimitExceeded(WBXMLResourceLimits.Kind)
}
