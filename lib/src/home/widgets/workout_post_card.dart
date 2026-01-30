import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../../core/utils/share_utils.dart';
import '../data/mutual_feed_repository.dart';
import '../../../route.dart';
import '../presentation/workout_details_page.dart';

class WorkoutPostCard extends StatefulWidget {
  final String id; // Add ID field
  final String name;
  final String username;
  final String handle;
  final String profileImage;
  final String timeAgo;
  final String content;
  final List<String> tags;
  final List<String> images;
  final String duration;
  final String volume;
  final String records;
  final List<Exercise> exercises;
  final int likes;
  final List<LikedByUser> likedBy;
  final bool isOwnPost;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final bool isLiked;
  final VoidCallback onLike;
  final int commentCount;
  final VoidCallback onComment;
  final VoidCallback onLikesClick;
  final bool isDetailView;

  const WorkoutPostCard({
    super.key,
    this.id =
        '', // Default or required, depends. It should be required but existing calls might break if I don't default.
    required this.name,
    required this.username,
    required this.handle,
    required this.profileImage,
    required this.timeAgo,
    required this.content,
    required this.tags,
    required this.images,
    required this.duration,
    required this.volume,
    required this.records,
    required this.exercises,
    required this.likes,
    required this.likedBy,
    this.isLiked = false,
    this.isOwnPost = false,
    required this.onLike,
    required this.commentCount,
    required this.onComment,
    required this.onLikesClick,
    required this.onDelete,
    required this.onEdit,
    this.isDetailView = false,
  });

  @override
  State<WorkoutPostCard> createState() => _WorkoutPostCardState();
}

class _WorkoutPostCardState extends State<WorkoutPostCard> {
  bool _isExpanded = false;

