//
//  WBXMLEncoderPreflight.swift
//  WAPBinaryXML
//
//  Created by Helge Hess on 06.04.26.
//  Copyright © 2026 ZeeZide GmbH. All rights reserved.
//

extension WBXMLEncoder {

  func preflight(_  document : WBXMLDocument,
                 stringTable : inout StringTableBuilder,
                 tracker     : inout WBXMLResourceLimits.Tracker) throws
  {
    if case .literal(let value) = document.publicIdentifier {
      try XMLValidation.validatePublicIdentifier(value)
      try accountText(value, charset: stringTable.charset, tracker: &tracker)
      try stringTable.add(value)
    }

    for instruction in document.processingInstructionsBeforeRoot {
      try tracker.addNode()
      try preflight(instruction, stringTable: &stringTable, tracker: &tracker)
    }
    try tracker.addNode()
    try preflight(document.root, depth: 1, stringTable: &stringTable,
                  tracker: &tracker)
    for instruction in document.processingInstructionsAfterRoot {
      try tracker.addNode()
      try preflight(instruction, stringTable: &stringTable, tracker: &tracker)
    }
  }

  func preflight(_   element : WBXMLElement, depth: Int,
                 stringTable : inout StringTableBuilder,
                 tracker     : inout WBXMLResourceLimits.Tracker) throws
  {
    let charset = stringTable.charset
    try preflightElementStart(element, depth: depth, stringTable: &stringTable,
                              tracker: &tracker)

    var stack = [ element.children.makeIterator() ]
    while var children = stack.popLast() {
      guard let node = children.next() else { continue }

      stack.append(children)
      try tracker.addNode()
      switch node {
        case .element(let child):
          try preflightElementStart(child, depth: depth + stack.count,
                                    stringTable: &stringTable,
                                    tracker: &tracker)
          stack.append(child.children.makeIterator())

        case .text(let value):
          try accountText(value, charset: charset, tracker: &tracker)

        case .stringTable(let value):
          try accountText(value, charset: charset, tracker: &tracker)
          try stringTable.add(value)

        case .entity(let value):
          try Self.validateEntity(value)

        case .extensionInline(let index, let value, _):
          try Self.validateExtensionIndex(index)
          try accountText(value, charset: charset, tracker: &tracker)

        case .extensionInteger(let index, _, _), .extension(let index, _):
          try Self.validateExtensionIndex(index)

        case .processingInstruction(let instruction):
          try preflight(instruction, stringTable: &stringTable,
                        tracker: &tracker)

        case .opaque(let data):
          try tracker.addOpaque(data.count)
          try Self.validateLength(data.count)
      }
    }
  }

  func preflightElementStart(_ element: WBXMLElement, depth: Int,
                             stringTable: inout StringTableBuilder,
                             tracker: inout WBXMLResourceLimits.Tracker) throws
  {
    let charset = stringTable.charset
    try tracker.checkDepth(depth)
    try XMLValidation.validateName(element.tag)
    let nameBytes = try charset.encodedByteCount(of: element.tag)

    if element.literal {
      try tracker.addText(nameBytes)
      try stringTable.add(element.tag)
    }

    try tracker.checkAttributes(element.attributes.count)
    var attributeNames = Set<WBXMLExactStringKey>()
    for attribute in element.attributes {
      try preflight(attribute, stringTable: &stringTable, tracker: &tracker,
                    emitExplicitEmptyValue: true)

      let nameKey = WBXMLExactStringKey(attribute.name)
      guard attributeNames.insert(nameKey).inserted else {
        throw WBXMLError.duplicateAttribute(attribute.name)
      }
    }
  }

  func preflight(_ attribute : WBXMLAttribute,
                 stringTable : inout StringTableBuilder,
                 tracker     : inout WBXMLResourceLimits.Tracker,
                 emitExplicitEmptyValue: Bool) throws
  {
    let charset = stringTable.charset
    try tracker.addNode()
    try XMLValidation.validateName(attribute.name)
    let nameBytes = try charset.encodedByteCount(of: attribute.name)

    if let prefix = attribute.valuePrefix {
      _ = try charset.encodedByteCount(of: prefix)
    }
    
    if attribute.literal {
      guard attribute.valuePrefix == nil else {
        throw WBXMLError.invalidAttribute
      }
      try tracker.addText(nameBytes)
      try stringTable.add(attribute.name)
    }

    for value in attribute.values {
      try tracker.addNode()

      switch value {
        case .text(let string):
          try accountText(string, charset: charset, tracker: &tracker)

        case .stringTable(let string):
          try accountText(string, charset: charset, tracker: &tracker)
          try stringTable.add(string)

        case .entity(let scalar):
          try Self.validateEntity(scalar)

        case .extensionInline(let index, let string, _):
          try Self.validateExtensionIndex(index)
          try accountText(string, charset: charset, tracker: &tracker)

        case .extensionInteger(let index, _, _), .extension(let index, _):
          try Self.validateExtensionIndex(index)

        case .token(let string, _):
          _ = try charset.encodedByteCount(of: string)

        case .opaque(let data):
          try tracker.addOpaque(data.count)
          try Self.validateLength(data.count)
      }
    }
    if emitExplicitEmptyValue, attribute.valuePrefix == nil,
       attribute.values.isEmpty
    {
      try tracker.addNode()
      try tracker.addText(0)
    }
  }

  func preflight(_ instruction : WBXMLProcessingInstruction,
                 stringTable   : inout StringTableBuilder,
                 tracker       : inout WBXMLResourceLimits.Tracker) throws
  {
    try tracker.checkAttributes(1)
    try XMLValidation.validatePITarget(instruction.attribute.name)
    try preflight(instruction.attribute, stringTable: &stringTable,
                  tracker: &tracker, emitExplicitEmptyValue: false)
    try instruction.validateData()
  }

  func accountText(_ text: String, charset: WBXMLCharset,
                   tracker: inout WBXMLResourceLimits.Tracker) throws
  {
    let count = try charset.encodedByteCount(of: text)
    try tracker.addText(count)
  }
}
