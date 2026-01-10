import 'package:flutter/material.dart';
import '../../feed/data/stories_repository.dart';
import '../../feed/widgets/discover_story_card.dart';
import '../../../core/theme/app_colors.dart'; // Added theme import for manual fallback if needed

class HighlightGrid extends StatelessWidget {
  final List<DiscoverStory> highlights; // Changed to DiscoverStory
  final Function(DiscoverStory)? onHighlightTap;

  const HighlightGrid({
    super.key,
    required this.highlights,
    this.onHighlightTap,
  });

  @override
  Widget build(BuildContext context) {
    if (highlights.isEmpty) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(40),
        child: const Text(
          'No highlights yet',
          style: TextStyle(
            color: AppColors.white60,
            fontSize: 16,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.65,
      ),
      itemCount: highlights.length,
      itemBuilder: (context, index) {
        return AspectRatio(
          aspectRatio: 0.65, // Match aspect ratio
          child: DiscoverStoryCard(
            story: highlights[index],
            onTap: () => onHighlightTap?.call(highlights[index]),
          ),
        );
      },
    );
  }
}

// HighlightCard removed - replaced by DiscoverStoryCard reuse
