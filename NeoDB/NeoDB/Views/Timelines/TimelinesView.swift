//
//  TimelinesView.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 1/7/25.
//

import OSLog
import SwiftUI

enum TimelineType: String, CaseIterable {
    case home = "Home"
    case local = "Local"
    case federated = "Federated"
}

struct TimelineState {
    var statuses: [MastodonStatus] = []
    var isLoading = false
    var isRefreshing = false
    var error: String?
    var detailedError: String?
    var maxId: String?
    var hasMore = true
}

@MainActor
class TimelinesViewModel: ObservableObject {
    // MARK: - Dependencies
    private let logger = Logger.home
    private let cacheService = CacheService()
    private var loadTasks: [TimelineType: Task<Void, Never>] = [:]

    // MARK: - Published Properties
    @Published var selectedTimelineType: TimelineType = .home
    @Published private(set) var timelineStates: [TimelineType: TimelineState] =
        [
            .home: TimelineState(),
            .local: TimelineState(),
            .federated: TimelineState(),
        ]

    // MARK: - Public Properties
    var accountsManager: AppAccountsManager? {
        didSet {
            if oldValue !== accountsManager {
                initTimelineStates()
            }
        }
    }

    // MARK: - Computed Properties
    var currentTimelineState: TimelineState {
        timelineStates[selectedTimelineType] ?? TimelineState()
    }

    func initTimelineStates() {
        timelineStates = [
            .home: TimelineState(),
            .local: TimelineState(),
            .federated: TimelineState(),
        ]
    }

