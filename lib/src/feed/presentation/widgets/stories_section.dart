import 'package:flutter/material.dart';
import '../../data/stories_repository.dart';
import 'story_avatar.dart';

class StoriesSection extends StatelessWidget {
  final List<StoryUser> stories;
  final Function(String storyId)? onStoryTap;
  final VoidCallback? onAddStory;

  const StoriesSection({
    super.key,
    required this.stories,
    this.onStoryTap,
    this.onAddStory,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: stories.length + 1, // +1 for add story button
        itemBuilder: (context, index) {
          if (index == 0) {
            return StoryAvatar(
              imageUrl: '',
              username: 'Your Story',
              isAddStory: true,
              onTap: onAddStory,
            );
          }

          final story = stories[index - 1];
          return StoryAvatar(
            imageUrl: story.profileImage,
            username: story.username,
            hasStory: story.hasStory,
            isViewed: story.isViewed,
            onTap: () => onStoryTap?.call(story.id),
          );
        },
      ),
    );
  }
}
