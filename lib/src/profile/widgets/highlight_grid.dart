import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../data/profile_repository.dart';

class HighlightGrid extends StatelessWidget {
  final List<HighlightVideo> highlights;
  final Function(HighlightVideo)? onHighlightTap;

  const HighlightGrid({
    super.key,
    required this.highlights,
    this.onHighlightTap,
  });

  @override
  Widget build(BuildContext context) {
    if (highlights.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text(
            'No highlights yet',
            style: TextStyle(
              color: AppColors.white60,
              fontSize: 16,
            ),
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
        return HighlightCard(
          highlight: highlights[index],
          onTap: () => onHighlightTap?.call(highlights[index]),
        );
      },
    );
  }
}

class HighlightCard extends StatelessWidget {
  final HighlightVideo highlight;
  final VoidCallback? onTap;

  const HighlightCard({
    super.key,
    required this.highlight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.greyDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail Image
              Image.network(
                highlight.thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.greyDark,
                    child: const Center(
                      child: Icon(
                        Icons.video_library,
                        color: AppColors.white40,
                        size: 30,
                      ),
                    ),
                  );
                },
              ),
              // Gradient overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              
              // Views count
              Positioned(
                bottom: 12,
                left: 12,
                child: Row(
                  children: [
                    const Icon(
                      Icons.play_circle_fill,
                      color: AppColors.pureWhite,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      highlight.formattedViews,
                      style: const TextStyle(
                        color: AppColors.pureWhite,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                      ),
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


}
