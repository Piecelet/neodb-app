//
//  ItemDescriptionView.swift
//  NeoDB
//
//  Created by citron on 1/22/25.
//

import SwiftUI

enum ItemDescriptionMode {
    case metadata
    case brief
    case metadataAndBrief
}

enum ItemDescriptionSize {
    case small
    case medium
    case large

    var font: Font {
        switch self {
        case .small:
            return .caption
        case .medium:
            return .footnote
        case .large:
            return .footnote
        }
    }

    var lineLimit: Int {
        switch self {
        case .small:
            return 1
        case .medium:
            return 2
        case .large:
            return 3
        }
    }
}

struct ItemDescriptionView: View {
    let item: (any ItemProtocol)?
    let mode: ItemDescriptionMode
    let size: ItemDescriptionSize

    private var metadata: [String] {
        guard let item else { return [] }

        var metadata: [String] = []
        

        switch item {
        case let book as EditionSchema:
            metadata = book.keyMetadata
        case let movie as MovieSchema:
            metadata = movie.keyMetadata
        case let tv as TVShowSchema:
            metadata = tv.keyMetadata
        case let music as AlbumSchema:
            metadata = music.keyMetadata
        case let performance as PerformanceSchema:
            metadata = performance.keyMetadata
        case let podcast as PodcastSchema:
            metadata = podcast.keyMetadata
        case let game as GameSchema:
            metadata = game.keyMetadata
        default:
            break
        }

        return metadata
    }

    var body: some View {
        Group {
            switch mode {
            case .metadata:
                metadataView
            case .brief:
                briefView
            case .metadataAndBrief:
                VStack(alignment: .leading, spacing: 4) {
                    metadataView
                    briefView
                }
            }
        }
        .enableInjection()
    }

    var metadataView: some View {
        Group {
            if !metadata.isEmpty {
                Text(metadata.joined(separator: " / "))
                    .font(size.font)
                    .foregroundStyle(.secondary)
                    .lineLimit(size.lineLimit)
            }
        }
    }

    var briefView: some View {
        Group {
            if let item = item {
                Text(item.brief)
                    .font(size.font)
                    .foregroundStyle(.secondary)
                    .lineLimit(size.lineLimit)
            }
        }
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}
