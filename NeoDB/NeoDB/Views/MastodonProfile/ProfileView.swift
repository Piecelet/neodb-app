//
//  ProfileView.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import CustomNavigationTitle
import SwiftUI

struct ProfileView: View {
    let id: String
    let account: MastodonAccount?
    var user: User?

    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @EnvironmentObject private var router: Router

    init(id: String, account: MastodonAccount? = nil, user: User? = nil) {
        self.id = id
        self.account = account
        self.user = user
    }

    var body: some View {
        Group {
            if let error = viewModel.error {
                errorView(error: error)
            } else if let account = account ?? viewModel.account {
                accountProfileView(account: account)
            } else if let user = user {
                userProfileView(user: user)
            } else if viewModel.isLoading {
                loadingView
            } else {
                notFoundView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.accountsManager = accountsManager
            if account == nil && user == nil {
                await viewModel.loadAccount(id: id)
            }
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .enableInjection()
    }

    // MARK: - Main Views

    private func accountProfileView(account: MastodonAccount) -> some View {
        List {
            // Profile Header Section
            Section {
                profileHeaderSection(account: account)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            // Statuses Section
            Section {
                statusesSection
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.automatic)
        .scrollAwareTitle(account.displayName ?? "")
        .refreshable {
            await viewModel.loadAccount(id: id, refresh: true)
            await viewModel.loadStatuses(refresh: true)
        }
    }

    private func profileHeaderSection(account: MastodonAccount) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header Image
            headerImageView(account: account)

            // Avatar and Stats
            avatarAndStatsView(account: account)

            // Profile Info
            profileInfoView(account: account)
        }
    }

    private func headerImageView(account: MastodonAccount) -> some View {
        Group {
            if let header = account.header {
                AsyncImage(url: header) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(.quaternary)
                }
                .frame(height: 200)
                .clipped()
            }
        }
    }

    private func avatarAndStatsView(account: MastodonAccount) -> some View {
        HStack(alignment: .bottom) {
            AccountAvatarView(account: account, size: .large)
                .padding(.leading)
                .offset(y: -40)
            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                // Relationship button
                if let relationship = viewModel.relationship {
                    Button {
                        Task {
                            if relationship.following {
                                await viewModel.unfollow(id: id)
                            } else {
                                await viewModel.follow(id: id)
                            }
                        }
                    } label: {
                        Text(
                            relationship.following
                                ? String(
                                    localized: "timelines_profile_unfollow",
                                    table: "Timelines")
                                : String(
                                    localized: "timelines_profile_follow",
                                    table: "Timelines")
                        )
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            relationship.following
                                ? Color.secondary.opacity(0.1)
                                : Color.accentColor
                        )
                        .foregroundStyle(
                            relationship.following ? .primary : Color.white
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .padding(.leading)
                    .disabled(viewModel.isLoadingRelationship)
                } else if viewModel.isLoadingRelationship {
                    ProgressView()
                        .padding(.leading)
                }

                statsView(account: account)
                    .padding(.horizontal)
            }
        }
        .padding(.bottom, -40)
    }

    private func statsView(account: MastodonAccount) -> some View {
        HStack(spacing: 24) {
            // Posts count
            VStack {
                Text("\(account.statusesCount ?? 0)")
                    .font(.headline)
                Text("timelines_profile_posts", tableName: "Timelines")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Following count
            Button {
                router.navigate(to: .following(id: account.id))
                TelemetryService.shared.trackMastodonProfileFollowingView()
            } label: {
                VStack {
                    Text("\(account.followingCount ?? 0)")
                        .font(.headline)
                    Text("timelines_profile_following", tableName: "Timelines")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            // Followers count
            Button {
                router.navigate(to: .followers(id: account.id))
                TelemetryService.shared.trackMastodonProfileFollowersView()
            } label: {
                VStack {
                    Text("\(account.followersCount ?? 0)")
                        .font(.headline)
                    Text("timelines_profile_followers", tableName: "Timelines")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func profileInfoView(account: MastodonAccount) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(account.displayName ?? "")
                    .font(.title2)
                    .bold()
                    .titleVisibilityAnchor()

                if let relationship = viewModel.relationship {
                    if relationship.followedBy {
                        Text(
                            "timelines_profile_follows_you",
                            tableName: "Timelines"
                        )
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
            }

            Text("@\(account.acct)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if !account.note.asRawText.isEmpty {
                Text(account.note.asRawText)
                    .font(.body)
                    .padding(.top, 4)
            }

            profileFieldsView(fields: account.fields)

            Text(
                String(
                    format: String(
                        localized: "timelines_profile_joined",
                        table: "Timelines"), account.createdAt.relativeFormatted
                )
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.top, 8)
        }
        .padding(.horizontal)
    }

    private func profileFieldsView(fields: [MastodonAccount.Field]) -> some View
    {
        Group {
            if !fields.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(fields) { field in
                        VStack(alignment: .leading) {
                            Text(field.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(field.value.asRawText)
                                .font(.callout)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
    }

    private var statusesSection: some View {
        Group {
            if viewModel.isLoadingStatuses && viewModel.statuses.isEmpty {
                ForEach(
                    Array(MastodonStatus.placeholders().enumerated()),
                    id: \.offset
                ) { index, status in
                    StatusView(status: status, mode: .timeline)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .alignmentGuide(.listRowSeparatorLeading) { _ in
                            return 4
                        }
                        .redacted(reason: .placeholder)
                }
            } else if viewModel.statuses.isEmpty && viewModel.account != nil
                && viewModel.isLoading == false
            {
                emptyStatusesView
            } else {
                statusListView
            }
        }
    }

    private var statusListView: some View {
        Group {
            ForEach(viewModel.statuses, id: \.id) { status in
                statusRowView(status: status)
            }

            if viewModel.hasMore {
                loadMoreView
            }
        }
    }

    private func statusRowView(status: MastodonStatus) -> some View {
        Group {
            if let item = status.content.links.compactMap(\.neodbItem).first {
                Button {
                    router.navigate(
                        to: .statusDetailWithStatusAndItem(
                            status: status, item: item))
                } label: {
                    StatusView(status: status, mode: .timelineWithItem)
                }
            } else {
                Button {
                    router.navigate(to: .statusDetailWithStatus(status: status))
                } label: {
                    StatusView(status: status, mode: .timeline)
                }
            }
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
        .alignmentGuide(.listRowSeparatorLeading) { _ in
            return 4
        }
    }

    private var loadMoreView: some View {
        ProgressView()
            .id(UUID())
            .frame(maxWidth: .infinity)
            .padding()
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .onAppear {
                if !viewModel.isLoadingStatuses {
                    Task {
                        await viewModel.loadNextPage()
                    }
                }
            }
    }

    private var emptyStatusesView: some View {
        EmptyStateView(
            String(localized: "timelines_no_posts_title", table: "Timelines"),
            systemImage: "text.bubble",
            description: Text(
                String(
                    localized: "timelines_no_posts_description",
                    table: "Timelines"))
        )
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .padding(.vertical, 30)
    }

    private func userProfileView(user: User) -> some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    // Avatar
                    HStack(alignment: .center) {
                        AccountAvatarView(user: user, size: .large)
                            .padding(.leading)

                        Spacer()
                    }
                    .padding(.vertical)

                    // Profile Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(user.displayName)
                            .font(.title2)
                            .bold()
                        Text("@\(user.username)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if let externalAcct = user.externalAcct {
                            Text(externalAcct)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func errorView(error: Error) -> some View {
        EmptyStateView(
            String(
                localized: "timelines_profile_error_title", table: "Timelines"),
            systemImage: "exclamationmark.triangle",
            description: Text(error.localizedDescription)
        )
        .refreshable {
            await viewModel.loadAccount(id: id, refresh: true)
        }
    }

    private var loadingView: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var notFoundView: some View {
        EmptyStateView(
            String(
                localized: "timelines_profile_not_found_title",
                table: "Timelines"),
            systemImage: "person.slash",
            description: Text(
                String(
                    localized: "timelines_profile_not_found_description",
                    table: "Timelines")
            )
        )
        .refreshable {
            await viewModel.loadAccount(id: id, refresh: true)
        }
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}

#Preview {
    NavigationStack {
        ProfileView(id: "1", account: .placeholder())
            .environmentObject(AppAccountsManager())
            .environmentObject(Router())
    }
}
