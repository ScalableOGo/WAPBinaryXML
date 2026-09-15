//
//  WBXMLDocument.swift
//  WAPBinaryXML
//
//  Created by Helge Hess on 06.04.26.
//  Copyright © 2026 ZeeZide GmbH. All rights reserved.
//

/// A decoded WBXML document.
public struct WBXMLDocument: Sendable {

  /// WBXML version byte (e.g. 0x03 for 1.3).
  public var version          : UInt8

  /// Numeric or literal public identifier.
  public var publicIdentifier : WBXMLPublicIdentifier

  /// Character encoding used by the document.
  public var charset          : WBXMLCharset

  /// Retained string-table context, or nil when no table is retained.
  public var stringTable      : WBXMLStringTable?

  /// Root element of the document tree.
  public var root : WBXMLElement

  public var processingInstructionsBeforeRoot : [ WBXMLProcessingInstruction ]
  public var processingInstructionsAfterRoot  : [ WBXMLProcessingInstruction ]

  /**
   * Setup document.
   */
  @inlinable
  public init(version : UInt8 = 0x03,
              publicIdentifier: WBXMLPublicIdentifier = .numeric(0x01),
              charset : WBXMLCharset = .utf8,
              stringTable: WBXMLStringTable? = nil,
              root    : WBXMLElement,
              processingInstructionsBeforeRoot : [ WBXMLProcessingInstruction ]
                                               = [],
              processingInstructionsAfterRoot  : [ WBXMLProcessingInstruction ]
                                               = [])
  {
    self.version                          = version
    self.publicIdentifier                 = publicIdentifier
    self.charset                          = charset
    self.stringTable                      = stringTable
    self.processingInstructionsBeforeRoot = processingInstructionsBeforeRoot
    self.root                             = root
    self.processingInstructionsAfterRoot  = processingInstructionsAfterRoot
  }
}

extension WBXMLDocument: Equatable {

  @inlinable
  public static func == (lhs: Self, rhs: Self) -> Bool {
    let before = lhs.processingInstructionsBeforeRoot
              == rhs.processingInstructionsBeforeRoot
    let after  = lhs.processingInstructionsAfterRoot
              == rhs.processingInstructionsAfterRoot
    return lhs.version == rhs.version
        && lhs.publicIdentifier == rhs.publicIdentifier
        && lhs.charset == rhs.charset && lhs.stringTable == rhs.stringTable
        && before && lhs.root == rhs.root && after
  }
}
