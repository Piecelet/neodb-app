//
//  ItemDetailView.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import SwiftUI
import Kingfisher

struct ItemDetailView: View {
    @StateObject private var viewModel: ItemDetailViewModel
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var accountsManager: AppAccountsManager
    
    let id: String
    let category: ItemCategory
    private let initialItem: (any ItemProtocol)?
    
    init(id: String, category: ItemCategory, item: (any ItemProtocol)? = nil) {
        self.id = id
        self.category = category
        self.initialItem = item
        self._viewModel = StateObject(wrappedValue: ItemDetailViewModel(initialItem: item))
    }
    
    var body: some View {
        ItemDetailContent(
            state: viewModel.state,
            header: ItemDetailHeader(
                title: viewModel.displayTitle,
                coverURL: viewModel.coverImageURL,
                rating: viewModel.rating,
                ratingCount: viewModel.ratingCount,
                metadata: viewModel.getKeyMetadata(for: viewModel.item)
            ),
            description: viewModel.description,
            actions: ItemDetailActions(
                item: viewModel.item,
                onAddToShelf: { 
                    if let item = viewModel.item {
                        router.presentedSheet = .addToShelf(item: item)
                    }
                }
            ),
            isRefreshing: viewModel.isRefreshing
        )
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.loadItemDetail(id: id, category: category, refresh: true)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
        .task {
            viewModel.accountsManager = accountsManager
            await viewModel.loadItemDetail(id: id, category: category)
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
}

private struct ItemDetailContent: View {
    let state: ItemDetailState
    let header: ItemDetailHeader
    let description: String
    let actions: ItemDetailActions
    let isRefreshing: Bool
    
    var body: some View {
        ScrollView {
            switch state {
            case .loading:
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading...")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 100)
                
            case .loaded:
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .overlay(alignment: .topTrailing) {
                            if isRefreshing {
                                ProgressView()
                                    .padding(8)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                                    .padding([.top, .trailing], 8)
                            }
                        }
                    
                    Divider()
                        .padding(.vertical)
                    
                    if !description.isEmpty {
                        ExpandableDescriptionView(description: description)
                        
                        Divider()
                            .padding(.vertical)
                    }
                    
                    actions
                        .padding(.horizontal)
                }
                
            case .error:
                EmptyStateView(
                    "Item Not Found",
                    systemImage: "exclamationmark.triangle",
                    description: Text("The requested item could not be found or has been removed.")
                )
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        ItemDetailView(
            id: "preview_id",
            category: .book
        )
        .environmentObject(Router())
        .environmentObject(AppAccountsManager())
    }
}
