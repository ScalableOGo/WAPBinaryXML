//
//  WBXMLEncoder.swift
//  WAPBinaryXML
//
//  Created by Helge Hess on 06.04.26.
//  Copyright © 2026 ZeeZide GmbH. All rights reserved.
//

/**
 * Encodes a document tree to WBXML binary data.
 *
 * This can be used multiple on multiple documents/elements and is reentrant.
 */
public struct WBXMLEncoder: Sendable {

  /// Code pages used to resolve tag and attribute tokens.
  public let codePages : WBXMLCodePage.Set

  /// Resource limits applied during encoding.
  public let limits    : WBXMLResourceLimits

  /// Create an encoder bound to a code page set.
  @inlinable
  public init(codePages : WBXMLCodePage.Set,
              limits    : WBXMLResourceLimits = .default)
  {
    self.codePages = codePages
    self.limits    = limits
  }

  /// Encode a full document to WBXML binary.
  public func encode(_ document: WBXMLDocument) throws -> ContiguousArray<UInt8>
  {
    guard document.version == 0x03 else {
      throw WBXMLError.unsupportedVersion(document.version)
    }

    do    { try codePages.validate() }
    catch { throw WBXMLError.invalidCodePage(error) }

    let charset = document.charset
    var stringTable = try StringTableBuilder(
      charset: charset, maximumBytes: limits.maximumStringTableBytes,
      retaining: document.stringTable
    )
    var tracker = WBXMLResourceLimits.Tracker(limits: limits)

    try preflight(document, stringTable: &stringTable, tracker: &tracker)

    var output = EncodingBuffer(maximumBytes: limits.maximumDocumentBytes)
    try output.append(document.version)

    switch document.publicIdentifier {
      case .numeric(let value):
        guard value != 0 else { throw WBXMLError.invalidPublicIdentifier }
        try output.appendMBUInt32(value)

      case .literal(let value):
        try output.appendMBUInt32(0)
        let offset = try stringTable.offset(for: value)
        try output.appendMBUInt32(offset)
    }

    try output.appendMBUInt32(charset.rawValue)
    try output.appendMBUInt32(try stringTable.length())
    try output.append(contentsOf: stringTable.bytes)

    var pages = EncodingPages()
    for instruction in document.processingInstructionsBeforeRoot {
      try encodePI(instruction, stringTable: stringTable,
                   charset: charset, into: &output, pages: &pages)
    }

    try encodeElement(document.root, depth: 1, stringTable: stringTable,
                      charset: charset, into: &output, pages: &pages)

    for instruction in document.processingInstructionsAfterRoot {
      try encodePI(instruction, stringTable: stringTable,
                   charset: charset, into: &output, pages: &pages)
    }

    return output.bytes
  }

  /// Encode a root element with the default WBXML header.
  @inlinable
  public func encode(_ root: WBXMLElement) throws -> ContiguousArray<UInt8> {
    try encode(WBXMLDocument(root: root))
  }
}

// MARK: - Tokens

extension WBXMLEncoder {

  static let switchPage     : UInt8 = 0x00
  static let end            : UInt8 = 0x01
  static let entity         : UInt8 = 0x02
  static let strI           : UInt8 = 0x03
  static let literal        : UInt8 = 0x04
  static let extensionI     : UInt8 = 0x40
  static let pi             : UInt8 = 0x43
  static let extensionT     : UInt8 = 0x80
  static let strT           : UInt8 = 0x83
  static let extensionToken : UInt8 = 0xC0
  static let opaque         : UInt8 = 0xC3
  static let contentBit     : UInt8 = 0x40
  static let attrBit        : UInt8 = 0x80
}

// MARK: - Primitive Encoding

extension WBXMLEncoder {

  func encodeInlineString(_ value: String, token: UInt8, charset: WBXMLCharset,
                          into output: inout EncodingBuffer) throws
  {
    try output.append(token)
    try output.appendTerminated(value, charset: charset)
  }

  func checkDepth(_ depth: Int) throws {
    guard depth <= limits.maximumDepth else {
      throw WBXMLError.resourceLimitExceeded(.depth)
    }
  }

  static func validateEntity(_ value: UInt32) throws {
    guard Unicode.Scalar(value) != nil,
          XMLValidation.isValidScalar(value) else
    {
      throw WBXMLError.invalidXMLScalar(value)
    }
  }

  static func validateExtensionIndex(_ index: UInt8) throws {
    guard index <= 2 else { throw WBXMLError.invalidExtensionIndex(index) }
  }

  static func validateLength(_ count: Int) throws {
    guard count >= 0, UInt64(count) <= UInt64(UInt32.max) else {
      throw WBXMLError.lengthOverflow
    }
  }

  static func uint32Length(_ count: Int) throws -> UInt32 {
    try validateLength(count)
    return UInt32(count)
  }
}
