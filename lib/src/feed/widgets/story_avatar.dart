import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class StoryAvatar extends StatelessWidget {
  final String imageUrl;
  final String username;
  final bool hasStory;
  final bool isViewed;
  final bool isAddStory;
  final VoidCallback? onTap;

  const StoryAvatar({
    super.key,
    required this.imageUrl,
    required this.username,
    this.hasStory = false,
    this.isViewed = false,
    this.isAddStory = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 75, // Fixed width container
        margin: const EdgeInsets.only(right: 8), // Reduced margin
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasStory && !isViewed
                        ? const LinearGradient(
                            colors: [
                              Color(0xFFBAE014),
                              Color(0xFFBAE014),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    border: isViewed
                        ? Border.all(color: AppColors.greyDark, width: 2)
                        : null,
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.greyDark,
                      image: isAddStory
                          ? null
                          : DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                            ),
                    ),
                    child: isAddStory
                        ? const Icon(
                            Icons.person_outline,
                            color: AppColors.greyLight,
                            size: 40,
                          )
                        : null,
                  ),
                ),
                if (isAddStory)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFBAE014),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.black,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 75,
              child: Text(
                username,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: const TextStyle(
                  color: AppColors.pureWhite,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
