//
//  ItemActionsView.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 1/7/25.
//

import SwiftUI

struct ItemActionsView: View {
    let item: ItemSchema
    @EnvironmentObject private var router: Router
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        VStack(spacing: 16) {
            // Add to Shelf Button
            Button {
                router.presentedSheet = .addToShelf(item: item)
            } label: {
                Label("Add to Shelf", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            
            // Share Button
            if let url = URL(string: item.url) {
                ShareLink(item: url) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            
            // External Links
            if let resources = item.externalResources, !resources.isEmpty {
                Menu {
                    ForEach(resources, id: \.url) { resource in
                        if let url = URL(string: resource.url) {
                            Button {
                                openURL(url)
                            } label: {
                                Label(url.host ?? "External Link", systemImage: "link")
                            }
                        }
                    }
                } label: {
                    Label("External Links", systemImage: "globe")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}

#Preview {
    ItemActionsView(item: .preview)
        .environmentObject(Router())
}

extension ItemSchema {
    static var preview: ItemSchema {
        ItemSchema(
            title: "Sample Item",
            description: "A sample item description",
            localizedTitle: [],
            localizedDescription: [],
            coverImageUrl: "https://example.com/image.jpg",
            rating: 4.5,
            ratingCount: 1234,
            id: "1",
            type: "book",
            uuid: "1",
            url: "https://example.com/item/1",
            apiUrl: "https://api.example.com/item/1",
            category: .book,
            parentUuid: nil,
            displayTitle: "Sample Item",
            externalResources: [
                ExternalResourceSchema(url: "https://example.com/external/1")
            ],
            brief: "A sample item brief description"
        )
    }
} 