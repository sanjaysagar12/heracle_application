import 'package:flutter/material.dart';
import '../data/stories_repository.dart';
import 'story_avatar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/upload_manager.dart';
import 'dart:math' as math;

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
    
    return ListenableBuilder(
      listenable: UploadManager(),
      builder: (context, _) {
        final storyTask = UploadManager().activeTasks.cast<UploadTask?>().firstWhere(
          (t) => t?.type == 'story',
          orElse: () => null,
        );
        final isUploading = storyTask != null;

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
                  alignment: Alignment.center,
                  children: [
                    if (isUploading)
                      const _RotatingStoryBorder(),
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: hasStory && !isUploading
                            ? const LinearGradient(
                                colors: [AppColors.primary, AppColors.primary],
                              )
                            : null, // No gradient (green ring) if no story
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.black, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 32,
                          // Always show profile image if available
                          backgroundImage: (myStory?.profileImage.isNotEmpty ?? false)
                              ? NetworkImage(myStory!.profileImage)
                              : null,
                          backgroundColor: AppColors.black100,
                          // Show person icon only if no profile image
                          child: (myStory?.profileImage.isEmpty ?? true)
                              ? const Icon(Icons.person, color: AppColors.white60, size: 32)
                              : null,
                        ),
                      ),
                    ),
                    // Plus icon positioned at bottom right
                    if (!isUploading)
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
      },
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

class _RotatingStoryBorder extends StatefulWidget {
  const _RotatingStoryBorder();

  @override
  State<_RotatingStoryBorder> createState() => _RotatingStoryBorderState();
}

class _RotatingStoryBorderState extends State<_RotatingStoryBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  Colors.transparent,
                  AppColors.primary,
                  AppColors.primary,
                  Colors.transparent,
                ],
                stops: [0.0, 0.2, 0.8, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }
}
