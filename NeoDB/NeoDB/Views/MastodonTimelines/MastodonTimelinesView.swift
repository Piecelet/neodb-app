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
    @AppStorage("selectedTimelineType") private var selectedTimelineType: MastodonTimelinesFilter = .local
    
    var body: some View {
        VStack(spacing: 0) {
            TopTabBarView(
                items: MastodonTimelinesFilter.availableTimeline(isAuthenticated: accountsManager.isAuthenticated),
                selection: $selectedTimelineType
            ) { item in item.displayName }
            
            List {
                ForEach(viewModel.statuses, id: \.id) { status in
                    Button {
                        router.navigate(to: .statusDetailWithStatus(status: status))
                    } label: {
                        StatusView(status: status, mode: .timeline)
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                }
                
                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .refreshable {
                await viewModel.loadTimeline(type: selectedTimelineType, refresh: true)
            }
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

