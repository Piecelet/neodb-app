# Shelf Feature Implementation

## Overview
Shelf display functionality in dedicated LibraryView tab for collection management. Supports navigation to item details, filtering, and shelf management.

## API Endpoints
- GET `/api/me/shelf/{type}`
  - Types: wishlist, progress, complete, dropped
  - Optional query params: category, page
  - Returns: PagedMarkSchema

## Models
1. ShelfType enum - Different shelf types (wishlist, progress, complete, dropped)
2. MarkSchema - Individual shelf item data
   ```swift
   struct MarkSchema: Codable {
       let shelfType: ShelfType
       let visibility: Int
       let item: ItemSchema
       let createdTime: Date  // ISO8601 date-time format
       let commentText: String?
       let ratingGrade: Int?
       let tags: [String]
   }
   ```
3. PagedMarkSchema - Paginated response structure
4. ItemSchema - Item details structure

## Date Handling
```swift
// Support multiple ISO8601 date formats
let formatCombinations = [
    ISO8601DateFormatter.Options([.withInternetDateTime, .withFractionalSeconds, .withTimeZone]),
    ISO8601DateFormatter.Options([.withInternetDateTime, .withTimeZone]),
    ISO8601DateFormatter.Options([.withInternetDateTime, .withFractionalSeconds]),
    ISO8601DateFormatter.Options([.withInternetDateTime])
]

// Enhanced error logging for date parsing
logger.error("Failed to parse date string: \(dateString)")
```

## Router Integration

### Destinations
```swift
// Library destinations
case itemDetail(id: String)
case itemDetailWithItem(item: ItemSchema)
case shelfDetail(type: ShelfType)
case userShelf(userId: String, type: ShelfType)

// Sheet destinations
case addToShelf(item: ItemSchema)
case editShelfItem(mark: MarkSchema)
```

### Navigation Examples
```swift
// Navigate to item detail
Button {
    router.navigate(to: .itemDetailWithItem(item: mark.item))
} label: {
    ShelfItemView(mark: mark)
}

// Present add to shelf sheet
router.presentedSheet = .addToShelf(item: item)

// Navigate to user's shelf
router.navigate(to: .userShelf(userId: user.id, type: .wishlist))
```

## Component Structure
- LibraryView/
  - LibraryView.swift (Main view)
  - LibraryViewModel.swift (Business logic)
  - Components/
    - ShelfItemView.swift (Item card)
    - ShelfFilterView.swift (Type/category filters)

## Features
- Shelf type switching (Want to Read, Reading, Completed, Dropped)
- Category filtering (All, Book, Movie, TV, Game)
- Infinite scrolling pagination
- Pull-to-refresh
- Loading states and error handling
- Deep linking support
- Navigation integration

## Error Handling
- Network errors
  - Unauthorized (401)
  - Invalid response
  - Network timeouts
- Data parsing errors
  - Invalid date formats
  - Missing required fields
  - Type mismatches
- Loading states
  - Initial loading
  - Pagination loading
  - Refresh loading
- Empty states
  - No items in shelf
  - No items in category
- Retry mechanisms
  - Auto-retry for network errors
  - Manual refresh option
  - Pagination retry

## Recent Changes
1. Fixed date parsing for shelf items
   - Added support for multiple ISO8601 formats
   - Improved error logging for date parsing failures
   - Added timezone support
2. Enhanced error handling
   - Better error messages
   - Detailed logging
   - Graceful fallbacks
3. Updated documentation
   - Added date format specifications
   - Documented error handling
   - Updated model definitions

## Future Improvements
- Batch actions
- Sorting options
- Search within library
- Enhanced filters
- Statistics view
- Reading progress
- Share functionality
- Export/Import
- Offline support 