import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    private let timelineService: TimelineService
    
    @Published var statuses: [Status] = []
    @Published var isLoading = false
    @Published var error: String?
    
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
        
        do {
            let newStatuses = try await timelineService.getHomeTimeline(maxId: maxId)
            if refresh {
                statuses = newStatuses
            } else {
                statuses.append(contentsOf: newStatuses)
            }
            maxId = newStatuses.last?.id
            hasMore = !newStatuses.isEmpty
        } catch {
            self.error = error.localizedDescription
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
                    description: Text(error)
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

struct StatusView: View {
    let status: Status
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                AsyncImage(url: URL(string: status.account.avatar)) { phase in
                    switch phase {
                    case .empty:
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 44, height: 44)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                    case .failure(_):
                        Image(systemName: "person.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                            .font(.system(size: 44))
                    @unknown default:
                        EmptyView()
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(status.account.displayName)
                        .font(.headline)
                    Text("@\(status.account.username)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text(status.createdAt.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Content
            Text(status.content)
                .font(.body)
            
            // Media
            if !status.mediaAttachments.isEmpty {
                mediaGrid
            }
            
            // Footer
            if !status.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(status.tags, id: \.name) { tag in
                            Text("#\(tag.name)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
    }
    
    @ViewBuilder
    private var mediaGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: min(status.mediaAttachments.count, 2))
        
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(status.mediaAttachments) { attachment in
                AsyncImage(url: URL(string: attachment.url)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(1, contentMode: .fill)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure(_):
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(1, contentMode: .fill)
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                            }
                    @unknown default:
                        EmptyView()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .aspectRatio(1, contentMode: .fit)
            }
        }
    }
} 