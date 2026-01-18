import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../data/mutual_feed_repository.dart';
import '../../nutrition/presentation/track_calories_page.dart';
import '../../../route.dart';
import '../widgets/comments_bottom_sheet.dart';
import '../widgets/likes_bottom_sheet.dart';
import '../providers/feed_provider.dart';
import '../data/profile_repository.dart' as home_repo;
import '../../profile/data/profile_repository.dart';

class NutritionDetailsPage extends StatefulWidget {
  final NutritionPost post;

  const NutritionDetailsPage({super.key, required this.post});

  @override
  State<NutritionDetailsPage> createState() => _NutritionDetailsPageState();
}

class _NutritionDetailsPageState extends State<NutritionDetailsPage> {
  late Future<FeedPost> _postFuture;
  final MutualFeedRepository _repository = MutualFeedRepository();
  final ProfileRepository _profileRepository = ProfileRepository(); // Added
  UserProfile? _currentUserProfile; // Added

  int _currentSessionIndex = 0;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadPost();
    _loadUserProfile(); // Added
  }
  
  void _loadPost() {
    _postFuture = _repository.getPostDetails(widget.post.id, isMeal: true);
  }

  Future<void> _loadUserProfile() async { // Added
      try {
           // Fallback to a default user or fetch 'me' if possible. 
           // Using same logic as WorkoutDetailsPage for consistency.
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

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  NutritionMeal _getCurrentMeal(NutritionPost post) {
    if (post.meals.isEmpty) {
        return NutritionMeal(
            sessionId: '', mealType: 'Meal', content: '', images: [], 
            calories: 0, protein: 0, carbs: 0, fats: 0);
    }
    if (_currentSessionIndex >= post.meals.length) return post.meals.first;
    return post.meals[_currentSessionIndex];
  }

  void _showComments(BuildContext context, FeedPost post) { // Added
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

  void _showLikes(BuildContext context, FeedPost post) { // Added
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
            
            final currentMeal = _getCurrentMeal(post);

            return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.black100,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(post),
                          
                          if (currentMeal.content.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              currentMeal.content,
                              style: const TextStyle(
                                color: AppColors.pureWhite,
                                fontSize: 15,
                                height: 1.4,
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),

                          if (post.meals.isNotEmpty)
                            _buildCarousel(post.meals),

                          if (post.meals.isNotEmpty)
                            _buildMacros(currentMeal),

                          const SizedBox(height: 16),
                          const Divider(color: AppColors.greyDark, height: 1),
                          const SizedBox(height: 16),

                          _buildActions(context, post), // Updated signature
                          
                          _buildLikedBy(context, post), // Updated signature
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Diet log',
                        style: TextStyle(
                          color: AppColors.pureWhite,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (post.meals.isNotEmpty)
                      _buildDietLogList(currentMeal),
                    
                    const SizedBox(height: 40),
                  ],
                ),
            );
        },
      ),
    );
  }

  Widget _buildHeader(NutritionPost post) {
      return Row(
        children: [
          GestureDetector(
            onTap: () {
               Navigator.pushNamed(
                context,
                AppRoutes.profile,
                arguments: post.handle,
              );
            },
            child: CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(post.profileImage.isNotEmpty
                  ? post.profileImage
                  : 'https://ui-avatars.com/api/?name=${post.username}&background=random'),
            ),
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
              fontSize: 12,
            ),
          ),
        ],
      );
  }
  
  Widget _buildActions(BuildContext context, NutritionPost post) {
       return Row(
        children: [
          GestureDetector(
            onTap: () async {
               await _repository.likePost(post.id, isMeal: true);
               setState(() {
                   _loadPost(); // Refresh
               });
            },
            child: Icon(
              post.isLiked ? Icons.favorite : Icons.favorite_border,
              color: post.isLiked ? Colors.red : AppColors.pureWhite,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
             onTap: () => _showLikes(context, post),
             child: Text('${post.likes}', style: const TextStyle(color: AppColors.pureWhite)),
          ),
          const SizedBox(width: 16),
          
          GestureDetector(
            onTap: () => _showComments(context, post),
            child: SvgPicture.asset(
              'assets/icons/comment.svg',
              width: 20,
              height: 20,
              color: AppColors.pureWhite,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
             onTap: () => _showComments(context, post),
             child: Text('${post.commentCount}', style: const TextStyle(color: AppColors.pureWhite)),
          ),
          const SizedBox(width: 16),

          SvgPicture.asset(
            'assets/icons/share.svg',
            width: 20,
            height: 20,
            color: AppColors.pureWhite,
          ),
        ],
      );
  }
  
  Widget _buildLikedBy(BuildContext context, NutritionPost post) {
     if (post.likedBy.isEmpty) return const SizedBox.shrink();
     
     return GestureDetector(
        onTap: () => _showLikes(context, post),
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            children: [
              ...post.likedBy.take(3).map((user) => Align(
                widthFactor: 0.7,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.greyDark,
                  backgroundImage: NetworkImage(user.profileImage),
                ),
              )),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  post.likes > 1
                      ? 'Liked by ${post.likedBy[0].name} and others'
                      : 'Liked by ${post.likedBy[0].name}',
                  style: const TextStyle(
                    color: AppColors.white60,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
     );
  }

  Widget _buildCarousel(List<NutritionMeal> meals) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 10,
          child: PageView.builder(
            controller: _pageController,
            itemCount: meals.length,
            onPageChanged: (index) {
              setState(() {
                _currentSessionIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final meal = meals[index];
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: NetworkImage(meal.images.isNotEmpty 
                        ? meal.images.first 
                        : 'https://dummyimage.com/600x400/000/fff'),
                    fit: BoxFit.cover,
                  ),
                ),
                 child: Stack(
                  children: [
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          meal.mealType,
                          style: const TextStyle(
                            color: AppColors.pureWhite,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        if (meals.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(meals.length, (index) {
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentSessionIndex == index 
                      ? AppColors.white60 
                      : AppColors.white10,
                ),
              );
            }),
          ),
      ],
    );
  }

  Widget _buildMacros(NutritionMeal meal) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMacroItem('Calories', '${meal.calories}', 'assets/icons/calories.svg', AppColors.primary),
          _buildMacroItem('Protein', '${meal.protein}g', 'assets/icons/protein.svg', AppColors.primary),
          _buildMacroItem('Carbs', '${meal.carbs}g', 'assets/icons/carbs.svg', AppColors.primary),
          _buildMacroItem('Fats', '${meal.fats}g', 'assets/icons/fat.svg', AppColors.primary),
        ],
      ),
    );
  }
  
  Widget _buildMacroItem(String label, String value, String assetPath, Color color) {
      return Column(
        children: [
          Row(
            children: [
               SvgPicture.asset(
                assetPath,
                width: 14,
                height: 14,
                color: AppColors.white60,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(color: AppColors.white60, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
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
