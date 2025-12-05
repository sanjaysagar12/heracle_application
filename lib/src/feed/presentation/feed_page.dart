import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../data/stories_repository.dart';
import '../widgets/stories_section.dart';
import '../widgets/discover_stories_grid.dart';
import '../widgets/feed_skeleton_loading.dart';
import '../widgets/story_viewer.dart'; // Updated import path
import 'tab/reels_tab.dart';
import 'tab/my_story_viewer.dart';

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
  StoryUser? _myStory;
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
        _storiesRepository.getMyStories(),
        _storiesRepository.getStories(),
        _storiesRepository.getDiscoverStories(),
      ]);

      final myStory = results[0] as StoryUser;
      final stories = results[1] as List<StoryUser>;

      // Preserve viewed AND liked state for discover stories
      final newDiscoverStories = results[2] as List<DiscoverStory>;
      final mergedDiscoverStories = newDiscoverStories.map((newStory) {
        // Check if this story was already viewed or liked
        final existingStory = _discoverStories.firstWhere(
          (s) => s.id == newStory.id,
          orElse: () => newStory,
        );
        // Preserve BOTH viewed status AND like status
        if (existingStory.id == newStory.id && _discoverStories.isNotEmpty) {
          return newStory.copyWith(
            isViewed: existingStory.isViewed,
            isLiked: existingStory.isLiked,
            likesCount: existingStory.likesCount,
          );
        }
        return newStory;
      }).toList();

      setState(() {
        _myStory = myStory;
        _stories = _storiesRepository.sortStories(stories);
        _discoverStories = mergedDiscoverStories;
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
    // Check if this is user's own story
    if (_myStory != null && storyId == _myStory!.id) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MyStoryViewer(myStory: _myStory!),
        ),
      );
      return;
    }

    final index = _stories.indexWhere((story) => story.id == storyId);
    if (index != -1) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => StoryViewer(
            stories: _stories,
            initialIndex: index,
            onStoryViewed: _markStoryAsViewed,
            onStoryLiked: _handleStoryLike, // Ensure this is passed if needed
            onStoryComment: _handleStoryComment,
          ),
        ),
      );
    }
  }

  void _handleStoryComment(String storyId, String text) {
    _storiesRepository.commentOnStory(storyId, text).catchError((e) {
      print('Error commenting on story: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send comment'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  void _handleStoryLike(String storyId) {
    // Optimistic update in UI
    setState(() {
      _stories = _storiesRepository.toggleStoryLike(_stories, storyId);
    });
    
    // Send request to backend
    _storiesRepository.likeStory(storyId).catchError((e) {
      // Revert state if request fails
      setState(() {
        _stories = _storiesRepository.toggleStoryLike(_stories, storyId);
      });
      print('Error liking story: $e');
    });
  }

  void _markStoryAsViewed(String storyId) {
    setState(() {
      _stories = _storiesRepository.markStoryAsViewed(_stories, storyId);
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
            // Optimistic update
            final updatedStories = _storiesRepository.toggleLike(_discoverStories, storyId);
            setState(() {
              _discoverStories = updatedStories;
            });
            
            // API call to backend
            _storiesRepository.likeDiscoverStory(storyId).catchError((e) {
              print('Error liking discover story: $e');
            });

            // Return the updated story list
            return updatedStories;
          },
          onStoryViewed: (storyId) {
            setState(() {
              _discoverStories = _storiesRepository.markDiscoverStoryAsViewed(_discoverStories, storyId);
            });
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

            // Stories section - pass myStory and only other users' stories
            SliverToBoxAdapter(
              child: StoriesSection(
                stories: _stories, // Don't include myStory here
                myStory: _myStory,
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