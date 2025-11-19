import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/mutual_feed_repository.dart';

class WorkoutPostCard extends StatelessWidget {
  final String username;
  final String handle;
  final String profileImage;
  final String timeAgo;
  final String content;
  final List<String> tags;
  final List<String> images;
  final String duration;
  final String volume;
  final String records;
  final List<Exercise> exercises;
  final int likes;
  final List<LikedByUser> likedBy;
  final bool isLiked;
  final VoidCallback onLike;
  final int commentCount;
  final VoidCallback onComment;

  const WorkoutPostCard({
    super.key,
    required this.username,
    required this.handle,
    required this.profileImage,
    required this.timeAgo,
    required this.content,
    required this.tags,
    required this.images,
    required this.duration,
    required this.volume,
    required this.records,
    required this.exercises,
    required this.likes,
    required this.likedBy,
    this.isLiked = false,
    required this.onLike,
    required this.commentCount,
    required this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.black100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          _buildContent(),
          const SizedBox(height: 12),
          _buildTags(),
          const SizedBox(height: 16),
          _buildImages(),
          const SizedBox(height: 16),
          _buildStats(),
          const SizedBox(height: 16),
          _buildExercises(),
          const SizedBox(height: 16),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundImage: NetworkImage(profileImage),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username,
                style: const TextStyle(
                  color: AppColors.pureWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                handle,
                style: const TextStyle(
                  color: AppColors.white60,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Text(
          timeAgo,
          style: const TextStyle(
            color: AppColors.white60,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Text(
      content,
      style: const TextStyle(
        color: AppColors.pureWhite,
        fontSize: 15,
        height: 1.4,
      ),
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 8,
      children: tags.map((tag) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.greyDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          tag,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 13,
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildImages() {
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                images[0],
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    images[1],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                if (images.length > 2)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '+${images.length - 2}',
                          style: const TextStyle(
                            color: AppColors.pureWhite,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        _buildStatItem('Duration', duration),
        const SizedBox(width: 24),
        _buildStatItem('Volume', volume),
        const SizedBox(width: 24),
        _buildStatItem('Records', records),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.white60,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.pureWhite,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildExercises() {
    return Column(
      children: [
        ...exercises.take(3).map((exercise) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.greyDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: AppColors.white60,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  exercise.name,
                  style: const TextStyle(
                    color: AppColors.pureWhite,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        )),
        if (exercises.length > 3)
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
            ),
            child: Text(
              'See ${exercises.length - 3} more exercises',
              style: const TextStyle(
                color: AppColors.white60,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Divider(color: AppColors.greyDark, height: 1),
        const SizedBox(height: 16),
        Row(
          children: [
            GestureDetector(
              onTap: onLike,
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.red : AppColors.pureWhite,
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$likes',
              style: const TextStyle(
                color: AppColors.pureWhite,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 24),
            GestureDetector(
              onTap: onComment,
              child: const Icon(
                Icons.chat_bubble_outline,
                color: AppColors.pureWhite,
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$commentCount',
              style: const TextStyle(
                color: AppColors.pureWhite,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 24),
            const Icon(Icons.send_outlined, color: AppColors.pureWhite, size: 24),
          ],
        ),
        const SizedBox(height: 12),
        if (likedBy.isNotEmpty)
          Row(
            children: [
              ...likedBy.take(3).map((user) => Align(
                widthFactor: 0.7,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.greyDark,
                  backgroundImage: NetworkImage(user.profileImage),
                ),
              )),
              const SizedBox(width: 8),
              Text(
                'Liked by ${likedBy[0].name} and others',
                style: const TextStyle(
                  color: AppColors.white60,
                  fontSize: 13,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class Exercise {
  final String name;

  Exercise({required this.name});
}
