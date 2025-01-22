# TimelineFilter.swift

```swift
import Foundation
import Models
import Network
import SwiftUI

public enum TimelineFilter: Hashable, Equatable {
  case home, local, federated, trending
  case hashtag(tag: String, accountId: String?)
  case list(list: Models.List)
  case remoteLocal(server: String)

  public func hash(into hasher: inout Hasher) {
    hasher.combine(title())
  }

  public static func availableTimeline(client: Client) -> [TimelineFilter] {
    if !client.isAuth {
      return [.local, .federated, .trending]
    }
    return [.home, .local, .federated, .trending]
  }

  public func title() -> String {
    switch self {
    case .federated:
      return "Federated"
    case .local:
      return "Local"
    case .trending:
      return "Trending"
    case .home:
      return "Home"
    case let .hashtag(tag, _):
      return "#\(tag)"
    case let .list(list):
      return list.title
    case let .remoteLocal(server):
      return server
    }
  }
  
  public func localizedTitle() -> LocalizedStringKey {
    switch self {
    case .federated:
      return "timeline.federated"
    case .local:
      return "timeline.local"
    case .trending:
      return "timeline.trending"
    case .home:
      return "timeline.home"
    case let .hashtag(tag, _):
      return "#\(tag)"
    case let .list(list):
      return LocalizedStringKey(list.title)
    case let .remoteLocal(server):
      return LocalizedStringKey(server)
    }
  }
  
  public func iconName() -> String? {
    switch self {
    case .federated:
      return "globe.americas"
    case .local:
      return "person.2"
    case .trending:
      return "chart.line.uptrend.xyaxis"
    case .home:
      return "house"
    case .list:
      return "list.bullet"
    case .remoteLocal:
      return "dot.radiowaves.right"
    default:
      return nil
    }
  }

  public func endpoint(sinceId: String?, maxId: String?, minId: String?, offset: Int?) -> Endpoint {
    switch self {
    case .federated: return Timelines.pub(sinceId: sinceId, maxId: maxId, minId: minId, local: false)
    case .local: return Timelines.pub(sinceId: sinceId, maxId: maxId, minId: minId, local: true)
    case .remoteLocal: return Timelines.pub(sinceId: sinceId, maxId: maxId, minId: minId, local: true)
    case .home: return Timelines.home(sinceId: sinceId, maxId: maxId, minId: minId)
    case .trending: return Trends.statuses(offset: offset)
    case let .list(list): return Timelines.list(listId: list.id, sinceId: sinceId, maxId: maxId, minId: minId)
    case let .hashtag(tag, accountId):
      if let accountId {
        return Accounts.statuses(id: accountId, sinceId: nil, tag: tag, onlyMedia: nil, excludeReplies: nil, pinned: nil)
      } else {
        return Timelines.hashtag(tag: tag, maxId: maxId)
      }
    }
  }
}
```

