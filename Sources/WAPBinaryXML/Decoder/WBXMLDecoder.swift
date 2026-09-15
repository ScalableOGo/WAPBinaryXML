//
//  WBXMLDecoder.swift
//  WAPBinaryXML
//
//  Created by Helge Hess on 06.04.26.
//  Copyright © 2026 ZeeZide GmbH. All rights reserved.
//

/**
 * Decodes WBXML 1.3 data into ``WBXMLDocument``.
 *
 * Failures throw ``WBXMLDecoder.ParseError``.
 */
public struct WBXMLDecoder: Sendable {

  /// Code pages used to resolve tag and attribute tokens.
  public let codePages : WBXMLCodePage.Set

  /// Resource limits applied to untrusted input.
  public let limits    : WBXMLResourceLimits

  @inlinable
  public init(codePages : WBXMLCodePage.Set,
              limits    : WBXMLResourceLimits = .default)
  {
    self.codePages = codePages
    self.limits    = limits
  }

  @inlinable
  public func decode<C: Collection>(_ bytes: C) throws -> WBXMLDocument
    where C.Element == UInt8
  {
    if let document = try bytes
      .withContiguousStorageIfAvailable({ try decode($0.span) })
    {
      return document
    }

    do {
      do    { try codePages.validate() }
      catch { throw WBXMLError.invalidCodePage(error) }
      
      guard limits.maximumDocumentBytes >= 0,
            bytes.count <= limits.maximumDocumentBytes else
      {
        throw WBXMLError.resourceLimitExceeded(.documentBytes)
      }
      let storage = ContiguousArray(bytes)
      return try decode(storage.span)
    }
    catch let reason as WBXMLError {
      throw ParseError(reason: reason, offset: 0)
    }
  }

  /// Decode a byte span, attaching cursor positions to codec errors.
  public func decode(_ bytes: Span<UInt8>) throws -> WBXMLDocument {
    var state = ParserState(tracker: .init(limits: limits))

    do {
      return try decodeDocument(bytes, state: &state)
    }
    catch let reason as WBXMLError {
      throw ParseError(reason: reason, offset: state.cursor.offset)
    }
  }

