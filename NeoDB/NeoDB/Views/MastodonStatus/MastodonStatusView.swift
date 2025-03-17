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
                List {
                    // Status Content Section
                    Section {
                        StatusView(status: status, mode: item != nil ? .detailWithItem : .detail)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        
                        if let item = item {
                            StatusItemView(item: item, mode: .indicator)
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                        
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
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    
                    // Replies Section
                    Section {
                        if viewModel.isLoadingReplies && viewModel.replies.isEmpty {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        } else if viewModel.replies.isEmpty {
                            Text(String(localized: "replies_no_replies_description", defaultValue: "No replies", table: "Timelines"))
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .padding(.vertical, 30)
                        } else {
                            ForEach(viewModel.replies, id: \.id) { reply in
                                Group {
                                    if let item = reply.content.links.compactMap(\.neodbItem).first {
                                        Button {
                                            router.navigate(to: .statusDetailWithStatusAndItem(status: reply, item: item))
                                        } label: {
                                            StatusView(status: reply, mode: .timelineWithItem)
                                        }
                                    } else {
                                        Button {
                                            router.navigate(to: .statusDetailWithStatus(status: reply))
                                        } label: {
                                            StatusView(status: reply, mode: .timeline)
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
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .scrollIndicators(.automatic)
                .refreshable {
                    await viewModel.loadStatus(id: id, refresh: true)
                    await viewModel.loadReplies(refresh: true)
                }
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
        .navigationTitle(String(localized: "timelines_status_title", table: "Timelines"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.accountsManager = accountsManager
                await viewModel.loadStatus(id: id)
            TelemetryService.shared.trackMastodonStatusDetailView()
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

