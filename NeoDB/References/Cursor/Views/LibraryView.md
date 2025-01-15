# LibraryView Migration Record

## Overview
LibraryView is a core view that displays user's library items in different shelf types (wishlist, reading, finished).

## Key Components

### LibraryViewModel
- Manages state and data loading for library items
- Handles pagination and caching
- Manages shelf type and category filtering

### Views
1. `LibraryView`
   - Main container view
   - Handles navigation and routing
   - Manages view model lifecycle

2. `ShelfFilterView`
   - Shelf type picker (wishlist/reading/finished)
   - Category filter

3. `ShelfItemView`
   - Individual item display
   - Shows cover image, title, rating, and tags
   - Uses KFImage for image loading

## Implementation Details

### Data Flow
```
LibraryView
└── LibraryViewModel
    ├── loadShelfItems()
    ├── loadNextPage()
    ├── changeShelfType()
    └── changeCategory()
```

### Caching Strategy
- Uses `CacheService` for offline support
- Cache key format: `{instance}_shelf_{shelfType}_{category}`

### Error Handling
- Displays error states with retry option
- Shows detailed network errors when available

## Migration Changes
1. Added proper error handling and loading states
2. Implemented pagination support
3. Added caching for offline access
4. Improved UI with empty states
5. Added pull-to-refresh functionality

## Known Issues
- ServerDate handling needs improvement for proper date formatting
- Need to implement proper item detail navigation
