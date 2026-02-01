import 'package:flutter/material.dart';
import '../../profile/presentation/profile_page.dart';
import '../../../core/theme/app_colors.dart';
import '../data/mutual_feed_repository.dart';
import '../data/profile_repository.dart';

class CommentsBottomSheet extends StatefulWidget {
  final List<Comment>? comments;
  final Future<void> Function(String) onAddComment;
  final Future<void> Function(String, String) onAddReply;
  final Future<bool> Function(String)? onDeleteComment; // New: delete callback
  final bool isLoading;
  final Function(Comment)? onOptimisticCommentAdd;
  final Function(String, Comment)? onOptimisticReplyAdd;
  final Profile? currentUserProfile;
  final String? postOwnerUsername; // Kept for display/reference if needed
  final bool isPostOwner; // New: explicit flag for ownership

  const CommentsBottomSheet({
    super.key,
    this.comments,
    required this.onAddComment,
    required this.onAddReply,
    this.onDeleteComment,
    this.isLoading = false,
    this.onOptimisticCommentAdd,
    this.onOptimisticReplyAdd,
    this.currentUserProfile,
    this.postOwnerUsername,
    this.isPostOwner = false,
  });

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  String? _replyingToId;
  String? _replyingToUsername;
  bool _isAddingComment = false;
  List<Comment> _localComments = [];

  // Removed internal ProfileRepository usage

  @override
  void initState() {
    super.initState();
    _localComments = List.from(widget.comments ?? []);
  }