  void _navigateToProfile() {
    Navigator.pushNamed(context, AppRoutes.profile, arguments: widget.handle);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.black100,
        title: const Text(
          'Delete Post',
          style: TextStyle(color: AppColors.pureWhite),
        ),
        content: const Text(
          'Are you sure you want to delete this post?',
          style: TextStyle(color: AppColors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.white60),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      widget.onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.black100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: GestureDetector(
        onTap: () {
          if (!widget.isDetailView && widget.id.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WorkoutDetailsPage(postId: widget.id),
              ),
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildContent(),
            const SizedBox(height: 12),
            _buildTags(),
            const SizedBox(height: 16),
            _buildImages(),
            const SizedBox(height: 16),
            _buildStats(),
            const SizedBox(height: 16),
            if (!widget.isDetailView) ...[
              const SizedBox(height: 16),
              _buildExercises(),
            ],
            const SizedBox(height: 16),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _navigateToProfile,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(widget.profileImage),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: const TextStyle(
                          color: AppColors.pureWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.handle.isNotEmpty
                            ? widget.handle
                            : '@${widget.username}',
                        style: const TextStyle(
                          color: AppColors.white60,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  widget.timeAgo,
                  style: const TextStyle(
                    color: AppColors.white60,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.isOwnPost)
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                widget.onEdit();
              } else if (value == 'delete') {
                _confirmDelete();
              }
            },
            icon: const Icon(Icons.more_vert, color: AppColors.white60),
            color: AppColors.black100,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.greyDark),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20, color: AppColors.pureWhite),
                    SizedBox(width: 12),
                    Text('Edit', style: TextStyle(color: AppColors.pureWhite)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildContent() {
    if (widget.content.isEmpty) return const SizedBox.shrink();
    return Text(
      widget.content,
      style: const TextStyle(
        color: AppColors.pureWhite,
        fontSize: 15,
        height: 1.4,
      ),
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 8,
      children: widget.tags
          .map(
            (tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.greyDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                tag,
                style: const TextStyle(color: AppColors.primary, fontSize: 13),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildImages() {
    if (widget.images.isEmpty) return const SizedBox.shrink();

    if (widget.images.length == 1) {
      return GestureDetector(
        onTap: () => _showImageCarousel(context, 0),
        child: SizedBox(
          height: 200,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              widget.images[0],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: AppColors.greyDark),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _showImageCarousel(context, 0),
              child: Container(
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.images[0],
                    fit: BoxFit.cover,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: AppColors.greyDark),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => _showImageCarousel(context, 1),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.images[1],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: AppColors.greyDark),
                    ),
                  ),
                  if (widget.images.length > 2)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '+${widget.images.length - 2}',
                          style: const TextStyle(
                            color: AppColors.pureWhite,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
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
  }

  void _showImageCarousel(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ImageCarouselViewer(
          images: widget.images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        _buildStatItem('Duration', widget.duration),
        const SizedBox(width: 24),
        _buildStatItem('Volume', widget.volume),
        const SizedBox(width: 24),
        _buildStatItem('Records', widget.records),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.white60, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.pureWhite,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildExercises() {
    final exercisesToShow = _isExpanded
        ? widget.exercises
        : widget.exercises.take(3).toList();

    return Column(
      children: [
        for (var exercise in exercisesToShow)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                  ),
                  child: ClipOval(
                    child: Image.network(
                      exercise.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.greyDark,
                          child: const Icon(
                            Icons.fitness_center,
                            color: AppColors.white60,
                            size: 20,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    exercise.name,
                    style: const TextStyle(
                      color: AppColors.pureWhite,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (widget.exercises.length > 3)
          TextButton(
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              _isExpanded
                  ? 'Show less'
                  : 'See ${widget.exercises.length - 3} more exercises',
              style: const TextStyle(color: AppColors.white60, fontSize: 14),
            ),
          ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Divider(color: AppColors.greyDark, height: 1),
        const SizedBox(height: 16),
        Row(
          children: [
            GestureDetector(
              onTap: widget.onLike,
              child: Icon(
                widget.isLiked ? Icons.favorite : Icons.favorite_border,
                color: widget.isLiked ? Colors.red : AppColors.pureWhite,
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: widget.onLikesClick,
              child: Text(
                '${widget.likes}',
                style: const TextStyle(
                  color: AppColors.pureWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 24),
            GestureDetector(
              onTap: widget.onComment,
              child: SvgPicture.asset(
                'assets/icons/comment.svg',
                width: 24,
                height: 24,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: widget.onComment,
              child: Text(
                '${widget.commentCount}',
                style: const TextStyle(
                  color: AppColors.pureWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 24),
            GestureDetector(
              onTap: () {
                ShareUtils.showShareOptions(
                  context: context,
                  title: 'Check out this workout by ${widget.name}',
                  content: widget.content,
                  username: widget.name,
                  profileImageUrl: widget.profileImage,
                  postId: widget.id,
                  type: 'workout',
                  imageUrl: widget.images.isNotEmpty
                      ? widget.images.first
                      : null,
                );
              },
              child: SvgPicture.asset(
                'assets/icons/share.svg',
                width: 24,
                height: 24,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.likedBy.isNotEmpty)
          GestureDetector(
            onTap: widget.onLikesClick,
            child: Row(
              children: [
                ...widget.likedBy
                    .take(3)
                    .map(
                      (user) => Align(
                        widthFactor: 0.7,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.greyDark,
                          backgroundImage: NetworkImage(user.profileImage),
                        ),
                      ),
                    ),
                const SizedBox(width: 8),
                Text(
                  widget.likes > 1
                      ? 'Liked by ${widget.likedBy[0].name} and others'
                      : 'Liked by ${widget.likedBy[0].name}',
                  style: const TextStyle(
                    color: AppColors.white60,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ImageCarouselViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _ImageCarouselViewer({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_ImageCarouselViewer> createState() => _ImageCarouselViewerState();
}

class _ImageCarouselViewerState extends State<_ImageCarouselViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1}/${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.network(
                widget.images[index],
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.error, color: Colors.white, size: 50),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
