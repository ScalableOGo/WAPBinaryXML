//
//  WBXMLEncoderLookup.swift
//  WAPBinaryXML
//
//  Created by Helge Hess on 06.04.26.
//  Copyright © 2026 ZeeZide GmbH. All rights reserved.
//

extension WBXMLEncoder {

  struct EncodingPages {

    var tag       : UInt8 = 0
    var attribute : UInt8 = 0
  }

  func resolveElement(_ element: WBXMLElement, activePage: UInt8)
    throws -> WBXMLCodePage.TokenReference
  {
    if let explicitPage = element.page {
      guard let page = codePages.pages[explicitPage] else {
        throw WBXMLError.unknownCodePage(explicitPage)
      }
      guard let token = page.tagToken(for: element.tag) else {
        throw WBXMLError.unknownElementOnPage(element.tag, explicitPage)
      }

      return .init(page: explicitPage, token: token)
    }

    if let token = codePages.pages[activePage]?.tagToken(for: element.tag) {
      return .init(page: activePage, token: token)
    }

    guard let resolved = codePages.token(for: element.tag) else {
      throw WBXMLError.unknownElement(element.tag)
    }

    return resolved
  }

  func resolveAttribute(_ attr: WBXMLAttribute, activePage: UInt8)
    throws -> WBXMLCodePage.TokenReference
  {
    if let explicitPage = attr.page {
      guard let page = codePages.pages[explicitPage] else {
        throw WBXMLError.unknownCodePage(explicitPage)
      }

      let token = page
            .attributeStartToken(for: attr.name, valuePrefix: attr.valuePrefix)
      guard let token else {
        throw WBXMLError.unknownAttributeOnPage(attr.name, explicitPage)
      }

      return .init(page: explicitPage, token: token)
    }

    let activeCodePage = codePages.pages[activePage]
    let activeToken = activeCodePage?
          .attributeStartToken(for: attr.name, valuePrefix: attr.valuePrefix)
    if let token = activeToken { return .init(page: activePage, token: token) }

    let resolved = codePages
      .attributeStartToken(for: attr.name, valuePrefix: attr.valuePrefix)
    guard let resolved else {
      throw WBXMLError.unknownAttribute(attr.name)
    }

    return resolved
  }

  func resolveAttributeValue(_ value: String, explicitPage: UInt8?,
                             activePage: UInt8)
    throws -> WBXMLCodePage.TokenReference
  {
    if let explicitPage {
      guard let page = codePages.pages[explicitPage] else {
        throw WBXMLError.unknownCodePage(explicitPage)
      }
      guard let token = page.attributeValueToken(for: value) else {
        throw WBXMLError.unknownAttributeValueOnPage(value, explicitPage)
      }
      return .init(page: explicitPage, token: token)
    }

    let activeCodePage = codePages.pages[activePage]
    if let token = activeCodePage?.attributeValueToken(for: value) {
      return .init(page: activePage, token: token)
    }

    guard let resolved = codePages.attributeValueToken(for: value) else {
      throw WBXMLError.unknownAttributeValue(value)
    }

    return resolved
  }

  func switchTagPage<O>(to requestedPage: UInt8?,
                        into output: inout EncodingBuffer<O>,
                        pages: inout EncodingPages) throws
    where O: Output
  {
    guard let requestedPage, requestedPage != pages.tag else { return }
    try output.append(Self.switchPage)
    try output.append(requestedPage)
    pages.tag = requestedPage
  }

  func switchAttributePage<O>(to requestedPage: UInt8?,
                              into output: inout EncodingBuffer<O>,
                              pages: inout EncodingPages) throws
    where O: Output
  {
    guard let requestedPage, requestedPage != pages.attribute else { return }
    try output.append(Self.switchPage)
    try output.append(requestedPage)
    pages.attribute = requestedPage
  }
}