  private func decodeDocument(_ bytes: Span<UInt8>, state: inout ParserState)
    throws -> WBXMLDocument
  {
    do    { try codePages.validate() }
    catch { throw WBXMLError.invalidCodePage(error) }

    guard limits.maximumDocumentBytes >= 0,
          bytes.count <= limits.maximumDocumentBytes else
    {
      throw WBXMLError.resourceLimitExceeded(.documentBytes)
    }

    let version = try state.cursor.readByte(bytes)
    guard version == 0x03 else { throw WBXMLError.unsupportedVersion(version) }

    let publicId     = try state.cursor.readMBUInt32(bytes)
    let publicIdIndex : UInt32?
    if publicId == 0 { publicIdIndex = try state.cursor.readMBUInt32(bytes) }
    else             { publicIdIndex = nil }

    let charset = try state.cursor.readMBUInt32(bytes)
    guard let encoding = WBXMLCharset(rawValue: charset) else {
      throw WBXMLError.unsupportedCharset(charset)
    }

    let tableLengthValue = try state.cursor.readMBUInt32(bytes)
    guard let tableLength = Int(exactly: tableLengthValue),
          limits.maximumStringTableBytes >= 0,
          tableLength <= limits.maximumStringTableBytes else
    {
      throw WBXMLError.resourceLimitExceeded(.stringTableBytes)
    }
    let tableRange = try state.cursor.skipBytes(tableLength, bytes)
    try Self.validateStringTable(bytes, range: tableRange, charset: encoding)

    state.charset        = encoding
    state.stringTable    = tableRange
    let publicIdentifier : WBXMLPublicIdentifier
    if let index = publicIdIndex {
      let value = try readStringTable(bytes, state: &state, at: index)
      try XMLValidation.validatePublicIdentifier(value)
      publicIdentifier = .literal(value)
    }
    else { publicIdentifier = .numeric(publicId) }

    var beforeRoot = [ WBXMLProcessingInstruction ]()
    while state.cursor.peek(bytes) == Self.pi {
      beforeRoot.append(try parseProcessingInstruction(bytes, state: &state))
    }

    guard let firstBodyByte = state.cursor.peek(bytes) else {
      throw WBXMLError.missingRoot
    }
    if firstBodyByte == Self.end { throw WBXMLError.unmatchedEnd }
    guard Self.isElementStart(firstBodyByte)
       || firstBodyByte == Self.switchPage else
    {
      throw WBXMLError.unexpectedGlobalToken(firstBodyByte)
    }
    let root = try parseElement(bytes, state: &state)

    var afterRoot = [ WBXMLProcessingInstruction ]()
    while state.cursor.peek(bytes) == Self.pi {
      afterRoot.append(try parseProcessingInstruction(bytes, state: &state))
    }

    if state.cursor.peek(bytes) == Self.end { throw WBXMLError.unmatchedEnd }
    guard state.cursor.offset == bytes.count else {
      throw WBXMLError.trailingData
    }

    let table: WBXMLStringTable?
    if tableRange.isEmpty {
      table = nil
    }
    else {
      let tableBytes = bytes.extracting(tableRange).withUnsafeBufferPointer {
        ContiguousArray($0)
      }
      var retained = try WBXMLStringTable(bytes: tableBytes, charset: encoding)
      retained.offsets.merge(state.tableReferences) { original, _ in original }
      table = retained
    }
    return WBXMLDocument(version: version, publicIdentifier: publicIdentifier,
                          charset: encoding, stringTable: table, root: root,
                          processingInstructionsBeforeRoot: beforeRoot,
                          processingInstructionsAfterRoot: afterRoot)
  }
}

// MARK: - Strings, Entities, and Opaque Data

private extension WBXMLDecoder {

  func readInlineString(_ bytes: Span<UInt8>, state: inout ParserState)
    throws -> String
  {
    let range = try state.cursor.readTerminatedRange(bytes)
    try state.tracker.addText(range.count)
    return try Self.decodeString(bytes, range: range, charset: state.charset)
  }

  func readStringTable(_ bytes: Span<UInt8>, state: inout ParserState,
                       at index: UInt32) throws -> String
  {
    guard let offset = Int(exactly: index) else {
      throw WBXMLError.lengthOverflow
    }
    guard offset < state.stringTable.count else {
      throw WBXMLError.invalidStringTableOffset(offset)
    }

    let start = state.stringTable.lowerBound + offset
    var end   = start
    while end < state.stringTable.upperBound && bytes[end] != 0 { end += 1 }
    guard end < state.stringTable.upperBound else {
      throw WBXMLError.unterminatedString
    }

    let range = start ..< end
    try state.tracker.addText(range.count)
    let value = try Self.decodeString(bytes, range: range,
                                       charset: state.charset)
    let key = WBXMLExactStringKey(value)
    if state.tableReferences[key] == nil { state.tableReferences[key] = index }
    return value
  }

  func readOpaque(_ bytes: Span<UInt8>, state: inout ParserState)
    throws -> [ UInt8 ]
  {
    let lengthValue = try state.cursor.readMBUInt32(bytes)
    guard let length = Int(exactly: lengthValue) else {
      throw WBXMLError.resourceLimitExceeded(.opaqueBytes)
    }
    try state.tracker.addOpaque(length)
    return try state.cursor.readBytes(length, bytes)
  }

  static func validateStringTable(_ bytes: Span<UInt8>, range: Range<Int>,
                                  charset: WBXMLCharset) throws
  {
    var start = range.lowerBound
    while start < range.upperBound {
      var end = start
      while end < range.upperBound && bytes[end] != 0 { end += 1 }
      guard end < range.upperBound else { throw WBXMLError.unterminatedString }

      _ = try decodeString(bytes, range: start ..< end, charset: charset)
      start = end + 1
    }
  }

