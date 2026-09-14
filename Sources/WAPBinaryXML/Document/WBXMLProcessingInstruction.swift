//
//  WBXMLProcessingInstruction.swift
//  WAPBinaryXML
//
//  Created by Helge Hess on 06.04.26.
//  Copyright © 2026 ZeeZide GmbH. All rights reserved.
//

/// A WBXML processing instruction.
public struct WBXMLProcessingInstruction: Sendable {

  /// The processing instruction's single attribute.
  public var attribute : WBXMLAttribute

  /// Build a processing instruction.
  @inlinable
  public init(attribute: WBXMLAttribute) { self.attribute = attribute }
}

extension WBXMLProcessingInstruction: Equatable {

  @inlinable
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.attribute == rhs.attribute
  }
}
