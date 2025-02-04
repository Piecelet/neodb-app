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
    
    private init() {
        configure()
    }
    
    private func configure() {
        let config = TelemetryDeck.Config(appID: AppConfig.telemetryDeckAppID)
        
        // Add default signal prefix for better organization
        config.defaultSignalPrefix = "App."
        
        // Add default parameters that will be included with every signal
        config.defaultParameters = { [
        "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
        "buildNumber": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown",
        "isDebug": "\(AppConfig.isDebug)"
    ] }
        
        TelemetryDeck.initialize(config: config)
        logger.debug("TelemetryDeck initialized")
    }

    func updateDefaultUserID(to id: String?) {
        TelemetryDeck.updateDefaultUserID(to: id)
    }
    
    // MARK: - App Lifecycle Events
    
    func trackAppLaunch() {
        TelemetryDeck.signal("launched")
        logger.debug("Tracked app launch")
    }
    
    // MARK: - Authentication Events
    
    func trackAuthLogin(instance: String? = nil) {
        TelemetryDeck.signal("auth.login", parameters: ["instance": instance ?? "unknown"])
        logger.debug("Tracked login for instance: \(instance ?? "unknown")")
    }
    
    func trackAuthLogout(instance: String? = nil) {
        TelemetryDeck.signal("auth.logout", parameters: ["instance": instance ?? "unknown"])
        logger.debug("Tracked logout for instance: \(instance ?? "unknown")")
    }
    
    // MARK: - Navigation Events
    
    func trackTabChange(to tab: TabSection) {
        TelemetryDeck.signal("navigation.tab", parameters: ["tab": tab.rawValue])
        logger.debug("Tracked tab change to: \(tab.rawValue)")
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