  static func decodeString(_ bytes: Span<UInt8>, range: Range<Int>,
                           charset: WBXMLCharset) throws -> String
  {
    let slice = bytes.extracting(range)
    return try slice.withUnsafeBufferPointer { pointer in
      try charset.decode(pointer)
    }
  }

  static func validateXMLScalar(_ value: UInt32) throws {
    guard XMLValidation.isValidScalar(value) else {
      throw WBXMLError.invalidXMLScalar(value)
    }
  }
}

// MARK: - Page Switching

private extension WBXMLDecoder {

  func readTagPageSwitch(_ bytes:Span<UInt8>, state: inout ParserState) throws {
    let token = try state.cursor.readByte(bytes)
    guard token == Self.switchPage else {
      throw WBXMLError.invalidToken(.init(page: state.tagPage, token: token))
    }
    state.tagPage = try state.cursor.readByte(bytes)
  }

  func readAttributePageSwitch(_ bytes: Span<UInt8>,
                               state: inout ParserState) throws
  {
    let token = try state.cursor.readByte(bytes)
    guard token == Self.switchPage else {
      throw WBXMLError
        .invalidToken(.init(page: state.attributePage, token: token))
    }
    state.attributePage = try state.cursor.readByte(bytes)
  }
}

// MARK: - Token Constants

private extension WBXMLDecoder {

  static let switchPage : UInt8 = 0x00
  static let end        : UInt8 = 0x01
  static let entity     : UInt8 = 0x02
  static let strI       : UInt8 = 0x03
  static let literal    : UInt8 = 0x04
  static let extI0      : UInt8 = 0x40
  static let extI1      : UInt8 = 0x41
  static let extI2      : UInt8 = 0x42
  static let pi         : UInt8 = 0x43
  static let literalC   : UInt8 = 0x44
  static let extT0      : UInt8 = 0x80
  static let extT1      : UInt8 = 0x81
  static let extT2      : UInt8 = 0x82
  static let strT       : UInt8 = 0x83
  static let literalA   : UInt8 = 0x84
  static let ext0       : UInt8 = 0xC0
  static let ext1       : UInt8 = 0xC1
  static let ext2       : UInt8 = 0xC2
  static let opaque     : UInt8 = 0xC3
  static let literalAC  : UInt8 = 0xC4

  static let contentBit : UInt8 = 0x40
  static let attrBit    : UInt8 = 0x80
  static let tokenMask  : UInt8 = 0x3F

  static func isElementStart(_ token: UInt8) -> Bool {
    token == literal || token == literalC
      || token == literalA || token == literalAC
      || (token >= 0x05 && token <= 0x3F)
      || (token >= 0x45 && token <= 0x7F)
      || (token >= 0x85 && token <= 0xBF)
      || (token >= 0xC5 && token <= 0xFF)
  }

  static func isAttributeStart(_ token: UInt8) -> Bool {
    token == literal || (token >= 0x05 && token <= 0x3F)
      || (token >= 0x45 && token <= 0x7F)
  }

  static func isAttributeValueToken(_ token: UInt8) -> Bool {
    (token >= 0x85 && token <= 0xBF) || (token >= 0xC5 && token <= 0xFF)
  }

  static func isExtension(_ token: UInt8) -> Bool {
    (token >= extI0 && token <= extI2) || (token >= extT0 && token <= extT2)
      || (token >= ext0 && token <= ext2)
  }
}

// MARK: - Attribute and PI Parsing

private extension WBXMLDecoder {

