//
//  LibraryView.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 1/7/25.
//

import SwiftUI
import OSLog
import Kingfisher

@MainActor
//class LibraryViewModel: ObservableObject {
//    var accountsManager: AppAccountsManager? {
//        didSet {
//            if oldValue !== accountsManager {
//                shelfItems = []
//            }
//        }
//    }
//    
//    private let cacheService = CacheService()
//    private let logger = Logger.views.library
//    private var loadTask: Task<Void, Never>?
//    
//    @Published var selectedShelfType: ShelfType = .wishlist
//    @Published var shelfItems: [MarkSchema] = []
//    @Published var isLoading = false
//    @Published var error: String?
//    @Published var detailedError: String?
//    @Published var isRefreshing = false
//    @Published var selectedCategory: ItemCategory?
//    
//    @Published var currentPage = 1
//    @Published var totalPages = 1
//    
//    func loadShelfItems(refresh: Bool = false) async {
//        loadTask?.cancel()
//        
//        loadTask = Task {
//            guard let accountsManager = accountsManager else {
//                logger.debug("No accountsManager available")
//                return
//            }
//            
//            logger.debug("Loading shelf items for instance: \(accountsManager.currentAccount.instance)")
//            
//            if refresh {
//                logger.debug("Refreshing shelf items, resetting pagination")
//                currentPage = 1
//                if !Task.isCancelled {
//                    isRefreshing = true
//                }
//            } else {
//                if !Task.isCancelled {
//                    isLoading = true
//                }
//            }
//            
//            defer {
//                if !Task.isCancelled {
//                    isLoading = false
//                    isRefreshing = false
//                }
//            }
//            
//            error = nil
//            detailedError = nil
//            
//            let cacheKey = "\(accountsManager.currentAccount.instance)_shelf_\(selectedShelfType.rawValue)_\(selectedCategory?.rawValue ?? "all")"
//            logger.debug("Using cache key: \(cacheKey)")
//            
//            do {
//                // Only load from cache if not refreshing and shelfItems is empty
//                if !refresh && shelfItems.isEmpty,
//                   let cached = try? await cacheService.retrieve(
//                    forKey: cacheKey, type: PagedMarkSchema.self)
//                {
//                    if !Task.isCancelled {
//                        shelfItems = cached.data
//                        totalPages = cached.pages
//                        logger.debug("Loaded \(cached.data.count) items from cache")
//                    }
//                }
//                
//                guard !Task.isCancelled else {
//                    logger.debug("Shelf items loading cancelled")
//                    return
//                }
//                
//                guard accountsManager.isAuthenticated else {
//                    logger.error("User not authenticated")
//                    throw NetworkError.unauthorized
//                }
//                
//                let endpoint = ShelfEndpoint.get(
//                    type: selectedShelfType,
//                    category: selectedCategory,
//                    page: currentPage
//                )
//                logger.debug("Fetching shelf items with endpoint: \(String(describing: endpoint))")
//                
//                let result = try await accountsManager.currentClient.fetch(
//                    endpoint, type: PagedMarkSchema.self)
//                
//                guard !Task.isCancelled else {
//                    logger.debug("Shelf items loading cancelled after fetch")
//                    return
//                }
//                
//                if refresh {
//                    shelfItems = result.data
//                } else {
//                    shelfItems.append(contentsOf: result.data)
//                }
//                totalPages = result.pages
//                
//                try? await cacheService.cache(
//                    result, forKey: cacheKey, type: PagedMarkSchema.self)
//                
//                logger.debug("Successfully loaded \(result.data.count) items")
//                
//            } catch {
//                if !Task.isCancelled {
//                    logger.error("Failed to load shelf items: \(error.localizedDescription)")
//                    self.error = "Failed to load library"
//                    if let networkError = error as? NetworkError {
//                        detailedError = networkError.localizedDescription
//                    }
//                }
//            }
//        }
//        
//        await loadTask?.value
//    }
//    
//    func loadNextPage() async {
//        guard currentPage < totalPages, !isLoading else { return }
//        currentPage += 1
//        await loadShelfItems()
//    }
//    
//    func changeShelfType(_ type: ShelfType) {
//        selectedShelfType = type
//        loadTask?.cancel()
//        loadTask = Task {
//            await loadShelfItems(refresh: true)
//        }
//    }
//    
//    func changeCategory(_ category: ItemCategory?) {
//        selectedCategory = category
//        loadTask?.cancel()
//        loadTask = Task {
//            await loadShelfItems(refresh: true)
//        }
//    }
//    
//    func cleanup() {
//        loadTask?.cancel()
//        loadTask = nil
//    }
//}

