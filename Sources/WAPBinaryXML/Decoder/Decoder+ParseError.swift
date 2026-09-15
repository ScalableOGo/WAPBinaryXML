//
//  Decoder+ParseError.swift
//  WAPBinaryXML
//
//  Created by Helge Hess on 09.09.26.
//  Copyright © 2026 ZeeZide GmbH. All rights reserved.
//

extension WBXMLDecoder {

  public struct ParseError: Error, Equatable, Sendable {

    public let reason : WBXMLError
    public let offset : Int

    @inlinable
    public init(reason: WBXMLError, offset: Int) {
      self.reason = reason
      self.offset = offset
    }
  }
}
