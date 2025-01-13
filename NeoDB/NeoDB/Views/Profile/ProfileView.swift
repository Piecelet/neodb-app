//
//  ProfileView.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 1/7/25.
//

import SwiftUI
import Kingfisher
import OSLog

@MainActor
class ProfileViewModel: ObservableObject {
    private let accountsManager: AppAccountsManager
    private let cacheService: CacheService
    private let logger = Logger.networkUser
    
    @Published var user: User?
    @Published var isLoading = false
    @Published var error: String?
    
    init(accountsManager: AppAccountsManager) {
        self.accountsManager = accountsManager
        self.cacheService = CacheService()
    }
    
    func loadUserProfile(forceRefresh: Bool = false) async {
        if forceRefresh {
            isLoading = true
        }
        error = nil
        
        do {
            user = try await getCurrentUser(forceRefresh: forceRefresh)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func getCurrentUser(forceRefresh: Bool = false) async throws -> User {
        let cacheKey = "\(accountsManager.currentAccount.instance)_user"
        
        // Return cached user if available and not forcing refresh
        if !forceRefresh, let cachedUser = try? await cacheService.retrieve(
            forKey: cacheKey,
            type: User.self
        ) {
            logger.debug("Returning cached user for instance: \(accountsManager.currentAccount.instance)")
            return cachedUser
        }
        
        guard accountsManager.isAuthenticated else {
            logger.error("No access token available")
            throw NetworkError.unauthorized
        }
        
        logger.debug("Fetching user profile from network")
        let user = try await accountsManager.currentClient.fetch(UserEndpoint.me, type: User.self)
        
        // Cache the user
        try? await cacheService.cache(user, forKey: cacheKey, type: User.self)
        logger.debug("Cached user profile for instance: \(accountsManager.currentAccount.instance)")
        
        return user
    }
    
    func logout() {
        Task {
            try? await cacheService.remove(forKey: "\(accountsManager.currentAccount.instance)_user", type: User.self)
            logger.debug("Cleared user cache")
        }
        accountsManager.delete(account: accountsManager.currentAccount)
    }
}

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.refresh) private var refresh
    
    private let avatarSize: CGFloat = 60
    
    init(accountsManager: AppAccountsManager) {
        _viewModel = StateObject(wrappedValue: ProfileViewModel(
            accountsManager: accountsManager
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
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
    
    private var profileContent: some View {
        List {
            // Profile Header Section
            Section {
                HStack(spacing: 16) {
                    if let user = viewModel.user {
                        KFImage(user.avatar)
                            .placeholder {
                                placeholderAvatar
                            }
                            .onFailure { _ in
                                Image(systemName: "person.circle.fill")
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(.secondary)
                                    .font(.system(size: avatarSize * 0.8))
                                    .frame(width: avatarSize, height: avatarSize)
                            }
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: avatarSize, height: avatarSize)
                            .clipShape(Circle())
                            .transition(.scale.combined(with: .opacity))
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
