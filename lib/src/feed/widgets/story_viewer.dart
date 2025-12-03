import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_colors.dart';
import '../data/stories_repository.dart';

class StoryViewer extends StatefulWidget {
  final List<StoryUser> stories;
  final int initialIndex;
  final Function(String) onStoryViewed;

  const StoryViewer({
    super.key,
    required this.stories,
    required this.initialIndex,
    required this.onStoryViewed,
  });

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> with TickerProviderStateMixin {
  PageController? _pageController;
  int _currentUserIndex = 0;
  int _currentStoryIndex = 0;
  bool _isContentLoaded = false;
  VideoPlayerController? _videoController;
  AnimationController? _progressController;
  Animation<double>? _progressAnimation;
  Duration _storyDuration = const Duration(seconds: 5);
  bool _isVideoProgressTracking = false;

  @override
  void initState() {
    super.initState();
    _currentUserIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _setupProgressController();
    _startCurrentStory();
  }

  void _setupProgressController() {
    _progressController = AnimationController(
      duration: _storyDuration,
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController!, curve: Curves.linear),
    );
    
    _progressController!.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _nextStory();
      }
    });
  }

  void _startCurrentStory() {
    setState(() {
      _isContentLoaded = false;
      _currentStoryIndex = 0;
    });
    
    _progressController?.reset();
    final currentUser = widget.stories[_currentUserIndex];
    if (currentUser.stories.isNotEmpty) {
      _loadContent(currentUser.stories[_currentStoryIndex]);
    }
  }

  void _loadContent(StoryContent story) {
    if (story.type == 'video' && story.imageUrl != null) {
      _initializeVideoPlayer(story.imageUrl!);
    } else if (story.type == 'image' && story.imageUrl != null) {
      _preloadImage(story.imageUrl!);
    } else {
      // Text story - no loading needed
      setState(() {
        _isContentLoaded = true;
      });
      _startTimer(story);
    }
  }

  bool _isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  void _preloadImage(String imageUrl) {
    if (!_isValidUrl(imageUrl)) {
      setState(() {
        _isContentLoaded = true;
      });
      final currentUser = widget.stories[_currentUserIndex];
      if (currentUser.stories.isNotEmpty) {
        _startTimer(currentUser.stories[_currentStoryIndex]);
      }
      return;
    }

    final ImageProvider imageProvider = NetworkImage(imageUrl);
    final ImageStream stream = imageProvider.resolve(const ImageConfiguration());
    
    stream.addListener(ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        if (mounted) {
          setState(() {
            _isContentLoaded = true;
          });
          final currentUser = widget.stories[_currentUserIndex];
          if (currentUser.stories.isNotEmpty) {
            _startTimer(currentUser.stories[_currentStoryIndex]);
          }
        }
      },
      onError: (exception, stackTrace) {
        if (mounted) {
          setState(() {
            _isContentLoaded = true;
          });
          final currentUser = widget.stories[_currentUserIndex];
          if (currentUser.stories.isNotEmpty) {
            _startTimer(currentUser.stories[_currentStoryIndex]);
          }
        }
      },
    ));
  }

  void _initializeVideoPlayer(String videoUrl) async {
    if (!_isValidUrl(videoUrl)) {
      setState(() {
        _isContentLoaded = true;
      });
      final currentUser = widget.stories[_currentUserIndex];
      if (currentUser.stories.isNotEmpty) {
        _startTimer(currentUser.stories[_currentStoryIndex]);
      }
      return;
    }

    _videoController?.dispose();
    _videoController = VideoPlayerController.network(videoUrl);
    
    try {
      await _videoController!.initialize();
      if (mounted) {
        setState(() {
          _isContentLoaded = true;
        });
        
        // Set up video progress listener
        _videoController!.addListener(_videoProgressListener);
        
        await _videoController!.play();
        final currentUser = widget.stories[_currentUserIndex];
        if (currentUser.stories.isNotEmpty) {
          _startTimer(currentUser.stories[_currentStoryIndex]);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isContentLoaded = true;
        });
        final currentUser = widget.stories[_currentUserIndex];
        if (currentUser.stories.isNotEmpty) {
          _startTimer(currentUser.stories[_currentStoryIndex]);
        }
      }
    }
  }

  void _videoProgressListener() {
    if (_videoController != null && 
        _videoController!.value.isInitialized && 
        _isVideoProgressTracking &&
        mounted) {
      
      final position = _videoController!.value.position;
      final duration = _videoController!.value.duration;
      
      if (duration.inMilliseconds > 0) {
        final progress = position.inMilliseconds / duration.inMilliseconds;
        _progressController?.value = progress.clamp(0.0, 1.0);
        
        // Check if video completed
        if (progress >= 1.0) {
          _nextStory();
        }
      }
      
      // Handle video buffering or errors
      if (_videoController!.value.hasError) {
        _nextStory();
      }
    }
  }

  void _startTimer(StoryContent story) {
    if (!_isContentLoaded) return;
    
    // Set duration based on story type
    if (story.type == 'video' && _videoController != null) {
      _storyDuration = _videoController!.value.duration;
      _isVideoProgressTracking = true;
      // For videos, don't start the animation controller, use video position instead
      _progressController?.duration = _storyDuration;
    } else {
      _storyDuration = const Duration(seconds: 5); // Default for images and text
      _isVideoProgressTracking = false;
      // Update progress controller duration
      _progressController?.duration = _storyDuration;
      // Start progress animation for images and text
      _progressController?.forward(from: 0.0);
    }
  }

  void _nextStory() {
    _progressController?.reset();
    _videoController?.pause();
    _isVideoProgressTracking = false;
    
    final currentUser = widget.stories[_currentUserIndex];
    
    if (_currentStoryIndex < currentUser.stories.length - 1) {
      // Next story in current user
      setState(() {
        _currentStoryIndex++;
        _isContentLoaded = false;
      });
      _loadContent(currentUser.stories[_currentStoryIndex]);
    } else {
      // Next user
      _nextUser();
    }
  }

  void _previousStory() {
    _progressController?.reset();
    _videoController?.pause();
    _isVideoProgressTracking = false;
    
    if (_currentStoryIndex > 0) {
      // Previous story in current user
      setState(() {
        _currentStoryIndex--;
        _isContentLoaded = false;
      });
      final currentUser = widget.stories[_currentUserIndex];
      _loadContent(currentUser.stories[_currentStoryIndex]);
    } else {
      // Previous user
      _previousUser();
    }
  }

  void _nextUser() {
    if (_currentUserIndex < widget.stories.length - 1) {
      setState(() {
        _currentUserIndex++;
      });
      _pageController?.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _markCurrentUserAsViewed();
      _startCurrentStory();
    } else {
      // End of stories
      _markCurrentUserAsViewed();
      Navigator.of(context).pop();
    }
  }

  void _previousUser() {
    if (_currentUserIndex > 0) {
      setState(() {
        _currentUserIndex--;
      });
      _pageController?.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startCurrentStory();
    }
  }

  void _markCurrentUserAsViewed() {
    final currentUser = widget.stories[_currentUserIndex];
    widget.onStoryViewed(currentUser.id);
  }

  @override
  void dispose() {
    _videoController?.removeListener(_videoProgressListener);
    _progressController?.dispose();
    _videoController?.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.stories.length,
        onPageChanged: (index) {
          _progressController?.reset();
          _isVideoProgressTracking = false;
          setState(() {
            _currentUserIndex = index;
          });
          _startCurrentStory();
        },
        itemBuilder: (context, index) {
          final user = widget.stories[index];
          if (user.stories.isEmpty) {
            return const Center(
              child: Text(
                'No stories available',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final currentStory = user.stories[_currentStoryIndex];
          
          return GestureDetector(
            onTapUp: (details) {
              final screenWidth = MediaQuery.of(context).size.width;
              if (details.globalPosition.dx < screenWidth * 0.3) {
                _previousStory();
              } else if (details.globalPosition.dx > screenWidth * 0.7) {
                _nextStory();
              }
            },
            onLongPressStart: (_) {
              // Pause progress when holding
              if (_isVideoProgressTracking) {
                _videoController?.pause();
              } else {
                _progressController?.stop();
              }
            },
            onLongPressEnd: (_) {
              // Resume progress when releasing
              if (_isContentLoaded) {
                if (_isVideoProgressTracking) {
                  _videoController?.play();
                } else {
                  _progressController?.forward();
                }
              }
            },
            child: Stack(
              children: [
                // Story Content
                _buildStoryContent(currentStory),
                
                // Loading Indicator
                if (!_isContentLoaded)
                  const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                
                // Story Progress Indicators
                Positioned(
                  top: 60,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: List.generate(
                      user.stories.length,
                      (storyIndex) => Expanded(
                        child: Container(
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: storyIndex == _currentStoryIndex
                              ? _isVideoProgressTracking
                                  ? ValueListenableBuilder<VideoPlayerValue>(
                                      valueListenable: _videoController!,
                                      builder: (context, value, child) {
                                        double progress = 0.0;
                                        if (value.isInitialized && value.duration.inMilliseconds > 0) {
                                          progress = value.position.inMilliseconds / value.duration.inMilliseconds;
                                        }
                                        return LinearProgressIndicator(
                                          value: progress.clamp(0.0, 1.0),
                                          backgroundColor: Colors.transparent,
                                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                          minHeight: 3,
                                        );
                                      },
                                    )
                                  : AnimatedBuilder(
                                      animation: _progressAnimation!,
                                      builder: (context, child) {
                                        return LinearProgressIndicator(
                                          value: _progressAnimation!.value,
                                          backgroundColor: Colors.transparent,
                                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                          minHeight: 3,
                                        );
                                      },
                                    )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: storyIndex < _currentStoryIndex
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // User Info
                Positioned(
                  top: 80,
                  left: 16,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: _isValidUrl(user.profileImage) 
                            ? NetworkImage(user.profileImage)
                            : null,
                        backgroundColor: Colors.grey[600],
                        child: !_isValidUrl(user.profileImage) 
                            ? Icon(Icons.person, color: Colors.white, size: 20)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        user.username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Close Button
                Positioned(
                  top: 60,
                  right: 16,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStoryContent(StoryContent story) {
    switch (story.type) {
      case 'image':
        return _isValidUrl(story.imageUrl)
            ? Image.network(
                story.imageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[800],
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: Colors.white, size: 50),
                          SizedBox(height: 16),
                          Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
            : Container(
                color: Colors.grey[800],
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported, color: Colors.white, size: 50),
                      SizedBox(height: 16),
                      Text(
                        'Invalid image URL',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              );
              
      case 'video':
        if (!_isValidUrl(story.imageUrl)) {
          return Container(
            color: Colors.grey[800],
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam_off, color: Colors.white, size: 50),
                  SizedBox(height: 16),
                  Text(
                    'Invalid video URL',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          );
        }
        
        return _videoController != null && _videoController!.value.isInitialized
            ? Stack(
                children: [
                  AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  ),
                  // Show buffering indicator when video is buffering
                  if (_videoController!.value.isBuffering)
                    const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                ],
              )
            : Container(
                color: Colors.grey[800],
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
              
      case 'text':
      default:
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: story.backgroundColor != null
              ? Color(int.parse(story.backgroundColor!.replaceFirst('#', '0xFF')))
              : AppColors.primary,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                story.text ?? 'No content available',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
    }
  }
}
