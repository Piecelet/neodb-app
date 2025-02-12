//
//  SettingsView.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 1/7/25.
//

import Kingfisher
import OSLog
import SwiftUI
import WishKit
import Defaults

@MainActor
class SettingsViewModel: ObservableObject {
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
    @Published var isCacheClearing = false
    @Published var showClearCacheConfirmation = false

    private let cacheService = CacheService.shared
    private let logger = Logger.views.settings

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

    private func getCurrentUser(forceRefresh: Bool = false) async throws -> User
    {
        guard let accountsManager = accountsManager else {
            throw NetworkError.unauthorized
        }

        if !forceRefresh,
            let cachedUser = try? await cacheService.retrieveUser(
                key: accountsManager.currentAccount.id)
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

        try? await cacheService.cacheUser(
            user, key: accountsManager.currentAccount.id)
        logger.debug(
            "Cached user profile for instance: \(accountsManager.currentAccount.instance)"
        )

        return user
    }

    func logout() {
        guard let accountsManager = accountsManager else { return }
        Task {
            try? await cacheService.removeUser(
                key: accountsManager.currentAccount.id)
            logger.debug("Cleared user cache")
        }
        accountsManager.delete(account: accountsManager.currentAccount)
    }

    func clearAllCaches() async {
        isCacheClearing = true
        await cacheService.removeAll()
        isCacheClearing = false
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
                    Text(User.placeholder().displayName)
                        .font(.headline)
                    Text(User.placeholder().username)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .redacted(reason: user == nil || isLoading ? .placeholder : [])
        }
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
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
            .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}

struct AccountRow: View {
    @EnvironmentObject private var accountsManager: AppAccountsManager
    let account: AppAccount
    private let avatarSize: CGFloat = 40

