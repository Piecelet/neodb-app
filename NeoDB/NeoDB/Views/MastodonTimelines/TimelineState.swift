import Foundation

struct TimelineState: Equatable {
    var statuses: [MastodonStatus] = []
    var isLoading = false
    var isRefreshing = false
    var error: String?
    var detailedError: String?
    
    // Pagination
    var maxId: String?
    var hasMore = true
    
    // Stream management
    var isActive = false
    var isStreamSubscribed = false
    var lastRefreshTime: Date?
    
    static func == (lhs: TimelineState, rhs: TimelineState) -> Bool {
        lhs.statuses.map(\.id) == rhs.statuses.map(\.id) &&
        lhs.isLoading == rhs.isLoading &&
        lhs.isRefreshing == rhs.isRefreshing &&
        lhs.error == rhs.error &&
        lhs.detailedError == rhs.detailedError &&
        lhs.maxId == rhs.maxId &&
        lhs.hasMore == rhs.hasMore &&
        lhs.isActive == rhs.isActive &&
        lhs.isStreamSubscribed == rhs.isStreamSubscribed &&
        lhs.lastRefreshTime == rhs.lastRefreshTime
    }
} 