//
//  ItemView.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import ExpandableText
import Kingfisher
import SwiftUI

struct ItemView: View {
    // MARK: - Properties
    @StateObject private var viewModel: ItemViewModel
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @Environment(\.openURL) private var openURL

    let id: String
    let category: ItemCategory
    private let initialItem: (any ItemProtocol)?

    // MARK: - Initialization
    init(id: String, category: ItemCategory, item: (any ItemProtocol)? = nil) {
        self.id = id
        self.category = category
        self.initialItem = item
        self._viewModel = StateObject(
            wrappedValue: ItemViewModel(initialItem: item))
    }

    // MARK: - Body
    var body: some View {
        ScrollView {
            switch viewModel.state {
            case .loading:
                loadingView
            case .loaded:
                loadedView
            case .error:
                errorView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent
        }
        .refreshable {
            await viewModel.loadItemDetail(
                id: itemUUID, category: category, refresh: true)
        }
        .alert(
            "Error", isPresented: $viewModel.showError,
            presenting: viewModel.error
        ) { _ in
            Button("OK", role: .cancel) {}
        }
        .task {
            viewModel.accountsManager = accountsManager
            await viewModel.loadItemDetail(id: itemUUID, category: category)
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .environmentObject(viewModel)
        .enableInjection()
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }

    // MARK: - Loaded View
    private var loadedView: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView
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

            if !viewModel.description.isEmpty {
                descriptionView

                Divider()
                    .padding(.vertical)
            }

            actionsView
                .padding(.horizontal)
        }
    }

    // MARK: - Error View
    private var errorView: some View {
        EmptyStateView(
            "Item Not Found",
            systemImage: "exclamationmark.triangle",
            description: Text(
                "The requested item could not be found or has been removed."
            )
        )
    }

    // MARK: - Header View
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                coverImageView
                itemDetailsView
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
        }
        .padding(.vertical)
    }

    private var coverImageView: some View {
        ItemCoverView(
            item: viewModel.item,
            size: .medium
        )
    }

    private var itemDetailsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.displayTitle)
                    .font(.title2)
                    .fontWeight(.bold)

                if !viewModel.originalTitle.isEmpty {
                    Text(viewModel.originalTitle)
                        .font(.headline)
                }
            }
            .lineLimit(3)

            ratingView

            if !viewModel.metadata.isEmpty {
                Text(viewModel.metadata.joined(separator: " / "))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Button {
                    router.presentSheet(.itemDetails(item: viewModel.item!))
                } label: {
                    Text("View Details")
                        .font(.caption)
                        .foregroundStyle(.accent)
                }
            }
        }
    }

    private var ratingView: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .foregroundStyle(
                    viewModel.rating.isEmpty
                        ? .gray.opacity(0.5) : .orange.opacity(0.8))
            if viewModel.rating.isEmpty {
                Text("No Ratings")
                    .foregroundStyle(.secondary)
            } else {
                Text(viewModel.rating)
                Text("(\(viewModel.ratingCount))")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.subheadline)
    }

    // MARK: - Description View
    private var descriptionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.headline)

            ExpandableText(viewModel.description)
                .font(.callout)
                .foregroundStyle(.black.opacity(0.8))
                .lineLimit(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }

    // MARK: - Actions View
    private var actionsView: some View {
        VStack(spacing: 12) {
            if viewModel.isMarkLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if let mark = viewModel.mark {
                markInfoView(mark)
            }

            actionButton
        }
        .onChange(of: viewModel.isRefreshing) { newValue in
            if newValue {
                viewModel.refresh()
            }
        }
    }

    private func markInfoView(_ mark: MarkSchema) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let rating = mark.ratingGrade {
                    markRatingView(rating)
                }
                if mark.ratingGrade != nil {
                    Text("・")
                        .foregroundStyle(.secondary)
                }
                Text(mark.shelfType.displayName)
                    .foregroundStyle(.primary)
                Text("・")
                    .foregroundStyle(.secondary)
                Text(mark.createdTime.formatted)
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)

            if let comment = mark.commentText, !comment.isEmpty {
                Text(comment)
                    .font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func markRatingView(_ rating: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .foregroundStyle(.yellow)
            Text("\(rating)")
                .foregroundStyle(.primary)
            Text("/10")
                .foregroundStyle(.secondary)
        }
    }

    private var actionButton: some View {
        Button {
            if let item = viewModel.item {
                if let mark = viewModel.mark {
                    router.presentSheet(.editShelfItem(mark: mark))
                } else {
                    router.presentSheet(.addToShelf(item: item))
                }
            }
        } label: {
            HStack {
                Image(
                    systemName: viewModel.shelfType == nil
                        ? "plus" : "checkmark")
                if let shelfType = viewModel.shelfType {
                    Text(shelfType.displayName)
                } else {
                    Text("Add to Shelf")
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .disabled(viewModel.isMarkLoading)
    }

    // MARK: - Toolbar Content
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: 16) {
                if let resources = viewModel.item?.externalResources,
                    !resources.isEmpty
                {
                    Menu {
                        ForEach(resources, id: \.url) { resource in
                            Button(role: .none) {
                                openURL(resource.url)
                            } label: {
                                Label(resource.name, systemImage: resource.icon)
                            }
                        }
                    } label: {
                        Image(systemName: "link")
                    }
                }

                if let url = viewModel.shareURL {
                    ShareLink(item: url) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }

    // MARK: - Helper Properties
    private var itemUUID: String {
        URL(string: id)?.lastPathComponent ?? id
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
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
