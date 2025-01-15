# ItemDetailView Migration Record

## Overview
ItemDetailView displays detailed information about various types of items (books, movies, etc.) with support for different content types and caching.

## Key Components

### ItemDetailViewModel
- Manages state and data loading for item details
- Handles caching and background refresh
- Supports multiple item types (book, movie, tv, etc.)

### Views
1. `ItemDetailView`
   - Main container view
   - Displays item information
   - Handles loading and error states

2. `ItemHeaderView`
   - Shows cover image and basic info
   - Displays rating and metadata

3. `ItemActionsView`
   - Action buttons (add to shelf, share, etc.)
   - Integration with router for navigation
   - Migrated from `AuthService` to `AppAccountsManager` for instance handling
   - Uses `currentAccount.instance` for URL construction

## Implementation Details

### Data Flow
```
ItemDetailView
└── ItemDetailViewModel
    ├── loadItemDetail()
    ├── refreshItemInBackground()
    └── handleItemActions()
```

### Caching Strategy
- Uses `CacheService` for offline support
- Separate caches for different item types
- Background refresh for cached data

### Error Handling
- Displays error states with retry option
- Shows detailed network errors
- Graceful fallback for unsupported item types

## Migration Changes
1. Moved service logic into ViewModel
2. Implemented proper error handling
3. Added background refresh support
4. Improved UI with loading states
5. Added proper type handling for different items
6. Migrated from `AuthService` to `AppAccountsManager`
7. Added UUID extraction from full URLs

## Known Issues
- Need to implement proper action handling
- Cache invalidation strategy needs review 