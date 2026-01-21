import 'package:flutter/material.dart';
import '../core/services/upload_manager.dart';
import '../core/theme/app_colors.dart';

/// A floating upload progress bar widget that appears at the bottom of the screen
/// when there are active uploads
class UploadProgressBar extends StatefulWidget {
  const UploadProgressBar({super.key});

  @override
  State<UploadProgressBar> createState() => _UploadProgressBarState();
}

class _UploadProgressBarState extends State<UploadProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<double>(begin: 100, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    UploadManager().addListener(_onUploadManagerChange);
  }

  @override
  void dispose() {
    UploadManager().removeListener(_onUploadManagerChange);
    _animationController.dispose();
    super.dispose();
  }

  void _onUploadManagerChange() {
    if (UploadManager().tasks.isNotEmpty) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tasks = UploadManager().tasks;

    if (tasks.isEmpty && !_animationController.isAnimating) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(opacity: _fadeAnimation.value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.black100,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: tasks.map((task) => _buildTaskItem(task)).toList(),
        ),
      ),
    );
  }

  Widget _buildTaskItem(UploadTask task) {
    final isSuccess = task.status == UploadStatus.success;
    final isFailed = task.status == UploadStatus.failed;
    final isUploading = task.status == UploadStatus.uploading;

    Color progressColor = AppColors.primary;
    IconData statusIcon = Icons.cloud_upload_outlined;
    String statusText = 'Uploading...';

    if (isSuccess) {
      progressColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Posted successfully!';
    } else if (isFailed) {
      progressColor = Colors.red;
      statusIcon = Icons.error_outline;
      statusText = task.errorMessage ?? 'Upload failed';
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon with animation
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isUploading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.primary,
                          value: null, // Indeterminate while we simulate
                        ),
                      )
                    : Icon(
                        statusIcon,
                        key: ValueKey(task.status),
                        color: progressColor,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 12),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        color: AppColors.pureWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: isSuccess
                            ? Colors.green
                            : isFailed
                            ? Colors.red
                            : AppColors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Close button for failed uploads
              if (isFailed)
                GestureDetector(
                  onTap: () => UploadManager().removeTask(task.id),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.close,
                      color: AppColors.white60,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),

          // Progress bar
          if (isUploading || isSuccess) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: task.progress),
                duration: const Duration(milliseconds: 200),
                builder: (context, value, child) {
                  return LinearProgressIndicator(
                    value: isSuccess ? 1.0 : (value > 0 ? value : null),
                    backgroundColor: AppColors.greyDark.withAlpha(77),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    minHeight: 4,
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A wrapper widget that positions the upload progress bar above the navigation bar
class UploadProgressOverlay extends StatelessWidget {
  final Widget child;
  final double bottomPadding;

  const UploadProgressOverlay({
    super.key,
    required this.child,
    this.bottomPadding = 100, // Account for nav bar height
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          left: 0,
          right: 0,
          bottom: bottomPadding,
          child: const UploadProgressBar(),
        ),
      ],
    );
  }
}
