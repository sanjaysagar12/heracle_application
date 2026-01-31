import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../data/user_suggestion.dart';

class UserSuggestionCard extends StatelessWidget {
  final UserSuggestion suggestion;
  final VoidCallback onFollow;
  final VoidCallback onDismiss;
  final VoidCallback? onTap;
  final bool isFollowing;

  const UserSuggestionCard({
    super.key,
    required this.suggestion,
    required this.onFollow,
    required this.onDismiss,
    this.onTap,
    this.isFollowing = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      width: 160,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Slightly lighter than black bg
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white10),
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              // Avatar
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.greyDark,
                backgroundImage: suggestion.avatarUrl != null
                    ? NetworkImage(suggestion.avatarUrl!)
                    : null,
                child: suggestion.avatarUrl == null
                    ? const Icon(
                        Icons.person,
                        size: 40,
                        color: AppColors.white60,
                      )
                    : null,
              ),
              const SizedBox(height: 12),

              // Name
              Text(
                suggestion.name.isNotEmpty
                    ? suggestion.name
                    : suggestion.username,
                style: const TextStyle(
                  color: AppColors.pureWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 4),

              // Followed By
              if (suggestion.followedBy.isNotEmpty)
                _buildFollowedBy(suggestion.followedBy)
              else
                const Text(
                  'Suggested',
                  style: TextStyle(color: AppColors.white60, fontSize: 10),
                ),

              const Spacer(),

              // Follow Button
              SizedBox(
                width: double.infinity,
                height: 32,
                child: ElevatedButton(
                  onPressed: onFollow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFollowing
                        ? Colors.transparent
                        : AppColors.primary,
                    foregroundColor: isFollowing
                        ? AppColors.white60
                        : AppColors.black,
                    padding: EdgeInsets.zero,
                    elevation: isFollowing ? 0 : 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: isFollowing
                          ? const BorderSide(color: AppColors.white40)
                          : BorderSide.none,
                    ),
                  ),
                  child: Text(
                    isFollowing ? 'Following' : 'Follow',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isFollowing ? AppColors.white60 : AppColors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Dismiss Button
          Positioned(
            top: -4,
            right: -4,
            child: GestureDetector(
              onTap: onDismiss,
              child: const Icon(
                Icons.close,
                color: AppColors.white60,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildFollowedBy(List<UserSuggestionFollowedBy> followedBy) {
    // Show overlapping avatars or just text?
    // Image suggests: small avatar + "Followed by name + 8 more"
    // Let's implement a simplified version

    final first = followedBy.first;
    final count = followedBy.length - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (first.avatarUrl != null)
          CircleAvatar(
            radius: 8,
            backgroundColor: AppColors.greyDark,
            backgroundImage: NetworkImage(first.avatarUrl!),
          ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            count > 0
                ? 'Followed by ${first.username} +$count more'
                : 'Followed by ${first.username}',
            style: const TextStyle(color: AppColors.white60, fontSize: 10),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
