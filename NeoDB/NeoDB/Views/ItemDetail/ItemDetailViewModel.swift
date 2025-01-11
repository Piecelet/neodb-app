import Foundation
import OSLog

@MainActor
class ItemDetailViewModel: ObservableObject {
    private let itemDetailService: ItemDetailService
    private let logger = Logger.view
    private var loadedItemId: String?
    private var currentTask: Task<Void, Never>?
    
    @Published var item: (any ItemDetailProtocol)?
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var error: Error?
    @Published var showError = false
    
    init(itemDetailService: ItemDetailService) {
        self.itemDetailService = itemDetailService
    }
    
    func loadItem(id: String, category: ItemCategory) {
        // Cancel any existing task
        currentTask?.cancel()
        
        // Skip if already loaded and not refreshing
        if loadedItemId == id, item != nil {
            return
        }
        
        isLoading = item == nil // Only show loading if we don't have cached data
        error = nil
        
        let task = Task {
            do {
                logger.debug("Loading item: \(id) of category: \(category.rawValue)")
                
                // Try to get item (either from cache or network)
                let loadedItem = try await itemDetailService.fetchItemDetail(id: id, category: category)
                
                if !Task.isCancelled {
                    item = loadedItem
                    loadedItemId = id
                }
            } catch {
                if !Task.isCancelled {
                    logger.error("Failed to load item: \(error.localizedDescription)")
                    self.error = error
                    self.showError = true
                }
            }
            
            if !Task.isCancelled {
                isLoading = false
            }
        }
        
        currentTask = task
    }
    
    func loadItem(item: ItemSchema) {
        // Cancel any existing task
        currentTask?.cancel()
        
        // Skip if already loaded and not refreshing
        if loadedItemId == item.uuid, self.item != nil {
            return
        }
        
        isLoading = self.item == nil // Only show loading if we don't have cached data
        error = nil
        
        let task = Task {
            do {
                logger.debug("Loading item details for: \(item.displayTitle)")
                
                // Try to get item (either from cache or network)
                let loadedItem = try await itemDetailService.fetchItemDetail(id: item.uuid, category: item.category)
                
                if !Task.isCancelled {
                    self.item = loadedItem
                    loadedItemId = item.uuid
                }
            } catch {
                if !Task.isCancelled {
                    logger.error("Failed to load item details: \(error.localizedDescription)")
                    self.error = error
                    self.showError = true
                }
            }
            
            if !Task.isCancelled {
                isLoading = false
            }
        }
        
        currentTask = task
    }
    
    var displayTitle: String {
        item?.displayTitle ?? ""
    }
    
    var coverImageURL: URL? {
        guard let urlString = item?.coverImageUrl else { return nil }
        return URL(string: urlString)
    }
    
    var rating: String {
        if let rating = item?.rating {
            return String(format: "%.1f", rating)
        }
        return "N/A"
    }
    
    var ratingCount: String {
        if let count = item?.ratingCount {
            return "\(count) ratings"
        }
        return ""
    }
    
    var description: String {
        item?.description ?? ""
    }
    
    var externalLinks: [URL] {
        item?.externalResources?.compactMap { URL(string: $0.url) } ?? []
    }
    
    func getKeyMetadata(for item: any ItemDetailProtocol) -> [(label: String, value: String)] {
        switch item {
        case let book as EditionSchema:
            return [
                ("Author", book.author.joined(separator: ", ")),
                ("Year", book.pubYear.map { String($0) } ?? ""),
                ("Publisher", book.pubHouse ?? ""),
                ("ISBN", book.isbn ?? ""),
                ("Pages", book.pages.map { "\($0)" } ?? ""),
                ("Language", book.language.joined(separator: ", "))
            ]
        case let movie as MovieSchema:
            return [
                ("Director", movie.director.joined(separator: ", ")),
                ("Year", movie.year.map { String($0) } ?? ""),
                ("Genre", movie.genre.joined(separator: ", ")),
                ("Cast", movie.actor.joined(separator: ", ")),
                ("Duration", movie.duration ?? ""),
                ("Language", movie.language.joined(separator: ", "))
            ]
        case let show as TVShowSchema:
            return [
                ("Director", show.director.joined(separator: ", ")),
                ("Year", show.year.map { String($0) } ?? ""),
                ("Genre", show.genre.joined(separator: ", ")),
                ("Cast", show.actor.joined(separator: ", ")),
                ("Episodes", show.episodeCount.map { String($0) } ?? ""),
                ("Language", show.language.joined(separator: ", "))
            ]
        case let season as TVSeasonSchema:
            return [
                ("Season", season.seasonNumber.map { String($0) } ?? ""),
                ("Episodes", season.episodeCount.map { String($0) } ?? ""),
                ("Director", season.director.joined(separator: ", ")),
                ("Year", season.year.map { String($0) } ?? ""),
                ("Genre", season.genre.joined(separator: ", "))
            ]
        case let episode as TVEpisodeSchema:
            return [
                ("Episode", episode.episodeNumber.map { String($0) } ?? ""),
                ("Title", episode.title),
                ("Parent", episode.parentUuid ?? "")
            ]
        case let game as GameSchema:
            return [
                ("Developer", game.developer.joined(separator: ", ")),
                ("Publisher", game.publisher.joined(separator: ", ")),
                ("Platform", game.platform.joined(separator: ", ")),
                ("Genre", game.genre.joined(separator: ", ")),
                ("Release", game.releaseDate.map { String($0) } ?? "")
            ]
        case let album as AlbumSchema:
            return [
                ("Artist", album.artist.joined(separator: ", ")),
                ("Genre", album.genre.joined(separator: ", ")),
                ("Company", album.company.joined(separator: ", ")),
                ("Release", album.releaseDate.map { String($0) } ?? ""),
                ("Duration", album.duration.map { String($0) } ?? "")
            ]
        case let podcast as PodcastSchema:
            return [
                ("Host", podcast.host.joined(separator: ", ")),
                ("Genre", podcast.genre.joined(separator: ", ")),
                ("Language", podcast.language.joined(separator: ", "))
            ]
        case let performance as PerformanceSchema:
            return [
                ("Director", performance.director.joined(separator: ", ")),
                ("Cast", performance.performer.joined(separator: ", ")),
                ("Genre", performance.genre.joined(separator: ", ")),
                ("Language", performance.language.joined(separator: ", ")),
                ("Opening", performance.openingDate ?? ""),
                ("Closing", performance.closingDate ?? "")
            ]
        default:
            return []
        }
    }
} 