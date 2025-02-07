//
//  TimelinesViewModel.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/7/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation
import Perception
import SwiftUI

@MainActor
@Perceptible
class TimelinesViewModel {
    var scrollToId: String?
    var statusesState: MastodonStatusesState = .loading
    var timeline: MastodonTimelinesFilter = .local {
        willSet {
            if timeline == .local,
                newValue != .following,
                newValue != timeline
            {
                saveMarker()
            }
        }
        didSet {
            timelineTask?.cancel()
            timelineTask = Task {
                await handleLatestOrResume(oldValue)

                if oldValue != timeline {

                    await reset()
                    pendingStatusesObserver.pendingStatuses = []
                }

                guard !Task.isCancelled else {
                    return
                }

                await fetchNewestStatuses(pullToRefresh: false)
            }
        }
    }

    private(set) var timelineTask: Task<Void, Never>?

    // Internal source of truth for a timeline.
    private(set) var datasource = MastodonTimelinesDatasource()
    private let statusFetcher: MastodonTimelinesStatusFetching
//    private let cache = TimelineCache()
//    private var isCacheEnabled: Bool {
//        canFilterTimeline && timeline.supportNewestPagination
//            && client?.isAuth == true
//    }

    @PerceptionIgnored
    private var visibleStatuses: [MastodonStatus] = []

    private var canStreamEvents: Bool = true {
        didSet {
            if canStreamEvents {
                pendingStatusesObserver.isLoadingNewStatuses = false
            }
        }
    }

    @PerceptionIgnored
    var canFilterTimeline: Bool = true

    var accountsManager: AppAccountsManager? {
        didSet {
            if oldValue !== accountsManager {
                Task {
                    await reset()
                }
            }
        }
    }

    var scrollToTopVisible: Bool = false

    var serverName: String {
        accountsManager?.currentAccount.instance ?? "Error"
    }

    var isTimelineVisible: Bool = false
    let pendingStatusesObserver: MastodonTimelinesUnreadStatusesObserver = .init()
    var marker: MastodonMarker.Content?

    init(statusFetcher: MastodonTimelinesStatusFetching = MastodonTimelinesStatusFetcher()) {
        self.statusFetcher = statusFetcher
    }

    func reset() async {
        await datasource.reset()
    }

    private func handleLatestOrResume(_ oldValue: MastodonTimelinesFilter) async {
        if timeline == .latest || timeline == .resume {
//            await clearCache(filter: oldValue)
            if timeline == .resume, let marker = await fetchMarker() {
                self.marker = marker
            }
            timeline = oldValue
        }
    }
}

// MARK: - Cache

extension TimelinesViewModel {
//    private func cache() async {
//        if let client = accountsManager?.currentClient, isCacheEnabled {
//            await cache.set(
//                statuses: datasource.get(), client: client.id,
//                filter: timeline.id)
//        }
//    }
//
//    private func getCachedStatuses() async -> [Status]? {
//        if let client = accountsManager?.currentClient, isCacheEnabled {
//            return await cache.getStatuses(for: client.id, filter: timeline.id)
//        }
//        return nil
//    }
//
//    private func clearCache(filter: TimelinesFilter) async {
//        if let client = accountsManager?.currentClient, isCacheEnabled {
//            await cache.clearCache(for: client.id, filter: filter.id)
//            await cache.setLatestSeenStatuses(
//                [], for: client, filter: filter.id)
//        }
//    }
}

// MARK: - StatusesFetcher

extension TimelinesViewModel: MastodonStatusesFetcher {
    func pullToRefresh() async {
        timelineTask?.cancel()

       if !timeline.supportNewestPagination
       {
           await reset()
       }
        await fetchNewestStatuses(pullToRefresh: true)
    }

    func refreshTimeline() {
        timelineTask?.cancel()
        timelineTask = Task {
//            if UserPreferences.shared.fastRefreshEnabled {
//                await reset()
//            }
            await fetchNewestStatuses(pullToRefresh: false)
        }
    }

    func refreshTimelineContentFilter() async {
        timelineTask?.cancel()
        let statuses = await datasource.getFiltered()
        withAnimation {
            statusesState = .display(
                statuses: statuses, nextPageState: .hasNextPage)
        }
    }

    func fetchStatuses(from: MastodonMarker.Content) async throws {
        guard let accountsManager = accountsManager else { return }
        statusesState = .loading
        var statuses: [MastodonStatus] = try await accountsManager.currentClient.fetch(
            timeline.endpoint(
                sinceId: nil,
                maxId: from.lastReadId,
                minId: nil,
                offset: 0,
                limit: 40), type: [MastodonStatus].self)

        StatusDataControllerProvider.shared.updateDataControllers(
            for: statuses, accountsManager: accountsManager)

        await datasource.set(statuses)
        // await cache()
        statuses = await datasource.getFiltered()
        marker = nil

        withAnimation {
            statusesState = .display(
                statuses: statuses, nextPageState: .hasNextPage)
        }

        await fetchNewestStatuses(pullToRefresh: false)
    }

