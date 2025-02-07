import Foundation
import OSLog
import Combine

//@MainActor
//final class TimelineActor: ObservableObject {
//    private let logger = Logger.views.timelines
//    private let cacheService = CacheService()
//    private var loadTasks: [TimelineType: Task<Void, Never>] = [:]
//    private var cancellables = Set<AnyCancellable>()
//    
//    // MARK: - Published Properties
//    @Published private(set) var timelineStates: [TimelineType: TimelineState] = [
//        .friends: TimelineState(),
//        .home: TimelineState(),
//        .popular: TimelineState(),
//        .fediverse: TimelineState()
//    ]
//    
//    // MARK: - Properties
//    var accountsManager: AppAccountsManager? {
//        didSet {
//            if oldValue !== accountsManager {
//                initTimelineStates()
//            }
//        }
//    }
//    
//    // MARK: - State Management
//    private func initTimelineStates() {
//        timelineStates = [
//            .friends: TimelineState(),
//            .home: TimelineState(),
//            .popular: TimelineState(),
//            .fediverse: TimelineState()
//        ]
//    }
//    
//    func state(for type: TimelineType) -> TimelineState {
//        timelineStates[type] ?? TimelineState()
//    }
//    
//    private func updateState(for type: TimelineType, update: (inout TimelineState) -> Void) {
//        var state = timelineStates[type] ?? TimelineState()
//        update(&state)
//        timelineStates[type] = state
//    
//    }
//    
//    // MARK: - Timeline Loading
//    func loadTimeline(type: TimelineType, refresh: Bool = false) async {
//        loadTasks[type]?.cancel()
//        
//        loadTasks[type] = Task {
//            guard let accountsManager = accountsManager else {
//                logger.debug("No accountsManager available")
//                return
//            }
//            
//            // Set timeline as active when loading
//            updateState(for: type) { state in
//                state.isActive = true
//                state.isLoading = true
//                if refresh {
//                    state.maxId = nil
//                    state.isRefreshing = true
//                    state.error = nil
//                }
//            }
//            
//            defer {
//                updateState(for: type) { state in
//                    state.isLoading = false
//                    state.isRefreshing = false
//                }
//            }
//            
//            do {
//                // Load from cache first if not refreshing
//                if !refresh {
//                    if let cached = try? await cacheService.retrieveTimelines(
//                        key: "\(accountsManager.currentAccount.id)_\(type.rawValue)")
//                    {
//                        updateState(for: type) { state in
//                            // Only update if we don't have newer data
//                            if state.statuses.isEmpty {
//                                state.statuses = cached
//                                state.lastRefreshTime = Date()
//                            }
//                        }
//                    }
//                }
//                
//                // Fetch from network
//                let state = timelineStates[type] ?? TimelineState()
//                let endpoint = type.endpoint(maxId: state.maxId)
//                
//                let newStatuses = try await accountsManager.currentClient.fetch(
//                    endpoint, type: [MastodonStatus].self)
//                
//                updateState(for: type) { state in
//                    if refresh {
//                        state.statuses = newStatuses
//                    } else {
//                        // Merge new statuses, avoiding duplicates
//                        let existingIds = Set(state.statuses.map(\.id))
//                        let uniqueNewStatuses = newStatuses.filter { !existingIds.contains($0.id) }
//                        state.statuses.append(contentsOf: uniqueNewStatuses)
//                    }
//                    state.maxId = newStatuses.last?.id
//                    state.hasMore = !newStatuses.isEmpty
//                    state.lastRefreshTime = Date()
//                    state.error = nil
//                }
//                
//                // Cache only if it's a refresh or first load
//                if refresh || state.statuses.isEmpty {
//                    try? await cacheService.cacheTimelines(
//                        timelineStates[type]?.statuses ?? [],
//                        key: "\(accountsManager.currentAccount.id)_\(type.rawValue)")
//                }
//                
//            } catch {
//                updateState(for: type) { state in
//                    // Only show error if:
//                    // 1. It's a refresh and we have no data
//                    // 2. It's an initial load (no existing data)
//                    if (refresh && state.statuses.isEmpty) || (!refresh && state.statuses.isEmpty) {
//                        state.error = error.localizedDescription
//                        logger.error("Timeline load error: \(error.localizedDescription)")
//                    } else {
//                        // Log but don't display pagination errors
//                        logger.debug("Pagination error suppressed: \(error.localizedDescription)")
//                    }
//                }
//            }
//        }
//        
//        await loadTasks[type]?.value
//    }
//    
//    private func handleStatusUpdate(_ status: MastodonStatus) async {
//        // Determine which timeline type this status belongs to based on visibility and source
//        for type in TimelineType.allCases {
//            let shouldAdd: Bool
//            switch type {
//            case .friends:
//                shouldAdd = status.visibility == .priv || status.visibility == .direct
//            case .home:
//                shouldAdd = status.account.acct.contains("@") == false // Local user
//            case .popular:
//                shouldAdd = false // Popular timeline doesn't get real-time updates
//            case .fediverse:
//                shouldAdd = status.account.acct.contains("@") // Remote user
//            }
//            
//            if shouldAdd {
//                updateState(for: type) { state in
//                    // Insert new status at the top if it's not already present
//                    if !state.statuses.contains(where: { $0.id == status.id }) {
//                        state.statuses.insert(status, at: 0)
//                    }
//                }
//            }
//        }
//    }
//    
//    private func handleStatusDelete(_ statusId: String) async {
//        for type in TimelineType.allCases {
//            updateState(for: type) { state in
//                state.statuses.removeAll { $0.id == statusId }
//            }
//        }
//    }
//    
//    // MARK: - Cleanup
//    func cleanup() {
//        loadTasks.values.forEach { $0.cancel() }
//        loadTasks.removeAll()
//        
//        // Mark all timelines as inactive
//        for type in TimelineType.allCases {
//            updateState(for: type) { state in
//                state.isActive = false
//            }
//        }
//    }
//}
//
//// MARK: - Helper Extensions
//private extension TimelineType {
//    func endpoint(maxId: String?) -> TimelinesEndpoint {
//        switch self {
//        case .friends:
//            return .home(sinceId: nil, maxId: maxId, minId: nil, limit: nil)
//        case .home:
//            return .pub(sinceId: nil, maxId: maxId, minId: nil, local: true, limit: nil)
//        case .popular:
//            return .trending(maxId: maxId)
//        case .fediverse:
//            return .pub(sinceId: nil, maxId: maxId, minId: nil, local: false, limit: nil)
//        }
//    }
//} 
