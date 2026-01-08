import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/widgets/comments_bottom_sheet.dart';
import '../../../home/widgets/likes_bottom_sheet.dart';
import '../../data/stories_repository.dart';
import '../../../home/data/profile_repository.dart'; // Added
import 'dart:math' as math;
import '../../../home/data/mutual_feed_repository.dart'; // Needed for Comment/LikedByUser types

class ReelsTab extends StatefulWidget {
  final List<DiscoverStory> stories;
  final int initialIndex;
  final List<DiscoverStory> Function(String storyId) onLike;
  final Function(String storyId)? onStoryViewed;

  const ReelsTab({
    super.key,
    required this.stories,
    this.initialIndex = 0,
    required this.onLike,
    this.onStoryViewed,
  });

  @override
  State<ReelsTab> createState() => _ReelsTabState();
}

class _ReelsTabState extends State<ReelsTab> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _showLikeAnimation = false;
  late List<DiscoverStory> _stories;

  // Track which stories are expanded (caption/tags shown fully)
  final Set<String> _expandedStories = {};

  // Added: stories repo and comments cache to reuse Home comments UI
  final StoriesRepository _storiesRepository = StoriesRepository();
  final Map<String, List<Comment>> _commentsCache = {};
  
  // Added: Profile loading for comments
  final ProfileRepository _profileRepository = ProfileRepository();
  Profile? _profile;

  @override
  void initState() {
    super.initState();
    _stories = widget.stories;
    _currentIndex = widget.initialIndex;
    _loadProfile(); // Load profile
    
    _pageController = PageController(
      initialPage: _currentIndex,
      viewportFraction: 1.0,
      keepPage: true,
    );
    
    // Mark initial story as viewed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentIndex < _stories.length) {
        final initialStory = _stories[_currentIndex];
        widget.onStoryViewed?.call(initialStory.id);
        _loadStoryDetails(initialStory.id);
      }
    });
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileRepository.getProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
        });
      }
    } catch (e) {
      print('Error loading profile in ReelsTab: $e');
    }
  }

  @override




  bool _isExpanded(String storyId) => _expandedStories.contains(storyId);

  void _toggleExpanded(String storyId) {
    setState(() {
      if (_expandedStories.contains(storyId)) {
        _expandedStories.remove(storyId);
      } else {
        _expandedStories.add(storyId);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleDoubleTap(String storyId, bool isLiked) {
    // Toggle like state
    _handleLike(storyId);
    
    // Show animation only when liking (not unliking)
    // Note: isLiked passed here is the OLD state. So if it WAS NOT liked, we are liking it now.
    if (!isLiked) {

      setState(() {
        _showLikeAnimation = true;
      });

      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _showLikeAnimation = false;
          });
        }
      });
    }
  }

  Future<void> _handleLike(String storyId) async {
    // Optimistic update
    final updatedStories = widget.onLike(storyId);
    
    setState(() {
      _stories = updatedStories;
    });

    try {
      // Use standard story like endpoint
      await _storiesRepository.likeStory(storyId);
    } catch (e) {
      print('Error liking reel: $e');
      // Revert if failed
      final revertedStories = widget.onLike(storyId);
      if (mounted) {
        setState(() {
          _stories = revertedStories;
        });
      }
    }
  }

  void _showMoreOptions(DiscoverStory story) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.black100,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: _buildMoreOptionsSheet(story),
      ),
    );
  }

  void _showShareOptions(DiscoverStory story) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.black100,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: _buildShareSheet(story),
      ),
    );
  }

  void _showLikes(DiscoverStory story) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => LikesBottomSheet(
          likedByUsers: story.likedBy,
        ),
      ),
    );
  }

  Future<void> _showComments(DiscoverStory story) async {
    // Show bottom sheet immediately with loading state
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          bool isLoadingComments = !_commentsCache.containsKey(story.id);
          List<Comment> currentComments = _commentsCache[story.id] ?? [];

          // Fetch comments in background if not cached
          if (isLoadingComments) {
            _storiesRepository.getStoryComments(story.id).then((comments) {
              if (mounted) {
                setState(() {
                  _commentsCache[story.id] = comments;
                });
                setModalState(() {}); // Update modal to show comments
              }
            }).catchError((e) {
              print('Error loading comments: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to load comments'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            });
          }

          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) => CommentsBottomSheet(
              comments: currentComments,
              isLoading: isLoadingComments,
              onAddComment: (content) async {
                // Add comment via repo and update cache + UI
                final newComment = await _storiesRepository.commentOnStory(story.id, content);
                setState(() {
                  _commentsCache[story.id] = [...(_commentsCache[story.id] ?? []), newComment];
                });
                setModalState(() {}); // refresh modal content
              },
              onAddReply: (commentId, content) async {
                final newReply = await _storiesRepository.replyToComment(commentId, content);
                setState(() {
                  final current = _commentsCache[story.id] ?? [];
                  _commentsCache[story.id] = _addReplyToComment(current, commentId, newReply);
                });
                setModalState(() {}); // refresh modal content
              },
              currentUserProfile: _profile,
            ),
          );
        },
      ),
    );
  }

  // Helper to add reply into nested comment list (returns new list)
  List<Comment> _addReplyToComment(List<Comment> comments, String commentId, Comment newReply) {
    return comments.map((comment) {
      if (comment.id == commentId) {
        return comment.copyWithReply(newReply);
      }
      if (comment.replies.isNotEmpty) {
        return Comment(
          id: comment.id,
          username: comment.username,
          handle: comment.handle,
          profileImage: comment.profileImage,
          timeAgo: comment.timeAgo,
          content: comment.content,
          replies: _addReplyToComment(comment.replies, commentId, newReply),
        );
      }
      return comment;
    }).toList();
  }

  // helper to render overlapping avatars safely
  Widget _buildOverlappingAvatars(List<String> urls, {double size = 20, double overlap = 6, int max = 3}) {
    final display = urls.take(max).toList();
    final count = display.length;
    final width = count > 0 ? size + (count - 1) * (size - overlap) : 0.0;
    return SizedBox(
      width: width,
      height: size,
      child: Stack(
        children: List.generate(display.length, (i) {
          return Positioned(
            left: i * (size - overlap),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.black100, width: 1),
                image: display[i].isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(display[i]),
                        fit: BoxFit.cover,
                        onError: (_, __) {}, // Handle error silently
                      )
                    : null,
                color: display[i].isEmpty ? AppColors.greyDark : null, // Fallback color
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPlainAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          // for comment/share use SVG assets used in Home; otherwise fallback to Icon
          if (icon == Icons.comment)
            SvgPicture.asset(
              'assets/icons/comment.svg',
              width: 30,
              height: 30,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            )
          else if (icon == Icons.send)
            SvgPicture.asset(
              'assets/icons/share.svg',
              width: 30,
              height: 30,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            )
          else
            Icon(
              icon,
              color: color,
              size: 30,
              shadows: const [Shadow(color: Colors.black26, blurRadius: 4)],
            ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.pureWhite,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.pureWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Reels',
          style: TextStyle(
            color: AppColors.pureWhite,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        physics: const PageScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        pageSnapping: true,
        itemCount: _stories.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
            _showLikeAnimation = false;
            _expandedStories.clear();
          });
          
          if (index < _stories.length) {
            final story = _stories[index];
            widget.onStoryViewed?.call(story.id);
            _loadStoryDetails(story.id);
          }
        },
        itemBuilder: (context, index) {
          final story = _stories[index];
          
          // Add smooth vertical transitions if needed, or keep simple
          // Using ValueKey to force rebuild when story state changes
          return AnimatedBuilder(
            key: ValueKey('${story.id}_${story.isLiked}_${story.isViewed}_${story.likesCount}_${story.commentsCount}'),
            animation: _pageController,
            builder: (context, child) {
              // Standard scale/opacity logic for vertical list if desired
              double value = 1.0;
              double opacity = 1.0;
              
              if (_pageController.position.haveDimensions) {
                final currentPage = _pageController.page ?? 0.0;
                final offset = currentPage - index;
                
                // Subtle scale effect for neighbors
                value = (1 - (offset.abs() * 0.1)).clamp(0.9, 1.0);
                // Gentle opacity fade
                opacity = (1 - (offset.abs() * 0.3)).clamp(0.7, 1.0);
              }

              final isPlaying = index == (_pageController.hasClients ? (_pageController.page?.round() ?? 0) : 0);
              
              return Transform.scale(
                scale: value,
                child: Opacity(
                  opacity: opacity,
                  child: _buildReelItem(story, isCurrentUser: true, isPlaying: isPlaying),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Fetch updated story details (likes, comments, etc)
  Future<void> _loadStoryDetails(String storyId) async {
    try {
      final repository = StoriesRepository();
      final details = await repository.getStoryDetails(storyId);
      
      // Update local state with fresh details
      setState(() {
        final updatedStories = _stories.map((s) {
          if (s.id == storyId) {
            return s.copyWith(
              likesCount: details.likesCount,
              commentsCount: details.commentsCount,
              likedBy: details.likes.map((l) => LikedByUser(
                name: l.username,
                username: l.username, // Pass username as handle
                profileImage: l.avatarUrl ?? '',
              )).toList(),
            );
          }
          return s;
        }).toList();
        
        _stories = updatedStories;

      });
    } catch (e) {
      print('Error loading story details: $e');
    }
  }

  void _navigateToPreviousStory() {
    if (_currentIndex > 0) {
      _pageController.animateToPage(
        _currentIndex - 1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _navigateToNextStory() {
    if (_currentIndex < _stories.length - 1) {
      _pageController.animateToPage(
        _currentIndex + 1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Widget _buildReelItem(DiscoverStory story, {bool isCurrentUser = true, bool isPlaying = false}) {
    return GestureDetector(
      onDoubleTap: () => _handleDoubleTap(story.id, story.isLiked),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Left tap zone for previous story
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: MediaQuery.of(context).size.width * 0.3,
            child: GestureDetector(
              onTap: _navigateToPreviousStory,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Right tap zone for next story
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: MediaQuery.of(context).size.width * 0.3,
            child: GestureDetector(
              onTap: _navigateToNextStory,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Background Media (Image or Video)
          Container(
            color: Colors.black,
            child: Center(
              child: story.mediaType == 'VIDEO'
                  ? ReelVideoPlayer(
                      videoUrl: story.imageUrl ?? '',
                      isPlaying: isPlaying,
                    )
                  : Image.network(
                      story.imageUrl ?? '',
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                    ),
            ),
          ),

          // Solid black bar at top (Instagram style)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 100,
                color: Colors.black,
              ),
            ),
          ),

          // Solid black bar at bottom (Instagram style)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 140,
                color: Colors.black,
              ),
            ),
          ),

          // Dimming overlay when caption is expanded
          AnimatedOpacity(
            opacity: _isExpanded(story.id) ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: _isExpanded(story.id)
                ? Positioned.fill(
                    child: GestureDetector(
                      onTap: () => _toggleExpanded(story.id),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Like animation
          if (_showLikeAnimation)
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 400),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(
                      opacity: 1.0 - value,
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 120,
                      ),
                    ),
                  );
                },
              ),
            ),

          // Right side actions
          Positioned(
            right: 12,
            bottom: 40,
            child: _buildRightActions(story),
          ),

          // Bottom info
          Positioned(
            left: 16,
            right: 80,
            bottom: 40,
            child: _buildBottomInfo(story),
          ),
        ],
      ),
    );
  }

  Widget _buildRightActions(DiscoverStory story) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Like (same favorite icon as Home)
        Column(
          children: [
            GestureDetector(
              onTap: () => _handleLike(story.id),
              child: Icon(
                story.isLiked ? Icons.favorite : Icons.favorite_border,
                color: story.isLiked ? Colors.red : AppColors.pureWhite,
                size: 30,
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => _showLikes(story),
              child: Text(
                _formatCount(story.likesCount),
                style: const TextStyle(color: AppColors.pureWhite, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Comment (use Home SVG)
        GestureDetector(
          onTap: () => _showComments(story),
          child: Column(
            children: [
              SvgPicture.asset(
                'assets/icons/comment.svg',
                width: 28,
                height: 28,
                colorFilter: const ColorFilter.mode(AppColors.pureWhite, BlendMode.srcIn),
              ),
              const SizedBox(height: 6),
              Text(
                _formatCount(story.commentsCount),
                style: const TextStyle(color: AppColors.pureWhite, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Share (use Home SVG)
        GestureDetector(
          onTap: () => _showShareOptions(story),
          child: Column(
            children: [
              SvgPicture.asset(
                'assets/icons/share.svg',
                width: 26,
                height: 26,
                colorFilter: const ColorFilter.mode(AppColors.pureWhite, BlendMode.srcIn),
              ),
              const SizedBox(height: 6),
              const Text(
                'Share',
                style: TextStyle(color: AppColors.pureWhite, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // More options (plain icon)
        GestureDetector(
          onTap: () => _showMoreOptions(story),
          child: const Icon(Icons.more_vert, color: AppColors.pureWhite, size: 28),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.pureWhite,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  color: Colors.black,
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInfo(DiscoverStory story) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // User info
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(story.profileImage),
            ),
            const SizedBox(width: 12),
            Text(
              story.username,
              style: const TextStyle(
                color: AppColors.pureWhite,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.pureWhite, width: 1.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Follow',
                style: TextStyle(
                  color: AppColors.pureWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Content (caption) - tappable to expand/collapse with smooth animation
        GestureDetector(
          onTap: () => _toggleExpanded(story.id),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.fastOutSlowIn,
            alignment: Alignment.topLeft,
            child: Text(
              story.content,
              style: const TextStyle(
                color: AppColors.pureWhite,
                fontSize: 14,
                height: 1.3,
              ),
              maxLines: _isExpanded(story.id) ? null : 2,
              overflow: _isExpanded(story.id) ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Hashtags - show limited number unless expanded with smooth animation
        GestureDetector(
          onTap: () => _toggleExpanded(story.id),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.fastOutSlowIn,
            alignment: Alignment.topLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: (_isExpanded(story.id) ? story.hashtags : story.hashtags.take(math.min(3, story.hashtags.length))).map((tag) {
                return Text(
                  '#$tag',
                  style: const TextStyle(
                    color: Color(0xFFD4FC79),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList()
                ..addAll([
                  if (!_isExpanded(story.id) && story.hashtags.length > 3)
                    Text(
                      ' +${story.hashtags.length - 3} more',
                      style: const TextStyle(color: AppColors.white60, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                ]),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Liked by preview (overlapping avatars + ellipsis text)
        if (story.likesCount > 0 && story.likedBy.isNotEmpty)
          GestureDetector(
            onTap: () => _showLikes(story),
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  _buildOverlappingAvatars(
                    story.likedBy.take(3).map((user) => user.profileImage).toList(),
                    size: 20,
                    overlap: 6,
                    max: 3,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Liked by ${_getLikedByText(story)}',
                      style: const TextStyle(color: AppColors.white60, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),


      ],
    );
  }

  Widget _buildCommentsSheet(DiscoverStory story) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.black100,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.greyDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  'Comments',
                  style: TextStyle(
                    color: AppColors.pureWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(color: AppColors.greyDark, height: 1),
              // Comments list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: NetworkImage(
                              'https://i.pravatar.cc/150?img=${20 + index}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'User ${index + 1}',
                                  style: const TextStyle(
                                    color: AppColors.pureWhite,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Great workout! Keep it up! 💪',
                                  style: TextStyle(
                                    color: AppColors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${index + 1}h ago',
                                  style: const TextStyle(
                                    color: AppColors.white40,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.favorite_border,
                              color: AppColors.white60,
                              size: 20,
                            ),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Comment input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.black,
                  border: Border(
                    top: BorderSide(color: AppColors.greyDark),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: NetworkImage(story.profileImage),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        style: const TextStyle(color: AppColors.pureWhite),
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: TextStyle(color: AppColors.white60),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Color(0xFFD4FC79),
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareSheet(DiscoverStory story) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Share to',
            style: TextStyle(
              color: AppColors.pureWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _buildShareOption(Icons.message, 'Message', Colors.blue),
              _buildShareOption(Icons.link, 'Copy Link', Colors.green),
              _buildShareOption(Icons.share, 'Share', Colors.orange),
              _buildShareOption(Icons.bookmark, 'Save', Colors.purple),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildShareOption(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label clicked'),
            duration: const Duration(seconds: 1),
            backgroundColor: Color(0xFFD4FC79),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.pureWhite, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.pureWhite,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreOptionsSheet(DiscoverStory story) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMoreOption(Icons.report, 'Report', Colors.red, () {
            Navigator.pop(context);
          }),
          _buildMoreOption(Icons.block, 'Not Interested', AppColors.white70, () {
            Navigator.pop(context);
          }),
          _buildMoreOption(Icons.person_add_disabled, 'Hide', AppColors.white70, () {
            Navigator.pop(context);
          }),
          _buildMoreOption(Icons.info_outline, 'About this account', AppColors.white70, () {
            Navigator.pop(context);
          }),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.pureWhite,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'tiktok':
        return Icons.music_note;
      case 'instagram':
        return Icons.camera_alt;
      case 'youtube':
        return Icons.play_arrow;
      default:
        return Icons.public;
    }
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }



  String _getLikedByText(DiscoverStory story) {
    if (story.likesCount <= 0 || story.likedBy.isEmpty) return '';

    final buffer = StringBuffer();
    final displayCount = story.likedBy.length < 3 ? story.likedBy.length : 3;
    
    for (int i = 0; i < displayCount; i++) {
      buffer.write(story.likedBy[i].name);
      if (i == displayCount - 1 && story.likesCount > displayCount) {
        buffer.write(' and ${story.likesCount - displayCount} others');
      } else if (i < displayCount - 1) {
        buffer.write(', ');
      }
    }
    return buffer.toString();
  }
}

class ReelVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool isPlaying;

  const ReelVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.isPlaying,
  });

  @override
  State<ReelVideoPlayer> createState() => _ReelVideoPlayerState();
}

class _ReelVideoPlayerState extends State<ReelVideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _initialized = true;
          });
          if (widget.isPlaying) {
            _controller.play();
            _controller.setLooping(true);
          }
        }
      });
  }

  @override
  void didUpdateWidget(ReelVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying && _initialized) {
      if (widget.isPlaying) {
        _controller.play();
      } else {
        _controller.pause();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFD4FC79)),
      );
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }
}
