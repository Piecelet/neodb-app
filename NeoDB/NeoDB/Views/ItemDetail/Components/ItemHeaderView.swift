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
    @State private var showMetadataSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title and Cover Section
            HStack(alignment: .top, spacing: 16) {
                // Cover Image
                KFImage(coverImageURL)
                    .placeholder {
                        Rectangle()
                            .fill(Color(.systemGray6))
                            .aspectRatio(2/3, contentMode: .fit)
                    }
                    .onFailure { _ in
                        Rectangle()
                            .fill(Color(.systemGray6))
                            .aspectRatio(2/3, contentMode: .fit)
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundStyle(.secondary)
                            }
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                // Title and Rating
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if rating != "N/A" {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .imageScale(.small)
                                .foregroundStyle(.yellow)
                            Text(rating)
                                .fontWeight(.medium)
                            if !ratingCount.isEmpty {
                                Text("·")
                                    .foregroundStyle(.secondary)
                                Text(ratingCount)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .font(.footnote)
                    }
                    
                    // Key Metadata (Preview)
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(keyMetadata.prefix(3)), id: \.label) { item in
                            if !item.value.isEmpty {
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text(item.label)
                                        .foregroundStyle(.secondary)
                                    Text(item.value)
                                        .lineLimit(1)
                                }
                                .font(.footnote)
                            }
                        }
                    }
                    
                    // Show All Metadata Button
                    if keyMetadata.count > 3 {
                        Button {
                            showMetadataSheet = true
                        } label: {
                            Text("Show All Details")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .sheet(isPresented: $showMetadataSheet) {
            NavigationStack {
                List {
                    ForEach(keyMetadata, id: \.label) { item in
                        if !item.value.isEmpty {
                            HStack(alignment: .top) {
                                Text(item.label)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 80, alignment: .leading)
                                Text(item.value)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                    }
                }
                .navigationTitle("Details")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            showMetadataSheet = false
                        }
                    }
                }
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
