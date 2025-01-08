import SwiftUI
import OSLog
import Kingfisher

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
    
    init(shelfService: ShelfService) {
        self.shelfService = shelfService
    }
    
    func loadShelfItems(refresh: Bool = false) async {
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
            if refresh {
                shelfItems = result.data
            } else {
                shelfItems.append(contentsOf: result.data)
            }
            totalPages = result.pages
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadNextPage() async {
        guard currentPage < totalPages, !isLoading else { return }
        currentPage += 1
        await loadShelfItems()
    }
    
    func changeShelfType(_ type: ShelfType) {
        selectedShelfType = type
        Task {
            await loadShelfItems(refresh: true)
        }
    }
    
    func changeCategory(_ category: ItemCategory?) {
        selectedCategory = category
        Task {
            await loadShelfItems(refresh: true)
        }
    }
}

struct LibraryView: View {
    @StateObject private var viewModel: LibraryViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    init(authService: AuthService) {
        let shelfService = ShelfService(authService: authService)
        _viewModel = StateObject(wrappedValue: LibraryViewModel(shelfService: shelfService))
    }
    
    var body: some View {
        NavigationStack {
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
        }
        .task {
            await viewModel.loadShelfItems()
        }
    }
    
    private var libraryContent: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.shelfItems) { mark in
                    ShelfItemView(mark: mark)
                        .onAppear {
                            if mark.id == viewModel.shelfItems.last?.id {
                                Task {
                                    await viewModel.loadNextPage()
                                }
                            }
                        }
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
