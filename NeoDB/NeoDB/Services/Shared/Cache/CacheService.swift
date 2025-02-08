import Foundation
import OSLog
import Cache

@MainActor
class CacheService {
    static let shared = CacheService()
    
    private init() {}
    
    private let logger = Logger.cache
    
    private let diskConfig = DiskConfig(
        name: "NeoDB",
        expiry: .date(Date().addingTimeInterval(7 * 24 * 60 * 60)), // 7 days
        maxSize: 512 * 1024 * 1024 // 512 MB
    )
    
    private let memoryConfig = MemoryConfig(
        expiry: .date(Date().addingTimeInterval(12 * 60 * 60)), // 12 hours
        countLimit: 50,
        totalCostLimit: 50 * 1024 * 1024 // 50 MB
    )
    
    private var storages: [String: Any] = [:]
    
    func storage<T: Codable>(for type: T.Type) throws -> Storage<String, T> {
        let name = String(describing: type)
        if let existing = storages[name] as? Storage<String, T> {
            return existing
        }
        
        let storage = try Storage<String, T>(
            diskConfig: diskConfig,
            memoryConfig: memoryConfig,
            fileManager: FileManager.default,
            transformer: TransformerFactory.forCodable(ofType: T.self)
        )
        
        storages[name] = storage
        return storage
    }
    
    func cache<T: Codable>(_ item: T, forKey key: String, type: T.Type) async throws {
        let storage = try storage(for: type)
        try storage.setObject(item, forKey: key)
        logger.debug("Cached item of type \(type) with key: \(key)")
    }
    
    func retrieve<T: Codable>(forKey key: String, type: T.Type) async throws -> T? {
        let storage = try storage(for: type)
        let item = try? storage.object(forKey: key)
        if item != nil {
            logger.debug("Retrieved item of type \(type) with key: \(key)")
        }
        return item
    }
    
    func remove<T: Codable>(forKey key: String, type: T.Type) async throws {
        let storage = try storage(for: type)
        try storage.removeObject(forKey: key)
        logger.debug("Removed item of type \(type) with key: \(key)")
    }
    
    func removeExpired() async {
        for (name, storage) in storages {
            if let typedStorage = storage as? any StorageAware {
                try? typedStorage.removeExpiredObjects()
                logger.debug("Removed expired items from \(name) storage")
            }
        }
    }
    
    func removeAll() async {
        for (name, storage) in storages {
            if let typedStorage = storage as? any StorageAware {
                try? typedStorage.removeAll()
                logger.debug("Cleared all items from \(name) storage")
            }
        }
        storages.removeAll()
    }
} 
