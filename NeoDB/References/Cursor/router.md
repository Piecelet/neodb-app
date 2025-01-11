# Router Implementation Design

## Overview
Implementing a navigation router system for NeoDB app, inspired by IceCubes' implementation. The router provides centralized navigation management, type-safe routing, deep linking support, and independent navigation stacks for each tab.

## Navigation Architecture
1. Tab-based Navigation
   ```swift
   enum TabSection: String, CaseIterable {
       case home
       case search
       case library
       case profile
   }
   ```

2. Independent Navigation Paths
   ```swift
   class Router: ObservableObject {
       @Published var paths: [TabSection: [RouterDestination]] = [:]
       @Published var selectedTab: TabSection = .home
       
       func path(for tab: TabSection) -> Binding<[RouterDestination]> {
           Binding(
               get: { self.paths[tab] ?? [] },
               set: { self.paths[tab] = $0 }
           )
       }
   }
   ```

## Router Destinations
Main navigation destinations in the app:

```swift
enum RouterDestination: Hashable {
    // Library
    case itemDetail(id: String)
    case itemDetailWithItem(item: ItemSchema)
    case shelfDetail(type: ShelfType)
    case userShelf(userId: String, type: ShelfType)
    
    // Social
    case userProfile(id: String)
    case userProfileWithUser(user: User)
    case statusDetail(id: String)
    case statusDetailWithStatus(status: Status)
    case hashTag(tag: String)
    
    // Lists
    case followers(id: String)
    case following(id: String)
}
```

## Navigation Examples

### Profile Navigation
```swift
// Navigate to user profile using ID
Button {
    router.navigate(to: .userProfile(id: status.account.id))
} label: {
    // Avatar or username view
}

// Navigate to user profile with User object
Button {
    router.navigate(to: .userProfileWithUser(user: user))
} label: {
    UserAvatarView(user: user)
}
```

### Status Navigation
```swift
// Navigate to status detail
Button {
    router.navigate(to: .statusDetail(id: status.id))
} label: {
    // Status content view
}

// Navigate with full status object
Button {
    router.navigate(to: .statusDetailWithStatus(status: status))
} label: {
    StatusView(status: status)
}
```

### Library Navigation
```swift
// Navigate to item detail with ID
Button {
    router.navigate(to: .itemDetail(id: item.id))
} label: {
    // Item preview
}

// Navigate to item detail with full item
Button {
    router.navigate(to: .itemDetailWithItem(item: item))
} label: {
    // Item preview
}

// Navigate to shelf
Button {
    router.navigate(to: .shelfDetail(type: .wishlist))
} label: {
    Text("Want to Read")
}
```

## Sheet Destinations
Modal presentations in the app:

```swift
enum SheetDestination: Identifiable {
    case newStatus
    case editStatus(status: Status)
    case replyToStatus(status: Status)
    case addToShelf(item: ItemSchema)
    case editShelfItem(mark: MarkSchema)
    
    var id: String {
        switch self {
        case .newStatus, .editStatus, .replyToStatus:
            return "statusEditor"
        case .addToShelf:
            return "shelfEditor"
        case .editShelfItem:
            return "shelfItemEditor"
        }
    }
}
```

## Deep Linking Support

### URL Patterns
```
/items/{id}
/users/{id}
/users/{id}/shelf/{type}
/status/{id}
/tags/{tag}
/~{username}~/{type}/{id}
```

### URL Handling
```swift
func handleURL(_ url: URL) -> Bool {
    // Handle NeoDB internal URLs
    if url.host == "neodb.social" {
        let pathComponents = url.pathComponents
        
        // Handle ~username~ pattern URLs
        if pathComponents.count >= 4,
           pathComponents[1].hasPrefix("~"),
           pathComponents[1].hasSuffix("~") {
            let type = pathComponents[2]
            let id = pathComponents[3]
            
            // Create temporary item for navigation
            let tempItem = ItemSchema(
                id: id,
                type: type,
                category: categoryFromType(type)
            )
            navigate(to: .itemDetailWithItem(item: tempItem))
            return true
        }
        
        // Handle other patterns
        if pathComponents.contains("items"),
           let id = pathComponents.last {
            navigate(to: .itemDetail(id: id))
            return true
        }
        
        if pathComponents.contains("users"),
           let id = pathComponents.last {
            navigate(to: .userProfile(id: id))
            return true
        }
        
        // ... other patterns
    }
    return false
}

private func categoryFromType(_ type: String) -> ItemCategory {
    switch type {
    case "movie": return .movie
    case "book": return .book
    case "tv": return .tv
    case "game": return .game
    case "album": return .music
    case "podcast": return .podcast
    case "performance": return .performance
    default: return .book
    }
}
```

## Best Practices

### Navigation
1. Use IDs for navigation when possible
2. Pass full objects only when needed for immediate display
3. Handle deep links gracefully
4. Support back navigation
5. Maintain navigation stack state for each tab independently

### Error Handling
1. Log navigation failures
2. Provide fallback routes
3. Handle invalid URLs
4. Support external URLs

### Performance
1. Minimize object passing
2. Cache navigation state
3. Preload common destinations
4. Clean up navigation stack

## Recent Changes
1. Added support for independent navigation stacks per tab
2. Implemented tab-based navigation state management
3. Updated deep linking to work with multiple stacks
4. Improved navigation state persistence

## Future Improvements
- [ ] Navigation history per tab
- [ ] Custom transitions
- [ ] Nested navigation
- [ ] Route analytics
- [ ] State restoration
- [ ] URL scheme expansion
- [ ] Cross-tab navigation coordination
- [ ] Tab-specific deep linking rules 