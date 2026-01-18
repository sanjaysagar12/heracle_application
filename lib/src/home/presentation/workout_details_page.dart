import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart'; // Correct path: src/home/presentation -> src/home -> src -> lib -> core/theme (3 levels up)
import '../data/mutual_feed_repository.dart';
import '../widgets/comments_bottom_sheet.dart';
import '../widgets/likes_bottom_sheet.dart';
import '../../profile/presentation/profile_page.dart';
import '../providers/feed_provider.dart';
import '../data/profile_repository.dart' as home_repo;
import '../../profile/data/profile_repository.dart';

class WorkoutDetailsPage extends StatefulWidget {
  final String postId;

  const WorkoutDetailsPage({super.key, required this.postId});

  @override
  State<WorkoutDetailsPage> createState() => _WorkoutDetailsPageState();
}

class _WorkoutDetailsPageState extends State<WorkoutDetailsPage> {
  late Future<FeedPost> _postFuture;
  final MutualFeedRepository _repository = MutualFeedRepository();
  final ProfileRepository _profileRepository = ProfileRepository();
  UserProfile? _currentUserProfile;

  @override
  void initState() {
    super.initState();
    _loadPost();
    _loadUserProfile();
  }
  
  Future<void> _loadUserProfile() async {
      try {
          // Assuming we can get current user profile. Using a hardcoded username or getting from auth is typical.
          // For now, let's try to get it if we have a way, or rely on FeedProvider if it has it.
          // ProfilePage loads it. Here we might be deep in nav.
          // Let's try to fetch via ProfileRepository using 'me' or similar if supported, 
          // or just assume we can get it from an auth provider.
          // Since I don't have easy access to "my username" without auth context, 
          // I will look at how ProfilePage does it. It uses widget.username ?? '@sanjaysagar'.
          // I'll try to fetch '@sanjaysagar' as a fallback for the "current user" for commenting.
          // In a real app, I'd grab this from a UserProvider.
           final profile = await _profileRepository.getUserProfile('@sanjaysagar.main');
           if (mounted) {
               setState(() {
                   _currentUserProfile = profile;
               });
           }
      } catch (e) {
          print('Error loading user profile: $e');
      }
  }

  void _loadPost() {
    _postFuture = _repository.getPostDetails(widget.postId);
  }

