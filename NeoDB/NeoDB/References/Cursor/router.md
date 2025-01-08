# Router Implementation Design

## Overview
Implementing a navigation router system for NeoDB app, inspired by IceCubes' implementation. The router provides centralized navigation management, type-safe routing, and deep linking support.

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
// Navigate to item detail
Button {
    router.navigate(to: .itemDetail(id: item.id))
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
```

### URL Handling
```swift
func handleURL(_ url: URL) -> Bool {
    if url.pathComponents.contains("items"),
       let id = url.pathComponents.last {
        navigate(to: .itemDetail(id: id))
        return true
    }
    
    if url.pathComponents.contains("users"),
       let id = url.pathComponents.last {
        navigate(to: .userProfile(id: id))
        return true
    }
    
    // ... other patterns
    return false
}
```

## Best Practices

### Navigation
1. Use IDs for navigation when possible
2. Pass full objects only when needed for immediate display
3. Handle deep links gracefully
4. Support back navigation
5. Maintain navigation stack state

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

## Future Improvements
- [ ] Navigation history
- [ ] Custom transitions
- [ ] Nested navigation
- [ ] Route analytics
- [ ] State restoration
- [ ] URL scheme expansion 