import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../data/stories_repository.dart';
import '../../home/widgets/likes_bottom_sheet.dart';

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

  // Local like state for each story
  final Map<String, bool> _likedStories = {};
  // For vertical drag to show likes
  double _verticalDragOffset = 0.0;

  StoryContent get _currentStory {
    final currentUser = widget.stories[_currentUserIndex];
    return currentUser.stories[_currentStoryIndex];
  }

  @override
  void initState() {
    super.initState();
    _currentUserIndex = widget.initialIndex;
    _userPageController = PageController(initialPage: _currentUserIndex);
    _progressController = AnimationController(vsync: this);

    // Mark initial user's story as viewed after the build phase completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onStoryViewed(widget.stories[_currentUserIndex].id);
    });
    
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
      _userPageController.animateToPage(
        _currentUserIndex - 1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _nextUser() {
    if (_currentUserIndex < widget.stories.length - 1) {
      _userPageController.animateToPage(
        _currentUserIndex + 1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    } else {
      _closeViewer();
    }
  }

  void _closeViewer() {
    Navigator.of(context).pop();
  }

  void _showStoryOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.black100,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.report, color: Colors.red),
              title: const Text('Report', style: TextStyle(color: AppColors.pureWhite)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Reported'),
                  backgroundColor: Color(0xFFD4FC79),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.volume_off, color: AppColors.pureWhite),
              title: const Text('Mute', style: TextStyle(color: AppColors.pureWhite)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Muted'),
                  backgroundColor: Color(0xFFD4FC79),
                ));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showLikesBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => LikesBottomSheet(likedByUsers: _currentStory.likedBy),
    );
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
        onVerticalDragUpdate: (details) {
          setState(() => _verticalDragOffset += details.delta.dy);
        },
        onVerticalDragEnd: (details) {
          if (_verticalDragOffset < -100) { // dragged up
            _showLikesBottomSheet();
          }
          setState(() => _verticalDragOffset = 0.0);
        },
        child: Stack(
          children: [
            // Story content
            // Story content with parallax/scale transition between users
            SizedBox.expand(
              child: PageView.builder(
                controller: _userPageController,
                onPageChanged: _onUserPageChanged,
                itemCount: widget.stories.length,
                itemBuilder: (context, userIndex) {
                  final user = widget.stories[userIndex];
                  return AnimatedBuilder(
                    animation: _userPageController,
                    builder: (context, child) {
                      final pageValue = (_userPageController.hasClients && _userPageController.page != null)
                          ? _userPageController.page!
                          : _currentUserIndex.toDouble();

                      final offset = (pageValue - userIndex);
                      final clamped = offset.clamp(-1.0, 1.0);

                      // horizontal translation (parallax) - Instagram-like smooth slide
                      final dx = clamped * MediaQuery.of(context).size.width * 0.8;

                      // smooth scale when moving between pages (Instagram effect)
                      final scale = (1 - clamped.abs() * 0.08).clamp(0.92, 1.0);

                      // smooth fade at edges
                      final opacity = (1 - clamped.abs() * 0.5).clamp(0.5, 1.0);

                      // select story content for this user (current user's active story, otherwise first)
                      final StoryContent? storyContent = user.stories.isEmpty
                          ? null
                          : (userIndex == _currentUserIndex ? user.stories[_currentStoryIndex] : user.stories[0]);

                      final pageChild = storyContent == null ? _buildEmptyStory(user) : _buildStoryContent(user, storyContent);

                      return Transform.translate(
                        offset: Offset(dx, 0),
                        child: Transform.scale(
                          scale: scale,
                          alignment: Alignment.center,
                          child: Opacity(
                            opacity: opacity,
                            child: pageChild,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Solid black bar at top (Instagram style)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  height: 40,
                  color: Colors.black,
                ),
              ),
            ),

            // Solid black bar at bottom (Instagram style)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  height: 100,
                  color: Colors.black,
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

            // Header (updated: loading ring + avatar, username, 3-dot menu)
            Positioned(
              top: 65,
              left: 16,
              right: 16,
              child: _buildHeader(),
            ),

            // Bottom action bar (message input, like, share)
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: _buildBottomActions(),
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
      color: Colors.black,
      child: Center(
        child: Image.network(
          story.imageUrl!,
          fit: BoxFit.contain,
        ),
      ),
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
            height: 2,
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
                return ClipRRect(
                  borderRadius: BorderRadius.circular(1),
                  child: LinearProgressIndicator(
                    value: value,
                    backgroundColor: AppColors.white40,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.pureWhite,
                    ),
                    minHeight: 2,
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
        // Loading ring around avatar
        SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  value: _progressController.isAnimating ? _progressController.value : null,
                  strokeWidth: 2.8,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.pureWhite),
                  backgroundColor: AppColors.white40,
                ),
              ),
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(user.profileImage),
              ),
            ],
          ),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Just now',
                style: const TextStyle(
                  color: AppColors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // 3-dot menu instead of close icon
        IconButton(
          icon: const Icon(
            Icons.more_vert,
            color: AppColors.pureWhite,
          ),
          onPressed: _showStoryOptions,
        ),
      ],
    );
  }



  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.white40),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: AppColors.pureWhite),
                      decoration: const InputDecoration(
                        hintText: 'Send message',
                        hintStyle: TextStyle(color: AppColors.white60),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onSubmitted: (text) {
                        if (text.trim().isEmpty) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Message sent: $text'),
                            backgroundColor: const Color(0xFFD4FC79),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Like button (toggles local state)
          GestureDetector(
            onTap: () => setState(() => _likedStories[_currentStory.id] = !(_likedStories[_currentStory.id] ?? _currentStory.isLiked)),
            child: Icon(
              (_likedStories[_currentStory.id] ?? _currentStory.isLiked) ? Icons.favorite : Icons.favorite_border,
              color: (_likedStories[_currentStory.id] ?? _currentStory.isLiked) ? Colors.red : AppColors.pureWhite,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          // Share icon (use SVG from Home)
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Share clicked'),
                backgroundColor: Color(0xFFD4FC79),
              ));
            },
            child: SvgPicture.asset(
              'assets/icons/share.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(AppColors.pureWhite, BlendMode.srcIn),
            ),
          ),
        ],
      ),
    );
  }

}
