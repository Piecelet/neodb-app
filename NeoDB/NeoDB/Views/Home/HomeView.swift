import SwiftUI
import OSLog
import HTML2Markdown
import MarkdownUI

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
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
    
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
    @Environment(\.openURL) private var openURL
    
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
            HTMLContentView(htmlContent: status.content)
                .textSelection(.enabled)
            
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
            
            // Stats
            HStack(spacing: 16) {
                Label("\(status.repliesCount)", systemImage: "bubble.right")
                Label("\(status.reblogsCount)", systemImage: "arrow.2.squarepath")
                Label("\(status.favouritesCount)", systemImage: "star")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
    
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

struct HTMLContentView: View {
    let htmlContent: String
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        if let markdown = convertHTMLToMarkdown(htmlContent) {
            Markdown(markdown)
                .textSelection(.enabled)
                .padding(.vertical, 4)
        } else {
            Text(htmlContent)
                .textSelection(.enabled)
        }
    }
    
    private func convertHTMLToMarkdown(_ html: String) -> String? {
        // Remove extra newlines and spaces
        let cleanedHTML = html.replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        do {
            let dom = try HTMLParser().parse(html: cleanedHTML)
            // Use bullets for unordered lists for better SwiftUI Text compatibility
            let markdown = dom.markdownFormatted(options: .unorderedListBullets)
            return markdown
        } catch {
            print("Error parsing HTML: \(error)")
            return nil
        }
    }
} 