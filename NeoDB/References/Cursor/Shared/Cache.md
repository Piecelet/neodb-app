# Cache System Design

## Overview
The NeoDB app implements a unified caching system to improve performance and user experience by storing frequently accessed data locally. The system is designed to be type-safe, maintainable, and consistent across the application.

## Core Components

### CacheService Extension
- Provides a unified interface for all caching operations
- Implements type-safe caching through generic methods
- Manages cache keys through a centralized `Keys` enum

### Key Management
The `Keys` enum provides standardized key generation for different data types:
- Items: `item_[id]`
- Users: `[instance]_user`
- Marks: `marks_[instance]_[shelfType]`
- Gallery: `gallery_[instance]`

## Caching Operations

### Items
- `cacheItem(_:id:category:)`: Caches items based on their category type
- `retrieveItem(id:category:)`: Retrieves cached items
- `removeItem(id:category:)`: Removes items from cache
- Supports multiple item types: Book, Movie, TV, Music, Game, etc.

### Users
- `cacheUser(_:instance:)`: Caches user data for specific instances
- `retrieveUser(instance:)`: Retrieves cached user data
- `removeUser(instance:)`: Removes user data from cache

### Marks
- `cacheMarks(_:instance:shelfType:)`: Caches marks with optional shelf type filtering
- `retrieveMarks(instance:shelfType:)`: Retrieves cached marks
- `removeMarks(instance:shelfType:)`: Removes marks from cache

### Gallery
- `cacheGallery(_:instance:)`: Caches gallery results
- `retrieveGallery(instance:)`: Retrieves cached gallery data
- `removeGallery(instance:)`: Removes gallery data from cache

## Best Practices

### Key Generation
- Use the `Keys` enum for all key generation
- Follow the established naming pattern for consistency
- Include necessary identifiers (instance, ID, type) in keys

### Error Handling
- All cache operations are throwing functions
- Handle cache misses gracefully
- Implement proper error handling in ViewModels

### Type Safety
- Use generic methods for type-safe caching
- Implement proper type checking for item categories
- Maintain consistent types between caching and retrieval

## Update Records

### January 20, 2024
- Initial implementation of unified cache system
- Added centralized key management through `Keys` enum
- Implemented type-safe caching operations for all data types

### January 21, 2024
- Fixed TVSeason and TVEpisode caching
- Ensured type consistency between ItemSchema.make and caching operations
- Enhanced error handling in cache operations

## Future Improvements

### Planned
- Implement cache expiration policies
- Add cache size management
- Consider implementing a cache warming strategy
- Add support for batch operations

### Under Consideration
- Cache compression for large datasets
- Offline-first caching strategy
- Background cache cleanup
- Cache analytics and monitoring
