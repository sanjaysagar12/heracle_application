import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../data/profile_repository.dart';

class ProfileHeader extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback? onFollowTap;
  final VoidCallback? onProfileImageTap;

  const ProfileHeader({
    super.key,
    required this.profile,
    this.onFollowTap,
    this.onProfileImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Profile Image with gradient border
          GestureDetector(
            onTap: onProfileImageTap,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.5),
                    AppColors.primary.withOpacity(0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(3),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.black, width: 3),
                ),
                child: ClipOval(
                  child: Image.network(
                    profile.profileImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.greyDark,
                        child: const Icon(
                          Icons.person,
                          color: AppColors.white60,
                          size: 50,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Name with verification badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                profile.name,
                style: const TextStyle(
                  color: AppColors.pureWhite,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (profile.isVerified) ...[
                const SizedBox(width: 6),
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: AppColors.black,
                    size: 14,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatColumn('Highlights', profile.formattedHighlights),
              Container(
                height: 40,
                width: 1,
                color: AppColors.greyDark,
                margin: const EdgeInsets.symmetric(horizontal: 32),
              ),
              _buildStatColumn('Following', profile.formattedFollowing),
              Container(
                height: 40,
                width: 1,
                color: AppColors.greyDark,
                margin: const EdgeInsets.symmetric(horizontal: 32),
              ),
              _buildStatColumn('Followers', profile.formattedFollowers),
            ],
          ),
          const SizedBox(height: 24),
          // Follow Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onFollowTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              icon: Icon(
                profile.isFollowing ? Icons.check : Icons.person_add,
                size: 20,
              ),
              label: Text(
                profile.isFollowing ? 'Following' : 'Follow',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.white60,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.pureWhite,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
