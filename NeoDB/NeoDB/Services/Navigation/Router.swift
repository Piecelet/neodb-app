//
//  Router.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 1/7/25.
//

import SwiftUI
import OSLog

enum TabSection: String, CaseIterable {
    case home
    case search
    case library
    case profile
}

@MainActor
class Router: ObservableObject {
    @Published var paths: [TabSection: [RouterDestination]] = [:]
    @Published var sheetStack: [SheetDestination] = []
    
    var presentedSheet: SheetDestination? {
        sheetStack.last
    }
    
    @Published var itemToLoad: (any ItemProtocol)?
    @Published var selectedTab: TabSection = .home
    
    private let logger = Logger.router
    
    init() {
        // Initialize empty paths for each tab
        TabSection.allCases.forEach { tab in
            paths[tab] = []
        }
    }
    
    func path(for tab: TabSection) -> Binding<[RouterDestination]> {
        Binding(
            get: { self.paths[tab] ?? [] },
            set: { self.paths[tab] = $0 }
        )
    }
    
    func navigate(to destination: RouterDestination) {
        paths[selectedTab]?.append(destination)
        
        // Store item for loading if navigating to item detail
        if case .itemDetailWithItem(let item) = destination {
            itemToLoad = item
        }
        
        // logger.debug("Navigated to: \(String(describing: destination)) in tab: \(self.selectedTab.rawValue)")
    }
    
    func dismissSheet() {
        if !sheetStack.isEmpty {
            sheetStack.removeLast()
        }
    }
    
    func dismissAllSheets() {
        if !sheetStack.isEmpty {
            sheetStack.removeAll()
        }
    }
    
    func presentSheet(_ destination: SheetDestination) {
        logger.debug("Presenting sheet: \(destination)")
        sheetStack.append(destination)
    }
    
    func handleURL(_ url: URL) -> Bool {
        logger.debug("Handling URL: \(url.absoluteString)")
        
        // Handle deep links and internal navigation
        if url.host == "neodb.social" {
            let pathComponents = url.pathComponents
            
            if pathComponents.contains("items"),
               let id = pathComponents.last {
                navigate(to: .itemDetail(id: id))
                return true
            }
            
            if pathComponents.contains("users"),
               let id = pathComponents.last {
                navigate(to: .userProfile(id: id))
                return true
            }
            
            if pathComponents.contains("status"),
               let id = pathComponents.last {
                navigate(to: .statusDetail(id: id))
                return true
            }
            
            if pathComponents.contains("tags"),
               let tag = pathComponents.last {
                navigate(to: .hashTag(tag: tag))
                return true
            }
        }
        
        return false
    }
    
    func handleStatus(status: MastodonStatus, url: URL) -> Bool {
        logger.debug("Handling status URL: \(url.absoluteString)")
        
        let pathComponents = url.pathComponents
        
        // Handle hashtags
        if pathComponents.contains("tags"),
           let tag = pathComponents.last {
            navigate(to: .hashTag(tag: tag))
            return true
        }
        
        return false
    }
} 
