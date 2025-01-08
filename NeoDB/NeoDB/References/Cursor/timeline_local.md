# Timeline Local-Only Implementation

## Overview
Modified TimelineService to show only local statuses from the instance.

## API Reference
From Mastodon API documentation:
- Endpoint: GET `/api/v1/timelines/public`
- Parameter: `local=true` to show only local statuses
- Default: Shows both local and remote statuses (local=false)

## Implementation Details
1. Added local parameter to URL query
2. Set local=true by default to show only local statuses
3. Improved error logging for better debugging

## Design Rationale
- Local-only timeline provides more relevant content for NeoDB users
- Reduces noise from remote instances
- Improves performance by reducing data load
- Better content moderation as all content is from the same instance

## Code Changes
- Modified getTimeline method in TimelineService
- Added local parameter to URLComponents
- Updated documentation 