struct LibraryView: View {
    // MARK: - Properties
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @StateObject private var viewModel = LibraryViewModel()
    @Environment(\.colorScheme) private var colorScheme
        
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            filterView
                .padding(.horizontal, 0)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
            
            contentView
        }
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.large)
        .task {
            viewModel.accountsManager = accountsManager
            await viewModel.loadShelfItems()
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
    
    // MARK: - Filter View
    private var filterView: some View {
        ShelfFilterView(
            selectedShelfType: $viewModel.selectedShelfType,
            selectedCategory: $viewModel.selectedCategory,
            onShelfTypeChange: viewModel.changeShelfType,
            onCategoryChange: viewModel.changeCategory
        )
    }
    
    // MARK: - Content View
    @ViewBuilder
    private var contentView: some View {
        if let error = viewModel.error {
            EmptyStateView(
                "Couldn't Load Library",
                systemImage: "exclamationmark.triangle",
                description: Text(viewModel.detailedError ?? error)
            )
            .refreshable {
                await viewModel.loadShelfItems(refresh: true)
            }
        } else if viewModel.shelfItems.isEmpty && !viewModel.isLoading && !viewModel.isRefreshing {
            EmptyStateView(
                "No Items Found",
                systemImage: "books.vertical",
                description: Text("Add some items to your \(viewModel.selectedShelfType.displayName.lowercased()) list")
            )
            .refreshable {
                await viewModel.loadShelfItems(refresh: true)
            }
        } else {
            libraryContent
        }
    }
    
    // MARK: - Library Content
    private var libraryContent: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.shelfItems) { mark in
                    Button {
                        router.navigate(to: .itemDetailWithItem(item: mark.item))
                    } label: {
                        ShelfItemView(mark: mark)
                            .onAppear {
                                if mark.id == viewModel.shelfItems.last?.id {
                                    Task {
                                        await viewModel.loadNextPage()
                                    }
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
                
                if viewModel.isLoading && !viewModel.isRefreshing {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .padding()
        }
        .refreshable {
            await viewModel.loadShelfItems(refresh: true)
        }
    }
}

// MARK: - ShelfFilterView
private struct ShelfFilterView: View {
    @Binding var selectedShelfType: ShelfType
    @Binding var selectedCategory: ItemCategory?
    let onShelfTypeChange: (ShelfType) -> Void
    let onCategoryChange: (ItemCategory?) -> Void
    
    @State private var activeTab: ItemCategory.shelfAvailable = .allItems
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            shelfTypePicker
            categoryFilter
        }
    }
    
    private var shelfTypePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ShelfType.allCases, id: \.self) { type in
                    Button {
                        selectedShelfType = type
                        onShelfTypeChange(type)
                    } label: {
                        HStack {
                            Image(systemName: type.iconName)
                            Text(type.displayName)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            selectedShelfType == type ?
                            Color.accentColor :
                            Color.secondary.opacity(0.1)
                        )
                        .foregroundStyle(
                            selectedShelfType == type ?
                            Color.white :
                            Color.primary
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var categoryFilter: some View {
        ItemCategoryBarView(activeTab: $activeTab)
            .onChange(of: activeTab) { newValue in
                selectedCategory = newValue.itemCategory
                onCategoryChange(newValue.itemCategory)
            }
    }
}

// MARK: - ShelfItemView
private struct ShelfItemView: View {
    let mark: MarkSchema
    
    var body: some View {
        HStack(spacing: 12) {
            coverImage
            itemDetails
            Spacer()
            chevronIcon
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
    
    private var coverImage: some View {
        KFImage(mark.item.coverImageUrl)
            .placeholder {
                placeholderView
            }
            .onFailure { _ in
                placeholderView
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 60, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
    
    private var placeholderView: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .aspectRatio(2/3, contentMode: .fit)
            .frame(width: 60)
    }
    
    private var itemDetails: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(mark.item.displayTitle ?? "")
                .font(.headline)
                .lineLimit(2)
            
            if let rating = mark.ratingGrade {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text("\(rating)/10")
                }
                .font(.subheadline)
            }
            
            if !mark.tags.isEmpty {
                Text(mark.tags.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
    
    private var chevronIcon: some View {
        Image(systemName: "chevron.right")
            .foregroundStyle(.secondary)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        LibraryView()
            .environmentObject(Router())
            .environmentObject(AppAccountsManager())
    }
}