# TimelineView.swift
```swift
import DesignSystem
import Env
import Models
import Network
import Shimmer
import Status
import SwiftUI

public struct TimelineView: View {
  private enum Constants {
    static let scrollToTop = "top"
  }

  @Environment(\.scenePhase) private var scenePhase
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var account: CurrentAccount
  @EnvironmentObject private var watcher: StreamWatcher
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var routerPath: RouterPath

  @StateObject private var viewModel = TimelineViewModel()

  @State private var scrollProxy: ScrollViewProxy?
  @Binding var timeline: TimelineFilter
  @Binding var scrollToTopSignal: Int

  private let feedbackGenerator = UIImpactFeedbackGenerator()

  public init(timeline: Binding<TimelineFilter>, scrollToTopSignal: Binding<Int>) {
    _timeline = timeline
    _scrollToTopSignal = scrollToTopSignal
  }

  public var body: some View {
    ScrollViewReader { proxy in
      ZStack(alignment: .top) {
        ScrollView {
          Rectangle()
            .frame(height: 0)
            .id(Constants.scrollToTop)
          LazyVStack {
            tagHeaderView
              .padding(.bottom, 16)
            switch viewModel.timeline {
            case .remoteLocal:
              StatusesListView(fetcher: viewModel, isRemote: true)
            default:
              StatusesListView(fetcher: viewModel)
            }
          }
          .padding(.top, .layoutPadding + (!viewModel.pendingStatuses.isEmpty ? 28 : 0))
        }
        .background(theme.primaryBackgroundColor)
        if viewModel.pendingStatusesEnabled {
          makePendingNewPostsView(proxy: proxy)
        }
      }
      .onAppear {
        scrollProxy = proxy
      }
    }
    .navigationTitle(timeline.localizedTitle())
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      if viewModel.client == nil {
        viewModel.client = client
        viewModel.timeline = timeline
      }
    }
    .refreshable {
      feedbackGenerator.impactOccurred(intensity: 0.3)
      await viewModel.fetchStatuses(userIntent: true)
      feedbackGenerator.impactOccurred(intensity: 0.7)
    }
    .onChange(of: watcher.latestEvent?.id) { _ in
      if let latestEvent = watcher.latestEvent {
        viewModel.handleEvent(event: latestEvent, currentAccount: account)
      }
    }
    .onChange(of: scrollToTopSignal, perform: { _ in
      withAnimation {
        scrollProxy?.scrollTo(Constants.scrollToTop, anchor: .top)
      }
    })
    .onChange(of: timeline) { newTimeline in
      switch newTimeline {
      case let .remoteLocal(server):
        viewModel.client = Client(server: server)
      default:
        viewModel.client = client
      }
      viewModel.timeline = newTimeline
    }
    .onChange(of: scenePhase, perform: { scenePhase in
      switch scenePhase {
      case .active:
        Task {
          await viewModel.fetchStatuses(userIntent: false)
        }
      default:
        break
      }
    })
  }

  @ViewBuilder
  private func makePendingNewPostsView(proxy: ScrollViewProxy) -> some View {
    if !viewModel.pendingStatuses.isEmpty {
      HStack(spacing: 6) {
        Button {
          withAnimation {
            proxy.scrollTo(Constants.scrollToTop)
            viewModel.displayPendingStatuses()
          }
        } label: {
          Text(viewModel.pendingStatusesButtonTitle)
        }
        .keyboardShortcut("r", modifiers: .command)
        .buttonStyle(.bordered)
        .background(.thinMaterial)
        .cornerRadius(8)
        if viewModel.pendingStatuses.count > 1 {
          Button {
            withAnimation {
              viewModel.dequeuePendingStatuses()
            }
          } label: {
            Image(systemName: "text.insert")
          }
          .buttonStyle(.bordered)
          .background(.thinMaterial)
          .cornerRadius(8)
        }
      }
      .padding(.top, 6)
    }
  }

  @ViewBuilder
  private var tagHeaderView: some View {
    if let tag = viewModel.tag {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("#\(tag.name)")
            .font(.scaledHeadline)
          Text("timeline.n-recent-from-n-participants \(tag.totalUses) \(tag.totalAccounts)")
            .font(.scaledFootnote)
            .foregroundColor(.gray)
        }
        Spacer()
        Button {
          Task {
            if tag.following {
              viewModel.tag = await account.unfollowTag(id: tag.name)
            } else {
              viewModel.tag = await account.followTag(id: tag.name)
            }
          }
        } label: {
          Text(tag.following ? "account.follow.following" : "account.follow.follow")
        }.buttonStyle(.bordered)
      }
      .padding(.horizontal, .layoutPadding)
      .padding(.vertical, 8)
      .background(theme.secondaryBackgroundColor)
    }
  }
}
```

