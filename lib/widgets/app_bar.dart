import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/theme/app_colors.dart';
import '../src/home/presentation/notification_page.dart';
import '../core/services/notification_service.dart';
import '../core/services/upload_manager.dart';
import 'dart:math' as math;

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
            ListenableBuilder(
              listenable: UploadManager(),
              builder: (context, _) {
                final storyTask = UploadManager().activeTasks.cast<UploadTask?>().firstWhere(
                  (t) => t?.type == 'story',
                  orElse: () => null,
                );
                final isUploading = storyTask != null;

                return GestureDetector(
                  onTap: hasStory ? onStoryTap : onProfileTap,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isUploading)
                        const _RotatingProgressBorder(),
                      Container(
                        padding: const EdgeInsets.all(2), // Space for border
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: hasStory && !isUploading
                              ? const LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primary,
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
                    ],
                  ),
                );
              },
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
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
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
            GestureDetector(
              onTap: () {
                 Navigator.push(
                   context,
                   MaterialPageRoute(builder: (context) => const NotificationPage()),
                 );
              },
              child: ValueListenableBuilder<bool>(
                valueListenable: NotificationService().hasUnreadNotifications,
                builder: (context, hasUnread, child) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
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
                      if (hasUnread)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.primary, // Green dot (using primary color which is green-ish)
                              shape: BoxShape.circle,
                              border: Border.fromBorderSide(BorderSide(color: AppColors.black, width: 1.5)),
                            ),
                          ),
                        ),
                    ],
                  );
                }
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RotatingProgressBorder extends StatefulWidget {
  const _RotatingProgressBorder();

  @override
  State<_RotatingProgressBorder> createState() => _RotatingProgressBorderState();
}

class _RotatingProgressBorderState extends State<_RotatingProgressBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  Colors.transparent,
                  AppColors.primary,
                  AppColors.primary,
                  Colors.transparent,
                ],
                stops: [0.0, 0.2, 0.8, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }
}
