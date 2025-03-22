//
//  TelemetryService.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/4/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation
import TelemetryDeck
import OSLog
import SwiftUI

@MainActor
class TelemetryService: ObservableObject {
    // MARK: - Singleton
    static let shared = TelemetryService()
    
    private let logger = Logger.services.telemetry.telemetry

    private let config = TelemetryDeck.Config(appID: AppConfig.telemetryDeckAppID)
    
    @AppStorage("isTelemetryEnabled") private var isTelemetryEnabled = true
    
    private init() {
        configure()
    }
    
    private func configure() {
        config.defaultSignalPrefix = "App."
        TelemetryDeck.initialize(config: config)
        logger.debug("TelemetryDeck initialized")
    }

    func setTelemetryEnabled(_ enabled: Bool) {
        isTelemetryEnabled = enabled
        if enabled {
            configure()
        } else {
            // Create a minimal config that effectively disables telemetry
            let disabledConfig = TelemetryDeck.Config(appID: "")
            TelemetryDeck.initialize(config: disabledConfig)
        }
    }
    
    func isEnabled() -> Bool {
        return isTelemetryEnabled
    }
    
    private func shouldTrack() -> Bool {
        return isTelemetryEnabled
    }

    func updateDefaultUserID(to id: String?) {
        guard shouldTrack() else { return }
        TelemetryDeck.updateDefaultUserID(to: id)
    }

    func updateInstance(to instance: String) {
        guard shouldTrack() else { return }
        config.defaultParameters = { ["instance": instance] }
        TelemetryDeck.initialize(config: config)
        logger.debug("TelemetryDeck initialized with instance: \(instance)")
    }
    
    // MARK: - App Lifecycle Events
    
    func trackAppLaunch() {
        guard shouldTrack() else { return }
        TelemetryDeck.signal("launched")
        logger.debug("Tracked app launch")
    }
    
    // MARK: - Authentication Events
    
    func trackAuthLogin(instance: String? = nil) {
        guard shouldTrack() else { return }
        if let instance = instance {
            TelemetryDeck.signal("auth.login", parameters: ["instance": instance])
        } else {
            TelemetryDeck.signal("auth.login")
        }
        logger.debug("Tracked login for instance: \(instance ?? "unknown")")
    }
    
    func trackAuthLogout(instance: String? = nil) {
        guard shouldTrack() else { return }
        if let instance = instance {
            TelemetryDeck.signal("auth.logout", parameters: ["instance": instance])
        } else {
            TelemetryDeck.signal("auth.logout")
        }
        logger.debug("Tracked logout for instance: \(instance ?? "unknown")")
    }
    
    // MARK: - Navigation Events
    
    func trackTabChange(to tab: TabDestination) {
        guard shouldTrack() else { return }
        TelemetryDeck.signal("navigation.tab", parameters: ["tab": tab.rawValue])
        logger.debug("Tracked tab change to: \(tab.rawValue)")
    }

    func trackPurchaseWithFeature(feature: StoreConfig.Features? = nil) {
        guard shouldTrack() else { return }
        var parameters: [String: String] = [:]
        if let feature = feature {
            parameters["feature"] = feature.rawValue
        }
        TelemetryDeck.signal("purchase.withFeature", parameters: parameters)
        logger.debug("Tracked purchase with feature: \(feature?.rawValue ?? "none")")
    }

    // MARK - Discover Events
    func trackSearchSubmit(category: ItemCategory? = nil) {
        guard shouldTrack() else { return }
        var parameters: [String: String] = [:]
        if let category = category {
            parameters["itemCategory"] = category.rawValue
        }
        TelemetryDeck.signal("discover.search.submit", parameters: parameters)
        logger.debug("Tracked search submit with category: \(category?.rawValue ?? "none")")
    }

