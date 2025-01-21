# Shared Item Components

## ItemDescriptionView
- Displays item metadata and brief descriptions
- Three display modes: metadata, brief, metadataAndBrief
- Three sizes: small, medium, large
- Features:
  - Consistent font sizes and line limits per size
  - Handles optional values gracefully
  - Supports all item types through ItemProtocol
  - Secondary text color for better readability

## ItemRatingView
- Shows item ratings with optional count
- Three sizes: small, medium, large
- Features:
  - StarView for visual rating display (5-star scale)
  - Converts 10-point scale to 5-star display
  - Optional rating count display
  - Consistent styling with app theme

## ItemMarkView
- Displays user marks/reviews for items
- Two sizes: medium, large
- Features:
  - Shows rating, timestamp, and shelf type
  - Supports tags with horizontal scrolling
  - Optional edit button with icon
  - Consistent padding and spacing per size
  - Brief mode for compact display

## ItemCoverView
- Displays item cover images with placeholders
- Three sizes: small, medium, large
- Features:
  - Maintains aspect ratio
  - Category-specific placeholders
  - Loading skeleton state
  - Proper corner radius handling
  - Left-aligned layout
