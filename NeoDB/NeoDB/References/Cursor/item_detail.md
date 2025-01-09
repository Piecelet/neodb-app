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

## URL Patterns and API Mapping
1. Basic Item URLs
   - `/~username~/type/id` → `/api/{type}/{id}`
2. TV-specific URLs and API Endpoints
   - `/~username~/tv/id` → `/api/tv/{id}`
   - `/~username~/tv/season/id` → `/api/tv/season/{id}`
   - `/~username~/tv/episode/id` → `/api/tv/episode/{id}`

## Type Handling
1. URL Type Resolution
   - Base type (tv) determines category
   - Subtype (season, episode) determines API endpoint
   - Type information preserved in ItemSchema
2. API Endpoint Selection
   - TV shows: /api/tv/{uuid}
   - TV seasons: /api/tv/season/{uuid}
   - TV episodes: /api/tv/episode/{uuid}

## Models
1. Core Models (Models.swift)
   - ItemSchema
     - Basic fields (title, description, etc.)
     - Type and category information
     - API-specific fields (uuid, url, etc.)
   - TVShowSchema
     - Show-specific fields (seasonCount, episodeCount)
     - Cast and crew information
   - TVSeasonSchema
     - Season-specific fields (seasonNumber, episodeCount)
     - Episode list and metadata
   - TVEpisodeSchema
     - Basic fields (title, description)
     - Episode-specific fields (episodeNumber)
     - Parent reference

## Features
1. Dynamic Layout
   - Type-specific metadata display
   - Conditional UI elements
   - Responsive design
2. TV Content Hierarchy
   - Show → Season → Episode navigation
   - Parent-child relationships
   - Type-specific API endpoints
3. Metadata Display
   - Key information preview
   - Detailed metadata sections
   - Expandable content

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