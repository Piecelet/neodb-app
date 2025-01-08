# Timeline Local-Only Implementation

## Overview
Modified TimelineService to show only local statuses from the instance and properly render HTML content.

## API Reference
From Mastodon API documentation:
- Endpoint: GET `/api/v1/timelines/public`
- Parameter: `local=true` to show only local statuses
- Default: Shows both local and remote statuses (local=false)

## Content Rendering
Status content comes in HTML format with the following features:
- Links with href attributes
- Mentions with rel attributes
- Emoji ratings (🌕 for filled stars)
- Paragraphs with spacing

### HTML Example
```html
<p>看過 <a href="https://neodb.social/movie/xxx" rel="nofollow">电影名称</a> 🌕🌕🌕🌕🌕  </p>
```

### Implementation Details
1. Added SwiftDown package for HTML parsing
2. Created custom AttributedString converter
3. Added link handling support
4. Implemented emoji rating display

## Dependencies
Required SPM packages:
- SwiftDown: HTML and Markdown parsing
- SwiftSoup (optional): Advanced HTML manipulation

## Implementation Details
1. Added local parameter to URL query
2. Set local=true by default to show only local statuses
3. Improved error logging for better debugging
4. Added HTML content parsing and rendering
5. Implemented link handling and styling

## Design Rationale
- Local-only timeline provides more relevant content for NeoDB users
- Reduces noise from remote instances
- Improves performance by reducing data load
- Better content moderation as all content is from the same instance
- Rich text rendering enhances readability and interaction

## Code Changes
- Modified getTimeline method in TimelineService
- Added local parameter to URLComponents
- Added HTML content rendering support
- Updated documentation
- Enhanced StatusView with rich text support 