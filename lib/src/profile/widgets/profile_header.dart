import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../data/profile_repository.dart';

class ProfileHeader extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback? onFollowTap;
  final VoidCallback? onEditTap; // Added
  final VoidCallback? onProfileImageTap;
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;

  const ProfileHeader({
    super.key,
    required this.profile,
    this.onFollowTap,
    this.onEditTap, // Added
    this.onProfileImageTap,
    this.onFollowersTap,
    this.onFollowingTap,
  });

  @override
  Widget build(BuildContext context) {
    const double bannerHeight = 140;
    const double profileImageSize = 100;

    return Column(
      children: [
        // Banner + Profile Image
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Banner
            Container(
              height: bannerHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.greyDark,
                image: profile.bannerUrl != null
                    ? DecorationImage(
                        image: NetworkImage(profile.bannerUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
            ),
            // Profile Image
            Positioned(
              bottom: -(profileImageSize / 2),
              child: GestureDetector(
                onTap: onProfileImageTap,
                child: Container(
                  width: profileImageSize,
                  height: profileImageSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: profile.hasStory
                        ? LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
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
            ),
          ],
        ),
        
        // Spacing for the bottom half of the profile image
        SizedBox(height: (profileImageSize / 2) + 16),
        
        // Profile Info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
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
              const SizedBox(height: 4),
              Text(
                '@${profile.username}',
                style: const TextStyle(
                  color: AppColors.white60,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 24),
              // Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatColumn('Highlights', profile.formattedHighlights),
                  const SizedBox(width: 32),
                  _buildStatColumn(
                    'Following', 
                    profile.formattedFollowing, 
                    onTap: onFollowingTap,
                  ),
                  const SizedBox(width: 32),
                  _buildStatColumn(
                    'Followers', 
                    profile.formattedFollowers, 
                    onTap: onFollowersTap,
                  ),
                ],
              ),
              
              // Follow or Edit Button
              if (onEditTap != null) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onEditTap,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.white40),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Edit Profile',
                      style: TextStyle(
                        color: AppColors.pureWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ] else if (onFollowTap != null) ...[
                const SizedBox(height: 24),
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
              ] else ...[
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
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
      ),
    );
  }
}
