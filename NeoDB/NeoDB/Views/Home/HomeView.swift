import SwiftUI
import OSLog

@MainActor
class HomeViewModel: ObservableObject {
    private let timelineService: TimelineService
    private let logger = Logger(subsystem: "app.neodb", category: "HomeViewModel")
    
    @Published var statuses: [Status] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var detailedError: String?
    
    // Pagination
    private var maxId: String?
    private var hasMore = true
    
    init(timelineService: TimelineService) {
        self.timelineService = timelineService
    }
    
    func loadTimeline(refresh: Bool = false) async {
        if refresh {
            maxId = nil
            hasMore = true
        }
        
        guard !isLoading, hasMore else { return }
        
        isLoading = true
        error = nil
        detailedError = nil
        
        do {
            let newStatuses = try await timelineService.getTimeline(maxId: maxId)
            if refresh {
                statuses = newStatuses
            } else {
                statuses.append(contentsOf: newStatuses)
            }
            maxId = newStatuses.last?.id
            hasMore = !newStatuses.isEmpty
            logger.debug("Successfully loaded \(newStatuses.count) statuses")
        } catch {
            logger.error("Failed to load timeline: \(error.localizedDescription)")
            self.error = "Failed to load timeline"
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .dataCorrupted(let context):
                    detailedError = "Data corrupted: \(context.debugDescription)"
                case .keyNotFound(let key, let context):
                    detailedError = "Key not found: \(key.stringValue) in \(context.debugDescription)"
                case .typeMismatch(let type, let context):
                    detailedError = "Type mismatch: expected \(type) at \(context.debugDescription)"
                case .valueNotFound(let type, let context):
                    detailedError = "Value not found: expected \(type) at \(context.debugDescription)"
                @unknown default:
                    detailedError = "Unknown decoding error: \(decodingError)"
                }
            } else {
                detailedError = error.localizedDescription
            }
        }
        
        isLoading = false
    }
}

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    init(authService: AuthService) {
        let timelineService = TimelineService(authService: authService)
        _viewModel = StateObject(wrappedValue: HomeViewModel(timelineService: timelineService))
    }
    
    var body: some View {
        Group {
            if let error = viewModel.error {
                EmptyStateView(
                    "Couldn't Load Timeline",
                    systemImage: "exclamationmark.triangle",
                    description: Text(viewModel.detailedError ?? error)
                )
            } else if viewModel.statuses.isEmpty && !viewModel.isLoading {
                EmptyStateView(
                    "No Posts Yet",
                    systemImage: "text.bubble",
                    description: Text("Follow some users to see their posts here")
                )
            } else {
                timelineContent
            }
        }
        .navigationTitle("Home")
        .task {
            await viewModel.loadTimeline()
        }
    }
    
    private var timelineContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.statuses) { status in
                    StatusView(status: status)
                        .onAppear {
                            if status.id == viewModel.statuses.last?.id {
                                Task {
                                    await viewModel.loadTimeline()
                                }
                            }
                        }
                }
                
                if viewModel.isLoading {
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