//
//  TimelinesView.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 1/7/25.
//

import OSLog
import SwiftUI

enum TimelineType: String, CaseIterable {
    case friends
    case home
    case popular
    case fediverse

    var displayName: String {
        switch self {
        case .friends:
            return String(
                localized: "timelines_type_friends", table: "Timelines")
        case .home:
            return String(localized: "timelines_type_home", table: "Timelines")
        case .popular:
            return String(
                localized: "timelines_type_popular", table: "Timelines")
        case .fediverse:
            return String(
                localized: "timelines_type_fediverse", table: "Timelines")
        }
    }
}


struct TimelinesView: View {
    @StateObject private var actor = TimelineActor()
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("selectedTimelineType") private var selectedTimelineType:
        TimelineType = .home

    var body: some View {
        VStack(spacing: 0) {
            TopTabBarView(
                items: TimelineType.allCases,
                selection: $selectedTimelineType
            ) { $0.displayName }

            TabView(selection: $selectedTimelineType) {
                ForEach(TimelineType.allCases, id: \.self) { type in
                    List {
                        timelineContent(for: type)
                            .refreshable {
                                await actor.loadTimeline(
                                    type: type, refresh: true)
                            }
                            .tag(type)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
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
        .task {
            actor.accountsManager = accountsManager
            await actor.loadTimeline(type: selectedTimelineType)
        }
        .onChange(of: selectedTimelineType) { type in
            Task {
                await actor.loadTimeline(type: type)
            }
        }
        .onDisappear {
            actor.cleanup()
        }
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif

    @ViewBuilder
    private func timelineContent(for type: TimelineType) -> some View {
        let state = actor.state(for: type)

        if let error = state.error {
            EmptyStateView(
                String(localized: "timelines_error_title", table: "Timelines"),
                systemImage: "exclamationmark.triangle",
                description: Text(error)
            )
        } else if state.statuses.isEmpty {
            if state.isLoading || state.isRefreshing {
                timelineSkeletonContent
            } else {
                EmptyStateView(
                    String(
                        localized: "timelines_no_posts_title",
                        table: "Timelines"),
                    systemImage: "text.bubble",
                    description: Text(
                        String(
                            localized: "timelines_no_posts_description",
                            table: "Timelines")
                    )
                )
            }
        } else {
            ForEach(Array(state.statuses.enumerated()), id: \.element.id) {
                index, status in
                Button {
                    router.navigate(
                        to: .statusDetailWithStatus(status: status))
                } label: {
                    StatusView(status: status, mode: .timeline)
                        .id(index)
                        .task {
                            if index >= state.statuses.count - 3
                                && state.hasMore
                            {
                                await actor.loadTimeline(type: type)
                            }
                        }
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)

                if status.id != state.statuses.last?.id {
                    Divider()
                        .padding(.horizontal)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                }
            }

            if state.isLoading && !state.isRefreshing {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .padding()
            }
        }
    }

    private let skeletonCount = 5

    private var timelineSkeletonContent: some View {
        ForEach(0..<skeletonCount, id: \.self) { _ in
            statusSkeletonView
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
        }
    }

    private var statusSkeletonView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Avatar and name
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 120, height: 16)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 80, height: 12)
                }
            }

            // Content placeholder
            VStack(alignment: .leading, spacing: 4) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        TimelinesView()
            .environmentObject(Router())
            .environmentObject(AppAccountsManager())
    }
}
