import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/stories_repository.dart';

class MyStoryViewer extends StatefulWidget {
  final StoryUser myStory;

  const MyStoryViewer({
    super.key,
    required this.myStory,
  });

  @override
  State<MyStoryViewer> createState() => _MyStoryViewerState();
}

class _MyStoryViewerState extends State<MyStoryViewer> with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  int _currentStoryIndex = 0;
  bool _isContentLoaded = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(vsync: this);
    _loadCurrentStory();
  }

  void _loadCurrentStory() {
    if (widget.myStory.stories.isEmpty) return;

    setState(() {
      _isContentLoaded = false;
    });

    final currentStory = widget.myStory.stories[_currentStoryIndex];
    
    if (currentStory.type == 'image' && currentStory.imageUrl != null) {
      _preloadImage(currentStory.imageUrl!);
    } else {
      // Text story - no loading needed
      setState(() {
        _isContentLoaded = true;
      });
      _startProgress();
    }
  }

  void _preloadImage(String imageUrl) {
    final ImageProvider imageProvider = NetworkImage(imageUrl);
    final ImageStream stream = imageProvider.resolve(const ImageConfiguration());
    
    stream.addListener(ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        if (mounted) {
          setState(() {
            _isContentLoaded = true;
          });
          _startProgress();
        }
      },
      onError: (exception, stackTrace) {
        if (mounted) {
          setState(() {
            _isContentLoaded = true;
          });
          _startProgress();
        }
      },
    ));
  }

  void _startProgress() {
    if (widget.myStory.stories.isEmpty || !_isContentLoaded) return;

    final currentStory = widget.myStory.stories[_currentStoryIndex];
    _progressController.duration = currentStory.duration;
    _progressController.reset();
    _progressController.forward().then((_) {
      if (_currentStoryIndex < widget.myStory.stories.length - 1) {
        setState(() => _currentStoryIndex++);
        _loadCurrentStory();
      } else {
        Navigator.pop(context);
      }
    });
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
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.myStory.stories.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppColors.pureWhite),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text(
            'No stories yet',
            style: TextStyle(color: AppColors.pureWhite, fontSize: 18),
          ),
        ),
      );
    }

    final currentStory = widget.myStory.stories[_currentStoryIndex];

    return Scaffold(
      backgroundColor: AppColors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 2) {
            if (_currentStoryIndex > 0) {
              setState(() => _currentStoryIndex--);
              _loadCurrentStory();
            } else {
              Navigator.pop(context);
            }
          } else {
            if (_currentStoryIndex < widget.myStory.stories.length - 1) {
              setState(() => _currentStoryIndex++);
              _loadCurrentStory();
            } else {
              Navigator.pop(context);
            }
          }
        },
        onLongPressStart: (_) => _pauseProgress(),
        onLongPressEnd: (_) => _resumeProgress(),
        child: Stack(
          children: [
            // Story Content
            Center(
              child: currentStory.type == 'image' && currentStory.imageUrl != null
                  ? Image.network(
                      currentStory.imageUrl!,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.greyDark,
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error, color: AppColors.pureWhite, size: 50),
                                SizedBox(height: 16),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(color: AppColors.pureWhite),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: AppColors.primary,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            currentStory.text ?? '',
                            style: const TextStyle(fontSize: 24, color: AppColors.black),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
            ),

            // Loading Indicator
            if (!_isContentLoaded)
              const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),

            // Progress bars
            Positioned(
              top: 50,
              left: 8,
              right: 8,
              child: Row(
                children: List.generate(
                  widget.myStory.stories.length,
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
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.pureWhite),
                              minHeight: 2,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Header
            Positioned(
              top: 65,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: widget.myStory.profileImage.isNotEmpty
                        ? NetworkImage(widget.myStory.profileImage)
                        : null,
                    backgroundColor: AppColors.primary,
                    child: widget.myStory.profileImage.isEmpty
                        ? const Icon(Icons.person, color: AppColors.black)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.myStory.username,
                      style: const TextStyle(
                        color: AppColors.pureWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.pureWhite),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Story stats
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(Icons.visibility, '${currentStory.views} views'),
                  _buildStatItem(Icons.favorite, '${currentStory.likes} likes'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.pureWhite, size: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: AppColors.pureWhite)),
        ],
      ),
    );
  }
}
