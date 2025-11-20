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
                // Username
                Text(
                  story.username,
                  style: const TextStyle(
                    color: AppColors.pureWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                
                // Description
                Text(
                  story.content,
                  style: TextStyle(
                    color: AppColors.pureWhite.withOpacity(0.9),
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // Hashtags
                if (story.hashtags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: story.hashtags
                        .take(3) // Limit to 3 hashtags
                        .map((tag) => Text(
                              '#$tag',
                              style: TextStyle(
                                color: AppColors.pureWhite.withOpacity(0.8),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
