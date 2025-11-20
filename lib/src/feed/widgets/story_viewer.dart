import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../data/stories_repository.dart';

class StoryViewer extends StatefulWidget {
  final List<StoryUser> stories;
  final int initialIndex;
  final Function(String storyId) onStoryViewed;

  const StoryViewer({
    super.key,
    required this.stories,
    required this.initialIndex,
    required this.onStoryViewed,
  });

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer>
    with SingleTickerProviderStateMixin {
  late PageController _userPageController;
  late AnimationController _progressController;
  int _currentUserIndex = 0;
  int _currentStoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentUserIndex = widget.initialIndex;
    _userPageController = PageController(initialPage: _currentUserIndex);
    _progressController = AnimationController(vsync: this);

    _startProgress();
  }

  void _startProgress() {
    final currentUser = widget.stories[_currentUserIndex];
    if (currentUser.stories.isEmpty) {
      _nextUser();
      return;
    }

    final currentStory = currentUser.stories[_currentStoryIndex];
    _progressController.duration = currentStory.duration;
    _progressController.reset();
    _progressController.forward().then((_) {
      _nextContent();
    });
  }

  void _nextContent() {
    final currentUser = widget.stories[_currentUserIndex];
    
    if (_currentStoryIndex < currentUser.stories.length - 1) {
      // Move to next story of same user
      setState(() {
        _currentStoryIndex++;
      });
      _startProgress();
    } else {
      // Move to next user
      _nextUser();
    }
  }

  void _previousContent() {
    if (_currentStoryIndex > 0) {
      // Go to previous story of same user
      setState(() {
        _currentStoryIndex--;
      });
      _startProgress();
    } else if (_currentUserIndex > 0) {
      // Go to previous user's last story
      _userPageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextUser() {
    if (_currentUserIndex < widget.stories.length - 1) {
      _userPageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _closeViewer();
    }
  }

  void _closeViewer() {
    Navigator.of(context).pop();
  }

  void _onUserPageChanged(int index) {
    setState(() {
      _currentUserIndex = index;
      _currentStoryIndex = 0;
    });
    
    // Mark user's story as viewed
    widget.onStoryViewed(widget.stories[index].id);
    
    _startProgress();
  }

  void _pauseProgress() {
    _progressController.stop();
  }

  void _resumeProgress() {
    if (_progressController.status == AnimationStatus.forward) {
      return;
    }
    _progressController.forward();
  }

  @override
  void dispose() {
    _userPageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          final tapPosition = details.globalPosition.dx;

          if (tapPosition < screenWidth / 2) {
            _previousContent();
          } else {
            _nextContent();
          }
        },
        onLongPressStart: (_) => _pauseProgress(),
        onLongPressEnd: (_) => _resumeProgress(),
        child: Stack(
          children: [
            // Story content
            PageView.builder(
              controller: _userPageController,
              onPageChanged: _onUserPageChanged,
              itemCount: widget.stories.length,
              itemBuilder: (context, userIndex) {
                final user = widget.stories[userIndex];
                if (user.stories.isEmpty) {
                  return _buildEmptyStory(user);
                }
                
                // Only show current story index for current user
                if (userIndex == _currentUserIndex) {
                  return _buildStoryContent(
                    user,
                    user.stories[_currentStoryIndex],
                  );
                }
                
                // For other users, show first story
                return _buildStoryContent(user, user.stories[0]);
              },
            ),

            // Top gradient overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Progress bars
            Positioned(
              top: 50,
              left: 8,
              right: 8,
              child: _buildProgressBars(),
            ),

            // Header
            Positioned(
              top: 65,
              left: 16,
              right: 16,
              child: _buildHeader(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStory(StoryUser user) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(user.profileImage),
            ),
            const SizedBox(height: 16),
            Text(
              user.username,
              style: const TextStyle(
                color: AppColors.pureWhite,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No stories available',
              style: TextStyle(
                color: AppColors.pureWhite.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryContent(StoryUser user, StoryContent story) {
    if (story.type == 'text') {
      return _buildTextStory(story);
    } else {
      return _buildImageStory(story);
    }
  }

  Widget _buildImageStory(StoryContent story) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(story.imageUrl!),
          fit: BoxFit.cover,
        ),
      ),
      child: story.text != null
          ? Container(
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  story.text!,
                  style: const TextStyle(
                    color: AppColors.pureWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildTextStory(StoryContent story) {
    Color bgColor = AppColors.black;
    if (story.backgroundColor != null) {
      bgColor = Color(
        int.parse(story.backgroundColor!.replaceFirst('#', '0xFF')),
      );
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: bgColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            story.text ?? '',
            style: TextStyle(
              color: _getContrastColor(bgColor),
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Color _getContrastColor(Color backgroundColor) {
    // Calculate luminance to determine if text should be black or white
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? AppColors.black : AppColors.pureWhite;
  }

  Widget _buildProgressBars() {
    final currentUser = widget.stories[_currentUserIndex];
    final storyCount = currentUser.stories.isNotEmpty 
        ? currentUser.stories.length 
        : 1;

    return Row(
      children: List.generate(
        storyCount,
        (index) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 3,
            child: AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) {
                double value;
                if (index < _currentStoryIndex) {
                  value = 1.0;
                } else if (index == _currentStoryIndex) {
                  value = _progressController.value;
                } else {
                  value = 0.0;
                }
                return LinearProgressIndicator(
                  value: value,
                  backgroundColor: AppColors.white40,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.pureWhite,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final user = widget.stories[_currentUserIndex];
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: NetworkImage(user.profileImage),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.username,
                style: const TextStyle(
                  color: AppColors.pureWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Just now',
                style: TextStyle(
                  color: AppColors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.close,
            color: AppColors.pureWhite,
          ),
          onPressed: _closeViewer,
        ),
      ],
    );
  }
}
