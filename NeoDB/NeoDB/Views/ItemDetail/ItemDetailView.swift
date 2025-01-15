//
//  ItemDetailView.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import SwiftUI
import Kingfisher

struct ItemDetailView: View {
    @ObservedObject var viewModel: ItemDetailViewModel
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var accountsManager: AppAccountsManager
    
    let id: String
    let category: ItemCategory
    
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
                    ItemActionsView(item: item)
                        .padding(.horizontal)
                    
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

// MARK: - Preview
#Preview {
    NavigationStack {
        ItemDetailView(
            viewModel: ItemDetailViewModel(),
            id: "preview_id",
            category: .book
        )
        .environmentObject(Router())
        .environmentObject(AppAccountsManager())
    }
}
