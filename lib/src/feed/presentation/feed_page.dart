import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../data/stories_repository.dart';
import '../widgets/stories_section.dart';
import '../widgets/discover_stories_grid.dart';
import '../widgets/feed_skeleton_loading.dart';
import '../widgets/story_viewer.dart';
import 'tab/reels_tab.dart';

/// Feed Page - Main stories and discover feed
/// 
/// Architecture Pattern (Standard for all feature modules):
/// - widgets/ folder is at feature root level (NOT inside presentation/)
/// - api/ contains service layer for data fetching
/// - data/ contains repositories and models for state management
/// - presentation/ contains only pages (UI entry points)
/// 
/// Functionality:
/// - Stories at top with Instagram-like behavior
/// - Viewed stories move to end and lose highlight
/// - Add story button navigates to camera page
/// - Discover stories grid with detailed bottom sheet
/// - Pull to refresh, skeleton loading
/// - Full state management in data layer
class FeedPage extends StatefulWidget {
  final VoidCallback? onNavigateToCamera;

  const FeedPage({
    super.key,
    this.onNavigateToCamera,
  });

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final StoriesRepository _storiesRepository = StoriesRepository();
  List<StoryUser> _stories = [];
  List<DiscoverStory> _discoverStories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _storiesRepository.getStories(),
        _storiesRepository.getDiscoverStories(),
      ]);

      setState(() {
        _stories = _storiesRepository.sortStories(
          results[0] as List<StoryUser>,
        );
        _discoverStories = results[1] as List<DiscoverStory>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading feed data: $e');
    }
  }

  void _handleStoryTap(String storyId) {
    final index = _stories.indexWhere((story) => story.id == storyId);
    if (index != -1) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => StoryViewer(
            stories: _stories,
            initialIndex: index,
            onStoryViewed: _markStoryAsViewed,
          ),
        ),
      );
    }
  }

  void _markStoryAsViewed(String storyId) {
    setState(() {
      _stories = _storiesRepository.markStoryAsViewed(_stories, storyId);
    });
  }

  void _handleLike(String storyId) {
    setState(() {
      _discoverStories = _storiesRepository.toggleLike(_discoverStories, storyId);
    });
  }

  void _handleAddStory() {
    // Navigate to camera page
    if (widget.onNavigateToCamera != null) {
      widget.onNavigateToCamera!();
    } else {
      // Fallback if callback not provided
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening camera to create story...'),
          duration: Duration(seconds: 1),
          backgroundColor: Color(0xFFD4FC79),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleDiscoverStoryTap(DiscoverStory story) {
    // Navigate to reels viewer
    final storyIndex = _discoverStories.indexWhere((s) => s.id == story.id);
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReelsTab(
          stories: _discoverStories,
          initialIndex: storyIndex,
          onLike: (storyId) {
            setState(() {
              _discoverStories = _storiesRepository.toggleLike(_discoverStories, storyId);
            });
            // Return the updated story list
            return _discoverStories;
          },
        ),
      ),
    ).then((_) {
      // Refresh the grid when returning from reels
      setState(() {});
    });
  }
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.black,
        body: FeedSkeletonLoading(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.black,
      body: RefreshIndicator(
        onRefresh: _loadData,
        backgroundColor: AppColors.black100,
        color: const Color(0xFFD4FC79),
        child: CustomScrollView(
          slivers: [
            // Top spacing for status bar
            const SliverToBoxAdapter(
              child: SizedBox(height: 60),
            ),

            // Stories section
            SliverToBoxAdapter(
              child: StoriesSection(
                stories: _stories,
                onStoryTap: _handleStoryTap,
                onAddStory: _handleAddStory,
              ),
            ),

            // Discover Stories title
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Text(
                  'Discover Stories',
                  style: TextStyle(
                    color: AppColors.pureWhite,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Discover stories grid
            DiscoverStoriesGrid(
              stories: _discoverStories,
              onStoryTap: _handleDiscoverStoryTap,
              onLike: _handleLike,
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }
}