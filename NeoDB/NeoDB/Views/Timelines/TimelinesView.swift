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
            
            let cacheKey = "\(accountsManager.currentAccount.instance)_timeline"
            logger.debug("Using cache key: \(cacheKey)")
            
            do {
                // Only load from cache if not refreshing and statuses is empty
                if !refresh && statuses.isEmpty,
                    let cached = try? await cacheService.retrieve(
                        forKey: cacheKey, type: [MastodonStatus].self)
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
                    sinceId: nil, maxId: maxId, minId: nil, local: true, limit: nil)
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
                
                try? await cacheService.cache(
                    statuses, forKey: cacheKey, type: [MastodonStatus].self)
                
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

    var body: some View {
        Group {
            if let error = viewModel.error {
                EmptyStateView(
                    "Couldn't Load Timeline",
                    systemImage: "exclamationmark.triangle",
                    description: Text(viewModel.detailedError ?? error)
                )
                .refreshable {
                    await viewModel.loadTimeline(refresh: true)
                }
            } else if viewModel.statuses.isEmpty && !viewModel.isLoading && !viewModel.isRefreshing {
                EmptyStateView(
                    "No Posts Yet",
                    systemImage: "text.bubble",
                    description: Text("Follow some users to see their posts here")
                )
                .refreshable {
                    await viewModel.loadTimeline(refresh: true)
                }
            } else {
                timelineContent
            }
        }
        .navigationTitle("Home")
        .task {
            viewModel.accountsManager = accountsManager
            await viewModel.loadTimeline()
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
        .refreshable {
            await viewModel.loadTimeline(refresh: true)
        }
    }
}
