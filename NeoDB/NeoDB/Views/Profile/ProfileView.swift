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
    
    func loadUserProfile() async {
        isLoading = true
        error = nil
        
        do {
            user = try await userService.getCurrentUser()
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func logout() {
        authService.logout()
    }
}

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    init(authService: AuthService) {
        let userService = UserService(authService: authService)
        _viewModel = StateObject(wrappedValue: ProfileViewModel(userService: userService, authService: authService))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(1.2)
                } else if let user = viewModel.user {
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
                                    Circle()
                                        .stroke(
                                            .linearGradient(
                                                colors: [.blue.opacity(0.5), .purple.opacity(0.5)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                }
                                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(user.displayName)
                                        .font(.headline)
                                    Text("@\(user.username)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .listRowBackground(Color.clear)
                        }
                        
                        // External Account Section
                        if let externalAcct = user.externalAcct {
                            Section("Account Information") {
                                HStack {
                                    Label {
                                        Text("External Account")
                                    } icon: {
                                        Image(systemName: "link")
                                            .foregroundStyle(.blue)
                                    }
                                    Spacer()
                                    Text(externalAcct)
                                        .foregroundStyle(.secondary)
                                }
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
                                    .font(.headline)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background {
                                        Capsule()
                                            .fill(.red.opacity(0.1))
                                    }
                                    .overlay {
                                        Capsule()
                                            .stroke(.red.opacity(0.3), lineWidth: 1)
                                    }
                            }
                            .foregroundStyle(.red)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .background {
                        Color(colorScheme == .dark ? .black : .white)
                            .ignoresSafeArea()
                    }
                } else if let error = viewModel.error {
                    EmptyStateView(
                        "Error",
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
        }
        .task {
            await viewModel.loadUserProfile()
        }
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}
