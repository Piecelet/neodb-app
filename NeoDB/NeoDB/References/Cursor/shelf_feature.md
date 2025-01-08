# Shelf Feature Implementation

## Overview
Shelf display functionality in dedicated LibraryView tab for collection management. Supports navigation to item details, filtering, and shelf management.

## API Endpoints
- GET `/api/me/shelf/{type}`
  - Types: wishlist, progress, complete, dropped
  - Optional query params: category, page
  - Returns: PagedMarkSchema

## Models
1. ShelfType enum - Different shelf types (wishlist, progress, complete, dropped)
2. MarkSchema - Individual shelf item data
3. PagedMarkSchema - Paginated response structure
4. ItemSchema - Item details structure

## Router Integration

### Destinations
```swift
// Library destinations
case itemDetail(id: String)
case itemDetailWithItem(item: ItemSchema)
case shelfDetail(type: ShelfType)
case userShelf(userId: String, type: ShelfType)

// Sheet destinations
case addToShelf(item: ItemSchema)
case editShelfItem(mark: MarkSchema)
```

### Navigation Examples
```swift
// Navigate to item detail
Button {
    router.navigate(to: .itemDetailWithItem(item: mark.item))
} label: {
    ShelfItemView(mark: mark)
}

// Present add to shelf sheet
router.presentedSheet = .addToShelf(item: item)

// Navigate to user's shelf
router.navigate(to: .userShelf(userId: user.id, type: .wishlist))
```

## Component Structure
- LibraryView/
  - LibraryView.swift (Main view)
  - LibraryViewModel.swift (Business logic)
  - Components/
    - ShelfItemView.swift (Item card)
    - ShelfFilterView.swift (Type/category filters)

## Features
- Shelf type switching (Want to Read, Reading, Completed, Dropped)
- Category filtering (All, Book, Movie, TV, Game)
- Infinite scrolling pagination
- Pull-to-refresh
- Loading states and error handling
- Deep linking support
- Navigation integration

## Implementation Details

### LibraryView
```swift
struct LibraryView: View {
    @StateObject private var viewModel: LibraryViewModel
    @EnvironmentObject private var router: Router
    
    var body: some View {
        VStack {
            ShelfFilterView(...)
            
            ScrollView {
                LazyVStack {
                    ForEach(viewModel.shelfItems) { mark in
                        Button {
                            router.navigate(to: .itemDetailWithItem(item: mark.item))
                        } label: {
                            ShelfItemView(mark: mark)
                        }
                    }
                }
            }
        }
    }
}
```

### ShelfItemView
```swift
struct ShelfItemView: View {
    let mark: MarkSchema
    
    var body: some View {
        HStack {
            KFImage(URL(string: mark.item.coverImageUrl))
                .placeholder { ... }
            
            VStack(alignment: .leading) {
                Text(mark.item.displayTitle)
                if let rating = mark.ratingGrade {
                    RatingView(rating: rating)
                }
                TagsView(tags: mark.tags)
            }
        }
    }
}
```

## Deep Linking
Support for deep links to:
- Specific items
- User shelves
- Shelf types
- Categories

URL patterns:
```
/items/{id}
/users/{id}/shelf/{type}
/shelf/{type}?category={category}
```

## Error Handling
- Network errors
- Invalid data
- Loading states
- Empty states
- Retry mechanisms

## Future Improvements
- Batch actions
- Sorting options
- Search within library
- Enhanced filters
- Statistics view
- Reading progress
- Share functionality
- Export/Import
- Offline support 