  func parseAttributes(_ bytes: Span<UInt8>, state: inout ParserState)
    throws -> [ WBXMLAttribute ]
  {
    var attributes     = [ WBXMLAttribute ]()
    var attributeNames = Set<WBXMLExactStringKey>()
    while true {
      guard let token = state.cursor.peek(bytes) else {
        throw WBXMLError.unexpectedEnd
      }
      if token == Self.end {
        guard !attributes.isEmpty else { throw WBXMLError.invalidAttribute }
        state.cursor.advance()
        return attributes
      }

      if token == Self.switchPage {
        try readAttributePageSwitch(bytes, state: &state)
        guard let next = state.cursor.peek(bytes), next != Self.literal,
              Self.isAttributeStart(next) else
        {
          throw WBXMLError.invalidAttribute
        }
      }

      guard let start = state.cursor.peek(bytes),
            Self.isAttributeStart(start) else
      {
        throw WBXMLError.invalidAttribute
      }
      try state.tracker.checkAttributes(attributes.count + 1)
      let attribute = try parseAttribute(bytes, state: &state)
      guard attribute.valuePrefix != nil || !attribute.values.isEmpty else {
        throw WBXMLError.invalidAttribute
      }
      let nameKey = WBXMLExactStringKey(attribute.name)
      guard attributeNames.insert(nameKey).inserted else {
        throw WBXMLError.duplicateAttribute(attribute.name)
      }
      attributes.append(attribute)
    }
  }

  func parseAttribute(_ bytes: Span<UInt8>, state: inout ParserState)
    throws -> WBXMLAttribute
  {
    try state.tracker.addNode()

    let token     = try state.cursor.readByte(bytes)
    let page      = state.attributePage
    let name      : String
    let prefix    : String?
    let isLiteral : Bool
    if token == Self.literal {
      let index = try state.cursor.readMBUInt32(bytes)
      name      = try readStringTable(bytes, state: &state, at: index)
      prefix    = nil
      isLiteral = true
    }
    else {
      guard (token >= 0x05 && token <= 0x3F)
         || (token >= 0x45 && token <= 0x7F) else
      {
        throw WBXMLError.invalidAttribute
      }
      guard codePages.pages[page] != nil else {
        throw WBXMLError.unknownCodePage(page)
      }
      guard let definition =
              codePages.attributeStart(page: page, token: token) else
      {
        throw WBXMLError.unknownToken(.init(page: page, token: token))
      }
      name      = definition.name
      prefix    = definition.valuePrefix
      isLiteral = false
    }
    
    try XMLValidation.validateName(name)
    _ = try state.charset.encodedByteCount(of: name)
    if let prefix {
      _ = try state.charset.encodedByteCount(of: prefix)
    }

    let values = try parseAttributeValues(bytes, state: &state)
    return WBXMLAttribute(name: name, page: isLiteral ? nil : page,
                          literal: isLiteral,
                          valuePrefix: prefix, values: values)
  }

