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
- Uses async/await for network operations (especially for podcast episodes)

### URL Processing
1. Validates URL format and presence of `~neodb~` identifier
2. Extracts type and ID from path components
3. Creates two URLs:
   - Item URL: Removes `~neodb~` from path
   - API URL: Replaces `~neodb~` with `api` in path
4. For podcast episodes:
   - Asynchronously loads and parses HTML content
   - Extracts podcast UUID from meta refresh tag
   - Uses URLSession for non-blocking network requests

### Category Handling
- Maps URL types to `ItemCategory` enum
- Special handling for TV content (seasons/episodes)
- Special handling for performance productions
- Special async handling for podcast episodes
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
7. Converted to async/await for network operations
8. Improved podcast episode handling with non-blocking network requests

## Usage
```swift
// Async usage in views
Task {
    if let item = await NeoDBURL.parseItemURL(url) {
        // Handle item
    }
}

// Completion handler style
URLHandler.handleItemURL(url) { destination in
    if let destination = destination {
        router.navigate(to: destination)
    } else {
        // Handle non-NeoDB URLs
        openURL(url)
    }
}
```

## Performance Considerations
- Network operations are now non-blocking using async/await
- HTML parsing for podcast episodes is done asynchronously
- URL parsing and manipulation remain synchronous for performance
- Completion handlers are dispatched asynchronously when needed