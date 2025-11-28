import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    return Opacity(
      opacity: story.isViewed ? 0.7 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.black,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: Image.network(
                    story.imageUrl ?? '',
                    fit: BoxFit.contain,
                  ),
                ),
              Container(
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
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                // Profile avatar with Instagram-style ring
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Green gradient ring for unviewed stories
                    gradient: !story.isViewed
                        ? const LinearGradient(
                            colors: [
                              Color(0xFFBAE014),
                              Color(0xFFBAE014),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    // Grey border for viewed stories
                    border: story.isViewed
                        ? Border.all(color: AppColors.greyDark, width: 2)
                        : null,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: NetworkImage(story.profileImage),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
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
                
                // ...actions removed from card to keep Discover cards clean.
                // If you want a compact likes count on the card, add a single Text line here instead.
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
