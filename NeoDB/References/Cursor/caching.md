# Caching System Implementation

## Overview
NeoDB implements a unified caching system using the Cache library to provide consistent caching behavior across the app. The system supports both memory and disk caching with type-safe storage for different data types.

## Features
1. Hybrid Caching
   - Memory cache for fast access
   - Disk cache for persistence
   - Automatic cache cleanup
   - Type-safe storage
   - Configurable expiry times
   - Size and count limits

2. Cache Configuration
   - Memory Cache:
     - Expiry: 30 minutes
     - Count Limit: 50 items per type
     - Size Limit: 10MB per type
   - Disk Cache:
     - Expiry: 24 hours
     - Size Limit: 50MB per type
     - Separate storage for each type

3. Cache Categories
   - Items (books, movies, etc.)
   - User Profiles
   - Timelines
   - Shelves
   - Status Updates

## Implementation Details

### Service Layer
```swift
// CacheService.swift
@MainActor
class CacheService {
    private let logger = Logger.data
    
    // Default configurations
    private let defaultMemoryConfig = MemoryConfig(
        expiry: .date(Date().addingTimeInterval(30 * 60)), // 30 minutes
        countLimit: 50,
        totalCostLimit: 10 * 1024 * 1024 // 10 MB
    )
    
    private let defaultDiskConfig = DiskConfig(
        name: "NeoDB",
        expiry: .date(Date().addingTimeInterval(24 * 60 * 60)), // 24 hours
        maxSize: 50 * 1024 * 1024 // 50 MB
    )
    
    // Type-safe storage instances
    private var storages: [String: Any] = [:]
    
    // Create storage for a specific type
    func storage<T: Codable>(for type: T.Type, name: String) throws -> Storage<String, T> {
        if let existing = storages[name] as? Storage<String, T> {
            return existing
        }
        
        let diskConfig = DiskConfig(
            name: name,
            expiry: defaultDiskConfig.expiry,
            maxSize: defaultDiskConfig.maxSize
        )
        
        let storage = try Storage(
            diskConfig: diskConfig,
            memoryConfig: defaultMemoryConfig,
            transformer: TransformerFactory.forCodable(ofType: T.self)
        )
        
        storages[name] = storage
        return storage
    }
    
    // Generic methods for cache operations
    func cache<T: Codable>(_ item: T, forKey key: String, type: T.Type) async throws {
        let storage = try storage(for: type, name: String(describing: type))
        try storage.setObject(item, forKey: key)
        logger.debug("Cached item of type \(type) with key: \(key)")
    }
    
    func retrieve<T: Codable>(forKey key: String, type: T.Type) async throws -> T? {
        let storage = try storage(for: type, name: String(describing: type))
        let item = try storage.object(forKey: key)
        logger.debug("Retrieved item of type \(type) with key: \(key)")
        return item
    }
    
    func remove<T: Codable>(forKey key: String, type: T.Type) async throws {
        let storage = try storage(for: type, name: String(describing: type))
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
```

### Usage Example
```swift
// In a service class
class ItemDetailService {
    private let cacheService: CacheService
    
    func fetchItemDetail(id: String, category: ItemCategory) async throws -> any ItemDetailProtocol {
        // Try cache first
        if let cachedItem = try? await cacheService.retrieve(
            forKey: id,
            type: category.modelType
        ) {
            // Return cached data and refresh in background
            Task {
                await refreshItemInBackground(id: id, category: category)
            }
            return cachedItem
        }
        
        // If no cache, fetch from network
        let item = try await fetchItemFromNetwork(id: id, category: category)
        try? await cacheService.cache(item, forKey: id, type: type(of: item))
        return item
    }
}
```

## Best Practices
1. Cache Management
   - Use appropriate expiry times
   - Implement size limits
   - Clear expired items regularly
   - Handle cache misses gracefully

2. Error Handling
   - Cache errors should be non-fatal
   - Log cache operations
   - Fallback to network requests
   - Preserve type safety

3. Performance
   - Use memory cache for frequent access
   - Implement background cleanup
   - Avoid caching large objects
   - Monitor cache size

4. Data Consistency
   - Update cache after network requests
   - Clear cache on logout
   - Handle version migrations
   - Validate cached data

## Recent Changes
1. Initial Implementation
   - Created unified CacheService
   - Added type-safe storage
   - Implemented generic cache operations
   - Added logging integration

2. Configuration
   - Set default expiry times
   - Configured size limits
   - Added per-type storage
   - Implemented cleanup methods 