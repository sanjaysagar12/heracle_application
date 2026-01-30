import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../data/mutual_feed_repository.dart';
import '../widgets/comments_bottom_sheet.dart';
import '../widgets/likes_bottom_sheet.dart';
import '../widgets/workout_post_card.dart'; // Import the card
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
    const isMeal = false;

    feedProvider.loadComments(post.id, isMeal: isMeal);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Consumer<FeedProvider>(
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
                    username: post.username,
                  );
                  setState(() { _loadPost(); });
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
              onDeleteComment: (commentId) async {
                return await feedProv.deleteComment(
                  post.id,
                  commentId,
                  isMeal: isMeal,
                );
              },
              currentUserProfile: userProfile,
              postOwnerUsername: post.username,
            );
          },
        ),
      ),
    );
  }

  void _showLikes(BuildContext context, FeedPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Use WorkoutPostCard
                WorkoutPostCard(
                  id: post.id,
                  name: post.name,
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
                  isOwnPost: post.isOwnPost,
                  commentCount: post.commentCount,
                  isDetailView: true, // IMPORTANT: Disables recursive nav and summary exercises
                  onLike: () async {
                      await _repository.likePost(post.id);
                      setState(() { _loadPost(); });
                  },
                  onComment: () => _showComments(context, post),
                  onLikesClick: () => _showLikes(context, post),
                  onDelete: () async {
                     // Implement delete if needed
                  },
                  onEdit: () {
                    // Implement edit if needed
                  },
                ),

                const SizedBox(height: 16),
                
                 const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Workout',
                    style: TextStyle(
                      color: AppColors.pureWhite,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Detailed Exercise List
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildExercisesList(post),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          );
        },
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
