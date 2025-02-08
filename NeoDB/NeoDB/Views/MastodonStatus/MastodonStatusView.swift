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
    let item: (any ItemProtocol)?
    @StateObject private var viewModel = MastodonStatusViewModel()
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @EnvironmentObject private var router: Router
    
    init(id: String, status: MastodonStatus? = nil, item: (any ItemProtocol)? = nil) {
        self.id = id
        self.status = status
        self.item = item
    }
    
    var body: some View {
        Group {
            if let error = viewModel.error {
                EmptyStateView(
                    String(localized: "timelines_status_error_title", table: "Timelines"),
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
                    String(localized: "timelines_status_not_found_title", table: "Timelines"),
                    systemImage: "text.bubble",
                    description: Text("timelines_status_not_found_description", tableName: "Timelines")
                )
                .refreshable {
                    await viewModel.loadStatus(id: id, refresh: true)
                }
            }
        }
        .navigationTitle(item?.title ?? String(localized: "timelines_status_title", table: "Timelines"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.accountsManager = accountsManager
            if status == nil {
                await viewModel.loadStatus(id: id)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let url = status?.url {
                    ShareLink(item: URL(string: url)!)
                        .foregroundStyle(.primary)
                }
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
    
    private func statusContent(_ status: MastodonStatus) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // Status Content
                StatusView(status: status, mode: .detail)
                
                Divider()
                
                // Additional Info
                HStack(alignment: .bottom, spacing: 12) {
                    if let application = status.application {
                        infoRow(
                            title: String(localized: "timelines_status_posted_via", table: "Timelines"),
                            content: application.name
                        )
                        Spacer()
                    }
                    
                    infoRow(
                        title: String(localized: "timelines_status_visibility", table: "Timelines"),
                        content: status.visibility.displayName
                    )
                    
                    if let url = status.url {
                        Spacer()
                        Link(destination: URL(string:url)!) {
                            HStack {
                                VStack(alignment: .trailing) {
                                    Text("timelines_status_browser_button", tableName: "Timelines")
                                        .font(.caption)
                                    Text("timelines_status_comments_button", tableName: "Timelines")
                                        .font(.subheadline)
                                }
                                Image(systemName: "arrow.up.right")
                            }
                        }
                    }
                }
                .padding()
                .padding(.horizontal)
            }
        }
        .refreshable {
            await viewModel.loadStatus(id: id, refresh: true)
        }
        .enableInjection()
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

