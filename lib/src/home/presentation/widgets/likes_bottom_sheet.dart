import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/mutual_feed_repository.dart';

class LikesBottomSheet extends StatelessWidget {
  final List<LikedByUser> likedByUsers;

  const LikesBottomSheet({
    super.key,
    required this.likedByUsers,
  });

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
          if (likedByUsers.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Text(
                'No likes yet',
                style: TextStyle(
                  color: AppColors.white60,
                  fontSize: 16,
                ),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: likedByUsers.length,
                itemBuilder: (context, index) {
                  return _buildUserItem(likedByUsers[index]);
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
                  user.name,
                  style: const TextStyle(
                    color: AppColors.pureWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '@${user.name}',
                  style: const TextStyle(
                    color: AppColors.white60,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildFollowButton(user.isFollowing),
        ],
      ),
    );
  }

  Widget _buildFollowButton(bool isFollowing) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
