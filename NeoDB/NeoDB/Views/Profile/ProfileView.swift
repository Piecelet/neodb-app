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
    
    init(authService: AuthService) {
        let userService = UserService(authService: authService)
        _viewModel = StateObject(wrappedValue: ProfileViewModel(userService: userService, authService: authService))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if let user = viewModel.user {
                    List {
                        // Profile Header Section
                        Section {
                            HStack(spacing: 16) {
                                AsyncImage(url: URL(string: user.avatar)) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .transition(.scale.combined(with: .opacity))
                                    case .failure(_):
                                        Image(systemName: "person.circle.fill")
                                            .symbolRenderingMode(.hierarchical)
                                            .foregroundStyle(.secondary)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                                .overlay {
                                    if viewModel.isLoading {
                                        Circle()
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                            .overlay {
                                                ProgressView()
                                                    .scaleEffect(0.5)
                                            }
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(user.displayName)
                                        .font(.headline)
                                        .redacted(reason: viewModel.isLoading ? .placeholder : [])
                                    Text("@\(user.username)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .redacted(reason: viewModel.isLoading ? .placeholder : [])
                                }
                            }
                        }
                        
                        // External Account Section
                        if let externalAcct = user.externalAcct {
                            Section("Account Information") {
                                LabeledContent("External Account", value: externalAcct)
                                    .redacted(reason: viewModel.isLoading ? .placeholder : [])
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
                            }
                            .foregroundStyle(.red)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable {
                        await viewModel.loadUserProfile(forceRefresh: true)
                    }
                } else if let error = viewModel.error {
                    EmptyStateView(
                        "Couldn't Load Profile",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else {
                    EmptyStateView(
                        "No Profile",
                        systemImage: "person.crop.circle.badge.exclamationmark",
                        description: Text("Unable to load profile")
                    )
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .overlay {
                if viewModel.isLoading && viewModel.user == nil {
                    ProgressView()
                }
            }
        }
        .task {
            await viewModel.loadUserProfile()
        }
    }
}
