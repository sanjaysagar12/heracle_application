import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class NutritionPostCard extends StatelessWidget {
  final String username;
  final String handle;
  final String profileImage;
  final String timeAgo;
  final String content;
  final List<String> images;
  final int calories;
  final int protein;
  final int carbs;
  final int fats;
  final int likes;
  final List<String> likedBy;
  final bool isLiked;
  final VoidCallback onLike;
  final int commentCount;
  final VoidCallback onComment;

  const NutritionPostCard({
    super.key,
    required this.username,
    required this.handle,
    required this.profileImage,
    required this.timeAgo,
    required this.content,
    required this.images,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
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
          const SizedBox(height: 16),
          _buildImages(),
          const SizedBox(height: 16),
          _buildNutritionStats(),
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

  Widget _buildNutritionStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildNutritionItem('🔥 Calories', calories.toString(), AppColors.white70),
        _buildNutritionItem('💪 Protein', '${protein}g', AppColors.primary),
        _buildNutritionItem('🍞 Carbs', '${carbs}g', AppColors.primary),
        _buildNutritionItem('🥑 Fats', '${fats}g', AppColors.primary),
      ],
    );
  }

  Widget _buildNutritionItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.white60,
            fontSize: 11,
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
        Row(
          children: [
            ...likedBy.take(3).map((avatar) => Align(
              widthFactor: 0.7,
              child: CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.greyDark,
                backgroundImage: NetworkImage(avatar),
              ),
            )),
            const SizedBox(width: 8),
            Text(
              'Liked by ${likedBy[0].split('/').last} and others',
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
