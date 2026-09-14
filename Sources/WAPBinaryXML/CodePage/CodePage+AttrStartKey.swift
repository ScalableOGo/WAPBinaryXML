//
//  CodePageAttributeStartKey.swift
//  WAPBinaryXML
//
//  Created by Helge Hess on 11.09.26.
//  Copyright © 2026 ZeeZide GmbH. All rights reserved.
//

extension WBXMLCodePage {

  @usableFromInline
  struct AttributeStartKey: Sendable, Hashable {

    @usableFromInline
    let name        : WBXMLExactStringKey

    @usableFromInline
    let valuePrefix : WBXMLExactStringKey?

    @inlinable
    init(name: String, valuePrefix: String?) {
      self.name        = WBXMLExactStringKey(name)
      self.valuePrefix = valuePrefix.map(WBXMLExactStringKey.init)
    }
  }
}
