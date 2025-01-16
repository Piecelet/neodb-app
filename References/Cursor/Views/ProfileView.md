## ProfileView Migration Record

### Overview
ProfileView displays user profiles from Mastodon, supporting both full account details and basic user information. It handles loading states, errors, and provides a refreshable interface.

### Components
1. **ProfileViewModel**
   - Manages account data loading and caching
   - Handles authentication and error states
   - Supports task cancellation and cleanup
   - Uses CacheService for data persistence

2. **ProfileView**
   - Displays user profile information
   - Supports both MastodonAccount and User types
   - Shows header image, avatar, statistics, and profile fields
   - Implements pull-to-refresh functionality

### Implementation Details
1. **Data Flow**
   - Uses AppAccountsManager for authentication
   - Caches account data with instance-specific keys
   - Supports preloaded accounts and basic user info

2. **Error Handling**
   - Shows EmptyStateView for errors and not found states
   - Provides refresh option for error recovery
   - Logs errors with detailed messages

3. **UI Components**
   - Header image and avatar display
   - Statistics section (posts, following, followers)
   - Profile information (name, username, note, fields)
   - Join date display

### Migration Changes
1. **ViewModel Improvements**
   - Added accountsManager dependency
   - Enhanced cache key generation with instance info
   - Improved error handling and logging
   - Added authentication checks
   - Enhanced task cancellation handling
   - Used defer for state updates

2. **View Enhancements**
   - Added EmptyStateView for error states
   - Improved initialization method
   - Added onDisappear cleanup
   - Set accountsManager in task
   - Enhanced refresh handling

### Known Issues
1. Need to handle rate limiting
2. Consider adding loading states for statistics
3. Improve error messages for specific failure cases

### Next Steps
1. Implement rate limit handling
2. Add animation for state transitions
3. Consider adding profile action buttons
4. Implement profile editing functionality 