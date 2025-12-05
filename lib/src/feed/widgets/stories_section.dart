import 'package:flutter/material.dart';
import '../data/stories_repository.dart';
import 'story_avatar.dart';
import '../../../core/theme/app_colors.dart';

class StoriesSection extends StatelessWidget {
  final List<StoryUser> stories;
  final StoryUser? myStory; // Add myStory parameter
  final Function(String storyId)? onStoryTap;
  final VoidCallback? onAddStory;

  const StoriesSection({
    super.key,
    required this.stories,
    this.myStory,
    this.onStoryTap,
    this.onAddStory,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: stories.length + 1, // +1 for add story button
        separatorBuilder: (context, index) => const SizedBox(width: 12), // Fix: Add separator
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildAddStoryButton();
          }
          final story = stories[index - 1];
          return _buildStoryItem(story);
        },
      ),
    );
  }

  Widget _buildAddStoryButton() {
    final hasStory = myStory != null && myStory!.hasStory;
    
    return GestureDetector(
      onTap: () {
        if (hasStory) {
          // If user has story, open MyStoryViewer
          onStoryTap?.call(myStory!.id);
        } else {
          // Otherwise navigate to camera
          onAddStory?.call();
        }
      },
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasStory
                        ? const LinearGradient(
                            colors: [AppColors.primary, AppColors.primary],
                          )
                        : const LinearGradient(
                            colors: [Color(0xFFD4FC79), Color(0xFF8BC34A)],
                          ),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundImage: hasStory && myStory!.profileImage.isNotEmpty
                        ? NetworkImage(myStory!.profileImage)
                        : null,
                    backgroundColor: AppColors.black100,
                    child: !hasStory || myStory!.profileImage.isEmpty
                        ? const Icon(Icons.person, color: AppColors.white60, size: 32)
                        : null,
                  ),
                ),
                // Plus icon positioned at bottom right
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: onAddStory, // Always navigate to camera when plus is clicked
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.black, width: 2),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.black,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Your Story',
              style: TextStyle(
                color: AppColors.pureWhite,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryItem(StoryUser story) {
    return GestureDetector(
      onTap: () => onStoryTap?.call(story.id),
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: story.isViewed
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFFD4FC79), Color(0xFF8BC34A)],
                      ),
                border: story.isViewed
                    ? Border.all(color: AppColors.greyDark, width: 2)
                    : null,
              ),
              padding: const EdgeInsets.all(2),
              child: CircleAvatar(
                radius: 32,
                backgroundImage: story.profileImage.isNotEmpty
                    ? NetworkImage(story.profileImage)
                    : null,
                backgroundColor: AppColors.black100,
                child: story.profileImage.isEmpty
                    ? const Icon(Icons.person, color: AppColors.white60)
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              story.username,
              style: TextStyle(
                color: story.isViewed 
                    ? AppColors.white60 
                    : AppColors.pureWhite,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
