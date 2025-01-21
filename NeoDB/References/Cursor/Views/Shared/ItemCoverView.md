# ItemCoverView Design

## Overview
ItemCoverView is a reusable SwiftUI component for displaying item cover images across the app. It handles loading states, placeholders, and different size variants consistently.

## Features
- Supports multiple predefined sizes
- Handles loading and error states
- Shows category-specific placeholders
- Uses Kingfisher for efficient image loading
- Consistent styling across the app

## Size Variants
```swift
enum ItemCoverSize {
    case small   // 64pt height, 4pt corner radius
    case medium  // 140pt height, 8pt corner radius
}
```

## Implementation Details

### Key Components
- Takes optional `ItemProtocol` for type safety
- Uses `KFImage` for image loading and caching
- Shows loading indicator with skeleton effect
- Displays category icon in placeholder state

### Props
```swift
struct ItemCoverView: View {
    let item: (any ItemProtocol)?  // Optional item
    let size: ItemCoverSize        // Size variant
    var showSkeleton: Bool = false // Loading state
}
```

### States
1. Loading
   - Shows placeholder with skeleton effect
   - Maintains aspect ratio
   - Displays category icon

2. Error
   - Shows placeholder with photo icon
   - Maintains consistent size
   - Uses secondary color styling

3. Success
   - Displays loaded image
   - Clips to rounded corners
   - Maintains aspect ratio

## Usage Examples

### In ItemView (Medium Size)
```swift
ItemCoverView(
    item: viewModel.item,
    size: .medium
)
```

### In StatusItemView (Small Size)
```swift
ItemCoverView(
    item: viewModel.item,
    size: .small,
    showSkeleton: viewModel.showSkeleton
)
```

## Migration Notes
1. Unified cover image handling across the app
2. Replaced duplicate image loading code
3. Standardized placeholder appearance
4. Added consistent size variants
5. Improved loading state feedback

## Best Practices
- Always specify a size variant
- Use optional item binding for dynamic content
- Consider skeleton effect for loading states
- Maintain 2:3 aspect ratio for covers
- Use in list items and detail views
