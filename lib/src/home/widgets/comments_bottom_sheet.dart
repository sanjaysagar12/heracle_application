import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../data/mutual_feed_repository.dart';

class CommentsBottomSheet extends StatefulWidget {
  final List<Comment> comments;
  final Future<void> Function(String) onAddComment;
  final Future<void> Function(String, String) onAddReply;

  const CommentsBottomSheet({
    super.key,
    required this.comments,
    required this.onAddComment,
    required this.onAddReply,
  });

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  String? _replyingToId;
  String? _replyingToUsername;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleAddComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    if (_replyingToId != null) {
      await widget.onAddReply(_replyingToId!, content);
      _cancelReply();
    } else {
      await widget.onAddComment(content);
    }

    _commentController.clear();
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
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.black100,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: widget.comments.isEmpty
                ? const Center(
                    child: Text(
                      'No comments yet\nBe the first to comment!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.white60,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: widget.comments.length,
                    itemBuilder: (context, index) {
                      return _buildCommentItem(widget.comments[index], 0);
                    },
                  ),
          ),
          if (_replyingToUsername != null) _buildReplyingToBar(),
          _buildCommentInput(),
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

  Widget _buildCommentItem(Comment comment, int depth) {
    return Padding(
      padding: EdgeInsets.only(left: depth * 24.0, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(comment.profileImage),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.username,
                          style: const TextStyle(
                            color: AppColors.pureWhite,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildReplyingToBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.greyDark,
        border: Border(
          top: BorderSide(color: AppColors.greyLight, width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Replying to $_replyingToUsername',
            style: const TextStyle(
              color: AppColors.white60,
              fontSize: 13,
            ),
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
        border: Border(
          top: BorderSide(color: AppColors.greyDark, width: 1),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(
              'https://tse3.mm.bing.net/th/id/OIP.dvSVSBNTSG_uMW_J4J5pWwHaHa?w=1000&h=1000&rs=1&pid=ImgDetMain&o=7&rm=3',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _commentController,
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
          IconButton(
            onPressed: _handleAddComment,
            icon: const Icon(Icons.send, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
