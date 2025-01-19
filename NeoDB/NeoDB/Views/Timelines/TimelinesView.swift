//
//  TimelinesView.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 1/7/25.
//

import OSLog
import SwiftUI

@MainActor
class TimelinesViewModel: ObservableObject {
    var accountsManager: AppAccountsManager? {
        didSet {
            if oldValue !== accountsManager {
                statuses = []
            }
        }
    }

    private let cacheService = CacheService()
    private let logger = Logger.home
    private var loadTask: Task<Void, Never>?

    @Published var statuses: [MastodonStatus] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var detailedError: String?
    @Published var isRefreshing = false

    // Pagination
    private var maxId: String?
    private var hasMore = true

    func loadTimeline(refresh: Bool = false) async {
        loadTask?.cancel()

        loadTask = Task {
            guard let accountsManager = accountsManager else {
                logger.debug("No accountsManager available")
                return
            }

            logger.debug(
                "Loading timeline for instance: \(accountsManager.currentAccount.instance)"
            )

            if refresh {
                logger.debug("Refreshing timeline, resetting pagination")
                maxId = nil
                hasMore = true
                if !Task.isCancelled {
                    isRefreshing = true
                }
            } else {
                guard hasMore else {
                    logger.debug("No more content to load")
                    return
                }
                if !Task.isCancelled {
                    isLoading = true
                }
            }

            defer {
                if !Task.isCancelled {
                    isLoading = false
                    isRefreshing = false
                }
            }

            error = nil
            detailedError = nil

            do {
                // Only load from cache if not refreshing and statuses is empty
                if !refresh && statuses.isEmpty,
                   let cached = try? await cacheService.retrieveTimelines(key: accountsManager.currentAccount.id)
                {
                    if !Task.isCancelled {
                        statuses = cached
                        logger.debug(
                            "Loaded \(cached.count) statuses from cache")
                    }
                }

                guard !Task.isCancelled else {
                    logger.debug("Timeline loading cancelled")
                    return
                }

                guard accountsManager.isAuthenticated else {
                    logger.error("User not authenticated")
                    throw NetworkError.unauthorized
                }

                let endpoint = TimelinesEndpoint.pub(
                    sinceId: nil, maxId: maxId, minId: nil, local: true,
                    limit: nil)
                logger.debug(
                    "Fetching timeline with endpoint: \(String(describing: endpoint)), maxId: \(maxId ?? "nil")"
                )

                let newStatuses = try await accountsManager.currentClient.fetch(
                    endpoint, type: [MastodonStatus].self)

                guard !Task.isCancelled else {
                    logger.debug("Timeline loading cancelled after fetch")
                    return
                }

                if refresh {
                    statuses = newStatuses
                } else {
                    statuses.append(contentsOf: newStatuses)
                }

                try? await cacheService.cacheTimelines(statuses, key: accountsManager.currentAccount.id)

                maxId = newStatuses.last?.id
                hasMore = !newStatuses.isEmpty
                logger.debug(
                    "Successfully loaded \(newStatuses.count) statuses")

            } catch {
                if !Task.isCancelled {
                    logger.error(
                        "Failed to load timeline: \(error.localizedDescription)"
                    )
                    self.error = "Failed to load timeline"
                    if let networkError = error as? NetworkError {
                        detailedError = networkError.localizedDescription
                    }
                }
            }
        }

        await loadTask?.value
    }
}

struct TimelinesView: View {
    @StateObject private var viewModel = TimelinesViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if let error = viewModel.error {
                EmptyStateView(
                    "Couldn't Load Timeline",
                    systemImage: "exclamationmark.triangle",
                    description: Text(viewModel.detailedError ?? error)
                )
            } else if viewModel.statuses.isEmpty {
                if viewModel.isLoading || viewModel.isRefreshing {
                    timelineSkeletonContent
                } else {
                    EmptyStateView(
                        "No Posts Yet",
                        systemImage: "text.bubble",
                        description: Text(
                            "Follow some users to see their posts here")
                    )
                }
            } else {
                timelineContent
            }
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.accountsManager = accountsManager
            await viewModel.loadTimeline()
        }
        .refreshable {
            await viewModel.loadTimeline(refresh: true)
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                Task {
                    await viewModel.loadTimeline(refresh: true)
                }
            }
        }
    }

    private var timelineContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.statuses) { status in
                    Button {
                        router.navigate(
                            to: .statusDetailWithStatus(status: status))
                    } label: {
                        StatusView(status: status)
                            .onAppear {
                                if status.id == viewModel.statuses.last?.id {
                                    Task {
                                        await viewModel.loadTimeline()
                                    }
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }

                if viewModel.isLoading && !viewModel.isRefreshing {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
        }
    }

    private var timelineSkeletonContent: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(0..<5, id: \.self) { _ in
                    statusSkeletonView
                }
            }
            .padding()
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
                        .frame(width: 80, height: 14)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 8) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 16)
                }
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 200, height: 16)
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
