import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    private let userService: UserService
    private let authService: AuthService
    private let shelfService: ShelfService
    
    @Published var user: User?
    @Published var isLoading = false
    @Published var error: String?
    
    // Shelf data
    @Published var selectedShelfType: ShelfType = .wishlist
    @Published var shelfItems: [MarkSchema] = []
    @Published var isLoadingShelf = false
    @Published var shelfError: String?
    @Published var currentPage = 1
    @Published var totalPages = 1
    @Published var selectedCategory: ItemCategory?
    
    init(userService: UserService, authService: AuthService, shelfService: ShelfService) {
        self.userService = userService
        self.authService = authService
        self.shelfService = shelfService
    }
    
    func loadUserProfile(forceRefresh: Bool = false) async {
        if forceRefresh {
            isLoading = true
        }
        error = nil
        
        do {
            user = try await userService.getCurrentUser(forceRefresh: forceRefresh)
            // Load shelf items after profile is loaded
            await loadShelfItems(refresh: true)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadShelfItems(refresh: Bool = false) async {
        if refresh {
            currentPage = 1
            shelfItems = []
        }
        
        guard !isLoadingShelf else { return }
        isLoadingShelf = true
        shelfError = nil
        
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
            shelfError = error.localizedDescription
        }
        
        isLoadingShelf = false
    }
    
    func loadNextPage() async {
        guard currentPage < totalPages, !isLoadingShelf else { return }
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
    
    func logout() {
        userService.clearCache()
        authService.logout()
    }
}

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.refresh) private var refresh
    
    private let avatarSize: CGFloat = 60
    
    init(authService: AuthService) {
        let userService = UserService(authService: authService)
        let shelfService = ShelfService(authService: authService)
        _viewModel = StateObject(wrappedValue: ProfileViewModel(
            userService: userService,
            authService: authService,
            shelfService: shelfService
        ))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if let error = viewModel.error {
                    EmptyStateView(
                        "Couldn't Load Profile",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else {
                    profileContent
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            await viewModel.loadUserProfile()
        }
    }
    
    private var profileContent: some View {
        List {
            // Profile Header Section
            Section {
                HStack(spacing: 16) {
                    if let user = viewModel.user {
                        AsyncImage(url: URL(string: user.avatar)) { phase in
                            switch phase {
                            case .empty:
                                placeholderAvatar
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: avatarSize, height: avatarSize)
                                    .clipShape(Circle())
                                    .transition(.scale.combined(with: .opacity))
                            case .failure(_):
                                Image(systemName: "person.circle.fill")
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(.secondary)
                                    .font(.system(size: avatarSize * 0.8))
                                    .frame(width: avatarSize, height: avatarSize)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        placeholderAvatar
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        if let user = viewModel.user {
                            Text(user.displayName)
                                .font(.headline)
                            Text("@\(user.username)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Loading Name")
                                .font(.headline)
                            Text("@username")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .redacted(reason: viewModel.user == nil || viewModel.isLoading ? .placeholder : [])
                }
            }
            
            // External Account Section
            if let user = viewModel.user, let externalAcct = user.externalAcct {
                Section("Account Information") {
                    LabeledContent("External Account", value: externalAcct)
                        .redacted(reason: viewModel.isLoading ? .placeholder : [])
                }
            } else if viewModel.user == nil {
                Section("Account Information") {
                    LabeledContent("External Account", value: "loading...")
                        .redacted(reason: .placeholder)
                }
            }
            
            // Shelf Section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    // Shelf Type Picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(ShelfType.allCases, id: \.self) { type in
                                Button {
                                    viewModel.changeShelfType(type)
                                } label: {
                                    HStack {
                                        Image(systemName: type.systemImage)
                                        Text(type.displayName)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        viewModel.selectedShelfType == type ?
                                        Color.accentColor :
                                        Color.secondary.opacity(0.1)
                                    )
                                    .foregroundStyle(
                                        viewModel.selectedShelfType == type ?
                                        Color.white :
                                        Color.primary
                                    )
                                    .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    
                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            Button {
                                viewModel.changeCategory(nil)
                            } label: {
                                Text("All")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        viewModel.selectedCategory == nil ?
                                        Color.accentColor :
                                        Color.secondary.opacity(0.1)
                                    )
                                    .foregroundStyle(
                                        viewModel.selectedCategory == nil ?
                                        Color.white :
                                        Color.primary
                                    )
                                    .clipShape(Capsule())
                            }
                            
                            ForEach([ItemCategory.book, .movie, .tv, .game], id: \.self) { category in
                                Button {
                                    viewModel.changeCategory(category)
                                } label: {
                                    Text(category.rawValue.capitalized)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            viewModel.selectedCategory == category ?
                                            Color.accentColor :
                                            Color.secondary.opacity(0.1)
                                        )
                                        .foregroundStyle(
                                            viewModel.selectedCategory == category ?
                                            Color.white :
                                            Color.primary
                                        )
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    
                    // Shelf Items
                    if viewModel.shelfError != nil {
                        Text(viewModel.shelfError!)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical)
                    } else if viewModel.shelfItems.isEmpty && !viewModel.isLoadingShelf {
                        Text("No items found")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical)
                    } else {
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
                            
                            if viewModel.isLoadingShelf {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                        }
                    }
                }
            } header: {
                Text("My Shelf")
            }
            
            // Logout Button
            Section {
                Button(role: .destructive, action: {
                    withAnimation {
                        viewModel.logout()
                        dismiss()
                    }
                }) {
                    Text("Sign Out")
                        .frame(maxWidth: .infinity)
                }
                .disabled(viewModel.user == nil)
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await viewModel.loadUserProfile(forceRefresh: true)
        }
        .overlay {
            if viewModel.isLoading && viewModel.user == nil {
                Color.clear
                    .background(.ultraThinMaterial)
                    .overlay {
                        ProgressView()
                    }
                    .allowsHitTesting(false)
            }
        }
        .enableInjection()
    }
    
    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
    
    private var placeholderAvatar: some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: avatarSize, height: avatarSize)
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.5)
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: avatarSize * 0.5))
                        .foregroundStyle(.secondary)
                }
            }
    }
}

struct ShelfItemView: View {
    let mark: MarkSchema
    
    var body: some View {
        HStack(spacing: 12) {
            // Cover Image
            AsyncImage(url: URL(string: mark.item.coverImageUrl ?? "")) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(2/3, contentMode: .fit)
                        .frame(width: 60)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 90)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                case .failure:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(2/3, contentMode: .fit)
                        .frame(width: 60)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        }
                @unknown default:
                    EmptyView()
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(mark.item.displayTitle)
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
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
