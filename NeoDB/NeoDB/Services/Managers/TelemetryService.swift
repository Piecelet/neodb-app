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

@MainActor
class TelemetryService: ObservableObject {
    // MARK: - Singleton
    static let shared = TelemetryService()
    
    private let logger = Logger.services.telemetry.telemetry

    private let config = TelemetryDeck.Config(appID: AppConfig.telemetryDeckAppID)
    
    private init() {
        configure()
    }
    
    private func configure() {
        config.defaultSignalPrefix = "App."
        TelemetryDeck.initialize(config: config)
        logger.debug("TelemetryDeck initialized")
    }

    func updateDefaultUserID(to id: String?) {
        TelemetryDeck.updateDefaultUserID(to: id)
    }

    func updateInstance(to instance: String) {
        config.defaultParameters = { ["instance": instance] }
        TelemetryDeck.initialize(config: config)
        logger.debug("TelemetryDeck initialized with instance: \(instance)")
    }
    
    // MARK: - App Lifecycle Events
    
    func trackAppLaunch() {
        TelemetryDeck.signal("launched")
        logger.debug("Tracked app launch")
    }
    
    // MARK: - Authentication Events
    
    func trackAuthLogin(instance: String? = nil) {
        if let instance = instance {
            TelemetryDeck.signal("auth.login", parameters: ["instance": instance])
        } else {
            TelemetryDeck.signal("auth.login")
        }
        logger.debug("Tracked login for instance: \(instance ?? "unknown")")
    }
    
    func trackAuthLogout(instance: String? = nil) {
        if let instance = instance {
            TelemetryDeck.signal("auth.logout", parameters: ["instance": instance])
        } else {
            TelemetryDeck.signal("auth.logout")
        }
        logger.debug("Tracked logout for instance: \(instance ?? "unknown")")
    }
    
    // MARK: - Navigation Events
    
    func trackTabChange(to tab: TabDestination) {
        TelemetryDeck.signal("navigation.tab", parameters: ["tab": tab.rawValue])
        logger.debug("Tracked tab change to: \(tab.rawValue)")
    }

    // MARK - Discover Events
    func trackSearchSubmit(category: ItemCategory? = nil) {
        var parameters: [String: String] = [:]
        if let category = category {
            parameters["itemCategory"] = category.rawValue
        }
        TelemetryDeck.signal("discover.search.submit", parameters: parameters)
        logger.debug("Tracked search submit with category: \(category?.rawValue ?? "none")")
    }

    func trackSearchCategoryChange(category: ItemCategory? = nil) {
        var parameters: [String: String] = [:]
        if let category = category {
            parameters["itemCategory"] = category.rawValue
        }
        TelemetryDeck.signal("discover.search.category.change", parameters: parameters)
        logger.debug("Tracked search category change to: \(category?.rawValue ?? "none")")
    }

    func trackSearchURLPaste() {
        TelemetryDeck.signal("discover.search.url.paste")
        logger.debug("Tracked search URL paste")
    }

    func trackSearchURLSubmit() {
        TelemetryDeck.signal("discover.search.url.submit")
        logger.debug("Tracked search URL submit")
    }
    
    
    // MARK: - Feature Usage Events
    
    func trackSearch(query: String, category: ItemCategory?) {
        var parameters: [String: String] = ["queryLength": "\(query.count)"]
        if let category = category {
            parameters["category"] = category.rawValue
        }
        TelemetryDeck.signal("search.performed", parameters: parameters)
        logger.debug("Tracked search with category: \(category?.rawValue ?? "none")")
    }
    
    func trackItemView(id: String, category: ItemCategory) {
        TelemetryDeck.signal("item.viewed", parameters: [
            "itemId": id,
            "category": category.rawValue
        ])
        logger.debug("Tracked item view: \(id)")
    }
    
    // MARK: - Store Events
    
    func trackPurchaseStart(package: String) {
        TelemetryDeck.signal("store.purchase.started", parameters: ["package": package])
        logger.debug("Tracked purchase start for package: \(package)")
    }
    
    func trackPurchaseComplete(package: String) {
        TelemetryDeck.signal("store.purchase.completed", parameters: ["package": package])
        logger.debug("Tracked purchase completion for package: \(package)")
    }
    
    func trackPurchaseError(package: String, error: String) {
        TelemetryDeck.signal("store.purchase.error", parameters: [
            "package": package,
            "error": error
        ])
        logger.debug("Tracked purchase error for package: \(package)")
    }
}

