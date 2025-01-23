# TimelinesView Design

## Recent Updates (February 2024)

### Architecture Improvements
- Introduced `TimelineActor` for centralized state management
- Converted to async/await for better concurrency handling
- Implemented real-time updates via WebSocket
- Enhanced caching strategy for better performance

### Timeline Types
- Renamed and reorganized timeline types:
  - "Home" → "Friends" (following feed)
  - "Local" → "Home" (instance feed)
  - "Federated" → "Fediverse" (federated feed)
  - Added "Popular" timeline

### State Management
- Improved state isolation using Actor pattern
- Better handling of cached data and network requests
- Optimized real-time update distribution
- Enhanced error handling and loading states

## Current Design

### Core Components
1. `TimelinesView`: Main view container
2. `TimelineActor`: State management and data coordination
3. `StatusView`: Reusable status component
4. `StatusReplyView`: Status reply interface

### Data Flow
1. Initial load from cache
2. Network request for fresh data
3. WebSocket connection for real-time updates
4. State updates through actor methods

## Future Roadmap

### Short-term Goals
- [ ] Optimize timeline scrolling performance
- [ ] Implement pull-to-refresh with smooth animations
- [ ] Add support for media-only timeline filter
- [ ] Enhance error recovery mechanisms

### Long-term Goals
- [ ] Support for timeline filters and preferences
- [ ] Advanced caching strategies
- [ ] Improved media handling
- [ ] Enhanced interaction animations

## Migration Notes

### From Previous Version
- State management moved from view to actor
- Timeline types restructured
- WebSocket handling improved
- Cache implementation optimized

### Known Issues
- Need to handle network transitions gracefully
- Optimize memory usage for long timelines
- Handle rate limiting more elegantly
