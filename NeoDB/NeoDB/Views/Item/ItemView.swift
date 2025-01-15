//
//  ItemView.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import SwiftUI
import Kingfisher

struct ItemView: View {
    @StateObject private var viewModel: ItemViewModel
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var accountsManager: AppAccountsManager
    
    let id: String
    let category: ItemCategory
    private let initialItem: (any ItemProtocol)?
    
    init(id: String, category: ItemCategory, item: (any ItemProtocol)? = nil) {
        self.id = id
        self.category = category
        self.initialItem = item
        self._viewModel = StateObject(wrappedValue: ItemViewModel(initialItem: item))
    }
    
    private var itemUUID: String {
        if let url = URL(string: id), url.pathComponents.count >= 2 {
            return url.lastPathComponent
        }
        return id
    }
    
    var body: some View {
        ItemContent(
            state: viewModel.state,
            header: ItemHeaderView(
                title: viewModel.displayTitle,
                coverURL: viewModel.coverImageURL,
                rating: viewModel.rating,
                ratingCount: viewModel.ratingCount,
                metadata: viewModel.getKeyMetadata(for: viewModel.item)
            ),
            description: viewModel.description,
            actions: ItemActionsView(
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
            await viewModel.loadItemDetail(id: itemUUID, category: category, refresh: true)
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
            await viewModel.loadItemDetail(id: itemUUID, category: category)
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
}

private struct ItemContent: View {
    let state: ItemState
    let header: ItemHeaderView
    let description: String
    let actions: ItemActionsView
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
        ItemView(
            id: "preview_id",
            category: .book
        )
        .environmentObject(Router())
        .environmentObject(AppAccountsManager())
    }
}
