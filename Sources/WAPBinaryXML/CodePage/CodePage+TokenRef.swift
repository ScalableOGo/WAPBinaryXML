//
//  CodePageTokenReference.swift
//  WAPBinaryXML
//
//  Created by Helge Hess on 13.09.26.
//  Copyright © 2026 ZeeZide GmbH. All rights reserved.
//

extension WBXMLCodePage {

  /// A code-page number and token byte.
  public struct TokenReference: Sendable, Hashable {

    /// Code page containing the token.
    public let page  : UInt8

    /// Token byte within the code page.
    public let token : UInt8

    @inlinable
    public init(page: UInt8, token: UInt8) {
      self.page  = page
      self.token = token
    }
  }
}
