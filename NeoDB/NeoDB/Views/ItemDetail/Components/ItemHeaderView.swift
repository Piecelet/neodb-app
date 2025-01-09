//
//  ItemHeaderView.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 1/7/25.
//

import SwiftUI
import Kingfisher

struct ItemHeaderView: View {
    let title: String
    let coverImageURL: URL?
    let rating: String
    let ratingCount: String
    let keyMetadata: [(label: String, value: String)]
    @State private var showAllMetadata = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                // Cover Image
                KFImage(coverImageURL)
                    .placeholder {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(2/3, contentMode: .fit)
                    }
                    .onFailure { _ in
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(2/3, contentMode: .fit)
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundStyle(.secondary)
                            }
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .shadow(radius: 4)
                
                // Title, Rating and Key Metadata
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Rating
                    if rating != "N/A" {
                        HStack(spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                Text(rating)
                                    .fontWeight(.semibold)
                            }
                            
                            if !ratingCount.isEmpty {
                                Text("·")
                                    .foregroundStyle(.secondary)
                                Text(ratingCount)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .font(.subheadline)
                    }
                    
                    // Key Metadata (first 3 items)
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(keyMetadata.prefix(3), id: \.label) { item in
                            if !item.value.isEmpty {
                                HStack(alignment: .top) {
                                    Text(item.label)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 60, alignment: .leading)
                                    
                                    Text(item.value)
                                        .lineLimit(1)
                                }
                                .font(.caption)
                            }
                        }
                    }
                    
                    if keyMetadata.count > 3 {
                        Button {
                            withAnimation {
                                showAllMetadata.toggle()
                            }
                        } label: {
                            Text(showAllMetadata ? "Show Less" : "Show More")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding()
            
            // Expanded Metadata
            if showAllMetadata {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(keyMetadata.dropFirst(3), id: \.label) { item in
                        if !item.value.isEmpty {
                            HStack(alignment: .top) {
                                Text(item.label)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 60, alignment: .leading)
                                
                                Text(item.value)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .font(.caption)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

#Preview {
    ItemHeaderView(
        title: "Sample Title",
        coverImageURL: URL(string: "https://example.com/image.jpg"),
        rating: "4.5",
        ratingCount: "1,234 ratings",
        keyMetadata: [
            ("Year", "2024"),
            ("Genre", "Drama, Thriller"),
            ("Director", "Christopher Nolan"),
            ("Cast", "John David Washington, Robert Pattinson"),
            ("Duration", "150 minutes"),
            ("Language", "English")
        ]
    )
}
