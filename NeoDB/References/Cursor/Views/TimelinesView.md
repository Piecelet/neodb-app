# TimelinesView Design Documentation

## Overview
TimelinesView is a core component that manages and displays different types of timelines (Friends, Home, Popular, Fediverse) in the NeoDB app. It uses modern Swift concurrency and the actor pattern for efficient state management.

## Architecture

### Core Components
1. **TimelineActor**
   - Centralized state management using `@MainActor`
   - Handles timeline data loading, caching, and real-time updates
   - Manages WebSocket connections for live updates

2. **TimelineState**
   - Stores timeline-specific data and states
   - Tracks loading, refresh, and error states
   - Maintains pagination information

3. **StatusView**
   - Displays individual status posts
   - Handles media attachments and item previews
   - Supports user interactions and navigation

## Recent Improvements

### State Management
1. **Actor Pattern Implementation**
   - Introduced `TimelineActor` for thread-safe state management
   - Improved state isolation and concurrency handling
   - Better coordination between UI and data updates

2. **Error Handling**
   - Enhanced error suppression during pagination
   - Smarter error display logic based on context
   - Improved error logging for debugging

3. **Cache Integration**
   - Implemented smart caching strategy
   - Faster initial load times
   - Reduced network requests

### Real-time Updates
1. **WebSocket Integration**
   - Efficient stream subscription management
   - Smart distribution of updates to appropriate timelines
   - Proper cleanup on deactivation

2. **Timeline-specific Rules**
   - Friends: Private and direct messages
   - Home: Local instance posts
   - Popular: No real-time updates
   - Fediverse: Remote instance posts

## Recent Changes

### Version 0.8
1. **Timeline Types Reorganization**
   - Renamed "Home" to "Friends"
   - Added "Popular" timeline
   - Renamed "Federated" to "Fediverse"
   - Enhanced filtering capabilities

2. **Performance Optimizations**
   - Improved pagination handling
   - Reduced unnecessary state updates
   - Better memory management

3. **UI Improvements**
   - Enhanced loading states
   - Smoother transitions
   - Better error message handling

## Known Issues & Solutions

1. **Pagination Error Flashes**
   - Issue: Brief error messages during pagination
   - Solution: Implemented smarter error suppression
   - Status: Fixed in latest version

2. **WebSocket Reconnection**
   - Issue: Inconsistent stream updates after app background
   - Solution: Improved cleanup and reactivation logic
   - Status: Fixed

## Future Plans

### Short-term
1. **Performance**
   - [ ] Implement virtualized list for better memory usage
   - [ ] Add prefetching for smoother infinite scroll
   - [ ] Optimize image loading and caching

2. **Features**
   - [ ] Add timeline filters (by type, visibility)
   - [ ] Implement timeline search
   - [ ] Add bookmark functionality

### Long-term
1. **Architecture**
   - [ ] Consider moving to Swift Data for persistence
   - [ ] Implement timeline composition API
   - [ ] Add support for custom timeline types

2. **User Experience**
   - [ ] Add timeline customization options
   - [ ] Implement advanced filtering
   - [ ] Add timeline analytics

## Best Practices

1. **State Management**
   - Use `TimelineActor` for all state modifications
   - Maintain single source of truth
   - Handle cleanup properly

2. **Performance**
   - Implement proper pagination
   - Use efficient caching strategies
   - Minimize unnecessary updates

3. **Error Handling**
   - Show errors only when necessary
   - Maintain existing content during errors
   - Log errors appropriately

## Testing Guidelines

1. **Unit Tests**
   - Test timeline state transitions
   - Verify error handling logic
   - Test caching mechanisms

2. **Integration Tests**
   - Test WebSocket integration
   - Verify timeline type interactions
   - Test pagination behavior

## Migration Notes

When updating from previous versions:
1. Update timeline type usage
2. Review WebSocket implementation
3. Update caching implementation if needed
4. Verify error handling behavior