  func parseAttributeValues(_ bytes: Span<UInt8>, state: inout ParserState)
    throws -> [ WBXMLAttributeValue ]
  {
    var values = [ WBXMLAttributeValue ]()

    while true {
      guard let token = state.cursor.peek(bytes) else {
        throw WBXMLError.unexpectedEnd
      }
      if token == Self.end || Self.isAttributeStart(token) { return values }

      if token == Self.switchPage {
        try readAttributePageSwitch(bytes, state: &state)
        guard let next = state.cursor.peek(bytes) else {
          throw WBXMLError.unexpectedEnd
        }
        if next == Self.literal { throw WBXMLError.invalidAttribute }
        if Self.isAttributeStart(next) { return values }
        guard Self.isAttributeValueToken(next) || Self.isExtension(next) else {
          throw WBXMLError.invalidAttribute
        }
        continue
      }

      switch token {
        case Self.strI:
          state.cursor.advance()
          try state.tracker.addNode()
          values.append(.text(try readInlineString(bytes, state: &state)))

        case Self.strT:
          state.cursor.advance()
          try state.tracker.addNode()
          let index = try state.cursor.readMBUInt32(bytes)
          let value = try readStringTable(bytes, state: &state, at: index)
          values.append(.stringTable(value))

        case Self.entity:
          state.cursor.advance()
          try state.tracker.addNode()
          let value = try state.cursor.readMBUInt32(bytes)
          try Self.validateXMLScalar(value)
          values.append(.entity(value))

        case _ where token >= Self.extI0 && token <= Self.extI2:
          state.cursor.advance()
          try state.tracker.addNode()
          let value = try readInlineString(bytes, state: &state)
          values.append(.extensionInline(index: token - Self.extI0,
                                         value: value,
                                         page: state.attributePage))

        case _ where token >= Self.extT0 && token <= Self.extT2:
          state.cursor.advance()
          try state.tracker.addNode()
          let value = try state.cursor.readMBUInt32(bytes)
          values.append(.extensionInteger(index: token - Self.extT0,
                                          value: value,
                                          page: state.attributePage))

        case _ where token >= Self.ext0 && token <= Self.ext2:
          state.cursor.advance()
          try state.tracker.addNode()
          values.append(
            .extension(index: token - Self.ext0, page: state.attributePage))

        case Self.opaque:
          state.cursor.advance()
          try state.tracker.addNode()
          values.append(.opaque(try readOpaque(bytes, state: &state)))

        default:
          guard Self.isAttributeValueToken(token) else {
            throw WBXMLError.unexpectedGlobalToken(token)
          }
          let page = state.attributePage
          guard codePages.pages[page] != nil else {
            throw WBXMLError.unknownCodePage(page)
          }

          guard let definition = codePages.attributeValue(page: page,
                                                          token: token) else
          {
            throw WBXMLError.unknownToken(.init(page: page, token: token))
          }

          _ = try state.charset.encodedByteCount(of: definition.value)
          state.cursor.advance()
          try state.tracker.addNode()
          values.append(.token(definition.value, page: page))
      }
    }
  }

  func parseProcessingInstruction(_ bytes: Span<UInt8>,
                                  state: inout ParserState)
    throws -> WBXMLProcessingInstruction
  {
    let token = try state.cursor.readByte(bytes)
    guard token == Self.pi else {
      throw WBXMLError.unexpectedGlobalToken(token)
    }

    try state.tracker.addNode()
    try state.tracker.checkAttributes(1)

    if state.cursor.peek(bytes) == Self.switchPage {
      try readAttributePageSwitch(bytes, state: &state)
      guard let next = state.cursor.peek(bytes), next != Self.literal,
            Self.isAttributeStart(next) else
      {
        throw WBXMLError.invalidAttribute
      }
    }
    guard let start = state.cursor.peek(bytes),
          Self.isAttributeStart(start) else
    {
      throw WBXMLError.invalidAttribute
    }
    let attribute = try parseAttribute(bytes, state: &state)
    try XMLValidation.validatePITarget(attribute.name)
    guard state.cursor.peek(bytes) == Self.end else {
      throw WBXMLError.invalidAttribute
    }

    let instruction = WBXMLProcessingInstruction(attribute: attribute)
    try instruction.validateData()
    state.cursor.advance()
    return instruction
  }
}

// MARK: - Element Parsing

private extension WBXMLDecoder {

  func parseElement(_ bytes: Span<UInt8>, state: inout ParserState)
    throws -> WBXMLElement
  {
    let root = try parseElementStart(bytes, state: &state, depth: 1)
    if !root.hasContent { return root.element }

    var stack = [ root.element ]
    while let token = state.cursor.peek(bytes) {
      if token == Self.end {
        state.cursor.advance()
        guard let element = stack.popLast() else {
          throw WBXMLError.unmatchedEnd
        }

        if stack.isEmpty { return element } // EXIT LOOP / FUNCTION

        stack[stack.count - 1].children.append(.element(element))
      }
      else if token == Self.switchPage {
        try readTagPageSwitch(bytes, state: &state)

        guard let next = state.cursor.peek(bytes) else {
          throw WBXMLError.unexpectedEnd
        }
        guard Self.isElementStart(next) || Self.isExtension(next) else {
          throw WBXMLError.invalidToken(.init(page: state.tagPage, token: next))
        }
      }
      else if Self.isElementStart(token) {
        let child =
          try parseElementStart(bytes, state: &state, depth: stack.count + 1)

        if child.hasContent { stack.append(child.element) }
        else { stack[stack.count - 1].children.append(.element(child.element)) }
      }
      else {
        let node = try parseContentNode(bytes, state: &state)
        stack[stack.count - 1].children.append(node)
      }
    }

    throw WBXMLError.unexpectedEnd
  }

