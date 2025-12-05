import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_colors.dart';
import '../data/stories_repository.dart';

class StoryViewer extends StatefulWidget {
  final List<StoryUser> stories;
  final int initialIndex;
  final Function(String) onStoryViewed;
  final Function(String)? onStoryLiked;
  final Function(String, String)? onStoryComment;

  const StoryViewer({
    super.key,
    required this.stories,
    required this.initialIndex,
    required this.onStoryViewed,
    this.onStoryLiked,
    this.onStoryComment,
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
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  List<StoryUser> _localStories = [];

  @override
  void initState() {
    super.initState();
    _localStories = List.from(widget.stories);
    _currentUserIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    
    // Add listener to pause story when typing
    _commentFocus.addListener(_onFocusChange);
    
    _setupProgressController();
    _startCurrentStory();
  }

  void _onFocusChange() {
    if (_commentFocus.hasFocus) {
      // Pause playback when typing
      if (_isVideoProgressTracking) {
        _videoController?.pause();
      } else {
        _progressController?.stop();
      }
    } else {
      // Resume playback when focus lost (keyboard dismissed or sent)
      if (_isContentLoaded) {
        if (_isVideoProgressTracking) {
          _videoController?.play();
        } else {
          _progressController?.forward();
        }
      }
    }
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
    final currentUser = _localStories[_currentUserIndex];
    if (currentUser.stories.isNotEmpty) {
      _loadContent(currentUser.stories[_currentStoryIndex]);
    }
  }

  void _loadContent(StoryContent story) {
    // Dispose previous video controller to prevent leaks/audio playing
    _videoController?.pause();
    _videoController?.removeListener(_videoProgressListener);
    _videoController?.dispose();
    _videoController = null;

    if (story.type == 'video' && story.imageUrl != null) {
      _initializeVideoPlayer(story.imageUrl!);
    } else if (story.type == 'image' && story.imageUrl != null) {
      _preloadImage(story.imageUrl!);
    } else {
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
      final currentUser = _localStories[_currentUserIndex];
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
          final currentUser = _localStories[_currentUserIndex];
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
          final currentUser = _localStories[_currentUserIndex];
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
      final currentUser = _localStories[_currentUserIndex];
      if (currentUser.stories.isNotEmpty) {
        _startTimer(currentUser.stories[_currentStoryIndex]);
      }
      return;
    }

    // Use networkUrl instead of network
    final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    _videoController = controller;
    
    try {
      await controller.initialize();
      // Check if mounted and if the controller is still the current one (avoid race conditions)
      if (mounted && _videoController == controller) {
        setState(() {
          _isContentLoaded = true;
        });
        
        controller.addListener(_videoProgressListener);
        await controller.play();
        
        final currentUser = _localStories[_currentUserIndex];
        if (currentUser.stories.isNotEmpty) {
          _startTimer(currentUser.stories[_currentStoryIndex]);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isContentLoaded = true;
        });
        final currentUser = _localStories[_currentUserIndex];
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
        
        if (progress >= 1.0) {
          _nextStory();
        }
      }
      
      if (_videoController!.value.hasError) {
        _nextStory();
      }
    }
  }

  void _startTimer(StoryContent story) {
    if (!_isContentLoaded) return;
    
    if (story.type == 'video' && _videoController != null) {
      _storyDuration = _videoController!.value.duration;
      _isVideoProgressTracking = true;
      _progressController?.duration = _storyDuration;
    } else {
      _storyDuration = const Duration(seconds: 5);
      _isVideoProgressTracking = false;
      _progressController?.duration = _storyDuration;
      _progressController?.forward(from: 0.0);
    }
  }

  void _nextStory() {
    _progressController?.reset();
    _videoController?.pause();
    _isVideoProgressTracking = false;
    
    final currentUser = _localStories[_currentUserIndex];
    
    if (_currentStoryIndex < currentUser.stories.length - 1) {
      setState(() {
        _currentStoryIndex++;
        _isContentLoaded = false;
      });
      _loadContent(currentUser.stories[_currentStoryIndex]);
    } else {
      _nextUser();
    }
  }

  void _previousStory() {
    _progressController?.reset();
    _videoController?.pause();
    _isVideoProgressTracking = false;
    
    if (_currentStoryIndex > 0) {
      setState(() {
        _currentStoryIndex--;
        _isContentLoaded = false;
      });
      final currentUser = _localStories[_currentUserIndex];
      _loadContent(currentUser.stories[_currentStoryIndex]);
    } else {
      _previousUser();
    }
  }

  void _nextUser() {
    _markCurrentUserAsViewed();
    
    if (_currentUserIndex < widget.stories.length - 1) {
      setState(() {
        _currentUserIndex++;
      });
      _pageController?.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startCurrentStory();
    } else {
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
    final currentUser = _localStories[_currentUserIndex];
    widget.onStoryViewed(currentUser.id);
  }

  void _toggleLike() {
    final currentUser = _localStories[_currentUserIndex];
    if (currentUser.stories.isNotEmpty) {
      final currentStory = currentUser.stories[_currentStoryIndex];
      
      setState(() {
        final updatedStories = currentUser.stories.map((story) {
          if (story.id == currentStory.id) {
            final newIsLiked = !story.isLiked;
            final newLikes = newIsLiked ? story.likes + 1 : story.likes - 1;
            return story.copyWith(
              isLiked: newIsLiked,
              likes: newLikes,
            );
          }
          return story;
        }).toList();
        
        final updatedUser = currentUser.copyWith(stories: updatedStories);
        _localStories[_currentUserIndex] = updatedUser;
      });
      
      widget.onStoryLiked?.call(currentStory.id);
    }
  }

  void _submitComment() {
    final comment = _commentController.text.trim();
    if (comment.isNotEmpty) {
      final currentUser = _localStories[_currentUserIndex];
      if (currentUser.stories.isNotEmpty) {
        final currentStory = currentUser.stories[_currentStoryIndex];
        
        widget.onStoryComment?.call(currentStory.id, comment);
        
        _commentController.clear();
        _commentFocus.unfocus();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment sent!'),
            duration: Duration(seconds: 1),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _commentFocus.removeListener(_onFocusChange);
    _commentController.dispose();
    _commentFocus.dispose();
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
        itemCount: _localStories.length,
        onPageChanged: (index) {
          _progressController?.reset();
          _isVideoProgressTracking = false;
          _commentFocus.unfocus();
          setState(() {
            _currentUserIndex = index;
          });
          _startCurrentStory();
        },
        itemBuilder: (context, index) {
          final user = _localStories[index];
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
              final screenHeight = MediaQuery.of(context).size.height;
              if (details.globalPosition.dy > screenHeight - 120) return;
              
              final screenWidth = MediaQuery.of(context).size.width;
              if (details.globalPosition.dx < screenWidth * 0.3) {
                _previousStory();
              } else if (details.globalPosition.dx > screenWidth * 0.7) {
                _nextStory();
              }
            },
            onLongPressStart: (_) {
              if (_isVideoProgressTracking) {
                _videoController?.pause();
              } else {
                _progressController?.stop();
              }
            },
            onLongPressEnd: (_) {
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
                _buildStoryContent(currentStory),
                
                if (!_isContentLoaded)
                  const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                
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
                            ? const Icon(Icons.person, color: Colors.white, size: 20)
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
                
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: MediaQuery.of(context).padding.bottom + 16,
                      top: 20,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 14, right: 14),
                            child: TextField(
                              controller: _commentController,
                              focusNode: _commentFocus,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Send message',
                                hintStyle: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 0,
                                ),
                              ),
                              maxLines: 1,
                              onSubmitted: (_) => _submitComment(),
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        GestureDetector(
                          onTap: _toggleLike,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: currentStory.isLiked
                                  ? Colors.red.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  currentStory.isLiked ? Icons.favorite : Icons.favorite_border,
                                  key: ValueKey(currentStory.isLiked),
                                  color: currentStory.isLiked ? Colors.red : Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        GestureDetector(
                          onTap: _submitComment,
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ],
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
            ? Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black,
                child: Center(
                  child: Image.network(
                    story.imageUrl!,
                    fit: BoxFit.contain,
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
                  ),
                ),
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
            ? Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      ),
                      if (_videoController!.value.isBuffering)
                        const CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                ),
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