    var body: some View {
        HStack(spacing: 12) {
            if let avatarURL = account.avatar.flatMap(URL.init) {
                KFImage(avatarURL)
                    .placeholder {
                        AvatarPlaceholderView(
                            isLoading: false,
                            size: avatarSize
                        )
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: avatarSize, height: avatarSize)
                    .clipShape(Circle())
                    .saturation(
                        account.id == accountsManager.currentAccount.id ? 1 : 0
                    )
                    .opacity(
                        account.id == accountsManager.currentAccount.id
                            ? 1 : 0.6)
            } else {
                AvatarPlaceholderView(
                    isLoading: false,
                    size: avatarSize
                )
                .opacity(
                    account.id == accountsManager.currentAccount.id ? 1 : 0.6)
            }

            VStack(alignment: .leading) {
                Text(account.displayName ?? account.instance)
                    .font(.headline)
                Text(account.handle ?? "Unauthenticated")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if account.id == accountsManager.currentAccount.id {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.tint)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            switchToAccount(account)
            TelemetryService.shared.trackSettingsSwitchAccount(to: account.instance)
        }
        .swipeActions(edge: .trailing) {
            if account.id != accountsManager.currentAccount.id {
                Button(role: .destructive) {
                    deleteAccount(account)
                    TelemetryService.shared.trackSettingsDeleteAccount(from: account.instance)
                } label: {
                    Label("Remove", systemImage: "trash")
                }
            }
        }
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif

    private func switchToAccount(_ account: AppAccount) {
        withAnimation {
            accountsManager.currentAccount = account
        }
    }

    private func deleteAccount(_ account: AppAccount) {
        withAnimation {
            accountsManager.delete(account: account)
        }
    }
}

struct AccountManagementSection: View {
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var storeManager: StoreManager

    var body: some View {
        Section {
            ForEach(accountsManager.availableAccounts) { account in
                AccountRow(account: account)
            }

            Button(action: addAccount) {
                Label(
                    String(localized: "account_add", table: "Settings"),
                    systemImage: "person.badge.plus")
            }
        } header: {
            Text(String(localized: "accounts_title", table: "Settings"))
        } footer: {
            if accountsManager.availableAccounts.count > 1 {
                Text(String(localized: "accounts_footer", table: "Settings"))
            }
        }
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif

    private func addAccount() {
        if !storeManager.isPlus {
            router.presentSheet(
                .purchaseWithFeature(feature: .multipleAccounts))
        } else {
            router.presentSheet(.login)
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.refresh) private var refresh
    @EnvironmentObject private var router: Router
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var storeManager: StoreManager

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
        .navigationTitle(String(localized: "settings_title", table: "Settings"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Text("settings_title", tableName: "Settings")
                    .font(.system(size: 24))
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 2)
                    .padding(.top, 4)
            }
            ToolbarItem(placement: .principal) {
                Text("settings_title", tableName: "Settings")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 2)
                    .hidden()
            }
        }
        .task {
            TelemetryService.shared.trackSettingsView()
        }
        #if DEBUG
            .enableInjection()
        #endif
    }

    // MARK: - Content Views
    @ViewBuilder
    private var contentView: some View {
        Group {
            profileContent
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
            String(localized: "profile_error_title", table: "Settings"),
            systemImage: "exclamationmark.triangle",
            description: Text(error),
            actions: {
                logoutButton
            }
        )
    }

    private var profileContent: some View {
        List {
            if viewModel.isLoading && viewModel.user == nil {
                loadingView
            } else if let error = viewModel.error {
                errorView(error)
            } else {
            profileHeaderSection
            }
            purchaseSection
            accountManagementSection
            if viewModel.error == nil {
                accountInformationSection
            }
            mainInterfaceSection
            appSection
            cacheManagementSection
            logoutSection
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await viewModel.loadUserProfile(forceRefresh: true)
        }
        .confirmationDialog(
            Text("cache_clear_button", tableName: "Settings"),
            isPresented: $viewModel.showClearCacheConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear", role: .destructive) {
                Task {
                    await viewModel.clearAllCaches()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("cache_clear_confirmation", tableName: "Settings")
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

    private var accountManagementSection: some View {
        AccountManagementSection()
    }

    private var accountInformationSection: some View {
        Group {
            if let user = viewModel.user, !user.externalAccounts.isEmpty {
                Section {
                    ForEach(user.externalAccounts, id: \.self) {
                        externalAccount in
                        LabeledContent {
                            Text(externalAccount.handle)
                        } label: {
                            Text(externalAccount.platform.capitalized)
                        }
                    }
                    .redacted(reason: viewModel.isLoading ? .placeholder : [])
                } header: {
                    Text(String(localized: "account_title", table: "Settings"))
                }
            } else if viewModel.user == nil {
                Section {
                    LabeledContent {
                        Text(
                            String(localized: "loading_text", table: "Settings")
                        )
                    } label: {
                        Text(
                            String(
                                localized: "account_external", table: "Settings"
                            ))
                    }
                    .redacted(reason: .placeholder)
                } header: {
                    Text(String(localized: "account_title", table: "Settings"))
                }
            }
        }
    }

    private var purchaseSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Label {
                        Text("store_title", tableName: "Settings")
                            .font(.headline)
                    } icon: {
                        Image(systemSymbol: .bubblesAndSparkles)
                            .font(.title2)
                    }
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.primary)

                    VStack(alignment: .leading, spacing: 4) {
                        Label {
                            Text("store_title", tableName: "Settings")
                                .font(.headline)
                        } icon: {
                            Image(systemSymbol: .bubblesAndSparkles)
                                .font(.title2)
                        }
                        .labelStyle(.titleOnly)
                        .foregroundStyle(.primary)
                        if storeManager.isPlus {
                            Text(
                                "store_description_plus", tableName: "Settings"
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        } else {
                            Text("store_description", tableName: "Settings")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .background(
                ZStack {
                    LinearGradient(
                        colors: [
                            .green.opacity(0.8),
                            .mint.opacity(0.9),
                            .teal.opacity(0.8),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .opacity(0.5)

                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            colorScheme == .dark
                                ? .black.opacity(0.7) : .white.opacity(0.9)
                        )
                        .padding(2)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                NavigationLink(destination: PurchaseView()) {
                    EmptyView()
                }
                .opacity(0)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }

    private var mainInterfaceSection: some View {
        SettingsViewCustomizeHome()
    }

    private var appSection: some View {
        Section {
            NavigationLink {
                WishKitView()
            } label: {
                Label {
                    Text("app_feature_requests", tableName: "Settings")
                } icon: {
                    Image(systemName: "lightbulb")
                }
            }
            NavigationLink {
                AboutView()
            } label: {
                Label {
                    Text("app_about", tableName: "Settings")
                } icon: {
                    Image(systemName: "info.circle")
                }
            }
            #if DEBUG
                NavigationLink {
                    DeveloperView()
                } label: {
                    Label {
                        Text(
                            String(
                                localized: "developer_title", table: "Settings")
                        )
                    } icon: {
                        Image(systemName: "hammer")
                    }
                }
            #endif
        } header: {
            Text("app_title", tableName: "Settings")
        }
    }

    private var cacheManagementSection: some View {
        Section {
            Button(role: .destructive) {
                viewModel.showClearCacheConfirmation = true
                TelemetryService.shared.trackSettingsClearCache()
            } label: {
                HStack {
                    if viewModel.isCacheClearing {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text("cache_clear_button", tableName: "Settings")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .disabled(viewModel.isCacheClearing)
        } header: {
            Text("cache_title", tableName: "Settings")
        } footer: {
            Text("cache_clear_footer", tableName: "Settings")
        }
    }

    private var logoutSection: some View {
        Section {
            logoutButton
        }
    }

    private var logoutButton: some View {
            Button(role: .destructive) {
                withAnimation {
                    viewModel.logout()
                    dismiss()
                }
                TelemetryService.shared.trackSettingsSignOut()
            } label: {
                Text(String(localized: "signout_button", table: "Settings"))
                    .frame(maxWidth: .infinity)
            }
    }
    
}
