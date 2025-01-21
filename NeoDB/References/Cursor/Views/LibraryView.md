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
   - Category filter using `ItemCategoryBarView`

3. `ItemCategoryBarView`
   - Horizontal scrollable category filter
   - Uses `ItemCategory.shelfAvailable` for options
   - Features:
     - "All" button stays fixed on the left
     - Buttons collapse when "All" is selected
     - Smooth animations for state changes
     - Auto-scrolling to selected category

4. `ShelfItemView`
   - Individual item display
   - Uses shared components:
     - `ItemCoverView` for cover images
     - `ItemRatingView` for ratings
     - `ItemDescriptionView` for brief info
     - `ItemMarkView` for user marks
   - Consistent styling and layout

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
6. Replaced category filter with new `ItemCategoryBarView`
7. Integrated shared components for consistent UI:
   - ItemCoverView for covers
   - ItemRatingView for ratings
   - ItemDescriptionView for descriptions
   - ItemMarkView for user marks

## Known Issues
- ServerDate handling needs improvement
- Need to implement proper item detail navigation
