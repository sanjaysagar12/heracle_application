import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/stories_repository.dart';
import '../../../home/data/mutual_feed_repository.dart'; // For Comment model
import '../../../home/widgets/comments_bottom_sheet.dart';

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
  final StoriesRepository _storiesRepository = StoriesRepository();
  late List<StoryContent> _stories;

  @override
  void initState() {
    super.initState();
    _stories = List.from(widget.myStory.stories);
    _progressController = AnimationController(vsync: this);
    _loadCurrentStory();
  }

  void _loadCurrentStory() {
    if (_stories.isEmpty) return;

    setState(() {
      _isContentLoaded = false;
    });

    final currentStory = _stories[_currentStoryIndex];
    
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
    if (_stories.isEmpty || !_isContentLoaded) return;

    final currentStory = _stories[_currentStoryIndex];
    _progressController.duration = currentStory.duration;
    _progressController.reset();
    _progressController.forward().then((_) {
      if (_currentStoryIndex < _stories.length - 1) {
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

  void _showDetailsBottomSheet() {
    _pauseProgress();
    
    final currentStory = _stories[_currentStoryIndex];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MyStoryDetailsSheet(
        storyId: currentStory.id,
        repository: _storiesRepository,
      ),
    ).then((_) {
      _resumeProgress();
    });
  }

  Future<void> _handlePublic(StoryContent story) async {
    try {
      await _storiesRepository.highlightStory(story.id, true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Story highlighted successfully'),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to highlight story: $e')),
        );
      }
    }
  }

  Future<void> _handleDelete(StoryContent story) async {
    _pauseProgress();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.greyDark,
        title: const Text('Delete Story?', style: TextStyle(color: AppColors.pureWhite)),
        content: const Text('Are you sure you want to delete this story?', style: TextStyle(color: AppColors.white60)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.white60)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _storiesRepository.deleteStory(story.id);
        if (mounted) {
          setState(() {
             _stories.removeAt(_currentStoryIndex);
          });
          
          if (_stories.isEmpty) {
             Navigator.pop(context);
          } else {
             if (_currentStoryIndex >= _stories.length) {
               _currentStoryIndex = _stories.length - 1;
             }
             _loadCurrentStory();
          }
        }
      } catch (e) {
        _resumeProgress();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete story: $e')),
          );
        }
      }
    } else {
      _resumeProgress();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_stories.isEmpty) {
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

    final currentStory = _stories[_currentStoryIndex];

    return Scaffold(
      backgroundColor: AppColors.black,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! < -500) { // Swipe Up
            _showDetailsBottomSheet();
          }
        },
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
            if (_currentStoryIndex < _stories.length - 1) {
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
                  _stories.length,
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
              child: Column(
                children: [
                  const Icon(Icons.keyboard_arrow_up, color: AppColors.pureWhite),
                  const Text('Swipe up for details', style: TextStyle(color: AppColors.pureWhite, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                       GestureDetector(
                        onTap: () => _handlePublic(currentStory),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(8), // Add padding for SVG
                          child: SvgPicture.asset(
                            'assets/icons/feed.svg',
                            colorFilter: const ColorFilter.mode(AppColors.pureWhite, BlendMode.srcIn),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => _handleDelete(currentStory),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.delete, color: Colors.red, size: 24),
                        ),
                      ),
                    ],
                  ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.pureWhite, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: AppColors.pureWhite, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.pureWhite, size: 16),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: AppColors.pureWhite, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _MyStoryDetailsSheet extends StatefulWidget {
  final String storyId;
  final StoriesRepository repository;

  const _MyStoryDetailsSheet({required this.storyId, required this.repository});

  @override
  State<_MyStoryDetailsSheet> createState() => _MyStoryDetailsSheetState();
}

class _MyStoryDetailsSheetState extends State<_MyStoryDetailsSheet> with SingleTickerProviderStateMixin {
  StoryDetails? _details;
  List<Comment> _comments = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        widget.repository.getStoryDetails(widget.storyId),
        widget.repository.getStoryComments(widget.storyId),
      ]);
      
      if (mounted) {
        setState(() {
          _details = results[0] as StoryDetails;
          _comments = results[1] as List<Comment>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppColors.black100,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.pureWhite,
            unselectedLabelColor: AppColors.white60,
            tabs: [
              Tab(text: 'Views ${_details?.viewsCount ?? ''}'),
              Tab(text: 'Likes ${_details?.likesCount ?? ''}'),
              const Tab(text: 'Comments'),
            ],
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildViewersList(),
                    _buildLikesList(),
                    CommentsBottomSheet(
                      comments: _comments,
                      isLoading: _isLoading,
                      onAddComment: (text) async {
                         await widget.repository.commentOnStory(widget.storyId, text);
                      },
                      onAddReply: (commentId, text) async {
                        await widget.repository.replyToComment(commentId, text);
                      },
                      onOptimisticCommentAdd: (comment) {
                        setState(() {
                          _comments.add(comment);
                        });
                      },
                      onOptimisticReplyAdd: (commentId, reply) {
                        setState(() {
                          _comments = _addReplyToCommentLocal(_comments, commentId, reply);
                        });
                      },
                    ),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  List<Comment> _addReplyToCommentLocal(List<Comment> comments, String commentId, Comment newReply) {
    return comments.map((comment) {
      if (comment.id == commentId) {
        return comment.copyWithReply(newReply);
      }
      if (comment.replies.isNotEmpty) {
        return Comment(
          id: comment.id,
          username: comment.username,
          handle: comment.handle,
          profileImage: comment.profileImage,
          timeAgo: comment.timeAgo,
          content: comment.content,
          replies: _addReplyToCommentLocal(comment.replies, commentId, newReply),
        );
      }
      return comment;
    }).toList();
  }

  Widget _buildViewersList() {
    if (_details?.viewers.isEmpty ?? true) {
      return const Center(child: Text('No views yet', style: TextStyle(color: AppColors.white60)));
    }
    return ListView.builder(
      itemCount: _details!.viewers.length,
      itemBuilder: (context, index) {
        final viewer = _details!.viewers[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: viewer.avatarUrl != null ? NetworkImage(viewer.avatarUrl!) : null,
            child: viewer.avatarUrl == null ? const Icon(Icons.person) : null,
          ),
          title: Text(viewer.username, style: const TextStyle(color: AppColors.pureWhite)),
          subtitle: Text(_formatDate(viewer.viewedAt), style: const TextStyle(color: AppColors.white60, fontSize: 12)),
        );
      },
    );
  }

  Widget _buildLikesList() {
    if (_details?.likes.isEmpty ?? true) {
      return const Center(child: Text('No likes yet', style: TextStyle(color: AppColors.white60)));
    }
    return ListView.builder(
      itemCount: _details!.likes.length,
      itemBuilder: (context, index) {
        final liker = _details!.likes[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: liker.avatarUrl != null ? NetworkImage(liker.avatarUrl!) : null,
            child: liker.avatarUrl == null ? const Icon(Icons.person) : null,
          ),
          title: Text(liker.username, style: const TextStyle(color: AppColors.pureWhite)),
          trailing: const Icon(Icons.favorite, color: Colors.red, size: 20),
        );
      },
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
