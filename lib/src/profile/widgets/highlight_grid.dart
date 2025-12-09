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
      padding: const EdgeInsets.all(2),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
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
          borderRadius: BorderRadius.circular(4),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
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
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: AppColors.greyDark,
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
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
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // Platform badge (TikTok)
              if (highlight.platform != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildPlatformBadge(highlight.platform!),
                ),
              // Views count
              Positioned(
                bottom: 8,
                left: 8,
                child: Row(
                  children: [
                    const Icon(
                      Icons.play_arrow,
                      color: AppColors.pureWhite,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      highlight.formattedViews,
                      style: const TextStyle(
                        color: AppColors.pureWhite,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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

  Widget _buildPlatformBadge(String platform) {
    IconData icon;
    Color bgColor;
    
    switch (platform.toLowerCase()) {
      case 'tiktok':
        icon = Icons.music_note;
        bgColor = Colors.black;
        break;
      case 'instagram':
        icon = Icons.camera_alt;
        bgColor = Colors.pink;
        break;
      case 'youtube':
        icon = Icons.play_arrow;
        bgColor = Colors.red;
        break;
      default:
        icon = Icons.video_library;
        bgColor = AppColors.greyDark;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        icon,
        color: AppColors.pureWhite,
        size: 14,
      ),
    );
  }
}
