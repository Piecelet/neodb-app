//
//  MastodonStatusView.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import SwiftUI

struct MastodonStatusView: View {
    let id: String
    let status: MastodonStatus?
    
    @StateObject private var viewModel = MastodonStatusViewModel()
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @EnvironmentObject private var router: Router
    
    init(id: String, status: MastodonStatus? = nil) {
        self.id = id
        self.status = status
    }
    
    var body: some View {
        Group {
            if let error = viewModel.error {
                EmptyStateView(
                    "Couldn't Load Status",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error.localizedDescription)
                )
                .refreshable {
                    await viewModel.loadStatus(id: id, refresh: true)
                }
            } else if let status = status ?? viewModel.status {
                statusContent(status)
            } else if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                EmptyStateView(
                    "Status Not Found",
                    systemImage: "text.bubble",
                    description: Text("The status you're looking for doesn't exist or has been deleted.")
                )
                .refreshable {
                    await viewModel.loadStatus(id: id, refresh: true)
                }
            }
        }
        .navigationTitle("Status")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.accountsManager = accountsManager
            if status == nil {
                await viewModel.loadStatus(id: id)
            }
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
    
    private func statusContent(_ status: MastodonStatus) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // Status Content
                StatusView(status: status)
                
                Divider()
                
                // Stats
                HStack(spacing: 16) {
                    statsButton(
                        count: status.repliesCount,
                        icon: "bubble.right",
                        label: "Replies"
                    )
                    statsButton(
                        count: status.reblogsCount,
                        icon: "arrow.2.squarepath",
                        label: "Reblogs"
                    )
                    statsButton(
                        count: status.favouritesCount,
                        icon: "star",
                        label: "Favorites"
                    )
                }
                .padding()
                
                Divider()
                
                // Additional Info
                VStack(alignment: .leading, spacing: 12) {
                    if let application = status.application {
                        infoRow(title: "Posted via", content: application.name)
                    }
                    
                    infoRow(title: "Visibility", content: status.visibility.rawValue.capitalized)
                    
                    if let url = status.url {
                        Link(destination: url) {
                            HStack {
                                Text("View Original")
                                Image(systemName: "arrow.up.right")
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .refreshable {
            await viewModel.loadStatus(id: id, refresh: true)
        }
    }
    
    private func statsButton(count: Int, icon: String, label: String) -> some View {
        Button {
            // TODO: Handle stats button tap
        } label: {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: icon)
                    Text("\(count)")
                }
                .font(.subheadline)
                
                Text(label)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
    }
    
    private func infoRow(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(content)
                .font(.subheadline)
        }
    }
}

#Preview {
    NavigationStack {
        MastodonStatusView(id: "1", status: .placeholder())
            .environmentObject(AppAccountsManager())
            .environmentObject(Router())
    }
}

