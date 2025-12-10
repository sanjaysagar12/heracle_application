import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/theme/app_colors.dart';

class CustomAppBar extends StatelessWidget {
  final String name;
  final int age;
  final String profileImageUrl;
  final VoidCallback? onProfileTap;
  final VoidCallback? onStoryTap;
  final bool hasStory;

  const CustomAppBar({
    super.key,
    required this.name,
    required this.age,
    required this.profileImageUrl,
    this.onProfileTap,
    this.onStoryTap,
    this.hasStory = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 16,
        right: 16,
      ),
      child: SizedBox(
        height: 80.0,
        child: Row(
          children: [
            GestureDetector(
              onTap: hasStory ? onStoryTap : onProfileTap,
              child: Container(
                padding: const EdgeInsets.all(2), // Space for border
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: hasStory
                      ? const LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary, // Or use a slight gradient if desired
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2), // Inner spacing/border
                  ),
                  child: CircleAvatar(
                    radius: 24, // Slightly reduced to fit in container
                    backgroundImage: NetworkImage(profileImageUrl),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: onProfileTap,
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                      ],
                    ),
                    Text(
                      '$age years old',
                      style: const TextStyle(color: AppColors.white60, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.black100,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/bell.svg',
                  width: 24,
                  height: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFF76B40), Color(0xFFFFB937)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/fire.svg',
                  width: 24,
                  height: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
