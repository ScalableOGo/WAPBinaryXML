//
//  WBXMLResourceLimits.swift
//  WAPBinaryXML
//
//  Created by Helge Hess on 06.04.26.
//  Copyright © 2026 ZeeZide GmbH. All rights reserved.
//

/// Resource limits applied by both the encoder and decoder.
public struct WBXMLResourceLimits: Sendable, Equatable {

  /// A resource category constrained while encoding or decoding.
  public enum Kind: Sendable, Equatable {

    /// Maximum encoded or decoded document byte count.
    case documentBytes

    /// Maximum encoded or decoded string-table byte count.
    case stringTableBytes

    /// Maximum element nesting depth.
    case depth

    /// Maximum retained model items: nodes, attributes, and value components.
    case nodes

    /// Maximum cumulative encoded text byte count.
    case textBytes

    /// Maximum cumulative opaque-data byte count.
    case opaqueBytes

    /// Maximum attributes attached to one element.
    case attributesPerElement
  }

  /// Maximum encoded or decoded document byte count.
  public var maximumDocumentBytes        : Int

  /// Maximum encoded or decoded string-table byte count.
  public var maximumStringTableBytes     : Int

  /// Maximum element nesting depth.
  public var maximumDepth                : Int

  /// Maximum retained model items: nodes, attributes, and value components.
  public var maximumNodes                : Int

  /// Maximum cumulative encoded length of document-carried string payloads.
  public var maximumTextBytes            : Int

  /// Maximum cumulative opaque-data byte count.
  public var maximumOpaqueBytes          : Int

  /// Maximum attributes attached to one element.
  public var maximumAttributesPerElement : Int

  /// Conservative limits suitable for untrusted network input.
  public static let `default` = WBXMLResourceLimits()

  @inlinable
  public init(maximumDocumentBytes    : Int = 16 * 1_024 * 1_024,
              maximumStringTableBytes : Int = 1_024 * 1_024,
              maximumDepth            : Int = 256, maximumNodes: Int = 100_000,
              maximumTextBytes        : Int = 8 * 1_024 * 1_024,
              maximumOpaqueBytes      : Int = 16 * 1_024 * 1_024,
              maximumAttributesPerElement: Int = 1_024)
  {
    self.maximumDocumentBytes        = maximumDocumentBytes
    self.maximumStringTableBytes     = maximumStringTableBytes
    self.maximumDepth                = maximumDepth
    self.maximumNodes                = maximumNodes
    self.maximumTextBytes            = maximumTextBytes
    self.maximumOpaqueBytes          = maximumOpaqueBytes
    self.maximumAttributesPerElement = maximumAttributesPerElement
  }
}

extension WBXMLResourceLimits {

  struct Tracker {

    let limits : WBXMLResourceLimits

    private(set) var nodes       = 0
    private(set) var textBytes   = 0
    private(set) var opaqueBytes = 0

    mutating func addNode() throws {
      guard nodes < limits.maximumNodes else {
        throw WBXMLError.resourceLimitExceeded(.nodes)
      }
      nodes += 1
    }

    mutating func addText(_ count: Int) throws {
      guard count >= 0, textBytes <= limits.maximumTextBytes,
            count <= limits.maximumTextBytes - textBytes else
      {
        throw WBXMLError.resourceLimitExceeded(.textBytes)
      }
      textBytes += count
    }

    mutating func addOpaque(_ count: Int) throws {
      guard count >= 0, opaqueBytes <= limits.maximumOpaqueBytes,
            count <= limits.maximumOpaqueBytes - opaqueBytes else
      {
        throw WBXMLError.resourceLimitExceeded(.opaqueBytes)
      }
      opaqueBytes += count
    }

    func checkDepth(_ depth: Int) throws {
      guard depth >= 0, depth <= limits.maximumDepth else {
        throw WBXMLError.resourceLimitExceeded(.depth)
      }
    }

    func checkAttributes(_ count: Int) throws {
      guard count >= 0, count <= limits.maximumAttributesPerElement else {
        throw WBXMLError.resourceLimitExceeded(.attributesPerElement)
      }
    }
  }
}
