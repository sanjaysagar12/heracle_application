import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/stories_repository.dart';
// import Home comments widget and mutual feed types/repo
import '../../../home/presentation/widgets/comments_bottom_sheet.dart';
import '../../../home/data/mutual_feed_repository.dart';

class ReelsTab extends StatefulWidget {
  final List<DiscoverStory> stories;
  final int initialIndex;
  final List<DiscoverStory> Function(String storyId) onLike;

  const ReelsTab({
    super.key,
    required this.stories,
    this.initialIndex = 0,
    required this.onLike,
  });

  @override
  State<ReelsTab> createState() => _ReelsTabState();
}

class _ReelsTabState extends State<ReelsTab> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _showLikeAnimation = false;
  late List<DiscoverStory> _stories;

  // Added: mutual feed repo and comments cache to reuse Home comments UI
  final MutualFeedRepository _mutualFeedRepository = MutualFeedRepository();
  final Map<String, List<Comment>> _commentsCache = {};

  @override
  void initState() {
    super.initState();
    _stories = widget.stories;
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleDoubleTap(String storyId, bool isLiked) {
    // Toggle like state and get updated stories
    final updatedStories = widget.onLike(storyId);
    
    setState(() {
      _stories = updatedStories;
    });
    
    // Show animation only when liking (not unliking)
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

  void _handleLike(String storyId) {
    // Toggle like state and get updated stories
    final updatedStories = widget.onLike(storyId);
    
    setState(() {
      _stories = updatedStories;
    });
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

  Future<void> _showComments(DiscoverStory story) async {
    try {
      // Fetch comments once and cache them
      if (!_commentsCache.containsKey(story.id)) {
        final comments = await _mutualFeedRepository.getPostComments(story.id);
        _commentsCache[story.id] = comments;
      }
      
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) => CommentsBottomSheet(
                comments: _commentsCache[story.id] ?? [],
                onAddComment: (content) async {
                  // Add comment via repo and update cache + UI
                  final newComment = await _mutualFeedRepository.addComment(story.id, content);
                  setState(() {
                    _commentsCache[story.id] = [...(_commentsCache[story.id] ?? []), newComment];
                  });
                  setModalState(() {}); // refresh modal content
                },
                onAddReply: (commentId, content) async {
                  final newReply = await _mutualFeedRepository.addReply(story.id, commentId, content);
                  setState(() {
                    final current = _commentsCache[story.id] ?? [];
                    _commentsCache[story.id] = _addReplyToComment(current, commentId, newReply);
                  });
                  setModalState(() {}); // refresh modal content
                },
              ),
            );
          },
        ),
      );
    } catch (e) {
      print('Error loading comments: $e');
      // optionally show a snackbar
    }
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
        itemCount: _stories.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
            _showLikeAnimation = false;
          });
        },
        itemBuilder: (context, index) {
          final story = _stories[index];
          return _buildReelItem(story);
        },
      ),
    );
  }

  Widget _buildReelItem(DiscoverStory story) {
    return GestureDetector(
      onDoubleTap: () => _handleDoubleTap(story.id, story.isLiked),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.network(
            story.imageUrl,
            fit: BoxFit.cover,
          ),

          // Gradient overlays
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),

          // Top gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
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
            bottom: 100,
            child: _buildRightActions(story),
          ),

          // Bottom info
          Positioned(
            left: 16,
            right: 80,
            bottom: 100,
            child: _buildBottomInfo(story),
          ),
        ],
      ),
    );
  }

  Widget _buildRightActions(DiscoverStory story) {
    return Column(
      children: [
        // Like button
        _buildActionButton(
          icon: story.isLiked ? Icons.favorite : Icons.favorite_border,
          label: _formatCount(story.likesCount),
          color: story.isLiked ? Colors.red : AppColors.pureWhite,
          onTap: () => _handleLike(story.id),
        ),
        const SizedBox(height: 24),

        // Comment button
        _buildActionButton(
          icon: Icons.comment,
          label: '${_getRandomCommentCount()}',
          color: AppColors.pureWhite,
          onTap: () => _showComments(story),
        ),
        const SizedBox(height: 24),

        // Share button
        _buildActionButton(
          icon: Icons.send,
          label: 'Share',
          color: AppColors.pureWhite,
          onTap: () => _showShareOptions(story),
        ),
        const SizedBox(height: 24),

        // More options
        GestureDetector(
          onTap: () => _showMoreOptions(story),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.more_vert,
              color: AppColors.pureWhite,
              size: 24,
            ),
          ),
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
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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

        // Content
        Text(
          story.content,
          style: const TextStyle(
            color: AppColors.pureWhite,
            fontSize: 14,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),

        // Hashtags
        Wrap(
          spacing: 8,
          children: story.hashtags
              .map(
                (tag) => Text(
                  '#$tag',
                  style: const TextStyle(
                    color: Color(0xFFD4FC79),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),

        // Platform badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getPlatformIcon(story.platform),
                color: AppColors.pureWhite,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                story.platformHandle,
                style: const TextStyle(
                  color: AppColors.pureWhite,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
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

  int _getRandomCommentCount() {
    return 15 + (_currentIndex * 7) % 50;
  }
}
