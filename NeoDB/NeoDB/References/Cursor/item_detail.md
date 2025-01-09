# Item Detail Feature Implementation

## Overview
Implementing item detail page functionality to display detailed information about books, movies, TV shows, games, and other media types.

## API Endpoints
From catalog.yaml:
- GET `/api/book/{uuid}` - Get book details
- GET `/api/movie/{uuid}` - Get movie details
- GET `/api/tv/{uuid}` - Get TV show details
- GET `/api/tv/season/{uuid}` - Get TV season details
- GET `/api/tv/episode/{uuid}` - Get TV episode details
- GET `/api/podcast/{uuid}` - Get podcast details
- GET `/api/album/{uuid}` - Get album details
- GET `/api/game/{uuid}` - Get game details
- GET `/api/performance/{uuid}` - Get performance details

## Models
1. Core Models (Models.swift)
   - ItemSchema - Base item model with common fields
   - MarkSchema - User marks/ratings with Identifiable support
   - LocalizedTitleSchema - Localized text content
   - ExternalResourceSchema - External resource links
   - ItemCategory - Media type enumeration
   - ShelfType - Shelf categories enumeration
2. Service Models
   - ItemDetailService - Handles API calls for different item types
   - ItemDetailViewModel - Manages item detail state and user interactions
3. View Models
   - ItemDetailView - Main view for displaying item details
   - Components:
     - ItemHeaderView - Title, cover image, rating
     - ItemMetadataView - Genre, release date, etc.
     - ItemCrewView - Directors, actors, authors
     - ItemActionsView - Add to shelf, share

## Features
- Dynamic layout based on item type
- Cover image with zoom capability
- Rating and review system
- Add to shelf functionality
- Share functionality
  - Simple URL sharing
  - Safe URL handling with optional binding
- Related items
- User reviews/comments
- External links

## Error Handling
- Network errors
  - Invalid UUID
  - Server errors
  - Timeout
- Data parsing errors
  - Missing fields
  - Invalid formats
- Loading states
  - Initial loading
  - Content loading
  - Action loading
- Empty states
  - Missing data
  - No reviews
  - No related items
- URL handling
  - Safe URL construction
  - Fallback for invalid URLs

## Implementation Plan
1. Create ItemDetailService
   - API endpoints for each item type
   - Response parsing
   - Error handling
2. Create ItemDetailViewModel
   - State management
   - User actions
   - Data loading
3. Create ItemDetailView
   - Layout structure
   - Type-specific components
   - Loading states
4. Implement components
   - Header component
   - Metadata component
   - Actions component
     - Safe URL handling in ShareLink
     - Optional binding for URLs
5. Add navigation integration
   - Router updates
   - Deep linking support
   - Sharing functionality

## Router Integration
```swift
// Existing routes
case itemDetail(id: String)
case itemDetailWithItem(item: ItemSchema)

// Navigation
router.navigate(to: .itemDetail(id: item.uuid))
router.navigate(to: .itemDetailWithItem(item: item))
```

## Recent Changes
1. Consolidated Models
   - Moved all shared models to Models.swift
   - Added Identifiable support to MarkSchema
   - Standardized naming (LocalizedTitleSchema, ExternalResourceSchema)
   - Removed duplicate definitions from ShelfModels.swift
2. Added PodcastSchema to Models.swift
   - Basic information fields
   - Podcast-specific fields (host, episodes, RSS)
   - Implemented ItemDetailProtocol
3. Fixed ShareLink implementation in ItemActionsView
   - Simplified URL sharing
   - Added safe URL handling with optional binding
   - Removed complex preview configuration
4. Updated error handling
   - Added URL validation
   - Improved error messages
   - Added fallback UI states

## Future Improvements
- Offline support
- Rich media content
- Advanced sharing options
  - Custom preview images
  - Rich text descriptions
- User collections
- Recommendations
- Social features integration
- Analytics tracking 