//
//  WAPBinaryXMLTests.swift
//  WAPBinaryXML
//
//  Created by Helge Hess on 30.08.26.
//  Copyright © 2026 ZeeZide GmbH. All rights reserved.
//

import XCTest
import WAPBinaryXML

#if canImport(Foundation)
import Foundation
#endif

final class WAPBinaryXMLTests: XCTestCase {

  let pages = WBXMLCodePage.Set([
    WBXMLCodePage(page: 0, namespace: "urn:example",
                  tokens: [ ( 0x05, "Root" ), ( 0x06, "Value" ) ])
  ])

  func testKnownDocumentEncodingAndDecoding() throws {
    let root = WBXMLBuilder.element("Root", page: 0) {
      $0.element("Value", text: "ok")
    }
    let expected : [ UInt8 ] = [
      0x03, 0x01, 0x6A, 0x00,
      0x45, 0x46, 0x03, 0x6F, 0x6B, 0x00, 0x01, 0x01
    ]

    var encoded = [ UInt8 ] ()
    try WBXMLEncoder(codePages: pages).encode(root, to: &encoded)
    XCTAssertEqual(encoded, expected)

    var appended = [ UInt8 ]([ 0xAA ])
    try WBXMLEncoder(codePages: pages).encode(root, into: &appended)
    XCTAssertEqual(appended, [ 0xAA ] + expected)

    let decoded = try WBXMLDecoder(codePages: pages).decode(expected)
    XCTAssertEqual(decoded.root.tag, "Root")
    XCTAssertEqual(decoded.root[tag: "Value"]?.textValue, "ok")
  }

  func testOpaqueArrayRoundTrip() throws {
    let payload : [ UInt8 ] = [ 0x00, 0x01, 0x80, 0xFF ]
    let empty = [ UInt8 ]()
    let values : [ WBXMLAttributeValue ] = [ .opaque(payload), .opaque(empty) ]
    let attribute = WBXMLAttribute(name: "Binary", literal: true,
                                    values: values)
    var root = WBXMLBuilder.element("Root", page: 0) {
      $0.opaque(payload)
      $0.opaque(empty)
    }
    root.attributes = [ attribute ]
    var encoded = [ UInt8 ]()
    try WBXMLEncoder(codePages: pages).encode(root, to: &encoded)

    let decoded = try WBXMLDecoder(codePages: pages).decode(encoded)
    XCTAssertEqual(decoded.root.opaqueValue, payload)
    XCTAssertEqual(decoded.root.children, root.children)
    XCTAssertEqual(decoded.root.attributes.first?.values, attribute.values)
  }

  func testTruncatedDocumentThrows() {
    let decoder = WBXMLDecoder(codePages: pages)
    XCTAssertThrowsError(try decoder.decode([ 0x03, 0x01 ])) {
      XCTAssertEqual($0 as? WBXMLDecoder.ParseError,
                     .init(reason: .unexpectedEnd, offset: 2))
    }
  }

  #if canImport(Foundation)
  func testFoundationDataRoundTrip() throws {
    let root    = WBXMLElement(tag: "Root", page: 0)
    let encoder = WBXMLEncoder(codePages: pages)
    let decoder = WBXMLDecoder(codePages: pages)

    var data = Data()
    try encoder.encode(root, into: &data)
    XCTAssertEqual(try decoder.decode(data).root, root)
  }
  #endif
}