    func trackSearchCategoryChange(category: ItemCategory? = nil) {
        guard shouldTrack() else { return }
        var parameters: [String: String] = [:]
        if let category = category {
            parameters["itemCategory"] = category.rawValue
        }
        TelemetryDeck.signal("discover.search.category.change", parameters: parameters)
        logger.debug("Tracked search category change to: \(category?.rawValue ?? "none")")
    }

    func trackSearchURLPaste() {
        guard shouldTrack() else { return }
        TelemetryDeck.signal("discover.search.url.paste")
        logger.debug("Tracked search URL paste")
    }

    func trackSearchURLSubmit() {
        guard shouldTrack() else { return }
        TelemetryDeck.signal("discover.search.url.submit")
        logger.debug("Tracked search URL submit")
    }

    func trackGalleryItemClick(itemId: String, category: ItemCategory) {
        guard shouldTrack() else { return }
        TelemetryDeck.signal("discover.gallery.item.click", parameters: [
            "itemId": itemId,
            "category": category.rawValue
        ])
        logger.debug("Tracked gallery item click: \(itemId)")
    }

    func trackGalleryCategoryClick(category: ItemCategory) {
        guard shouldTrack() else { return }
        TelemetryDeck.signal("discover.gallery.category.click", parameters: [
            "category": category.rawValue
        ])
        logger.debug("Tracked gallery category click: \(category.rawValue)")
    }

    // MARK: - Library Events

    func trackLibraryItemClick(itemId: String, category: ItemCategory, currentShelfType: ShelfType? = nil, currentShelfCategory: ItemCategory.shelfAvailable? = nil) {
        guard shouldTrack() else { return }
        var parameters: [String: String] = [
            "itemId": itemId,
            "category": category.rawValue
        ]
        if let currentShelfType = currentShelfType {
            parameters["currentShelfType"] = currentShelfType.rawValue
        }
        if let currentShelfCategory = currentShelfCategory {
            parameters["currentShelfCategory"] = currentShelfCategory.rawValue
        }
        TelemetryDeck.signal("library.item.click", parameters: parameters)
        logger.debug("Tracked library item click: \(itemId)")
    }

    func trackLibraryCategoryChange(category: ItemCategory.shelfAvailable, currentShelfType: ShelfType? = nil, currentShelfCategory: ItemCategory.shelfAvailable? = nil) {
        guard shouldTrack() else { return }
        var parameters: [String: String] = [
            "category": category.rawValue
        ]
        if let currentShelfType = currentShelfType {
            parameters["currentShelfType"] = currentShelfType.rawValue
        }
        if let currentShelfCategory = currentShelfCategory {
            parameters["currentShelfCategory"] = currentShelfCategory.rawValue
        }
        TelemetryDeck.signal("library.category.change", parameters: parameters)
        logger.debug("Tracked library category change: \(category.rawValue)")
    }

    func trackLibraryShelfTypeChange(shelfType: ShelfType, currentShelfType: ShelfType? = nil, currentShelfCategory: ItemCategory.shelfAvailable? = nil) {
        guard shouldTrack() else { return }
        var parameters: [String: String] = [
            "shelfType": shelfType.rawValue
        ]
        if let currentShelfType = currentShelfType {
            parameters["currentShelfType"] = currentShelfType.rawValue
        }
        if let currentShelfCategory = currentShelfCategory {
            parameters["currentShelfCategory"] = currentShelfCategory.rawValue
        }
        TelemetryDeck.signal("library.shelf.type.change", parameters: parameters)
        logger.debug("Tracked library shelf type change: \(shelfType.rawValue)")
    }

    func trackLibraryRefresh() {
        guard shouldTrack() else { return }
        TelemetryDeck.signal("library.refresh")
        logger.debug("Tracked library refresh")
    }
    
    // MARK: - Item Events

    func trackItemMarkEdit(itemId: String, category: ItemCategory) {
        guard shouldTrack() else { return }
        let parameters: [String: String] = [
            "itemId": itemId,
            "category": category.rawValue
        ]
        TelemetryDeck.signal("item.mark.edit", parameters: parameters)
        logger.debug("Tracked item mark edit: \(itemId)")
    }

