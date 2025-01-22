//
//  MastodonMediaAttachment.swift
//  NeoDB
//
//  Created by citron on 1/13/25.
//

import Foundation

public struct MastodonMediaAttachment: Codable, Identifiable, Hashable, Equatable {
    public struct MetaContainer: Codable, Equatable {
      public struct Meta: Codable, Equatable {
        public let width: Int?
        public let height: Int?
      }

      public let original: Meta?
    }

    public enum SupportedType: String {
      case image, gifv, video, audio
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(id)
    }

    public let id: String
    public let type: String
    public var supportedType: SupportedType? {
      SupportedType(rawValue: type)
    }

    public var localizedTypeDescription: String? {
      if let supportedType {
        switch supportedType {
        case .image:
          return NSLocalizedString(
            "accessibility.media.supported-type.image.label", bundle: .main,
            comment: "A localized description of SupportedType.image")
        case .gifv:
          return NSLocalizedString(
            "accessibility.media.supported-type.gifv.label", bundle: .main,
            comment: "A localized description of SupportedType.gifv")
        case .video:
          return NSLocalizedString(
            "accessibility.media.supported-type.video.label", bundle: .main,
            comment: "A localized description of SupportedType.video")
        case .audio:
          return NSLocalizedString(
            "accessibility.media.supported-type.audio.label", bundle: .main,
            comment: "A localized description of SupportedType.audio")
        }
      }
      return nil
    }

    public let url: URL?
    public let previewUrl: URL?
    public let description: String?
    public let meta: MetaContainer?

    public static func imageWith(url: URL) -> MastodonMediaAttachment {
      .init(
        id: UUID().uuidString,
        type: "image",
        url: url,
        previewUrl: url,
        description: nil,
        meta: nil)
    }

    public static func videoWith(url: URL) -> MastodonMediaAttachment {
      .init(
        id: UUID().uuidString,
        type: "video",
        url: url,
        previewUrl: url,
        description: nil,
        meta: nil)
    }
  }

  extension MastodonMediaAttachment: Sendable {}
  extension MastodonMediaAttachment.MetaContainer: Sendable {}
  extension MastodonMediaAttachment.MetaContainer.Meta: Sendable {}
  extension MastodonMediaAttachment.SupportedType: Sendable {}
