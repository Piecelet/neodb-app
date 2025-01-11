// 
//  ItemDetailView.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 1/7/25.
//

import SwiftUI

struct ItemDetailView: View {
    @ObservedObject var viewModel: ItemDetailViewModel
    @EnvironmentObject private var router: Router
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let item = viewModel.item {
                    // Header Section
                    ItemHeaderView(
                        title: viewModel.displayTitle,
                        coverImageURL: viewModel.coverImageURL,
                        rating: viewModel.rating,
                        ratingCount: viewModel.ratingCount,
                        keyMetadata: viewModel.getKeyMetadata(for: item)
                    )
                    .overlay(alignment: .topTrailing) {
                        if viewModel.isRefreshing {
                            ProgressView()
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .padding([.top, .trailing], 8)
                        }
                    }
                    
                    Divider()
                        .padding(.vertical)
                    
                    // Description Section
                    if !viewModel.description.isEmpty {
                        ExpandableDescriptionView(description: viewModel.description)
                        
                        Divider()
                            .padding(.vertical)
                    }
                    
                    // Actions Section
                    ItemActionsView(item: ItemSchema(
                        title: item.title,
                        description: item.description,
                        localizedTitle: item.localizedTitle,
                        localizedDescription: item.localizedDescription,
                        coverImageUrl: item.coverImageUrl,
                        rating: item.rating,
                        ratingCount: item.ratingCount,
                        id: item.id,
                        type: item.type,
                        uuid: item.uuid,
                        url: item.url,
                        apiUrl: item.apiUrl,
                        category: item.category,
                        parentUuid: item.parentUuid,
                        displayTitle: item.displayTitle,
                        externalResources: item.externalResources,
                        brief: nil
                    ))
                } else if viewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Loading...")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
                } else {
                    EmptyStateView(
                        "Item Not Found",
                        systemImage: "exclamationmark.triangle",
                        description: Text("The requested item could not be found or has been removed.")
                    )
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
    }
}

#Preview {
    NavigationStack {
        let router = Router()
        let viewModel = ItemDetailViewModel(itemDetailService: ItemDetailService(authService: AuthService(), router: router))
        viewModel.item = EditionSchema.preview
        return ItemDetailView(viewModel: viewModel)
            .environmentObject(router)
    }
}

extension EditionSchema {
    static var preview: EditionSchema {
        EditionSchema(
            id: "1",
            type: "book",
            uuid: "1",
            url: "https://example.com/book/1",
            apiUrl: "https://api.example.com/book/1",
            category: .book,
            parentUuid: nil,
            displayTitle: "The Lord of the Rings",
            externalResources: [
                ExternalResourceSchema(url: "https://example.com/book/1/external")
            ],
            title: "The Lord of the Rings",
            description: "An epic high-fantasy novel by English author and scholar J. R. R. Tolkien.",
            localizedTitle: [],
            localizedDescription: [],
            coverImageUrl: "https://example.com/lotr.jpg",
            rating: 4.8,
            ratingCount: 12345,
            subtitle: "",
            origTitle: "",
            author: ["J. R. R. Tolkien"],
            translator: [],
            language: ["English"],
            pubHouse: "Allen & Unwin",
            pubYear: 1954,
            pubMonth: nil,
            binding: "",
            price: nil,
            pages: 1178,
            series: nil,
            imprint: nil,
            isbn: "978-0261103252"
        )
    }
}
