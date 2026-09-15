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

extension WBXMLProcessingInstruction {

  func validateData() throws {
    var previousWasQuestionMark = false
    if let prefix = attribute.valuePrefix {
      try Self.consume(prefix, previousWasQuestionMark:&previousWasQuestionMark)
    }

    for value in attribute.values {
      switch value {
        case .text(let string), .stringTable(let string), .token(let string, _):
          try Self
            .consume(string, previousWasQuestionMark: &previousWasQuestionMark)
        case .entity(let scalar):
          try Self
            .consume(scalar, previousWasQuestionMark: &previousWasQuestionMark)
        case .extensionInline, .extensionInteger, .extension, .opaque:
          previousWasQuestionMark = false
      }
    }
  }
}

private extension WBXMLProcessingInstruction {

  static func consume(_ string: String,
                      previousWasQuestionMark: inout Bool) throws
  {
    for scalar in string.unicodeScalars {
      try consume(scalar.value,
                  previousWasQuestionMark: &previousWasQuestionMark)
    }
  }

  static func consume(_ scalar: UInt32,
                      previousWasQuestionMark: inout Bool) throws
  {
    if previousWasQuestionMark, scalar == UInt8(ascii: ">") {
      throw WBXMLError.invalidProcessingInstructionData
    }
    previousWasQuestionMark = scalar == UInt8(ascii: "?")
  }
}
