//
//  MastodonTimelinesView.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/7/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import OSLog
import SwiftUI

struct MastodonTimelinesView: View {
    @StateObject private var viewModel = MastodonTimelinesViewModel()
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @AppStorage("selectedTimelineType") private var selectedTimelineType:
        MastodonTimelinesFilter = .local

    var body: some View {
        VStack {
            // Without this, the tab bar will be transparent without any blur
            Text(verbatim: " ").frame(width: 0.01, height: 0.01)
            GeometryReader { geometry in
                TabView(selection: $selectedTimelineType) {
                    ForEach(
                        MastodonTimelinesFilter.availableTimeline(
                            isAuthenticated: accountsManager.isAuthenticated),
                        id: \.self
                    ) { type in
                        Group {
                            List {
                                timelineContent(
                                    for: type, geometry: geometry)
                            }
                        }
                        .ignoresSafeArea(edges: .bottom)
                        .listStyle(.plain)
                        .refreshable {
                            await viewModel.loadTimeline(
                                type: type, refresh: true)
                        }
                        .tag(type)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .toolbarBackground(.visible, for: .tabBar)
        .safeAreaInset(edge: .top) {
            VStack(spacing: 0) {
                TopTabBarView(
                    items: MastodonTimelinesFilter.availableTimeline(
                        isAuthenticated: accountsManager.isAuthenticated),
                    selection: $selectedTimelineType
                ) { item in item.displayName }
                .padding(.bottom, -12)
            }
        }
        .task {
            viewModel.accountsManager = accountsManager
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                Task {
                    await viewModel.loadTimeline(type: selectedTimelineType)
                }
            }
        }
        .onChange(of: selectedTimelineType) { type in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                Task {
                    await viewModel.loadTimeline(type: type, refresh: true)
                }
            }
        }
        .onDisappear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                viewModel.cleanup()
            }
        }
        .navigationTitle(
            String(localized: "timelines_title", table: "Timelines")
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Text(verbatim: "Piecelet")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 2)
            }
            ToolbarItem(placement: .principal) {
                Text(verbatim: "Piecelet")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 2)
                    .hidden()
            }
        }
        .enableInjection()
    }

    @ViewBuilder
    private func timelineContent(
        for type: MastodonTimelinesFilter, geometry: GeometryProxy? = nil
    ) -> some View {
        let state = viewModel.timelineStates[type] ?? MastodonTimelinesState()

        Group {
            if let error = state.error {
                EmptyStateView(
                    String(localized: "timelines_error_title", table: "Timelines"),
                    systemImage: "exclamationmark.triangle",
                    description: Text(error.localizedDescription)
                )
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .padding(.top, (geometry?.size.height ?? 0) / 4)
            } else if state.statuses.isEmpty {
                if state.isLoading || state.isRefreshing || !state.isInited {
                    ForEach(
                        Array(MastodonStatus.placeholders().enumerated()), id: \.offset
                    ) { index, status in
                        StatusView(
                            status: status, mode: .timeline
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .alignmentGuide(.listRowSeparatorLeading) { _ in
                            return 4
                        }
                        .redacted(reason: .placeholder)
                    }
                } else {
                    EmptyStateView(
                        String(
                            localized: "timelines_no_posts_title",
                            table: "Timelines"),
                        systemImage: "text.bubble",
                        description: Text(
                            String(
                                localized: "timelines_no_posts_description",
                                table: "Timelines"))
                    )
                    .id("status_empty")
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .padding(.top, (geometry?.size.height ?? 0) / 4)
                }
            } else {
                ForEach(state.statuses, id: \.id) { status in
                    Group {
                        if let item = status.content.links.compactMap(
                            \.neodbItem
                        ).first {
                            Button {
                                router.navigate(
                                    to: .statusDetailWithStatusAndItem(
                                        status: status, item: item))
                            } label: {
                                StatusView(status: status, mode: .timelineWithItem)
                            }
                        } else {
                            Button {
                                router.navigate(
                                    to: .statusDetailWithStatus(status: status))
                            } label: {
                                StatusView(status: status, mode: .timeline)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .task {
                        if status == state.statuses.last && state.hasMore {
                            Task {
                                await viewModel.loadTimeline(type: type)
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                    .alignmentGuide(.listRowSeparatorLeading) { _ in
                        return 4
                    }
                    .listRowInsets(EdgeInsets())
                }
                
                if state.isLoading && !state.isRefreshing {
                    HStack {
                        Spacer()
                        ProgressView()
                            .id(UUID())
                        Spacer()
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .padding()
                }
            }
        }
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}

#Preview {
    NavigationStack {
        MastodonTimelinesView()
            .environmentObject(Router())
            .environmentObject(AppAccountsManager())
    }
}
