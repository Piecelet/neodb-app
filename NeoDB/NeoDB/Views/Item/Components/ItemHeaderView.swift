//
//  ItemHeader.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Kingfisher
import SwiftUI

struct ItemHeaderView: View {
    let title: String
    let coverURL: URL?
    let rating: String
    let ratingCount: String
    let metadata: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Cover and Title
            HStack(alignment: .top, spacing: 16) {
                // Cover Image21
                KFImage(coverURL)
                    .placeholder {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(2 / 3, contentMode: .fit)
                            .frame(width: 120)
                    }
                    .onFailure { _ in
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(2 / 3, contentMode: .fit)
                            .frame(width: 120)
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundStyle(.secondary)
                            }
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .lineLimit(3)

                    // Rating
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                        Text(rating)
                        Text("(\(ratingCount))")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)

                    // Metadata
                    if !metadata.isEmpty {
                        Text(metadata.joined(separator: " / "))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
        }
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}

#Preview {
    ItemHeaderView(
        title:
            "Sample Book Title That is Very Long and Might Need Multiple Lines",
        coverURL: nil,
        rating: "4.5",
        ratingCount: "123",
        metadata: [
            "John Doe",
            "2024",
            "978-3-16-148410-0",
        ]
    )
}
