//
//  ProfileView.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import SwiftUI
import CustomNavigationTitle

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
                EmptyStateView(
                    String(
                        localized: "timelines_profile_error_title",
                        table: "Timelines"),
                    systemImage: "exclamationmark.triangle",
                    description: Text(error.localizedDescription)
                )
                .refreshable {
                    await viewModel.loadAccount(id: id, refresh: true)
                }
            } else if let account = account ?? viewModel.account {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Header Image
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

                        // Avatar and Stats
                        HStack(alignment: .bottom) {
                            AccountAvatarView(account: account, size: .large)
                                .padding(.leading)
                                .offset(y: -40)

                            Spacer()

                            // Stats
                            HStack(spacing: 24) {
                                VStack {
                                    Text("\(account.statusesCount ?? 0)")
                                        .font(.headline)
                                    Text(
                                        "timelines_profile_posts",
                                        tableName: "Timelines"
                                    )
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }

                                Button {
                                    router.navigate(
                                        to: .following(id: account.id))
                                    TelemetryService.shared.trackMastodonProfileFollowingView()
                                } label: {
                                    VStack {
                                        Text("\(account.followingCount ?? 0)")
                                            .font(.headline)
                                        Text(
                                            "timelines_profile_following",
                                            tableName: "Timelines"
                                        )
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Button {
                                    router.navigate(
                                        to: .followers(id: account.id))
                                    TelemetryService.shared.trackMastodonProfileFollowersView()
                                } label: {
                                    VStack {
                                        Text("\(account.followersCount ?? 0)")
                                            .font(.headline)
                                        Text(
                                            "timelines_profile_followers",
                                            tableName: "Timelines"
                                        )
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom, -40)

                        // Profile Info
                        VStack(alignment: .leading, spacing: 8) {
                            Text(account.displayName ?? "")
                                .font(.title2)
                                .bold()
                                .titleVisibilityAnchor()
                            Text("@\(account.username)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            if !account.note.asRawText.isEmpty {
                                Text(account.note.asRawText)
                                    .font(.body)
                                    .padding(.top, 4)
                            }

                            if !account.fields.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(account.fields) { field in
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

                            Text(
                                String(
                                    format: String(
                                        localized: "timelines_profile_joined",
                                        table: "Timelines"), account.createdAt.relativeFormatted)
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                        }
                        .padding(.horizontal)
                    }
                    
                    Divider()

                    // 状态列表
                    if viewModel.isLoadingStatuses && viewModel.statuses.isEmpty {
                        ForEach(Array(MastodonStatus.placeholders().enumerated()), id: \.offset) { index, status in
                            StatusView(status: status, mode: .timeline)
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                                .alignmentGuide(.listRowSeparatorLeading) { _ in
                                    return 4
                                }
                                .redacted(reason: .placeholder)
                        }
                    } else if viewModel.statuses.isEmpty && viewModel.account != nil && viewModel.isLoading == false {
                        EmptyStateView(
                            String(localized: "timelines_no_posts_title", table: "Timelines"),
                            systemImage: "text.bubble",
                            description: Text(String(localized: "timelines_no_posts_description", table: "Timelines"))
                        )
                        .padding(.vertical, 30)
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.statuses, id: \.id) { status in
                                Group {
                                    if let item = status.content.links.compactMap(\.neodbItem).first {
                                        Button {
                                            router.navigate(to: .statusDetailWithStatusAndItem(status: status, item: item))
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
                            }
                            
                            if viewModel.hasMore {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .onAppear {
                                        if !viewModel.isLoadingStatuses {
                                            Task {
                                                await viewModel.loadNextPage()
                                            }
                                        }
                                    }
                            }
                        }
                    }
                }
                .scrollAwareTitle(account.displayName ?? "")
                .refreshable {
                    await viewModel.loadAccount(id: id, refresh: true)
                    await viewModel.loadStatuses(refresh: true)
                }
            } else if let user = user {
                ScrollView {
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
            } else if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                EmptyStateView(
                    String(
                        localized: "timelines_profile_not_found_title",
                        table: "Timelines"),
                    systemImage: "person.slash",
                    description: Text(
                        String(
                            localized:
                                "timelines_profile_not_found_description",
                            table: "Timelines")
                    )
                )
                .refreshable {
                    await viewModel.loadAccount(id: id, refresh: true)
                }
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
