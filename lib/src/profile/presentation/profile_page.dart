import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../data/profile_repository.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_tab_bar.dart';
import '../widgets/highlight_grid.dart';
import '../widgets/profile_skeleton.dart';
import '../../feed/data/stories_repository.dart';
import '../../feed/presentation/tab/reels_tab.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileRepository _repository = ProfileRepository();
  
  UserProfile? _profile;
  List<HighlightVideo> _highlights = [];
  List<DiscoverStory> _discoverStories = []; // For ReelsTab navigation
  
  bool _isLoading = true;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _repository.getUserProfile(),
        _repository.getAllHighlights(),
      ]);

      setState(() {
        _profile = results[0] as UserProfile;
        _highlights = results[1] as List<HighlightVideo>;
        _discoverStories = _convertToDiscoverStories(_highlights, _profile!);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  void _onFollowTap() {
    if (_profile != null) {
      setState(() {
        _profile = _repository.toggleFollow(_profile!);
      });
    }
  }

  /// Convert HighlightVideo list to DiscoverStory list for ReelsTab
  List<DiscoverStory> _convertToDiscoverStories(List<HighlightVideo> highlights, UserProfile profile) {
    return highlights.map((highlight) {
      return DiscoverStory(
        id: highlight.id,
        username: profile.name,
        profileImage: profile.profileImageUrl,
        content: highlight.category,
        hashtags: [highlight.category],
        imageUrl: highlight.thumbnailUrl,
        platform: highlight.platform,
        platformHandle: profile.username,
        timeAgo: 'Recently',
        isLiked: false,
        likesCount: 0,
        likedBy: [],
        isViewed: false,
        mediaType: 'VIDEO',
      );
    }).toList();
  }

  /// Handle like action for reels
  List<DiscoverStory> _handleLike(String storyId) {
    setState(() {
      _discoverStories = _discoverStories.map((story) {
        if (story.id == storyId) {
          final newIsLiked = !story.isLiked;
          final newLikesCount = newIsLiked ? story.likesCount + 1 : story.likesCount - 1;
          return story.copyWith(isLiked: newIsLiked, likesCount: newLikesCount);
        }
        return story;
      }).toList();
    });
    return _discoverStories;
  }

  void _onHighlightTap(HighlightVideo highlight) {
    // Find the index of the tapped highlight
    final index = _highlights.indexWhere((h) => h.id == highlight.id);
    
    // Navigate to ReelsTab with all profile reels starting from tapped index
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReelsTab(
          stories: _discoverStories,
          initialIndex: index >= 0 ? index : 0,
          onLike: _handleLike,
          onStoryViewed: (storyId) {
            // Mark story as viewed
            setState(() {
              _discoverStories = _discoverStories.map((story) {
                if (story.id == storyId) {
                  return story.copyWith(isViewed: true);
                }
                return story;
              }).toList();
            });
          },
        ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.pureWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.pureWhite),
            onPressed: () {
              // TODO: Show options menu
            },
          ),
        ],
      ),
      body: _isLoading
          ? const ProfileSkeleton()
          : RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppColors.primary,
              backgroundColor: AppColors.greyDark,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Profile Header
                    if (_profile != null)
                      ProfileHeader(
                        profile: _profile!,
                        onFollowTap: _onFollowTap,
                      ),
                    // Tab Bar
                    ProfileTabBar(
                      selectedIndex: _selectedTabIndex,
                      onTabSelected: _onTabSelected,
                    ),
                    // Content based on selected tab
                    _buildTabContent(),
                    // Bottom padding for nav bar
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildHighlightsTab();
      case 1:
        return _buildSessionsTab();
      case 2:
        return _buildPostsTab();
      default:
        return _buildHighlightsTab();
    }
  }

  Widget _buildHighlightsTab() {
    return Column(
      children: [
        // Highlights grid
        HighlightGrid(
          highlights: _highlights,
          onHighlightTap: _onHighlightTap,
        ),
      ],
    );
  }

  Widget _buildSessionsTab() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Text(
          'Sessions coming soon',
          style: TextStyle(
            color: AppColors.white60,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildPostsTab() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Text(
          'Posts coming soon',
          style: TextStyle(
            color: AppColors.white60,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
