import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../data/mutual_feed_repository.dart';

class NutritionPostCard extends StatefulWidget {
  final String username;
  final String handle;
  final String profileImage;
  final String timeAgo;
  final List<NutritionMeal> meals;
  final int likes;
  final List<LikedByUser> likedBy;
  final bool isLiked;
  final VoidCallback onLike;
  final int commentCount;
  final VoidCallback onComment;
  final VoidCallback onLikesClick;

  const NutritionPostCard({
    super.key,
    required this.username,
    required this.handle,
    required this.profileImage,
    required this.timeAgo,
    required this.meals,
    required this.likes,
    required this.likedBy,
    this.isLiked = false,
    required this.onLike,
    required this.commentCount,
    required this.onComment,
    required this.onLikesClick,
  });

  @override
  State<NutritionPostCard> createState() => _NutritionPostCardState();
}

class _NutritionPostCardState extends State<NutritionPostCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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
          const SizedBox(height: 16),
          _buildMealCarousel(),
          const SizedBox(height: 12),
          _buildPageIndicator(),
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
          backgroundImage: NetworkImage(widget.profileImage),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.username,
                style: const TextStyle(
                  color: AppColors.pureWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.handle,
                style: const TextStyle(
                  color: AppColors.white60,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Text(
          widget.timeAgo,
          style: const TextStyle(
            color: AppColors.white60,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildMealCarousel() {
    return SizedBox(
      height: 340,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemCount: widget.meals.length,
        itemBuilder: (context, index) {
          return _buildMealCard(widget.meals[index]);
        },
      ),
    );
  }

  Widget _buildMealCard(NutritionMeal meal) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            meal.content,
            style: const TextStyle(
              color: AppColors.pureWhite,
              fontSize: 15,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          _buildMealImages(meal.images, meal.mealType),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMealNutritionItem('assets/icons/calories.svg', 'Calories', meal.calories.toString()),
              _buildMealNutritionItem('assets/icons/protein.svg', 'Protein', '${meal.protein}g'),
              _buildMealNutritionItem('assets/icons/carbs.svg', 'Carbs', '${meal.carbs}g'),
              _buildMealNutritionItem('assets/icons/fat.svg', 'Fats', '${meal.fats}g'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMealImages(List<String> images, String mealType) {
    if (images.isEmpty) {
      return const SizedBox.shrink();
    }

    // single image - keep badge centered on that image
    if (images.length == 1) {
      return SizedBox(
        height: 180,
        child: Container(
          color: Colors.black,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Center(
                  child: Image.network(
                    images[0],
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    mealType,
                    style: const TextStyle(
                      color: AppColors.pureWhite,
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ),
              ),
            ],
          ),
        ),
      );
    }

    // multiple images - stack the row and place one centered badge on top
    return SizedBox(
      height: 180,
      child: Stack(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  color: Colors.black,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Center(
                      child: Image.network(
                        images[0],
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  color: Colors.black,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Center(
                          child: Image.network(
                            images[1],
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                          ),
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
              ),
            ],
          ),
          // single badge centered across the entire images area
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  mealType,
                  style: const TextStyle(
                    color: AppColors.pureWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealNutritionItem(String iconPath, String label, String value) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconPath,
              width: 12,
              height: 12,
              colorFilter: const ColorFilter.mode(
                AppColors.white60,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.white60,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.meals.length,
        (index) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index ? AppColors.primary : AppColors.greyLight,
          ),
        ),
      ),
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
              onTap: widget.onLike,
              child: Icon(
                widget.isLiked ? Icons.favorite : Icons.favorite_border,
                color: widget.isLiked ? Colors.red : AppColors.pureWhite,
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: widget.onLikesClick,
              child: Text(
                '${widget.likes}',
                style: const TextStyle(
                  color: AppColors.pureWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 24),
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
                '${widget.commentCount}',
                style: const TextStyle(
                  color: AppColors.pureWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 24),
            SvgPicture.asset(
              'assets/icons/share.svg',
              width: 24,
              height: 24,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.likedBy.isNotEmpty)
          GestureDetector(
            onTap: widget.onLikesClick,
            child: Row(
              children: [
                ...widget.likedBy.take(3).map((user) => Align(
                  widthFactor: 0.7,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.greyDark,
                    backgroundImage: NetworkImage(user.profileImage),
                  ),
                )),
                const SizedBox(width: 8),
                Text(
                  'Liked by ${widget.likedBy[0].name} and others',
                  style: const TextStyle(
                    color: AppColors.white60,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
