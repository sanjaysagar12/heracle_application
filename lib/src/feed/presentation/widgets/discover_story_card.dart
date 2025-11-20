import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/stories_repository.dart';

class DiscoverStoryCard extends StatelessWidget {
  final DiscoverStory story;
  final VoidCallback? onTap;
  final VoidCallback? onLike;

  const DiscoverStoryCard({
    super.key,
    required this.story,
    this.onTap,
    this.onLike,
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
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Top section with platform and label
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPlatformBadge(),
                    if (story.label != null) _buildLabel(),
                  ],
                ),
              ),
              
              // Bottom section with user info
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: NetworkImage(story.profileImage),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                story.username,
                                style: const TextStyle(
                                  color: AppColors.pureWhite,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                story.content,
                                style: TextStyle(
                                  color: AppColors.pureWhite.withOpacity(0.8),
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Like button and hashtags row
                    Row(
                      children: [
                        // Like button
                        GestureDetector(
                          onTap: () {
                            if (onLike != null) {
                              onLike!();
                            }
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: story.isLiked
                                  ? const Color(0xFFD4FC79)
                                  : Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: story.isLiked
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFD4FC79)
                                            .withOpacity(0.4),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      )
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  story.isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: story.isLiked
                                      ? AppColors.black
                                      : AppColors.pureWhite,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${story.likesCount}',
                                  style: TextStyle(
                                    color: story.isLiked
                                        ? AppColors.black
                                        : AppColors.pureWhite,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (story.hashtags.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              children: story.hashtags
                                  .map((tag) => Text(
                                        '#$tag',
                                        style: TextStyle(
                                          color: AppColors.pureWhite
                                              .withOpacity(0.7),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformBadge() {
    IconData icon;
    String text;
    
    switch (story.platform.toLowerCase()) {
      case 'tiktok':
        icon = Icons.music_note;
        text = story.platformHandle;
        break;
      case 'instagram':
        icon = Icons.camera_alt;
        text = story.platformHandle;
        break;
      case 'youtube':
        icon = Icons.play_arrow;
        text = story.platformHandle;
        break;
      default:
        icon = Icons.public;
        text = story.platformHandle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppColors.pureWhite,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.pureWhite,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        story.label!,
        style: const TextStyle(
          color: AppColors.black,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
