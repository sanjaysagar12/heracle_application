import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../data/mutual_feed_repository.dart';
import '../../nutrition/presentation/track_calories_page.dart';
import '../../../route.dart';
import '../widgets/comments_bottom_sheet.dart';
import '../widgets/likes_bottom_sheet.dart';
import '../widgets/nutrition_post_card.dart';
import '../providers/feed_provider.dart';
import '../data/profile_repository.dart' as home_repo;
import '../../profile/data/profile_repository.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Still needed for logic icons if any remaining

class NutritionDetailsPage extends StatefulWidget {
  final NutritionPost? post;
  final String? postId;

  const NutritionDetailsPage({super.key, this.post, this.postId})
      : assert(post != null || postId != null);

  @override
  State<NutritionDetailsPage> createState() => _NutritionDetailsPageState();
}

class _NutritionDetailsPageState extends State<NutritionDetailsPage> {
  late Future<FeedPost> _postFuture;
  final MutualFeedRepository _repository = MutualFeedRepository();
  final ProfileRepository _profileRepository = ProfileRepository(); 
  UserProfile? _currentUserProfile;

  int _currentSessionIndex = 0; // Still used for diet log selection matching? 
  // Actually NutritionPostCard manages its own session index visually.
  // But our Diet Log list depends on which meal is selected.
  // PROBLEM: NutritionPostCard has its own PageController state. We don't get a callback when it changes page.
  // The user might swipe the card carousel, but our "Diet log" below won't update if we don't sync.
  // The request is "use the nutrition post card".
  // `NutritionPostCard` does NOT expose a callback for page change.
  // To strictly follow the "use the card" instruction AND keep "Diet Log" working, 
  // I either need to accept that Diet Log only shows the first meal (or all meals?), 
  // OR modify NutritionPostCard to expose onPageChanged.
  // Given the complexity, I'll update NutritionPostCard to expose `onPageChanged`.
  
  // However, for this step, I will assume showing all logs or just the first is acceptable, 
  // OR I can quickly add the callback to NutritionPostCard. 
  // Let's add the callback next. For now, I'll stick to showing a list for the *first* meal or handle it.
  // Actually, checking NutritionDetailsPage previous code (step 524), it had `_currentSessionIndex`.
  // If I delegate the carousel to the Card, I lose control.
  // I will add `onPageChanged` to `NutritionPostCard`.
  
  // WAIT. I'll stick to the plan of just implementing using the card first.
  // If I use the card, the "Diet Log" section below needs accurate data.
  // I'll make the diet log show *all* meals sequentially if there are multiple? 
  // Or just update the card to share state. sharing state is better.
  
  @override
  void initState() {
    super.initState();
    _loadPost();
    _loadUserProfile(); 
  }
  
  void _loadPost() {
    final id = widget.post?.id ?? widget.postId!;
    _postFuture = _repository.getPostDetails(id, isMeal: true);
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

  void _showComments(BuildContext context, FeedPost post) { 
    final feedProvider = context.read<FeedProvider>();
    const isMeal = true;

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
                  username: post.username,
                );
                // Refresh post to update comment count
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
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
         builder: (context, scrollController) => LikesBottomSheet(
            postId: post.id,
            isMeal: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.pureWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Diet Details',
          style: TextStyle(
            color: AppColors.pureWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<FeedPost>(
        future: _postFuture,
        builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
               return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            } else if (snapshot.hasError) {
               return const Center(
                  child: Text(
                    'Error loading details',
                    style: TextStyle(color: AppColors.white60),
                  ),
               );
            } else if (!snapshot.hasData) {
               return const Center(child: Text('Post not found', style: TextStyle(color: AppColors.white60)));
            }

            final post = snapshot.data!;
            if (post is! NutritionPost) {
                return const Center(child: Text('Not a nutrition post', style: TextStyle(color: AppColors.white60)));
            }
            
            // Note: We use the Card for display. The Diet Log needs to know which meal is active.
            // Since NutritionPostCard handles its own state, let's just show logs for ALL meals for now,
            // or just the first one if listing them all is too long.
            // Listing all with headers is a good detail view experience.
            
            return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NutritionPostCard(
                      post: post,
                      isDetailView: true,
                      onDelete: () async {
                         // Implement delete if needed
                      },
                      onLike: () async {
                         await _repository.likePost(post.id, isMeal: true);
                         setState(() { _loadPost(); });
                      },
                      onComment: () => _showComments(context, post),
                      onLikesClick: () => _showLikes(context, post),
                      onPageChanged: (index) {
                        setState(() {
                          _currentSessionIndex = index;
                        });
                      },
                    ),

                    const SizedBox(height: 12),
                    
                    if (post.meals.isNotEmpty && _currentSessionIndex < post.meals.length) ...[
                         Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              const Text(
                                'Diet log',
                                style: TextStyle(
                                  color: AppColors.pureWhite,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  post.meals[_currentSessionIndex].mealType,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        _buildDietLogList(post.meals[_currentSessionIndex]),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
            );
        },
      ),
    );
  }

  Widget _buildDietLogList(NutritionMeal meal) {
    if (meal.foodItems.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Text('No items logged', style: TextStyle(color: AppColors.white60)),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: meal.foodItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = meal.foodItems[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.black100,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.white10,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          color: AppColors.pureWhite,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                       color: AppColors.white10,
                       borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(
                        color: AppColors.pureWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   _buildMiniMacro('Calories', '${item.calories}Cal', AppColors.primary),
                   _buildMiniMacro('Protein', '${item.protein}g', AppColors.primary),
                   _buildMiniMacro('Fat', '${item.fat}g', AppColors.primary),
                   _buildMiniMacro('Carbs', '${item.carbs}g', AppColors.primary),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniMacro(String label, String value, Color color) {
     String iconPath = 'assets/icons/calories.svg';
      if (label == 'Protein') iconPath = 'assets/icons/protein.svg';
      if (label == 'Carbs') iconPath = 'assets/icons/carbs.svg';
      if (label == 'Fat') iconPath = 'assets/icons/fat.svg';

    return Column(
      children: [
        Row(
          children: [
            SvgPicture.asset(iconPath, width: 12, height: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.white10,
            borderRadius: BorderRadius.circular(8),
          ),
           child: Text(
            value,
            style: const TextStyle(color: AppColors.white60, fontSize: 11),
          ),
        ),
      ],
    );
  }
}
