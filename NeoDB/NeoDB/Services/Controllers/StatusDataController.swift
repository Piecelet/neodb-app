//
//  StatusDataController.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/7/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation
import OSLog
import SwiftUI

@MainActor
protocol StatusDataControlling {
  var isReblogged: Bool { get set }
  var isBookmarked: Bool { get set }
  var isFavorited: Bool { get set }

  var favoritesCount: Int { get set }
  var reblogsCount: Int { get set }
  var repliesCount: Int { get set }

  func toggleBookmark(remoteStatus: String?) async
  func toggleReblog(remoteStatus: String?) async
  func toggleFavorite(remoteStatus: String?) async
}

@MainActor
final class StatusDataControllerProvider {
  static let shared = StatusDataControllerProvider()

  private var dictionary: NSMutableDictionary = [:]

  private struct DictionaryKey: Hashable {
    let statusId: String
    let accountID: String
  }

  func dataController(for status: any AnyMastodonStatus, appAccountsManager: AppAccountsManager) -> StatusDataController {
    let key = DictionaryKey(statusId: status.id, accountID: appAccountsManager.currentAccount.id)
    if let controller = dictionary[key] as? StatusDataController {
      return controller
    }
    let controller = StatusDataController(status: status, appAccountsManager: appAccountsManager)
    dictionary[key] = controller
    return controller
  }

  func updateDataControllers(for statuses: [MastodonStatus], appAccountsManager: AppAccountsManager) {
    for status in statuses {
      let realStatus: AnyMastodonStatus = status.reblog ?? status
      let controller = dataController(for: realStatus, appAccountsManager: appAccountsManager)
      controller.updateFrom(status: realStatus)
    }
  }
}

@MainActor
final class StatusDataController: StatusDataControlling {
  private let status: AnyMastodonStatus
  private let appAccountsManager: AppAccountsManager

  @Published var isReblogged: Bool
  @Published var isBookmarked: Bool
  @Published var isFavorited: Bool
  @Published var content: HTMLString

  @Published var favoritesCount: Int
  @Published var reblogsCount: Int
  @Published var repliesCount: Int

  init(status: AnyMastodonStatus, appAccountsManager: AppAccountsManager) {
    self.status = status
    self.appAccountsManager = appAccountsManager

    isReblogged = status.reblogged == true
    isBookmarked = status.bookmarked == true
    isFavorited = status.favourited == true

    reblogsCount = status.reblogsCount
    repliesCount = status.repliesCount
    favoritesCount = status.favouritesCount
    content = status.content
  }

  func updateFrom(status: AnyMastodonStatus) {
    isReblogged = status.reblogged == true
    isBookmarked = status.bookmarked == true
    isFavorited = status.favourited == true

    reblogsCount = status.reblogsCount
    repliesCount = status.repliesCount
    favoritesCount = status.favouritesCount
    content = status.content
  }

  func toggleFavorite(remoteStatus: String?) async {
    guard appAccountsManager.isAuthenticated else { return }
    isFavorited.toggle()
    let id = remoteStatus ?? status.id
    let endpoint = isFavorited ? StatusesEndpoint.favorite(id: id) : StatusesEndpoint.unfavorite(id: id)
    withAnimation(.default) {
      favoritesCount += isFavorited ? 1 : -1
    }
    do {
      let status = try await appAccountsManager.currentClient.fetch(endpoint, type: MastodonStatus.self)
      updateFrom(status: status.reblog ?? status)
    } catch {
      isFavorited.toggle()
      favoritesCount += isFavorited ? -1 : 1
    }
  }

  func toggleReblog(remoteStatus: String?) async {
    guard appAccountsManager.isAuthenticated else { return }
    isReblogged.toggle()
    let id = remoteStatus ?? status.id
    let endpoint = isReblogged ? StatusesEndpoint.reblog(id: id) : StatusesEndpoint.unreblog(id: id)
    withAnimation(.default) {
      reblogsCount += isReblogged ? 1 : -1
    }
    do {
      let status = try await appAccountsManager.currentClient.fetch(endpoint, type: MastodonStatus.self)
      updateFrom(status: status.reblog ?? status)
    } catch {
      isReblogged.toggle()
      reblogsCount += isReblogged ? -1 : 1
    }
  }

  func toggleBookmark(remoteStatus: String?) async {
    guard appAccountsManager.isAuthenticated else { return }
    isBookmarked.toggle()
    let id = remoteStatus ?? status.id
    let endpoint = isBookmarked ? StatusesEndpoint.bookmark(id: id) : StatusesEndpoint.unbookmark(id: id)
    do {
      let status = try await appAccountsManager.currentClient.fetch(endpoint, type: MastodonStatus.self)
      updateFrom(status: status.reblog ?? status)
    } catch {
      isBookmarked.toggle()
    }
  }
}