    func trackItemShowDetail(itemId: String? = nil, category: ItemCategory? = nil) {
        guard shouldTrack() else { return }
        var parameters: [String: String] = [:]
        if let category = category {
            parameters["category"] = category.rawValue
        }
        if let itemId = itemId {
            parameters["itemId"] = itemId
        }
        TelemetryDeck.signal("item.show.detail", parameters: parameters)
    }

    func trackItemAddMark(itemId: String, category: ItemCategory, shelfType: ShelfType) {
        guard shouldTrack() else { return }
        let parameters: [String: String] = [
            "itemId": itemId,
            "category": category.rawValue,
            "shelfType": shelfType.rawValue
        ]
        TelemetryDeck.signal("item.add.mark", parameters: parameters)
        logger.debug("Tracked item add mark: \(itemId)")
    }

    func trackItemEditMark(itemId: String, category: ItemCategory, shelfType: ShelfType) {
        guard shouldTrack() else { return }
        let parameters: [String: String] = [
            "itemId": itemId,
            "category": category.rawValue,
            "shelfType": shelfType.rawValue
        ]
        TelemetryDeck.signal("item.edit.mark", parameters: parameters)
        logger.debug("Tracked item edit mark: \(itemId)")
    }
    
    func trackItemView(id: String? = nil, category: ItemCategory? = nil) {
        guard shouldTrack() else { return }
        var parameters: [String: String] = [:]
        if let category = category {
            parameters["category"] = category.rawValue
        }
        if let id = id {
            parameters["itemId"] = id
        }
        TelemetryDeck.signal("item.viewed", parameters: parameters)
        logger.debug("Tracked item view: \(id ?? "none")")
    }

    func trackItemViewFromStatus() {
        guard shouldTrack() else { return }
        TelemetryDeck.signal("item.viewed.from.status")
        logger.debug("Tracked item view from status")
    }

    // MARK: - Mark Events

    func trackMarkDelete(itemId: String, category: ItemCategory, shelfType: ShelfType) {
        guard shouldTrack() else { return }
        let parameters: [String: String] = [
            "itemId": itemId,
            "category": category.rawValue,
            "shelfType": shelfType.rawValue
        ]
        TelemetryDeck.signal("mark.delete", parameters: parameters)
        logger.debug("Tracked mark delete: \(itemId)")
    }

    func trackMarkSubmit(itemId: String, category: ItemCategory, shelfType: ShelfType, postToFediverse: Bool? = nil, changeTime: Bool? = nil, isRated: Bool? = nil) {
        guard shouldTrack() else { return }
        var parameters: [String: String] = [
            "itemId": itemId,
            "category": category.rawValue,
            "shelfType": shelfType.rawValue
        ]
        if let postToFediverse = postToFediverse {
            parameters["postToFediverse"] = postToFediverse.description
        }
        if let changeTime = changeTime {
            parameters["changeTime"] = changeTime.description
        }
        if let isRated = isRated {
            parameters["isRated"] = isRated.description
        }
        TelemetryDeck.signal("mark.submit", parameters: parameters)
        logger.debug("Tracked mark submit: \(itemId)")
    }

    // MARK: - Mastodon Status Events

    func trackMastodonStatusLike(statusId: String? = nil) {
        guard shouldTrack() else { return }
        var parameters: [String: String] = [:]
        if let statusId = statusId {
            parameters["statusId"] = statusId
        }
        TelemetryDeck.signal("mastodon.status.like", parameters: parameters)
        logger.debug("Tracked mastodon status like: \(statusId ?? "none")")
    }

    func trackMastodonStatusReply(statusId: String? = nil) {
        guard shouldTrack() else { return }
        var parameters: [String: String] = [:]
        if let statusId = statusId {
            parameters["statusId"] = statusId
        }
        TelemetryDeck.signal("mastodon.status.reply", parameters: parameters)
        logger.debug("Tracked mastodon status reply: \(statusId ?? "none")")
    }

