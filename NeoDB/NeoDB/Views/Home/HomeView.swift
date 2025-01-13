// 
//  HomeView.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 1/7/25.
//

import SwiftUI
import OSLog

@MainActor
class HomeViewModel: ObservableObject {
    private let timelineService: TimelineService
    private let logger = Logger.home
    
    @Published var statuses: [Status] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var detailedError: String?
    
    // Pagination
    private var maxId: String?
    private var hasMore = true
    
    // Task management
    private var currentLoadTask: Task<Void, Never>?
    
    init(timelineService: TimelineService) {
        self.timelineService = timelineService
    }
    
    func loadTimeline(refresh: Bool = false) async {
        // Cancel any existing load task
        currentLoadTask?.cancel()
        
        let task = Task { @MainActor in
            if refresh {
                maxId = nil
                hasMore = true
                // Only clear statuses if we're refreshing
                statuses = []
            }
            
            guard !isLoading, hasMore else { return }
            
            isLoading = true
            error = nil
            detailedError = nil
            
            do {
                try Task.checkCancellation()
                let newStatuses = try await timelineService.getTimeline(maxId: maxId)
                
                // Check if task was cancelled after the network call
                try Task.checkCancellation()
                
                if refresh {
                    statuses = newStatuses
                } else {
                    statuses.append(contentsOf: newStatuses)
                }
                maxId = newStatuses.last?.id
                hasMore = !newStatuses.isEmpty
                logger.debug("Successfully loaded \(newStatuses.count) statuses")
            } catch is CancellationError {
                logger.debug("Timeline load was cancelled")
                // Don't update error state for cancellation
            } catch {
                if !Task.isCancelled {
                    logger.error("Failed to load timeline: \(error.localizedDescription)")
                    self.error = "Failed to load timeline"
                    
                    if let networkError = error as? NetworkError {
                        detailedError = networkError.localizedDescription
                    } else if let decodingError = error as? DecodingError {
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
            }
            
            if !Task.isCancelled {
                isLoading = false
            }
        }
        
        currentLoadTask = task
    }
}

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var accountsManager: AppAccountsManager
    
    init(timelineService: TimelineService) {
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
                    Button {
                        router.navigate(to: .statusDetailWithStatus(status: status))
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