  @override
  void didUpdateWidget(CommentsBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.comments != oldWidget.comments && widget.comments != null) {
      _localComments = List.from(widget.comments!);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleAddComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _isAddingComment = true;
    });

    try {
      // Use passed profile or fallback
      final username = widget.currentUserProfile?.username ?? 'User';
      final handle = widget.currentUserProfile != null
          ? '@${widget.currentUserProfile!.username}'
          : '@user';
      final profileImage =
          widget.currentUserProfile?.profileImageUrl ??
          'https://ui-avatars.com/api/?name=User&background=random';

      if (_replyingToId != null) {
        // Create optimistic reply
        final optimisticReply = Comment(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          username: username,
          handle: handle,
          profileImage: profileImage,
          timeAgo: 'Just now',
          content: content,
          replies: [],
          isOwner: true,
        );

        // Update UI optimistically
        setState(() {
          _localComments = _addReplyToCommentLocal(
            _localComments,
            _replyingToId!,
            optimisticReply,
          );
        });

        // Call parent callback for optimistic update
        if (widget.onOptimisticReplyAdd != null) {
          widget.onOptimisticReplyAdd!(_replyingToId!, optimisticReply);
        }

        // Make API call
        await widget.onAddReply(_replyingToId!, content);
        _cancelReply();
      } else {
        // Create optimistic comment
        final optimisticComment = Comment(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          username: username,
          handle: handle,
          profileImage: profileImage,
          timeAgo: 'Just now',
          content: content,
          replies: [],
        );

        // Update UI optimistically
        setState(() {
          _localComments = [..._localComments, optimisticComment];
        });

        // Call parent callback for optimistic update
        if (widget.onOptimisticCommentAdd != null) {
          widget.onOptimisticCommentAdd!(optimisticComment);
        }

        // Make API call
        await widget.onAddComment(content);
      }
      _commentController.clear();
    } catch (e) {
      // Revert optimistic update on error
      setState(() {
        _localComments = List.from(widget.comments ?? []);
      });

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post comment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingComment = false;
        });
      }
    }
  }

  List<Comment> _addReplyToCommentLocal(
    List<Comment> comments,
    String commentId,
    Comment newReply,
  ) {
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
          replies: _addReplyToCommentLocal(
            comment.replies,
            commentId,
            newReply,
          ),
          isOwner: comment.isOwner,
        );
      }
      return comment;
    }).toList();
  }

  void _startReply(String commentId, String username) {
    setState(() {
      _replyingToId = commentId;
      _replyingToUsername = username;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingToId = null;
      _replyingToUsername = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(bottom: keyboardHeight),
      decoration: const BoxDecoration(
        color: AppColors.black100,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: widget.isLoading
                ? _buildSkeletonLoading()
                : (_localComments.isEmpty)
                ? const Center(
                    child: Text(
                      'No comments yet\nBe the first to comment!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.white60, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _localComments.length,
                    itemBuilder: (context, index) {
                      return _buildCommentItem(_localComments[index], 0);
                    },
                  ),
          ),
          if (_replyingToUsername != null) _buildReplyingToBar(),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) => _buildSkeletonCommentItem(),
    );
  }

  Widget _buildSkeletonCommentItem() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.greyDark,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.greyDark,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 40,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.greyDark,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.greyDark,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 200,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.greyDark,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 50,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.greyDark,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
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
            'Comments',
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

  /// Check if current user can delete a comment
  /// User can delete if they are the comment owner OR the post owner
  bool _canDeleteComment(Comment comment) {
    // Check if user is comment owner (using backend flag)
    bool isCommentOwner = comment.isOwner;

    // Fallback: Check username if backend flag not reliable or during optimistic updates?
    // Optimistic comments created in this file don't have isOwner=true set explicitly in _handleAddComment
    // I should probably set isOwner=true for optimistic comments too.
    if (!isCommentOwner && widget.currentUserProfile?.username != null) {
      isCommentOwner = comment.username == widget.currentUserProfile!.username;
    }

    // Check if user is post owner
    final currentUsername = widget.currentUserProfile?.username;
    final isPostOwner =
        widget.isPostOwner ||
        (widget.postOwnerUsername != null &&
            currentUsername != null &&
            widget.postOwnerUsername == currentUsername);

    return isCommentOwner || isPostOwner;
  }

  /// Show delete confirmation dialog
  void _showDeleteDialog(Comment comment) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.black100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Comment',
          style: TextStyle(color: AppColors.pureWhite),
        ),
        content: const Text(
          'Are you sure you want to delete this comment? This action cannot be undone.',
          style: TextStyle(color: AppColors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.white60),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _handleDeleteComment(comment);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  /// Handle comment deletion
  Future<void> _handleDeleteComment(Comment comment) async {
    if (widget.onDeleteComment == null) return;

    // Optimistically remove comment locally
    setState(() {
      _localComments = _removeCommentLocally(_localComments, comment.id);
    });

    final success = await widget.onDeleteComment!(comment.id);

    if (!success && mounted) {
      // Revert on failure - refresh from parent
      setState(() {
        _localComments = List.from(widget.comments ?? []);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete comment'),
          backgroundColor: Colors.red,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment deleted'),
          backgroundColor: AppColors.greyDark,
        ),
      );
    }
  }

  /// Recursively remove a comment by ID
  List<Comment> _removeCommentLocally(
    List<Comment> comments,
    String commentId,
  ) {
    return comments.where((comment) => comment.id != commentId).map((comment) {
      if (comment.replies.isNotEmpty) {
        return Comment(
          id: comment.id,
          username: comment.username,
          handle: comment.handle,
          profileImage: comment.profileImage,
          timeAgo: comment.timeAgo,
          content: comment.content,
          replies: _removeCommentLocally(comment.replies, commentId),
          isOwner: comment.isOwner,
        );
      }
      return comment;
    }).toList();
  }

  Widget _buildCommentItem(Comment comment, int depth) {
    final canDelete =
        _canDeleteComment(comment) && widget.onDeleteComment != null;

    return GestureDetector(
      onLongPress: canDelete ? () => _showDeleteDialog(comment) : null,
      child: Padding(
        padding: EdgeInsets.only(left: depth * 24.0, bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProfilePage(username: comment.username),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(comment.profileImage),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ProfilePage(username: comment.username),
                                ),
                              );
                            },
                            child: Text(
                              comment.username,
                              style: const TextStyle(
                                color: AppColors.pureWhite,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            comment.timeAgo,
                            style: const TextStyle(
                              color: AppColors.white60,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        comment.content,
                        style: const TextStyle(
                          color: AppColors.pureWhite,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _startReply(comment.id, comment.username),
                        child: const Text(
                          'Reply',
                          style: TextStyle(
                            color: AppColors.white60,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (comment.replies.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  children: comment.replies
                      .map((reply) => _buildCommentItem(reply, depth + 1))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyingToBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.greyDark,
        border: Border(top: BorderSide(color: AppColors.greyLight, width: 1)),
      ),
      child: Row(
        children: [
          Text(
            'Replying to $_replyingToUsername',
            style: const TextStyle(color: AppColors.white60, fontSize: 13),
          ),
          const Spacer(),
          IconButton(
            onPressed: _cancelReply,
            icon: const Icon(Icons.close, color: AppColors.white60, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.greyDark, width: 1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(
              widget.currentUserProfile?.profileImageUrl ??
                  'https://ui-avatars.com/api/?name=User&background=random',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _commentController,
              enabled: !_isAddingComment,
              style: const TextStyle(color: AppColors.pureWhite),
              decoration: InputDecoration(
                hintText: _replyingToUsername != null
                    ? 'Reply to $_replyingToUsername...'
                    : 'Add a comment...',
                hintStyle: const TextStyle(color: AppColors.white60),
                filled: true,
                fillColor: AppColors.greyDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _isAddingComment
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                )
              : IconButton(
                  onPressed: _handleAddComment,
                  icon: const Icon(Icons.send, color: AppColors.primary),
                ),
        ],
      ),
    );
  }
}