    func trackMastodonStatusRepost(statusId: String? = nil) {
        guard shouldTrack() else { return }
        var parameters: [String: String] = [:]
        if let statusId = statusId {
            parameters["statusId"] = statusId
        }
        TelemetryDeck.signal("mastodon.status.repost", parameters: parameters)
        logger.debug("Tracked mastodon status repost: \(statusId ?? "none")")
    }

    func trackMastodonStatusBookmark(statusId: String? = nil) {
        guard shouldTrack() else { return }
        var parameters: [String: String] = [:]
        if let statusId = statusId {
            parameters["statusId"] = statusId
        }
        TelemetryDeck.signal("mastodon.status.bookmark", parameters: parameters)
        logger.debug("Tracked mastodon status bookmark: \(statusId ?? "none")")
    }

    func trackMastodonStatusShare(statusId: String? = nil) {
        guard shouldTrack() else { return }
        var parameters: [String: String] = [:]
        if let statusId = statusId {
            parameters["statusId"] = statusId
        }
        TelemetryDeck.signal("mastodon.status.share", parameters: parameters)
        logger.debug("Tracked mastodon status share: \(statusId ?? "none")")
    }

    func trackMastodonStatusDetailView(statusId: String? = nil) {
        guard shouldTrack() else { return }
        var parameters: [String: String] = [:]
        if let statusId = statusId {
            parameters["statusId"] = statusId
        }
        TelemetryDeck.signal("mastodon.status.detail.view", parameters: parameters)
        logger.debug("Tracked mastodon status detail view: \(statusId ?? "none")")
    }

    func trackMastodonStatusItemMark(statusId: String? = nil) {
        guard shouldTrack() else { return }
        var parameters: [String: String] = [:]
        if let statusId = statusId {
            parameters["statusId"] = statusId
        }
        TelemetryDeck.signal("mastodon.status.item.mark", parameters: parameters)
    }

    // MARK: - Mastodon Profile Events

    func trackMastodonProfileView(profileId: String? = nil) {
        guard shouldTrack() else { return }
        var parameters: [String: String] = [:]
        if let profileId = profileId {
            parameters["profileId"] = profileId
        }
        TelemetryDeck.signal("mastodon.profile.view", parameters: parameters)
        logger.debug("Tracked mastodon profile view: \(profileId ?? "none")")
    }

    func trackMastodonProfileFollowingView(profileId: String? = nil) {
        guard shouldTrack() else { return }
        var parameters: [String: String] = [:]
        if let profileId = profileId {
            parameters["profileId"] = profileId
        }
        TelemetryDeck.signal("mastodon.profile.following.view", parameters: parameters)
        logger.debug("Tracked mastodon profile following view: \(profileId ?? "none")")
    }

    func trackMastodonProfileFollowersView(profileId: String? = nil) {
        guard shouldTrack() else { return }
        var parameters: [String: String] = [:]
        if let profileId = profileId {
            parameters["profileId"] = profileId
        }
        TelemetryDeck.signal("mastodon.profile.followers.view", parameters: parameters)
        logger.debug("Tracked mastodon profile followers view: \(profileId ?? "none")")
    }

    // MARK: - Mastodon Timelines Events

    func trackMastodonTimelinesTypeChange(timelineType: MastodonTimelinesFilter, currentTimelineType: MastodonTimelinesFilter? = nil) {
        guard shouldTrack() else { return }
        var parameters: [String: String] = [:]
        parameters["timelineType"] = timelineType.rawValue
        if let currentTimelineType = currentTimelineType {
            parameters["currentTimelineType"] = currentTimelineType.rawValue
        }
        TelemetryDeck.signal("mastodon.timelines.type.change", parameters: parameters)
        logger.debug("Tracked mastodon timelines type change: \(timelineType.rawValue)")
    }

