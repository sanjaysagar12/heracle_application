/// Feed Page Architecture Documentation
/// 
/// This document describes the standardized architecture for feature modules
/// as implemented in the feed folder.
///
/// ARCHITECTURE PATTERN (Standard for ALL features):
/// ================================================
///
/// feature/
/// ├── api/              # Service layer - Mock/Real API calls
/// ├── data/             # Repository layer - Models, state management, business logic
/// ├── presentation/     # UI entry points - Only main pages
/// └── widgets/          # Feature-specific reusable widgets (AT ROOT LEVEL!)
///
/// KEY PRINCIPLES:
/// ===============
///
/// 1. widgets/ folder is at FEATURE ROOT level (NOT inside presentation/)
///    - This makes widgets reusable across multiple presentation pages
///    - Keeps presentation/ clean with only page entry points
///
/// 2. Data Layer (data/) handles ALL state management:
///    - Models with copyWith() for immutability
///    - Repository methods for state transformations
///    - Business logic (e.g., markStoryAsViewed, sortStories)
///
/// 3. API Layer (api/) provides mock/real data:
///    - Returns List<Map<String, dynamic>> simulating API responses
///    - Includes delays to simulate network calls
///    - Easy to swap with real API implementation
///
/// 4. Presentation Layer (presentation/) only contains pages:
///    - Manages local UI state
///    - Calls repository methods for business logic
///    - Composes widgets from widgets/ folder
///
/// FEED PAGE IMPLEMENTATION:
/// =========================
///
/// Files Created:
/// -------------
/// api/
///   - stories_service.dart (Mock API with test data)
///
/// data/
///   - stories_repository.dart (Models: StoryUser, DiscoverStory)
///     * markStoryAsViewed() - Instagram-like behavior
///     * sortStories() - Unviewed first, viewed last
///
/// presentation/
///   - feed_page.dart (Main feed page with full functionality)
///
/// widgets/
///   - story_avatar.dart (Individual story circle)
///   - stories_section.dart (Horizontal stories list)
///   - discover_story_card.dart (Grid card component)
///   - discover_stories_grid.dart (2-column grid layout)
///   - story_viewer.dart (Full-screen story viewer)
///   - feed_skeleton_loading.dart (Loading state)
///   - widgets.dart (Widget exports)
///
/// FUNCTIONALITY IMPLEMENTED:
/// ==========================
///
/// ✅ Instagram-like Stories:
///    - Green gradient ring for unviewed stories
///    - Grey ring for viewed stories
///    - Tap to view story in full-screen viewer
///    - Auto-progress with 5-second timer
///    - Tap left/right to navigate between stories
///    - Long press to pause progress
///    - Viewed stories move to end of list
///
/// ✅ Add Story Navigation:
///    - Add story button (first in list)
///    - Navigates to camera page (tab index 1)
///    - Callback pattern for navigation
///
/// ✅ Discover Stories Grid:
///    - 2-column responsive grid
///    - Platform badges (TikTok, Instagram, YouTube)
///    - User info overlay
///    - Hashtags display
///    - Tap for detailed bottom sheet
///
/// ✅ Story Detail Bottom Sheet:
///    - Draggable with custom height
///    - Full story image
///    - User information
///    - Platform badge
///    - Content and hashtags
///    - Like and Share actions
///
/// ✅ Loading & Refresh:
///    - Skeleton loading with shimmer effect
///    - Pull-to-refresh with custom colors
///    - Parallel data loading
///
/// ✅ State Management:
///    - Stories sorted on load (unviewed first)
///    - Real-time reordering after viewing
///    - Optimistic UI updates
///
/// NAVIGATION PATTERN:
/// ===================
///
/// FeedPage receives onNavigateToCamera callback from AppPage:
///   AppPage builds FeedPage with: () => _changeTab(1)
///   FeedPage calls widget.onNavigateToCamera!() on add story tap
///   This changes bottom navigation to Camera tab
///
/// REMEMBER FOR FUTURE FEATURES:
/// ==============================
///
/// 1. Always put widgets/ at feature root level
/// 2. Use data/ repository for state transformations
/// 3. Keep presentation/ simple - only UI composition
/// 4. Use callback pattern for cross-feature navigation
/// 5. Implement skeleton loading for better UX
/// 6. Support pull-to-refresh on list views
/// 7. Use bottom sheets for detail views
/// 8. Add haptic feedback for interactions (future)
/// 9. Cache data in repository layer (future)
/// 10. Add error handling with retry options (future)
///
/// TESTING STRATEGY:
/// =================
///
/// - Unit tests for repository methods (markStoryAsViewed, sortStories)
/// - Widget tests for individual components
/// - Integration tests for full user flows
/// - Mock API responses for predictable testing
///
/// PERFORMANCE OPTIMIZATIONS:
/// ==========================
///
/// - IndexedStack in AppPage prevents page rebuilds
/// - const constructors where possible
/// - Cached network images
/// - Lazy loading with ListView.builder
/// - Parallel API calls with Future.wait
///
/// This architecture ensures:
/// - Scalability for growing features
/// - Easy testing and maintenance
/// - Clear separation of concerns
/// - Consistent code organization
/// - Reusable components