  func parseElementStart(_ bytes: Span<UInt8>, state: inout ParserState,
                         depth: Int)
    throws -> ( element: WBXMLElement, hasContent: Bool )
  {
    try state.tracker.checkDepth(depth)
    try state.tracker.addNode()

    if state.cursor.peek(bytes) == Self.switchPage {
      try readTagPageSwitch(bytes, state: &state)
    }

    let tagByte = try state.cursor.readByte(bytes)
    if tagByte == Self.end { throw WBXMLError.unmatchedEnd }
    guard Self.isElementStart(tagByte) else {
      throw WBXMLError.unexpectedGlobalToken(tagByte)
    }

    let hasAttributes = tagByte & Self.attrBit != 0
    let hasContent    = tagByte & Self.contentBit != 0
    let page          = state.tagPage
    let name          : String
    let isLiteral     : Bool

    switch tagByte {
      case Self.literal, Self.literalC, Self.literalA, Self.literalAC:
        let index = try state.cursor.readMBUInt32(bytes)
        name      = try readStringTable(bytes, state: &state, at: index)
        isLiteral = true

      default:
        guard codePages.pages[page] != nil else {
          throw WBXMLError.unknownCodePage(page)
        }
        let token = tagByte & Self.tokenMask
        guard let resolved = codePages.name(page: page, token: token) else {
          throw WBXMLError.unknownToken(.init(page: page, token: token))
        }
        name      = resolved
        isLiteral = false
    }

    try XMLValidation.validateName(name)
    _ = try state.charset.encodedByteCount(of: name)

    let attributes: [ WBXMLAttribute ]
    if hasAttributes { attributes = try parseAttributes(bytes, state: &state) }
    else { attributes = [] }

    let element = WBXMLElement(tag: name, page: page, literal: isLiteral,
                               attributes: attributes)
    return ( element, hasContent )
  }

  func parseContentNode(_ bytes: Span<UInt8>, state: inout ParserState)
    throws -> WBXMLNode
  {
    guard let token = state.cursor.peek(bytes) else {
      throw WBXMLError.unexpectedEnd
    }
    if token == Self.pi {
      let instruction = try parseProcessingInstruction(bytes, state: &state)
      return .processingInstruction(instruction)
    }
    state.cursor.advance()

    try state.tracker.addNode()

    switch token {
      case Self.strI:
        return .text(try readInlineString(bytes, state: &state))

      case Self.strT:
        let index = try state.cursor.readMBUInt32(bytes)
        let value = try readStringTable(bytes, state: &state, at: index)
        return .stringTable(value)

      case Self.entity:
        let value = try state.cursor.readMBUInt32(bytes)
        try Self.validateXMLScalar(value)
        return .entity(value)

      case _ where token >= Self.extI0 && token <= Self.extI2:
        let value = try readInlineString(bytes, state: &state)
        return .extensionInline(index: token - Self.extI0, value: value,
                                page: state.tagPage)

      case _ where token >= Self.extT0 && token <= Self.extT2:
        let value = try state.cursor.readMBUInt32(bytes)
        return .extensionInteger(index: token - Self.extT0, value: value,
                                 page: state.tagPage)

      case _ where token >= Self.ext0 && token <= Self.ext2:
        return .extension(index: token - Self.ext0, page: state.tagPage)

      case Self.opaque:
        return .opaque(try readOpaque(bytes, state: &state))

      default:
        throw WBXMLError.unexpectedGlobalToken(token)
    }
  }
}
