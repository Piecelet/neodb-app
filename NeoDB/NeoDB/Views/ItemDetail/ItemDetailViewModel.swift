import Foundation
import OSLog

@MainActor
class ItemDetailViewModel: ObservableObject {
    private let itemDetailService: ItemDetailService
    private let logger = Logger(subsystem: "app.neodb", category: "ItemDetail")
    
    @Published var item: (any ItemDetailProtocol)?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showError = false
    
    init(itemDetailService: ItemDetailService) {
        self.itemDetailService = itemDetailService
    }
    
    func loadItem(id: String, category: ItemCategory) {
        isLoading = true
        error = nil
        
        Task {
            do {
                logger.debug("Loading item: \(id) of category: \(category.rawValue)")
                item = try await itemDetailService.fetchItemDetail(id: id, category: category)
            } catch {
                logger.error("Failed to load item: \(error.localizedDescription)")
                self.error = error
                self.showError = true
            }
            isLoading = false
        }
    }
    
    func loadItem(item: ItemSchema) {
        isLoading = true
        error = nil
        
        Task {
            do {
                logger.debug("Loading item details for: \(item.displayTitle)")
                self.item = try await itemDetailService.fetchItemDetail(id: item.uuid, category: item.category)
            } catch {
                logger.error("Failed to load item details: \(error.localizedDescription)")
                self.error = error
                self.showError = true
            }
            isLoading = false
        }
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
} 