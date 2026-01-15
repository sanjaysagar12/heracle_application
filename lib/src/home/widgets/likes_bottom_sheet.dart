import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../data/mutual_feed_repository.dart';
import '../providers/feed_provider.dart';
import 'likes_skeleton.dart';
import '../../profile/presentation/profile_page.dart';

class LikesBottomSheet extends StatefulWidget {
  // Either provide postId to fetch likes from backend OR
  // provide likedByUsers directly. Both are optional but at least
  // one should be meaningful for the UI.
  final String? postId;
  final List<LikedByUser>? likedByUsers;
  final bool isMeal;

  const LikesBottomSheet({
    super.key,
    this.postId,
    this.likedByUsers,
    this.isMeal = false,
  });

  @override
  State<LikesBottomSheet> createState() => _LikesBottomSheetState();
}

class _LikesBottomSheetState extends State<LikesBottomSheet> {
  late Map<String, bool> _followingStatus;
  bool _isLoading = true;
  List<LikedByUser> _likes = [];

  // track follow/unfollow requests in progress per username
  final Set<String> _followInProgress = {};

  @override
  void initState() {
    super.initState();
    // Initialize following status from the user data (if any provided)
    _likes = widget.likedByUsers ?? [];
    _followingStatus = {
      for (var user in _likes) user.username: user.isFollowing,
    };

    // Show skeleton immediately. If a postId is provided, fetch from backend;
    // otherwise display the provided likedByUsers immediately.
    if (widget.postId != null) {
      _fetchLikes();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _fetchLikes() async {
    if (widget.postId == null) return;
    setState(() => _isLoading = true);
    try {
      final repo = MutualFeedRepository();
      final likes = await repo.getPostLikes(
        widget.postId!,
        isMeal: widget.isMeal,
      );

      // Sync fresh likes data to FeedProvider so the feed card updates
      if (mounted) {
        context.read<FeedProvider>().updatePostLikes(widget.postId!, likes);
      }

      setState(() {
        _likes = likes;
        _followingStatus = {for (var u in _likes) u.username: u.isFollowing};
        _isLoading = false;
      });
    } catch (e) {
      // On error, keep empty list and stop loading
      setState(() {
        _likes = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow(String username) async {
    if (_followInProgress.contains(username)) return;
    final previous = _followingStatus[username] ?? false;

    // Optimistic update (UI toggles immediately)
    setState(() {
      _followingStatus[username] = !previous;
      _followInProgress.add(username);
    });

    try {
      final repo = MutualFeedRepository();
      await repo.followUser(username);
      // success — UI already updated optimistically
    } catch (e) {
      // revert on error
      if (mounted) {
        setState(() {
          _followingStatus[username] = previous;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update follow: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      // remove in-progress flag (no UI spinner)
      _followInProgress.remove(username);
      if (mounted) setState(() {}); // ensure UI reflects any revert
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.black100,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          if (_isLoading)
            // show likes-specific skeleton while likes are loading
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(height: 160, child: LikesSkeleton()),
            )
          else if (_likes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Text(
                'No likes yet',
                style: TextStyle(color: AppColors.white60, fontSize: 16),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: _likes.length,
                itemBuilder: (context, index) {
                  return _buildUserItem(_likes[index]);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Likes',
            style: TextStyle(
              color: AppColors.pureWhite,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: AppColors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildUserItem(LikedByUser user) {
    final isFollowing = _followingStatus[user.username] ?? user.isFollowing;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(username: user.username),
                  ),
                );
              },
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(user.profileImage),
                    backgroundColor: AppColors.greyDark,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name.isNotEmpty ? user.name : user.username,
                          style: const TextStyle(
                            color: AppColors.pureWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          user.username.startsWith('@')
                              ? user.username
                              : '@${user.username}',
                          style: const TextStyle(
                            color: AppColors.white60,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // If this entry represents the viewer themselves, hide follow/following button
          if (!user.isViewer)
            GestureDetector(
              onTap: () => _toggleFollow(user.username),
              child: _buildFollowButton(isFollowing),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildFollowButton(bool isFollowing) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isFollowing ? Colors.transparent : AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        border: isFollowing
            ? Border.all(color: AppColors.white40, width: 1.5)
            : null,
      ),
      child: Text(
        isFollowing ? 'Following' : 'Follow',
        style: TextStyle(
          color: isFollowing ? AppColors.white60 : AppColors.black,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
