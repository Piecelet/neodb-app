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
    private let logger = Logger(subsystem: "social.neodb.app", category: "Router")
    
    func navigate(to destination: RouterDestination) {
        path.append(destination)
        logger.debug("Navigated to: \(String(describing: destination))")
    }
    
    func dismissSheet() {
        presentedSheet = nil
    }
    
    func handleURL(_ url: URL) -> Bool {
        logger.debug("Handling URL: \(url.absoluteString)")
        
        // Handle deep links and internal navigation
        if url.host == "neodb.social" {
            let pathComponents = url.pathComponents
            
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
            
            if pathComponents.contains("status"),
               let id = pathComponents.last {
                navigate(to: .statusDetail(id: id))
                return true
            }
            
            if pathComponents.contains("tags"),
               let tag = pathComponents.last {
                navigate(to: .hashTag(tag: tag))
                return true
            }
        }
        
        return false
    }
    
    func handleStatus(status: Status, url: URL) -> Bool {
        logger.debug("Handling status URL: \(url.absoluteString)")
        
        let pathComponents = url.pathComponents
        
        // Handle hashtags
        if pathComponents.contains("tags"),
           let tag = pathComponents.last {
            navigate(to: .hashTag(tag: tag))
            return true
        }
        
        // Handle mentions
        if pathComponents.contains("users"),
           let id = pathComponents.last {
            navigate(to: .userProfile(id: id))
            return true
        }
        
        // Handle status links
        if pathComponents.contains("status"),
           let id = pathComponents.last {
            navigate(to: .statusDetail(id: id))
            return true
        }
        
        return false
    }
}
```

## Integration with Views
Example of integration in views:

### ContentView
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
                            Text("Item Detail: \(id)")  // TODO: Implement ItemDetailView
                        case .userProfile(let id):
                            Text("User Profile: \(id)")  // TODO: Implement UserProfileView
                        // ... other cases
                        }
                    }
            }
        }
        .environmentObject(router)
        .sheet(item: $router.presentedSheet) { sheet in
            switch sheet {
            case .newStatus:
                Text("New Status")  // TODO: Implement StatusEditorView
            case .addToShelf(let item):
                Text("Add to Shelf: \(item.displayTitle)")  // TODO: Implement ShelfEditorView
            // ... other cases
            }
        }
    }
}
```

### HomeView
```swift
struct HomeView: View {
    @EnvironmentObject private var router: Router
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(viewModel.statuses) { status in
                    Button {
                        router.navigate(to: .statusDetailWithStatus(status: status))
                    } label: {
                        StatusView(status: status)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
```

### LibraryView
```swift
struct LibraryView: View {
    @EnvironmentObject private var router: Router
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(viewModel.shelfItems) { mark in
                    Button {
                        router.navigate(to: .itemDetailWithItem(item: mark.item))
                    } label: {
                        ShelfItemView(mark: mark)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
```

## Deep Linking Support
The router handles deep links through the `handleURL` method in the app's entry point:

```swift
struct NeoDBApp: App {
    @StateObject private var authService = AuthService()
    @StateObject private var router = Router()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated {
                    ContentView()
                        .environmentObject(authService)
                        .environmentObject(router)
                } else {
                    LoginView()
                        .environmentObject(authService)
                }
            }
            .onOpenURL { url in
                // First try to handle OAuth callback
                if url.scheme == "neodb" && url.host == "oauth" {
                    Task {
                        do {
                            try await authService.handleCallback(url: url)
                        } catch {
                            print("Authentication error: \(error)")
                        }
                    }
                    return
                }
                
                // Then try to handle deep links
                if !router.handleURL(url) {
                    // If the router didn't handle the URL, open it in the default browser
                    UIApplication.shared.open(url)
                }
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
6. Improved code organization
7. Better state management
8. Enhanced user experience

## Next Steps
1. Implement destination views (ItemDetailView, StatusDetailView, etc.)
2. Add more navigation features as needed
3. Enhance deep linking support
4. Improve error handling and logging
5. Add analytics tracking for navigation events 