
  Widget _buildStoryContent(StoryContent story) {
    if (story.type.toUpperCase() == 'VIDEO') {
      return VideoPlayerWidget(
        videoUrl: story.imageUrl,
        isPlaying: !_progressController.isAnimating ? false : true, // Basic pause check
        // We might want to link this better to user interaction (hold to pause)
        // But _progressController.isAnimating is a good proxy if we ensure it stops on long press.
        isLooping: true, 
      );
    } else if (story.type == 'image' && story.imageUrl != null) {
      return Image.network(
        story.imageUrl!,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppColors.greyDark,
          child: const Center(
             child: Icon(Icons.error, color: AppColors.pureWhite),
          ),
        ),
      );
    } else {
      return Container(
        color: AppColors.primary,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              story.text,
              style: const TextStyle(fontSize: 24, color: AppColors.black),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
  }
