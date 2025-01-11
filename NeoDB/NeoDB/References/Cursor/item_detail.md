# Item Detail Implementation

## Overview
The item detail system handles various types of media items including books, movies, TV shows (and their seasons/episodes), music, games, etc.

## Features
1. Modern UI Design
   - Clean, minimalist layout
   - Apple HIG compliant
   - Consistent typography
   - Subtle visual hierarchy
   - Efficient use of space
   - Focused content presentation

2. Content Organization
   - Header with key information
   - Sheet-based full metadata
   - Concise description
   - Streamlined actions
   - Contextual external links

3. Component Structure
   - ItemHeaderView: Title, cover, rating, preview metadata
   - MetadataSheet: Full item details
   - ExpandableDescriptionView: Collapsible description
   - ItemActionsView: Primary and secondary actions

4. Caching System
   - Hybrid memory and disk caching using Cache library
   - Type-safe caching for each media type
   - Memory cache expiry: 30 minutes
   - Disk cache expiry: 24 hours
   - Memory cache limit: 10MB
   - Disk cache limit: 50MB per type
   - Automatic cache cleanup for expired items
   - Cache-then-network strategy for immediate response
   - Background refresh for cached data
   - Optimistic UI updates with loading states

## Layout Guidelines
1. Header Section
   - Cover image (100pt width, 2:3 ratio)
   - Title in title3 style
   - Rating with subtle star icon
   - Preview metadata (3 items)
   - "Show All Details" button

2. Metadata Sheet
   - Full-screen modal presentation
   - List-based layout
   - Label width: 80pt
   - Multi-line value support
   - Navigation bar with Done button

3. Description Section
   - Section title in headline style
   - Three-line preview
   - Expandable content
   - "Read More" button

4. Actions Section
   - Primary action (Add to Shelf)
   - Secondary actions (Share, Links)
   - Consistent button styles

## Typography
1. Title: `.title3`, `.semibold`
2. Metadata: `.footnote`
3. Section Headers: `.headline`
4. Description: `.body`
5. Buttons: System default

## Spacing
1. Vertical Component Spacing: 16pt
2. Horizontal Padding: 16pt
3. Metadata Item Spacing: 4pt
4. Button Padding: 12pt (primary), 8pt (secondary)

## Caching Strategy

The item detail feature implements a "cache-then-network" strategy for optimal user experience:

### Cache Hit Scenario
1. Check cache for requested item
2. If found in cache:
   - Immediately return cached data to UI
   - Trigger background refresh to update cache
   - UI will update if new data differs from cache

### Cache Miss Scenario
1. Check cache for requested item
2. If not found in cache:
   - Fetch data from network
   - Store in cache
   - Return to UI
   - No background refresh needed (data is fresh)

### Cache Configuration
- Memory Cache:
  - Expiry: 30 minutes
  - Count Limit: 50 items
  - Size Limit: 10MB

- Disk Cache:
  - Expiry: 24 hours
  - Size Limit: 50MB per category
  - Separate storage for each item type (book, movie, etc.)

## Implementation Details

### Service Layer
```swift
func fetchItemDetail(id: String, category: ItemCategory) async throws -> any ItemDetailProtocol {
    // Try cache first
    if let cachedItem = try? getCachedItem(id: id, category: category) {
        // Return cached data and refresh in background
        Task {
            await refreshItemInBackground(id: id, category: category)
        }
        return cachedItem
    }
    
    // If no cache, fetch from network
    let item = try await fetchItemFromNetwork(id: id, category: category)
    try? cacheItem(item, id: id, category: category)
    return item
}
```

### ViewModel Layer
```swift
func loadItem(id: String, category: ItemCategory) {
    // Cancel existing task
    currentTask?.cancel()
    
    // Skip if already loaded
    if loadedItemId == id, item != nil {
        return
    }
    
    // Only show loading if no cached data
    isLoading = item == nil
    error = nil
    
    let task = Task {
        do {
            let loadedItem = try await itemDetailService.fetchItemDetail(id: id, category: category)
            if !Task.isCancelled {
                item = loadedItem
                loadedItemId = id
            }
        } catch {
            if !Task.isCancelled {
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
```

## Loading States

The UI reflects different loading states:
1. Initial Load (no cache):
   - Shows full loading indicator
   - Displays content when network request completes

2. Cached Data Available:
   - Immediately shows cached content
   - Shows refresh indicator during background update
   - Updates content if new data differs

## Error Handling

1. Cache Errors:
   - Non-fatal: continues to network request
   - Logs error but doesn't expose to user

2. Network Errors:
   - Shows error message if no cached data
   - Keeps showing cached data if available
   - Logs detailed error information

## Recent Changes

1. **Loading State Improvements**
   - Fixed double fetching issue while preserving refresh indicator
   - Improved refresh indicator timing in ViewModel
   - Added proper refresh state management for error cases
   - Enhanced user feedback during data loading

2. **Optimized Refresh Logic**
   - Eliminated unnecessary double fetch when no cache exists
   - Background refresh only triggered for cache hits
   - Improved loading state management

3. **Cache Management**
   - Separate storage for each content type
   - Configurable expiry times
   - Memory and disk cache limits

4. **Error Handling**
   - Better error messages
   - Improved error logging
   - Graceful fallback to cached data

## Best Practices
1. Visual Design
   - Use system colors and fonts
   - Maintain consistent spacing
   - Follow platform conventions
   - Keep UI elements subtle
   - Focus on content

2. Layout
   - Group related information
   - Use progressive disclosure
   - Maintain clear hierarchy
   - Optimize for readability
   - Consider different screen sizes

3. Interaction
   - Clear primary actions
   - Logical button placement
   - Intuitive gestures
   - Responsive feedback
   - Accessible controls

4. Caching Strategy
   - Use memory cache for frequently accessed items
   - Persist to disk for longer-term storage
   - Clear expired items automatically
   - Handle cache misses gracefully
   - Implement type-safe caching
   - Show cached content immediately
   - Refresh data in background
   - Update UI optimistically
   - Handle loading states appropriately
   - Maintain data consistency

## Future Improvements
- Enhanced image loading states
- Dynamic type support
- Accessibility improvements
- Dark mode refinements
- Animation polish
- Landscape optimization
- iPad layout adaptation
- Custom transitions
- Rich previews
- Social sharing enhancements 