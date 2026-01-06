import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../data/mutual_feed_repository.dart';

class NutritionPostCard extends StatefulWidget {
  final NutritionPost post;
  final VoidCallback onDelete;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onLikesClick;

  const NutritionPostCard({
    super.key,
    required this.post,
    required this.onDelete,
    required this.onLike,
    required this.onComment,
    required this.onLikesClick,
  });

  @override
  State<NutritionPostCard> createState() => _NutritionPostCardState();
}

class _NutritionPostCardState extends State<NutritionPostCard> {
  int _currentMealIndex = 0;
  
  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.black100,
        title: const Text('Delete Post', style: TextStyle(color: AppColors.pureWhite)),
        content: const Text('Are you sure you want to delete this post?', style: TextStyle(color: AppColors.white60)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.white60)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      widget.onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.post;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.black100,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(item.profileImage.isNotEmpty 
                      ? item.profileImage 
                      : 'https://ui-avatars.com/api/?name=${item.username}&background=random'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.username, 
                          style: const TextStyle(
                            color: AppColors.pureWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                         const SizedBox(width: 4),
                         const Icon(Icons.verified, size: 14, color: AppColors.primary),
                      ],
                    ),
                    Text(
                      item.handle,
                      style: const TextStyle(
                        color: AppColors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                item.timeAgo,
                style: const TextStyle(
                  color: AppColors.white60,
                  fontSize: 12,
                ),
              ),
              if (item.isOwnPost) ...[
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.white60),
                  color: AppColors.black100,
                  onSelected: (value) {
                    if (value == 'delete') _confirmDelete();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),
          
          // Dynamic Caption (Meal Content or Post Content)
          Builder(
            builder: (context) {
              final currentContent = (item.meals.isNotEmpty && _currentMealIndex < item.meals.length && item.meals[_currentMealIndex].content.isNotEmpty)
                  ? item.meals[_currentMealIndex].content
                  : item.content;

              if (currentContent.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentContent,
                    style: const TextStyle(
                      color: AppColors.pureWhite,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),

          // Meal Carousel
          if (item.meals.isNotEmpty) ...[
             AspectRatio(
               aspectRatio: 16/10, // Adjust based on your image needs
               child: PageView.builder(
                 itemCount: item.meals.length,
                 onPageChanged: (index) {
                   setState(() {
                     _currentMealIndex = index;
                   });
                 },
                 itemBuilder: (context, index) {
                   return _buildMealPage(item.meals[index]);
                 },
               ),
             ),
             const SizedBox(height: 12),
             
             // Indicators
             if (item.meals.length > 1)
               Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: List.generate(item.meals.length, (index) {
                   return Container(
                     width: 8,
                     height: 8,
                     margin: const EdgeInsets.symmetric(horizontal: 4),
                     decoration: BoxDecoration(
                       shape: BoxShape.circle,
                       color: _currentMealIndex == index 
                           ? AppColors.white60 
                           : AppColors.white10,
                     ),
                   );
                 }),
               ),
          ],

          const SizedBox(height: 16),

          const Divider(color: AppColors.greyDark, height: 1),
          const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              // Like
              GestureDetector(
                onTap: widget.onLike,
                child: Icon(
                  item.isLiked ? Icons.favorite : Icons.favorite_border,
                  color: item.isLiked ? Colors.red : AppColors.pureWhite,
                  size: 24,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.onLikesClick,
                child: Text(
                  '${item.likes}',
                  style: const TextStyle(
                    color: AppColors.pureWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(width: 24),
              
              // Comment
              GestureDetector(
                onTap: widget.onComment,
                child: SvgPicture.asset(
                  'assets/icons/comment.svg',
                  width: 24,
                  height: 24,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.onComment,
                child: Text(
                  '${item.commentCount}', 
                  style: const TextStyle(
                    color: AppColors.pureWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              const SizedBox(width: 24),
              // Share
              SvgPicture.asset(
                'assets/icons/share.svg',
                width: 24,
                height: 24,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (item.likedBy.isNotEmpty)
            GestureDetector(
              onTap: widget.onLikesClick,
              child: Row(
                children: [
                  ...item.likedBy.take(3).map((user) => Align(
                    widthFactor: 0.7,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.greyDark,
                      backgroundImage: NetworkImage(user.profileImage),
                    ),
                  )),
                  const SizedBox(width: 8),
                  Text(
                    'Liked by ${item.likedBy[0].name} and others',
                    style: const TextStyle(
                      color: AppColors.white60,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMealPage(NutritionMeal meal) {
    return Column(
      children: [
        // Image with Badge
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: NetworkImage(meal.images.isNotEmpty 
                    ? meal.images.first 
                    : 'https://dummyimage.com/600x400/000/fff'),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      meal.mealType,
                      style: const TextStyle(
                        color: AppColors.pureWhite,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Macros
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
             _buildMacroItem('Calories', '${meal.calories}', Icons.local_fire_department, AppColors.primary),
             _buildMacroItem('Protein', '${meal.protein}g', Icons.fitness_center, AppColors.primary),
             _buildMacroItem('Carbs', '${meal.carbs}g', Icons.grain, AppColors.primary),
             _buildMacroItem('Fats', '${meal.fats}g', Icons.opacity, AppColors.primary),
          ],
        ),
      ],
    );
  }

  Widget _buildMacroItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.white60, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: AppColors.white60, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color, 
            fontWeight: FontWeight.bold, 
            fontSize: 16
          ),
        ),
      ],
    );
  }
}
