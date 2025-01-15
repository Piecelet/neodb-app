# URLHandler Design

## Overview
URLHandler is responsible for handling NeoDB's deep links and URL routing. It specifically handles item URLs following the NeoDB standard format.

## URL Format
Standard NeoDB item URL format:
```
https://[domain]/~neodb~/[type]/[id]
```

Example:
```
Input:  https://neodb.social/~neodb~/book/2vzTQeac5TETMiVEY5iw4B
Item:   https://neodb.social/book/2vzTQeac5TETMiVEY5iw4B
API:    https://neodb.social/api/book/2vzTQeac5TETMiVEY5iw4B
```

## Implementation Details

### Key Components
- Uses `URLComponents` for robust URL parsing and manipulation
- Handles domain-agnostic URLs (works with any domain, not just neodb.social)
- Maintains URL integrity by preserving original components

### URL Processing
1. Validates URL format and presence of `~neodb~` identifier
2. Extracts type and ID from path components
3. Creates two URLs:
   - Item URL: Removes `~neodb~` from path
   - API URL: Replaces `~neodb~` with `api` in path

### Category Handling
- Maps URL types to `ItemCategory` enum
- Special handling for TV content (seasons/episodes)
- Special handling for performance productions
- Fallback to `.book` for unknown types

### Debug Logging
- Controlled by `isDebugLoggingEnabled` flag
- Logs URL processing steps and decisions
- Disabled by default in production

## Migration Changes
1. Renamed from `URLHandler` to `NeoDBURLHandler` for clarity
2. Added domain-agnostic URL handling
3. Improved URL manipulation using `URLComponents`
4. Added debug logging control
5. Enhanced error handling and logging
6. Added support for TV and performance subcategories

## Usage
```swift
NeoDBURLHandler.handleItemURL(url) { destination in
    if let destination = destination {
        router.navigate(to: destination)
    } else {
        // Handle non-NeoDB URLs
        openURL(url)
    }
} 