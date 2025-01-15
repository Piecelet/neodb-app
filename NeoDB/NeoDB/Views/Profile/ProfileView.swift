//
//  ProfileView.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 1/7/25.
//

import Kingfisher
import OSLog
import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    var accountsManager: AppAccountsManager? {
        didSet {
            if oldValue !== accountsManager {
                user = nil
            }
        }
    }
    
    @Published var user: User?
    @Published var isLoading = false
    @Published var error: String?

    private let cacheService: CacheService
    private let logger = Logger.views.profile

    init() {
        self.cacheService = CacheService()
    }

    func loadUserProfile(forceRefresh: Bool = false) async {
        guard accountsManager != nil else { return }
        
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
        guard let accountsManager = accountsManager else {
            throw NetworkError.unauthorized
        }
        
        let cacheKey = "\(accountsManager.currentAccount.instance)_user"

        if !forceRefresh,
            let cachedUser = try? await cacheService.retrieve(
                forKey: cacheKey,
                type: User.self
            )
        {
            logger.debug(
                "Returning cached user for instance: \(accountsManager.currentAccount.instance)"
            )
            return cachedUser
        }

        guard accountsManager.isAuthenticated else {
            logger.error("No access token available")
            throw NetworkError.unauthorized
        }

        logger.debug("Fetching user profile from network")
        let user = try await accountsManager.currentClient.fetch(
            UserEndpoint.me, type: User.self)

        try? await cacheService.cache(user, forKey: cacheKey, type: User.self)
        logger.debug(
            "Cached user profile for instance: \(accountsManager.currentAccount.instance)"
        )

        return user
    }

    func logout() {
        guard let accountsManager = accountsManager else { return }
        Task {
            try? await cacheService.remove(
                forKey: "\(accountsManager.currentAccount.instance)_user",
                type: User.self)
            logger.debug("Cleared user cache")
        }
        accountsManager.delete(account: accountsManager.currentAccount)
    }
}

struct ProfileHeaderView: View {
    let user: User?
    let isLoading: Bool
    let avatarSize: CGFloat

    var body: some View {
        HStack(spacing: 16) {
            if let user = user {
                KFImage(user.avatar)
                    .placeholder {
                        AvatarPlaceholderView(
                            isLoading: isLoading, size: avatarSize)
                    }
                    .onFailure { _ in
                        Image(systemName: "person.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                            .font(.system(size: avatarSize * 0.8))
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: avatarSize, height: avatarSize)
                    .clipShape(Circle())
                    .transition(.scale.combined(with: .opacity))
            } else {
                AvatarPlaceholderView(isLoading: isLoading, size: avatarSize)
            }

            VStack(alignment: .leading, spacing: 4) {
                if let user = user {
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
            .redacted(reason: user == nil || isLoading ? .placeholder : [])
        }
    }
}

struct AvatarPlaceholderView: View {
    let isLoading: Bool
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: size, height: size)
            .overlay {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.5)
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.5))
                        .foregroundStyle(.secondary)
                }
            }
    }
}

struct ProfileView: View {
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @StateObject private var viewModel = ProfileViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.refresh) private var refresh

    private let avatarSize: CGFloat = 60

    // MARK: - Body
    var body: some View {
        Group {
            contentView
        }
        .task {
            viewModel.accountsManager = accountsManager
            await viewModel.loadUserProfile()
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        #if DEBUG
        .enableInjection()
        #endif
    }

    // MARK: - Content Views
    @ViewBuilder
    private var contentView: some View {
        Group {
            if viewModel.isLoading && viewModel.user == nil {
                loadingView
            } else if let error = viewModel.error {
                errorView(error)
            } else {
                profileContent
            }
        }
        .animation(.smooth, value: viewModel.isLoading)
        .animation(.smooth, value: viewModel.error)
    }

    private var loadingView: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(_ error: String) -> some View {
        EmptyStateView(
            "Couldn't Load Profile",
            systemImage: "exclamationmark.triangle",
            description: Text(error)
        )
    }

    private var profileContent: some View {
        List {
            profileHeaderSection
            accountInformationSection
            logoutSection
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await viewModel.loadUserProfile(forceRefresh: true)
        }
    }
    
    // MARK: - Section Views
    private var profileHeaderSection: some View {
        Section {
            ProfileHeaderView(
                user: viewModel.user,
                isLoading: viewModel.isLoading,
                avatarSize: avatarSize
            )
        }
    }
    
    private var accountInformationSection: some View {
        Group {
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
        }
    }
    
    private var logoutSection: some View {
        Section {
            Button(role: .destructive) {
                withAnimation {
                    viewModel.logout()
                    dismiss()
                }
            } label: {
                Text("Sign Out")
                    .frame(maxWidth: .infinity)
            }
            .disabled(viewModel.user == nil)
        }
    }
}
