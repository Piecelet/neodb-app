//
//  MastodonTimelinesView.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/7/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import OSLog
import SwiftUI
import SwiftUIIntrospect

fileprivate struct HorizontalDivider: View {
    
    let color: Color
    let height: CGFloat
    
    init(color: Color, height: CGFloat = 0.5) {
        self.color = color
        self.height = height
    }
    
    var body: some View {
        color
            .frame(height: height)
    }
}

struct MastodonTimelinesView: View {
    @StateObject private var viewModel = MastodonTimelinesViewModel()
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @AppStorage("selectedTimelineType") private var selectedTimelineType: MastodonTimelinesFilter = .local
    @Environment(\.colorScheme) private var colorScheme
    
    let statusBarHeight: CGFloat = {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return windowScene.statusBarManager?.statusBarFrame.height ?? 0
        }
        return 0
    }()
    let topTabBarHeight: CGFloat = 32
    let navBarHeight: CGFloat
    let tabBarHeight: CGFloat = 92
    
    init() {
        navBarHeight = UINavigationController().navigationBar.frame.height
    }
    
    var body: some View {
        VStack {
            // Without this, the tab bar will be transparent without any blur
            if #unavailable(iOS 17.0) {
                Text(verbatim: " ").frame(width: 0.01, height: 0.01)
            }
            GeometryReader { geometry in
                TabView(selection: $selectedTimelineType) {
                    ForEach(MastodonTimelinesFilter.availableTimeline(isAuthenticated: accountsManager.isAuthenticated), id: \.self) { type in
                        Group {
                            if #available(iOS 17.0, *) {
                                List {
                                    timelineContent(for: type)
                                }
                                .safeAreaPadding(.top, topTabBarHeight + navBarHeight + statusBarHeight)
                                .safeAreaPadding(.bottom, tabBarHeight)
                            } else {
                                List {
                                    timelineContent(for: type)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .refreshable {
                            await viewModel.loadTimeline(type: type, refresh: true)
                        }
                        .tag(type)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea(edges: .bottom)
        }
        .toolbarBackground(.visible, for: .tabBar)
        .modifier(IgnoreSafeAreaModifier())
        .safeAreaInset(edge: .top) {
            VStack(spacing:0) {
                TopTabBarView(
                    items: MastodonTimelinesFilter.availableTimeline(isAuthenticated: accountsManager.isAuthenticated),
                    selection: $selectedTimelineType
                ) { item in item.displayName }
                    .padding(.bottom, 4)
                HorizontalDivider(color: .grayBackground, height: colorScheme == .dark ? 0.5 : 1)
            }
            .background(Material.bar)
        }
        .safeAreaInset(edge: .bottom) {
            Text(verbatim: " ").frame(width: 0.01, height: 0.01)
        }
        .task {
            viewModel.accountsManager = accountsManager
            await viewModel.loadTimeline(type: selectedTimelineType)
        }
        .onChange(of: selectedTimelineType) { type in
            Task {
                await viewModel.loadTimeline(type: type, refresh: true)
            }
        }
        .onDisappear {
            viewModel.cleanup()
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
    private func timelineContent(for type: MastodonTimelinesFilter, geometry: GeometryProxy? = nil) -> some View {
        let state = viewModel.timelineStates[type] ?? MastodonTimelinesState()
        
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
            if state.isLoading || state.isRefreshing {
                timelineSkeletonContent
            } else {
                EmptyStateView(
                    String(localized: "timelines_no_posts_title", table: "Timelines"),
                    systemImage: "text.bubble",
                    description: Text(String(localized: "timelines_no_posts_description", table: "Timelines"))
                )
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .padding(.top, (geometry?.size.height ?? 0) / 4)
            }
        } else {
            ForEach(state.statuses, id: \.id) { status in
                Group {
                    Button {
                        router.navigate(to: .statusDetailWithStatus(status: status))
                    } label: {
                        StatusView(status: status, mode: .timeline)
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        if status == state.statuses.last && state.hasMore {
                            Task {
                                await viewModel.loadTimeline(type: type)
                            }
                        }
                    }
                }
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
        .padding()
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

fileprivate struct IgnoreSafeAreaModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.ignoresSafeArea(edges: .top)
        } else {
            content
        }
    }
}
