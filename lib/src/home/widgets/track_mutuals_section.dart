import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../data/mutual_feed_repository.dart';
import '../providers/feed_provider.dart';
import 'workout_post_card.dart';
import 'nutrition_post_card.dart';
import 'user_suggestions_carousel.dart';

class TrackMutualsSection extends StatefulWidget {
  final List<FeedPost> posts;
  final Function(String) onLike;
  final Function(String) onComment;
  final Function(String) onLikesClick;
  final Function(String) onDeletePost;
  final Function(FeedPost) onEditPost;

  const TrackMutualsSection({
    super.key,
    required this.posts,
    required this.onLike,
    required this.onComment,
    required this.onLikesClick,
    required this.onDeletePost,
    required this.onEditPost,
  });

  @override
  State<TrackMutualsSection> createState() => _TrackMutualsSectionState();
}

class _TrackMutualsSectionState extends State<TrackMutualsSection> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Workout', 'Diet', 'Challenges'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Text(
            'Track Mutuals',
            style: TextStyle(
              color: AppColors.pureWhite,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 32, // Reduced from 40 to 32
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final filter = _filters[index];
              final isSelected = filter == _selectedFilter;
              return _buildFilterChip(filter, isSelected);
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildWorkoutPosts(),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ), // Reduced from horizontal: 20, vertical: 8
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16), // Reduced from 20 to 16
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.white40,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.black : AppColors.white60,
              fontSize: 12, // Reduced from 14 to 12
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutPosts() {
    final displayPosts = widget.posts.where((post) {
      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Workout' && post is WorkoutPost) return true;
      if (_selectedFilter == 'Diet' && post is NutritionPost) return true;
      return false;
    }).toList();

    if (displayPosts.isEmpty) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: const Text(
          'No posts found',
          style: TextStyle(color: AppColors.white60),
        ),
      );
    }

    final feedProvider = context.watch<FeedProvider>();
    final suggestions = feedProvider.suggestions;

    return Column(
      children: [
        for (int i = 0; i < displayPosts.length; i++) ...[
          _buildPostCard(displayPosts[i]),

          // Suggestion injection logic
          // 1st suggestion after 1st card (index 0)
          // 2nd suggestion after 7 cards (index 7, so 7 cards after card 0)
          // frequency: every 7 cards
          if ((i == 0 || (i > 0 && i % 7 == 0)) &&
              suggestions.isNotEmpty &&
              _selectedFilter == 'All')
            UserSuggestionsCarousel(
              suggestions: suggestions,
              followedIds: feedProvider.followedIds,
              onFollow: (username, userId) {
                feedProvider.followUser(username, userId);
              },
              onSeeAll: () {
                // Navigate to all suggestions page if exists
              },
            ),
        ],
        // "All caught up" message at the end
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: AppColors.primary,
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text(
                "You're all caught up!",
                style: TextStyle(
                  color: AppColors.pureWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "You have seen all the new posts from the past few days.",
                style: TextStyle(color: AppColors.white60, fontSize: 14),
              ),
              const SizedBox(height: 100), // Extra padding for nav bar
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPostCard(FeedPost post) {
    if (post is WorkoutPost) {
      return WorkoutPostCard(
        id: post.id,
        name: post.name,
        username: post.username,
        handle: post.handle,
        profileImage: post.profileImage,
        timeAgo: post.timeAgo,
        content: post.content,
        tags: post.tags,
        images: post.images,
        duration: post.duration,
        volume: post.volume,
        records: post.records,
        exercises: post.exercises,
        likes: post.likes,
        likedBy: post.likedBy,
        isLiked: post.isLiked,
        isOwnPost: post.isOwnPost,
        commentCount: post.commentCount,
        onLike: () => widget.onLike(post.id),
        onComment: () => widget.onComment(post.id),
        onLikesClick: () => widget.onLikesClick(post.id),
        onDelete: () => widget.onDeletePost(post.id),
        onEdit: () => widget.onEditPost(post),
      );
    } else if (post is NutritionPost) {
      return NutritionPostCard(
        post: post,
        onLike: () => widget.onLike(post.id),
        onComment: () => widget.onComment(post.id),
        onLikesClick: () => widget.onLikesClick(post.id),
        onDelete: () => widget.onDeletePost(post.id),
        // Nutrition post edit not requested yet
      );
    }
    return const SizedBox.shrink();
  }
}
