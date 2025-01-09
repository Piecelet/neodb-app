import SwiftUI
import OSLog

@MainActor
class LibraryViewModel: ObservableObject {
    private let shelfService: ShelfService
    private let logger = Logger(subsystem: "social.neodb.app", category: "LibraryViewModel")
    
    @Published var selectedShelfType: ShelfType = .wishlist
    @Published var shelfItems: [MarkSchema] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var currentPage = 1
    @Published var totalPages = 1
    @Published var selectedCategory: ItemCategory?
    
    private var currentLoadTask: Task<Void, Never>?

    init(shelfService: ShelfService) {
        self.shelfService = shelfService
    }
    
    func loadShelfItems(refresh: Bool = false) async {
        currentLoadTask?.cancel()
        
        let task = Task { @MainActor in
            if refresh {
                currentPage = 1
                shelfItems = []
            }
            
            guard !isLoading else { return }
            isLoading = true
            error = nil
            
            do {
                let result = try await shelfService.getShelfItems(
                    type: selectedShelfType,
                    category: selectedCategory,
                    page: currentPage
                )
                
                try Task.checkCancellation()
                
                if refresh {
                    shelfItems = result.data
                } else {
                    shelfItems.append(contentsOf: result.data)
                }
                totalPages = result.pages
            } catch is CancellationError {
                logger.debug("Load task was cancelled")
            } catch {
                if !Task.isCancelled {
                    self.error = error.localizedDescription
                    logger.error("Failed to load shelf items: \(error)")
                }
            }
            
            if !Task.isCancelled {
                isLoading = false
            }
        }
        
        currentLoadTask = task
        await task.value
    }
    
    func loadNextPage() async {
        guard currentPage < totalPages, !isLoading else { return }
        currentPage += 1
        await loadShelfItems()
    }
    
    func changeShelfType(_ type: ShelfType) {
        selectedShelfType = type
        currentLoadTask?.cancel()
        currentLoadTask = Task {
            await loadShelfItems(refresh: true)
        }
    }
    
    func changeCategory(_ category: ItemCategory?) {
        selectedCategory = category
        currentLoadTask?.cancel()
        currentLoadTask = Task {
            await loadShelfItems(refresh: true)
        }
    }
    
    func cleanup() {
        currentLoadTask?.cancel()
        currentLoadTask = nil
    }
}

struct LibraryView: View {
    @StateObject private var viewModel: LibraryViewModel
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var router: Router
    
    init(authService: AuthService) {
        let shelfService = ShelfService(authService: authService)
        _viewModel = StateObject(wrappedValue: LibraryViewModel(shelfService: shelfService))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Shelf Type Picker
            ShelfFilterView(
                selectedShelfType: $viewModel.selectedShelfType,
                selectedCategory: $viewModel.selectedCategory,
                onShelfTypeChange: viewModel.changeShelfType,
                onCategoryChange: viewModel.changeCategory
            )
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            
            // Content
            Group {
                if let error = viewModel.error {
                    EmptyStateView(
                        "Couldn't Load Library",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else if viewModel.shelfItems.isEmpty && !viewModel.isLoading {
                    EmptyStateView(
                        "No Items Found",
                        systemImage: "books.vertical",
                        description: Text("Add some items to your \(viewModel.selectedShelfType.displayName.lowercased()) list")
                    )
                } else {
                    libraryContent
                }
            }
        }
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadShelfItems()
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
    
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
                
                if viewModel.isLoading {
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
