//
//  ItemDetailHeader.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import SwiftUI
import Kingfisher

struct ItemDetailHeader: View {
    let title: String
    let coverURL: URL?
    let rating: String
    let ratingCount: String
    let metadata: [(String, String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Cover and Title
            HStack(alignment: .top, spacing: 16) {
                // Cover Image
                KFImage(coverURL)
                    .placeholder {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(2/3, contentMode: .fit)
                            .frame(width: 120)
                    }
                    .onFailure { _ in
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(2/3, contentMode: .fit)
                            .frame(width: 120)
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundStyle(.secondary)
                            }
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 180)
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
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            
            // Metadata
            if !metadata.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(metadata, id: \.0) { key, value in
                        HStack(alignment: .top) {
                            Text(key)
                                .foregroundStyle(.secondary)
                                .frame(width: 80, alignment: .leading)
                            Text(value)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .font(.subheadline)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    ItemDetailHeader(
        title: "Sample Book Title That is Very Long and Might Need Multiple Lines",
        coverURL: nil,
        rating: "4.5",
        ratingCount: "123",
        metadata: [
            ("Author", "John Doe"),
            ("Published", "2024"),
            ("ISBN", "978-3-16-148410-0")
        ]
    )
} 