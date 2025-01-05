import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    private let userService: UserService
    private let authService: AuthService
    
    @Published var user: User?
    @Published var isLoading = false
    @Published var error: String?
    
    init(userService: UserService, authService: AuthService) {
        self.userService = userService
        self.authService = authService
    }
    
    func loadUserProfile(forceRefresh: Bool = false) async {
        if forceRefresh {
            isLoading = true
        }
        error = nil
        
        do {
            user = try await userService.getCurrentUser(forceRefresh: forceRefresh)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
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
        _viewModel = StateObject(wrappedValue: ProfileViewModel(userService: userService, authService: authService))
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
            
            // Logout Button
            Section {
                Button(role: .destructive, action: {
                    withAnimation {
                        viewModel.logout()
                        dismiss()
                    }
                }) {
                    Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        .labelStyle(.iconOnly)
                }
                .foregroundStyle(.red)
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
