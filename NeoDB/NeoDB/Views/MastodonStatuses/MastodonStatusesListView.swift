//
//  MastodonStatusesListView.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/7/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI

@MainActor
struct MastodonStatusesListView<Fetcher>: View where Fetcher: MastodonStatusesFetcher {
    @State private var fetcher: Fetcher
    // Whether this status is on a remote local timeline (many actions are unavailable if so)
    private let isRemote: Bool
    private let router: Router
    private let accountsManager: AppAccountsManager

    init(
        fetcher: Fetcher,
        accountsManager: AppAccountsManager,
        router: Router,
        isRemote: Bool = false
    ) {
        _fetcher = .init(initialValue: fetcher)
        self.isRemote = isRemote
        self.accountsManager = accountsManager
        self.router = router
    }

    var body: some View {
        switch fetcher.statusesState {
        case .loading:
            ForEach(MastodonStatus.placeholders()) { status in
                MastodonStatusRowView(
                    viewModel: .init(
                        status: status, accountsManager: accountsManager, router: router),
                    context: .timeline
                )
                .allowsHitTesting(false)
            }
        case .error:
//            ErrorView(
//                title: "status.error.title",
//                message: "status.error.loading.message",
//                buttonTitle: "action.retry"
//            ) {
//                await fetcher.fetchNewestStatuses(pullToRefresh: false)
//            }
//            .listRowBackground(theme.primaryBackgroundColor)
//            .listRowSeparator(.hidden)
            Text("Error")

        case let .display(statuses, nextPageState):
            ForEach(statuses) { status in
                MastodonStatusRowView(
                    viewModel: MastodonStatusRowViewModel(
                        status: status,
                        accountsManager: accountsManager,
                        router: router,
                        isRemote: isRemote),
                    context: .timeline
                )
                .onAppear {
                    fetcher.statusDidAppear(status: status)
                }
                .onDisappear {
                    fetcher.statusDidDisappear(status: status)
                }
            }
            switch nextPageState {
            case .hasNextPage:
                EmptyView()
                .task {
                    try await fetcher.fetchNextPage()
                }
                .padding(.horizontal, .layoutPadding)

            case .none:
                EmptyView()
            }
        }
    }
}
