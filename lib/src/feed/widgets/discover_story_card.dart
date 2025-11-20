import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../data/stories_repository.dart';

class DiscoverStoryCard extends StatelessWidget {
  final DiscoverStory story;
  final VoidCallback? onTap;

  const DiscoverStoryCard({
    super.key,
    required this.story,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: NetworkImage(story.imageUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Profile avatar
                CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(story.profileImage),
                ),
                const SizedBox(height: 8),
                
                // Username (bold, directly under profile)
                Text(
                  story.username,
                  style: const TextStyle(
                    color: AppColors.pureWhite,
                    fontSize: 15, // increased size
                    fontWeight: FontWeight.w700, // explicit bold
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                
                // Description with hashtag inline
                RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: TextStyle(
                      color: AppColors.pureWhite.withOpacity(0.9),
                      fontSize: 11,
                    ),
                    children: [
                      TextSpan(
                        text: story.content.length > 25 
                            ? '${story.content.substring(0, 25)}... '
                            : '${story.content} ',
                      ),
                      if (story.hashtags.isNotEmpty)
                        TextSpan(
                          text: '#${story.hashtags.first}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
