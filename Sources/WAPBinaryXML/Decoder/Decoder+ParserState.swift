//
//  ParserState.swift
//  WAPBinaryXML
//
//  Created by Helge Hess on 06.04.26.
//  Copyright © 2026 ZeeZide GmbH. All rights reserved.
//

extension WBXMLDecoder {

  struct ParserState {

    var cursor          = Cursor()
    var tagPage         : UInt8 = 0
    var attributePage   : UInt8 = 0
    var charset         : WBXMLCharset = .utf8
    var stringTable     = 0..<0
    var tableReferences = [ WBXMLExactStringKey : UInt32 ]()
    var tracker         : WBXMLResourceLimits.Tracker
  }
}
