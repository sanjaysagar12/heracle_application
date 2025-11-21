import 'package:flutter/material.dart';
import '../data/stories_repository.dart';
import 'discover_story_card.dart';

class DiscoverStoriesGrid extends StatelessWidget {
  final List<DiscoverStory> stories;
  final Function(DiscoverStory story)? onStoryTap;

  const DiscoverStoriesGrid({
    super.key,
    required this.stories,
    this.onStoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.6, // reverted back to previous taller ratio
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final story = stories[index];
            return DiscoverStoryCard(
              key: ValueKey('${story.id}_${story.isViewed}'),
              story: story,
              onTap: () => onStoryTap?.call(story),
            );
          },
          childCount: stories.length,
        ),
      ),
    );
  }
}
