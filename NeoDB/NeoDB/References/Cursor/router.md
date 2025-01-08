# Router Implementation Design

## Overview
Implementing a navigation router system for NeoDB app, inspired by IceCubes' implementation.

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

## Router Implementation
Main router class that manages navigation state:

```swift
@MainActor
class Router: ObservableObject {
    @Published var path: [RouterDestination] = []
    @Published var presentedSheet: SheetDestination?
    
    func navigate(to destination: RouterDestination) {
        path.append(destination)
    }
    
    func dismissSheet() {
        presentedSheet = nil
    }
    
    func handleURL(_ url: URL) -> Bool {
        // Handle deep links and internal navigation
        if url.host == "neodb.social" {
            if let id = url.lastPathComponent {
                if url.path.contains("/items/") {
                    navigate(to: .itemDetail(id: id))
                    return true
                } else if url.path.contains("/users/") {
                    navigate(to: .userProfile(id: id))
                    return true
                }
            }
        }
        return false
    }
}
```

## Integration with SwiftUI
Example of integration in the main app structure:

```swift
struct ContentView: View {
    @StateObject private var router = Router()
    
    var body: some View {
        TabView {
            NavigationStack(path: $router.path) {
                HomeView()
                    .navigationDestination(for: RouterDestination.self) { destination in
                        switch destination {
                        case .itemDetail(let id):
                            ItemDetailView(id: id)
                        case .userProfile(let id):
                            UserProfileView(id: id)
                        // ... other cases
                        }
                    }
            }
            // ... other tabs
        }
        .environmentObject(router)
        .sheet(item: $router.presentedSheet) { sheet in
            switch sheet {
            case .newStatus:
                StatusEditorView()
            case .addToShelf(let item):
                ShelfEditorView(item: item)
            // ... other cases
            }
        }
    }
}
```

## Benefits
1. Centralized navigation management
2. Type-safe routing with enums
3. Deep linking support
4. Consistent navigation patterns
5. Easy to extend and maintain

## Usage Examples
```swift
// In a view
@EnvironmentObject private var router: Router

// Navigate
router.navigate(to: .itemDetail(id: "123"))

// Present sheet
router.presentedSheet = .addToShelf(item: someItem)

// Handle URL
router.handleURL(someURL)
``` 