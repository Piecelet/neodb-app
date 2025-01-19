//
//  ItemDetailsSheet.swift
//  NeoDB
//
//  Created by citron on 1/20/25.
//

import SwiftUI

struct ItemDetailsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let item: any ItemProtocol
    @State private var selectedText: String?

    var allMetadata: [(String, String)] {
        switch item {
        case let book as EditionSchema:
            return book.allMetadata
        case let movie as MovieSchema:
            return movie.allMetadata
        case let tv as TVShowSchema:
            return tv.allMetadata
        case let music as AlbumSchema:
            return music.allMetadata
        case let performance as PerformanceSchema:
            return performance.allMetadata
        case let podcast as PodcastSchema:
            return podcast.allMetadata
        case let game as GameSchema:
            return game.allMetadata
        default:
            return []
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom title bar
            HStack {
                Text(item.displayTitle ?? "Detail")
                    .font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray.opacity(0.5))
                        .font(.title2)
                }
            }
            .padding()
            
            List(Array(allMetadata.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 12) {
                    Text(item.0)
                        .foregroundStyle(.secondary)
                        .frame(width: 120, alignment: .leading)

                    Text(item.1)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle(item.displayTitle ?? "Detail")
            .navigationBarTitleDisplayMode(.inline)
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .presentationDetents([.fraction(0.999)])
        .background(.ultraThinMaterial)
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}
