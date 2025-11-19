import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/mutual_feed_repository.dart';
import 'workout_post_card.dart';
import 'nutrition_post_card.dart';

class TrackMutualsSection extends StatefulWidget {
  final List<FeedPost> posts;
  final Function(String) onLike;
  final Function(String) onComment;
  final Function(List<LikedByUser>) onLikesClick;

  const TrackMutualsSection({
    super.key,
    required this.posts,
    required this.onLike,
    required this.onComment,
    required this.onLikesClick,
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
          height: 40,
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
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
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutPosts() {
    return Column(
      children: widget.posts.map((post) {
        if (post is WorkoutPost) {
          return WorkoutPostCard(
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
            commentCount: post.commentCount,
            onLike: () => widget.onLike(post.id),
            onComment: () => widget.onComment(post.id),
            onLikesClick: () => widget.onLikesClick(post.likedBy),
          );
        } else if (post is NutritionPost) {
          return NutritionPostCard(
            username: post.username,
            handle: post.handle,
            profileImage: post.profileImage,
            timeAgo: post.timeAgo,
            meals: post.meals,
            likes: post.likes,
            likedBy: post.likedBy,
            isLiked: post.isLiked,
            commentCount: post.commentCount,
            onLike: () => widget.onLike(post.id),
            onComment: () => widget.onComment(post.id),
            onLikesClick: () => widget.onLikesClick(post.likedBy),
          );
        }
        return const SizedBox.shrink();
      }).toList(),
    );
  }
}
