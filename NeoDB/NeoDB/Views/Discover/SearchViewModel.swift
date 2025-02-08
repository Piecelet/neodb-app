//
//  SearchViewModel.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Foundation
import OSLog
import UIKit

@MainActor
class SearchViewModel: ObservableObject {
    private let logger = Logger.views.discover.search
    private let cacheService = CacheService.shared
    private var searchTask: Task<Void, Never>?
    private var searchDebounceTask: Task<Void, Never>?
    private let debounceInterval: TimeInterval = 0.5
     let minSearchLength = 2
    private let maxRecentSearches = 10
    
    enum SearchState: Equatable {
        case idle
        case searching
        case noResults
        case suggestions([ItemSchema])  // For hover/suggestion state
        case results([ItemSchema])      // For confirmed search state
        case error(Error)
        
        static func == (lhs: SearchState, rhs: SearchState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle):
                return true
            case (.searching, .searching):
                return true
            case (.noResults, .noResults):
                return true
            case (.suggestions(let lhsItems), .suggestions(let rhsItems)):
                return lhsItems.map { $0.uuid } == rhsItems.map { $0.uuid }
            case (.results(let lhsItems), .results(let rhsItems)):
                return lhsItems.map { $0.uuid } == rhsItems.map { $0.uuid }
            case (.error, .error):
                return true
            default:
                return false
            }
        }
    }
    
    @Published var searchText = "" {
        didSet {
            if oldValue != searchText {
                if forceSearch {
                    forceSearch = false
                } else {
                    isConfirmedSearch = false
                debouncedSearch()
                }
            }
        }
    }
    @Published private(set) var searchState: SearchState = .idle
    @Published var currentPage = 1
    @Published var hasMorePages = false
    @Published private(set) var recentSearches: [String] = []
    @Published var selectedCategory: ItemCategory.searchable = .allItems
    @Published var loadingStartTime: Date?
    @Published var showLoading = false
    @Published var isConfirmedSearch = false
    @Published var isShowingURLInput = false
    @Published var urlInput = ""
    @Published var isLoadingURL = false
    @Published var urlError: Error?
    
    var accountsManager: AppAccountsManager?

    private var forceSearch : Bool = false
    
    init() {
        loadRecentSearches()
    }
    
    private func debouncedSearch() {
        searchDebounceTask?.cancel()
        
        // Clear results if search text is empty
        if searchText.isEmpty {
            searchState = .idle
            return
        }
        
        // Check minimum search length
        if searchText.count < minSearchLength {
            return
        }
        
        searchDebounceTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(debounceInterval * 1_000_000_000))
            if !Task.isCancelled {
                currentPage = 1
                await search(confirmed: false)
            }
        }
    }
    
    func confirmSearch(searchText: String? = nil) async {
        if let searchText = searchText {
        forceSearch = true
            self.searchText = searchText
        }
        forceSearch = false
        isConfirmedSearch = true
        currentPage = 1
        await search(confirmed: true)
    }
    
    func search(confirmed: Bool = false) async {
        searchTask?.cancel()
        
        guard !searchText.isEmpty else {
            searchState = .idle
            return
        }
        
        guard searchText.count >= minSearchLength else {
            return
        }
        
        // Add to recent searches only for confirmed searches
        if confirmed {
            addToRecentSearches(searchText)
        }
        
        searchTask = Task {
            await performSearch(confirmed: confirmed)
        }
    }
    
    private func addToRecentSearches(_ query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }
        
        // Remove if already exists
        recentSearches.removeAll { $0.lowercased() == trimmedQuery.lowercased() }
        
        // Add to the beginning
        recentSearches.insert(trimmedQuery, at: 0)
        
        // Keep only the most recent searches
        if recentSearches.count > maxRecentSearches {
            recentSearches = Array(recentSearches.prefix(maxRecentSearches))
        }
        
        // Save to UserDefaults
        saveRecentSearches()
    }
    
    private func loadRecentSearches() {
        if let instance = accountsManager?.currentAccount.instance {
            let key = "recent_searches_\(instance)"
            recentSearches = UserDefaults.standard.stringArray(forKey: key) ?? []
        }
    }
    
    private func saveRecentSearches() {
        if let instance = accountsManager?.currentAccount.instance {
            let key = "recent_searches_\(instance)"
            UserDefaults.standard.set(recentSearches, forKey: key)
        }
    }
    
    func clearRecentSearches() {
        recentSearches.removeAll()
        saveRecentSearches()
    }
    
    func removeRecentSearch(_ query: String) {
        recentSearches.removeAll { $0 == query }
        saveRecentSearches()
    }
    
    func loadMore() {
        guard case .results = searchState, !Task.isCancelled, hasMorePages else { return }
        
        currentPage += 1
        searchTask = Task {
            await performSearch(append: true)
        }
    }
    
    private func performSearch(append: Bool = false, confirmed: Bool = false) async {
        guard let accountsManager = accountsManager else { return }
        
        if !append {
            loadingStartTime = Date()
            searchState = .searching
            
            // Start a timer to show loading after 0.5s
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                if case .searching = searchState {
                    showLoading = true
                }
            }
        }
        
        do {
            // Try to get cached search results first
            if !append {
                if let cachedResult = try? await cacheService.retrieveSearch(
                    query: searchText,
                    page: currentPage,
                    instance: accountsManager.currentAccount.instance
                ) {
                    if !Task.isCancelled {
                        updateSearchResults(cachedResult, append: append, confirmed: confirmed)
                    }
                }
            }
            
            guard !Task.isCancelled else { return }
            
            let endpoint = CatalogEndpoint.search(
                query: searchText,
                category: selectedCategory != .allItems ? selectedCategory.itemCategory : nil,
                page: currentPage
            )
            
            let result = try await accountsManager.currentClient.fetch(
                endpoint, type: SearchResult.self)
            
            if !Task.isCancelled {
                updateSearchResults(result, append: append, confirmed: confirmed)
                showLoading = false
                
                // Cache only if it's not appending
                if !append {
                    try? await cacheService.cacheSearch(
                        result,
                        query: searchText,
                        page: currentPage,
                        instance: accountsManager.currentAccount.instance
                    )
                }
            }
            
        } catch {
            if !Task.isCancelled {
                searchState = .error(error)
                showLoading = false
                logger.error("Search failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func updateSearchResults(_ result: SearchResult, append: Bool, confirmed: Bool) {
        if append {
            if case .results(let existingItems) = searchState {
                let updatedItems = existingItems + result.data
                searchState = updatedItems.isEmpty ? .noResults : .results(updatedItems)
            }
        } else {
            if result.data.isEmpty {
                searchState = .noResults
            } else if confirmed {
                searchState = .results(result.data)
            } else {
                // Filter out duplicates based on title for suggestions
                var uniqueTitles = Set<String>()
                let uniqueItems = result.data.filter { item in
                    let title = (item.displayTitle ?? item.title ?? "").lowercased()
                    return uniqueTitles.insert(title).inserted
                }
                searchState = .suggestions(uniqueItems)
            }
        }
        hasMorePages = currentPage < result.pages
    }
    
    func cleanup() {
        searchTask?.cancel()
        searchDebounceTask?.cancel()
        searchTask = nil
        searchDebounceTask = nil
        searchText = ""
    }
} 
