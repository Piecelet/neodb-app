# Logging System Design

## Overview

NeoDB uses Apple's recommended OSLog framework to implement a unified logging system. The logging system is located in the `Shared/Logging` directory and follows the project's architectural standards.

## Design Principles

### 1. Category Management

Logs are categorized by functional modules:

```swift
// App Lifecycle
Logger.lifecycle  // Application lifecycle events

// Network Operations
Logger.network    // General network operations
Logger.networkAuth    // Authentication network operations
Logger.networkTimeline // Timeline-related network operations
Logger.networkItem    // Item-related network operations
Logger.networkShelf   // Shelf-related network operations
Logger.networkUser    // User-related network operations

// Data Operations
Logger.data       // Data persistence and caching

// Authentication
Logger.auth       // User authentication

// View Lifecycle
Logger.view       // View lifecycle events

// User Interactions
Logger.userAction // User interactions

// Performance
Logger.performance // Performance metrics
```

### 2. Log Levels

Each category supports different log levels:

- `debug`: Development-only debugging information
- `info`: General information for normal flow
- `warning`: Warning messages for potential issues
- `error`: Error messages for operation failures
- `fault`: Critical errors affecting system operation

### 3. Log Format

Unified log format includes:

```
[FileName:LineNumber] FunctionName - Specific Message
```

Example:
```
[AuthService.swift:42] handleCallback(url:) - Handling OAuth callback with URL: neodb://oauth/callback
```

## Usage Guide

### 1. Basic Usage

```swift
// View-related
Logger.view.info("View appeared")

// Network requests
Logger.networkAuth.debug("Starting OAuth request")

// Error handling
Logger.networkItem.error("Failed to load item: \(error.localizedDescription)")

// User actions
Logger.userAction.info("User tapped login button")
```

### 2. Service-specific Logging

Network services use their dedicated loggers:

```swift
class AuthService {
    private let logger = Logger.networkAuth
    // ...
}

class ItemDetailService {
    private let logger = Logger.networkItem
    // ...
}

class TimelineService {
    private let logger = Logger.networkTimeline
    // ...
}

class ShelfService {
    private let logger = Logger.networkShelf
    // ...
}

class UserService {
    private let logger = Logger.networkUser
    // ...
}
```

### 3. Performance Logging

Record performance-related metrics:

```swift
Logger.performance.debug("Image loading took \(duration)s")
```

## Console.app Usage Tips

### 1. Filter Setup

Set up the following filters in Console.app:

- Subsystem: `app.neodb`
- Category: Choose specific category (e.g., `network.auth`, `network.item`)
- Level: Select log level

### 2. Saved Search Patterns

Create commonly used search patterns:

1. Network Request Monitoring:
   - Category: network.*
   - Level: Any

2. Error Tracking:
   - Level: Error
   - Category: Any

3. User Behavior Analysis:
   - Category: userAction
   - Level: Info

## Best Practices

1. **Choose Appropriate Log Levels**
   - `debug`: For development debugging
   - `info`: For important flow points
   - `warning`: For potential issues
   - `error`: For actual errors

2. **Include Context Information**
   ```swift
   logger.debug("Loading item: \(id) for user: \(userId)")
   ```

3. **Avoid Sensitive Information**
   ```swift
   // Correct approach: Use privacy parameter
   logger.info("User \(username, privacy: .private) logged in")
   ```

4. **Performance Considerations**
   - Debug level logs are automatically disabled in release builds
   - Use conditional compilation for debug-only logs
   ```swift
   #if DEBUG
   logger.debug("Debug only message")
   #endif
   ```

## Recent Changes

1. **Network Category Refinement**
   - Added subcategories for network operations:
     - `network.auth`: Authentication requests
     - `network.timeline`: Timeline operations
     - `network.item`: Item detail operations
     - `network.shelf`: Shelf management
     - `network.user`: User profile operations

2. **Logger Implementation Fix**
   - Fixed infinite recursion in convenience methods
   - Updated implementation to use `log(level:)` instead of direct level calls

3. **Service Integration**
   - Updated all network services to use their specific network subcategories
   - Maintained existing logging patterns while improving categorization

## References

- [Explore logging in Swift (WWDC 2020)](https://developer.apple.com/videos/play/wwdc2020/10168/)
- [Unified logging and Activity Tracing (Apple Documentation)](https://developer.apple.com/documentation/os/logging)
- [Debug with structured logging (WWDC 2023)](https://developer.apple.com/videos/play/wwdc2023/10226/) 