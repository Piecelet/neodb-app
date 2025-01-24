//
//  ProfileView.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

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
                        AsyncImage(url: account.header) { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(.quaternary)
                        }
                        .frame(height: 200)
                        .clipped()

                        // Avatar and Stats
                        HStack(alignment: .bottom) {
                            AsyncImage(url: account.avatar) { image in
                                image.resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle()
                                    .fill(.quaternary)
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(.quaternary, lineWidth: 1))
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
                                        table: "Timelines"), account.createdAt.formatted)
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                        }
                        .padding(.horizontal)
                    }
                }
                .refreshable {
                    await viewModel.loadAccount(id: id, refresh: true)
                }
            } else if let user = user {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Avatar
                        HStack(alignment: .center) {
                            AsyncImage(url: user.avatar) { image in
                                image.resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle()
                                    .fill(.quaternary)
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(.quaternary, lineWidth: 1))
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