  void _showComments(BuildContext context, FeedPost post) {
    final feedProvider = context.read<FeedProvider>();
    final isMeal = post is NutritionPost;

    // Start loading comments
    feedProvider.loadComments(post.id, isMeal: isMeal);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      builder: (sheetContext) => Consumer<FeedProvider>(
        builder: (sheetContext, feedProv, child) {
          final comments = feedProv.getComments(post.id);
          final isLoading = feedProv.isCommentsLoading(post.id);

          home_repo.Profile? userProfile;
          if (_currentUserProfile != null) {
            userProfile = home_repo.Profile(
              name: _currentUserProfile!.name,
              username: _currentUserProfile!.username,
              age: 0,
              profileImageUrl: _currentUserProfile!.profileImageUrl,
              hasStory: _currentUserProfile!.hasStory,
            );
          }

          return CommentsBottomSheet(
            comments: comments,
            isLoading: isLoading,
            onAddComment: (content) async {
               if (userProfile != null) {
                await feedProv.addComment(
                  post.id,
                  content,
                  userProfile,
                  isMeal: isMeal,
                  username: post.username, // Post owner username? Or just passed for context?
                );
               }
            },
            onAddReply: (commentId, content) async {
               if (userProfile != null) {
                await feedProv.addReply(
                  post.id,
                  commentId,
                  content,
                  userProfile,
                  isMeal: isMeal,
                );
               }
            },
            onOptimisticCommentAdd: (comment) {}, // Optional
            onOptimisticReplyAdd: (commentId, reply) {}, // Optional
            currentUserProfile: userProfile,
          );
        },
      ),
    );
  }

  void _showLikes(BuildContext context, FeedPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Changed to transparent for draggable sheet
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
         builder: (context, scrollController) => LikesBottomSheet(
            postId: post.id,
            isMeal: false,
        ),
      ),
    );
  }

  String _formatDuration(String durationStr) {
    if (durationStr.isEmpty) return '0min';
    final duration = int.tryParse(durationStr);
    if (duration != null) {
        if (duration > 60) {
            final hrs = duration ~/ 60;
            final mins = duration % 60;
            return '${hrs}hr ${mins}min';
        }
        return '${duration}min';
    }
    return durationStr;
  }

  String _formatVolume(String volumeStr) {
    if (volumeStr.isEmpty || volumeStr == '0') return '0kg';
    return '${volumeStr}kg'; 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.pureWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Workout Details', style: TextStyle(color: AppColors.pureWhite)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<FeedPost>(
        future: _postFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          } else if (snapshot.hasError) {
             print(snapshot.error);
            return const Center(
              child: Text(
                'Error loading post',
                style: TextStyle(color: AppColors.white60),
              ),
            );
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Post not found', style: TextStyle(color: AppColors.white60)));
          }

          final post = snapshot.data!;
          if (post is! WorkoutPost) {
             return const Center(child: Text('Not a workout post', style: TextStyle(color: AppColors.white60)));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, post),
                const SizedBox(height: 16),
                _buildContent(post),
                const SizedBox(height: 12),
                _buildTags(post),
                const SizedBox(height: 16),
                _buildImages(context, post),
                const SizedBox(height: 20),
                _buildStats(post),
                 const SizedBox(height: 16),
                const Divider(color: AppColors.greyDark),
                const SizedBox(height: 16),
                _buildActions(context, post),
                 const SizedBox(height: 16),
                _buildLikedBy(context, post),
                 const SizedBox(height: 24),
                const Text(
                  'Workout',
                  style: TextStyle(
                    color: AppColors.pureWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildExercisesList(post),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WorkoutPost post) {
    return GestureDetector(
      onTap: () {
         Navigator.push(
            context,
            MaterialPageRoute(
               builder: (context) => ProfilePage(username: post.username),
            ),
         );
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(post.profileImage),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.name, 
                  style: const TextStyle(
                    color: AppColors.pureWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  post.handle.isNotEmpty ? post.handle : '@${post.username}',
                  style: const TextStyle(
                    color: AppColors.white60,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            post.timeAgo,
            style: const TextStyle(
              color: AppColors.white60,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(WorkoutPost post) {
    if (post.content.isEmpty) return const SizedBox.shrink();
    return Text(
      post.content,
      style: const TextStyle(
        color: AppColors.pureWhite,
        fontSize: 15,
        height: 1.4,
      ),
    );
  }

  Widget _buildTags(WorkoutPost post) {
    if (post.tags.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      children: post.tags.map((tag) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.greyDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          tag,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 13,
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildImages(BuildContext context, WorkoutPost post) {
    if (post.images.isEmpty) return const SizedBox.shrink();
    
     return SizedBox(
      height: 200,
      child: post.images.length == 1
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                post.images[0],
                fit: BoxFit.cover,
                width: double.infinity,
                 errorBuilder: (context, error, stackTrace) => Container(color: AppColors.greyDark),
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      post.images[0],
                      fit: BoxFit.cover,
                      height: double.infinity,
                       errorBuilder: (context, error, stackTrace) => Container(color: AppColors.greyDark),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Stack(
                      fit: StackFit.expand,
                      children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              post.images[1],
                              fit: BoxFit.cover,
                               errorBuilder: (context, error, stackTrace) => Container(color: AppColors.greyDark),
                            ),
                          ),
                          if (post.images.length > 2)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '+${post.images.length - 2}',
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
              ],
            ),
    );
  }

  Widget _buildStats(WorkoutPost post) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
       children: [
          Expanded(child: _buildStatItem('Duration', _formatDuration(post.duration))),
          Expanded(child: _buildStatItem('Volume', _formatVolume(post.volume))),
          Expanded(child: _buildStatItem('Records', post.records.isEmpty || post.records == 'nil' ? 'nil' : post.records)),
       ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.white60,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.pureWhite,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, WorkoutPost post) {
      return Row(
          children: [
              GestureDetector(
                  onTap: () {
                     _repository.likePost(post.id);
                     setState(() {
                         _loadPost(); 
                     });
                  },
                  child: Icon(
                      post.isLiked ? Icons.favorite : Icons.favorite_border,
                      color: post.isLiked ? Colors.red : AppColors.pureWhite,
                      size: 28,
                  ),
              ),
              const SizedBox(width: 8),
              Text(
                  '${post.likes}',
                  style: const TextStyle(
                      color: AppColors.pureWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                  ),
              ),
              const SizedBox(width: 24),
              GestureDetector(
                  onTap: () => _showComments(context, post),
                  child: SvgPicture.asset(
                      'assets/icons/comment.svg',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(AppColors.pureWhite, BlendMode.srcIn),
                  ),
              ),
               const SizedBox(width: 8),
               Text(
                   '${post.commentCount}',
                   style: const TextStyle(
                       color: AppColors.pureWhite,
                       fontSize: 16,
                       fontWeight: FontWeight.bold,
                   ),
               )
           ],
      );
  }
  
  Widget _buildLikedBy(BuildContext context, WorkoutPost post) {
      if (post.likedBy.isEmpty) return const SizedBox.shrink();
      
      final firstUser = post.likedBy.first;
      return GestureDetector(
          onTap: () => _showLikes(context, post),
          child: Row(
              children: [
                  CircleAvatar(
                      radius: 10,
                      backgroundImage: NetworkImage(firstUser.profileImage),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        'Liked by ${firstUser.name} and others',
                        style: const TextStyle(
                            color: AppColors.white60,
                            fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
          ),
      );
  }

  Widget _buildExercisesList(WorkoutPost post) {
    return Column(
      children: post.exercises.map((exercise) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.black100, 
            borderRadius: BorderRadius.circular(16),
             border: Border.all(color: AppColors.greyDark.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Row(
                 children: [
                    CircleAvatar(
                       radius: 20,
                       backgroundColor: AppColors.greyDark,
                       backgroundImage: exercise.imageUrl.isNotEmpty 
                            ? NetworkImage(exercise.imageUrl) 
                            : null,
                       child: exercise.imageUrl.isEmpty 
                            ? const Icon(Icons.fitness_center, color: AppColors.white60) 
                            : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                          Text(
                             exercise.name,
                             style: const TextStyle(
                                color: AppColors.pureWhite,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                             ),
                          ),
                       ],
                    ),
                 ],
               ),
               const SizedBox(height: 16),
               if (exercise.sets.isNotEmpty)
                ...exercise.sets.map((set) => _buildSetRow(set)).toList(),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSetRow(ExerciseSet set) {
     return Padding(
       padding: const EdgeInsets.symmetric(vertical: 6.0),
       child: Row(
          children: [
             SizedBox(
                width: 50,
                child: Text(
                   'Set ${set.setNumber}',
                   style: const TextStyle(
                      color: AppColors.primary, 
                      fontWeight: FontWeight.bold,
                   ),
                ),
             ),
             const Spacer(),
             if (set.kg > 0) ...[
               _buildSetMetric('Weight', '${set.kg}'),
               const SizedBox(width: 16),
             ],
             if (set.reps > 0) ...[
               _buildSetMetric('Reps', '${set.reps}'),
               const SizedBox(width: 16),
             ],
             if (set.time > 0)
               _buildSetMetric('Time', '${set.time}s'),
          ],
       ),
     );
  }

  Widget _buildSetMetric(String label, String value) {
     return Row(
        children: [
           Text(
              label,
              style: const TextStyle(
                 color: AppColors.white60,
                 fontSize: 13,
              ),
           ),
           const SizedBox(width: 8),
           Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                 color: AppColors.greyDark,
                 borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                 value,
                 style: const TextStyle(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.bold,
                 ),
              ),
           ),
        ],
     );
  }
}