# TimelineViewModel.swift
```swift
import Env
import Models
import Network
import Status
import SwiftUI

@MainActor
class TimelineViewModel: ObservableObject, StatusesFetcher {
  var client: Client? {
    didSet {
      if oldValue != client {
        statuses = []
      }
    }
  }

  // Internal source of truth for a timeline.
  private var statuses: [Status] = []

  @Published var statusesState: StatusesState = .loading
  @Published var timeline: TimelineFilter = .federated {
    didSet {
      Task {
        if oldValue != timeline {
          statuses = []
          pendingStatuses = []
          tag = nil
        }
        await fetchStatuses(userIntent: false)
        switch timeline {
        case let .hashtag(tag, _):
          await fetchTag(id: tag)
        default:
          break
        }
      }
    }
  }

  @Published var tag: Tag?

  enum PendingStatusesState {
    case refresh, stream
  }

  @Published var pendingStatuses: [Status] = []
  @Published var pendingStatusesState: PendingStatusesState = .stream

  var pendingStatusesButtonTitle: LocalizedStringKey {
    switch pendingStatusesState {
    case .stream, .refresh:
      return "timeline.n-new-posts \(pendingStatuses.count)"
    }
  }

  var pendingStatusesEnabled: Bool {
    timeline == .home
  }

  var serverName: String {
    client?.server ?? "Error"
  }

  func fetchStatuses() async {
    await fetchStatuses(userIntent: false)
  }

  func fetchStatuses(userIntent: Bool) async {
    guard let client else { return }
    do {
      if statuses.isEmpty {
        pendingStatuses = []
        statusesState = .loading
        statuses = try await client.get(endpoint: timeline.endpoint(sinceId: nil,
                                                                    maxId: nil,
                                                                    minId: nil,
                                                                    offset: statuses.count))
        withAnimation {
          statusesState = .display(statuses: statuses, nextPageState: statuses.count < 20 ? .none : .hasNextPage)
        }
      } else if let first = pendingStatuses.first ?? statuses.first {
        var newStatuses: [Status] = await fetchNewPages(minId: first.id, maxPages: 20)
        if userIntent || !pendingStatusesEnabled {
          pendingStatuses.insert(contentsOf: newStatuses, at: 0)
          statuses.insert(contentsOf: pendingStatuses, at: 0)
          pendingStatuses = []
          withAnimation {
            statusesState = .display(statuses: statuses, nextPageState: statuses.count < 20 ? .none : .hasNextPage)
          }
        } else {
          newStatuses = newStatuses.filter { status in
            !pendingStatuses.contains(where: { $0.id == status.id })
          }
          pendingStatuses.insert(contentsOf: newStatuses, at: 0)
          pendingStatusesState = .refresh
        }
      }
    } catch {
      statusesState = .error(error: error)
      print("timeline parse error: \(error)")
    }
  }

  func fetchNewPages(minId: String, maxPages: Int) async -> [Status] {
    guard let client else { return [] }
    var pagesLoaded = 0
    var allStatuses: [Status] = []
    var latestMinId = minId
    do {
      while let newStatuses: [Status] = try await client.get(endpoint: timeline.endpoint(sinceId: nil,
                                                                                         maxId: nil,
                                                                                         minId: latestMinId,
                                                                                         offset: statuses.count)),
        !newStatuses.isEmpty,
        pagesLoaded < maxPages
      {
        pagesLoaded += 1
        allStatuses.insert(contentsOf: newStatuses, at: 0)
        latestMinId = newStatuses.first?.id ?? ""
      }
    } catch {
      return allStatuses
    }
    return allStatuses
  }

  func fetchNextPage() async {
    guard let client else { return }
    do {
      guard let lastId = statuses.last?.id else { return }
      statusesState = .display(statuses: statuses, nextPageState: .loadingNextPage)
      let newStatuses: [Status] = try await client.get(endpoint: timeline.endpoint(sinceId: nil,
                                                                                   maxId: lastId,
                                                                                   minId: nil,
                                                                                   offset: statuses.count))
      statuses.append(contentsOf: newStatuses)
      statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
    } catch {
      statusesState = .error(error: error)
    }
  }

  func fetchTag(id: String) async {
    guard let client else { return }
    do {
      tag = try await client.get(endpoint: Tags.tag(id: id))
    } catch {}
  }

  func handleEvent(event: any StreamEvent, currentAccount: CurrentAccount) {
    if let event = event as? StreamEventUpdate,
       pendingStatusesEnabled,
       !statuses.contains(where: { $0.id == event.status.id }),
       !pendingStatuses.contains(where: { $0.id == event.status.id })
    {
      if event.status.account.id == currentAccount.account?.id, pendingStatuses.isEmpty {
        withAnimation {
          statuses.insert(event.status, at: 0)
          statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
        }
      } else {
        pendingStatuses.insert(event.status, at: 0)
        pendingStatusesState = .stream
      }
    } else if let event = event as? StreamEventDelete {
      withAnimation {
        statuses.removeAll(where: { $0.id == event.status })
        statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
      }
    } else if let event = event as? StreamEventStatusUpdate {
      if let originalIndex = statuses.firstIndex(where: { $0.id == event.status.id }) {
        statuses[originalIndex] = event.status
        statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
      }
    }
  }

  func displayPendingStatuses() {
    guard timeline == .home else { return }
    pendingStatuses = pendingStatuses.filter { status in
      !statuses.contains(where: { $0.id == status.id })
    }
    statuses.insert(contentsOf: pendingStatuses, at: 0)
    pendingStatuses = []
    statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
  }

  func dequeuePendingStatuses() {
    guard timeline == .home else { return }
    if pendingStatuses.count > 1 {
      let status = pendingStatuses.removeLast()
      statuses.insert(status, at: 0)
    }
    statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
  }
}
```