    // MARK: - Public Methods
    func loadTimeline(type: TimelineType, refresh: Bool = false) async {
        loadTasks[type]?.cancel()

        loadTasks[type] = Task {
            guard let accountsManager = accountsManager else {
                logger.debug("No accountsManager available")
                return
            }

            logger.debug(
                "Loading timeline for instance: \(accountsManager.currentAccount.instance)"
            )

            updateLoadingState(type: type, refresh: refresh)

            defer {
                if !Task.isCancelled {
                    updateTimelineState(type: type) { state in
                        state.isLoading = false
                        state.isRefreshing = false
                    }
                }
            }

            do {
                // Only load from cache if not refreshing and timeline is empty
                if !refresh && currentTimelineState.statuses.isEmpty,
                    let cached = try? await cacheService.retrieveTimelines(
                        key:
                            "\(accountsManager.currentAccount.id)_\(type.rawValue)"
                    )
                {
                    if !Task.isCancelled {
                        updateTimelineState(type: type) { state in
                            state.statuses = cached
                        }
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

                let endpoint: TimelinesEndpoint
                let state = timelineStates[type] ?? TimelineState()

                switch type {
                case .home:
                    endpoint = .home(
                        sinceId: nil, maxId: state.maxId, minId: nil)
                case .local:
                    endpoint = .pub(
                        sinceId: nil, maxId: state.maxId, minId: nil,
                        local: true, limit: nil)
                case .federated:
                    endpoint = .pub(
                        sinceId: nil, maxId: state.maxId, minId: nil,
                        local: false, limit: nil)
                }

                logger.debug(
                    "Fetching timeline with endpoint: \(String(describing: endpoint)), maxId: \(state.maxId ?? "nil")"
                )

                let newStatuses = try await accountsManager.currentClient.fetch(
                    endpoint, type: [MastodonStatus].self)

                guard !Task.isCancelled else {
                    logger.debug("Timeline loading cancelled after fetch")
                    return
                }

                updateTimelineState(type: type) { state in
                    if refresh {
                        state.statuses = newStatuses
                    } else {
                        state.statuses.append(contentsOf: newStatuses)
                    }
                    state.maxId = newStatuses.last?.id
                    state.hasMore = !newStatuses.isEmpty
                }

                try? await cacheService.cacheTimelines(
                    timelineStates[type]?.statuses ?? [],
                    key: "\(accountsManager.currentAccount.id)_\(type.rawValue)"
                )

                logger.debug(
                    "Successfully loaded \(newStatuses.count) statuses")

            } catch {
                if !Task.isCancelled {
                    logger.error(
                        "Failed to load timeline: \(error.localizedDescription)"
                    )
                    updateTimelineState(type: type) { state in
                        state.error = "Failed to load timeline"
                        if let networkError = error as? NetworkError {
                            state.detailedError =
                                networkError.localizedDescription
                        }
                    }
                }
            }
        }

        await loadTasks[type]?.value
    }

    func loadAllTimelines(refresh: Bool = false) {
        Task {
            loadTasks.values.forEach { $0.cancel() }
            loadTasks.removeAll()

            // Load selected timeline first
            await loadTimeline(type: selectedTimelineType, refresh: refresh)

            // Then load others in parallel
            await withTaskGroup(of: Void.self) { group in
                for type in TimelineType.allCases
                where type != selectedTimelineType {
                    group.addTask {
                        await self.loadTimeline(type: type, refresh: refresh)
                    }
                }
            }
        }
    }

    func cleanup() {
        loadTasks.values.forEach { $0.cancel() }
        loadTasks.removeAll()
    }

    // MARK: - Private Methods
    private func updateTimelineState(
        type: TimelineType, update: (inout TimelineState) -> Void
    ) {
        var state = timelineStates[type] ?? TimelineState()
        update(&state)
        timelineStates[type] = state
    }

    private func updateLoadingState(type: TimelineType, refresh: Bool) {
        if !Task.isCancelled {
            updateTimelineState(type: type) { state in
                if refresh {
                    state.maxId = nil
                    state.hasMore = true
                    state.isRefreshing = true
                } else {
                    state.isLoading = true
                }
            }
        }
    }
}

struct TimelinesView: View {
    @StateObject private var viewModel = TimelinesViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("selectedTimelineType") private var selectedTimelineType:
        TimelineType = .home
    {
        didSet {
            viewModel.selectedTimelineType = selectedTimelineType
        }
    }

    var body: some View {
        VStack(spacing: 0) {

            TabView(selection: $selectedTimelineType) {
                ForEach(TimelineType.allCases, id: \.self) { type in
                    timelineContent(for: type)
                        .refreshable {
                            await viewModel.loadTimeline(
                                type: type, refresh: true)
                        }
                        .tag(type)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle("Timeline")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .top) {
            TopTabBarView(
                items: TimelineType.allCases,
                selection: $selectedTimelineType
            ) { $0.rawValue }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Text("Timeline")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 3)
            }
            ToolbarItem(placement: .principal) {
                Text("Timeline")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 3)
                    .hidden()
            }
        }
        .task {
            viewModel.accountsManager = accountsManager
            viewModel.selectedTimelineType = selectedTimelineType
            viewModel.loadAllTimelines()
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif

    @ViewBuilder
    private func timelineContent(for type: TimelineType) -> some View {
        let state = viewModel.timelineStates[type] ?? TimelineState()

        if let error = state.error {
            EmptyStateView(
                "Couldn't Load Timeline",
                systemImage: "exclamationmark.triangle",
                description: Text(state.detailedError ?? error)
            )
        } else if state.statuses.isEmpty {
            if state.isLoading || state.isRefreshing {
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
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(
                        Array(state.statuses.enumerated()), id: \.element.id
                    ) { index, status in
                        VStack(spacing: 0) {
                            Button {
                                router.navigate(
                                    to: .statusDetailWithStatus(status: status))
                            } label: {
                                StatusView(status: status)
                                    .id(index)
                                    .task {
                                        if index >= state.statuses.count - 3
                                            && state.hasMore
                                        {
                                            await viewModel.loadTimeline(
                                                type: type)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)

                            if status.id != state.statuses.last?.id {
                                Divider()
                                    .padding(.horizontal)
                            }
                        }
                    }

                    if state.isLoading && !state.isRefreshing {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
            }
        }
    }

    private let skeletonCount = 5

    private var timelineSkeletonContent: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(0..<skeletonCount, id: \.self) { _ in
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
