# Logging System Implementation

## Overview
NeoDB uses Apple's OSLog framework for a unified logging system. This system provides structured, categorized logging with different levels of detail and privacy.

## Design Principles

### Category Management
- **Environment**
  - `environment`: General environment operations
  - `environmentCurrentInstance`: Instance-related operations
  - `environmentCurrentAccount`: Account-related operations
- **Network**
  - `networkAuth`: Authentication operations
  - `networkTimeline`: Timeline operations
  - `networkItem`: Item operations
  - `networkShelf`: Shelf operations
  - `networkUser`: User operations
- **View**
  - `view`: General view operations
- **Data**
  - `data`: Data operations
- **User Action**
  - `userAction`: User-initiated actions

### Log Levels
- `debug`: Development information
- `info`: Important state changes
- `error`: Error conditions
- `warning`: Warning conditions

### Log Format
```swift
// Development environment
[Filename:LineNumber] FunctionName: Message

// Production environment
Message
```

## Usage Examples

### Environment Logging
```swift
// Instance operations
logger.debug("Fetched current instance: domain.social")
logger.error("Failed to fetch instance: Network error")

// Account operations
logger.debug("Fetched current account: username")
logger.info("Updated network client for instance: domain.social")
```

### Network Logging
```swift
// Authentication
logger.debug("Starting OAuth flow")
logger.info("User authenticated successfully")

// API calls
logger.debug("Fetching timeline")
logger.error("API request failed: 404 Not Found")
```

## Console.app Tips
1. Enable Info and Debug messages for development
2. Filter by subsystem: "app.neodb"
3. Filter by category for specific components
4. Use predicates for custom filtering

## Best Practices
1. Log at appropriate levels
2. Include relevant context
3. Avoid sensitive information
4. Use categories consistently
5. Keep messages concise

## Recent Changes
- Added environment logging categories
- Improved account operation logging
- Added network operation subcategories
- Fixed infinite recursion in convenience methods
- Enhanced log message formatting
- Added development vs production log formats 