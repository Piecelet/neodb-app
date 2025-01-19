//
//  ItemView.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Kingfisher
import SwiftUI

struct ItemView: View {
    @StateObject private var viewModel: ItemViewModel
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @Environment(\.openURL) private var openURL

    let id: String
    let category: ItemCategory
    private let initialItem: (any ItemProtocol)?

    init(id: String, category: ItemCategory, item: (any ItemProtocol)? = nil) {
        self.id = id
        self.category = category
        self.initialItem = item
        self._viewModel = StateObject(wrappedValue: ItemViewModel(initialItem: item))
    }

    var body: some View {
        ItemContent(
            state: viewModel.state,
            header: ItemHeaderView(
                title: viewModel.displayTitle,
                coverURL: viewModel.coverImageURL,
                rating: viewModel.rating,
                ratingCount: viewModel.ratingCount,
                metadata: viewModel.metadata
            ),
            description: viewModel.description,
            actions: ItemActionsView(isRefreshing: viewModel.isRefreshing),
            isRefreshing: viewModel.isRefreshing
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    if let resources = viewModel.item?.externalResources,
                        !resources.isEmpty
                    {
                        Menu {
                            ForEach(resources, id: \.url) { resource in
                                Button {
                                    openURL(resource.url)
                                } label: {
                                    Label(
                                        resource.name,
                                        systemImage: resource.icon)
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
        .refreshable {
            await viewModel.loadItemDetail(
                id: itemUUID, category: category, refresh: true)
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
        .environmentObject(viewModel)
    }
    
    private var itemUUID: String {
        if let url = URL(string: id), url.pathComponents.count >= 2 {
            return url.lastPathComponent
        }
        return id
    }
}

// MARK: - Content Views
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
                    description: Text(
                        "The requested item could not be found or has been removed."
                    )
                )
            }
        }
    }
}

// MARK: - Header View
private struct ItemHeaderView: View {
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


// MARK: - Description View
private struct ExpandableDescriptionView: View {
    let description: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.headline)

            Text(description)
                .font(.body)
                .lineLimit(isExpanded ? nil : 3)

            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                Text(isExpanded ? "Show Less" : "Read More")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}

// MARK: - Actions View
private struct ItemActionsView: View {
    @EnvironmentObject private var viewModel: ItemViewModel
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var router: Router

    let isRefreshing: Bool

    var body: some View {
        VStack(spacing: 12) {
            if viewModel.isMarkLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if let mark = viewModel.mark {
                // Show existing mark info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        if let rating = mark.ratingGrade {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                            Text("\(rating)")
                                .foregroundStyle(.primary)
                            Text("/10")
                                .foregroundStyle(.secondary)
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

            // Primary Action
            Button {
                if let item = viewModel.item {
                    if let mark = viewModel.mark {
                        router.presentedSheet = .editShelfItem(mark: mark)
                    } else {
                        router.presentedSheet = .addToShelf(item: item)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: viewModel.shelfType == nil ? "plus" : "checkmark")
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
        .onChange(of: isRefreshing) { newValue in
            if newValue {
                viewModel.refresh()
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
