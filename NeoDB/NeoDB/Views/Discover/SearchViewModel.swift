//
//  SearchViewModel.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Foundation
import OSLog

@MainActor
class SearchViewModel: ObservableObject {
    private let logger = Logger.views.search
    private let cacheService = CacheService()
    private var searchTask: Task<Void, Never>?
    private var galleryTask: Task<Void, Never>?
    
    @Published var searchText = ""
    @Published var items: [ItemSchema] = []
    @Published var galleryItems: [GalleryResult] = []
    @Published var isLoading = false
    @Published var isLoadingGallery = false
    @Published var error: Error?
    @Published var showError = false
    @Published var currentPage = 1
    @Published var hasMorePages = false
    
    var accountsManager: AppAccountsManager?
    
    func search() {
        searchTask?.cancel()
        
        guard !searchText.isEmpty else {
            items = []
            return
        }
        
        currentPage = 1
        searchTask = Task {
            await performSearch()
        }
    }
    
    func loadGallery() async {
        galleryTask?.cancel()
        
        galleryTask = Task {
            guard let accountsManager = accountsManager else { return }
            
            isLoadingGallery = true
            defer { isLoadingGallery = false }
            
            do {                
                // Try to get cached gallery first
                if let cachedGallery: [GalleryResult] = try? await cacheService.retrieveGallery(instance: accountsManager.currentAccount.instance) {
                    if !Task.isCancelled {
                        galleryItems = cachedGallery
                        logger.debug("Using cached gallery")
                    }
                }
                
                // Fetch fresh data
                let endpoint = CatalogEndpoint.gallery
                let result = try await accountsManager.currentClient.fetch(endpoint, type: [GalleryResult].self)
                if !Task.isCancelled {
                    galleryItems = result
                    // Cache the new results
                    try? await cacheService.cacheGallery(result, instance: accountsManager.currentAccount.instance)
                    logger.debug("Cached new gallery results")
                }
            } catch {
                if case NetworkError.cancelled = error {
                    logger.debug("Gallery loading cancelled")
                    return
                }
                
                self.error = error
                self.showError = true
                logger.error("Gallery loading failed: \(error.localizedDescription)")
            }
        }
        
        await galleryTask?.value
    }
    
    func loadMore() {
        guard !isLoading, hasMorePages else { return }
        
        currentPage += 1
        searchTask = Task {
            await performSearch(append: true)
        }
    }
    
    private func performSearch(append: Bool = false) async {
        guard let accountsManager = accountsManager else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let cacheKey = "\(accountsManager.currentAccount.instance)_search_\(searchText)_\(currentPage)"
            
            // Try to get cached search results first
            if !append, let cachedResults: SearchResult = try? await cacheService.retrieve(forKey: cacheKey, type: SearchResult.self) {
                if !Task.isCancelled {
                    items = cachedResults.data
                    hasMorePages = currentPage < cachedResults.pages
                    logger.debug("Using cached search results for page \(currentPage)")
                    return
                }
            }
            
            let endpoint = CatalogEndpoint.search(query: searchText, page: currentPage)
            let result = try await accountsManager.currentClient.fetch(endpoint, type: SearchResult.self)
            
            if append {
                items.append(contentsOf: result.data)
            } else {
                items = result.data
                // Cache only the first page
                try? await cacheService.cache(result, forKey: cacheKey, type: SearchResult.self)
                logger.debug("Cached search results for page \(currentPage)")
            }
            
            hasMorePages = currentPage < result.pages
        } catch {
            if case NetworkError.cancelled = error {
                logger.debug("Search cancelled")
                return
            }
            
            self.error = error
            self.showError = true
            logger.error("Search failed: \(error.localizedDescription)")
        }
    }
    
    func cleanup() {
        searchTask?.cancel()
        galleryTask?.cancel()
        searchTask = nil
        galleryTask = nil
    }
} 
