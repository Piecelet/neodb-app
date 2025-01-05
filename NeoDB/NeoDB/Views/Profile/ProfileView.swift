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
    
    init(authService: AuthService) {
        let userService = UserService(authService: authService)
        _viewModel = StateObject(wrappedValue: ProfileViewModel(userService: userService, authService: authService))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if let user = viewModel.user {
                    ScrollView {
                        VStack(spacing: 20) {
                            AsyncImage(url: URL(string: user.avatar)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                            
                            VStack(spacing: 8) {
                                Text(user.displayName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("@\(user.username)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let externalAcct = user.externalAcct {
                                Text(externalAcct)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            
                            Button(role: .destructive, action: {
                                viewModel.logout()
                                dismiss()
                            }) {
                                Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            .padding(.top, 20)
                        }
                        .padding()
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
        }
        .task {
            await viewModel.loadUserProfile()
        }
    }
} 