    func fetchNewestStatuses(pullToRefresh: Bool) async {
        guard let accountsManager else { return }
        do {
            if let marker {
                try await fetchStatuses(from: marker)
            } else if await datasource.isEmpty {
                try await fetchFirstPage(accountsManager: accountsManager)
            } else if let latest = await datasource.get().first,
                timeline.supportNewestPagination
            {
                pendingStatusesObserver.isLoadingNewStatuses = !pullToRefresh
                try await fetchNewPagesFrom(
                    latestStatus: latest.id, accountsManager: accountsManager)
            }
        } catch {
            if await datasource.isEmpty {
                statusesState = .error(error: error)
            }
            canStreamEvents = true
        }
    }

    // Hydrate statuses in the Timeline when statuses are empty.
    private func fetchFirstPage(accountsManager: AppAccountsManager?) async throws {
        guard let accountsManager = accountsManager else { return }

        pendingStatusesObserver.pendingStatuses = []

        if await datasource.isEmpty {
            statusesState = .loading
        }

        // If we get statuses from the cache for the home timeline, we displays those.
        // Else we fetch top most page from the API.
        if timeline.supportNewestPagination
            // let cachedStatuses = await getCachedStatuses(),
            // !cachedStatuses.isEmpty,
            // !UserPreferences.shared.fastRefreshEnabled
        {
//            await datasource.set(cachedStatuses)
            let statuses = await datasource.getFiltered()
            // if let latestSeenId = await cache.getLatestSeenStatus(
            //     for: client, filter: timeline.id)?.first
            // {
            //     // Restore cache and scroll to latest seen status.
            //     scrollToId = latestSeenId
            //     statusesState = .display(
            //         statuses: statuses, nextPageState: .hasNextPage)
            // } else {
                // Restore cache and scroll to top.
                withAnimation {
                    statusesState = .display(
                        statuses: statuses, nextPageState: .hasNextPage)
                }
            // }
            // And then we fetch statuses again toget newest statuses from there.
            await fetchNewestStatuses(pullToRefresh: false)
        } else {
            var statuses: [MastodonStatus] = try await statusFetcher.fetchFirstPage(
                accountsManager: accountsManager,
                timeline: timeline)

            StatusDataControllerProvider.shared.updateDataControllers(
                for: statuses, accountsManager: accountsManager)

            await datasource.set(statuses)
            // await cache()
            statuses = await datasource.getFiltered()

            withAnimation {
                statusesState = .display(
                    statuses: statuses,
                    nextPageState: statuses.count < 20 ? .none : .hasNextPage)
            }
        }
    }

    // Fetch pages from the top most status of the timeline.
    private func fetchNewPagesFrom(latestStatus: String, accountsManager: AppAccountsManager?)
        async throws
    {
        canStreamEvents = false
        let initialTimeline = timeline

        let newStatuses = try await fetchAndDedupNewStatuses(
            latestStatus: latestStatus,
            accountsManager: accountsManager)

        guard !newStatuses.isEmpty,
            isTimelineVisible,
            !Task.isCancelled,
            initialTimeline == timeline
        else {
            canStreamEvents = true
            return
        }

        await updateTimelineWithNewStatuses(newStatuses)

        if !Task.isCancelled, let latest = await datasource.get().first {
            pendingStatusesObserver.isLoadingNewStatuses = true
            try await fetchNewPagesFrom(latestStatus: latest.id, accountsManager: accountsManager)
        }
    }

    private func fetchAndDedupNewStatuses(latestStatus: String, accountsManager: AppAccountsManager?)
        async throws
        -> [MastodonStatus]
    {
        guard let accountsManager = accountsManager else { return [] }
        
        var newStatuses = try await statusFetcher.fetchNewPages(
            accountsManager: accountsManager,
            timeline: timeline,
            minId: latestStatus,
            maxPages: 5)
        let ids = await datasource.get().map(\.id)
        newStatuses = newStatuses.filter { status in
            !ids.contains(where: { $0 == status.id })
        }
        StatusDataControllerProvider.shared.updateDataControllers(
            for: newStatuses, accountsManager: accountsManager)
        return newStatuses
    }

