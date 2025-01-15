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
                let endpoint = CatalogEndpoint.gallery
                let result = try await accountsManager.currentClient.fetch(endpoint, type: [GalleryResult].self)
                if !Task.isCancelled {
                    galleryItems = result
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
            let endpoint = CatalogEndpoint.search(query: searchText, page: currentPage)
            let result = try await accountsManager.currentClient.fetch(endpoint, type: SearchResult.self)
            
            if append {
                items.append(contentsOf: result.data)
            } else {
                items = result.data
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