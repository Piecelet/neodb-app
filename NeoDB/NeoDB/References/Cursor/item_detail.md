# Item Detail Implementation

## Overview
The item detail system handles various types of media items including books, movies, TV shows (and their seasons/episodes), music, games, etc.

## Features
1. Dynamic Layout
   - Type-specific metadata display
   - Conditional UI elements
   - Responsive design
   - Key information preview
   - Detailed metadata sections
   - Expandable content

2. TV Content Hierarchy
   - Show → Season → Episode navigation
   - Parent-child relationships
   - Type-specific API endpoints

3. Metadata Display
   - Key information preview
   - Detailed metadata sections
   - Expandable content

## URL Patterns and API Mapping
1. Basic Item URLs
   - `/~username~/type/id` → `/api/{type}/{id}`
2. TV-specific URLs and API Endpoints
   - `/~username~/tv/id` → `/api/tv/{id}`
   - `/~username~/tv/season/id` → `/api/tv/season/{id}`
   - `/~username~/tv/episode/id` → `/api/tv/episode/{id}`

### TV Content Handling
For TV shows and their components:
1. TV shows: `/~username~/tv/id` → category: `.tv`
2. Seasons: `/~username~/tv/season/id` → category: `.tvSeason`
3. Episodes: `/~username~/tv/episode/id` → category: `.tvEpisode`

The system determines the correct category and API endpoint based on both the base type and subtype:
```swift
if type == "tv" && pathComponents.count >= 5 {
    let subtype = pathComponents[3] // "season" or "episode"
    category = categoryFromType(subtype) // Use subtype for category
}
```

## API Endpoints
Each category maps to a specific API endpoint:
- TV shows: `/api/tv/{id}`
- TV seasons: `/api/tv/season/{id}`
- TV episodes: `/api/tv/episode/{id}`
- Books: `/api/book/{id}`
- Movies: `/api/movie/{id}`
- Podcasts: `/api/podcast/{id}`
- Albums: `/api/album/{id}`
- Games: `/api/game/{id}`
- Performances: `/api/performance/{id}`

## Models
### Categories
```swift
enum ItemCategory: String, Codable {
    case tv
    case tvSeason = "tv_season"
    case tvEpisode = "tv_episode"
    case book
    case movie
    case music
    case game
    case podcast
    case performance
    // ... other cases
}
```

### TV-related Schemas
- `TVShowSchema`: Base TV show information
- `TVSeasonSchema`: Season-specific fields including:
  - seasonNumber
  - episodeCount
  - episodeUuids
- `TVEpisodeSchema`: Episode-specific fields including:
  - episodeNumber
  - parentUuid (links to season)

## Data Flow
1. URL Processing (`HTMLContentView`)
   - Parse URL components
   - Determine correct category based on type/subtype
   - Create temporary `ItemSchema` with proper category

2. Navigation
   - Use `Router` to navigate with the temporary item
   - Pass category information through the navigation stack

3. Data Fetching (`ItemDetailService`)
   - Use category to determine correct API endpoint
   - Fetch and decode appropriate schema type

## Design Considerations
1. **Type Safety**: Using distinct categories for TV seasons and episodes ensures type-safe API calls
2. **Clear Data Flow**: Category information flows from URL parsing to API calls
3. **Maintainability**: Centralized category handling in `categoryFromType`
4. **Extensibility**: Easy to add new subtypes by extending the category enum and mapping logic

## Recent Changes
1. API Endpoint Fixes
   - Corrected TV content API mapping
   - Added proper type resolution
   - Fixed endpoint selection logic
   - Improved error handling

2. URL Handling
   - Enhanced type parsing
   - Separated category and type handling
   - Fixed subtype resolution
   - Preserved type information

3. UI Updates
   - Type-specific displays
   - Enhanced metadata organization
   - Improved error states
   - Added loading indicators
   - Expandable metadata sections
   - Key information preview

## Best Practices
1. Always check URL structure before parsing
2. Use proper category for API endpoint selection
3. Maintain type information throughout the navigation flow
4. Log important state transitions for debugging

## Future Improvements
- Enhanced navigation between related items
- Batch loading of episodes
- Season overview pages
- Show timeline view
- Watch progress tracking
- Air date notifications
- Related content suggestions
- Advanced filtering
- Offline support 