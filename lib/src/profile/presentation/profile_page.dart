import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../data/profile_repository.dart';
import '../../home/data/profile_repository.dart' as home_repo;
import '../widgets/profile_header.dart';
import '../widgets/profile_tab_bar.dart';
import '../widgets/highlight_grid.dart';
import '../widgets/profile_skeleton.dart';
import '../../feed/data/stories_repository.dart';
import '../../feed/presentation/tab/reels_tab.dart';
import 'connections_page.dart';
import '../../workout/widgets/sessions_section.dart';
import '../../workout/data/session_repository.dart';
import '../../home/data/mutual_feed_repository.dart';
import '../../home/widgets/comments_bottom_sheet.dart';
import '../../home/widgets/likes_bottom_sheet.dart';
import '../../home/widgets/workout_post_card.dart';
import '../../home/widgets/nutrition_post_card.dart';
import '../../workout/data/post_workout_repository.dart'; // Added
import '../../workout/presentation/tab/post_workout_screen.dart'; // Added
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  final String? username;
  const ProfilePage({super.key, this.username});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileRepository _repository = ProfileRepository();
  
  UserProfile? _profile;
  // List<HighlightVideo> _highlights = []; // Removed
  List<Session> _sessions = [];
  List<DiscoverStory> _discoverStories = []; // For ReelsTab navigation
  
  bool _isLoading = true;
  int _selectedTabIndex = 0;

  // State variables for Feed interactions
  final MutualFeedRepository _mutualFeedRepository = MutualFeedRepository();
  List<FeedPost> _posts = [];
  Map<String, List<Comment>> _commentsCache = {};
  final Set<String> _likeInProgress = {};
  final PostWorkoutRepository _postWorkoutRepository = PostWorkoutRepository(); // Added

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final targetUsername = widget.username ?? '@sanjaysagar';
      
      // 1. Get profile first to get ID
      final profile = await _repository.getUserProfile(targetUsername);
      
      if (mounted) {
        setState(() {
          _profile = profile;
        });
      }
      
      // 2. Fetch independent data in parallel with error handling
      final results = await Future.wait([
        _repository.getUserFeed(profile.id).catchError((_) => <DiscoverStory>[]),
        _repository.getSessions(username: targetUsername).catchError((_) => <Session>[]),
        _repository.getPosts(targetUsername).catchError((_) => <FeedPost>[]),
      ]);

      if (mounted) {
        setState(() {
          _discoverStories = results[0] as List<DiscoverStory>;
          _sessions = results[1] as List<Session>;
          _posts = results[2] as List<FeedPost>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Only show error if profile itself failed to load
        if (_profile == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load profile used: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  void _onFollowTap() {
    if (_profile != null) {
      final oldProfile = _profile;
      setState(() {
        _profile = _repository.toggleFollow(_profile!);
      });
      
      _repository.followUser(_profile!.username).catchError((e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update follow status: $e')),
          );
          // Revert optimistic update
          setState(() {
            _profile = oldProfile;
          });
        }
      });
    }
  }

  void _onEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProfilePage()),
    );
    if (result == true) {
      _loadData();
    }
  }

  // _convertToDiscoverStories removed as we now fetch DiscoverStory directly

  /// Handle like action for reels
  List<DiscoverStory> _handleReelLike(String storyId) {
    setState(() {
      _discoverStories = _discoverStories.map((story) {
        if (story.id == storyId) {
          final newIsLiked = !story.isLiked;
          final newLikesCount = newIsLiked ? story.likesCount + 1 : story.likesCount - 1;
          return story.copyWith(isLiked: newIsLiked, likesCount: newLikesCount);
        }
        return story;
      }).toList();
    });
    return _discoverStories;
  }

  // --- Feed Interaction Methods (Copied/Adapted from HomePage) ---

  Future<void> _handleLike(String postId) async {
    if (_likeInProgress.contains(postId)) return; 
    _likeInProgress.add(postId);

    final previousPosts = List<FeedPost>.from(_posts);

    setState(() {
      _posts = _posts.map((post) {
        if (post.id == postId) {
          final newIsLiked = !post.isLiked;
          final newLikes = newIsLiked ? post.likes + 1 : post.likes - 1;
          return post.copyWith(isLiked: newIsLiked, likes: newLikes);
        }
        return post;
      }).toList();
    });

    try {
      await _mutualFeedRepository.likePost(postId);
    } catch (e) {
      if (mounted) {
        setState(() {
          _posts = previousPosts;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update like: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      _likeInProgress.remove(postId);
    }
  }

  Future<void> _handleAddComment(String postId, String content) async {
    try {
      final newComment = await _mutualFeedRepository.addComment(postId, content);
      setState(() {
        _commentsCache[postId] = _replaceTemporaryComment(_commentsCache[postId] ?? [], newComment);
      });
    } catch (e) {
      setState(() {
        _commentsCache[postId] = _removeTemporaryComments(_commentsCache[postId] ?? []);
      });
      rethrow;
    }
  }

  Future<void> _handleAddReply(String postId, String commentId, String content) async {
    try {
      final newReply = await _mutualFeedRepository.addReply(postId, commentId, content);
      setState(() {
        _commentsCache[postId] = _replaceTemporaryReply(_commentsCache[postId] ?? [], newReply);
      });
    } catch (e) {
      setState(() {
        _commentsCache[postId] = _removeTemporaryReplies(_commentsCache[postId] ?? []);
      });
      rethrow;
    }
  }

  List<Comment> _replaceTemporaryComment(List<Comment> comments, Comment newComment) {
    for (int i = comments.length - 1; i >= 0; i--) {
      if (comments[i].id.startsWith('temp_')) {
        comments[i] = newComment;
        break;
      }
    }
    return comments;
  }

  List<Comment> _replaceTemporaryReply(List<Comment> comments, Comment newReply) {
    return comments.map((comment) {
      if (comment.replies.any((reply) => reply.id.startsWith('temp_'))) {
        final updatedReplies = [...comment.replies];
        for (int i = updatedReplies.length - 1; i >= 0; i--) {
          if (updatedReplies[i].id.startsWith('temp_')) {
            updatedReplies[i] = newReply;
            break;
          }
        }
        return comment.copyWith(replies: updatedReplies);
      }
      if (comment.replies.isNotEmpty) {
        return comment.copyWith(replies: _replaceTemporaryReply(comment.replies, newReply));
      }
      return comment;
    }).toList();
  }

  List<Comment> _removeTemporaryComments(List<Comment> comments) {
    return comments.where((comment) => !comment.id.startsWith('temp_')).toList();
  }

  List<Comment> _removeTemporaryReplies(List<Comment> comments) {
    return comments.map((comment) => comment.copyWith(
      replies: comment.replies.where((reply) => !reply.id.startsWith('temp_')).toList(),
    )).toList();
  }

  Future<void> _handleDeletePost(String postId) async {
    try {
      await _postWorkoutRepository.deletePost(postId);
      setState(() {
        _posts.removeWhere((p) => p.id == postId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete post: $e')),
        );
      }
    }
  }

  void _handleEditPost(FeedPost post) async {
    if (post is! WorkoutPost) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostWorkoutScreen(
          duration: 0, // Placeholder
          volume: 0, // Placeholder
          exercises: post.exercises.map((e) => {
            'name': e.name,
            'image': e.imageUrl,
            'sets': [],
          }).toList(),
          postId: post.id,
          initialCaption: post.content,
          initialTags: post.tags,
        ),
      ),
    );

    if (result != null && result is Map) {
      final updatedCaption = result['caption'] as String;
      final updatedTags = result['tags'] as List<String>;

      setState(() {
        _posts = _posts.map((p) {
          if (p.id == post.id && p is WorkoutPost) {
             return WorkoutPost(
              id: p.id,
              username: p.username,
              handle: p.handle,
              profileImage: p.profileImage,
              timeAgo: p.timeAgo,
              content: updatedCaption,
              tags: updatedTags,
              images: p.images,
              duration: p.duration,
              volume: p.volume,
              records: p.records,
              exercises: p.exercises,
              likes: p.likes,
              likedBy: p.likedBy,
              isLiked: p.isLiked,
              isOwnPost: p.isOwnPost,
              commentCount: p.commentCount,
             );
          }
          return p;
        }).toList();
      });
      
      _loadData(); 
    }
  }

  void _handleOptimisticCommentAdd(String postId, Comment comment) {
    setState(() {
      _commentsCache[postId] = [...(_commentsCache[postId] ?? []), comment];
      _posts = _posts.map((post) {
        if (post.id == postId) {
          return post.copyWith(commentCount: post.commentCount + 1);
        }
        return post;
      }).toList();
    });
  }

  void _handleOptimisticReplyAdd(String postId, String commentId, Comment reply) {
    setState(() {
      _commentsCache[postId] = _addReplyToComment(_commentsCache[postId] ?? [], commentId, reply);
    });
  }

  List<Comment> _addReplyToComment(List<Comment> comments, String commentId, Comment newReply) {
    return comments.map((comment) {
      if (comment.id == commentId) {
        return comment.copyWithReply(newReply);
      }
      if (comment.replies.isNotEmpty) {
        return comment.copyWith(
          replies: _addReplyToComment(comment.replies, commentId, newReply),
        );
      }
      return comment;
    }).toList();
  }

  void _handleCommentClick(String postId) async {
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final bool isLoading = !_commentsCache.containsKey(postId);
          final List<Comment>? comments = _commentsCache[postId];
          
          if (isLoading) {
            _loadCommentsForModal(postId, setModalState);
          }
          
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              // Map UserProfile to home_repo.Profile
              home_repo.Profile? userProfile;
              if (mounted && _profile != null) {
                userProfile = home_repo.Profile(
                  name: _profile!.name,
                  username: _profile!.username,
                  age: 0, // ProfilePage doesn't have age, default to 0
                  profileImageUrl: _profile!.profileImageUrl,
                  hasStory: _profile!.hasStory,
                );
              }

              return CommentsBottomSheet(
                comments: comments,
                isLoading: isLoading,
                onAddComment: (content) async {
                  await _handleAddComment(postId, content);
                  setModalState(() {});
                },
                onAddReply: (commentId, content) async {
                  await _handleAddReply(postId, commentId, content);
                  setModalState(() {});
                },
                onOptimisticCommentAdd: (comment) {
                  _handleOptimisticCommentAdd(postId, comment);
                  setModalState(() {});
                },
                onOptimisticReplyAdd: (commentId, reply) {
                  _handleOptimisticReplyAdd(postId, commentId, reply);
                  setModalState(() {});
                },
                currentUserProfile: userProfile,
              );
            },
          );

        },
      ),
    );
  }

  Future<void> _loadCommentsForModal(String postId, StateSetter setModalState) async {
    try {
      final comments = await _mutualFeedRepository.getComments(postId);
      setState(() {
        _commentsCache[postId] = comments;
      });
      setModalState(() {});
    } catch (e) {
      setState(() {
        _commentsCache[postId] = [];
      });
      setModalState(() {});
    }
  }

  void _handleLikesClick(String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => LikesBottomSheet(
          postId: postId,
        ),
      ),
    );
  }

  void _onHighlightTap(DiscoverStory highlight) {
    final index = _discoverStories.indexWhere((h) => h.id == highlight.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReelsTab(
          stories: _discoverStories,
          initialIndex: index >= 0 ? index : 0,
          onLike: _handleReelLike,
          onStoryViewed: (storyId) {
            setState(() {
              _discoverStories = _discoverStories.map((story) {
                if (story.id == storyId) {
                  return story.copyWith(isViewed: true);
                }
                return story;
              }).toList();
            });
          },
        ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: _isLoading
          ? const ProfileSkeleton()
          : RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppColors.primary,
              backgroundColor: AppColors.greyDark,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    if (_profile != null)
                      Stack(
                        children: [
                          ProfileHeader(
                            profile: _profile!,
                            onFollowTap: _profile!.isViewer ? null : _onFollowTap,
                            onEditTap: _profile!.isViewer ? _onEditProfile : null, // Added edit handler
                            onFollowersTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ConnectionsPage(
                                    initialIndex: 0,
                                    username: _profile!.username,
                                  ),
                                ),
                              );
                            },
                            onFollowingTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ConnectionsPage(
                                    initialIndex: 1,
                                    username: _profile!.username,
                                  ),
                                ),
                              );
                            },
                          ),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Material(
                              color: Colors.black38,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => Navigator.of(context).pop(),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: SvgPicture.asset(
                                    'assets/icons/back.svg',
                                    width: 22,
                                    height: 22,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ProfileTabBar(
                      selectedIndex: _selectedTabIndex,
                      onTabSelected: _onTabSelected,
                    ),
                    _buildTabContent(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildHighlightsTab();
      case 1:
        return _buildSessionsTab();
      case 2:
        return _buildPostsTab();
      default:
        return _buildHighlightsTab();
    }
  }

  Widget _buildHighlightsTab() {
    return Column(
      children: [
        HighlightGrid(
          highlights: _discoverStories,
          onHighlightTap: _onHighlightTap,
        ),
      ],
    );
  }

  Widget _buildSessionsTab() {
    return SessionsSection(
      sessions: _sessions,
      isViewOnly: !_profile!.isViewer,
    );
  }

  Widget _buildPostsTab() {
    if (_posts.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(40),
        child: const Text(
          'No posts yet',
          style: TextStyle(
            color: AppColors.white60,
            fontSize: 16,
          ),
        ),
      );
    }
    
    return Column(
      children: _posts.map<Widget>((post) {
        if (post is WorkoutPost) {
          return WorkoutPostCard(
            username: post.username,
            handle: post.handle,
            profileImage: post.profileImage,
            timeAgo: post.timeAgo,
            content: post.content,
            tags: post.tags,
            images: post.images,
            duration: post.duration,
            volume: post.volume,
            records: post.records,
            exercises: post.exercises,
            likes: post.likes,
            likedBy: post.likedBy,
            isLiked: post.isLiked,
            commentCount: post.commentCount,
            onLike: () => _handleLike(post.id),
            onComment: () => _handleCommentClick(post.id),
            onLikesClick: () => _handleLikesClick(post.id),
            onDelete: () => _handleDeletePost(post.id),
            onEdit: () => _handleEditPost(post),
            isOwnPost: post.isOwnPost,
          );
        } else if (post is NutritionPost) {
          return NutritionPostCard(
            post: post,
            onLike: () => _handleLike(post.id),
            onComment: () => _handleCommentClick(post.id),
            onLikesClick: () => _handleLikesClick(post.id),
            onDelete: () => _handleDeletePost(post.id),
          );
        }
        return const SizedBox.shrink();
      }).toList(),
    );
  }
}