    func trackMastodonTimelinesRefresh() {
        guard shouldTrack() else { return }
        TelemetryDeck.signal("mastodon.timelines.refresh")
        logger.debug("Tracked mastodon timelines refresh")
    }

    // MARK: - Settings Events

    func trackSettingsView() {
        guard shouldTrack() else { return }
        TelemetryDeck.signal("settings.view")
        logger.debug("Tracked settings view")
    }

    func trackSettingsCustomizeDefaultTab(to tab: TabDestination.Configurable) {
        guard shouldTrack() else { return }
        TelemetryDeck.signal("settings.customize.defaultTab", parameters: ["tab": tab.rawValue])
        logger.debug("Tracked settings view customize default tab to: \(tab.rawValue)")
    }

    func trackSettingsSignOut() {
        guard shouldTrack() else { return }
        TelemetryDeck.signal("settings.signOut")
        logger.debug("Tracked settings sign out")
    }

    func trackSettingsClearCache() {
        guard shouldTrack() else { return }
        TelemetryDeck.signal("settings.clearCache")
        logger.debug("Tracked settings clear cache")
    }

    func trackSettingsSwitchAccount(to newInstance: String) {
        guard shouldTrack() else { return }
        TelemetryDeck.signal("settings.switchAccount", parameters: ["newInstance": newInstance])
        logger.debug("Tracked settings switch account to: \(newInstance)")
    }

    func trackSettingsDeleteAccount(from oldInstance: String) {
        guard shouldTrack() else { return }
        TelemetryDeck.signal("settings.deleteAccount", parameters: ["oldInstance": oldInstance])
        logger.debug("Tracked settings delete account from: \(oldInstance)")
    }

    func trackSettingsPurchase() {
        guard shouldTrack() else { return }
        TelemetryDeck.signal("settings.purchase")
        logger.debug("Tracked settings purchase")
    }

    // MARK: - Feature Usage Events
    
    func trackSearch(query: String, category: ItemCategory?) {
        guard shouldTrack() else { return }
        var parameters: [String: String] = ["queryLength": "\(query.count)"]
        if let category = category {
            parameters["category"] = category.rawValue
        }
        TelemetryDeck.signal("search.performed", parameters: parameters)
        logger.debug("Tracked search with category: \(category?.rawValue ?? "none")")
    }
    
    // MARK: - Store Events
    
    func trackPurchaseStart(package: String) {
        guard shouldTrack() else { return }
        TelemetryDeck.signal("store.purchase.started", parameters: ["package": package])
        logger.debug("Tracked purchase start for package: \(package)")
    }
    
    func trackPurchaseComplete(package: String) {
        guard shouldTrack() else { return }
        TelemetryDeck.signal("store.purchase.completed", parameters: ["package": package])
        logger.debug("Tracked purchase completion for package: \(package)")
    }
    
    func trackPurchaseError(package: String, error: String) {
        guard shouldTrack() else { return }
        TelemetryDeck.signal("store.purchase.error", parameters: [
            "package": package,
            "error": error
        ])
        logger.debug("Tracked purchase error for package: \(package)")
    }

    func trackPurchaseRestore() {
        guard shouldTrack() else { return }
        TelemetryDeck.signal("store.purchase.restore")
        logger.debug("Tracked purchase restore")
    }

    func trackPurchaseShowAllPlans(isShow: Bool) {
        guard shouldTrack() else { return }
        TelemetryDeck.signal("store.purchase.showAllPlans", parameters: ["isShow": isShow.description])
        logger.debug("Tracked purchase show all plans: \(isShow)")
    }

    func trackPurchasePackageChange(package: String) {
        guard shouldTrack() else { return }
        TelemetryDeck.signal("store.purchase.package.change", parameters: ["package": package])
        logger.debug("Tracked purchase package change: \(package)")
    }

    func trackPurchaseClose() {
        guard shouldTrack() else { return }
        TelemetryDeck.signal("store.purchase.close")
        logger.debug("Tracked purchase close")
    }
}