    private func updateTimelineWithNewStatuses(_ newStatuses: [MastodonStatus]) async {
        defer {
            canStreamEvents = true
        }
        let topStatus = await datasource.getFiltered().first
        await datasource.insert(contentOf: newStatuses, at: 0)
        if let lastVisible = visibleStatuses.last {
            await datasource.remove(after: lastVisible, safeOffset: 15)
        }
        // await cache()
        pendingStatusesObserver.pendingStatuses.insert(
            contentsOf: newStatuses.map(\.id), at: 0)

        let statuses = await datasource.getFiltered()

        if let topStatus = topStatus,
            visibleStatuses.contains(where: { $0.id == topStatus.id }),
            scrollToTopVisible
        {
            scrollToId = topStatus.id
            statusesState = .display(
                statuses: statuses, nextPageState: .hasNextPage)
        } else {
            withAnimation {
                statusesState = .display(
                    statuses: statuses, nextPageState: .hasNextPage)
            }
        }
    }

    enum NextPageError: Error {
        case internalError
    }

    func fetchNextPage() async throws {
        let statuses = await datasource.get()
        guard let accountsManager = accountsManager, let lastId = statuses.last?.id else {
            throw NextPageError.internalError
        }
        let newStatuses: [MastodonStatus] = try await statusFetcher.fetchNextPage(
            accountsManager: accountsManager,
            timeline: timeline,
            lastId: lastId,
            offset: statuses.count)

        await datasource.append(contentOf: newStatuses)
        StatusDataControllerProvider.shared.updateDataControllers(
            for: newStatuses, accountsManager: accountsManager)

        statusesState = await .display(
            statuses: datasource.getFiltered(),
            nextPageState: newStatuses.count < 20 ? .none : .hasNextPage)
    }

    func statusDidAppear(status: MastodonStatus) {
        pendingStatusesObserver.removeStatus(status: status)
        visibleStatuses.insert(status, at: 0)

//        if let accountsManager, timeline.supportNewestPagination {
//            Task {
//                await cache.setLatestSeenStatuses(
//                    visibleStatuses, for: accountsManager, filter: timeline.id)
//            }
//        }
    }

    func statusDidDisappear(status: MastodonStatus) {
        visibleStatuses.removeAll(where: { $0.id == status.id })
    }
}

// MARK: - Marker handling

extension TimelinesViewModel {
    func fetchMarker() async -> MastodonMarker.Content? {
        guard let client = accountsManager?.currentClient else {
            return nil
        }
        do {
            let data: MastodonMarker = try await client.fetch(MarkersEndpoint.markers, type: MastodonMarker.self)
            return data.home
        } catch {
            return nil
        }
    }

    func saveMarker() {
//        guard timeline == .home, let client = accountsManager?.currentClient else { return }
//        Task {
//            // guard
//            //     let id = await cache.getLatestSeenStatus(
//            //         for: client, filter: timeline.id)?.first
//            // else {
//            //     return
//            // }
//            do {
//                let _: MastodonMarker = try await client.fetch(
//                     MarkersEndpoint.markHome(lastReadId: id), type: MastodonMarker.self)
//            } catch {}
//        }
    }
}

// MARK: - Event handling

extension TimelinesViewModel {
    func handleEvent(event: any StreamEvent) async {
        guard let accountsManager, canStreamEvents, isTimelineVisible else {
            return
        }

        switch event {
        case let updateEvent as StreamEventUpdate:
            await handleUpdateEvent(updateEvent, accountsManager: accountsManager)
        case let deleteEvent as StreamEventDelete:
            await handleDeleteEvent(deleteEvent)
        case let statusUpdateEvent as StreamEventStatusUpdate:
            await handleStatusUpdateEvent(statusUpdateEvent, accountsManager: accountsManager)
        default:
            break
        }
    }

    private func handleUpdateEvent(_ event: StreamEventUpdate, accountsManager: AppAccountsManager)
        async
    {
        guard timeline == .local,
//            UserPreferences.shared.isPostsStreamingEnabled,
            await !datasource.contains(statusId: event.status.id)
        else { return }

        pendingStatusesObserver.pendingStatuses.insert(event.status.id, at: 0)
        await datasource.insert(event.status, at: 0)
//        await cache()
        StatusDataControllerProvider.shared.updateDataControllers(
            for: [event.status], accountsManager: accountsManager)
        await updateStatusesState()
    }

    private func handleDeleteEvent(_ event: StreamEventDelete) async {
        if await datasource.remove(event.status) != nil {
//            await cache()
            await updateStatusesState()
        }
    }

    private func handleStatusUpdateEvent(
        _ event: StreamEventStatusUpdate, accountsManager: AppAccountsManager
    ) async {
        guard
            let originalIndex = await datasource.indexOf(
                statusId: event.status.id)
        else { return }

        StatusDataControllerProvider.shared.updateDataControllers(
            for: [event.status], accountsManager: accountsManager)
        await datasource.replace(event.status, at: originalIndex)
//        await cache()
        await updateStatusesState()
    }

    private func updateStatusesState() async {
        let statuses = await datasource.getFiltered()
        withAnimation {
            statusesState = .display(
                statuses: statuses, nextPageState: .hasNextPage)
        }
    }
}
