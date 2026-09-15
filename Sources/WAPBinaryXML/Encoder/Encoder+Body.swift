//
//  WBXMLEncoderBody.swift
//  WAPBinaryXML
//
//  Created by Helge Hess on 06.04.26.
//  Copyright © 2026 ZeeZide GmbH. All rights reserved.
//

extension WBXMLEncoder {

  func encodeElement(_ element: WBXMLElement, depth: Int,
                     stringTable: StringTableBuilder, charset: WBXMLCharset,
                     into output: inout EncodingBuffer,
                     pages: inout EncodingPages) throws
  {
    try encodeElementStart(element, depth: depth, stringTable: stringTable,
                           charset: charset, into: &output, pages: &pages)
    if element.children.isEmpty { return }

    var stack = [ element.children.makeIterator() ]
    while var children = stack.popLast() {
      guard let node = children.next() else {
        try output.append(Self.end)
        continue
      }

      stack.append(children)

      try encodeNode(node, depth: depth + stack.count, stringTable: stringTable,
                     charset: charset, into: &output, pages: &pages)
      if case .element(let child) = node, !child.children.isEmpty {
        stack.append(child.children.makeIterator())
      }
    }
  }

  func encodeElementStart(_ element: WBXMLElement, depth: Int,
                          stringTable: StringTableBuilder,
                          charset: WBXMLCharset,
                          into output: inout EncodingBuffer,
                          pages: inout EncodingPages) throws
  {
    try checkDepth(depth)
    let hasAttributes = !element.attributes.isEmpty
    let hasContent    = !element.children.isEmpty
    var flags         : UInt8 = 0

    if hasAttributes { flags |= Self.attrBit }
    if hasContent { flags |= Self.contentBit }

    if element.literal {
      try switchTagPage(to: element.page, into: &output, pages: &pages)
      try output.append(Self.literal | flags)
      try output.appendMBUInt32(try stringTable.offset(for: element.tag))
    }
    else {
      let resolved = try resolveElement(element, activePage: pages.tag)
      try switchTagPage(to: resolved.page, into: &output, pages: &pages)
      try output.append(resolved.token | flags)
    }

    if hasAttributes {
      try encodeAttributes(element.attributes, stringTable: stringTable,
                           charset: charset, into: &output, pages: &pages)
    }
  }

  func encodeNode(_ node: WBXMLNode, depth: Int,
                  stringTable: StringTableBuilder, charset: WBXMLCharset,
                  into output: inout EncodingBuffer,
                  pages: inout EncodingPages) throws
  {
    switch node {
      case .element(let element):
        try encodeElementStart(element, depth: depth, stringTable: stringTable,
                               charset: charset, into: &output, pages: &pages)
      case .text(let value):
        try encodeInlineString(value, token: Self.strI, charset: charset,
                               into: &output)

      case .stringTable(let value):
        try output.append(Self.strT)
        try output.appendMBUInt32(try stringTable.offset(for: value))

      case .entity(let value):
        try output.append(Self.entity)
        try output.appendMBUInt32(value)

      case .extensionInline(let index, let value, let page):
        try switchTagPage(to: page, into: &output, pages: &pages)
        try output.append(Self.extensionI + index)
        try output.appendTerminated(value, charset: charset)

      case .extensionInteger(let index, let value, let page):
        try switchTagPage(to: page, into: &output, pages: &pages)
        try output.append(Self.extensionT + index)
        try output.appendMBUInt32(value)

      case .extension(let index, let page):
        try switchTagPage(to: page, into: &output, pages: &pages)
        try output.append(Self.extensionToken + index)

      case .processingInstruction(let instruction):
        try encodePI(instruction, stringTable: stringTable,
                     charset: charset, into: &output, pages: &pages)

      case .opaque(let data):
        try output.append(Self.opaque)
        try output.appendMBUInt32(try Self.uint32Length(data.count))
        try output.append(contentsOf: data)
    }
  }

  func encodePI(_ instruction: WBXMLProcessingInstruction,
                stringTable: StringTableBuilder, charset: WBXMLCharset,
                into output: inout EncodingBuffer,
                pages: inout EncodingPages) throws
  {
    try output.append(Self.pi)
    try encodeAttributes([ instruction.attribute ], stringTable: stringTable,
                         charset: charset, emitExplicitEmptyValue: false,
                         into: &output, pages: &pages)
  }
}

// MARK: - Attribute Encoding

extension WBXMLEncoder {

  func encodeAttributes(_ attributes: [ WBXMLAttribute ],
                        stringTable: StringTableBuilder, charset: WBXMLCharset,
                        emitExplicitEmptyValue: Bool = true,
                        into output: inout EncodingBuffer,
                        pages: inout EncodingPages) throws
  {
    for attribute in attributes {
      if attribute.literal {
        if let page = attribute.page, page != pages.attribute {
          throw WBXMLError.invalidAttribute
        }
        try output.append(Self.literal)
        let offset = try stringTable.offset(for: attribute.name)
        try output.appendMBUInt32(offset)
      }
      else {
        let resolved = try resolveAttribute(attribute,
                                            activePage: pages.attribute)
        try switchAttributePage(to: resolved.page, into: &output, pages: &pages)
        try output.append(resolved.token)
      }

      for value in attribute.values {
        try encodeAttributeValue(value, stringTable: stringTable,
                                 charset: charset, into: &output, pages: &pages)
      }
      if emitExplicitEmptyValue, attribute.valuePrefix == nil,
         attribute.values.isEmpty
      {
        try encodeInlineString("", token: Self.strI, charset: charset,
                               into: &output)
      }
    }
    try output.append(Self.end)
  }

  func encodeAttributeValue(_ value: WBXMLAttributeValue,
                            stringTable: StringTableBuilder,
                            charset: WBXMLCharset,
                            into output: inout EncodingBuffer,
                            pages: inout EncodingPages) throws
  {
    switch value {
      case .text(let string):
        try encodeInlineString(string, token: Self.strI, charset: charset,
                               into: &output)
                               
      case .stringTable(let string):
        try output.append(Self.strT)
        try output.appendMBUInt32(try stringTable.offset(for: string))
        
      case .entity(let scalar):
        try output.append(Self.entity)
        try output.appendMBUInt32(scalar)
        
      case .extensionInline(let index, let string, let page):
        try switchAttributePage(to: page, into: &output, pages: &pages)
        try output.append(Self.extensionI + index)
        try output.appendTerminated(string, charset: charset)
        
      case .extensionInteger(let index, let integer, let page):
        try switchAttributePage(to: page, into: &output, pages: &pages)
        try output.append(Self.extensionT + index)
        try output.appendMBUInt32(integer)
        
      case .extension(let index, let page):
        try switchAttributePage(to: page, into: &output, pages: &pages)
        try output.append(Self.extensionToken + index)
        
      case .token(let string, let explicitPage):
        let resolved =
          try resolveAttributeValue(string, explicitPage: explicitPage,
                                    activePage: pages.attribute)
        try switchAttributePage(to: resolved.page, into: &output, pages: &pages)
        try output.append(resolved.token)
        
      case .opaque(let data):
        try output.append(Self.opaque)
        try output.appendMBUInt32(try Self.uint32Length(data.count))
        try output.append(contentsOf: data)
    }
  }
}
