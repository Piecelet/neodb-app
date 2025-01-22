import Foundation
import OSLog
import Combine

@MainActor
final class TimelineActor: ObservableObject {
    private let logger = Logger.views.timelines
    private let cacheService = CacheService()
    private var streamWatcher: StreamWatcher?
    private var loadTasks: [TimelineType: Task<Void, Never>] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    @Published private(set) var timelineStates: [TimelineType: TimelineState] = [
        .friends: TimelineState(),
        .home: TimelineState(),
        .popular: TimelineState(),
        .fediverse: TimelineState()
    ]
    
    // MARK: - Properties
    var accountsManager: AppAccountsManager? {
        didSet {
            if oldValue !== accountsManager {
                initTimelineStates()
                setupStreamWatcher()
            }
        }
    }
    
    // MARK: - Initialization
    init() {
        setupStreamWatcher()
    }
    
    private func setupStreamWatcher() {
        streamWatcher = StreamWatcher()
        if let streamWatcher = streamWatcher {
            streamWatcher.$latestEvent
                .compactMap { $0 }
                .sink { [weak self] event in
                    guard let self = self else { return }
                    Task { @MainActor in
                        await self.handleStreamEvent(event)
                    }
                }
                .store(in: &cancellables)
        }
    }
    
    // MARK: - State Management
    private func initTimelineStates() {
        timelineStates = [
            .friends: TimelineState(),
            .home: TimelineState(),
            .popular: TimelineState(),
            .fediverse: TimelineState()
        ]
    }
    
    func state(for type: TimelineType) -> TimelineState {
        timelineStates[type] ?? TimelineState()
    }
    
    private func updateState(for type: TimelineType, update: (inout TimelineState) -> Void) {
        var state = timelineStates[type] ?? TimelineState()
        update(&state)
        timelineStates[type] = state
        
        // Update stream watcher subscription if needed
        if state.isActive && !state.isStreamSubscribed {
            subscribeToStream(for: type)
        }
    }
    
    // MARK: - Timeline Loading
    func loadTimeline(type: TimelineType, refresh: Bool = false) async {
        loadTasks[type]?.cancel()
        
        loadTasks[type] = Task {
            guard let accountsManager = accountsManager else {
                logger.debug("No accountsManager available")
                return
            }
            
            // Set timeline as active when loading
            updateState(for: type) { state in
                state.isActive = true
                state.isLoading = true
                if refresh {
                    state.maxId = nil
                    state.isRefreshing = true
                    state.error = nil
                }
            }
            
            defer {
                updateState(for: type) { state in
                    state.isLoading = false
                    state.isRefreshing = false
                }
            }
            
            do {
                // Load from cache first if not refreshing
                if !refresh {
                    if let cached = try? await cacheService.retrieveTimelines(
                        key: "\(accountsManager.currentAccount.id)_\(type.rawValue)")
                    {
                        updateState(for: type) { state in
                            // Only update if we don't have newer data
                            if state.statuses.isEmpty {
                                state.statuses = cached
                                state.lastRefreshTime = Date()
                            }
                        }
                    }
                }
                
                // Fetch from network
                let state = timelineStates[type] ?? TimelineState()
                let endpoint = type.endpoint(maxId: state.maxId)
                
                let newStatuses = try await accountsManager.currentClient.fetch(
                    endpoint, type: [MastodonStatus].self)
                
                updateState(for: type) { state in
                    if refresh {
                        state.statuses = newStatuses
                    } else {
                        // Merge new statuses, avoiding duplicates
                        let existingIds = Set(state.statuses.map(\.id))
                        let uniqueNewStatuses = newStatuses.filter { !existingIds.contains($0.id) }
                        state.statuses.append(contentsOf: uniqueNewStatuses)
                    }
                    state.maxId = newStatuses.last?.id
                    state.hasMore = !newStatuses.isEmpty
                    state.lastRefreshTime = Date()
                    state.error = nil
                }
                
                // Cache only if it's a refresh or first load
                if refresh || state.statuses.isEmpty {
                    try? await cacheService.cacheTimelines(
                        timelineStates[type]?.statuses ?? [],
                        key: "\(accountsManager.currentAccount.id)_\(type.rawValue)")
                }
                
            } catch {
                updateState(for: type) { state in
                    // Only show error if we don't have any existing data
                    if !refresh || state.statuses.isEmpty {
                        state.error = error.localizedDescription
                    }
                }
            }
        }
        
        await loadTasks[type]?.value
    }
    
    // MARK: - Stream Management
    private func subscribeToStream(for type: TimelineType) {
        guard let streamWatcher = streamWatcher else { return }
        
        let stream: StreamWatcher.Stream
        switch type {
        case .friends:
            stream = .home
        case .home:
            stream = .local
        case .popular:
            stream = .trending
        case .fediverse:
            stream = .federated
        }
        
        streamWatcher.watch(streams: [stream])
        
        updateState(for: type) { state in
            state.isStreamSubscribed = true
        }
    }
    
    private func handleStreamEvent(_ event: any StreamEvent) async {
        switch event {
        case let update as StreamEventUpdate:
            await handleStatusUpdate(update.status)
        case let statusUpdate as StreamEventStatusUpdate:
            await handleStatusUpdate(statusUpdate.status)
        case let delete as StreamEventDelete:
            await handleStatusDelete(delete.status)
        default:
            break
        }
    }
    
    private func handleStatusUpdate(_ status: MastodonStatus) async {
        // Determine which timeline type this status belongs to based on visibility and source
        for type in TimelineType.allCases {
            let shouldAdd: Bool
            switch type {
            case .friends:
                shouldAdd = status.visibility == .priv || status.visibility == .direct
            case .home:
                shouldAdd = status.account.acct.contains("@") == false // Local user
            case .popular:
                shouldAdd = false // Popular timeline doesn't get real-time updates
            case .fediverse:
                shouldAdd = status.account.acct.contains("@") // Remote user
            }
            
            if shouldAdd {
                updateState(for: type) { state in
                    // Insert new status at the top if it's not already present
                    if !state.statuses.contains(where: { $0.id == status.id }) {
                        state.statuses.insert(status, at: 0)
                    }
                }
            }
        }
    }
    
    private func handleStatusDelete(_ statusId: String) async {
        for type in TimelineType.allCases {
            updateState(for: type) { state in
                state.statuses.removeAll { $0.id == statusId }
            }
        }
    }
    
    // MARK: - Cleanup
    func cleanup() {
        loadTasks.values.forEach { $0.cancel() }
        loadTasks.removeAll()
        streamWatcher?.stopWatching()
        
        // Mark all timelines as inactive
        for type in TimelineType.allCases {
            updateState(for: type) { state in
                state.isActive = false
                state.isStreamSubscribed = false
            }
        }
    }
}

// MARK: - Helper Extensions
private extension TimelineType {
    func endpoint(maxId: String?) -> TimelinesEndpoint {
        switch self {
        case .friends:
            return .home(sinceId: nil, maxId: maxId, minId: nil)
        case .home:
            return .pub(sinceId: nil, maxId: maxId, minId: nil, local: true, limit: nil)
        case .popular:
            return .trending(maxId: maxId)
        case .fediverse:
            return .pub(sinceId: nil, maxId: maxId, minId: nil, local: false, limit: nil)
        }
    }
} 